@isTest
/** 
* Purpose : Test class of PC_DealRegTableController
**/
private class PC_DealRegTableController_Test {
    
    @testSetup
    static void setupTestData() {
        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        Profile adminProf = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'Rubrik Partner community Manager' LIMIT 1];

        User portalAccountOwner = new User(
            UserRoleId = portalRole.Id,
            ProfileId = adminProf.Id,
            Username = System.now().millisecond() + 'testpuser2@test.com',
            Alias = 'batman',
            Email='bruce.wayne@wayneenterprises.com',
            EmailEncodingKey='UTF-8',
            Firstname='Bruce',
            Lastname='Wayne',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago'
        );
        insert portalAccountOwner;

        System.runAs(portalAccountOwner) {
            Account portalAccount = new Account(Name = 'TestAccount', Type = 'MSP');
            insert portalAccount;

            Contact contact = new Contact(
                FirstName = 'Test',
                LastName = 'McTesty',
                AccountId = portalAccount.Id,
                Email = System.now().millisecond() + 'test@test.com',
                Primary_Role__c = 'Admin'
            );
            insert contact;

            User user = new User(
                Username = System.now().millisecond() + 'tespuser1@test.com',
                ContactId = contact.Id,
                ProfileId = portalProfile.Id,
                Alias = 'test123',
                Email = 'test12345@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'McTesty',
                CommunityNickname = 'test12345',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            insert user;

            PatchManager__c pm = new PatchManager__c(
                RecordTypeId = Schema.SObjectType.PatchManager__c.getRecordTypeInfosByName().get('Geographic').getRecordTypeId(),
                CDM__c = user.Id,
                SDR__c = user.Id,
                AccountExecutive__c = user.Id,
                CountryGlobal__c = 'United States',
                City__c = 'City',
                State__c = 'AK',
                StateGlobal__c = 'AK',
                Zip_code__c = '421302'
            );
            insert pm;
        }
    }
    
    @isTest
    static void testMethod1() {
        Test.startTest();
        PatchManager__c pm = [Select Id, RecordTypeId, CDM__c from PatchManager__c LIMIT 1];
        Account portalAccount = [Select Id, Type from Account LIMIT 1];
        User portalUser = [Select Id, Name, ContactId, Contact.AccountId from User Where Email = 'test12345@test.com'];
        System.runAs ( portalUser ) {
                
                Deal_Registration__c deal=TestDataFactory.getDealRegistration();
                deal.Deal_Registration_Status__c = 'Submitted';
                deal.Deal_Reg_Submitted_Date__c = System.today();
                deal.Primary__c = false;
                deal.Partner_Lookup__c = portalAccount.Id;
                deal.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
                insert deal;
                
                Deal_Registration__c deal1 = TestDataFactory.getDealRegistration();
                deal1.Deal_Registration_Status__c = 'Submitted';
                deal1.Deal_Reg_Submitted_Date__c = System.today();
                deal1.Primary__c = false;
                deal1.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByDeveloperName().get('Engagement').getRecordTypeId();
                deal1.Partner_Lookup__c = portalAccount.Id;
                insert deal1;
                
                string returnFields = 'Id,Company__c,Name,FirstName__c,LastName__c,Deal_Registration_Status__c,Deal_Reg_Exp_Date__c,recordType.Name, Partner_lookup__c';
                List<string> IdSet;
                List<sobject> records =  PC_DealRegTableController.getRecords('',returnFields,'Deal_Registration__c',0,'','','', IdSet, String.valueOf(system.today()), String.valueOf(system.today() + 1), null);
                List<FiscalYearSettings> fisList = PC_DealRegTableController.getFiscalYearData();
                PC_DealRegTableController.DealRegWrapper wrap = PC_DealRegTableController.getDealRegData();
                List<Deal_Registration__c> wrap1 = PC_DealRegTableController.getDealRegEngagementRecords('');
                List<Deal_Registration__c> wrap3 = PC_DealRegTableController.getDealRegEngagementRecords('Test');
                system.assertNotEquals(deal.Id, null);
            }
            portalAccount.Type = '';
            update portalAccount;
            System.runAs ( portalUser ) {
                List<Deal_Registration__c> wrap2 = PC_DealRegTableController.getDealRegEngagementRecords('');
                List<Deal_Registration__c> errorWrap = PC_DealRegTableController.getDealRegEngagementRecords( null);
            }
        
        Test.stoptest();
    }
    
    @isTest
    static void testMethod2() {
        Test.startTest();
        PatchManager__c pm = [Select Id, RecordTypeId, CDM__c from PatchManager__c LIMIT 1];
        Account portalAccount = [Select Id, Type from Account LIMIT 1];
        User portalUser = [Select Id, Name, ContactId, Contact.AccountId from User Where Email = 'test12345@test.com'];
        portalAccount.Type = 'Distributor';
        update portalAccount;
        System.runAs ( portalUser ) {
            Deal_Registration__c deal=TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Status__c = 'Submitted';
            deal.Deal_Reg_Submitted_Date__c = System.today();
            deal.Primary__c = false;
            deal.Partner_Lookup__c = portalAccount.Id;
            deal.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            insert deal;
            PC_DealRegTableController.DealRegWrapper wrap = PC_DealRegTableController.getDealRegData();
            system.assertNotEquals(deal.Id, null);
        }
        Test.stoptest();
    }
    
    @isTest static void testMethod3() {
        Test.startTest();
        List<Deal_Registration__c> lstDR =ShGl_TestFactory.testMethod_createDealRegistration(2);
        string returnFields = 'Id,Company__c,Name,FirstName__c,LastName__c,Deal_Registration_Status__c,Deal_Reg_Exp_Date__c';
        string objType = 'Deal_Registration__c';
        Integer pageSize;
        string fieldapiName = 'Name';
        string sortedDirection = 'desc';
        String sortedByValue = 'fn1';
        string direction = '';
        List<string> IdSet = new List<string>();
        IdSet.add(lstDR[0].Id);     
        List<sobject> records =  PC_DealRegTableController.getRecords('fn',returnFields,objType,pageSize,fieldapiName,sortedDirection,sortedByValue, IdSet, String.valueOf(system.today()), String.valueOf(system.today() + 1), null);
        List<sobject> records2 =  PC_DealRegTableController.getRecords('fn',returnFields,objType,pageSize,fieldapiName,'asc',sortedByValue, IdSet, String.valueOf(system.today()), String.valueOf(system.today() + 1), null);
        Integer totalsize = PC_DealRegTableController.getTotalRecords(objType);
        system.assertEquals(totalsize, 2);
        Test.stoptest();
    }
    @isTest static void testMethod4() {
        Test.startTest();
        List<Deal_Registration__c> lstDR =ShGl_TestFactory.testMethod_createDealRegistration(2);
        string returnFields = 'Id,Company__c,Name,FirstName__c,LastName__c,Deal_Registration_Status__c,Deal_Reg_Exp_Date__c';
        string objType = 'Deal_Registration__c';
        Integer pageSize;
        string fieldapiName = 'Deal_Reg_Exp_Date__c';
        string sortedDirection = 'asc';
        String sortedByValue = '11-11-2018';
        string direction = '';
        List<string> IdSet = new List<string>();
        IdSet.add(lstDR[0].Id);
        List<sobject> records =  PC_DealRegTableController.getRecords('',returnFields,objType,pageSize,fieldapiName,sortedDirection,sortedByValue, IdSet, String.valueOf(system.today()), String.valueOf(system.today() + 1), null);
        List<sobject> records2 =  PC_DealRegTableController.getRecords('fn',returnFields,objType,pageSize,fieldapiName,sortedDirection,sortedByValue, IdSet, String.valueOf(system.today()), String.valueOf(system.today() + 1), null);
        List<sobject> records3 =  PC_DealRegTableController.getRecords('',returnFields,objType,pageSize,fieldapiName,'desc',sortedByValue, IdSet, String.valueOf(system.today()), String.valueOf(system.today() + 1), null);
        List<sobject> records4 =  PC_DealRegTableController.getRecords('fn',returnFields,objType,pageSize,fieldapiName,'desc',sortedByValue, IdSet, String.valueOf(system.today()), String.valueOf(system.today() + 1), null);
        system.assertNotEquals(lstDR[0].Id, null);
        Test.stoptest();
    }
    @isTest static void testMethod5() {
        Test.startTest();
        List<Deal_Registration__c> lstDR =ShGl_TestFactory.testMethod_createDealRegistration(1);
        PC_DealRegTableController.checkAccess(lstDR[0].Id);
        Test.stopTest();
    }
    @isTest static void testMethod6() {
        Test.startTest();
        List<Deal_Registration__c> lstDR =ShGl_TestFactory.testMethod_createDealRegistration(1);
        PC_DealRegTableController.getPartnerType();
        Test.stopTest();
    }
   
}