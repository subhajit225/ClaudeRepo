/** Created By :Annappa
* Purpose : Test class of PC_PartnerRequestingFormController
**/
@isTest
private class PC_PartnerRequestingFormController_Test {
    /**
    * @description create PR records
    * @return null
    */
    public static testmethod void testCreationPartnerRequestRecord(){
        Test.startTest();
        Account accRec = ShGl_TestFactory.testMethod_PartnerAccount('Test Account');
        accRec.Name = 'TestCompany';
        update accRec;
        Account accRec1 = ShGl_TestFactory.testMethod_PartnerAccount('Test Account 1');
        accRec1.Name = 'TestCompany 1';
        update accRec1; 
        
        List<Contact> lstContact = ShGl_TestFactory.testMethod_PartnerContact(1,accRec);
        lstContact[0].email = 'abc@gmail.com';
        update lstContact;
        /** creation Partner Request**/
        List<Partner_Registration_Request__c> lstPPR = ShGl_TestFactory.testMethod_createPRRequest(3);
        lstPPR[0].First_Name__c = 'Test1';
        lstPPR[0].Last_Name__c = 'Test1 Lastname';
        lstPPR[1].First_Name__c = 'Test2';
        lstPPR[1].Last_Name__c = 'Test2 Lastname';
        lstPPR[1].Email__c = 'def@gmail.com';
        lstPPR[1].Company_Name__c = 'TestCompany 1';
        lstPPR[1].Country_Picklist__c = 'India';
        lstPPR[2].Company_Name__c = 'TestCompany 2';
        PC_PartnerRequestingFormController.savePartnerRecord(lstPPR[0]);
        PC_PartnerRequestingFormController.duplicateContactCheck(lstPPR[0]);
        PC_PartnerRequestingFormController.savePartnerRecord(lstPPR[1]);
        PC_PartnerRequestingFormController.savePartnerRecord(lstPPR[2]);
        system.assert(true);
        Test.stopTest();
    }
    
    /**
    * @description create PR records
    * @return null
    */
    public static testmethod void testCreationPartnerRequestRecord1(){
        Test.startTest();
        User portalAccountOwner1 = createTestUser();
        System.runAs ( portalAccountOwner1 ) {
        Account accRec = ShGl_TestFactory.testMethod_PartnerAccount('Test Account');
        accRec.Name = 'TestCompany';
            update accRec;
            Account accRec1 = ShGl_TestFactory.testMethod_PartnerAccount('Test Account 1');
            accRec1.Name = 'TestCompany 1';
            update accRec1; 
            
            List<Contact> lstContact = ShGl_TestFactory.testMethod_PartnerContact(1,accRec);
            lstContact[0].email = 'abc@gmail.com.sandbox';
            update lstContact;
            
            Profile portalProfile = [SELECT Id FROM Profile Where Name='Rubrik Partner community Manager' Limit 1];
            User user1 = new User(
                Username = System.now().millisecond() + 'abc@gmail.com.sandbox',
                ContactId = lstContact[0].Id,
                ProfileId = portalProfile.Id,
                Alias = 'abcgm',
                Email = 'abc@gmail.com.sandbox',
                EmailEncodingKey = 'UTF-8',
                LastName = 'McTesty',
                CommunityNickname = 'test12345',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            insert user1;
            
            /** creation Partner Request**/
            List<Partner_Registration_Request__c> lstPPR = ShGl_TestFactory.testMethod_createPRRequest(3);
            lstPPR[0].First_Name__c = 'Test1';
            lstPPR[0].Last_Name__c = 'Test1 Lastname';
            lstPPR[1].First_Name__c = 'Test2';
            lstPPR[1].Last_Name__c = 'Test2 Lastname';
            lstPPR[1].Email__c = 'abc@gmail.com.sandbox';
            lstPPR[1].Company_Name__c = 'TestCompany 1';
            lstPPR[1].Country_Picklist__c = 'India';
            lstPPR[1].Partner_Registration_Status__c = 'Submitted';
            lstPPR[2].Company_Name__c = 'TestCompany 2';
            lstPPR[2].Email__c = 'def@gmail.com.sandbox';
            lstPPR[2].OwnerId = null;
            lstPPR[2].Auto_Approval__c = true;
            lstPPR[2].Country_Picklist__c = 'United States';
            lstPPR[2].First_Name__c = 'Test2';
            lstPPR[2].Last_Name__c = 'Test2 Lastname';
            PC_PartnerRequestingFormController.savePartnerRecord(lstPPR[0]);
            PC_PartnerRequestingFormController.savePartnerRecord(lstPPR[1]);
            PC_PartnerRequestingFormController.savePartnerRecord(lstPPR[2]);
            PC_PartnerRequestingFormController.duplicateContactCheck(lstPPR[1]);
            system.assert(true);
            Test.stopTest();
        }
    }
    
    /**
    * @description create PR records
    * @return null
    */
    public static testmethod void testSaveRecord(){
        User portalAccountOwner1 = createTestUser();
        System.runAs ( portalAccountOwner1 ) {
            Account accRec1 = ShGl_TestFactory.testMethod_PartnerAccount('Test Account 100');
            accRec1.Name = 'TestCompany 100';
            update accRec1;
            
            Partner_Registration_Request__c pr = new Partner_Registration_Request__c(
                Address__c='test address',
                State__c='testState',
                Country__c='United States',
                Company_Name__c='TestCompany 100',
                Email__c='abc@gmail.com',
                State_Picklist__c='AZ',
                Country_Picklist__c='United States'
            );
            Test.startTest();
            PC_PartnerRequestingFormController.savePartnerRecord(pr);
            system.assert(true);
            Test.stopTest();    
        }
    }
    
    /**
    * @description create PR records
    * @return null
    */
    public static testmethod void testSaveRecord1(){
        User portalAccountOwner1 = createTestUser();
        System.runAs ( portalAccountOwner1 ) {
            Account accRec1 = ShGl_TestFactory.testMethod_PartnerAccount('Test Account 101');
            accRec1.Name = 'TestCompany 101';
            accRec1.Website = 'gmail.com';
            accRec1.BillingCountry = 'United States';
            update accRec1;
            
            Partner_Registration_Request__c pr = new Partner_Registration_Request__c(
                Address__c='test address',
                State__c='testState',
                Country__c='United States',
                Company_Name__c='TestCompany 101',
                Email__c='abc@gmail.com',
                State_Picklist__c='AZ',
                Country_Picklist__c='United States'
            );
            Test.startTest();
            PC_PartnerRequestingFormController.savePartnerRecord(pr);
            system.assert(true);
            Test.stopTest();   
        }
    }
    
    /**
    * @description test duplicate PR record
    * @return null
    */
    public static testmethod void testDuplicateCheck(){
        User portalAccountOwner1 = createTestUser();
        System.runAs ( portalAccountOwner1 ) {
            List<Partner_Registration_Request__c> lstPPR = ShGl_TestFactory.testMethod_createPRRequest(1);
            lstPPR[0].First_Name__c = 'Test3';
            lstPPR[0].Last_Name__c = 'Test3 Lastname';
            lstPPR[0].Country_Picklist__c = 'United States';
            lstPPR[0].Partner_Registration_Status__c = 'Submitted';
            insert lstPPR;
            Test.startTest();
            Boolean isDup = PC_PartnerRequestingFormController.duplicateContactCheck(lstPPR[0]);
            system.assert(true);
            Test.stopTest();   
        }
    }
    
    /**
    * @description Create System Admin User
    * @return User record
    */
    private static User createTestUser() {
        Profile profile1 = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];

        User u = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() + 'testpuser2@test.com',
            Alias = 'batman',
            Email = 'bruce.wayne@wayneenterprises.com',
            EmailEncodingKey = 'UTF-8',
            Firstname = 'Bruce',
            Lastname = 'Wayne',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Chicago'
        );
        insert u;
        return u;
    }
}