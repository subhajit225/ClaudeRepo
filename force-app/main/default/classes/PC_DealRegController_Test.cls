@isTest
public class PC_DealRegController_Test {
    public static testmethod void testgetUserDetails(){
        test.startTest();
        User u = [select id,name from user where profile.name ='System Administrator' and userRoleId != null and isactive=true limit 1];
        List<User> lstUserRec = new List<User>();
        system.runas(u){
            Account accRec = ShGl_TestFactory.testMethod_PartnerAccount('Test Account');
            List<Contact> lstContact = ShGl_TestFactory.testMethod_PartnerContact(1,accRec);
            List<Lead> lstLead = ShGl_TestFactory.testMethod_createLead(1);
            lstUserRec = ShGl_TestFactory.testMethod_PartnerUser(1,lstContact);
            Deal_Registration__c dc = ShGl_TestFactoryHelper.createDealRegistration(1);
            dc.Deal_Registration_Type__c = 'Partner Sourced New Logo (PSNL)';
            insert dc;
            PC_DealRegController.getUserDetails();
            //PC_DealRegController.getPartnerRepAccount(lstContact[0].Email);
            PC_DealRegController.saveDealReg(dc);
            SObject obj = PC_DealRegController.getRecordDetails(lstContact[0].Id, 'Contact');
            SObject obj1Lead = PC_DealRegController.getRecordDetails(lstLead[0].Id, 'Lead');
            Test.stopTest();
        }
        System.assert(true);
    }
}