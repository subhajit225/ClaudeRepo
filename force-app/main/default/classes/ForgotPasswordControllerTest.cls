/**
 * An apex page controller that exposes the site forgot password functionality
 */
@IsTest public with sharing class ForgotPasswordControllerTest {
  	 @IsTest(SeeAllData=true) public static void testForgotPasswordController() {
    	// Instantiate a new controller with all parameters in the page
    	ForgotPasswordController controller = new ForgotPasswordController();
    	controller.username = 'test@salesforce.com';

    	System.assertEquals(controller.forgotPassword(),null);
        System.assertEquals(controller.forgotPartnerPassword(),null);
        System.assertEquals(controller.forgotCustomerPassword(),null);

    }

    @IsTest
    static void testForwardToCustomPageEnabled() {
        Customer_Community_Tab_Settings__c settings = new Customer_Community_Tab_Settings__c(SetupOwnerId = UserInfo.getProfileId());
        settings.Forward_To_Custom_Start_Page__c = 'test';
        upsert settings;

        ForgotPasswordController instance = new ForgotPasswordController();
        System.assertNotEquals(null, instance.forwardToCustomPage());
    }

    @IsTest
    static void testForwardToCustomPageDisabled() {
        Customer_Community_Tab_Settings__c settings = new Customer_Community_Tab_Settings__c(SetupOwnerId = UserInfo.getProfileId());
        settings.Forward_To_Custom_Start_Page__c = null;
        upsert settings;

        ForgotPasswordController instance = new ForgotPasswordController();
        System.assertEquals(null, instance.forwardToCustomPage());
    }
    
}