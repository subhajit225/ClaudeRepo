/**
 * An apex page controller that exposes the change password functionality
 */
public with sharing class ChangePasswordController {
    public String oldPassword {get; set;}
    public String newPassword {get; set;}
    public String verifyNewPassword {get; set;}

    public PageReference changePassword() {
        return Site.changePassword(newPassword, verifyNewPassword, oldpassword);
    }

   	public ChangePasswordController() {}

    public PageReference forwardToCustomPage() {

        Customer_Community_Tab_Settings__c settings = Customer_Community_Tab_Settings__c.getInstance(UserInfo.getProfileId());
        if(settings != null && String.isNotBlank(settings.Forward_To_Custom_Start_Page__c)) {
            return new PageReference('/' + settings.Forward_To_Custom_Start_Page__c);
        }
        return null;
    }
}