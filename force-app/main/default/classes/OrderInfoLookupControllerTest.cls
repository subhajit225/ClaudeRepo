@isTest
private class OrderInfoLookupControllerTest {

    @isTest
    static void test_search_orders() {

        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];

        Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
        User portalAccountOwner1 = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() + 'portalAccountOwner1@randomtestdomain.com',
            Alias = 'batman',
            Email = System.now().millisecond() + 'random.email@randomtestdomain.com',
            EmailEncodingKey = 'UTF-8',
            Firstname = 'test',
            Lastname = 'test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Chicago'
        );
        Database.insert(portalAccountOwner1);

        Account portalAccount1;
        User portalUser;

        System.runAs(portalAccountOwner1) {
            //Create account
            portalAccount1 = new Account(
                Name = 'TestAccount',
                OwnerId = portalAccountOwner1.Id
            );
            Database.insert(portalAccount1);

            //Create contact
            Contact contact1 = new Contact(
                FirstName = 'Test',
                Lastname = 'McTesty',
                AccountId = portalAccount1.Id,
                Email = System.now().millisecond() + 'test@test.com'
            );
            Database.insert(contact1);

            //Create user
            Profile portalProfile = [SELECT Id FROM Profile Where UserType = 'PowerPartner' Limit 1];
            portalUser = new User(
                Username = System.now().millisecond() + 'test12345@test.com',
                ContactId = contact1.Id,
                ProfileId = portalProfile.Id,
                Alias = 'test123',
                Email = System.now().millisecond() + 'test12345@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'McTesty',
                CommunityNickname = 'test12345',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            Database.insert(portalUser);
        }

        Integer testSize = 10;

        System.runAs(portalAccountOwner1) {
            TriggerControl__c setting = new TriggerControl__c();
            setting.Name = 'Opportunity';
            setting.DisableTrigger__c = False;
            insert setting;

            Account acct = new Account(Name = 'testAccount');
            insert acct;

            Order ordr = new Order(
                Type = 'Revenue',
                AccountId = acct.Id,
                Bill_To_Name__c = portalAccount1.Id,
                EffectiveDate = System.Today(),
                //Status = 'Pending',
                Order_Status__c = 'Pending'
            );

            List<Order> orderList = new List<Order>();

            for(Integer i = 0; i < testSize; i++) {
                Order ol = ordr.clone();
                ol.PO_Number__c = 'test10' + i;
                ol.End_User_PO__c = 'test30' + i;
                orderList.add(ol);
            }
            insert orderList;
        }

        Test.startTest();
        System.runAs(portalUser){

            OrderInfoLookupController instance = new OrderInfoLookupController();
            instance.poNumber = 'test';
            instance.orderNumber = 'test';
            instance.endUserPo = 'test';

            System.assertEquals(testSize, instance.orders.size());

            instance.pageSize = testSize/2;
            instance.refreshPageSize();

            System.assertEquals(testSize/2, instance.orders.size());

            instance.apply();
            instance.doNext();
            instance.doPrevious();

        }
        Test.stopTest();

    }

    /* RubrikTests.test_CommunityHomeController */
    @isTest(SeeAllData=true)
    static void test_CommunityHomeController() {

        CommunityHomeController hp = new CommunityHomeController();

        hp.getTopSolutions();
        hp.getNewArticles();
        hp.getPortalNews();
        hp.getRankedSolutions();

    }

    /* RubrikTests.test_CommunityHomeController */
    @IsTest
    static void testForwardToCustomPageEnabled() {
        Customer_Community_Tab_Settings__c settings = new Customer_Community_Tab_Settings__c(SetupOwnerId = UserInfo.getProfileId());
        settings.Forward_To_Custom_Start_Page__c = 'test';
        upsert settings;

        CommunityHomeController instance = new CommunityHomeController();
        System.assertNotEquals(null, instance.forwardToCustomPage());
    }

    /* RubrikTests.test_CommunityHomeController */
    @IsTest
    static void testForwardToCustomPageDisabled() {
        Customer_Community_Tab_Settings__c settings = new Customer_Community_Tab_Settings__c(SetupOwnerId = UserInfo.getProfileId());
        settings.Forward_To_Custom_Start_Page__c = null;
        upsert settings;

        CommunityHomeController instance = new CommunityHomeController();
        System.assertEquals(null, instance.forwardToCustomPage());
    }
}