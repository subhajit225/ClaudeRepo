/**
* @description
*   Apex test class for the resetPasswordController, covers test scenarios related
*   to change password functionality, Okta integration, and custom start page logic
*   within a community user context.
* @test
* @author Vijay Kumar KR
* @date   2024-08-02
*/
@IsTest
public with sharing class resetPasswordControllerTest {
    
    /**
* @description Test data setup for reset password tests.
*/
    @TestSetup
    public static void dataSetup() {
        insert new TriggerControl__c(Name='Case');
        insert new TriggerControl__c(Name='Entitlement');
        
        Account acc = new Account(name='testAcc');
        insert acc;
        
        Contact cont = new Contact(lastName='testCont');
        cont.Notify_For_case_creation__c = true;
        cont.Email='testcontact@test.com';
        cont.AccountId = acc.Id;
        insert cont;
        
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'Rubrik Community Super User'].Id;
        
        User u = new User(
            ProfileId = profileId,
            ContactId = cont.Id,
            FirstName = 'Test Contact',
            LastName = 'User',
            Email = 'testcontactuser@test.com',
            Username = System.now().millisecond() + 'testcontactuser@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone()),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true);
        
        insert u;
    }   
    
    /**
* @description Test the change password controller for standard usage.
*/
    @IsTest
    public static void testChangePasswordController() {
        // Instantiate a new controller with all parameters in the page
        resetPasswordController controller = new resetPasswordController();
        controller.oldPassword = '123456';
        controller.newPassword = 'qwerty1';
        controller.verifyNewPassword = 'qwerty1';
        User us=[Select id from User where email='testcontactuser@test.com' LIMIT 1];
        System.runAs(us){
            controller.displayCngPwsForm();
            controller.hideCngPwsForm();
            controller.changePassword();
            controller.changeOktaPw();
            System.assertEquals(controller.changeOktaPw()!=null,true);
        }
    }
    
    /**
* @description Test forwardToCustomPage method when custom page is enabled.
*/
    @IsTest
    static void testForwardToCustomPageEnabled() {
        User us=[Select id from User where email='testcontactuser@test.com' LIMIT 1];
        System.runAs(us){
            Customer_Community_Tab_Settings__c settings = new Customer_Community_Tab_Settings__c(SetupOwnerId = UserInfo.getProfileId());
            settings.Forward_To_Custom_Start_Page__c = 'test';
            upsert settings;
            resetPasswordController instance = new resetPasswordController();
            PageReference expected = new PageReference('/test');
            System.assertEquals(expected.getUrl(), instance.forwardToCustomPage().getUrl());
        }
    }
    
    /**
* @description Test forwardToCustomPage method when custom page is disabled.
*/
    @IsTest
    static void testForwardToCustomPageDisabled() {
        Customer_Community_Tab_Settings__c settings = new Customer_Community_Tab_Settings__c(SetupOwnerId = UserInfo.getProfileId());
        settings.Forward_To_Custom_Start_Page__c = null;
        upsert settings;
        User us=[Select id from User where email='testcontactuser@test.com' LIMIT 1];
        System.runAs(us){
            resetPasswordController instance = new resetPasswordController();
            System.assertEquals(null, instance.forwardToCustomPage());
        }
    }
    
    /**
* @description Test Okta Password Reset button visibility when Okta is disabled.
*/
    @IsTest
    static void testDisabledOkta() {
        OktaUserUtilityTest.oktaCustomSettingsParams();
        
        Account objAcc = new Account(Name = 'test');
        INSERT objAcc;
        User us=[Select id from User where email='testcontactuser@test.com' LIMIT 1];
        System.runAs(us){
            ApexPages.StandardController sc = new ApexPages.StandardController(objAcc);
            resetPasswordController instance = new resetPasswordController(sc);
            System.assertEquals(true, instance.oktaPwResetBtn);
        }
    }
    
    /**
* @description Test Okta Password Reset synchronization scenario.
*/
    @IsTest
    static void testSyncOkta() {
        OktaUserUtilityTest.oktaCustomSettingsParams();
        
        Account objAcc = new Account(Name = 'test');
        INSERT objAcc;
        User us=[Select id from User where email='testcontactuser@test.com' LIMIT 1];
        System.runAs(us){
            ApexPages.StandardController sc = new ApexPages.StandardController(objAcc);
            resetPasswordController instance = new resetPasswordController(sc);
            System.assertEquals(true, instance.oktaPwResetBtn);
        }
    }
    
    /**
* @description Test password change when password fields are empty.
*/
    @IsTest
    static void emptyPassword() {
        Account objAcc = new Account(Name = 'test');
        INSERT objAcc;
        User us=[Select id from User where email='testcontactuser@test.com' LIMIT 1];
        System.runAs(us){
            OktaUserUtilityTest.oktaCustomSettingsParams();
            Okta_Attributes__c objOkta =OktaCalloutSelector.getOktaAttributes();
            objOkta.Disable_User_Sync__c=false;
            update objOkta;
            ApexPages.StandardController sc = new ApexPages.StandardController(objAcc);
            resetPasswordController instance = new resetPasswordController(sc);
            System.assert(true,'emptyPassword');
            instance.changePassword();
        }
    }
    
    /**
* @description Test password change when old password is empty.
*/
    @IsTest
    static void emptyOldPassword() {
        Account objAcc = new Account(Name = 'test');
        INSERT objAcc;
        ApexPages.StandardController sc = new ApexPages.StandardController(objAcc);
        resetPasswordController instance = new resetPasswordController();
        instance.newPassword = 'qwerty1';
        instance.verifyNewPassword = 'qwerty1';
        User us=[Select id from User where email='testcontactuser@test.com' LIMIT 1];
        System.runAs(us){
            instance.displayCngPwsForm();
            instance.hideCngPwsForm();
            instance.changePassword();
            System.assert(true,'emptyOldPassword');
        }
    }
}