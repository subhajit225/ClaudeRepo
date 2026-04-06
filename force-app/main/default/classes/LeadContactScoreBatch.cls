/**
 * @description Batch class to update Lead and Contact records' Update_Lead_Score__c field.
 * Updates all related records for the provided Account IDs.
 */
public class LeadContactScoreBatch implements Database.Batchable<SObject> {

    Set<Id> accountIds;
    String objectType;

    /**
     * @description Constructor to initialize the batch with Account IDs and Object Type.
     * @param accountIds Set of Account Ids whose related records need update.
     * @param objectType Type of object: 'Lead' or 'Contact'.
     */
    public LeadContactScoreBatch(Set<Id> accountIds, String objectType) {
        this.accountIds = accountIds;
        this.objectType = objectType;
    }

    /**
     * @description Defines the scope of records the batch should process.
     * @param bc Batchable context.
     * @return QueryLocator with selected Leads or Contacts.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        if(objectType == 'Lead') {
            return Database.getQueryLocator(
                [SELECT Id, Update_Lead_Score__c FROM Lead WHERE Winning_L2A_Account__c IN :accountIds]
            );
        } else {
            return Database.getQueryLocator(
                [SELECT Id, Update_Lead_Score__c FROM Contact WHERE AccountId IN :accountIds]
            );
        }
    }

     /**
     * @description Executes the logic for each chunk of records.
     * @param bc Batchable context.
     * @param scope List of SObjects to process.
     */
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<SObject> recordsToUpdate = new List<SObject>();
        for (SObject rec : scope) {
            rec.put('Update_Lead_Score__c', true);
            recordsToUpdate.add(rec);
        }
        if(!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }

    /**
     * @description Final logic after batch execution completes.
     * @param bc Batchable context.
     */
    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.DEBUG, 'Batch process completed for Account IDs: ' + accountIds);
    }
}