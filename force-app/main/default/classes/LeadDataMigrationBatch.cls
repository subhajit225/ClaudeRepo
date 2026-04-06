/**
 * @description Batch class to migrate IT Budget,Company Phone and Other Phone data from a managed package field
 * (DSCORGPKG__IT_Budget__c,DSCORGPKG__Company_Phone__c,DSCORGPKG__Other_Phone__c) to a custom field (IT_Budget__c,Company_Phone__c,Other_Phone__c) on the Lead object.
 */
public with sharing class LeadDataMigrationBatch implements Database.Batchable<SObject>{
    /**
     * @description The start method collects the records or objects to be passed into the execute method.
     * @param bc Database.BatchableContext
     * @return Database.QueryLocator A QueryLocator object for the Lead records.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, DSCORGPKG__IT_Budget__c,DSCORGPKG__Company_Phone__c,DSCORGPKG__Other_Phone__c FROM Lead WHERE DSCORGPKG__IT_Budget__c != NULL OR DSCORGPKG__Company_Phone__c != null OR DSCORGPKG__Other_Phone__c != null';
        return Database.getQueryLocator(query);
    }

    /**
     * @description The execute method performs the actual data processing. It receives a list of
     * sObjects (Lead records in this case) from the start method.
     * @param bc Database.BatchableContext
     * @param scope List<Lead> A list of Lead records to process in this batch chunk.
     */
    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        List<Lead> leadsToUpdate = new List<Lead>();
        for (Lead ld : scope) {
            Boolean hasChanged = false;
            if (ld.DSCORGPKG__IT_Budget__c != null) {
                ld.IT_Budget__c = ld.DSCORGPKG__IT_Budget__c;
                hasChanged = true;
            }
			if (ld.DSCORGPKG__Company_Phone__c != null) {
                ld.Company_Phone__c = ld.DSCORGPKG__Company_Phone__c;
                hasChanged = true;
            }
			if (ld.DSCORGPKG__Other_Phone__c != null) {
                ld.Other_Phone__c = ld.DSCORGPKG__Other_Phone__c;
                hasChanged = true;
            }
            if(hasChanged){
                leadsToUpdate.add(ld);
            }
        }
        if (!leadsToUpdate.isEmpty()) {
            try {
				Database.update(leadsToUpdate, false);

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