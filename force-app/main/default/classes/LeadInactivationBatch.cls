public with sharing class LeadInactivationBatch implements Database.Batchable<sObject>, Schedulable{
    
    public Id leadId;
    public LeadInactivationBatch(Id leadId){
        this.leadId = leadId; 
    }
    public LeadInactivationBatch(){}
	Set<String> leadStatuses = new Set<String>{'Open', 'Working', 'Meeting Set'};
	
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(this);
    }
    public Database.QueryLocator start(Database.BatchableContext bc){
        string query = '';
        if(leadId == null){
            query = 'SELECT Id, Status, MQL__c, Last_MQL_Date__c, MeetingDate__c, LastActivityDate, Lead_Rejection_Reason__c '
            			+ 'FROM Lead '
						+ 'WHERE Status IN: leadStatuses ' 
                		+ 'AND (Last_MQL_Date__c < LAST_N_DAYS :30 OR Last_MQL_Date__c = null)';
        }else{
         	query = 'SELECT Id, Status, MQL__c, Last_MQL_Date__c, MeetingDate__c, LastActivityDate, Lead_Rejection_Reason__c '
            			+ 'FROM Lead '
						+ 'WHERE Status IN:leadStatuses ' 
                		+ 'AND (Last_MQL_Date__c < LAST_N_DAYS :30 OR Last_MQL_Date__c = null) '
                		+ 'AND Id =: leadId';
        }
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC, List<Lead> leadList) {
        List<Lead> updateLeads = new List<Lead>();
        Date todaysDate = System.today();
        Date tenDaysBeforeToday = todaysDate.addDays(-10);
        Date sixtyDaysBeforeToday = todaysDate.addDays(-60);
        if(!leadList.isEmpty()){
			for(Lead ld : leadList){
				if(!ld.MQL__c
                    || (ld.Status == 'Open' && ((ld.LastActivityDate == null || ld.LastActivityDate < tenDaysBeforeToday) && (ld.MeetingDate__c== null || ld.MeetingDate__c.Date() < tenDaysBeforeToday)))
                    || (ld.Status == 'Meeting Set' && ((ld.LastActivityDate == null || ld.LastActivityDate < tenDaysBeforeToday) && (ld.MeetingDate__c == null || ld.MeetingDate__c.Date() < sixtyDaysBeforeToday)))
                    || (ld.Status == 'Working' && ((ld.LastActivityDate == null || ld.LastActivityDate < tenDaysBeforeToday) && (ld.MeetingDate__c == null || ld.MeetingDate__c.Date() < tenDaysBeforeToday)))
                ){
						ld.Status = 'Nurture';
						ld.Lead_Rejection_Reason__c = 'Automated unMQL (Admin Only)';
                        ld.MQL__c = false;
                        updateLeads.add(ld);
			    }
			}
		}
        if(!updateLeads.isEmpty()){
            Database.SaveResult[] leadSaveResult = Database.update(updateLeads,false);
            for(Database.SaveResult sr : leadSaveResult){
                if(sr.isSuccess() == false) {      
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('Error: '+err.getMessage());
                    }
                }
            }            
        }
    }
    
    public void finish(Database.BatchableContext bc){
    }
}
/*
Below Cron Trigger can be used to schedule the Batch
String cronTriggerString = '0 0 2 * * ? *';
System.schedule('LeadInactivationBatch', cronTriggerString, new LeadInactivationBatch());
*/