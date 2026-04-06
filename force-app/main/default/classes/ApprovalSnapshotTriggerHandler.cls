/**
* @File Name : ApprovalSnapshotTriggerHandler.cls
* @description :  Trigger Handler for Approval Snapshot object
* @Author : Paritosh Bhatia
* @Last Modified By : Paritosh Bhatia
* @Last Modified On : November 20, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 20, 2025 |   | Initial Version
**/
public without sharing class ApprovalSnapshotTriggerHandler extends TriggerHandler {
    /**
     * @description : Overiding the Insert Method
     */
    public override void afterInsert() {
        List<sbaa__ApprovalSnapshot__c> snapshotsToDelete = new List<sbaa__ApprovalSnapshot__c>();
        List<String> aggFuncList = new List<String>{'Max','Min'};

        for (sbaa__ApprovalSnapshot__c snapshot : [
            SELECT Id, sbaa__ApprovalCondition__r.sbaa__TestedVariable__r.sbaa__AggregateFunction__c, sbaa__ApprovedValueNumeric__c
            FROM sbaa__ApprovalSnapshot__c WHERE Id IN :Trigger.newMap.keySet()]){

            if(aggFuncList.contains(snapshot.sbaa__ApprovalCondition__r?.sbaa__TestedVariable__r?.sbaa__AggregateFunction__c) 
            && snapshot.sbaa__ApprovedValueNumeric__c == 0){
                snapshotsToDelete.add(snapshot);
            }
        }

        if (snapshotsToDelete.size() > 0){
            delete snapshotsToDelete;
        }

    }
}