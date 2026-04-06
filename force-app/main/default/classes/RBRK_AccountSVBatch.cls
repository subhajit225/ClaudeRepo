/**
 * @description Batch class to process Account records with Type in ('Customer', 'Distributor', 'Reseller').
 *              For each batch of accounts, it calls the RBRK_SubscriptionSummaryVariableCalc class
 *              to perform downstream processing.
 * 
 * @author      Siddharth Ahluwalia
 * @created     2025-06-27
 * @version     1.0
 */
Public class RBRK_AccountSVBatch implements Database.Batchable<SObject>,Schedulable{

    /**
     * @description Returns the QueryLocator for Accounts with specified Types.
     * @param       bc The batch context provided by the Salesforce runtime.
     * @return      A QueryLocator for eligible Account records.
     */
    Public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Type FROM Account WHERE Id in (Select SBQQSC__Account__c from ContractLineItem)';
        return Database.getQueryLocator(query);
    }

    /**
     * @description Processes each batch of Account records and passes them to RBRK_SubscriptionSummaryVariableCalc.
     * @param       bc The batch context.
     * @param       scope A list of Account records for the current batch.
     */
    Public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Account> accountList = new List<Account>();

        for (SObject obj : scope) {
            accountList.add((Account)obj);
        }

        if (!accountList.isEmpty()) {
            try {

            RBRK_SubscriptionSummaryVariableCalc rbrk = new RBRK_SubscriptionSummaryVariableCalc(accountList);
            
            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, 'Error executing RBRK_SubscriptionSummaryVariableCalc: ' + ex.getMessage());
            }
        }
    }

    /**
     * @description Called after all batches are processed. Logs completion message.
     * @param       bc The batch context.
     */
    Public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO, 'Account batch processing completed successfully.');
    }
     /**
     * @description Schedulable entry point
     * @param       sc The batch Schedulable context.
     */
    public void execute(SchedulableContext sc) {
        // Run the batch when scheduled
        Database.executeBatch(new RBRK_AccountSVBatch(), 5);
    }
}