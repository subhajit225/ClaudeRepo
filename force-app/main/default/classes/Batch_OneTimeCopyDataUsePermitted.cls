/**
 * @name - Batch_OneTimeCopyDataUsePermitted
 * @description - One time Batch class to copy value of Privacy_Compliance__c to Data Use Permitted.
 */
public class Batch_OneTimeCopyDataUsePermitted implements Database.Batchable<sObject>, Database.Stateful {
    
    /**
     * @description - Start method to retrieve all Non Converted Leads
     * @param bc Database.BatchableContext - the batch context
     * @return Database.QueryLocator - query locator for Lead records
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Name, Privacy_Compliance__c, Data_Use_Permitted__c FROM Lead ' +
                       'WHERE IsConverted = FALSE AND Privacy_Compliance__c = TRUE';
        return Database.getQueryLocator(query);
    }
    
    /**
     * @description - Execute method to copy value of Privacy_Compliance__c to Data Use Permitted
     * @param bc Database.BatchableContext - the batch context
     * @param scope List<Lead> - scope of Lead records for this execution
     */
    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        List<Lead> lOfLeadsToUpdate = new List<Lead>();
        for(Lead l : scope){
            l.Data_Use_Permitted__c = l.Privacy_Compliance__c;
            lOfLeadsToUpdate.add(l);
        }
        
        if (!lOfLeadsToUpdate.isEmpty()) {
            flowControll.leadTriggerHandler = false;
            update lOfLeadsToUpdate;
            flowControll.leadTriggerHandler = true;
        }
    }
    
    /**
     * @description - Finish method for post-processing
     * @param bc Database.BatchableContext - the batch context
     */
    public void finish(Database.BatchableContext bc) {}

}