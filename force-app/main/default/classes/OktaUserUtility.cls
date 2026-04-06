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
public without sharing class OktaUserUtility implements Queueable, Database.AllowsCallouts{
    
    Set<Id> userIdSet = new Set<Id>();
    Map<Id,User> oldRecordsMap = new Map<Id,User>();
    public final static String CUSTOMER_USER_TYPE = 'CspLitePortal';
    public final static String PARTNER_USER_TYPE = 'PowerPartner';
    public final static String GROUP_ID = String.valueOf(OktaCalloutSelector.getOktaAttributes().get('Group_Id__c'));
    
    public OktaUserUtility(Set<Id> userIdSet, Map<Id,sObject> oldRecordsMap) {
        this.userIdSet = userIdSet;
        this.oldRecordsMap = (Map<Id,User>)oldRecordsMap;
    }
    
    public final static String POST = 'POST';
    public final static String GET = 'GET';

    // Existing Multiple Support Active users with Same Email: User details Map
    public static Map<String, List<User>> existingActiveSupportUserByEmailMap = new Map<String, List<User>>(); 
    // Existing Active users if it is partner or customer users
    public static Map<String, List<User>> existingActiveUserByEmailMap = new Map<String, List<User>>();
    public static Map<String, List<User>> existingActiveOktaUserByEmailMap = new Map<String, List<User>>();
    // Support and Partner Okta fields by SF Fields
    public static Map<String, String> oktaFieldNameByCustomerFieldMap = new Map<String, String>();
    public static Map<String, String> oktaFieldNameByPartnerFieldMap = new Map<String, String>();
    public static Map<String, User> allExistingPortalUserByEmailMap = new Map<String, User>();
    public static Map<String, User> existingInActiveUserByEmailMap = new Map<String, User>();
    public static String oktaUser_Id ='';
    
    /**
    * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
    * @description: Method to fecth SF to Okta fields mapping for Customer Support/Partner User
    * ───────────────────────────────────────────────────────────────────────────────────────────────────
    * @Method   : getOktaFieldsByPortalUserFields 
    * @return   : void
    * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public static void getOktaFieldsByPortalUserFields(){
        for(SF_Okta_Field_Mapping__mdt objMtd : SF_Okta_Field_Mapping__mdt.getAll().values()){
            // Customer Support Fields                                            
            if(objMtd.Common_Field__c 
                || (!objMtd.isPartner_Field__c && !objMtd.Common_Field__c)){
                    if(!oktaFieldNameByCustomerFieldMap.containsKey(objMtd.SF_Field_API_Name__c)){
                        oktaFieldNameByCustomerFieldMap.put(objMtd.SF_Field_API_Name__c, objMtd.Okta_Field_API_Name__c);
                    }
            }
            // Partner fields
            if(objMtd.Common_Field__c 
                || (objMtd.isPartner_Field__c && !objMtd.Common_Field__c)){
                    if(!oktaFieldNameByPartnerFieldMap.containsKey(objMtd.SF_Field_API_Name__c)){
                        oktaFieldNameByPartnerFieldMap.put(objMtd.SF_Field_API_Name__c, objMtd.Okta_Field_API_Name__c);
                    }
            }
        }
    }
    
    /**
    * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
    * @description: Rendering API Callout based on User Existing in OKTA
    * ───────────────────────────────────────────────────────────────────────────────────────────────────
    * Method    : execute 
    * @param    : QueueableContext context
    * @return    : Void
    * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public void execute (QueueableContext context){
        
        Map<Id, User> userMap = OktaCalloutSelector.getUserList(userIdSet);
        // New Welcome Email (Password set) to Users
        Map<Id, User> newUserMap = new Map<Id, User>();
        // Portal access email for eixtsing SF Portal users
        Map<Id, User> existingUserMap = new Map<Id, User>();
        // New User Email Change
        Map<String, String> newEmailByOldEmailMap = new Map<String, String>();
        Map<String, String> oktaUserIdByOldEmailMap = new Map<String, String>();

        Map<Id,String> activationUrlByUserIdMap = new Map<Id,String>();
        // userByIdMap
        OktaCalloutSelector.UserData resJsonBody = null;
        try {

            getOktaFieldsByPortalUserFields();
            // CIAM-99: Disabling users from Contact and Re-Enabling User
            Set<String> userEmailSet = new Set<String>();

            Set<String> deactivateUserEmailSet = new Set<String>();
            // Multiple Support Users with Same Email: To Update Existing Active User details into Okta when latest Support user is De-Activated
            for(User userObj : userMap.values()){
                // CIAM-99:
                // Replacement of 1001 API
                userEmailSet.add(userObj.Email);
            }

            // 1001 replacement
            OktaCalloutSelector.eixstingUserWrapper eixstingUserWrap = OktaCalloutSelector.getExistingUser(userEmailSet);
            allExistingPortalUserByEmailMap = eixstingUserWrap.allExistingPortalUserByEmailMap;
            existingActiveOktaUserByEmailMap = eixstingUserWrap.existingActiveOktaUserByEmailMap; 
            existingActiveUserByEmailMap = eixstingUserWrap.existingActiveUserByEmailMap; 
            existingInActiveUserByEmailMap = eixstingUserWrap.existingInActiveUserByEmailMap;
            existingActiveSupportUserByEmailMap = eixstingUserWrap.existingActiveSupportUserByEmailMap;
            
            System.debug('existingInActiveUserByEmailMap>>>'+existingInActiveUserByEmailMap);
            //Replacement of 1001 API
            System.debug('userEmailSet-->'+userEmailSet);
            
            for(User userObj : userMap.values()){
                System.debug(LoggingLevel.ERROR, 'userObj>>> '+userObj.Okta_UserId__c);
                System.debug(LoggingLevel.ERROR, 'oldrecords>>> '+oldRecordsMap);

                // CIAM-103: When Contact created from Admin Panel
                String userEmail = userObj.Email != null ? userObj.Email : userObj.Username;
                System.debug(LoggingLevel.ERROR, 'userEmail '+userEmail);

                // User Activation / De-Activation in SF (Okta: User Exists / User is De-activated)
                System.debug('existingInActiveUserByEmailMap>>>>>'+existingInActiveUserByEmailMap);
                System.debug('existingActiveOktaUserByEmailMap>>>>>'+existingActiveOktaUserByEmailMap);
                System.debug('existingActiveSupportUserByEmailMap>>>>>'+existingActiveSupportUserByEmailMap);

                // CIAM-278: Email Change: New De-Activated User creation in Okta for Old Email for audit purpose
                if(oldRecordsMap != null 
                    && userObj.Email != oldRecordsMap.get(userObj.Id).Email
                    && userObj.isActive){
                        System.debug('userObj.Email>>>>>'+userObj.Email);
                        createNewInAcitveOktaUser(userObj, oldRecordsMap, newEmailByOldEmailMap, oktaUserIdByOldEmailMap);
                }

                // Existing Records Active/InActive Update 
                if((oldRecordsMap != null 
                    && userObj.isActive != oldRecordsMap.get(userObj.Id).isActive
                    && userObj.Okta_UserId__c != null)
                    || (existingInActiveUserByEmailMap?.containsKey(userObj.Email)
                        && existingActiveOktaUserByEmailMap.isEmpty()
                        && allExistingPortalUserByEmailMap?.containsKey(userObj.Email))){
                            oktaUser_Id = allExistingPortalUserByEmailMap.get(userObj.Email).Okta_UserId__c;
                            System.debug('useractivationdecation');
                            userActivationOrDeActivation(userObj, activationUrlByUserIdMap, newUserMap, existingUserMap);
                    }
                else{
                    
                    System.debug('allExistingPortalUserByEmailMap-->'+allExistingPortalUserByEmailMap);
                    // Only when User doesn't exists in Okta
                    if((userObj.Okta_UserId__c == null 
                        && !allExistingPortalUserByEmailMap?.containsKey(userObj.Email))
                        // Case 3: For Creating Multiple Support Portal Users From Contact (Enable Customer User)
                        || (!existingActiveSupportUserByEmailMap.isEmpty()
                            && existingActiveSupportUserByEmailMap?.get(userObj.Email).size() < 1)){
                            System.debug(LoggingLevel.ERROR, 'creating  >>> '+userObj.Email);
                            System.debug(LoggingLevel.ERROR, 'creating new User>>> '+userObj.Okta_UserId__c);
                            // [API 1002] Create new OKTA User
                            createNewUser(userObj, newUserMap, activationUrlByUserIdMap); 
                    }
                    // PU in SF and CU in SF both are sync to Okta
                    // PU  in InActce and CU user in Okta 
                    // Active User exists in Okta (With Partner/Customer App)
                    else {
                        
                        OktaCalloutSelector.UserData resJsonBodyUpdateUserName = null;
                        // update application name if partner/customer is exist and we are creating partner/customer user
                        String OktaUserId = allExistingPortalUserByEmailMap?.get(userObj.Email).Okta_UserId__c;

                        if(userObj.Okta_UserId__c == null){
                            // System.debug('existingCustomerUserByEmailMap--->'+existingCustomerUserByEmailMap);
                            // Execute only once when Partner user creates at first time when another Partner User already exists
                            
                            if(userObj.UserType == PARTNER_USER_TYPE 
                                && allExistingPortalUserByEmailMap?.containsKey(userObj.Email)){
                                    resJsonBodyUpdateUserName = updateApplicationUserName(userObj, userObj.Username, 'API-1004: Update Partner User Application Failure', OktaUserId);
                            }
                            
                            // When there is no Active One/Multiple Customer User exists then Updating App for New Customer User in Okta
                            // TODO: Create new map for CU and replace allExistingPortalUserByEmailMap
                            else if(userObj.UserType == CUSTOMER_USER_TYPE 
                                    && allExistingPortalUserByEmailMap?.containsKey(userObj.Email)){
                                        resJsonBodyUpdateUserName = updateApplicationUserName(userObj, userObj.Username, 'API-1004: Update Customer User Application Failure', OktaUserId);
                            }
                            
                        }

                        // CIAM-121: If Username/Email Updated from Salesforce Page, Skipping this API call if above 1004 is executed 
                        if(oldRecordsMap != null 
                            && (userObj.Email != oldRecordsMap.get(userObj.Id).Email
                                || userObj.UserName != oldRecordsMap.get(userObj.Id).UserName
                                // CIAM-323: Firstname and lastname update in SF is not updated at Profile level in CIAM
                                || userObj.FirstName != oldRecordsMap.get(userObj.Id).FirstName
                                || userObj.LastName != oldRecordsMap.get(userObj.Id).LastName)
                            && resJsonBodyUpdateUserName == null){
                                resJsonBodyUpdateUserName = updateApplicationUserName(userObj, userObj.Username, 'API-1004: Update UserName Failure', OktaUserId);
                        }
                        
                        if((resJsonBodyUpdateUserName != null
                            && resJsonBodyUpdateUserName.errorSummary == null) || oldRecordsMap!= null){
                                // [API 1007] Update Application Attributes for User
                                updateAppAttributes(userObj, OktaUserId, 'API-1005: Update User Attributes Failure');
                            }
                        
                        // Send Welcome email for existing user to provide partner/customer login access
                        if(oldRecordsMap == null){
                            if((resJsonBodyUpdateUserName != null 
                            && resJsonBodyUpdateUserName.Profile.sfdcCustomerPortalUsername != null 
                            && resJsonBodyUpdateUserName.Profile.sfdcPartnerPortalUsername != null)
                            // If New Support User created on Existing Active Support User: Existing Welcome email 
                            || (!existingActiveSupportUserByEmailMap.isEmpty()
                                    && existingActiveSupportUserByEmailMap?.get(userObj.Email).size() > 1)){
                                        existingUserMap.put(userObj.Id, userObj);
                            }
                        }
                    }
                }
            }
            
            System.debug(LoggingLevel.ERROR, 'newUserMap User>>> '+newUserMap);
            System.debug(LoggingLevel.ERROR, 'existingUserMap User>>> '+existingUserMap);
            // Send Welcome Email
            if(!newUserMap.isEmpty() && !activationUrlByUserIdMap.isEmpty()){
                OktaCalloutHandler.sendWelcomeEmail(newUserMap, activationUrlByUserIdMap, true);
            }
            // Send welcome Email for existing user
            if(!existingUserMap.isEmpty()){
                OktaCalloutHandler.sendWelcomeEmail(existingUserMap, activationUrlByUserIdMap, false);
            }
            
            
        } 
        // catch statement for exceptions.
        catch (Exception e) {
            System.debug('Exception>>>>>'+e.getmessage());
            Custom_Error_Log__c exceptionErrorLog = new Custom_Error_Log__c();
            exceptionErrorLog.Class__c = 'OktaUserUtility';
            exceptionErrorLog.Exception_Message__c = e.getmessage();
            exceptionErrorLog.ErrorTrace__c = e.getStackTraceString();
            OktaCalloutSelector.errorLogList.add(exceptionErrorLog);
        } 
    
        // Finally block
        finally{
            System.debug(LoggingLevel.ERROR,'errorLogList: '+OktaCalloutSelector.errorLogList);
            if(!OktaCalloutSelector.errorLogList.isEmpty()){
                upsert OktaCalloutSelector.errorLogList;
            }

            System.debug(LoggingLevel.ERROR,'newEmailByOldEmailMap: '+newEmailByOldEmailMap+' :oktaUserIdByOldEmailMap: '+oktaUserIdByOldEmailMap);
            if(!newEmailByOldEmailMap.isEmpty()){
                OktaCalloutHandler.updateUserOldEmail(newEmailByOldEmailMap, oktaUserIdByOldEmailMap);
            }

            system.debug(LoggingLevel.ERROR,'updateUserMap: '+OktaCalloutSelector.updateUserMap);
            //upadte api status for failure record
            if(!OktaCalloutSelector.updateUserMap.isEmpty() && !Test.isRunningTest()){
                // Executing below code as System Admin context
                update OktaCalloutSelector.updateUserMap.values();
            }
        }
    }
    
    /**
    * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
    * @description De-Activation and Activation of User related API callouts
    * ───────────────────────────────────────────────────────────────────────────────────────────────────
    * @Method    userActivationOrDeActivation
    * @param     User userObj, OktaCalloutSelector.UserData resJsonBody
    * @return    void
    * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public static void userActivationOrDeActivation(User userObj, Map<Id,String> activationUrlByUserIdMap, Map<Id, User> newUserMap, Map<Id, User> existingUserMap){
        // System.debug('userActivationOrDeActivation>>>>>: '+existingActiveUserByEmailMap);
        System.debug('userOktaId>>>>>: '+userObj.Okta_UserId__c);
        // User De-Activation and No existing Active Support User
        // De-Activating Partner will remove's the partner Application in Okta
        // De-Activating Customer: remove's the customer app only if No Eixtsing Active Support users in SF else execute // Multiple Users: logic
        if((userObj.Usertype == PARTNER_USER_TYPE
            && !userObj.isActive)
            || (!userObj.isActive 
                && !existingActiveSupportUserByEmailMap.containsKey(userObj.Email)
                && userObj.Usertype == CUSTOMER_USER_TYPE)){
            // [API 1006] remove Application name based on UserType from [sfdcCustomerPortalUsername/sfdcPartnerPortalUsername]
            OktaCalloutSelector.UserData resJsonBody = updateApplicationUserName(userObj, null, 'API-1004: User App Deactivation Failure', userObj.Okta_UserId__c);
            System.debug('resJsonBody--->'+resJsonBody);
            // [API 1008] Deactivating User in Okta If both CU + PU De-Activated
            if(resJsonBody != null &&
                String.isBlank(resJsonBody.Profile.sfdcPartnerPortalUsername) &&
                String.isBlank(resJsonBody.Profile.sfdcCustomerPortalUsername)){
                   System.debug('in deactivation');
                   // De-Activating Okta User When both Partner & Customer user is In-Active in SF
                   OktaCalloutHandler.sendUserDetails(resJsonBody.id, '', POST, '1007', userObj.UserType, 'API-1007: User Deactivation Failure', userObj.Id, false);
               }
        }
        // CIAM-66: Multiple Users: User De-Activation with an existing Active Support User
        else if(!userObj.isActive
                && userObj.Usertype == CUSTOMER_USER_TYPE     
                && existingActiveSupportUserByEmailMap.containsKey(userObj.Email)){
                    System.debug('1004 and 1005:: : '+existingActiveSupportUserByEmailMap.get(userObj.Email));

                    User objUser = existingActiveSupportUserByEmailMap.get(userObj.Email)[0];
                    // make callout for 1004: Update User profile with Application name [sfdcCustomerPortalUsername/sfdcPartnerPortalUsername]
                    OktaCalloutSelector.UserData resJsonBody = updateApplicationUserName(objUser, objUser.Username, 'API-1004: Multiple User App Deactivation Failure', objUser.Okta_UserId__c);
                    if(resJsonBody.errorSummary == null){
                        // [API 1005] Update Application Attributes for User
                        updateAppAttributes(objUser, resJsonBody.id, 'API-1005: Multiple User Update Attributes Failure');
                    }
        }
        // User Activation: 
        else{
            // User Activation: Only When Complete User is De-Activeted in Okta 
            OktaCalloutSelector.UserData resJsonBodyReactivation = null;
            // New User Created in Okta
            System.debug('existingInActiveUserByEmailMap-->'+existingInActiveUserByEmailMap);
             System.debug('existingActiveSupportUserByEmailMap-->'+existingActiveSupportUserByEmailMap);
            if((userObj.isActive
                && existingActiveUserByEmailMap?.get(userObj.Email).size() <= 1 )){
                // Multiple Support user Re-Activation  
                // || existingActiveSupportUserByEmailMap?.get(userObj.Email).size() <= 1){
                    System.debug('In-Active User in Okta--->');

                    String oktaUserId = allExistingPortalUserByEmailMap.get(userObj.Email).Okta_UserId__c;
                    // [API 1003] Activate User and get activation token
                    resJsonBodyReactivation = activateUser(oktaUserId, userObj.UserType, 'API-1003: User Re-activation Failure', userObj.Id);
                    activationUrlByUserIdMap.put(userObj.Id, resJsonBodyReactivation.activationUrl);
                    newUserMap.put(userObj.Id, userObj);
            }
            System.debug('Response SF Acitve-->'+resJsonBodyReactivation);
            // Once User Active in Okta, below Code to Update User Attributes
            if((resJsonBodyReactivation != null 
                    && resJsonBodyReactivation.activationUrl != null)
                    || existingActiveOktaUserByEmailMap?.containsKey(userObj.Email)){
                    System.debug('Activated User in Okat SF Acitve-->'+resJsonBodyReactivation);

                    String oktaUserId = userObj.Okta_UserId__c != null ? userObj.Okta_UserId__c : allExistingPortalUserByEmailMap.get(userObj.Email).Okta_UserId__c;

                    // [API 1006] Update User profile with Application name [sfdcCustomerPortalUsername/sfdcPartnerPortalUsername]
                    OktaCalloutSelector.UserData resJsonBody = updateApplicationUserName(userObj, userObj.Username, 'API-1004: Re-activated User App Failure', oktaUserId);
                    System.debug('resJsonBody after activation url--->'+resJsonBody);
                    if(resJsonBody != null && resJsonBody.errorSummary == null){
                        // [API 1007] Update Application Attributes for User
                        updateAppAttributes(userObj, oktaUserId, 'API-1005: Re-activated User Attributes Failure');
                    }
                    
                    // Sending Email to Login: New User created on existing user.
                    if(resJsonBodyReactivation == null){
                        existingUserMap.put(userObj.Id, userObj);
                    }
            }
        }
    }
    
    /**
    * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
    * @description [API 1006] Set sfdcCustomerPortalUsername/sfdcPartnerPortalUsername
    * ───────────────────────────────────────────────────────────────────────────────────────────────────
    * @Method    updateApplicationUserName
    * @param     OktaCalloutSelector.UserData resJsonBody
    * @return    void
    * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public static OktaCalloutSelector.UserData updateApplicationUserName(User objUser, String userName, String apiStatus, String oktaUserId){

        Map<String, Object> payload = new Map<String, Object>();
        Map<String, Object> portalUserMap = new Map<String, Object>();
        String userType = objUser.UserType;

        System.debug('userType-->'+userType);
        System.debug('Okta_UserId__c-->'+oktaUserId);

        // on Email change: Email & login Update on User header
        portalUserMap.put('email', objUser.Email);
        portalUserMap.put('login', objUser.Email);

        // name
        String firstNameStr = objUser.FirstName != null ? objUser.FirstName.length() > 50 ? objUser.FirstName.substring(0, 50) : objUser.FirstName : '';
        String lastNameStr = objUser.LastName.length() > 50 ? objUser.LastName.substring(0, 50) : objUser.LastName;
        portalUserMap.put('firstName', firstNameStr);
        portalUserMap.put('lastName', lastNameStr);
        
        if(userType == CUSTOMER_USER_TYPE){
                portalUserMap.put('sfdcCustomerPortalUsername', userName);
                payload.put('profile', portalUserMap);
                System.debug(LoggingLevel.ERROR, 'sfdcCustomerPortalUsername payload>>>> '+payload);
                OktaCalloutSelector.UserData resJsonBody = OktaCalloutHandler.sendUserDetails(oktaUserId, JSON.serialize(payload), POST, '1004', userType, apiStatus, objUser.Id, false);
                return resJsonBody;
        }else if(userType == PARTNER_USER_TYPE){
                        portalUserMap.put('sfdcPartnerPortalUsername', userName);
                        payload.put('profile', portalUserMap);
                        System.debug(LoggingLevel.ERROR, 'sfdcPartnerPortalUsername payload>>>> '+payload);
                        OktaCalloutSelector.UserData resJsonBody = OktaCalloutHandler.sendUserDetails(oktaUserId, JSON.serialize(payload), POST, '1004', userType, apiStatus, objUser.Id, false);
                        System.debug('resJsonBody123>>'+resJsonBody);
                        return resJsonBody;
                    }
        return null;
    }
    
    /**
    * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
    * @description [API 1002 and 1007] Create new OKTA User and Update SF Portal Specific attributes
    * ───────────────────────────────────────────────────────────────────────────────────────────────────
    * Method    createNewUser
    * @param    User userObj, OktaCalloutSelector.UserData resJsonBody
    * @return   void
    * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public static void createNewUser(User userObj, Map<Id, User> newUserMap, Map<Id,String> activationUrlByUserIdMap){
        
        Map<String, Object> userDetailsMap = new Map<String, Object>();
        Map<String, Object> payload = new Map<String, Object>();
        
        // CIAM-103: When Contact created from Admin Panel
        String userEmail = userObj.Email != null ? userObj.Email : userObj.Username;

        String firstNameStr = userObj.FirstName != null ? userObj.FirstName.length() > 50 ? userObj.FirstName.substring(0, 50) : userObj.FirstName : '';
        String lastNameStr = userObj.LastName.length() > 50 ? userObj.LastName.substring(0, 50) : userObj.LastName;

        userDetailsMap.put('firstName', firstNameStr);
        userDetailsMap.put('lastName', lastNameStr);
        userDetailsMap.put('email', userEmail);
        userDetailsMap.put('login', userEmail);
        // User App Type 
        if(userObj.UserType == CUSTOMER_USER_TYPE){
            userDetailsMap.put('sfdcCustomerPortalUsername', userObj.Username);
        }else if(userObj.UserType == PARTNER_USER_TYPE){
            userDetailsMap.put('sfdcPartnerPortalUsername', userObj.Username);
        }
        
        payload.put('profile', userDetailsMap);
        payload.put('groupIds', new List<String>{GROUP_ID});
        
        System.debug(LoggingLevel.ERROR, 'createNewUser payload>>>> '+payload);
        
        OktaCalloutSelector.UserData resJsonBody = OktaCalloutHandler.sendUserDetails('', JSON.serialize(payload), POST, '1002', userObj.UserType, 'API-1002: New User Creation Failure', userObj.Id, false);

        if(resJsonBody != null){
            if(resJsonBody.errorCauses != null){
                String errorSummaryStr = resJsonBody.errorCauses[0].errorSummary;
                // CIAM-193: New User Created in SF for Existing Okta User. 
                if(errorSummaryStr != null 
                    && errorSummaryStr.containsIgnoreCase('already exists')){
                    OktaCalloutSelector.UserData resBody = OktaCalloutHandler.sendUserDetails(userObj.Email, '', GET, '1001', userObj.UserType, 'API-1001: New SF User Creation Failure', userObj.Id, false);
                }
            }
            // New User created from SF to Okta
            else{
                // [API 1003] Activate User and get activation token
                OktaCalloutSelector.UserData activationResJsonBodyActivation = activateUser(resJsonBody.Id, userObj.UserType, 'API-1003: New User Activation Failure', userObj.Id);
                if(activationResJsonBodyActivation.errorSummary == null){

                    activationUrlByUserIdMap.put(userObj.Id, activationResJsonBodyActivation.activationUrl);
                
                    // [API 1005] Update Application Attributes for User
                    updateAppAttributes(userObj, resJsonBody.id, 'API-1005: New User Update Application Attributes Failure');
                    // Send Welcome Email + set Password
                    newUserMap.put(userObj.Id, userObj);
                }
            }
            
        }
    }
    
    /**
    * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
    * @description [API 1003] Activate User and get activation token
    * ───────────────────────────────────────────────────────────────────────────────────────────────────
    * Method    activateUser
    * @param    User userObj, OktaCalloutSelector.UserData resJsonBody
    * @return   void
    * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public static OktaCalloutSelector.UserData activateUser(String oktaUserId, String userType, String apiStatus, String userId){
        String queryParam = oktaUserId+'/lifecycle/activate?sendEmail=false';
        System.debug(LoggingLevel.ERROR, 'activateUser queryParam>>>> '+queryParam);
        OktaCalloutSelector.UserData resJsonBody = OktaCalloutHandler.sendUserDetails(queryParam, '', POST, '1003', userType, apiStatus, userId, false);
        return resJsonBody;
    }
    
    /**
    * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
    * @description [API 1007] Update Application Attributes for User
    * ───────────────────────────────────────────────────────────────────────────────────────────────────
    * Method    updateAppAttributes
    * @param    User userObj, OktaCalloutSelector.UserData resJsonBody
    * @return   void
    * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public static void updateAppAttributes(User userObj, String oktaUserId, String apiStatus){
        if(userObj.UserType == CUSTOMER_USER_TYPE){
            updateAppAttributesByUserType(oktaFieldNameByCustomerFieldMap, userObj, oktaUserId, apiStatus);
        }else if(userObj.UserType == PARTNER_USER_TYPE){
            updateAppAttributesByUserType(oktaFieldNameByPartnerFieldMap, userObj, oktaUserId, apiStatus);
        }
    }
    
    /**
    * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
    * @description [API 1007] Update Application Attributes for User
    * ───────────────────────────────────────────────────────────────────────────────────────────────────
    * Method    updateAppAttributesByUserType
    * @param    Map<String, String> oktaFieldNameBySfFieldMap, User userObj, OktaCalloutSelector.UserData resJsonBody
    * @return   void
    * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public static void updateAppAttributesByUserType(Map<String, String> oktaFieldNameBySfFieldMap, User userObj, String oktaUserId, String apiStatus){
        Map<String, Object> userFieldValByOktaKey = new Map<String, Object>();
        Map<String, Object> payload = new Map<String, Object>();
        // Email Update
        
        for(String sfField : oktaFieldNameBySfFieldMap.keySet()){

            if(!sfField.containsIgnoreCase('UserName')){
                if(sfField.containsIgnoreCase('UserLicense')){
                    userFieldValByOktaKey.put(oktaFieldNameBySfFieldMap.get(sfField), userObj.Profile.UserLicense.Name);  
                }else if(sfField == 'Profile.Name'){
                    userFieldValByOktaKey.put(oktaFieldNameBySfFieldMap.get(sfField), userObj.Profile.Name);  
                }else if(sfField == 'UserRole.Name'){
                    userFieldValByOktaKey.put(oktaFieldNameBySfFieldMap.get(sfField), userObj.UserRole.Name);  
                }else if(sfField == 'FirstName'){
                    String firstNameStr = userObj.FirstName != null ? userObj.FirstName.length() > 50 ? userObj.FirstName.substring(0, 50) : userObj.FirstName : '';
                    userFieldValByOktaKey.put(oktaFieldNameBySfFieldMap.get(sfField), firstNameStr);  
                }else if(sfField == 'LastName'){
                    String lastNameStr = userObj.LastName.length() > 50 ? userObj.LastName.substring(0, 50) : userObj.LastName;
                    userFieldValByOktaKey.put(oktaFieldNameBySfFieldMap.get(sfField), lastNameStr);  
                }
                else if(sfField == 'Contact.Agreed_To_POC_term__c'
                        && userObj.UserType == PARTNER_USER_TYPE){
                            userFieldValByOktaKey.put(oktaFieldNameBySfFieldMap.get(sfField), userObj.Contact.Agreed_To_POC_term__c);  
                        }
                else{
                    userFieldValByOktaKey.put(oktaFieldNameBySfFieldMap.get(sfField), userObj?.get(sfField));  
                }
            }
        }
        if(!userFieldValByOktaKey.keySet().isEmpty()){
            payload.put('profile', userFieldValByOktaKey);
        }
        System.debug(LoggingLevel.ERROR, 'updateAppAttributesByUserType payload>> '+payload);
        
        OktaCalloutHandler.sendUserDetails(oktaUserId, JSON.serialize(payload), POST, '1005', userObj.UserType, apiStatus, userObj.Id, false);
    }

    /**
    * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
    * @description CIAM-278: Email Updation Process in Salesforce: Create New InActive Okta User with SF Old Email
    * ───────────────────────────────────────────────────────────────────────────────────────────────────
    * Method    createNewInAcitveOktaUser
    * @param    User userObj
    * @return   void
    * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */ 
    public static void createNewInAcitveOktaUser(User userObj, Map<Id, User> oldRecordsMap, Map<String, String> newEmailByOldEmailMap, Map<String, String> oktaUserIdByOldEmailMap){

        Map<String, Object> userDetailsMap = new Map<String, Object>();
        Map<String, Object> payload = new Map<String, Object>();
        
        // Old UN and Email
        String userEmail = oldRecordsMap.get(userObj.Id).Email;
        String userName = oldRecordsMap.get(userObj.Id).Username;
        // Update existing Users Email
        newEmailByOldEmailMap.put(userEmail, userObj.Email);
        oktaUserIdByOldEmailMap.put(userEmail, userObj.Okta_UserId__c);
        // 
        userDetailsMap.put('firstName', userObj.FirstName);
        userDetailsMap.put('lastName', userObj.LastName);
        userDetailsMap.put('email', userEmail+'.invalid');
        userDetailsMap.put('login', userEmail+'.invalid');
        payload.put('profile', userDetailsMap);
        payload.put('groupIds', new List<String>{GROUP_ID});
        
        System.debug(LoggingLevel.ERROR, 'createNewInAcitveOktaUser payload>>>> '+payload);
        
        OktaCalloutSelector.UserData resJsonBody = OktaCalloutHandler.sendUserDetails('', JSON.serialize(payload), POST, '1002', userObj.UserType, 'API-1002: New InActive User Creation Failure', userObj.Id, true);
        System.debug(LoggingLevel.ERROR, 'createNewInAcitveOktaUser resJsonBody>>>> '+resJsonBody);
        
        if(resJsonBody != null
            && resJsonBody.errorCauses == null){
                OktaCalloutSelector.UserData resJsonBody1 = OktaCalloutHandler.sendUserDetails(resJsonBody.id, '', POST, '1007', userObj.UserType, 'API-1007: New InActive User Deactivation Failure', userObj.Id, true);
        }
    }
    
}