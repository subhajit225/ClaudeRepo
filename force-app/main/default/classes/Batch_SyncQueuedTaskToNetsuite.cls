public class Batch_SyncQueuedTaskToNetsuite implements Database.Batchable<sObject>, Schedulable, Database.RaisesPlatformEvents{
	
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('Select Id From PS_Task__c Where Sync_to_Net_Suite__c=\'Queued for Net Suite Sync\'');
    }
    
    public void execute(SchedulableContext SC) {Database.executeBatch( new Batch_SyncQueuedTaskToNetsuite() );}
    
    public void execute(Database.BatchableContext bc, List<PS_Task__c> lstTask) {
        List<PS_Task__c> lstTaskToUpdate = new List<PS_Task__c>();for( PS_Task__c objTask : lstTask ) {objTask.Sync_to_Net_Suite__c = 'Sync to NetSuite';}update lstTask;
     }
    
    public void finish( Database.BatchableContext bc ){}
    
}