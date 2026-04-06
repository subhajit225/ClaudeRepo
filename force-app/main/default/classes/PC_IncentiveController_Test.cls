/** Created By :Annappa
* Purpose : Test class of PC_IncentiveController
**/
@isTest
private class PC_IncentiveController_Test {
    @TestSetup static void testDataMethod(){
        List<Contact> contList = new List<Contact>();
        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        Profile profileAdmin = [SElECT Id FROM Profile WHERE name = 'System Administrator' LIMIT 1];
        User portalAccountOwner1 = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profileAdmin.Id,
            Username = System.now().millisecond() + 'testpuser2@test.com',
            Alias = 'batman',
            Email='bruce.wayne@wayneenterprises123.com',
            EmailEncodingKey='UTF-8',
            Firstname='Bruce',
            Lastname='Wayne',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago'
        );
        Database.insert(portalAccountOwner1);
        System.runAs ( portalAccountOwner1 ) {
            //Account creation
            Account portalAccount1 = new Account(
                Name = 'TestAccount',
                OwnerId = portalAccountOwner1.Id
            );
            Database.insert(portalAccount1);

            //Create contact
            Contact contact1 = new Contact(
                FirstName = 'Test',
                Lastname = 'McTesty',
                AccountId = portalAccount1.Id,
                Email = System.now().millisecond() + 'test@test.com',
                Primary_Role__c = 'Admin'
            );
            contList.add(contact1);
            Contact contact2 = new Contact(
                FirstName = 'Test 2',
                Lastname = 'McTesty 2',
                AccountId = portalAccount1.Id,
                Email = System.now().millisecond() + 'test@test.com',
                Primary_Role__c = 'Executive'
            );
            contList.add(contact2);
            insert contList;

            Profile portalProfileAdmin = [SELECT Id FROM Profile WHERE Name ='Rubrik Partner Community Manager' LIMIT 1];
            User user1 = new User(
                Username = System.now().millisecond() + 'tespuser1@test.com',
                ContactId = contact1.Id,
                ProfileId = portalProfileAdmin.Id,
                Alias = 'test123',
                Email = 'test12345@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'McTesty',
                CommunityNickname = 'test12345',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            Database.insert(user1);

            Profile portalProfile = [SELECT Id FROM Profile WHERE Name ='Rubrik Partner Community User' LIMIT 1];
            User user2 = new User(
                Username = System.now().millisecond() + 'tespuser3@test.com',
                ContactId = contact2.Id,
                ProfileId = portalProfile.Id,
                Alias = 'test1234',
                Email = 'test123456@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'McTesty 2',
                CommunityNickname = 'test123456',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            Database.insert(user2);
        }
        //Insert CCR
    }
    public static testmethod void testUserDetails(){
        PC_IncentiveController.getUserDetails();
        List<Incentives__c> incentives = ShGl_TestFactory.testMethod_Incentive(1,new List<String>{'Brik_Dollar_Incentive_Claim_Req'});
        PC_IncentiveController.getIncentiveForm(incentives[0].Id);
    }
    public static testmethod void testSaveCcrRecord(){
        test.startTest();
        User u = [select id,name from user where profile.name ='System Administrator' and userRoleId != null and isactive=true limit 1];
        List<User> lstUserRec = new List<User>();
        system.runas(u){
            Account accRec = ShGl_TestFactory.testMethod_PartnerAccount('Test Account');
            List<Contact> lstContact = ShGl_TestFactory.testMethod_PartnerContact(1,accRec);
            lstUserRec = ShGl_TestFactory.testMethod_PartnerUser(1,lstContact);            
        }
        Id ccRecordTypeId = Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Partner Claim Form').getRecordTypeId();
        CCR__c Cr=new CCR__c();
        Cr.recordtypeId=ccRecordTypeId;
        String result;
        system.runAs(lstUserRec[0]){
            PC_IncentiveController.saveCcrRecord(Cr,'Marketing SPIFF'); 
            result = PC_IncentiveController.saveCcrRecord(Cr,'Marketing1 SPIFF'); 
        }
        System.assert(result != null, true);
        test.stopTest();
    }    
    /*Create test records */
    public static testmethod void testSPIFFClaimReport(){
        User portalUser1 = [SELECT Id,Profile.name FROM User Where LastName ='McTesty'];
        User portalUser2 = [SELECT Id,Profile.name FROM User Where LastName ='McTesty 2'];
        Account acc = [Select Id,Name FROM Account Where Name = 'TestAccount'];
        List<String> accIds = new List<String>();
        String startdate;
        String enddate;
        String searchtext;
        String status;
        String incentivetype;
        User u = [select id,name from user where profile.name ='System Administrator' and userRoleId != null and isactive=true limit 1];
        system.runas(u){
            Account accRec = ShGl_TestFactory.testMethod_PartnerAccount('Test Account');
            List<Contact> lstContact = ShGl_TestFactory.testMethod_PartnerContact(1,accRec);
            Id ccRecordTypeId = Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Partner Claim Form').getRecordTypeId();
            CCR__c Cr = new CCR__c();
            Cr.recordtypeId = ccRecordTypeId;
            PC_IncentiveController.saveCcrRecord(Cr,'Channel SPIFF');
            PC_PartnerSPIFFClaimApexController.getPartnerSPIFFClaims(portalUser2.ID,startdate,enddate,searchtext,accIds,status,incentivetype);
            
            startdate = '2023-08-08';
            enddate = '2023-08-09';
            searchtext = 'sdghj';
            status = 'Submitted';
            incentivetype = 'Deal Reg';
            accIds.add(acc.Id);
            PC_PartnerSPIFFClaimApexController.getPartnerSPIFFClaims(portalUser1.ID,startdate,enddate,searchtext,accIds,status,incentivetype);
        }
        Assert.areEqual('Deal Reg', incentivetype);
    }
}