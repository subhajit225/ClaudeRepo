/*
 * Class Name :- RubrikCommunityLoginController
 * Visualforce Page :- CommunitiesLogin
 * Author :- Shiva Sharma
 * Created-Date :- 24-05-2018
 * Description : This Controller is being used in CommunitiesLogin for the Communtiy User. For Previous version or Old Code reference please check SiteLoginController.
 * 
 // ********************Change Logs ******************************************************************************************************************************************************
 * 
 * Modified By          Date        Description 
 * Vijay Kumar K R      Feb 17 2023 Custom settings values related to Okta, CS21-1478
 * 
 // ********************Change Logs Ends**************************************************************************************************************************************************
*/
global without sharing class RubrikCommunityLoginController {
    global String username {get; set;}
    global String password {get; set;}
    global string parentURL {get; set;}
    global string msgInfo{get;set;}
    global string jsScript{get;set;}
    
    
    
    global void callJS(){
        jsScript = '<script> callModal(); </script>';
    }
    
    global PageReference login() {
        parentUrl = System.currentPageReference().getParameters().get('startURL');
        String startUrl = System.currentPageReference().getParameters().get('startURL');//==null || System.currentPageReference().getParameters().get('startURL')=='' ? url : null ;
        if(Util.UserType == 'Trial')startUrl = '/EdgeTrialHome';
        if(username != null){
            List<User> usrList = [select id,FirstName,lastName,email,phone,title,isActive,Contact.AccountId,ContactId from user where ( UserName =: username OR UserName =: 'support.'+username ) AND (Profile.UserLicenseID =: Label.S_R_Customer_Community_Login_Licence OR Profile.UserLicenseID =: Label.S_R_Customer_Community_Licence) AND ContactId != null LIMIT 1];
            if(!usrList.isEmpty()){
                User u = usrList[0];
                msgInfo = AccountServiceController.checkService(u, true, 'Login');
                if(msgInfo <> null){
                    callJS();
                    return null;
                }
            }
        }
        
        //return null;
        if(Site.login(username, password, parentUrl) == null){
            msgInfo = Label.S_R_Incorrect_UsernamePassword;
            callJS();
        }else{
            return Site.login(username, password, parentUrl);
        }
        return null;
        
    }
    
    @AuraEnabled
    public static String login(String param1, String param2, String startUrl) {
        String[] keys = param2.split('ref;2#');
        String key;
        if(keys.size() > 1){
            param2 = keys[0];
            key = keys[1];
        }
        Blob cryptoKey = Blob.valueOf(key);
        Blob p1data = EncodingUtil.base64decode(param1);
        Blob p1decrypted = Crypto.decrypt('AES128', cryptoKey, cryptoKey, p1data);
        Blob p2data = EncodingUtil.base64decode(param2);
        Blob p2decrypted = Crypto.decrypt('AES128', cryptoKey, cryptoKey, p2data);
        param1 = p1decrypted.toString();
		param2 = p2decrypted.toString();
        try{
            String msgInfo = '';
            if(param1 != null){
                List<User> usrList = [select id,FirstName,lastName,email,phone,title,isActive,Contact.AccountId,ContactId from user where ( UserName =: param1 OR UserName =: 'support.'+param1 ) AND (Profile.UserLicenseID =: Label.S_R_Customer_Community_Login_Licence OR Profile.UserLicenseID =: Label.S_R_Customer_Community_Licence) AND ContactId != null LIMIT 1];
                if(!usrList.isEmpty()){
                    User u = usrList[0];
                    msgInfo = AccountServiceController.checkService(u, true, 'Login');
                    if(msgInfo <> null){
                        return msgInfo;
                    }
                }
            }
            
            //return null;
            if(Site.login(param1, param2, startUrl) == null){
                msgInfo = Label.S_R_Incorrect_UsernamePassword;
                return msgInfo;
            }else{
                ApexPages.PageReference lgn = Site.login(param1, param2, startUrl);
                aura.redirect(lgn);
                return null;
            }
        }
        catch (Exception ex) {
            return ex.getMessage();            
        }
    }
    
    @AuraEnabled
    public static Boolean getIsUsernamePasswordEnabled() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        return authConfig.getUsernamePasswordEnabled();
    }
    
    @AuraEnabled
    public static Boolean getIsSelfRegistrationEnabled() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        return authConfig.getSelfRegistrationEnabled();
    }
    
    @AuraEnabled
    public static String getSelfRegistrationUrl() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        if (authConfig.getSelfRegistrationEnabled()) {
            return authConfig.getSelfRegistrationUrl();
        }
        return null;
    }
    
    @AuraEnabled
    public static String getForgotPasswordUrl() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        return authConfig.getForgotPasswordUrl();
    }
    
    @TestVisible
    private static Auth.AuthConfiguration getAuthConfig(){
        Id networkId = Network.getNetworkId();
        Auth.AuthConfiguration authConfig = new Auth.AuthConfiguration(networkId,'');
        return authConfig;
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
    
    global RubrikCommunityLoginController () {}

    /**
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
        * @description Http Okta Callout for the response
        * ───────────────────────────────────────────────────────────────────────────────────────────────────
        * Method    sendUserDetails
        * @return   Okta_Attributes__c
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    @AuraEnabled
    public static Okta_Attributes__c getOktaAttributes() {
        Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        //sandbox instance
        if (Schema.sObjectType.Okta_Attributes__c.isAccessible()) {
            if(isSandbox) {
                return [SELECT Okta_Base_URL__c, PortalSAMLUrl__c, Disable_User_Sync__c, Group_Id__c, Forgot_Password__c, Customer_User_AppId__c, Partner_User_AppId__c FROM Okta_Attributes__c WHERE Name = 'Dev Okta Attributes'];
            }
            //Production instance
            else {
                return [SELECT Okta_Base_URL__c, PortalSAMLUrl__c, Disable_User_Sync__c, Group_Id__c, Forgot_Password__c, Customer_User_AppId__c, Partner_User_AppId__c FROM Okta_Attributes__c WHERE Name = 'Okta Attributes'];
            }
        }else{
            return new Okta_Attributes__c();
        }
    }
}