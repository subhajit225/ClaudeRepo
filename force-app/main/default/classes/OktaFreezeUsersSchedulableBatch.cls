/**
* @Author      : Vijay Kumar K R (Customer)
* @CreatedDate : Apr 06, 2023 
* @TstClass    : OktaUserUtilityTest
* @Description :
* -------------------------- @History -------------------------------------
* Story Number       Modified By              Date           Description
* 
* -------------------------------------------------------------------------
*/
global class OktaFreezeUsersSchedulableBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {

    public List<Custom_Error_Log__c> freezeErrorLogList = new List<Custom_Error_Log__c>();
    public Map<Id, User> freezeUpdateUserMap = new Map<Id, User>();
    
    public Map<String, List<User>> existingUnFrozenUsersByEmailMap = new Map<String, List<User>>();
    public Map<String, List<User>> existingUnFrozenCustomerUsersByEmailMap = new Map<String, List<User>>();

    global Database.QueryLocator start(Database.BatchableContext bc){
        // Query String
        String userLoginQueryString = 'SELECT Id, isFrozen, UserId FROM UserLogin Order By LastModifiedDate DESC LIMIT 20';
        System.debug('userLoginQueryString:: '+userLoginQueryString);
        return Database.getQueryLocator(userLoginQueryString);
    }
    
    global void execute(Database.BatchableContext bc, List<UserLogin> userLoginList){

        System.debug('userLoginList siez: '+userLoginList.size());
        Map<Id, User> updateUserMap = new Map<Id, User>();
        Map<Id, FreezeUserWrap> frozenUserByIdMap = new Map<Id, FreezeUserWrap>();
        Map<Id, FreezeUserWrap> unFrozenUserByIdMap = new Map<Id, FreezeUserWrap>();
        Set<String> userFieldSet = new Set<String>();

        // Users Fields from Mtd
        for(SF_Okta_Field_Mapping__mdt objMtd : [SELECT SF_Field_API_Name__c, Okta_Field_API_Name__c 
                                                 FROM SF_Okta_Field_Mapping__mdt]){
                                                     userFieldSet.add(objMtd.SF_Field_API_Name__c);
        }

        try {

            OktaUserUtility.getOktaFieldsByPortalUserFields();
            
            Map<Id, UserLogin> userLoginByUserIdMap = new Map<Id, UserLogin>();
            Set<Id> frozenUserIdSet = new Set<Id>();
            // UserType Filter String
            String portalProfileFilter = 'UserType = \'CspLitePortal\' OR UserType = \'PowerPartner\'';

            for(UserLogin objUl : [SELECT Id, isFrozen, UserId FROM UserLogin WHERE Id IN: userLoginList]){
                userLoginByUserIdMap.put(objUl.UserId, objUl);
                if(objUl.isFrozen){
                    frozenUserIdSet.add(objUl.UserId);
                }
            }

            Map<String, Id> userIdByEmailMap = new Map<String, Id>();
            for(User user : [SELECT Id, Email FROM User WHERE Id IN: userLoginByUserIdMap.keySet()]){
                userIdByEmailMap.put(user.Email, user.Id);
            }
            
            if(!userIdByEmailMap.isEmpty()){
                Set<String> userEmailSet =  userIdByEmailMap.keySet();
                // Query String
                String userQueryString = 'SELECT Okta_UserId__c, API_Status__c, UserType, Is_Okta_User_Frozen__c, '+ String.escapeSingleQuotes(String.join(new List<String>(userFieldSet), ', ')) + ' FROM ';
                userQueryString += 'User WHERE ('+portalProfileFilter+') AND isActive = true AND API_Status__c != null AND Okta_UserId__c != null AND Email IN: userEmailSet Order By CreatedDate DESC' ;
                
                for(User objUser : Database.query(userQueryString)){
                    
                    UserLogin objUl = userLoginByUserIdMap.get(userIdByEmailMap.get(objUser.Email));
                    if(!frozenUserIdSet.contains(objUser.Id)){
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
            }
           
            System.debug('existingUnFrozenUsersByEmailMap: '+existingUnFrozenUsersByEmailMap);
            System.debug('existingUnFrozenCustomerUsersByEmailMap: '+existingUnFrozenCustomerUsersByEmailMap);
            
            Set<Id> userIdSet =  userLoginByUserIdMap.keySet();
            // Query String
            String userQueryString = 'SELECT Okta_UserId__c, API_Status__c, UserType, Is_Okta_User_Frozen__c, '+ String.escapeSingleQuotes(String.join(new List<String>(userFieldSet), ', ')) + ' FROM ';
            userQueryString += 'User WHERE ('+portalProfileFilter+') AND isActive = true AND API_Status__c != null AND Okta_UserId__c != null AND Id IN: userIdSet Order By CreatedDate DESC' ;
            System.debug('userQueryString:: '+userQueryString);

            // While Data Migration, If Existing User is Frozen in SF and Okta team need to suspend this User in Okta as well
            for(User objUser : Database.query(userQueryString)){
                UserLogin objUl = userLoginByUserIdMap.get(objUser.Id);
                // If User if Frozen in SF and Status is Not Suspended
                
                if(objUl.isFrozen 
                    && !objUser.Is_Okta_User_Frozen__c){
                        System.debug('User Iffff '+objUser.Email );
                        // update SF field
                        objUser.Is_Okta_User_Frozen__c = true;
                        updateUserMap.put(objUser.Id, objUser);

                        // Check for Multiplt Customer Users
                        if(objUser.UserType == 'CspLitePortal'
                            && !existingUnFrozenCustomerUsersByEmailMap.isEmpty()
                            && existingUnFrozenCustomerUsersByEmailMap.containsKey(objUser.Email)){
                                System.debug('Multiplt CU '+objUser.Email );

                                User existingUser = existingUnFrozenCustomerUsersByEmailMap.get(objUser.Email)[0];
                                // Update existing CUstomer UserName in Okta Application
                                OktaCalloutSelector.UserData resJsonBody = OktaUserUtility.updateApplicationUserName(objUser, existingUser.UserName, 'API-1004: Frozen User App Failure', objUser.Okta_UserId__c);
                                // [API 1005] Update Application Attributes for UnFrozen User
                                if(resJsonBody.errorSummary == null ){
                                    OktaUserUtility.updateAppAttributes(existingUser, resJsonBody.Id, 'API-1005: UnFrozen User Update Attributes Failure');
                                }
                        }else{
                            System.debug('Suspending  '+objUser.Email );
                            // Remove Frozen User Application from Okta
                            OktaCalloutSelector.UserData resJsonBody = OktaUserUtility.updateApplicationUserName(objUser, null, 'API-1004: Frozen User App Failure', objUser.Okta_UserId__c);
                            // Suspend Okta User Only if there are no Active UnFrozen Users present in SF
                            if(resJsonBody.errorSummary == null ){
                                // Avoid Suspend: If Existing User (CU/PU) is UnFrozen in SF
                                if(!existingUnFrozenUsersByEmailMap?.containsKey(objUser.Email)){
                                    frozenUserByIdMap.put(objUser.Id, new FreezeUserWrap(objUser, 'Freeze'));
                                }
                            }
                        }
                }
                // If User if UnFrozen in SF and Status is Suspended
                else if(!objUl.isFrozen 
                        // Process Only Re-Frozen User into Okta
                        && objUser.Is_Okta_User_Frozen__c){
                            System.debug('UnSuspend objUser: '+objUser.Email);
                            // Add UnFrozened User Application in Okta
                            OktaCalloutSelector.UserData resJsonBody = OktaUserUtility.updateApplicationUserName(objUser, objUser.UserName, 'API-1004: UnFrozen User App Failure', objUser.Okta_UserId__c);
                            // UnSuspend Okta User
                            if(resJsonBody.errorSummary == null ){
                                // [API 1005] Update Application Attributes for UnFrozen User
                                OktaUserUtility.updateAppAttributes(objUser, resJsonBody.id, 'API-1005: UnFrozen User Update Attributes Failure');
                                objUser.Is_Okta_User_Frozen__c = false;
                                updateUserMap.put(objUser.Id, objUser);
                                unFrozenUserByIdMap.put(objUser.Id, new FreezeUserWrap(objUser, 'Unfreeze'));
                            }
                        }
            }

        } catch (Exception e) {
            Custom_Error_Log__c exceptionErrorLog = new Custom_Error_Log__c();
            exceptionErrorLog.Class__c = 'OktaFreezeUsersSchedulableBatch';
            exceptionErrorLog.Exception_Message__c = e.getmessage();
            exceptionErrorLog.ErrorTrace__c = e.getStackTraceString();
            OktaCalloutSelector.errorLogList.add(exceptionErrorLog);
        }

        // Finally block
        finally{
            System.debug('OktaFreezeUsersSchedulableBatch errorLogList: '+OktaCalloutSelector.errorLogList);
            if(!OktaCalloutSelector.errorLogList.isEmpty()){
                upsert OktaCalloutSelector.errorLogList;
            }

            system.debug('Freeze updateUserMap: '+updateUserMap);
            //upadte api status for failure record
            if(!updateUserMap.isEmpty() && !Test.isRunningTest()){
                // Executing below code as System Admin context
                update updateUserMap.values();
            }

            System.debug('finish size frozenUserByIdMap: '+frozenUserByIdMap.size());
            System.debug('finish size unFrozenUserByIdMap: '+unFrozenUserByIdMap.size());
            if(!frozenUserByIdMap.isEmpty() || !unFrozenUserByIdMap.isEmpty()){
                System.enqueueJob(new OktaFreezeUsersSync(frozenUserByIdMap, unFrozenUserByIdMap));
            }
        }
        
    }

    global void finish(Database.BatchableContext bc){
        // Batch Execute for every 4min
        if(!Test.isRunningTest()) {
            System.scheduleBatch(new OktaFreezeUsersSchedulableBatch(), 'Okta Sync Freeze Users - Class : OktaFreezeUsersSchedulableBatch - '+ datetime.now(), 4, 200);
        }
    }

    public class FreezeUserWrap{
        public User objUser {get;set;}
        public String userFreezeState {get;set;}

        public FreezeUserWrap(User objUser, String userFreezeState){
            this.objUser = objUser;
            this.userFreezeState = userFreezeState;
        }
    }
}