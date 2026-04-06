@isTest
private class PC_ProfileController_Test {
    public static testmethod void testgetUserDetails(){
        test.startTest();
        User u = [select id,name from user where profile.name ='System Administrator' and userRoleId != null and isactive=true limit 1];
        List<User> lstUserRec = new List<User>();
        system.runas(u){
            Account accRec = ShGl_TestFactory.testMethod_PartnerAccount('Test Account');
            List<Contact> lstContact = ShGl_TestFactory.testMethod_PartnerContact(1,accRec);
            lstUserRec = ShGl_TestFactory.testMethod_PartnerUser(1,lstContact);
        }
        PC_ProfileController.getUserDetails();
        test.stopTest();
    }
}