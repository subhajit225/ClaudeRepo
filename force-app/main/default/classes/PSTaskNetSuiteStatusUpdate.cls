public with sharing class PSTaskNetSuiteStatusUpdate implements Database.Batchable<sObject>, Schedulable, Database.RaisesPlatformEvents{


    set<String> taskType =new Set<String>{'Non-Billable (Product)','Non-Billable (PS)','Non-Billable (Sales)','Non-Billable (Expired)',null};   
    Set<String> TaskStatus = new Set<String>{'Open','Not Started'}; 
    string query = 'Select id,Name from PS_Task__c '
                            +'WHERE Task_Status__c IN:TaskStatus AND Task_Type__c NOT IN:taskType'; 
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(this);
    }
    public Database.QueryLocator start(Database.BatchableContext bc){
        system.debug('query>>'+query);
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc, List<PS_Task__c> PSTaskList){
        
        system.debug('PSTaskList>>'+PSTaskList);
        for(PS_Task__c psTask : PSTaskList){
           
                  psTask.Sync_to_Net_Suite__c='Sync to NetSuite';
        }
        update PSTaskList;
    }
    public void finish(Database.BatchableContext bc){

    }
}