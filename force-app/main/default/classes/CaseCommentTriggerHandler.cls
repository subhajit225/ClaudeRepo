/**
* @description : CaseCommentTriggerHandler to handle the methods that are being called at case comment events
* @Author      : Shiva Sharma
* @TestClass    : CaseCommentTrigger_Test
* -------------------------- @History --------------------------------------------------------------------------------------------
* Story Number       Modified By              Date           Description
* Old Build       ----------------------------------------------------
* CS21-1368       Shiva Sharma             11/24/2022     Added check to enable assignement for Digital case
* CS21-1535       Shiva Sharma             2/23/2023      Completing First milestone on case comment from
* CS21-1840       Shiva Sharma             8/25/2023      Added Logic to update Subphase on case comment update only if origin is portal.
* CS21-1806       Raveesh Layal            8/28/2023      Auto Populate NCC values (REMOVED)
* CS21-100        Shiva Sharma             11/18/2023     Changed field from comment to text
* CS21-2009        Vijay Kumar K R        Dec 19 2023     Request to have 'Initial Case Owner' field in SFDC cases owned by Proactive Support Team
* CS21-3005        Vijay Kumar K R        Jan 10 2025     New Field and Logic on Case Object: Last Customer Update
* CS21-3033      Vijay Kumar K R    Jan 27 2025   US ASE / FED queue and routing changes FY25
* CS21-3568		Shailesh Kumar			  19, Nov, 2025   Fixed Null pointer exception and test class coverage
*/
public class CaseCommentTriggerHandler{
    /**
     * @description Stores Case Ids that have already been processed
     */
    public static Set<Id> processedCases = new Set<Id>();
    /**
     * @description Internal flag to determine whether the handler is currently executing.
     */
    private boolean m_isExecuting = false;
    /**
     * @description Stores the trigger batch size for operational use.
     */
    private integer BatchSize = 0;
    /**
     * @description Indicates whether the execution originated from a batch job.
     */
    public static boolean IsFromBachJob ;
    /**
     * @description Indicates whether the execution originated from the Upload API.
     */
    public static boolean isFromUploadAPI=false;
    /**
     * @description Set of Case Ids for NCC (Next Case Comment?) updates.
     */
    public static Set<Id> caseIdsforNCCUpdate = new Set<Id>();
    
    /**
     * @description constructor for class
     * @param isExecuting
     * @param size
     */
    public CaseCommentTriggerHandler(boolean isExecuting, integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }

    /**
     * @description onBeforeInsert
     * @param newCaseComment
     */
    public void onBeforeInsert(List<CaseComment> newCaseComment){
        Set<Id> caseIds = new Set<Id>();
        List<String> ListcaseMileIds = new List<String>();
        set<String> caseMileIds = new set<String>();
        for(CaseComment cs : newCaseComment){
            caseIds.add(cs.ParentId);
        }
        map<Id,case> mapOfCase = new map<Id,case>([Select id,Workaround_Verified__c,status,E2CAdv__Public_Recent_Comments_Text__c, Ncc_Date__c, origin from case where ID IN : caseIds]);

        for(CaseComment cs : newCaseComment){
            //CS-586 Akashdeep Singh
            system.debug(LoggingLevel.DEBUG,'//Ashwini isPublic'+cs.Ispublished);
            if(UserInfo.getUserId() != Label.Context_User_Id && !Label.Rubrik_Community_Profiles.containsIgnoreCase(UserInfo.getProfileId()) && mapOfCase!=null && !mapOfCase.isEmpty() && mapOfCase.containsKey(cs.parentId) && cs.Ispublished == true){
                caseMileIds.add(cs.parentId+'_'+mapOfCase.get(cs.parentId).status+'_Comment');
                //CS21-1535
                processedCases.add(cs.parentId);
            }
        }
        //CS21-1535
        if(!System.isBatch() && !System.isFuture() && !processedCases.isEmpty()){
            CaseCommentTriggerHandler.completeInitalResponse(processedCases);
        }
        if(caseMileIds!=null && !caseMileIds.isEmpty()){
            ListcaseMileIds.addAll(caseMileIds);
            system.debug(LoggingLevel.DEBUG,'//Ashwini called from CasecommentHandler mapOfCase: '+mapOfCase);
            CaseTriggerHandler.completemilestone(ListcaseMileIds,mapOfCase);
        }
    }

    /**
     * @description caseOwnerChange
     * @param newCaseCommentList
     */
    public void caseOwnerChange(List<CaseComment> newCaseCommentList){
        Set<Id> caseIds = new Set<Id>();
        Set<Id> commentCreatorIdSet = new Set<Id>();
        
        Id profileId=userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId]?.Name;

        for(CaseComment eachCaseComment : newCaseCommentList){
            if(eachCaseComment.IsPublished) {
                caseIds.add(eachCaseComment.ParentId);
                commentCreatorIdSet.add(eachCaseComment.CreatedById);
            }
        }

        List<String> communityProfilesList = System.Label.Workday_Rubrik_Community_Profiles.split(';');

        Map<Id, User> userIdToUserMap = new Map<Id, User>([SELECT Id, Name, Email FROM User WHERE Id =: commentCreatorIdSet AND (Profile.Name =: communityProfilesList OR Name = 'Support Bot')]);

        // 3033: Added AccountId in SOQL
        Map<Id, Case> caseIdToCaseMap = new Map<Id, Case>([SELECT Id, US_Federal_Account__c, Owner.FirstName, Owner.Lastname, AccountId,
                                                           Owner.Email, Owner_Manager_Email__c, Automated_time_off_case_routing__c, Platform__c,
                                                           is_Digital_Case__c, Is_TA_Case__c, Account.US_Federal_Account__c
                                                           FROM Case
                                                           WHERE Id =: caseIds
                                                           AND (
                                                               (Owner_Time_Off__c = true
                                                                AND Automated_time_off_case_routing__c IN ('Automatic', '')
                                                                AND Owner_automated_time_off_case_routing__c IN ('Automatic', ''))
                                                               OR Automated_time_off_case_routing__c = 'Enable'
                                                               OR Owner_automated_time_off_case_routing__c = 'Enable'
                                                           )
                                                           AND Automated_time_off_case_routing__c != 'Disable'
                                                           AND Owner_automated_time_off_case_routing__c != 'Disable'
                                                           AND (Origin NOT IN ('Alert', 'Alert (come in email)', 'Health-check', 'Pulse', 'Alert_JIRA')
                                                           OR Account.US_Federal_Account__c = true)
                                                           AND Status NOT IN ('Closed', 'Resolved - Pending Customer', 'Resolved - Pending upgrade', 'Customer requested close')]);

        //CS21-561
        Map<Id,case> mapOfCase = new map<Id,case>([Select Initial_Case_Owner__c,Priority,Owner.Name,owner.type,owner.isActive,isclosed,id,Customer_s_First_Response__c,Customer_First_Contact__c,OwnerId,RecordTypeId,Workaround_Verified__c,status,E2CAdv__Public_Recent_Comments_Text__c, Ncc_Date__c, origin, Is_Digital_Case__c,Is_TA_Case__c,Account.US_Federal_Account__c from case where ID IN : caseIds]);

        if(!mapOfCase.isEmpty()){

            List<Case> caseUpdate = new List<Case>();
            //CS21-1368 - Converted Id of Queue to Map of Queue
            Map<String, Id> queueNameIdMap = new Map<String, Id>();
            for(Group g : [SELECT Id, Name, DeveloperName
                           FROM Group
                           WHERE Type = 'Queue'
                           AND DeveloperName IN ('Open_Queue_Digital', 'Unassigned_Cases')]){
                               queueNameIdMap.put(g.DeveloperName, g.Id);
                           }
            Id successCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Success').getRecordTypeId();
            for(CaseComment cs : newCaseCommentList){
                Boolean isUpdate = false;
                //CS21-561
                if(userIdToUserMap.containsKey(cs.CreatedById)){
                    if(mapOfCase.containsKey(cs.ParentId) && mapOfCase.get(cs.ParentId).Owner.Name == 'Proactive campaign'){
                        if(mapOfCase.get(cs.ParentId).Is_Digital_Case__c){//CS21-1368 - added check for Queue Assignment
                            mapOfCase.get(cs.ParentId).OwnerId = queueNameIdMap.get('Open_Queue_Digital');
                        }else{
                            mapOfCase.get(cs.ParentId).OwnerId = queueNameIdMap.get('Unassigned_Cases');
                        }
                        isUpdate = true;
                    }
                     //CS21-1840
                    if(caseIds.contains(cs.ParentId) && mapOfCase.containsKey(cs.ParentId) && mapOfCase.get(cs.ParentId).RecordTypeId == successCaseId && userIdToUserMap.get(cs.CreatedById).Name != 'Support Bot'){
                        mapOfCase.get(cs.ParentId).Sub_Phase__c = 'CSM Action Pending';
                        mapOfCase.get(cs.ParentId).Status = 'Waiting for Rubrik Support';
                        isUpdate = true;
                    }
                    if(mapOfCase.containsKey(cs.ParentId) && mapOfCase.get(cs.ParentId).RecordTypeId == successCaseId  && mapOfCase.get(cs.ParentId).Customer_s_First_Response__c == null){
                        mapOfCase.get(cs.ParentId).Customer_s_First_Response__c = system.now();
                        isUpdate = true;
                    }
                }else if(mapOfCase.containsKey(cs.ParentId) && mapOfCase.get(cs.ParentId).RecordTypeId == successCaseId  && cs.createdById == mapOfCase.get(cs.ParentId).OwnerId
                         && mapOfCase.get(cs.ParentId).Customer_First_Contact__c == null){
                             mapOfCase.get(cs.ParentId).Customer_First_Contact__c = system.now();
                             isUpdate = true;

                         }
                
                String supportUserProfileNameStr = 'Rubrik Customer Support User';
                // 2009
                List<String> byPassUserIdList = System.Label.ByPass_Initial_Case_Owner_UserIds.split(';');

                //CS21-2066 STARTS     
                if(caseIds.contains(cs.ParentId) 
                       && mapOfCase.containsKey(cs.ParentId) 
                       && mapOfCase.get(cs.ParentId).Initial_Case_Owner__c == null
                       && profileName.containsIgnoreCase(supportUserProfileNameStr)
                       && !byPassUserIdList.contains(cs.createdById)){
                            mapOfCase.get(cs.ParentId).Initial_Case_Owner__c=cs.createdById;
                            isUpdate = true; 
                }
                //CS21-2066 ENDS
                //
                if(isUpdate)
                    caseUpdate.add(mapOfCase.get(cs.ParentId));
            }
            System.debug(LoggingLevel.DEBUG,caseUpdate);
            if(!caseUpdate.isEmpty())
                update caseUpdate;
        }
        if(!caseIdToCaseMap.isEmpty()){
            Map<Id,Case> caseMap = new Map<Id,Case>();
            Map<Id, DateTime> caseToCreatedDateMap = new Map<Id, DateTime>();

            for(CaseComment eachCaseComment : newCaseCommentList){
                if(caseIdToCaseMap.containsKey(eachCaseComment.ParentId) && userIdToUserMap.containsKey(eachCaseComment.CreatedById)) {
                    Case commentCaseParentRecord = caseIdToCaseMap.get(eachCaseComment.ParentId);
                    caseMap.put(commentCaseParentRecord.Id, commentCaseParentRecord);
                    caseToCreatedDateMap.put(eachCaseComment.ParentId, eachCaseComment.CreatedDate);
                }
            }

            if(!caseMap.isEmpty() && !caseToCreatedDateMap.isEmpty()){
                Workday_GenericCaseOwnerChange.updateCaseOwnerToQueue(caseMap, caseToCreatedDateMap);
            }
        }
    }

    /**
     * @description updateLastCustomerUpdate
     * @param newCaseCommentList
     */
    public void updateLastCustomerUpdate(List<CaseComment> newCaseCommentList){

        Set<Id> userIdSet = new Set<Id>();
        for(CaseComment eachCaseComment : newCaseCommentList){
            if(eachCaseComment.IsPublished
                && (String.valueOf(eachCaseComment.CreatedById).startsWith('005'))) {
                    userIdSet.add(eachCaseComment.CreatedById);
            }
        }

        Set<Id> customerUserId = new Set<Id>();
        Map<Id, Case> caseUpdateMap = new Map<Id, Case>();

        if(!userIdSet.isEmpty()){
            for(User objUsr : [SELECT Id, Name FROM User WHERE Id IN: userIdSet AND ContactId != null]){
                customerUserId.add(objUsr.Id);
            }

            User supBotUser = [SELECT Id, Name FROM User WHERE Name Like '%Support bot%' Limit 1];
            customerUserId.add(supBotUser.Id);
            
            if(!customerUserId.isEmpty()){
                for(CaseComment eachCaseComment : newCaseCommentList){
                    if(eachCaseComment.IsPublished
                        && (String.valueOf(eachCaseComment.CreatedById).startsWith('005'))
                        && customerUserId.contains(eachCaseComment.CreatedById)) {
                            Case objCase = new Case(Id = eachCaseComment.ParentId);
                            objCase.Last_Customer_Update__c = System.now();
                            caseUpdateMap.put(objCase.Id, objCase);
                    }
                }
            }
        }
        
        if(!caseUpdateMap.isEmpty()){
            UPDATE caseUpdateMap.values();
        }
    }

    /**
     * @description completeInitalResponse //CS21-1535
     * @param caseIds
     */
    @future
    public static void completeInitalResponse(set<Id> caseIds){
        map<Id,Case> caseIdToCase =new map<Id,Case>();  
        List<caseMileStone> allCsmList = new List<caseMilestone>();
        allCsmList = [SELECT Id, MilestoneType.Name, CaseId,Case.Priority,Case.Createddate,
                      CompletionDate, isCompleted,MilestoneTypeId  
                      FROM caseMilestone
                      WHERE isCompleted = false
                      AND CaseID IN : caseIds
                      AND MilestoneType.Name like '%Initial%'
                      AND CompletionDate = null
                      ORDER BY TargetResponseInMins];
        for(CaseMilestone each : allCsmList){
            each.CompletionDate = system.now();
            if(each.Case.Priority!=null){
                caseIdToCase.put(each.CaseId,each.Case); 
            }
            
        }
        update allCsmList;  
        
        if(caseIdToCase.size()>0){
            ChangeInitialMilestoneFlagColor(caseIdToCase,null);
        }
        
        
    }
    
    /**
     * @description Updates the Initial Milestone Flag Name Field based on the Case Milestones Criteria
     * @param idToCase
     * @param caseNewMap
     */
    public static void changeInitialMilestoneFlagColor(Map<Id, Case> idToCase,map<Id,Case> caseNewMap) {
        if (idToCase == null || idToCase.isEmpty() || String.isBlank(Label.PriorityToTimeTriggerMinutes)) {
            return;
        }
        
        final String redFlag = 'Bold Red';
        final String greenFlag = 'Bold Green';
        String milestoneFlagColor;
        
        List<Case> casesToUpdate = new List<Case>();
        Map<String, Object> priorityToTimeTriggerMinutes;
        
        try {
            priorityToTimeTriggerMinutes = (Map<String, Object>) JSON.deserializeUntyped(Label.PriorityToTimeTriggerMinutes);
        } catch (Exception e) {
            System.debug(LoggingLevel.DEBUG, 'Error parsing JSON: ' + e.getMessage());
            return;
        }
        
        if (priorityToTimeTriggerMinutes == null || priorityToTimeTriggerMinutes.isEmpty()) {
            return;
        }
        
        for (Id caseId : idToCase.keySet()) {
            Case caseRecord = idToCase.get(caseId);
            if (String.isBlank(caseRecord.Priority) || caseRecord.CreatedDate == null) {
                continue;
            }
            
            if (!priorityToTimeTriggerMinutes.containsKey(caseRecord.Priority)) {
                continue;
            }
            
            Integer timeTriggerMinutes;
            try {
                timeTriggerMinutes = Integer.valueOf(priorityToTimeTriggerMinutes.get(caseRecord.Priority));
            } catch (Exception e) {
                System.debug(LoggingLevel.DEBUG, 'Invalid time trigger value for priority: ' + caseRecord.Priority);
                continue;
            }
            milestoneFlagColor = (System.now() > caseRecord.CreatedDate.addMinutes(timeTriggerMinutes)) ? redFlag : greenFlag;
            
            
            if(caseNewMap!=null && caseNewMap.size()>0){
                caseNewMap.get(caseId).Initial_Milestone_Flag_Name__c=milestoneFlagColor;
            }else{
                Case caseToUpdate = new Case(Id = caseId);
                caseToUpdate.Initial_Milestone_Flag_Name__c =milestoneFlagColor;
            casesToUpdate.add(caseToUpdate);
            }   
        }
        
        if (!casesToUpdate.isEmpty() && Schema.sObjectType.Case.isAccessible() && Schema.sObjectType.Case.isUpdateable()) {
            update casesToUpdate;
        }
    }
    
}