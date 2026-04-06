/**
 * @description Batch class to populate the RBRK_NotSummaryVarCustomRuleId__c field on Account
 *              where the field is currently null. It sets the value from a custom label.
 */
public class ClearRBRKFieldsBatch implements Database.Batchable<SObject> {

    /**
     * @description Defines the query to retrieve Account records to process.
     * @param bc The batchable context
     * @return Query locator for Account records with null RBRK_NotSummaryVarCustomRuleId__c
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO, 'Starting batch - retrieving accounts with null RBRK_NotSummaryVarCustomRuleId__c');
        return Database.getQueryLocator([
            SELECT Id, RBRK_NotSummaryVarCustomRuleId__c, RBRK_SummaryVarCustomRuleId__c
            FROM Account 
            WHERE RBRK_NotSummaryVarCustomRuleId__c = NULL AND RBRK_SummaryVarCustomRuleId__c = NULL
        ]);
    }

    /**
     * @description Updates the RBRK_NotSummaryVarCustomRuleId__c field with the default label value.
     * @param bc The batchable context
     * @param scope List of Account records in current batch scope
     */
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Account> accountsToUpdate = new List<Account>();

        for (SObject sObj : scope) {
            Account acc = (Account) sObj;
            acc.RBRK_NotSummaryVarCustomRuleId__c = System.Label.AllCustomSVsJSON;
            accountsToUpdate.add(acc);
        }

        if (!accountsToUpdate.isEmpty()) {
            System.debug(LoggingLevel.INFO, 'Updating ' + accountsToUpdate.size() + ' Account records in this batch chunk.');
            Database.update(accountsToUpdate, false);
        } else {
            System.debug(LoggingLevel.INFO, 'No accounts to update in this chunk.');
        }
    }

    /**
     * @description Logs completion of the batch job.
     * @param bc The batchable context
     */
    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO, 'ClearRBRKFieldsBatch execution finished successfully.');
    }
}