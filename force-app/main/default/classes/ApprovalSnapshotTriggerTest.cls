/***********************************************************************************************************
* Class Name           : ApprovalSnapshotTriggerTest
* Date Created/Modified: 21/11/2025
* Author               : Paritosh
* @description         : Test class for ApprovalSnapshotTrigger
* Test Class           :
/********************************************************************************************************/
@isTest
public without sharing class ApprovalSnapshotTriggerTest {
    /***********************************************************************************************************
    * Method Name          : testSnapshot
    * Date Created/Modified: 21/11/2025
    * Author               : Paritosh
    * @description         : Test method
    /**********************************************************************************************************/
    @isTest
    public static void testSnapshot() {

        TriggerControl__c control = new TriggerControl__c(
            Name = 'Approval',
            DisableTrigger__c = true
        );
        insert control;

        sbaa__Approval__c approval = new sbaa__Approval__c(
            sbaa__Status__c = 'Requested',
            sbaa__AssignedTo__c = UserInfo.getUserId(),
            sbaa__RecordField__c = 'Quote__c',
            sbaa__ApprovalStep__c = 1
        );
        insert approval;

        sbaa__ApprovalVariable__c var = new sbaa__ApprovalVariable__c();
        var.sbaa__AggregateFunction__c = 'MAX';
        insert var;

        sbaa__ApprovalRule__c rule = new sbaa__ApprovalRule__c();
        rule.sbaa__TargetObject__c = 'SBQQ__Quote__c';
        insert rule;

        sbaa__ApprovalCondition__c condition = new sbaa__ApprovalCondition__c();
        condition.sbaa__TestedVariable__c = var.Id;
        condition.sbaa__ApprovalRule__c = rule.Id;
        insert condition;

        Test.startTest();

        System.runAs(new User(Id = UserInfo.getUserId())) {

            sbaa__ApprovalSnapshot__c snap = new sbaa__ApprovalSnapshot__c();
            snap.sbaa__Approval__c = approval.Id;
            snap.sbaa__ApprovalCondition__c = condition.Id;
            snap.sbaa__ApprovedValueNumeric__c = 0;
            insert snap;

            System.assert([SELECT COUNT() FROM sbaa__ApprovalSnapshot__c WHERE Id = :snap.Id] == 0, 'Snapshot should be deleted');

        }

        Test.stopTest();

    }
}