@IsTest global with sharing class AccountServiceControllerTest {
    @testSetup static void setup() {
        Account rbkAcc = new Account(Name='Rubrik');
        insert rbkAcc;
        testDataFactoryClass.createUser();
        testDataFactoryClass.createCustomSettings();
        testDataFactoryClass.createContactWithUserLogin(5);
        List<Account> accList = [select id,recordtypeId from account];
        /*Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();

        for(Account ac : accList){
            ac.recordtypeId = partner;
        }
        update accList;*/
    }

    @isTest static void testMethodAcounts() {
        Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        List<Account> accList = [select id,Partner_Agreement_Status__c,recordtypeId from account];
        
        for(Account ac : accList){
            ac.recordtypeId = partner;
            ac.Partner_Agreement_Status__c = '';
        }
        update accList;
        RubrikCommunityLoginController controller = new RubrikCommunityLoginController ();
        controller.username = 'testuser@testuser4.com';
        controller.password = '123456';
        System.assertEquals(controller.login(),null);
        
        for(Account ac1 : accList){
            ac1.recordtypeId = partner;
            ac1.Partner_Agreement_Status__c = 'Signed - Inactive';
        }
        update accList;
        controller = new RubrikCommunityLoginController ();
        controller.username = 'testuser@testuser4.com';
        controller.password = '123456';
        System.assertEquals(controller.login(),null);
        
        for(Account ac2 : accList){
            ac2.recordtypeId = partner;
            ac2.Partner_Agreement_Status__c = 'Terminated';
        }
        update accList;
        controller = new RubrikCommunityLoginController ();
        controller.username = 'testuser@testuser4.com';
        controller.password = '123456';
        System.assertEquals(controller.login(),null);
    }

    @isTest static void testMethod1() {
        // Instantiate a new controller with all parameters in the page
        test.startTest();
        RubrikCommunityLoginController controller = new RubrikCommunityLoginController ();
        controller.username = 'testuser@testuser2.com';
        controller.password = '123456';

        System.assertEquals(controller.login(),null);
        test.stopTest();
    }

    @isTest static void testMethod2() {
        // Instantiate a new controller with all parameters in the page
        test.startTest();
        RubrikCommunityLoginController controller = new RubrikCommunityLoginController ();
        controller.username = 'testuser@testuser4.com';
        controller.password = '123456';
        ForgotPasswordController fp = new ForgotPasswordController();
        fp.username = 'testuser@testuser4.com';
        fp.forgotCustomerPassword();
        System.assertEquals(controller.login(),null);
        test.stopTest();

    }
    @isTest static void testMethod3() {
        // Instantiate a new controller with all parameters in the page
        test.startTest();
        RubrikCommunityLoginController controller = new RubrikCommunityLoginController ();
        controller.username = 'testuser@testuser5.com';
        controller.password = '123456';

        System.assertEquals(controller.login(),null);
        test.stopTest();
    }

     @isTest static void testMethod4() {
        // Instantiate a new controller with all parameters in the page
        test.startTest();
        RubrikCommunityLoginController controller = new RubrikCommunityLoginController ();
        controller.username = 'testuser@testuser6.com';
        controller.password = '123456';

        System.assertEquals(controller.login(),null);
        test.stopTest();

    }
    @isTest static void testMethod5() {
        // Instantiate a new controller with all parameters in the page
        test.startTest();
        RubrikCommunityLoginController controller = new RubrikCommunityLoginController ();
        controller.username = 'testuser@testuser7.com';
        controller.password = '123456';

        System.assertEquals(controller.login(),null);
        test.stopTest();
    }

    // @IsTest
    // static void testLoginWithInvalidCredentials() {
    //     String userName = 'xxxxx';
    //     String password = 'xxxxx';

    //     RubrikCommunityLoginController.login(userName, password, null);
    //     RubrikCommunityLoginController.login(userName, password, null);
    //     System.assertEquals(Label.S_R_Incorrect_UsernamePassword, RubrikCommunityLoginController.login(userName, password, null));
    // }

    @IsTest
    static void LightningLoginFormControllerInstantiation() {
        RubrikCommunityLoginController controller = new RubrikCommunityLoginController();

        RubrikCommunityLoginController.setExperienceId('123');
        RubrikCommunityLoginController.setExperienceId(null);
        //RubrikCommunityLoginController.getForgotPasswordUrl();
        System.assertNotEquals(controller, null);
    }

    @IsTest
    static void testIsUsernamePasswordEnabled() {
        //System.assertEquals(true, RubrikCommunityLoginController.getIsUsernamePasswordEnabled());
    }

    @IsTest
    static void testIsSelfRegistrationEnabled() {
        System.assertEquals(false, RubrikCommunityLoginController.getIsSelfRegistrationEnabled());
    }

    @IsTest
    static void testGetSelfRegistrationURL() {
        System.assertEquals(null, RubrikCommunityLoginController.getSelfRegistrationUrl());
    }

    @isTest static void testMethodAcount() {
        Map<id,String> domainMap = new Map<Id,String>();
        
        for(Account actList : testDataFactoryClass.createAccount(1,0)){
            domainMap.put(actList.id, 'test.com');
        }
        // AccountServiceController.createDomain(domainMap);
        AccountServiceController.createNewDomain(domainMap, false);
    }

    @IsTest
    static void testAuthConfig() {
        Auth.AuthConfiguration authConfig = RubrikCommunityLoginController.getAuthConfig();
        System.assertNotEquals(null, authConfig);
    }
}