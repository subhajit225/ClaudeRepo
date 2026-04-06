/**
* @Author      : Gaurav (partner) + Vijay Kumar K R (Customer)
* @CreatedDate : Mar 20, 2023 
* @TstClass    : OktaProcessFailedUsersBatchTest
* @Description :
* -------------------------- @History -------------------------------------
* Story Number       Modified By              Date           Description
* 
* -------------------------------------------------------------------------
*/
public class OktaUserFailureSync {
    
    @InvocableMethod
    public static void userFailureSync(List<Requests> requestLists){
        System.debug('userFailureSync--->'+new List<User>{requestLists[0].userRecord});
        // User records from Flow called from "Okta Sync" button on User
        processFailedUserRecords(new List<User>{requestLists[0].userRecord});
    }
    
    // Creting Map for New User, Existing Map and Activation URL Map
    public static Map<Id, User> newUserMap = new Map<Id, User>();
    public static Map<Id,String> activationUrlByUserIdMap = new Map<Id,String>();
    public static Map<Id, User> existingUserMap = new Map<Id, User>();
    
    // Creating Map to Get Existing Map From OktaUserUtility Class
    public static Map<String, User> allExistingPortalUserByEmailMap = new Map<String, User>();
    public static Map<String, List<User>> existingActiveSupportUserByEmailMap = new Map<String, List<User>>();
    public static Map<String, List<User>> existingActiveUserByEmailMap = new Map<String, List<User>>();
    
    // Creating Maps for Freezing/ Unfreezing Functionality
    public static Map<Id, OktaFreezeUsersSchedulableBatch.FreezeUserWrap> frozenUserByIdMap = new Map<Id, OktaFreezeUsersSchedulableBatch.FreezeUserWrap>();
    public static Map<Id, OktaFreezeUsersSchedulableBatch.FreezeUserWrap> unFrozenUserByIdMap = new Map<Id, OktaFreezeUsersSchedulableBatch.FreezeUserWrap>();
    public static Map<String, List<User>> existingUnFrozenUsersByEmailMap = new Map<String, List<User>>();
    public static Map<String, List<User>> existingUnFrozenCustomerUsersByEmailMap = new Map<String, List<User>>();
    
    // Creating Maps for getting Existing Failed Users
    public static Map<String, User> activeUserByEmailMap = new Map<String, User>();
    public static Map<String, User> activeFailedUserMapByEMail = new Map<String, User>();

    public static Map<Id, UserLogin> userLoginByUserIdMap = new Map<Id,UserLogin>();
    
    // Reusing from OktaProcessFailedUsersBatch 
    public static void processFailedUserRecords(List<User> failedUserList){
        System.debug('processFailedUserRecords--->'+failedUserList);
        try{
            OktaUserUtility.getOktaFieldsByPortalUserFields();
            
            System.debug('failureUserRecordList--->'+failedUserList);
            Set<String> userEmailSet = new Set<String>();
            Map<Id,User> failedUserMap = new Map<Id,User>();
            // records
            for(User objUser : failedUserList){
                userEmailSet.add(objUser.Email);
                failedUserMap.put(objUser.Id, objUser);
            }
            
            Set<Id> unFrozenUserIdSet = new Set<Id>();
            for(userLogin useLogin : [SELECT Id,IsFrozen,userId FROM UserLogin Where userId IN : failedUserMap.keySet()]){
                if(!userLoginByUserIdMap.containsKey(useLogin.userId)){
                    userLoginByUserIdMap.put(useLogin.userId, useLogin);
                    unFrozenUserIdSet.add(useLogin.UserId);
                }
            }
            Set<String> userFieldSet = new Set<String>();
            for(SF_Okta_Field_Mapping__mdt objMtd : [SELECT SF_Field_API_Name__c, Okta_Field_API_Name__c 
                                                     FROM SF_Okta_Field_Mapping__mdt]){
                                                         userFieldSet.add(objMtd.SF_Field_API_Name__c);
                                                     }
            // UserType Filter String
            String portalProfileFilter = 'UserType = \'CspLitePortal\' OR UserType = \'PowerPartner\'';
            // Query String
            String userQueryString = 'SELECT Okta_UserId__c, Okta_Flow_Status__c, API_Status__c, CreatedDate, LastModifiedDate, UserType, Is_Okta_User_Frozen__c, '+ String.escapeSingleQuotes(String.join(new List<String>(userFieldSet), ', ')) + ' FROM ';
            userQueryString += 'User WHERE ('+portalProfileFilter+') AND Id IN: unFrozenUserIdSet Order By CreatedDate DESC' ;
            System.debug('userQueryString:: '+userQueryString);
            
            if(!unFrozenUserIdSet.isEmpty()){
                for(User objUser : Database.query(userQueryString)){
                    if(!existingUnFrozenUsersByEmailMap.containsKey(objUser.Email)){
                        existingUnFrozenUsersByEmailMap.put(objUser.Email, new List<User>());
                    }
                    existingUnFrozenUsersByEmailMap.get(objUser.Email).add(objUser);
                    
                    if(objUser.UserType == 'CspLitePortal'){
                        if(!existingUnFrozenCustomerUsersByEmailMap.containsKey(objUser.Email)){
                            existingUnFrozenCustomerUsersByEmailMap.put(objUser.Email, new List<User>());
                        }
                        existingUnFrozenCustomerUsersByEmailMap.get(objUser.Email).add(objUser);
                    }
                }
            }
            Map<Id, User> userMap = OktaCalloutSelector.getUserList(failedUserMap.keySet());
            System.debug('userEmailSet-->'+userEmailSet);
            
            OktaCalloutSelector.eixstingUserWrapper eixstingUserWrap = OktaCalloutSelector.getExistingUser(userEmailSet);
            allExistingPortalUserByEmailMap = eixstingUserWrap.allExistingPortalUserByEmailMap;
            existingActiveUserByEmailMap = eixstingUserWrap.existingActiveUserByEmailMap;
            existingActiveSupportUserByEmailMap = eixstingUserWrap.existingActiveSupportUserByEmailMap;
            System.debug('allExistingPortalUserByEmailMap--->'+allExistingPortalUserByEmailMap);
            
            existedUserWrapper existedUserWrap = getExistingActiveUser(userEmailSet, failedUserMap);
            activeUserByEmailMap = existedUserWrap.activeUserMapByEMail;
            activeFailedUserMapByEMail = existedUserWrap.activeFailedUserMapByEMail;
            System.debug('activeUserByEmailMap-->'+activeUserByEmailMap);
            System.debug('activeFailedUserMapByEMail-->'+activeFailedUserMapByEMail);
            
            for(User objUser : userMap.Values()){
                oktaCallout(objUser);
            }
        }
        // catch statement for exceptions.
        catch (Exception e) {
            Custom_Error_Log__c exceptionErrorLog = new Custom_Error_Log__c();
            exceptionErrorLog.Class__c = 'OktaUserUtility';
            exceptionErrorLog.Exception_Message__c = e.getmessage();
            exceptionErrorLog.ErrorTrace__c = e.getStackTraceString();
            OktaCalloutSelector.errorLogList.add(exceptionErrorLog);
        } 
        
        // Finally block
        finally{
            
            // Send Welcome Email
            if(!newUserMap.isEmpty() && !activationUrlByUserIdMap.isEmpty()){
                OktaCalloutHandler.sendWelcomeEmail(newUserMap, activationUrlByUserIdMap, true);
            }
            // Send welcome Email for existing user
            if(!existingUserMap.isEmpty()){
                OktaCalloutHandler.sendWelcomeEmail(existingUserMap, activationUrlByUserIdMap, false);
            }
            
            System.debug('errorLogList: '+OktaCalloutSelector.errorLogList);
            if(!OktaCalloutSelector.errorLogList.isEmpty()){
                upsert OktaCalloutSelector.errorLogList;
            }
            
            //upadte api status for failure record
            if(!OktaCalloutSelector.updateUserMap.isEmpty() && !Test.isRunningTest()){
                update OktaCalloutSelector.updateUserMap.values();
            }
            
            if(!frozenUserByIdMap.isEmpty() || !unFrozenUserByIdMap.isEmpty()){
                System.enqueueJob(new OktaFreezeUsersSync(frozenUserByIdMap, unFrozenUserByIdMap));
            }
        }
    }
    
    public static void oktaCallout(User objUser){
        
        OktaUserUtility.oktaUser_Id = objUser.Okta_UserId__c;
        System.debug('objUser.Okta_Flow_Status__c:: '+objUser.Okta_Flow_Status__c+'objUser--->'+objUser);
        // Re-Activate Okta User from SFDC User "Re-Activate Okta User" Custom link button:
        if(objUser.Okta_Flow_Status__c == 'Re-Activate'){
            String queryParam = objUser.Okta_UserId__c+'/lifecycle/activate?sendEmail=false';
            OktaCalloutHandler.sendUserDetails(queryParam, '', 'POST', '1003', objUser.UserType, 'API-1003: User Re-activation Failure from Custom Link', objUser.Id, false);
        }

        String apiStatus = objUser.API_Status__c;
        System.debug('apiStatus--->'+apiStatus);
        switch on apiStatus {
            // Sync User basic details to Okta
            when 'Success',null{
                System.debug('objUser--->'+objUser);
                if(objUser.Okta_UserId__c != null){
                    OktaCalloutSelector.UserData resJsonBodyUpdateUserName = null;
                    String OktaUserId = objUser.Okta_UserId__c;
                    resJsonBodyUpdateUserName = OktaUserUtility.updateApplicationUserName(objUser, objUser.Username, 'API-1004: Update UserName Failure', OktaUserId);
                    if(resJsonBodyUpdateUserName != null
                        && resJsonBodyUpdateUserName.errorSummary == null){
                            // [API 1007] Update Application Attributes for User
                            OktaUserUtility.updateAppAttributes(objUser, OktaUserId, 'API-1005: New User Update Application Attributes Failure');
                    }
                }
            }
            
            when 'API-1002: New User Creation Failure'{
                if(objUser.Okta_UserId__c == null){
                    //API-1002: New User Creation Failure
                    OktaUserUtility.createNewUser(objUser, newUserMap, activationUrlByUserIdMap);
                }
            }
            
            when 'API-1003: New User Activation Failure' {
                OktaCalloutSelector.UserData activationResJsonBodyActivation = null;
                // [API 1003] Activate User and get activation token
                activationResJsonBodyActivation = OktaUserUtility.activateUser(objUser.Okta_UserId__c, objUser.UserType, 'API-1003: New User Activation Failure', objUser.Id);
                
                if(activationResJsonBodyActivation != null && activationResJsonBodyActivation.errorSummary == null) {
                    activationUrlByUserIdMap.put(objUser.Id, activationResJsonBodyActivation.activationUrl);
                    // [API 1007] Update Application Attributes for User
                    OktaUserUtility.updateAppAttributes(objUser, objUser.Okta_UserId__c, 'API-1005: New User Update Application Attributes Failure');
                    //Send Welcome Email + set Password
                    newUserMap.put(objUser.Id, objUser);
                }
            }
            when 'API-1005: New User Update Application Attributes Failure' {
                OktaCalloutSelector.UserData deactivateResponse = null;
                
                deactivateResponse = OktaCalloutHandler.sendUserDetails(objUser.Okta_UserId__c, '', 'POST', '1007', objUser.UserType, 'API-1007: User Deactivation Failure', objUser.Id, false);
                System.debug('deactivateResponse-->'+deactivateResponse);
                if(deactivateResponse != null){
                    // [API 1003] Activate User and get activation token
                    OktaCalloutSelector.UserData activationResJsonBodyActivation = OktaUserUtility.activateUser(objUser.Okta_UserId__c, objUser.UserType, 'API-1003: New User Activation Failure', objUser.Id);
                    System.debug('activationResJsonBodyActivation--->'+activationResJsonBodyActivation);
                    if(activationResJsonBodyActivation!= null && activationResJsonBodyActivation.errorSummary == null){
                        activationUrlByUserIdMap.put(objUser.Id, activationResJsonBodyActivation.activationUrl);
                        
                        // [API 1007] Update Application Attributes for User
                        OktaUserUtility.updateAppAttributes(objUser, objUser.Okta_UserId__c, 'API-1005: New User Update Application Attributes Failure');
                        
                        // Send Welcome Email + set Password
                        newUserMap.put(objUser.Id, objUser);
                        System.debug('activationUrlByUserIdMap-->'+activationUrlByUserIdMap);
                        System.debug('newUserMap-->'+newUserMap);
                    }
                }
            }
            when 'API-1004: Update Partner User Application Failure', 'API-1004: Update Customer User Application Failure' {
                OktaCalloutSelector.UserData resJsonBodyUpdateUserName = null;
                String OktaUserId = objUser.Okta_UserId__c != null?objUser.Okta_UserId__c:allExistingPortalUserByEmailMap.get(objUser.Email).Okta_UserId__c;
                OktaUserUtility.oktaUser_Id = allExistingPortalUserByEmailMap.get(objUser.Email).Okta_UserId__c;
                if(objUser.Okta_UserId__c == null &&
                   allExistingPortalUserByEmailMap?.containsKey(objUser.Email)){
                       resJsonBodyUpdateUserName = OktaUserUtility.updateApplicationUserName(objUser, objUser.Username, apiStatus, OktaUserId);
                   }
                
                if(objUser.Okta_UserId__c != null && 
                   resJsonBodyUpdateUserName == null){
                       resJsonBodyUpdateUserName = OktaUserUtility.updateApplicationUserName(objUser, objUser.Username, 'API-1004: Update UserName Failure', OktaUserId);
                   }
                
                
                // [API 1007] Update Application Attributes for User
                OktaUserUtility.updateAppAttributes(objUser, OktaUserId, 'API-1005: Update User Attributes Failure');
                
                // Send Welcome email for existing user to provide partner/customer login access
                if(objUser.Okta_UserId__c == null){
                    existingUserMap.put(objUser.Id, objUser);
                }
                
            }
            when 'API-1005: Update User Attributes Failure'{
                
                String OktaUserId = objUser.Okta_UserId__c != null?objUser.Okta_UserId__c:allExistingPortalUserByEmailMap.get(objUser.Email).Okta_UserId__c;
                OktaUserUtility.oktaUser_Id = allExistingPortalUserByEmailMap.get(objUser.Email).Okta_UserId__c;
                // [API 1007] Update Application Attributes for User
                OktaUserUtility.updateAppAttributes(objUser, OktaUserId, apiStatus);
                
                // Send Welcome email for existing user to provide partner/customer login access
                if(objUser.LastModifiedDate == objUser.CreatedDate){
                    existingUserMap.put(objUser.Id, objUser);
                }
            }
            when 'API-1003: User Re-activation Failure' {
                OktaCalloutSelector.UserData resJsonBodyReactivation = null;
                String OktaUserId = objUser.Okta_UserId__c != null?objUser.Okta_UserId__c:allExistingPortalUserByEmailMap.get(objUser.Email).Okta_UserId__c;
                if((objUser.isActive
                    && existingActiveUserByEmailMap.isEmpty() )){
                        // [API 1003] Activate User and get activation token
                        resJsonBodyReactivation = OktaUserUtility.activateUser(objUser.Okta_UserId__c, objUser.UserType, 'API-1003: User Re-activation Failure', objUser.Id);
                        activationUrlByUserIdMap.put(objUser.Id, resJsonBodyReactivation.activationUrl);
                        newUserMap.put(objUser.Id, objUser);
                    }
                // Once User Active, below Code to Update User Attributes
                
                // [API 1006] Update User profile with Application name [sfdcCustomerPortalUsername/sfdcPartnerPortalUsername]
                OktaCalloutSelector.UserData resJsonBodyUpdateApplication = OktaUserUtility.updateApplicationUserName(objUser, objUser.Username, 'API-1004: Re-activated User App Failure', OktaUserId);
                if(resJsonBodyUpdateApplication != null && resJsonBodyUpdateApplication.errorSummary == null){
                    // [API 1007] Update Application Attributes for User
                    OktaUserUtility.updateAppAttributes(objUser, OktaUserId, 'API-1005: Re-activated User Attributes Failure');
                }
                // Sending Email to Login: New User created on existing user.
                if(resJsonBodyReactivation == null){
                    existingUserMap.put(objUser.Id, objUser);
                }
            }
            when 'API-1004: Re-activated User App Failure', 'API-1005: Re-activated User Attributes Failure' {
                OktaCalloutSelector.UserData resJsonBodyReactivation = null;
                OktaCalloutSelector.UserData deactivateResponse = null;
                
                String OktaUserId = objUser.Okta_UserId__c != null?objUser.Okta_UserId__c:allExistingPortalUserByEmailMap.get(objUser.Email).Okta_UserId__c;
                System.debug('OktaUserId-->'+OktaUserId);
                
                // If existing Active User Not Present
                if(!activeUserByEmailMap.containsKey(objUser.Email)){
                    
                    // De-Activating Okta User When both Partner & Customer user is In-Active in SF
                    deactivateResponse = OktaCalloutHandler.sendUserDetails(objUser.Okta_UserId__c, '', 'POST', '1007', objUser.UserType, 'API-1007: User Deactivation Failure', objUser.Id, false);
                    if(deactivateResponse != null){
                        
                        // [API 1003] Activate User and get activation token
                        resJsonBodyReactivation = OktaUserUtility.activateUser(objUser.Okta_UserId__c, objUser.UserType, 'API-1003: User Re-activation Failure', objUser.Id);
                        activationUrlByUserIdMap.put(objUser.Id, resJsonBodyReactivation.activationUrl);
                        newUserMap.put(objUser.Id, objUser);
                    }
                }
                // [API 1006] Update User profile with Application name [sfdcCustomerPortalUsername/sfdcPartnerPortalUsername]
                OktaCalloutSelector.UserData resJsonBodyUpdateApplication = OktaUserUtility.updateApplicationUserName(objUser, objUser.Username, 'API-1004: Re-activated User App Failure', OktaUserId);
                if(resJsonBodyUpdateApplication != null && resJsonBodyUpdateApplication.errorSummary == null){
                    // [API 1007] Update Application Attributes for User
                    OktaUserUtility.updateAppAttributes(objUser, OktaUserId, 'API-1005: Re-activated User Attributes Failure');
                }
                // Sending Email to Login: New User created on existing user.
                if(resJsonBodyReactivation == null){
                    existingUserMap.put(objUser.Id, objUser);
                }
            }
            when 'API-1004: User App Deactivation Failure' {
                // [API 1006] remove Application name based on UserType from [sfdcCustomerPortalUsername/sfdcPartnerPortalUsername]
                OktaCalloutSelector.UserData resJsonBody = OktaUserUtility.updateApplicationUserName(objUser, null, 'API-1004: User App Deactivation Failure', objUser.Okta_UserId__c);
                // [API 1003] Deactivating User in Okta If both CU + PU De-Activated
                if(resJsonBody != null &&
                   resJsonBody.Profile.sfdcPartnerPortalUsername == null &&
                   resJsonBody.Profile.sfdcCustomerPortalUsername == null){
                       System.debug('in deactivation');
                       // De-Activating Okta User When both Partner & Customer user is In-Active in SF
                       OktaCalloutHandler.sendUserDetails(resJsonBody.id, '', 'POST', '1007', objUser.UserType, 'API-1007: User Deactivation Failure', objUser.Id, false);
                   }
            }
            when 'API-1007: User Deactivation Failure' {
                // De-Activating Okta User When both Partner & Customer user is In-Active in SF
                OktaCalloutHandler.sendUserDetails(objUser.Okta_UserId__c, '', 'POST', '1007', objUser.UserType, 'API-1007: User Deactivation Failure', objUser.Id, false);
            }
            when 'API-1004: Multiple User App Deactivation Failure'{
                User existingUser = existingActiveSupportUserByEmailMap?.get(objUser.Email)[0];
                OktaCalloutSelector.UserData resJsonBody = OktaUserUtility.updateApplicationUserName(existingUser, existingUser.Email, 'API-1004: Multiple User App Deactivation Failure', existingUser.Okta_UserId__c);
                if(resJsonBody != null && resJsonBody.errorSummary == null){
                    // [API 1005] Update Application Attributes for User
                    OktaUserUtility.updateAppAttributes(existingUser, resJsonBody.id, 'API-1005: Multiple User Update Attributes Failure');
                }
            }
            when 'API-1005: Multiple User Update Attributes Failure' {
                // [API 1005] Update Application Attributes for User
                User existingUser = existingActiveSupportUserByEmailMap.get(objUser.Email)[0];
                OktaUserUtility.updateAppAttributes(existingUser, existingUser.Okta_UserId__c, 'API-1005: Multiple User Update Attributes Failure');
            }
            when 'API-1011: Okta User Suspend Failure'{
                OktaCalloutSelector.UserData oktaResp = null;
                // De-Activating Okta User When both Partner & Customer user is In-Active in SF
                oktaResp = OktaCalloutHandler.sendUserDetails(objUser.Okta_UserId__c, '', 'POST', '1011', objUser.UserType, 'API-1011: Okta User Suspend Failure', objUser.Id, false);
                if(oktaResp.errorSummary != null){
                    apiStatus = 'API-1011: Okta User Suspend Failure';
                }else{
                    objUser.Is_Okta_User_Frozen__c = true;
                }
                objUser.API_Status__c = apiStatus;
                objUser.Okta_UserId__c = objUser.Okta_UserId__c;
                OktaCalloutSelector.updateUserMap.put(objUser.Id, objUser);
            }
            when 'API-1012: Okta User UnSuspend Failure'{
                OktaCalloutSelector.UserData oktaResp = null;
                // De-Activating Okta User When both Partner & Customer user is In-Active in SF
                oktaResp = OktaCalloutHandler.sendUserDetails(objUser.Okta_UserId__c, '', 'POST', '1012', objUser.UserType, 'API-1012: Okta User UnSuspend Failure', objUser.Id, false);
                if(oktaResp.errorSummary != null){
                    apiStatus = 'API-1012: Okta User UnSuspend Failure';
                }
                else{
                    objUser.Is_Okta_User_Frozen__c = false;
                }
                objUser.API_Status__c = apiStatus;
                objUser.Okta_UserId__c = objUser.Okta_UserId__c;
                OktaCalloutSelector.updateUserMap.put(objUser.Id, objUser);
            }
            
            when 'API-1004: UnFrozen User App Failure'{
                //// Add UnFrozened User Application in Okta
                OktaCalloutSelector.UserData resJsonBody = OktaUserUtility.updateApplicationUserName(objUser, objUser.UserName, 'API-1004: UnFrozen User App Failure', objUser.Okta_UserId__c);
                if(resJsonBody.errorSummary == null ){
                    // [API 1005] Update Application Attributes for UnFrozen User
                    OktaUserUtility.updateAppAttributes(objUser, resJsonBody.id, 'API-1005: UnFrozen User Update Attributes Failure');
                    objUser.Is_Okta_User_Frozen__c = false;
                    OktaCalloutSelector.updateUserMap.put(objUser.Id, objUser);
                    unFrozenUserByIdMap.put(objUser.Id, new OktaFreezeUsersSchedulableBatch.FreezeUserWrap(objUser, 'Unfreeze'));
                }
            }
            
            when 'API-1004: Frozen User App Failure'{
                objUser.Is_Okta_User_Frozen__c = true;
                OktaCalloutSelector.updateUserMap.put(objUser.Id, objUser);
                if(objUser.UserType == 'CspLitePortal'
                   && !existingUnFrozenCustomerUsersByEmailMap.isEmpty()
                   && existingUnFrozenCustomerUsersByEmailMap.containsKey(objUser.Email)){
                       OktaCalloutSelector.UserData resJsonBody = OktaUserUtility.updateApplicationUserName(objUser, objUser.UserName, 'API-1004: Frozen User App Failure', objUser.Okta_UserId__c);
                       // [API 1005] Update Application Attributes for UnFrozen User
                       if(resJsonBody.errorSummary == null ){
                           OktaUserUtility.updateAppAttributes(objUser, resJsonBody.Id, 'API-1005: UnFrozen User Update Attributes Failure');
                       }
                   }
                
                else{
                    System.debug('Suspending  '+objUser.Email );
                    
                    // Remove Frozen User Application from Okta
                    OktaCalloutSelector.UserData resJsonBody = OktaUserUtility.updateApplicationUserName(objUser, null, 'API-1004: Frozen User App Failure', objUser.Okta_UserId__c);
                    
                    // Suspend Okta User Only if there are no Active UnFrozen Users present in SF
                    if(resJsonBody.errorSummary == null ){
                        // Avoid Suspend: If Existing User (CU/PU) is UnFrozen in SF
                        if(!existingUnFrozenUsersByEmailMap?.containsKey(objUser.Email)){
                            frozenUserByIdMap.put(objUser.Id, new OktaFreezeUsersSchedulableBatch.FreezeUserWrap(objUser, 'Freeze'));
                        }
                    }
                }
            }
            when 'API-1005: UnFrozen User Update Attributes Failure'{
                if(userLoginByUserIdMap.get(objUser.Id).isFrozen){
                    OktaUserUtility.updateAppAttributes(objUser, objUser.Okta_UserId__c, 'API-1005: UnFrozen User Update Attributes Failure');
                }else{
                    OktaUserUtility.updateAppAttributes(objUser, objUser.Okta_UserId__c, 'API-1005: UnFrozen User Update Attributes Failure');
                    objUser.Is_Okta_User_Frozen__c = false;
                    OktaCalloutSelector.updateUserMap.put(objUser.Id, objUser);
                    unFrozenUserByIdMap.put(objUser.Id, new OktaFreezeUsersSchedulableBatch.FreezeUserWrap(objUser, 'Unfreeze'));
                }
            }
        }
    }
    
    public class Requests{
        @InvocableVariable
        public User userRecord;
    }
    public static existedUserWrapper getExistingActiveUser(Set<String> userEmailSet, Map<Id,User> failedUserMap){
        Set<String> userFieldSet = new Set<String>();
        for(SF_Okta_Field_Mapping__mdt objMtd : [SELECT SF_Field_API_Name__c, Okta_Field_API_Name__c 
                                                 FROM SF_Okta_Field_Mapping__mdt]){
                                                     userFieldSet.add(objMtd.SF_Field_API_Name__c);
                                                 }
        String portalProfileFilter = 'UserType = \'CspLitePortal\' OR UserType = \'PowerPartner\'';
        String userQueryString = 'SELECT UserType, Okta_UserId__c, API_Status__c, CreatedDate, LastModifiedDate, '+ String.escapeSingleQuotes(String.join(new List<String>(userFieldSet), ', ')) + ' FROM ';
        userQueryString += 'User WHERE ('+portalProfileFilter+') AND Email IN : userEmailSet';
        List<User> userObjList = Database.query(userQueryString);
        
        Map<String, User> activeUserMapByEMail = new Map<String, User>();
        Map<String, User> activeFailedUserMapByEMail = new Map<String, User>();
        for(User userObjins : userObjList){
            if(!activeUserMapByEMail.containsKey(userObjins.Email) && 
               userObjins.isActive && userObjins.API_Status__c == 'Success' &&
               !failedUserMap.containsKey(userObjins.Id)){
                   activeUserMapByEMail.put(userObjins.Email, userObjins);
               }
            if(!activeFailedUserMapByEMail.containsKey(userObjins.Email) &&
               userObjins.isActive &&
               userObjins.API_Status__c == 'Success'){
                   activeFailedUserMapByEMail.put(userObjins.Email, userObjins);
               }
           
        }
        return new existedUserWrapper(activeUserMapByEMail, activeFailedUserMapByEMail);                                         
        
    }
    public class existedUserWrapper{
        public Map<String, User> activeUserMapByEMail {get;set;}
        public Map<String, User> activeFailedUserMapByEMail {get;set;}
        
        public existedUserWrapper(Map<String, User> activeUserMapByEMail, Map<String, User> activeFailedUserMapByEMail){
            
            this.activeUserMapByEMail = activeUserMapByEMail;
            this.activeFailedUserMapByEMail = activeFailedUserMapByEMail;
        }
    }
    
}