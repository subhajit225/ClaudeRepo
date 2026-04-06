/**
 * An apex page controller that exposes the change password functionality
 */
@IsTest public with sharing class ChangePasswordControllerTest {
   	@IsTest(SeeAllData=true) public static void testChangePasswordController() {
        // Instantiate a new controller with all parameters in the page
        ChangePasswordController controller = new ChangePasswordController();
        controller.oldPassword = '123456';
        controller.newPassword = 'qwerty1';
        controller.verifyNewPassword = 'qwerty1';

        System.assertEquals(controller.changePassword(),null);
    }

    @IsTest
    static void testForwardToCustomPageEnabled() {
        Customer_Community_Tab_Settings__c settings = new Customer_Community_Tab_Settings__c(SetupOwnerId = UserInfo.getProfileId());
        settings.Forward_To_Custom_Start_Page__c = 'test';
        upsert settings;

        ChangePasswordController instance = new ChangePasswordController();
        System.assertNotEquals(null, instance.forwardToCustomPage());
    }

    @IsTest
    static void testForwardToCustomPageDisabled() {
        Customer_Community_Tab_Settings__c settings = new Customer_Community_Tab_Settings__c(SetupOwnerId = UserInfo.getProfileId());
        settings.Forward_To_Custom_Start_Page__c = null;
        upsert settings;

        ChangePasswordController instance = new ChangePasswordController();
        System.assertEquals(null, instance.forwardToCustomPage());
    }
}