/**
 * @description Batch class to migrate IT Budget data from a managed package field
 * (DSCORGPKG__IT_Budget__c) to a custom field (IT_Budget__c) on the Account object.
 */
public with sharing class AccountDataMigrationBatch implements Database.Batchable<SObject>{
    /**
     * @description The start method collects the records or objects to be passed into the execute method.
     * @param bc Database.BatchableContext
     * @return Database.QueryLocator A QueryLocator object for the Account records.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, DSCORGPKG__IT_Budget__c FROM Account WHERE DSCORGPKG__IT_Budget__c != NULL';
        return Database.getQueryLocator(query);
    }

    /**
     * @description The execute method performs the actual data processing. It receives a list of
     * sObjects (Account records in this case) from the start method.
     * @param bc Database.BatchableContext
     * @param scope List<Account> A list of Account records to process in this batch chunk.
     */
    public void execute(Database.BatchableContext bc, List<Account> scope) {
        List<Account> accountsToUpdate = new List<Account>();
        for (Account acc : scope) {
            if (acc.DSCORGPKG__IT_Budget__c != null) {
                acc.IT_Budget__c = acc.DSCORGPKG__IT_Budget__c;
                accountsToUpdate.add(acc);
            }
        }
        if (!accountsToUpdate.isEmpty()) {
            try {
                Database.update(accountsToUpdate, false);
            } catch (DmlException e) {
                System.debug(System.LoggingLevel.debug,'Batch Execute: DML Error updating accounts: ' + e.getMessage());
            }
        }
    }

    /**
     * @description The finish method is executed once all batches are processed. 
     * @param bc Database.BatchableContext
     */
    public void finish(Database.BatchableContext bc) {
        System.debug(System.LoggingLevel.debug,'Batch Finish: IT Budget Migration Batch Job completed with status: ');
        
    }
}