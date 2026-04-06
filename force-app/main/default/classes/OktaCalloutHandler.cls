/**
 * @Author      : (Vijay Kumar K R) Customer Portal
 * @CreatedDate : Jan 23, 2023 
 * @TstClass    : OktaUserUtilityTest
 * @Description :
 * -------------------------- @History -------------------------------------
 * Story Number       Modified By              Date           Description
 * 
 * -------------------------------------------------------------------------
 */
public without sharing class OktaCalloutHandler {
    
    public final static String POST = 'POST';
	public final static String GET = 'GET';
    public static String apiResponse;
    @TestVisible
    public final static String customerUserAppId = String.valueOf(OktaCalloutSelector.getOktaAttributes().get('Customer_User_AppId__c'));
    public final static String partnerUserAppId = String.valueOf(OktaCalloutSelector.getOktaAttributes().get('Partner_User_AppId__c'));

    // Error log track Var
    public static String endUrl;
    public static String reqBody;
    public static String requestTime;
    public static String responseTime;
    public final static String CUSTOMER_USER_TYPE = 'CspLitePortal';
    public final static String PARTNER_USER_TYPE = 'PowerPartner';

    public static String OKTA_BASE_URL = String.valueOf(OktaCalloutSelector.getOktaAttributes().get('Okta_Base_URL__c'));
    public static String ACCESS_TOKEN ='SSWS '+String.valueOf(OktaCalloutSelector.getOktaAttributes().get('Access_Token__c'));
    @TestVisible
    public static String SAML_URL = String.valueOf(OktaCalloutSelector.getOktaAttributes().get('PortalSAMLUrl__c'));

    // OWD 
    public static final Id CU_FROM_ADD = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'donotreply@rubrik.com'].Id;
    public static final Id PU_FROM_ADD = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'goforward@rubrik.com'].Id;
    
    /**
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
        * @description Http Okta Callout for the response
        * ───────────────────────────────────────────────────────────────────────────────────────────────────
        * Method    sendUserDetails
        * @param    String queryParams, String payload, String reqType, String apiNum, String userType
        * @return   OktaCalloutSelector.UserData
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    @AuraEnabled
    public static OktaCalloutSelector.UserData sendUserDetails(String queryParams, String payload, String reqType, 
                                                                String apiNum, String userType, String apiStatus, 
                                                                String userId, Boolean isEmailUpdated){
        System.debug(LoggingLevel.ERROR, 'apiNum:: '+apiNum+' :: Th queryParams: '+queryParams);
        System.debug(LoggingLevel.ERROR, 'reqType: ' +reqType+' Th payload: '+payload);
        
        String endpoint = OKTA_BASE_URL+'/api/v1/';

        HttpRequest req = new HttpRequest();

        String portalUserAppId = null;
        if(userType == CUSTOMER_USER_TYPE){
            portalUserAppId = customerUserAppId;
        }else if(userType == PARTNER_USER_TYPE){
            portalUserAppId = partnerUserAppId;
        }
        
        // 1001 API
        if (reqType == GET){
			req.setEndpoint(endpoint + 'users/' + EncodingUtil.urlEncode(queryParams, 'UTF-8'));
		}
        if(reqType == POST){
            switch on apiNum{
                // [1002] Create okta user
                when '1002' {
                    req.setEndpoint(endpoint + 'users?activate=false');
                }
                // [1003] Activate / Re-Activation User and get activation token
                when '1003' {
                    req.setEndpoint(endpoint + 'users/'+queryParams);
                }
                // [1004] Set sfdcCustomerPortalUsername/sfdcPartnerPortalUsername
                when  '1004' {
                    req.setEndpoint(endpoint + 'users/'+queryParams);
                }
                // [1005] Update Application Attributes for User
                when '1005' {
                    req.setEndpoint(endpoint + 'apps/'+portalUserAppId+'/users/'+queryParams);
                }
                // [1007] Deactivate User
                when '1007' {
                    req.setEndpoint(endpoint + 'users/'+queryParams+'/lifecycle/deactivate?sendEmail=false');
                }
                // [1009] reset password Used in "reset Okta Password" Admin button
                when '1009' {
                    req.setEndpoint(endpoint + 'users/'+queryParams+'/lifecycle/reset_password?sendEmail=false&revokeSessions=true');
                }
                // [1011] Suspend Okta User
                when '1011' {
                    req.setEndpoint(endpoint + 'users/'+queryParams+'/lifecycle/suspend');
                }
                // [1012] Unsuspend Okta User
                when '1012' {
                    req.setEndpoint(endpoint + 'users/'+queryParams+'/lifecycle/unsuspend');
                }
            }
            req.setBody(payload);
        }

        req.setMethod(reqType);
        req.setCompressed(false);
        req.setTimeout(20000);
        req.setHeader('Accept','application/json');
		req.setHeader('Content-Type', 'application/json');
		req.setHeader('Connection', 'keep-alive');
        // TO DO Store in Custom Settings
		req.setHeader('Authorization', ACCESS_TOKEN);
        
        // Error log track var
        endUrl = req.getEndpoint();
        reqBody = req.getBody();

        System.debug(LoggingLevel.ERROR, 'req>>>> '+req);
        Http http = new Http();
        requestTime = System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS');
        HTTPResponse response = http.send(req);
        System.debug('response--->'+response);
        apiResponse = response.getBody();
        responseTime = System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS');   
        return statusCheck(response, apiStatus, userId, isEmailUpdated);
    }

    /**
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
        * @description returning http response based on status
        * ───────────────────────────────────────────────────────────────────────────────────────────────────
        * Method    statusCheck
        * @param    HTTPResponse response
        * @return   OktaCalloutSelector.UserData
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public static OktaCalloutSelector.UserData statusCheck(HTTPResponse response, String apiStatus, String userId, Boolean isEmailUpdated){
        
        switch on response.getStatusCode(){
			when 200 {
				OktaCalloutSelector.UserData oktaResp = (OktaCalloutSelector.UserData)System.JSON.deserialize(response.getBody(), OktaCalloutSelector.UserData.class);
                if(!isEmailUpdated){
                    String oktaUserId = oktaResp.id != null?oktaResp.id:OktaUserUtility.oktaUser_Id;
                    updateProcessedUser(userId, 'Success', oktaUserId);
                }
                return oktaResp;
			}
            when 400 {
                OktaCalloutSelector.UserData oktaResp = (OktaCalloutSelector.UserData)System.JSON.deserialize(response.getBody(), OktaCalloutSelector.UserData.class);
                String errorSummaryStr = oktaResp.errorCauses[0].errorSummary;
                if(errorSummaryStr.containsIgnoreCase('already exists')){
                    return oktaResp;
                }else{
                    updateProcessedUser(userId, apiStatus, null);
                    OktaCalloutSelector.errorLogList.add(createErrorLog('OktaUserUtility', reqBody, response.getBody(), String.ValueOf(response.getStatusCode()), endUrl, requestTime, responseTime, apiStatus));
                    throw new CalloutException ('Code: 400 \n This typically means the server cannot or will not process the request due to something that is perceived to be a client error .');
                }
			}
			when 402 {
                updateProcessedUser(userId, apiStatus, null);
                OktaCalloutSelector.errorLogList.add(createErrorLog('OktaUserUtility', reqBody, response.getBody(), String.ValueOf(response.getStatusCode()), endUrl, requestTime, responseTime, apiStatus));
				throw new CalloutException ('Code: 402 \n This typically means there is a problem with the login ID or access token.');
			}
			when  403 {
                updateProcessedUser(userId, apiStatus, null);
                OktaCalloutSelector.errorLogList.add(createErrorLog('OktaUserUtility', reqBody, response.getBody(), String.ValueOf(response.getStatusCode()), endUrl, requestTime, responseTime, apiStatus));
				throw new CalloutException ('Code: 403  \n This typically means there is a OKta permission problem with the SF account');
			}
			when 404 {
                // When New User Created in SF and If Email doesn't macth in Okta, We are inserting that User in Okta
                OktaCalloutSelector.UserData oktaResp = (OktaCalloutSelector.UserData)System.JSON.deserialize(response.getBody(), OktaCalloutSelector.UserData.class);
                updateProcessedUser(userId, apiStatus, null);
                OktaCalloutSelector.errorLogList.add(createErrorLog('OktaUserUtility', reqBody, response.getBody(), String.ValueOf(response.getStatusCode()), endUrl, requestTime, responseTime, apiStatus));
                throw new CalloutException ('Code: 404  \n This typically means there is Data found on Okta');
                // }
			}
			when else {
                updateProcessedUser(userId, apiStatus, null);
                OktaCalloutSelector.errorLogList.add(createErrorLog('OktaUserUtility', reqBody, response.getBody(), String.ValueOf(response.getStatusCode()), endUrl, requestTime, responseTime, apiStatus));
				throw new CalloutException ('response codewith this detail: ' + String.valueOf(response.getStatuscode()));
			}
		}
    }

    /**
        * ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
        * @description updateProcessedUser
        * ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
        * Method    updateProcessedUser
        * @param    String userId, String apiStatus
        * @return   void
        * ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public static void updateProcessedUser(String userId, String apiStatus, String oktaUserId){
        
        if(!OktaCalloutSelector.updateUserMap.containsKey(userId) && oktaUserId != null){
            OktaCalloutSelector.updateUserMap.put(userId, new user(Id = userId, API_Status__c = apiStatus, Okta_UserId__c = oktaUserId));
        }else if(!OktaCalloutSelector.updateUserMap.containsKey(userId) && oktaUserId == null){
            OktaCalloutSelector.updateUserMap.put(userId, new user(Id = userId, API_Status__c = apiStatus));
        }else{
            OktaCalloutSelector.updateUserMap.get(userId).API_Status__c = apiStatus;
        }
    }
    
    /**
        * ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
        * @description Create Custom Error Log record
        * ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
        * Method    createErrorLog
        * @param    String className, String reqBody, String resBody, String statusCode, String endpoint, String reqTime, String resTime 
        * @return   Custom_Error_Log__c
        * ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public static Custom_Error_Log__c createErrorLog(String className, String reqBody, String resBody, String statusCode, String endpoint, String reqTime, String resTime, String apiStatus){
        Custom_Error_Log__c errorLog = new Custom_Error_Log__c();
        errorLog.Class__c = className;
        errorLog.Http_Request__c = reqBody;
        errorLog.Http_Response__c = resBody;
        errorLog.Http_StatusCode__c = statusCode;
        errorLog.Server_Endpoint__c = endpoint;
        errorLog.Request_Time__c = reqTime;
        errorLog.Response_Time__c = resTime;
        errorLog.FailedRecords__c = apiStatus;
        return errorLog;
    }

    /**
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
        * @description Sending Welcome Email For Existing User
        * ───────────────────────────────────────────────────────────────────────────────────────────────────
        * Method    sendWelcomeEmailToExistingUser
        * @param    Map<Id, User> userByuserIdMap
        * @return   void
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public static void sendWelcomeEmail(Map<Id, User> userByuserIdMap, Map<Id,String> activationUrlMap, Boolean isNewUser){

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        String partnerPortalTemplate = 'Send_Welcome_Email';
        String customerPortalTemplate = 'Communities_New_Member_Welcome_Email_HTML';

        if(isNewUser){
            partnerPortalTemplate = 'Partner_Community_New_Member_Welcome_Email';
            customerPortalTemplate = 'Communities_New_Member_Welcome_Email_HTML';
        }

        EmailTemplate supportEtId = [SELECT Id, Name, Subject, Body, HtmlValue 
                                        FROM EmailTemplate 
                                        WHERE DeveloperName = :customerPortalTemplate limit 1];
        EmailTemplate partnerEtId = [SELECT Id, Name, Subject, Body, HtmlValue 
                                        FROM EmailTemplate 
                                        WHERE DeveloperName = :partnerPortalTemplate limit 1];
        for(Id userId : userByuserIdMap.keySet()){
            // var declaration
            String portalUrl = '';
            String emailTemplateBody='';
            User objUser = userByuserIdMap.get(userId);

            // CIAM-103: When Contact created from Admin Panel
            String userEmail = objUser.Email != null ? objUser.Email : objUser.Username;
            String userFirstName = objUser.FirstName != null ? objUser.FirstName : '';
            // String userSupportId = objUser.Support_ID__c != null ? objUser.Support_ID__c : '';

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{userEmail});
            
            if( objUser.userType == 'PowerPartner'){
                portalUrl = SAML_URL + partnerUserAppId + '/46';
                if(isNewUser){
                    portalUrl = activationUrlMap.get(userId) + '?fromURI=' ;
                    portalUrl += EncodingUtil.urlEncode(SAML_URL + partnerUserAppId, 'UTF-8') + '/46';
                }

                mail.setSubject(partnerEtId.Subject);
                emailTemplateBody = partnerEtId.Body;
                if(emailTemplateBody.contains('{!Receiving_User.FirstName}')){
                    emailTemplateBody = emailTemplateBody.replace('{!Receiving_User.FirstName}', userFirstName);
                }
                if(emailTemplateBody.contains('{!Receiving_User.Username}')){
                    emailTemplateBody = emailTemplateBody.replace('{!Receiving_User.Username}', userEmail);
                }
                if(emailTemplateBody.contains('{!Community_Url}')){
                    emailTemplateBody = emailTemplateBody.replace('{!Community_Url}',portalUrl);
                }
                mail.setOrgWideEmailAddressId(PU_FROM_ADD);
                mail.setPlainTextBody(emailTemplateBody);
            }
            else if( objUser.userType == 'CspLitePortal'){
                portalUrl = SAML_URL + customerUserAppId + '/46';
                if(isNewUser){
                    portalUrl = activationUrlMap.get(userId) + '?fromURI=' ;
                    portalUrl += EncodingUtil.urlEncode(SAML_URL + customerUserAppId, 'UTF-8') + '/46';
                }
                
                mail.setSubject(supportEtId.Subject);
                emailTemplateBody = supportEtId.HtmlValue;
                System.debug('!emailTemplateBody: '+emailTemplateBody);   
                
                if(emailTemplateBody.contains('{!Receiving_User.FirstName}')){
                    emailTemplateBody = emailTemplateBody.replace('{!Receiving_User.FirstName}', userFirstName);
                }
                if(emailTemplateBody.contains('{!Receiving_User.Username}')){
                    emailTemplateBody = emailTemplateBody.replace('{!Receiving_User.Username}', objUser.Username);
                }
                if(!isNewUser && emailTemplateBody.contains('Set your password and access the Rubrik Support Portal:')){
                    emailTemplateBody = emailTemplateBody.replace('Set your password and access the Rubrik Support Portal:', 'Access the Rubrik Support Portal:');
                }
                if(emailTemplateBody.contains('{!Community_Url}')){
                    emailTemplateBody = emailTemplateBody.replace('{!Community_Url}',portalUrl);
                }
                if(emailTemplateBody.contains('{!Receiving_User.Email}')){
                    emailTemplateBody = emailTemplateBody.replace('{!Receiving_User.Email}', userEmail);
                }
                // if(emailTemplateBody.contains('{!Receiving_User.Support_ID__c}')){
                //     emailTemplateBody = emailTemplateBody.replace('{!Receiving_User.Support_ID__c}', userSupportId);
                // }
                mail.setOrgWideEmailAddressId(CU_FROM_ADD);
                mail.setHtmlBody(emailTemplateBody);
            }
            

            emails.add(mail);
        }
        
        if(!emails.isEmpty()){
            Messaging.sendEmail(emails); 
        }
    }

    /**
        * ──────────────────────────────────────────────────────────────────────────────────────────────────────┐
        * @description CIAM-278: Email Updation Process in Salesforce: Update old email matched users to new Email
        * ──────────────────────────────────────────────────────────────────────────────────────────────────────
        * Method    updateUserOldEmail
        * @param    Map<String, String> newEmailByOldEmailMap
        * @return   void
        * ──────────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public static void updateUserOldEmail(Map<String,String> newEmailByOldEmailMap, Map<String, String> oktaUserIdByOldEmailMap){
        Map<Id, User> updateUserOldEmailMap = new Map<Id, User>();
        if(!newEmailByOldEmailMap.isEmpty()){
            // fetch existing users matched by old emails
            for(User objUser : [SELECT Id, Email, Okta_UserId__c, UserType
                                FROM User 
                                WHERE Email IN: newEmailByOldEmailMap.keySet()
                                AND (UserType = 'CspLitePortal'
                                    OR UserType = 'PowerPartner')]){
                if(oktaUserIdByOldEmailMap?.containsKey(objUser.Email)
                    && oktaUserIdByOldEmailMap.get(objUser.Email) == objUser.Okta_UserId__c){
                        // Updating users with new email
                        objUser.Email = newEmailByOldEmailMap.get(objUser.Email);
                        updateUserOldEmailMap.put(objUser.Id, objUser);
                }
            }
            if(!updateUserOldEmailMap.isEmpty()){
                OktaCalloutSelector.updateUserMap.putAll(updateUserOldEmailMap);
            }
        }
    }

}