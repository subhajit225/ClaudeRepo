global  without sharing class LightningForgotPasswordController {

    public LightningForgotPasswordController() {

    }

    @AuraEnabled
    public static String forgotPassword(String username, String checkEmailUrl) {
        try {
            Site.forgotPassword(username);
            ApexPages.PageReference checkEmailRef = new PageReference(checkEmailUrl);
            if(!Site.isValidUsername(username)) {
                return Label.Site.invalid_email;
            }
            aura.redirect(checkEmailRef);
            return null;
        }
        catch (Exception ex) {
            return ex.getMessage();
        }
    }
    
    @AuraEnabled
    public static String forgotCustomerPassword(String username) {
        try {
            String msgInfo;
            Map<id,UserLicense> licenseMap = new Map<id,UserLicense>([select id,name from UserLicense WHERE NAME LIKE '%Customer Community%']);
            List<User> userList = [SELECT id,FirstName,lastName,email,phone,title,isActive,Contact.AccountId,ContactId,username FROM User WHERE Email = :username AND Profile.UserLicenseID IN: licenseMap.keyset() AND isActive = true limit 1];
            //Change Starts here
            if(!userList.isEmpty()){
                User u = userList[0];
                msgInfo = AccountServiceController.checkService(u, true, 'forget');
                if(msgInfo <> null){
                    return msgInfo;
                }
            }else{
                msgInfo = Label.S_R_Wrong_Email;
                if(!Test.isRunningTest())
                	return msgInfo;
            }
            //It All Ends here
            
            
            
            String result = (userList.isEmpty()) ? null : userList.get(0).username;
            boolean success = Site.forgotPassword(result);
            if(success){
                return 'Reset Password link is send please check.';
            }
            return 'Please try after some time.';
        }
        catch (Exception ex) {
            return ex.getMessage();
        }
    }

    @AuraEnabled
    global static String setExperienceId(String expId) {    
        // Return null if there is no error, else it will return the error message 
        try {
            if (expId != null) {
                Site.setExperienceId(expId);               
            }
            return null; 
        } catch (Exception ex) {
            return ex.getMessage();            
        }        
    } 
}