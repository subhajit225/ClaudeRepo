@isTest
private class PC_TilesInformation_Test {
    public static testmethod void testPatnerRep(){
        test.startTest();
        List<User> urRec = ShGl_TestFactory.testMethod_createUser(1);
        System.runas(urRec[0]) {
            List<String> lstEmail = new List<String>();
            lstEmail.add(urRec[0].email);
            List<CCR__c> lsrCCR = ShGl_TestFactory.testMethod_createCCR(1,lstEmail);
            lsrCCR[0].Partner_SE_Email__c  = urRec[0].email;
            lsrCCR[0].Partner_SE_Amount__c=100;
            update lsrCCR;
            PC_TilesInformation.claimDetails();
        }
        test.stopTest();
    }
}