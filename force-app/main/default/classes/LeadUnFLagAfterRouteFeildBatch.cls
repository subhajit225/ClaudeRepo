public with sharing class LeadUnFLagAfterRouteFeildBatch implements Database.Batchable<sObject>, Schedulable{
  
 //MKT23-717 Deployment
    String query = 'SELECT Id,AssignLeadInAfter__c FROM Lead WHERE AssignLeadInAfter__c =true'; 
    
   
    public void execute(SchedulableContext sc) { 
        Database.executeBatch(this);
    }
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc, List<Lead> LeadList){
        system.debug('LeadList>>>>'+LeadList);
        for(Lead l : LeadList){
             if(l.AssignLeadInAfter__c) {
                l.AssignLeadInAfter__c = False;
             }
             
        }
        update LeadList;
    }
    public void finish(Database.BatchableContext bc){

    }
}