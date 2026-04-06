/**
* @Author      : (Vijay Kumar K R) Customer Portal
* @CreatedDate : Ap 03, 2023 
* @TstClass    : 
* @Description :
* -------------------------- @History -------------------------------------
* Story Number       Modified By              Date           Description
* 
* -------------------------------------------------------------------------
*/
public without sharing class OktaFreezeUsersSync implements Queueable, Database.AllowsCallouts{
    
    Map<Id, OktaFreezeUsersSchedulableBatch.FreezeUserWrap> processUserRecord = new Map<Id, OktaFreezeUsersSchedulableBatch.FreezeUserWrap>();
    Map<Id, OktaFreezeUsersSchedulableBatch.FreezeUserWrap> unFrozenUserByIdMap = new Map<Id, OktaFreezeUsersSchedulableBatch.FreezeUserWrap>();

    public oktaFreezeUsersSync(Map<Id, OktaFreezeUsersSchedulableBatch.FreezeUserWrap> processUserRecord, Map<Id, OktaFreezeUsersSchedulableBatch.FreezeUserWrap> unFrozenUserByIdMap) {
        this.processUserRecord = processUserRecord;
        this.unFrozenUserByIdMap = unFrozenUserByIdMap;
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
        
        Map<Id, User> updateUserMap = new Map<Id, User>();

        System.debug('frozen records: '+processUserRecord);
        // If frozenUserByIdMap is Empty, unFrozenUserByIdMap not empty will process from below method 
        processFrozenUsers (processUserRecord, updateUserMap);

        System.debug('updateUserMap:: '+updateUserMap);
        if(!updateUserMap.isEmpty()){
            UPDATE updateUserMap.values();
        }
    }

    /**
    * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
    * @description: Process Frozen and unFrozen users
    * ───────────────────────────────────────────────────────────────────────────────────────────────────
    * Method        : processFrozenUsers 
    * @param        : Map<Id, OktaFreezeUsersSchedulableBatch.FreezeUserWrap> processUserRecord, Map<Id, User> updateUserMap
    * @return       : Void
    * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public void processFrozenUsers (Map<Id, OktaFreezeUsersSchedulableBatch.FreezeUserWrap> processUserRecord, Map<Id, User> updateUserMap){

        Set<Id> processIdSet = new Set<Id>();
        Boolean hitLimit = false;

        for(Id userId : processUserRecord.keySet()){
            OktaFreezeUsersSchedulableBatch.FreezeUserWrap objWpr = processUserRecord.get(userId);
            // break if max limits reached 
            if (Limits.getCallouts() == Limits.getLimitCallouts()) {
                hitLimit = true;
                break;
            }
            // callout
            makeCallout(objWpr.objUser, objWpr.userFreezeState, updateUserMap);
            // Track processed user records 
            processIdSet.add(userId);
        }

        System.debug('AA frozen processIdSet: '+processIdSet);

        // cleaning up the list of users needing a callout
        if(!processIdSet.isEmpty()){
            for (Id userId : processIdSet) {
                // removing all users that have been sent already
                processUserRecord.remove(userId);
            }
        }
        System.debug('AA frozen records: '+processUserRecord);

        if (hitLimit) {
            // process remainder user records
            System.enqueueJob(this);
        }
        // Process UnFreeze 
        else {
            System.debug('else unFrozenUserByIdMap: '+unFrozenUserByIdMap);
            if (!unFrozenUserByIdMap.isEmpty()) { 
                // process remainder user records
                processFrozenUsers (unFrozenUserByIdMap, updateUserMap);
            }
        }
    }

    /**
    * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
    * @description: Make Callout (Suspend/UnSuspend) to Okta based on User Freeze State
    * ───────────────────────────────────────────────────────────────────────────────────────────────────
    * Method        : makeCallout 
    * @param        : User objUser, String freezeSate
    * @return       : Void
    * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public void makeCallout (User objUser, String freezeSate, Map<Id, User> updateUserMap){
        
        OktaUserUtility.oktaUser_Id = objUser.Okta_UserId__c;

        OktaCalloutSelector.UserData oktaResp = null;
        String apiStatus = 'Success';
        switch on freezeSate{
            // [1011] suspend Okta User
            when 'Freeze' {
                // De-Activating Okta User When both Partner & Customer user is In-Active in SF
                oktaResp = OktaCalloutHandler.sendUserDetails(objUser.Okta_UserId__c, '', 'POST', '1011', objUser.UserType, 'API-1011: Okta User Suspend Failure', objUser.Id, false);
                if(oktaResp.errorSummary != null){
                    apiStatus = 'API-1011: Okta User Suspend Failure';
                }
            }
            // [1012] unsuspend Okta User
            when 'Unfreeze' {
                // De-Activating Okta User When both Partner & Customer user is In-Active in SF
                oktaResp = OktaCalloutHandler.sendUserDetails(objUser.Okta_UserId__c, '', 'POST', '1012', objUser.UserType, 'API-1012: Okta User UnSuspend Failure', objUser.Id, false);
                if(oktaResp.errorSummary != null){
                    apiStatus = 'API-1012: Okta User UnSuspend Failure';
                }
            }
        }
        objUser.API_Status__c = apiStatus;
        objUser.Okta_UserId__c = objUser.Okta_UserId__c;
        updateUserMap.put(objUser.Id, objUser);
    }

}