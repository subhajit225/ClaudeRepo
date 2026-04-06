@IsTest global with sharing class RubrikCommunityLoginControllerTest {
    
    @testSetup static void setup() {
        OktaUserUtilityTest.oktaCustomSettingsParams();
        Account rbkAcc = new Account(Name='Rubrik');
        insert rbkAcc;
        testDataFactoryClass.createUser();
        testDataFactoryClass.createCustomSettings();
        testDataFactoryClass.createContactWithUserLogin(5);
    }
    @isTest static void testMethodAcounts() {
        List<Account> accList = [select id,recordtypeId from account];
        Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer/Prospect').getRecordTypeId();
        for(Account ac : accList){
            ac.recordtypeId = partner;
        }
        update accList;
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
    @IsTest
    static void testLoginWithInvalidCredentials() {
        String userName = 'xwRzVIRZnaP9Ou8v1lhwwQ==';
        String password = 'qIJWZ+QowvLcaKpEnMKKNQ==ref;2#beb31bc24b318c24';

        RubrikCommunityLoginController.login(userName, password, null);
        RubrikCommunityLoginController.login(userName, password, null);
        System.assertEquals(Label.S_R_Incorrect_UsernamePassword, RubrikCommunityLoginController.login(userName, password, null));
    }
    
    @IsTest
    static void LightningLoginFormControllerInstantiation() {
        RubrikCommunityLoginController controller = new RubrikCommunityLoginController();
        
        RubrikCommunityLoginController.setExperienceId('123');
        RubrikCommunityLoginController.setExperienceId(null);
        RubrikCommunityLoginController.getForgotPasswordUrl();
        System.assertNotEquals(controller, null);
    }
    
    @IsTest
    static void testIsUsernamePasswordEnabled() {
        Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
            if(isSandbox) {
                System.assertEquals(true, RubrikCommunityLoginController.getIsUsernamePasswordEnabled());
            }else{
                System.assertEquals(false, RubrikCommunityLoginController.getIsUsernamePasswordEnabled());
            }
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
            domainMap.put(actList.id,'test.com');
        }
        AccountServiceController.createNewDomain(domainMap, false);
        AccountServiceController.createNewDomain(domainMap, false);
    }
    
    @IsTest
    static void testAuthConfig() {
        Auth.AuthConfiguration authConfig = RubrikCommunityLoginController.getAuthConfig();
        System.assertNotEquals(null, authConfig);
    }
    
    @isTest
    static void testGetOktaAttributes_Sandbox() {
        Test.startTest();
        Okta_Attributes__c result = RubrikCommunityLoginController.getOktaAttributes(); 

        System.assertNotEquals(null, result);
        Test.stopTest();
    }
}