/**
 * @name - Batch_OneTimeCDMUpdateInContact
 * @description - One time Batch class to update MQL_Channel_CDM__c Field in Contact with MQL_Channel_Partner__r.OwnerId.
 */
public class Batch_OneTimeCDMUpdateInContact implements Database.Batchable<sObject>, Database.Stateful {
    
    private static final Date FILTER_START_DATE = Date.newInstance(2025, 2, 1);
    
    /**
     * @description - Start method to retrieve all Contact where Last_MQL_Date__c >= FILTER_START_DATE
     * @param bc Database.BatchableContext - the batch context
     * @return Database.QueryLocator - query locator for Contact records
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, MQL_Channel_Partner__c, MQL_Channel_Partner__r.OwnerId, Last_MQL_Date__c, MQL_Channel_CDM__c
            FROM Contact
            WHERE Last_MQL_Date__c > :FILTER_START_DATE AND MQL_Channel_Partner__c != null
        ]);
    }
    
    /**
     * @description - Execute method to update MQL_Channel_CDM__c with MQL_Channel_Partner__r.OwnerId
     * @param bc Database.BatchableContext - the batch context
     * @param scope List<Contact> - scope of Contact records for this execution
     */
    public void execute(Database.BatchableContext bc, List<Contact> scope) {
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Contact c : scope) {
            Id newOwner = c.MQL_Channel_Partner__r.OwnerId;
            if (newOwner != null && c.MQL_Channel_CDM__c != newOwner) {
                c.MQL_Channel_CDM__c = newOwner;
                contactsToUpdate.add(c);
            }
        }
        if (!contactsToUpdate.isEmpty()) {
            flowControll.contactTrigger = false;
            Database.update(contactsToUpdate, false);
            flowControll.contactTrigger = true;
        }
    }
    
    /**
     * @description - Finish method for post-processing
     * @param bc Database.BatchableContext - the batch context
     */
    public void finish(Database.BatchableContext bc) {
        //no post processing required for this batch operation.
    }
}