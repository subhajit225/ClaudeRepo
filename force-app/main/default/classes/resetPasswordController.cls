/**
 * @Author      : 
 * @CreatedDate : 
 * @TstClass    : resetPasswordControllerTest
 * @Description : An apex page controller that exposes the change password functionality
 * -------------------------- @History -------------------------------------
 * Story Number       Modified By              Date           Description
 * CIAM-96          Vijay Kumar K R          Mar 7, 2023    Re-direct "Change Password" button from the Edit page of user on Support Portal to the OKTA change password
 * -------------------------------------------------------------------------
 */
public with sharing class resetPasswordController {
    public String oldPassword {get; set;}
    public String newPassword {get; set;}
    public String verifyNewPassword {get; set;}
    public String result {get; set;}
    public Boolean displayForm {get; set;}
    public Boolean displayBtn {get; set;}
    // Okta attribute
    public Boolean oktaPwResetBtn {get; set;}
    public String oktaBaseUrl {get; set;}
    
    public void displayCngPwsForm(){
        displayBtn = false;
        displayForm = true;
    }
    public void hideCngPwsForm(){
        displayForm = false;
        displayBtn = true;
    }
    /**
     * Method: changeOktaPw 
     * params: 
     * return: Pagereference
     **/
    public Pagereference changeOktaPw(){
        PageReference pageRef = new PageReference(oktaBaseUrl+'/signin/forgot-password');
        pageRef.setRedirect(true);
        return  pageRef;
    }
    public void changePassword() {
        system.debug('change password called'+oldPassword +'..newPassword..'+newPassword+'..verifyNewPassword..'+verifyNewPassword);
        
        if(newPassword == null || verifyNewPassword == null  || newPassword == '' || verifyNewPassword == ''){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Value required in all fields'));
        }
        else{
            if(oldPassword == null)
                oldPassword = '';
            PageReference changePws = Site.changePassword(newPassword, verifyNewPassword, oldPassword);
            if(changePws!=null){
                result = 'success';
            }
            else{
                result = 'error';
            }
        }  
    }
    
    public resetPasswordController (ApexPages.StandardController controller) {
        // by Vijay: CIAM-96 Updated password reset link to Okta for Support User  
        Okta_Attributes__c objOkta = OktaCalloutSelector.getOktaAttributes();

        if(!objOkta.Disable_User_Sync__c){
            oktaBaseUrl = objOkta.Okta_Base_URL__c;
            displayBtn = false;
            oktaPwResetBtn = true;
        }else{
            displayBtn = true;
            oktaPwResetBtn = false;
        }
    }
    
    public resetPasswordController () {}
    
    public PageReference forwardToCustomPage() {
        
        Customer_Community_Tab_Settings__c settings = Customer_Community_Tab_Settings__c.getInstance(UserInfo.getProfileId());
        if(settings != null && String.isNotBlank(settings.Forward_To_Custom_Start_Page__c)) {
            return new PageReference('/' + settings.Forward_To_Custom_Start_Page__c);
        }
        return null;
    }
}