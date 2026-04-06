/**
 * An apex page controller that exposes the site forgot password functionality
 */
public without sharing class ForgotPasswordController {
    public String username {get; set;}
    public String email {get; set;}
    public string msgInfo{get;set;}
    public string jsScript{get;set;}
    public Boolean logRedirect{get;set;}
    
    
    
    public void callJS(){
       jsScript = '<script> callModal(); </script>';
    }

    public ForgotPasswordController() {}

    public PageReference forgotPassword() {
        boolean success = Site.forgotPassword(username);
        PageReference pr = Page.ForgotPasswordConfirm;
        pr.setRedirect(true);

        if (success) {
            return pr;
        }
        return null;
    }
    public PageReference forgotPartnerPassword() {

        List<User> userName = [SELECT username FROM User WHERE Email = :username AND ProfileId = '00e40000001FaR0AAK' AND isActive = true limit 1];
        String result = (userName.isEmpty()) ? null : userName.get(0).username;

        boolean success = Site.forgotPassword(result);
        PageReference pr = Page.ForgotPasswordConfirm;
        pr.setRedirect(true);

        if (success) {
            return pr;
        }
        return null;
    }
    public PageReference forgotCustomerPassword() {
        logRedirect = false;
        PageReference p;
        Map<id,UserLicense> licenseMap = new Map<id,UserLicense>([select id,name from UserLicense WHERE NAME LIKE '%Customer Community%']);
        List<User> userName = [SELECT id,FirstName,lastName,email,phone,title,isActive,Contact.AccountId,ContactId,username FROM User WHERE Email = :username AND Profile.UserLicenseID IN: licenseMap.keyset() AND isActive = true limit 1];
        //Change Starts here
        if(!userName.isEmpty()){
            p = null;
            }
        else{
            logRedirect = true;
            msgInfo = Label.S_R_Wrong_Email;
            callJS();
            p = null;
        }
        return p;
    }

    public PageReference forwardToCustomPage() {
		PageReference p = null;
        Customer_Community_Tab_Settings__c settings = Customer_Community_Tab_Settings__c.getInstance(UserInfo.getProfileId());
        if(settings != null && String.isNotBlank(settings.Forward_To_Custom_Start_Page__c)) {
            p = new PageReference('/' + settings.Forward_To_Custom_Start_Page__c);
        }
        return p;
    }
}