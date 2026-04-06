/*****************************************************************************
 

* @Author      : Sushant Arora
* @description : Update Case Entitlement EndDate - Holds logic for updating Case Custom field Entitlement_End_Date__c with Entitlement EndDate.
* @TestClass   : UpdateCaseEntitlementEndDateBatchTest 


******************************************************************************/

global class UpdateCaseEntitlementEndDateBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, RecordType.Name, Entitlement__c, Entitlement__r.EndDate, Entitlement_End_Date__c
            FROM Case
            WHERE RecordType.Name = 'Customer Success' AND Entitlement__c != null AND Entitlement_End_Date__c = null
        ]);
    }
    global void execute(Database.BatchableContext BC, List<Case> scope) {
        List<Case> caseListToUpdate = new List<Case>();
        for (Case caseRecord : scope) {
            if (caseRecord.Entitlement__c != null) {
                caseRecord.Entitlement_End_Date__c = caseRecord.Entitlement__r.EndDate;
                caseListToUpdate.add(caseRecord);
            }
        }
        if (!caseListToUpdate.isEmpty()) {
            Database.update(caseListToUpdate, false);
        }
    }

    global void finish(Database.BatchableContext BC) {
    }
}