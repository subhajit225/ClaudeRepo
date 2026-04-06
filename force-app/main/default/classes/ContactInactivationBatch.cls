public class ContactInactivationBatch implements Database.Batchable<SObject>, Schedulable  {
    public Id contactId; 
    public ContactInactivationBatch(Id contactId){
        this.contactId = contactId;
    }
    public ContactInactivationBatch(){}
	Set<String> contactStatuses = new Set<String>{'Open', 'Working', 'Meeting Set'};
	
    
    public void execute(SchedulableContext sc) { 
        Database.executeBatch(this); 
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        string query = '';
        if(contactId == null){
            query = 'SELECT Id, Contact_Status__c, MQL__c, Last_MQL_Date__c, MeetingDate__c, LastActivityDate, ContactRejectReason__c '
            			+ 'FROM Contact '
						+ 'WHERE Contact_Status__c IN:contactStatuses ' 
                		+ 'AND (Last_MQL_Date__c < LAST_N_DAYS :30 OR Last_MQL_Date__c = null)';
        }else{
         	query = 'SELECT Id, Contact_Status__c, MQL__c, Last_MQL_Date__c, MeetingDate__c, LastActivityDate, ContactRejectReason__c '
            			+ 'FROM Contact '
						+ 'WHERE Contact_Status__c IN:contactStatuses ' 
                		+ 'AND (Last_MQL_Date__c < LAST_N_DAYS :30 OR Last_MQL_Date__c = null) '
                		+ 'AND Id =: contactId';
        }
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Contact> contactList) {
        List<Contact> updateContacts = new List<Contact>();
      Date todaysDate = System.today();
        Date tenDaysBeforeToday = todaysDate.addDays(-10);
        Date sixtyDaysBeforeToday = todaysDate.addDays(-60);
        if(!contactList.isEmpty()){
			for(Contact con : contactList){
				if(!con.MQL__c
                    || (con.Contact_Status__c == 'Open' && ((con.LastActivityDate == null || con.LastActivityDate < tenDaysBeforeToday) && (con.MeetingDate__c== null || con.MeetingDate__c.Date() < tenDaysBeforeToday)))
                    || (con.Contact_Status__c == 'Meeting Set' && ((con.LastActivityDate == null || con.LastActivityDate < tenDaysBeforeToday) && (con.MeetingDate__c == null || con.MeetingDate__c.Date() < sixtyDaysBeforeToday)))
                    || (con.Contact_Status__c == 'Working' && ((con.LastActivityDate == null || con.LastActivityDate < tenDaysBeforeToday) && (con.MeetingDate__c == null || con.MeetingDate__c.Date() < tenDaysBeforeToday)))
                ){
						con.Contact_Status__c = 'Nurture';
						con.ContactRejectReason__c = 'Automated unMQL (Admin Only)';
                        con.MQL__c = false;
                        updateContacts.add(con);
			    }   
		    }
            if(!updateContacts.isEmpty()){         
                Database.SaveResult[] contactSaveResult = Database.update(updateContacts,false);
                for(Database.SaveResult sr : contactSaveResult){
                    if(sr.isSuccess() == false) {      
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('Error: '+err.getMessage());
                        }
                    }
                } 
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
         
    }
}

/*
Below Cron Trigger can be used to schedule the Batch
String cronTriggerString = '0 0 3 * * ? *';
System.schedule('ContactInactivationBatch', cronTriggerString, new ContactInactivationBatch());
*/