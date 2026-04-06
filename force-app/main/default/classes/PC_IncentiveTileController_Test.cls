@isTest
private class PC_IncentiveTileController_Test {
    public static testmethod void testincentiveDetails(){
        test.startTest();
        User u = [select id,name from user where profile.name ='System Administrator' and userRoleId != null and isactive=true limit 1];
        List<User> lstUserRec = new List<User>();
        system.runas(u){
            Account accRec = ShGl_TestFactory.testMethod_PartnerAccount('Test Account');
            List<Contact> lstContact = ShGl_TestFactory.testMethod_PartnerContact(1,accRec);
            lstUserRec = ShGl_TestFactory.testMethod_PartnerUser(1,lstContact);
            List<String> lstCCRType= new List<String>();
            lstCCRType.add('Brik_Dollar_Incentive_Claim_Req');
            List<Incentives__c> lstIncentive = ShGl_TestFactory.testMethod_Incentive(1,lstCCRType);
            PC_IncentiveTileController.fetchIncentiveDetails();
        }
        test.stopTest();
    }
}