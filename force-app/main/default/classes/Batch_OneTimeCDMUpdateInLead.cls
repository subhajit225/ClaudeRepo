/**
 * @name - Batch_OneTimeCDMUpdateInLead
 * @description - One time Batch class to update MQL_Channel_CDM__c Field in Lead with MQL_Channel_Partner__r.OwnerId.
 */
public class Batch_OneTimeCDMUpdateInLead implements Database.Batchable<sObject>, Database.Stateful {
    
    private static final Date FILTER_START_DATE = Date.newInstance(2025, 2, 1);
    
    /**
     * @description - Start method to retrieve all Leads where Last_MQL_Date__c >= FILTER_START_DATE AND IsConverted = False
     * @param bc Database.BatchableContext - the batch context
     * @return Database.QueryLocator - query locator for Lead records
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, MQL_Channel_Partner__c, MQL_Channel_Partner__r.OwnerId, Last_MQL_Date__c, MQL_Channel_CDM__c
            FROM Lead
            WHERE Last_MQL_Date__c > :FILTER_START_DATE AND IsConverted = FALSE AND MQL_Channel_Partner__c != null
        ]);
    }
    
    /**
     * @description - Execute method to update MQL_Channel_CDM__c with MQL_Channel_Partner__r.OwnerId
     * @param bc Database.BatchableContext - the batch context
     * @param scope List<Lead> - scope of Lead records for this execution
     */
    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        List<Lead> leadsToUpdate = new List<Lead>();
        for (Lead l : scope) {
            Id newOwner = l.MQL_Channel_Partner__r.OwnerId;
            if (newOwner != null && l.MQL_Channel_CDM__c != newOwner) {
                l.MQL_Channel_CDM__c = newOwner;
                leadsToUpdate.add(l);
            }
        }
        if (!leadsToUpdate.isEmpty()) {
            flowControll.leadTriggerHandler = false;
            Database.update(leadsToUpdate, false);
            flowControll.leadTriggerHandler = true;
        }
    }
    
    /**
     * @description - Finish method for post-processing
     * @param bc Database.BatchableContext - the batch context
     */
    public void finish(Database.BatchableContext bc) {
        Database.executeBatch(new Batch_OneTimeCDMUpdateInContact(), 2000);
    }
}