@isTest
private class requestToInformationControllerTest {

    @isTest
    static void fetchApprovalTest() {
        TestDataFactory.setTriggerSwitch('Approval', false);
        sbaa__Approval__c objApproval = new sbaa__Approval__c();
        objApproval.sbaa__RecordField__c = 'Quote__c';
        objApproval.sbaa__ApprovalStep__c = 1;
        objApproval.sbaa__Status__c = 'Requested';
        insert objApproval;
        Test.startTest();
        system.assert(objApproval!=null);
        requestToInformationController.fetchApprovalRecord(String.valueOf(objApproval.Id));
        Test.stopTest();
    }
}