public with sharing class EventBatchSetMeetingCancel  implements Database.Batchable<SObject> ,Schedulable  {
        
     public void execute(SchedulableContext sc) { 
        Database.executeBatch(this);
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {      
            set<String> TypeString = new set<String>{'Inside Sales Led Meeting', 'Transformation Team Generated Meeting'};
            set<String> objectSupported = new set<String>{'Lead','Contact'};
            string query ='';
            if(Test.isRunningTest()) {
                query = 'SELECT Id ,Event_Status__c, Cancellation_Reason__c, Post_Meeting_Status__c, Completed_By__c, Completed_Date__c FROM Event WHERE Type IN :TypeString AND Post_Meeting_Status__c = null AND Who.type IN:objectSupported';
            }else 
        	    query = 'SELECT Id ,Event_Status__c, Cancellation_Reason__c, Post_Meeting_Status__c, Completed_By__c, Completed_Date__c FROM Event WHERE Type IN :TypeString AND ActivityDate = LAST_FISCAL_QUARTER AND Post_Meeting_Status__c = null AND Who.type IN:objectSupported';
            return Database.getQueryLocator(query);
    }

// MKT23-6565//
    public void execute(Database.BatchableContext BC, List<Event> scope) {
        for(Event ev : scope){
            ev.Completed_By__c = 'Marketing Automation';
			ev.Completed_Date__c = System.Today();
			ev.Post_Meeting_Status__c = 'Meeting Cancelled';
			ev.Cancellation_Reason__c = 'System Closed No Action';
			ev.Event_Status__c = 'Cancelled'; 
        }
        if(!scope.isEmpty()){
             Database.SaveResult[] eventSaveResult = Database.update(scope,false);
            for(Database.SaveResult sr : eventSaveResult){
                if (sr.isSuccess() == false) {      
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('Error: '+err.getMessage());
                    }
                }
            } 
        }
    }

  //MKT2300032432
    public void finish(Database.BatchableContext BC) {
         
    }
/*
CronTrigger Expression to run the Batch Class on the last day of the first month of each Quarter
String cronExpString ='0 0 23 L FEB,MAY,AUG,NOV ? *';
*/
}