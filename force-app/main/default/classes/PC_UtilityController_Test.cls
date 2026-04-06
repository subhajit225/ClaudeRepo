@isTest
private class PC_UtilityController_Test {
    public static testmethod void testRecordType(){
        test.startTest();
        PC_UtilityController.getRecordType('Account','Partner_Distributor');
        PC_UtilityController.getUserDetails();
        test.stopTest();
    }
}