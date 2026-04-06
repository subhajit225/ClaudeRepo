global without sharing class LightningLoginFormController {
    public LightningLoginFormController() {
        
    }
/**     
    Description :  This method is used for login into Partner community and also chcks if user agrred for Terms & Conditions
    Retrun type :  string - It returns whether login is success or not.
    Parameters  :  username - Username entered by user
    password - password entered by user
    startUrl - url to which we need to navigate after successfull login
**/     
    @AuraEnabled
    public static string login(String username, String password, String startUrl) {
        string showLogin = '';
        List<User> userRecord = new List<User>();
        //SF-3607
        userRecord = [SELECT Id,contact.AccountId,Account.Accepted_Code_of_Conduct__c,Profile.Name,Account.Partner_Agreement_Status__c,Contact.No_Longer_Employed_Here__c,UserType,isActive
                        FROM User
                        WHERE username=:username];
        if(!userRecord.isEmpty() && !userRecord[0].isActive && userRecord[0].Account.Partner_Agreement_Status__c != 'Signed - Active' && userRecord[0].UserType == 'PowerPartner') {
            return Label.PC_Login_Outdated_Agreement;
        }else if(!userRecord.isEmpty() && !userRecord[0].isActive && userRecord[0].Contact.No_Longer_Employed_Here__c && userRecord[0].UserType == 'PowerPartner'){
            return Label.PC_Login_Not_Employed;
        }else if(!userRecord.isEmpty() && !userRecord[0].isActive && userRecord[0].UserType == 'PowerPartner'){
            //Activate the user/send to reactivation
            userRecord[0].isActive = true;
            update userRecord[0];
            return Label.PC_Login_Success;
        }/*else{
            return Label.Login_Community_Alternative_Message;
        }*/
        try{
            system.debug(username+' '+password);
            ApexPages.PageReference lgn1 = Site.login(username, password, ''); // To validate Username and Password detaila are correct
            if(!userRecord.isEmpty() && (!userRecord[0].Account.Accepted_Code_of_Conduct__c) && (userRecord[0].Profile.Name == label.Rubrik_Partner_Community_User || userRecord[0].Profile.Name == label.Rubrik_Partner_Community_Manager )){
                showLogin = 'Both';
                system.debug('@@ in if '+showLogin);
                return showLogin; 
            }
            else if(!userRecord.isEmpty() && (userRecord[0].Profile.Name == label.Rubrik_Partner_Community_User || userRecord[0].Profile.Name == label.Rubrik_Partner_Community_Manager ))
            {
                showLogin = 'Terms';
                system.debug('@@ in if '+showLogin);
                return showLogin; 
            }else if(!userRecord.isEmpty() && !userRecord[0].Account.Accepted_Code_of_Conduct__c && (userRecord[0].Profile.Name == label.Rubrik_Partner_Community_User || userRecord[0].Profile.Name == label.Rubrik_Partner_Community_Manager ))
            {
                showLogin = 'Conduct';
                system.debug('@@ in else if '+showLogin);
                return showLogin;
            }
            else{
                system.debug('@@ in else '+showLogin);
                showLogin = 'success';
                ApexPages.PageReference lgn = Site.login(username, password, startUrl); 
                system.debug('@@ lgn '+lgn);
                aura.redirect(lgn); //Navigate to partner community on successfull login
                return null;
            }
            
            
        }
        catch (Exception ex) {
            system.debug('Exception occurred : '+ex.getMessage()+' at line '+ex.getLineNumber());
            return ex.getMessage();            
        }
    }
    /*      
        Description :  This method is used for updating user's Account record on agreeing Terms & Conditions
        Retrun type :  string - It returns whether login is success or not.
        Parameters  :  username - Username entered by user
        password - password entered by user
        OptIn    - contains value of Agreed Terms & Conditions  
        startUrl - url to which we need to navigate after successfull login 
    */
     /*Added New Method to validate the opt In checkbox - SHADAB  - referring existing Portal code*/
    @AuraEnabled
    global static string continueAfterOptInCheck(String username,String password, Boolean OptIn, Boolean conductCheck,string startUrl) {
        string showLogin = '';
        try{
            List<User> userRecord = new List<User>();
            userRecord = [select id,contact.AccountId,AccountId, Account.Accepted_Code_of_Conduct__c ,Profile.Name,name from User where username=:username  and (Profile.Name = :label.Rubrik_Partner_Community_User OR Profile.Name = :label.Rubrik_Partner_Community_Manager) WITH SECURITY_ENFORCED];
            system.debug('@@ userRecord '+userRecord);
            system.debug('@@ '+OptIn);
            system.debug('@@ '+conductCheck);
            Boolean isupdate = false;
                if(!userRecord.isEmpty() && !OptIn)
                {
                    showLogin=label.Please_agree_Terms_Conditions_to_login;
                    system.debug('@@ showLogin '+showLogin);
                    return showLogin;
                }else{
                    
                    system.debug('@@ startUrl '+startUrl);
                    
                    if(userRecord != null && !userRecord.isEmpty()){
                    List<Account> partnerAccount   = new  List<Account>();
                    partnerAccount =[select id,Accepted_Code_of_Conduct__c,GDPR_terms_Agreed__c from Account where Id =:userRecord[0].AccountId WITH SECURITY_ENFORCED];
                    system.debug('userRecord=='+userRecord[0].AccountId);
                    system.debug('partnerAccount=='+partnerAccount);
                        if(partnerAccount != null  && !partnerAccount.isEmpty() && OptIn){
                            String terms ='IMPORTANT: THIS IS A LEGAL DOCUMENT.  PLEASE READ IT CAREFULLY.THIS ADDENDUM TO YOUR CHANNEL PARTNER AGREEMENT (THIS “ADDENDUM”) FORMS A BINDING CONTRACT ADDING ADDITIONAL TERMS TO THE CHANNEL PARTNER AGREEMENT (THE “AGREEMENT”) BETWEEN RUBRIK, INC. (“RUBRIK”) AND YOU (“RESELLER”).  IF YOU DO NOT WISH TO ACCEPT THIS ADDENDUM, THEN DO NOT CLICK ACCEPT, IN WHICH CASE THE AGREEMENT WILL BE TERMINATED IN ACCORDANCE WITH ITS TERMS AND CONDITIONS.NOW, THEREFORE, FOR VALUABLE CONSIDERATION, THE RECEIPT AND SUFFICIENCY OF WHICH ARE HEREBY ACKNOWLEDGED, THE PARTIES HERETO HEREBY AGREE TO ADD THE FOLLOWING NEW PROVISION TO THE AGREEMENT AS FOLLOWS:End User Data.If Reseller provides Rubrik with personal information concerning its customers, prospects or employees, Rubrik will only use the information in connection with the purposes outlined in the Agreement, or as otherwise indicated at the time Rubrik receives such information (the “Intended Purposes”).  Reseller will not deliver, disclose or otherwise make such personal information available to Rubrik, except as required for the Intended Purposes.  The information may be maintained by Rubrik in data centers in the United States or in other parts of the world and the information may be accessed by Rubrik’s global personnel and authorized third parties as required for its business purposes.  Reseller agrees to comply with all applicable laws, including but not limited to privacy and data protection laws, provide all relevant notices, and obtain any consents required to share the information with Rubrik and its authorized third parties for the Intended Purposes.  In the event Reseller is authorized to and provides a proof-of-concept unit (“POC unit”) to an End User or prospective customer for evaluation or other temporary purposes (an “Evaluation Period”), Reseller agrees to enable encryption of the POC unit where technically possible and to ensure that such encryption remains enabled during the Evaluation Period.  Reseller shall require each recipient of a POC unit to comply with the following: (1)    The POC unit is not for production use and may not be used with production data;(2) Personal data and other data regulated by GDPR or other data privacy laws may not be entered into or stored on the POC unit and shall not be shared with Reseller or Rubrik other than as required for its evaluation of the POC unit and then only in compliance with all applicable privacy laws and regulations; and(3)  All data entered into or stored on the POC unit during the Evaluation Period must be removed prior to the return of any POC unit.  Reseller represents and warrants that it shall verify the above three requirements prior to any subsequent use of any POC unit. In the event of any inconsistency or conflict between the Agreement and this Addendum, the terms and conditions of this Addendum shall control.  Capitalized terms used but not defined herein shall have the meanings ascribed them in the Agreement.RESELLER ACCEPTS THIS ADDENDUM BY: (1) INDICATING ACCEPTANCE OF THESE TERMS; OR (2) ACCESSING ANY PROGRAM BENEFIT (INCLUDING EXERCISING OR PURPORTING TO EXERCISE ANY OF THE RIGHTS GRANTED TO RESELLER UNDER THE AGREEMENT).  THE INDIVIDUAL ACCEPTING THIS ADDENDUM ON BEHALF OF RESELLER REPRESENTS THAT HE OR SHE: (1) HAS THE AUTHORITY TO REPRESENT RESELLER; AND (2) HAS READ AND UNDERSTANDS ALL THE PROVISIONS OF THIS ADDENDUM.';
                            partnerAccount[0].GDPR_terms_Agreed__c =terms;
                            isupdate = true;
                        }
                        if(partnerAccount != null  && !partnerAccount.isEmpty() && !partnerAccount[0].Accepted_Code_of_Conduct__c && conductCheck){
                            partnerAccount[0].Accepted_Code_of_Conduct__c = true;
                            isupdate = true;
                        }
                        if(isupdate){
                             if(!test.isRunningTest())update partnerAccount; // Updates Account record of corresponding partner community user
                        }
                    }
                    PageReference  loginref=  Site.login(username, password, startUrl);
                    aura.redirect(loginref); //Navigate to partner community on successfull login
                    return null;
                }
           
        }catch (Exception ex) {
            system.debug(LoggingLevel.WARN, 'Exception occurred : '+ex.getMessage()+' at line '+ex.getLineNumber());
            return ex.getMessage();            
        }
        
    }
 
/* Method to check whether Username & Password is enabled */  
    @AuraEnabled
    public static Boolean getIsUsernamePasswordEnabled() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        return authConfig.getUsernamePasswordEnabled();
    }
    
/* Method to check whether Self registration is enabled */  
    @AuraEnabled
    public static Boolean getIsSelfRegistrationEnabled() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        return authConfig.getSelfRegistrationEnabled();
    }
    
/* Method to get Self registration url */  
    @AuraEnabled
    public static String getSelfRegistrationUrl() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        if (authConfig.getSelfRegistrationEnabled()) {
            return authConfig.getSelfRegistrationUrl();
        }
        return null;
    }

/* Method to get forgot password url */      
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
    
    /**
        @Name : handleforgotPassword
        @Description : SF-3607 Partner Password Reset issue
    
    */
    
    @AuraEnabled
    public static String handleforgotPassword(String emailId) {
        try {
            String msgInfo;
            Map<id,UserLicense> licenseMap = new Map<id,UserLicense>([select id,name from UserLicense WHERE NAME LIKE '%Partner Community%']);
            List<User> userList = [SELECT id,FirstName,lastName,email,phone,title,isActive,Contact.AccountId,ContactId,username 
                                                FROM User 
                                                WHERE Email = :emailId AND Profile.UserLicenseID IN: licenseMap.keyset() LIMIT 1];
            //Change Starts here
            if(!userList.isEmpty()){
                if(userList.get(0).isActive == false) {
                    return Label.Login_Community_Alternative_Message;
                }
            }else{
                msgInfo = Label.S_R_Wrong_Email;
                return msgInfo;
            }
            
            String result = (userList.isEmpty()) ? null : userList.get(0).username;
            boolean success = Site.forgotPassword(result);
            if(success){
                return Label.Login_Community_Message;
                //return 'Your password has been reset. Please check your email from Rubrik Support with the password reset link. If you have any issues, please contact GoForward@Rubrik.com';
            }
            return 'Please try after some time.';
        }
        catch (Exception ex) {
            return ex.getMessage();
        }
    }   
    
    @AuraEnabled
    public static Document getpdf() {
        return [Select id,Name from Document where DeveloperName ='Rubrik_Third_Party_Code_of_Conduct'];
    }
    @AuraEnabled
    public static OktaCustomSettingWrpr getOktaCustomStng(){

        Okta_Attributes__c oktaParams = OktaCalloutSelector.getOktaAttributes();
        String forgotPasswordUrl = String.valueOf(oktaParams.get('Forgot_Password__c'));
        Boolean disableSync = Boolean.valueOf(oktaParams.get('Disable_User_Sync__c'));
        String baseUrl = String.valueOf(oktaParams.get('Okta_Base_URL__c'));
        String partnerApplicationId = String.valueOf(oktaParams.get('Partner_User_AppId__c'));

        OktaCustomSettingWrpr wrpInstance = new OktaCustomSettingWrpr(forgotPasswordUrl, disableSync, baseUrl, partnerApplicationId);
        
        return wrpInstance;
    }

    public class OktaCustomSettingWrpr{
        @AuraEnabled 
        public String forgotPasswordUrl {get;set;}
        @AuraEnabled 
        public Boolean disableSync {get;set;}
        @AuraEnabled 
        public String baseUrl {get;set;}
        @AuraEnabled 
        public String partnerApplicationId {get;set;}

        public OktaCustomSettingWrpr(String forgotpassUrl, boolean disSync, String oktaBaseUrl, String appId){

            forgotPasswordUrl = forgotpassUrl;
            disableSync = disSync;
            baseUrl = oktaBaseUrl;
            partnerApplicationId = appId;
        }
    }
}