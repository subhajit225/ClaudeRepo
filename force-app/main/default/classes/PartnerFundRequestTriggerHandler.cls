/**
 * @description Trigger handler class for PartnerFundRequest object
 * Handles various business logic including CDM updates, amount validations, campaign creation, and approval processes
 * @author Harshit Garg
 * @group Partner Fund Management
 * @last modified on 02-09-2026
 * @last modified by Harshit Garg
**/
public without sharing class PartnerFundRequestTriggerHandler {
    /**
     * @description Method to update CDM on PartnerFundRequest record as ChannelPartner.Owner (Account.Owner)
     * @param newPFRList List of new PartnerFundRequest records
     * @param oldPFRMap Map of old PartnerFundRequest records by ID
     */
    public static void updateCDM(List<PartnerFundRequest> newPFRList, Map<Id, PartnerFundRequest> oldPFRMap){
        Set<Id> accountIds = new Set<Id>();
        Map<Id,Account> accountMap = new Map<ID,Account>();
        for(PartnerFundRequest pfr :newPFRList){
            if(oldPFRMap == null || (!oldPFRMap.isEmpty() && pfr.ChannelPartnerId != oldPFRMap.get(pfr.Id).ChannelPartnerID)){
                accountIds.add(pfr.ChannelPartnerId);
            }
        }
        
        //get all ownerIds for the accounts
        if(!accountIds.isEmpty()){
            accountMap = new Map<ID,Account>([Select Id,OwnerId,BillingCountry from Account where Id in :accountIds]);
        }
        for(PartnerFundRequest pfr :newPFRList){
            if(!accountMap.isEmpty() && accountMap.containskey(pfr.ChannelPartnerId)){
                pfr.CDM__c = accountMap.get(pfr.ChannelPartnerId).OwnerId;
                pfr.Country__c = accountMap.get(pfr.ChannelPartnerId).BillingCountry;
            }
        }
        
    }
    
    /**
     * @description Method to update Requested Amount on PartnerFundRequest record
     * @param newPFRList List of new PartnerFundRequest records
     * @param oldPFRMap Map of old PartnerFundRequest records by ID
     */
    public static void updateRequestedAmount(List<PartnerFundRequest> newPFRList, Map<Id, PartnerFundRequest> oldPFRMap){
        for (PartnerFundRequest rec : newPFRList) {
            PartnerFundRequest oldRec = oldPFRMap == null ? null : oldPFRMap.get(rec.Id);
            // If RequestedAmount is changed/filled, update Requested_Amount__c
            if (rec.RequestedAmount != null && (oldRec == null || rec.RequestedAmount != oldRec.RequestedAmount)) {
                rec.Requested_Amount__c = rec.RequestedAmount;
            }
            // If Requested_Amount__c is changed/filled, update RequestedAmount
            else if (rec.Requested_Amount__c != null && (oldRec == null || rec.Requested_Amount__c != oldRec.Requested_Amount__c)) {
                rec.RequestedAmount = rec.Requested_Amount__c;
            }
        }
    }
    
    /**
     * @description Method to update TLevels and FMM on PartnerFundRequest record based on CDM
     * @param newPFRList List of new PartnerFundRequest records
     * @param oldPFRMap Map of old PartnerFundRequest records by ID
     */
    public static void updateTLevelAndFMM(List<PartnerFundRequest> newPFRList, Map<Id, PartnerFundRequest> oldPFRMap){
        Set<Id> userIds = new Set<Id>();
        Map<Id,List<UserTerritory2Association>> cdmTerritoryAssociationMap = new Map<Id,List<UserTerritory2Association>>();
        Map<string,string> cdmToFmmMap = new Map<string,string>();
        Id defaultFMMId = null;
        Set<String> activeFMM = new Set<String>();
        Set<String> allFMM = new Set<String>();
        List<PartnerFundRequest_CDM_FMM__mdt> allFMMList = new List<PartnerFundRequest_CDM_FMM__mdt>();
        for(PartnerFundRequest pfr :newPFRList){
            if(oldPFRMap == null || (!oldPFRMap.isEmpty() && pfr.CDM__c != oldPFRMap.get(pfr.Id).CDM__c)){
                userIds.add(pfr.CDM__c);
            }
        }
        
        if(!userIds.isEmpty()){
            //get all ownerIds for the accounts
            List<UserTerritory2Association> territoryAssList = [SELECT Id, UserId,User.Name, Territory2Id, Territory2.Internal_Territory_Name__c, Territory2.ParentTerritory2Id, Territory2.ParentTerritory2.Internal_Territory_Name__c,Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c, Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c, RoleInTerritory2, Territory2.Territory2Type.DeveloperName
                                                                FROM UserTerritory2Association
                                                                WHERE Territory2.Territory2Model.State = 'Active'
                                                                AND (Territory2.Internal_Territory_Name__c LIKE '%CDR-%' OR Territory2.Internal_Territory_Name__c LIKE '%CDM-%')
                                                                AND UserId IN :userIds];
            
            if(!territoryAssList.isEmpty()){
                for(UserTerritory2Association terAss : territoryAssList){
                    if(cdmTerritoryAssociationMap.containsKey(terAss.UserId)){
                        cdmTerritoryAssociationMap.get(terAss.UserId).add(terAss);
                    }else{
                        List<UserTerritory2Association> terrRecList = new List<UserTerritory2Association>();
                        terrRecList.add(terAss);
                        cdmTerritoryAssociationMap.put(terAss.UserId,terrRecList);
                    }
                }  
            }
            
            //get all cdm_fmm mapping from custom meta and add it to map except Default one
            //PRIT24-392
            //If FMM is inactive, assign MDF request Marketing Manager = Tomo (Default).
            allFMMList = [SELECT MasterLabel,CDM_Id__c,FMM_Id__c,FMM_Name__c FROM PartnerFundRequest_CDM_FMM__mdt];
            for(PartnerFundRequest_CDM_FMM__mdt fmm : allFMMList){
                allFMM.add(fmm.FMM_Id__c);
                if(fmm.CDM_Id__c == 'Default'){
                    defaultFMMId = Id.valueOf(fmm.FMM_Id__c);
                }
            }
            for(User u : [SELECT Id FROM User WHERE Id IN :allFMM AND isActive = TRUE]){
                activeFMM.add(u.Id);
            }
            for(PartnerFundRequest_CDM_FMM__mdt fmm : allFMMList){
                if(fmm.CDM_Id__c != 'Default' && activeFMM.contains(fmm.FMM_Id__c)){
                    cdmToFmmMap.put(Id.valueOf(fmm.CDM_Id__c), Id.valueOf(fmm.FMM_Id__c));
                }else if(fmm.CDM_Id__c != 'Default' && !activeFMM.contains(fmm.FMM_Id__c)){
                    cdmToFmmMap.put(Id.valueOf(fmm.CDM_Id__c), defaultFMMId);
                }else{
                    cdmToFmmMap.put(fmm.CDM_Id__c, Id.valueOf(fmm.FMM_Id__c));
                } 
            }
        }
        for(PartnerFundRequest pfr :newPFRList){
            if(oldPFRMap == null || (!oldPFRMap.isEmpty() && pfr.CDM__c != oldPFRMap.get(pfr.Id).CDM__c)){
                if(!cdmTerritoryAssociationMap.isEmpty()){
                    for(UserTerritory2Association terrAss : cdmTerritoryAssociationMap.get(pfr.CDM__c)){
                        if(pfr.CDM_Tlevel1__c ==null && terrAss.Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c != null && (terrAss.Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c.contains('CDR-') || terrAss.Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c.contains('CDM-'))){
                            pfr.CDM_Tlevel1__c = terrAss.Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c;
                            pfr.CDM_Tlevel2__c = terrAss.Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c;
                            pfr.CDM_Tlevel3__c = terrAss.Territory2.ParentTerritory2.Internal_Territory_Name__c;
                        }else if(pfr.CDM_Tlevel1__c ==null && terrAss.Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c != null && (terrAss.Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c.contains('CDR-') || terrAss.Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c.contains('CDM-'))){
                            pfr.CDM_Tlevel1__c = terrAss.Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c;
                            pfr.CDM_Tlevel2__c = terrAss.Territory2.ParentTerritory2.Internal_Territory_Name__c;
                            pfr.CDM_Tlevel3__c = terrAss.Territory2.Internal_Territory_Name__c;
                        }else if(pfr.CDM_Tlevel1__c ==null && terrAss.Territory2.ParentTerritory2.Internal_Territory_Name__c != null && (terrAss.Territory2.ParentTerritory2.Internal_Territory_Name__c.contains('CDR-') || terrAss.Territory2.ParentTerritory2.Internal_Territory_Name__c.contains('CDM-'))){
                            pfr.CDM_Tlevel1__c = terrAss.Territory2.ParentTerritory2.Internal_Territory_Name__c;
                            pfr.CDM_Tlevel2__c = terrAss.Territory2.Internal_Territory_Name__c;
                        }else if(pfr.CDM_Tlevel1__c ==null && terrAss.Territory2.Internal_Territory_Name__c != null && (terrAss.Territory2.Internal_Territory_Name__c.contains('CDR-') || terrAss.Territory2.Internal_Territory_Name__c.contains('CDM-'))){
                            pfr.CDM_Tlevel1__c = terrAss.Territory2.ParentTerritory2.Internal_Territory_Name__c;
                        }
                    }
                }
                //map fmm
                if(!cdmToFmmMap.isEmpty()){
                    pfr.Field_Marketing_Manager__c = cdmToFmmMap.containskey(pfr.CDM__c) ? Id.valueOf(cdmToFmmMap.get(pfr.CDM__c)) : Id.valueOf(cdmToFmmMap.get('Default'));
                }
            }
        }
    }
    
    /**
     * @description Performs validations and updates Campaigns when Partner Fund Requests are approved or modified
     * @param newPFRList List of new PartnerFundRequest records
     * @param oldPFRMap Map of old PartnerFundRequest records by ID
     */
    public static void checkAmount(List<PartnerFundRequest> newPFRList, Map<Id, PartnerFundRequest> oldPFRMap){
        string errormsg = '';
        Boolean flag = false;
        Map<string,string> pfrCampMap = new Map<string,string>();
        Map<string,List<Campaign>> pfrCampListMap;
        Map<Id, Campaign> campList = new Map<Id, Campaign>();
        set<string> pfrIdset = new Set<String>();
        
        //PRIT24-428
        //Avoid Campaign Creation for 'Training and Readiness', 'Sales Incentives', 'Dedicated Resource' MDFs
        Set<String> activityWithoutCamp = new Set<String> {'Training and Readiness','Sales Incentives', 'Dedicated Resource'};
            for(PartnerFundRequest pfr :newPFRList){
                if(oldPFRMap != null && oldPFRMap.containskey(pfr.Id) && pfr.status != oldPFRMap.get(pfr.Id).status && pfr.status == 'Approved' && pfr.Do_Not_Auto_Generate_Campaign__c){
                    if(!activityWithoutCamp.contains(pfr.Activity)){
                        pfrIdset.add(pfr.Id);
                    }
                }
            }
        if(!pfrIdset.isEmpty()){
            pfrCampMap = new Map<string,string>();
            for(Campaign cmp : [select Id,Partner_Fund_Request__c from Campaign where Partner_Fund_Request__c IN:pfrIdset]){
                pfrCampMap.put(cmp.Partner_Fund_Request__c,cmp.Id);       
            }
        }
        
        //PRIT25-740 - Start - Akanksha
        for (PartnerFundRequest pfr : newPFRList) {
            if (pfr.Routing_Method__c == 'MQL to ETM' && String.isBlank(pfr.ETM_Role__c)) {
                pfr.addError('ETM Role is required when Routing Method is "MQL to ETM"');
            }
        }
        //PRIT25-740 - End - Akanksha
        
        for(PartnerFundRequest pfr :newPFRList){
            if(oldPFRMap != null && oldPFRMap.containskey(pfr.Id) && pfr.status != oldPFRMap.get(pfr.Id).status && pfr.status == 'Approved' ){
                errormsg = 'To Approve record, please enter the details of : ';
                flag = false;
                if(pfr.Amount == null){
                    flag = true;
                    errormsg=errormsg+'Approved Amount';
                }
                //PRIT25-368-start
                if(pfr.Approved_Amount_USD__c == null){
                    if(flag){
                        errormsg=errormsg+',';
                    }
                    flag = true;
                    errormsg=errormsg+'Approved Amount (USD)';
                }
                //PRIT25-368-end
                if(string.isBlank(pfr.Campaign_Focus__c)){
                    if(flag){
                        errormsg=errormsg+',';
                    }
                    flag = true;
                    errormsg=errormsg+'Campaign Focus';
                }
                if(string.isBlank(pfr.Field_Event_Type__c) && pfr.Activity == 'Event Marketing'){
                    if(flag){
                        errormsg=errormsg+',';
                    }
                    flag = true;
                    errormsg=errormsg+'Field Event Type';
                }
                if(string.isBlank(pfr.Fiscal_Period__c) && pfr.Activity == 'Dedicated Resource'){
                    if(flag){
                        errormsg=errormsg+',';
                    }
                    flag = true;
                    errormsg=errormsg+'Fiscal Period';
                }
                if(string.isBlank(pfr.Budget_Code__c)){
                    if(flag){
                        errormsg=errormsg+',';
                    }
                    flag = true;
                    errormsg=errormsg+'Budget Code';
                }
                if(string.isBlank(pfr.Executed_By__c)){
                    flag = true;
                    if(flag){
                        errormsg=errormsg+',';
                    }
                    errormsg=errormsg+'Executed By';
                }
                if(pfr.Planned_Inquiries__c == null){
                    if(flag){
                        errormsg=errormsg+',';
                    }
                    flag = true;
                    errormsg=errormsg+'Planned Inquiries';
                }
                if(!pfrIdset.isEmpty() && pfrIdset.contains(pfr.Id) && ((!pfrCampMap.isEmpty() && !pfrCampMap.containskey(pfr.Id)) || pfrCampMap.isEmpty())){
                    if(flag){
                        errormsg=errormsg+'.';
                    }
                    flag = true;
                    errormsg=errormsg+' Please attach the current record to the (Partner Fund Request) lookup field on the Campaign record';
                }
                if(flag){
                    pfr.addError(errormsg);
                }
                else if(pfrCampMap.containsKey(pfr.Id)){
                    //add planned mql
                    campList.put(pfrCampMap.get(pfr.Id), new Campaign(Id=pfrCampMap.get(pfr.Id), Planned_MQL__c=pfr.Planned_MQL__c, Planned_meetings__c=pfr.Planned_meetings__c));
                }
            }
        }
        pfrIdset = new Set<String>();
        for(PartnerFundRequest pfr :newPFRList){
            if(oldPFRMap != null && oldPFRMap.containskey(pfr.Id) && pfr.Re_Calculate_Actual_Cost__c != oldPFRMap.get(pfr.Id).Re_Calculate_Actual_Cost__c && pfr.Re_Calculate_Actual_Cost__c){
                pfrIdset.add(pfr.Id);
            }
        }
        if(!pfrIdset.isEmpty()){
            pfrCampListMap = new Map<string,List<Campaign>>();
            for(Campaign cmp : [SELECT Id,ActualCost,Partner_Fund_Request__c FROM Campaign WHERE Partner_Fund_Request__c IN:pfrIdset]){
                if(pfrCampListMap.isEmpty() || !pfrCampListMap.containskey(cmp.Partner_Fund_Request__c)){
                    pfrCampListMap.put(cmp.Partner_Fund_Request__c,new List<Campaign>());
                } 
                pfrCampListMap.get(cmp.Partner_Fund_Request__c).add(cmp);       
            }
            for(PartnerFundRequest pfr :newPFRList){
                if(!pfrCampListMap.isEmpty() && pfrCampListMap.containsKey(pfr.Id)){
                    for(Campaign cmp : pfrCampListMap.get(pfr.Id)){
                        Campaign cmp1 = new Campaign(Id=cmp.Id,ActualCost=pfr.TotalApprovedFcs, Planned_MQL__c=pfr.Planned_MQL__c, Planned_meetings__c=pfr.Planned_meetings__c);
                        campList.put(cmp1.Id, cmp1);
                    }
                }
                pfr.Re_Calculate_Actual_Cost__c = false;
            }
        }        
        if(!campList.isEmpty()){
            flowControll.CampaignTrigger = false;
            update campList.values();
        }           
        
    }
    
    /**
     * @description Assigns the owner of Partner Fund Requests to the first pending approver when status changes to 'Submitted'
     * @param newPFRList List of new PartnerFundRequest records
     * @param oldPFRMap Map of old PartnerFundRequest records by ID
     */
    public static void assignOwner(List<PartnerFundRequest> newPFRList, Map<Id, PartnerFundRequest> oldPFRMap){
        List<ProcessInstance> pInsList = new List<ProcessInstance>();
        List<PartnerFundRequest> pfrList = new List<PartnerFundRequest>();
        Set<String> pfrIdSet = new Set<string>();
        Map<string,string> pfrOwnerMap = new Map<string,string>();
        
        for(PartnerFundRequest pfr :newPFRList){
            if(oldPFRMap != null && oldPFRMap.containskey(pfr.Id) && pfr.status != oldPFRMap.get(pfr.Id).status && pfr.status == 'Submitted'){
                pfrIdSet.add(pfr.Id);
            }
        }
        if(!pfrIdSet.isEmpty()){
            pInsList = [SELECT Id,TargetObjectId,Status, (SELECT Id, OriginalActorId, OriginalActor.Name,StepStatus FROM StepsAndWorkitems where StepStatus='Pending')
                        FROM ProcessInstance where TargetObjectId IN: pfrIdSet AND Status='Pending' order by createddate asc];
        }
        if(!pInsList.isEmpty()){
            for(ProcessInstance pi : pInsList){
                for(ProcessInstanceHistory pih : pi.StepsAndWorkitems){
                    if(pih.StepStatus == 'Pending'){
                        pfrOwnerMap.put(pi.TargetObjectId,pih.OriginalActorId);
                    }
                }
            }
            pfrList = [select Id,OwnerId from PartnerFundRequest where Id IN: pfrIdSet];
        }
        for(PartnerFundRequest pfr : pfrList){
            if(!pfrOwnerMap.isEmpty() && pfrOwnerMap.containsKey(pfr.Id)){
                pfr.OwnerId = pfrOwnerMap.get(pfr.Id);
            }
        }
        if(!pfrList.isEmpty()){
            update pfrList;
        }
    }
    
    /**
     * @description Updates Partner Fund Requests with the current active budget and allocation
     * @param newPFRList List of new PartnerFundRequest records
     */
    public static void updateAllocation(List<PartnerFundRequest> newPFRList){
        List<PartnerMarketingBudget> budgetList = new List<PartnerMarketingBudget>();
        List<PartnerFundAllocation> allocationList = new List<PartnerFundAllocation>();
        Date todaydate = system.today(); 
        budgetList = [select Id,StartDate,EndDate from PartnerMarketingBudget where EndDate >= :todaydate AND StartDate <= :todaydate];
        if(!budgetList.isEmpty()){
            allocationList = [select Id from PartnerFundAllocation where BudgetId =:budgetList[0].Id limit 1];
        }
        if(!allocationList.isEmpty()){
            for(PartnerFundRequest pfr :newPFRList){
                pfr.BudgetId = budgetList[0].Id;
                pfr.AllocationId = allocationList[0].Id;
            }
        }
    }
    
    /**
     * @description Cancels approved Partner Fund Requests if eligible and sets rejection details
     * @param newPFRList List of new PartnerFundRequest records
     * @param oldPFRMap Map of old PartnerFundRequest records by ID
     */
    public static void cancelRequest(List<PartnerFundRequest> newPFRList, Map<Id, PartnerFundRequest> oldPFRMap){
        Set<String> pfrIdSet = new Set<string>();
        List<PartnerFundClaim> pfcList = new List<PartnerFundClaim>();
        
        for(PartnerFundRequest pfr :newPFRList){
            if(oldPFRMap != null && pfr.status != 'Approved' && oldPFRMap.containskey(pfr.Id) && pfr.Cancel_Partner_Fund_Request__c != oldPFRMap.get(pfr.Id).Cancel_Partner_Fund_Request__c && pfr.Cancel_Partner_Fund_Request__c){
                pfr.addError('Only Approved Request can be cancelled');
            }else if(oldPFRMap != null && pfr.status == 'Approved' && oldPFRMap.containskey(pfr.Id) && pfr.Cancel_Partner_Fund_Request__c != oldPFRMap.get(pfr.Id).Cancel_Partner_Fund_Request__c && pfr.Cancel_Partner_Fund_Request__c){
                pfrIdSet.add(pfr.Id);
            }
        }
        if(!pfrIdSet.isEmpty()){
            pfcList = [select Id,RequestId from PartnerFundClaim where RequestId IN: pfrIdSet]; 
            for(PartnerFundClaim pfc : pfcList){
                pfrIdSet.remove(pfc.RequestId);
                for(PartnerFundRequest pfr :newPFRList){
                    if(pfr.Id == pfc.RequestId){
                        pfr.addError('Cannot cancel a Request with MDF Claim');
                    }
                }
            }
        }
        
        for(PartnerFundRequest pfr :newPFRList){
            if(!pfrIdSet.isEmpty() && pfrIdSet.contains(pfr.Id)){
                pfr.Status = 'Rejected';
                pfr.Rejection_Reason__c = 'Request Canceled by User: ' + userInfo.getName();
                pfr.Cancellation_Requested_By__c = userInfo.getUserId();
            }
        }  
    }
    
    /**
     * @description Unlocks Partner Fund Request records when status changes to 'Submitted'
     * @param newPFRList List of new PartnerFundRequest records
     * @param oldPFRMap Map of old PartnerFundRequest records by ID
     */
    public static void unLockRecord(List<PartnerFundRequest> newPFRList,  Map<Id, PartnerFundRequest> oldPFRMap){
        List<PartnerFundRequest> pFRListToUnlock = new List<PartnerFundRequest>();
        List<Id> recordsToUnlock = new List<Id>();
        for(PartnerFundRequest pfr :newPFRList){
            if(oldPFRMap != null && oldPFRMap.containskey(pfr.Id) && pfr.status != oldPFRMap.get(pfr.Id).status && pfr.status == 'Submitted'){
                recordsToUnlock.add(pfr.id); 
            }
        }
        if(!recordsToUnlock.isEmpty())
            unLockRecords(recordsToUnlock);
    }
    
    /**
     * @description Unlocks Partner Fund Request records asynchronously if currently locked
     * @param newPFRListIds List of PartnerFundRequest IDs to unlock
     */
    @Future
    public static void unLockRecords(List<id> newPFRListIds){
        //Check locked records
        List<PartnerFundRequest> fundReqLockList = new List<PartnerFundRequest>();
        for(id c :newPFRListIds){
            if(Approval.isLocked(c) || Test.isRunningTest()){
                PartnerFundRequest rec = new PartnerFundRequest();
                rec.id = c;
                fundReqLockList.add(rec);
            }
        }
        //Unlock record
        if(!fundReqLockList.isEmpty()){
            List<Approval.UnlockResult> ulrList = Approval.unlock(fundReqLockList, false);
            for(Approval.UnlockResult  ulr : ulrList) {
                if (!ulr.isSuccess()) {
                    System.debug(system.logginglevel.DEBUG,'Approval unlock error');
                }
            }
        }
    }
    
    /**
     * @description Method to update Rejection Reason based on Status
     * @param newPFRList List of new PartnerFundRequest records
     * @param oldPFRMap Map of old PartnerFundRequest records by ID
     */
    public static void rejectionReasonCheck(List<PartnerFundRequest> newPFRList, Map<Id, PartnerFundRequest> oldPFRMap){
        for(PartnerFundRequest pfr : newPFRList){
            if(pfr.Status == 'Rejected' && pfr.Status != oldPFRMap.get(pfr.Id).Status 
               && (String.isEmpty(pfr.Rejection_Reason__c) || pfr.Rejection_Reason__c == '')){
                   pfr.addError('A rejected request requires a rejection reason');
               }
        }
    }
    
    // ========= INPUT/OUTPUT WRAPPERS =========

    /**
     * @description Input wrapper class for invocable method
     */
    public class Request {
        @InvocableVariable(required=true label='Partner Fund Request ID')
        public Id partnerFundRequestId;
    }

    /**
     * @description Output wrapper class for invocable method
     */
    public class Result {
        @InvocableVariable(label='Campaign ID')
        public Id campaignId;

        @InvocableVariable(label='Success')
        public Boolean isSuccess;

        @InvocableVariable(label='Error Message')
        public String errorMessage;

        /**
         * @description Constructor for Result class
         * @param campaignId ID of the created Campaign
         * @param success Whether the operation was successful
         * @param errMsg Error message if operation failed
         */
        public Result(Id campaignId, Boolean success, String errMsg){
            this.campaignId = campaignId;
            this.isSuccess = success;
            this.errorMessage = errMsg;
        }
    }
    
    // ========= INVOCABLE METHOD =========

    /**
     * @description Creates Campaign records from PartnerFundRequest IDs using metadata-driven field mappings
     * This method is invocable from Flow and uses ObjectMappingService for field mapping
     * @param requests List of Request objects containing PartnerFundRequest IDs
     * @return List<Result> List of Result objects containing Campaign IDs and success status
     */
    @InvocableMethod(label='Create Campaign from PartnerFundRequest' description='Creates Campaign using Custom Metadata mappings')
    public static List<Result> createCampaign(List<Request> requests) {
        List<Result> results = new List<Result>();
        if (requests == null || requests.isEmpty()) {
            results.add(new Result(null,false,'No Partner Fund Request provided'));
            return results;
        }

        try {
            // Extract PFR IDs
            Set<Id> pfrIds = new Set<Id>();
            for (Request req : requests) {
                pfrIds.add(req.partnerFundRequestId);
            }

            // Call the reusable method to create campaigns
            List<Campaign> createdCampaigns = createCampaignsFromPFRIds(pfrIds);

            // Return Campaign IDs with success status
            if (createdCampaigns != null && !createdCampaigns.isEmpty()) {
                for (Campaign camp : createdCampaigns) {
                    results.add(new Result(camp.Id,true,null));
                }
            } else {
                results.add(new Result(null,false,'No campaigns were created'));
            }

            return results;
        } catch (Exception e) {
            logException(e, 'Campaign Creation From MDF');
            results.add(new Result(null,false,e.getMessage()));
            return results;
        }
    }

    // ========= REUSABLE METHOD: CREATE CAMPAIGNS FROM PFR IDS =========
    /**
     * @description Creates Campaign records from PartnerFundRequest IDs using metadata-driven field mappings
     * This method can be called from Flow (via createCampaign) or from other methods within the class
     * @param pfrIds Set of PartnerFundRequest IDs to create Campaigns from
     * @return List of inserted Campaign records
     */
    public static List<Campaign> createCampaignsFromPFRIds(Set<Id> pfrIds) {
        List<Campaign> campaignsToInsert = new List<Campaign>();

        if (pfrIds == null || pfrIds.isEmpty()) {
            return campaignsToInsert;
        }

        try {
            // Query PartnerFundRequests with only required fields using ObjectMappingService
            Set<Id> recordIds = pfrIds; // Variable name must match the bind variable in the query
            String query = ObjectMappingService.buildDynamicQuery('PFR_to_Campaign', recordIds);
            List<PartnerFundRequest> pfrList = (List<PartnerFundRequest>) Database.query(query);

            // Map records using ObjectMappingService
            List<SObject> mappedCampaigns = ObjectMappingService.mapRecords('PFR_to_Campaign', pfrList);

            // Cast to Campaign list
            for (SObject sobj : mappedCampaigns) {
                campaignsToInsert.add((Campaign) sobj);
            }

            // Insert Campaigns
            if (!campaignsToInsert.isEmpty()) {
                insert campaignsToInsert;
            }

            return campaignsToInsert;
        } catch (Exception e) {
            logException(e, 'Campaign Creation From PFR IDs');
            return new List<Campaign>();
        }
    }

    // ========= HELPER: LOG EXCEPTION =========

    /**
     * @description Logs exception details to Custom_Error_Log__c object
     * @param e Exception to log
     * @param functionality Name of the functionality where exception occurred
     */
    private static void logException(Exception e, String functionality) {
        insert new Custom_Error_Log__c(
            Class__c = 'PartnerFundRequestTriggerHandler',
            Exception_Message__c = e.getMessage(),
            Functionality__c = functionality,
            ErrorTrace__c = e.getStackTraceString()
        );
    }
}