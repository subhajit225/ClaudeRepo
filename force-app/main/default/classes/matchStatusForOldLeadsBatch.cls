public class matchStatusForOldLeadsBatch implements Database.Batchable<sObject>, Schedulable{
	public void execute(SchedulableContext sc) {
        Database.executeBatch(new matchStatusForOldLeadsBatch());
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        string Days_For_Last_Activity = System.Label.Days_For_Last_Activity;
        string query = 'select id, Last_MQL_Date__c,MQL__C, status, Lead_Rejection_Reason__c, FCRM__FCR_Status_Last_Set__c, LastActivityDate, owner.name from lead';
        if(!Test.isRunningTest())
       		query = query +'  where ((MQL__C= false and status IN (\'Open\' , \'Working\' , \'Meeting Set\')) OR (MQL__C= true and status IN ( \'RAW\', \'Nurture\', \'Non-Qualified\')) ) and Partner_MQL__c = false and isconverted = false and deal_registration__C = false and FCRM__FCR_Status_Last_Set__c < LAST_N_DAYS:'+Days_For_Last_Activity+' and lastactivitydate < LAST_N_DAYS:'+Days_For_Last_Activity+' and (Last_MQL_Date__c < LAST_N_DAYS:'+Days_For_Last_Activity+' OR (Last_MQL_Date__c = null And MQL__C= false) )';	

        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Lead> scope){
        for(lead leadRec : scope) {
            if((leadRec.status== 'Open' || leadRec.status== 'Working' || leadRec.status== 'Meeting Set') && leadRec.MQL__C == false){
                leadRec.status= 'Nurture';
                if(String.isBlank(leadRec.Lead_Rejection_Reason__c) || leadRec.Lead_Rejection_Reason__c == 'AE Active Opp') leadRec.Lead_Rejection_Reason__c = 'Automated unMQL (Admin Only)';
            }
            else if((leadRec.status== 'RAW' || leadRec.status== 'Nurture' || leadRec.status== 'Non-Qualified') && leadRec.MQL__C == true){
                leadRec.MQL__C = false;
                if(leadRec.status== 'Non-Qualified' && String.isBlank(leadRec.Lead_Rejection_Reason__c)) leadRec.Lead_Rejection_Reason__c = 'No Potential';
            }
        }
        update scope; 
    }
    
    public void finish(Database.BatchableContext bc){
    }
    
}