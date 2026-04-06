/**
 * @name - Batch_OneTimeCopyData_Contact
 * @description - One time Batch class to copy value of Limited Use to Data Use Permitted.
 */
public class Batch_OneTimeCopyData_Contact implements Database.Batchable<sObject>, Database.Stateful {
    
    /**
     * @description - Start method to retrieve all Non Converted Leads
     * @param bc Database.BatchableContext - the batch context
     * @return Database.QueryLocator - query locator for Lead records
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Name,Data_Use_Permitted__c,Limited_Use__c FROM Contact ' +
                       'WHERE Limited_Use__c = TRUE';
        return Database.getQueryLocator(query);
    }
    
    /**
     * @description - Execute method to copy value of Limited_Use__c to Data Use Permitted
     * @param bc Database.BatchableContext - the batch context
     * @param scope List<Contact> - scope of Lead records for this execution
     */
    public void execute(Database.BatchableContext bc, List<Contact> scope) {
        List<Contact> ContactsToUpdate = new List<Contact>();
        for(Contact c : scope){
            c.Data_Use_Permitted__c = c.Limited_Use__c;
            ContactsToUpdate.add(c);
        }
        
        if (!ContactsToUpdate.isEmpty()) {
            flowControll.contactTrigger = false;
            update ContactsToUpdate;
            flowControll.contactTrigger = true;
        }
    }
    
    /**
     * @description - Finish method for post-processing
     * @param bc Database.BatchableContext - the batch context
     */
    public void finish(Database.BatchableContext bc) {
        //No Post processing is required for this batch
    }

}