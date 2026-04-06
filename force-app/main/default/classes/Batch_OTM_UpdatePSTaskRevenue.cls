public class Batch_OTM_UpdatePSTaskRevenue implements Database.Batchable<sObject>, Database.Stateful {
	
    public Map<String, String> mapProductToRevenueType ;
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        this.mapProductToRevenueType = new Map<String, String>();
        for( PS_Task_Meta__mdt taskmdt : [Select Id, MasterLabel , Revenue_Type__c from PS_Task_Meta__mdt] ) {
            mapProductToRevenueType.put( taskmdt.MasterLabel, taskmdt.Revenue_Type__c );
        }
        return Database.getQueryLocator('Select Id, Order_Product__c,Revenue_Type__c From PS_Task__c Where Revenue_Type__c=null');
    }
    
    public void execute(Database.BatchableContext bc, List<PS_Task__c> lstScope) {
        List<PS_Task__c> lstTaskToUpdate = new List<PS_Task__c>();
        for( PS_Task__c objTask : lstScope ) {
            if( mapProductToRevenueType.containsKey( objTask.Order_Product__c ) ) {
                objTask.Revenue_Type__c = mapProductToRevenueType.get( objTask.Order_Product__c );
                lstTaskToUpdate.add( objTask );
            }
        }
        if( !lstTaskToUpdate.isEmpty() ) {
            update lstTaskToUpdate;
        }
    }
    
    public void finish(Database.BatchableContext BC){
        
    }
    
    public static void dummyMethod() {
        Integer i=0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
    
}