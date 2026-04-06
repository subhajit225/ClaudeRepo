/**************************************************************
Description : CCR trigger handler  
              Holds logic for disabling the trigger execution 
              Max recursion                        
Developer : Chaitra
Date : 8/2020
****************************************************************/

public class CCRTriggerHandler extends TriggerHandler {
    
    private static final Integer DEFAULT_MAX_LOOP = 2;
    private boolean isDisabled ;
    private Map<Id,CCR__c> CCROldMap = new Map<Id,CCR__c>();
    private List<CCR__c> newCCRList = new List<CCR__c>();
    private Set<Id> processedCCRS = new Set<Id>();
    public CCRTriggerHandler() {  
        ShGl_DisableBusinessLogic__c triggerControl = ShGl_DisableBusinessLogic__c.getInstance();
        Integer maxLoop = triggerControl.TriggerMaxLoopCount__c!= null?Integer.Valueof(triggerControl.TriggerMaxLoopCount__c):DEFAULT_MAX_LOOP ;
        isDisabled = triggerControl.Disable_CCR_Triggers__c ;
        if(!Test.isRunningTest()) {this.setMaxLoopCount(maxLoop);} //12199
        CCROldMap = (Map<Id,CCR__c>)Trigger.oldmap;
        newCCRList = (List<CCR__c>)Trigger.new;
    }
    
    
    public override void afterUpdate() {
        List<Id> ordCCRIds = new List<Id>();
        List<CCR__c> bkgCCR= new List<CCR__c>();
        Set<Id> approvedsplitCCROppIds = new Set<Id>();
        Set<Id> rejectedsplitCCROppIds = new Set<Id>();
        
        if(!isDisabled){
            for(CCR__c ccr : newCCRList){
                if(CCROldMap.get(ccr.id).User__c!=ccr.User__c //!ccr.CCR_Split_Exception__c && //SAL25-668
                   && ccr.CCR_Type__c != null
                   && 'Approved'.equalsIgnoreCase(ccr.User__c)
                   &&  Constants.CCR_TYPES.contains(ccr.CCR_Type__c)){
                       if(!processedCCRS.contains(ccr.Id)){
                           if('Partner Referral Fee'.equalsIgnoreCase(ccr.CCR_Type__c) == false
                              && 'LineItem Based'.equalsIgnoreCase(ccr.Customer_Returns_Type__c)){
                                  //processAdjustments.add(new CCREvent__e(CCR_Id__c=ccr.id,Action_Type__c='CreateOrdersOpportunity'));
                                  ordCCRIds.add(ccr.id);
                                  processedCCRS.add(ccr.id);
                            }else if('Partner Referral Fee'.equalsIgnoreCase(ccr.CCR_Type__c) || ccr.Customer_Returns_Type__c == 'Amount Based'){
                                bkgCCR.add(ccr); 
                                processedCCRS.add(ccr.id);
                            } 
                        }
                   }//SAL25-668
                   /*else if(ccr.CCR_Split_Exception__c && CCROldMap.get(ccr.id).User__c!=ccr.User__c && 'Approved'.equalsIgnoreCase(ccr.User__c)){ //GAM-3,GAM-4
                       approvedsplitCCROppIds.add(ccr.Opportunity__c);
                   }else if(ccr.CCR_Split_Exception__c && CCROldMap.get(ccr.id).User__c!=ccr.User__c && 'Rejected'.equalsIgnoreCase(ccr.User__c)){ //GAM-3,GAM-4
                       rejectedsplitCCROppIds.add(ccr.Opportunity__c);
                   }*/
            }
            if(!ordCCRIds.isEmpty()){
                
                System.enqueueJob(new CreateDebookingOPPandOrder(ordCCRIds));
                //CreateDebookingOPPandOrder.CreateNegativeOrder(ordCCRIds);
            }
            if(!bkgCCR.isEmpty()){
                CreateBLIorBLIwithBooking.createBLIorBLIwithBkg(bkgCCR);
            }
            //SAL25-668
            /*if(!approvedsplitCCROppIds.isEmpty()){ //GAM-3,GAM-4
                CCRTriggerHelper.updateOpportunityonApproval(approvedsplitCCROppIds);
            }
            if(!rejectedsplitCCROppIds.isEmpty()){ //GAM-3,GAM-4
                CCRTriggerHelper.updateOpportunityonRejection(rejectedsplitCCROppIds);
            }*/
            //Commented for PRIT24-261 
            //CCRTriggerHelper.partnerIncentiveCCRApproval(newCCRList,CCROldMap);
            //SAL24-299
            CCRTriggerHelper.manageCCRShare(newCCRList, CCROldMap);
        }
    }
    public override void beforeInsert() {
        //SF-12199
        if(!isDisabled){
             updateSecondLevelManager(newCCRList, null); 
             calculateReferralFeeAmount(newCCRList, null);
            
            }
    }
    public override void afterInsert() {
        //SAL24-299
        if(!isDisabled){
            CCRTriggerHelper.manageCCRShare(newCCRList, null);
        }
    }
    public override void beforeUpdate() {
        //SF-12199
        if(!isDisabled){ 
            updateSecondLevelManager(newCCRList, CCROldMap);
            calculateReferralFeeAmount(newCCRList, CCROldMap);
        }
    }

    public static void calculateReferralFeeAmount(List<CCR__c> newCCRList, Map<Id,CCR__c> oldCCRMap) {
        Map<Id, Decimal> oppAmountMap = new Map<Id, Decimal>();
        //SAL24-300
        Set<Id> amountOppIdSet = new Set<Id>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        Set<Id> closeOppIdSet = new Set<Id>();
        Set<Id> approvedCCROppIdSet = new Set<Id>();
        Set<Id> allOppIds = new Set<Id>();

        for(CCR__c ccr : newCCRList){
            if(ccr.Referral_Fee_Percent__c != null && ccr.Opportunity__c != null && (oldCCRMap == null || ccr.Referral_Fee_Percent__c != oldCCRMap.get(ccr.Id).Referral_Fee_Percent__c || ccr.Referral_Fee_Amount__c != oldCCRMap.get(ccr.Id).Referral_Fee_Amount__c)){
                if(trigger.isInsert) {
                    amountOppIdSet.add(ccr.Opportunity__c); //SAL24-300
                }
                if(trigger.isUpdate) {
                    ccr.Referral_Fee_Amount__c = ((ccr.Related_Opportunity_Amount__c!=null?ccr.Related_Opportunity_Amount__c:0)*ccr.Referral_Fee_Percent__c)/100;
                }
            }
            //SAL24-300
            if((oldCCRMap == null || ccr.Opportunity__c != oldCCRMap.get(ccr.Id).Opportunity__c || ccr.CCR_Type__c != oldCCRMap.get(ccr.Id).CCR_Type__c) && ccr.CCR_Type__c == 'Partner Referral Fee'){
                closeOppIdSet.add(ccr.Opportunity__c);
            }
            if(oldCCRMap != null && ccr.User__c != oldCCRMap.get(ccr.Id).User__c && ccr.User__c == 'Approved' && ccr.CCR_Type__c == 'Partner Referral Fee'){
                approvedCCROppIdSet.add(ccr.Opportunity__c);
            }
        }
        //System.debug('oppIdSet :: '+oppIdSet);
        //SAL24-300
        allOppIds.addAll(amountOppIdSet);
        allOppIds.addAll(closeOppIdSet);
        allOppIds.addAll(approvedCCROppIdSet);
        If(!allOppIds.isEmpty()) { 
            for(Opportunity opp : [SELECT Id, Amount, CloseDate FROM Opportunity WHERE Id IN :allOppIds]){ //SAL24-300
                oppAmountMap.put(opp.Id, opp.Amount!=null?opp.Amount:0);
                oppMap.put(opp.Id, opp); //SAL24-300
            }
            //System.debug('oppAmountMap :: '+oppAmountMap);
            if(!oppAmountMap.isEmpty()) {
                for(CCR__c ccr : newCCRList) {
                    if(amountOppIdSet.contains(ccr.Opportunity__c) ) { //SAL24-300
                        ccr.Referral_Fee_Amount__c = (oppAmountMap.get(ccr.Opportunity__c)*ccr.Referral_Fee_Percent__c)/100;
                        //System.debug('ccr.Referral_Fee_Amount__c :: '+ccr.Referral_Fee_Amount__c);
                    }
                    //SAL24-300
                    if(closeOppIdSet.contains(ccr.Opportunity__c) ) {
                        ccr.Effective_Date__c = oppMap.get(ccr.Opportunity__c)?.CloseDate;
                    }
                    if(approvedCCROppIdSet.contains(ccr.Opportunity__c) ) {
                        ccr.Approved_Related_Opportunity_Amount__c = oppMap.get(ccr.Opportunity__c)?.Amount;
                    }
                }
            }   
        }
    }

    //SF-12199
    public static void updateSecondLevelManager(List<CCR__c> newCCRList, Map<Id,CCR__c> oldCCRMap){
        Set<Id> ownerIds = new Set<Id>();
        Map<Id, Id> userToManagerMap = new Map<Id, Id>();
        //SAL24-299
        Map<Id, Id> userToMgrMgrMap = new Map<Id, Id>();
        Map<Id, Id> userToMgrMgrMgrMap = new Map<Id, Id>();
        for(CCR__c ccr : newCCRList){
           if(oldCCRMap!=null &&   oldCCRMap.get(ccr.id).User__c!=ccr.User__c 
               && ccr.CCR_Type__c != null
               && 'Approved'.equalsIgnoreCase(ccr.User__c)
               &&  Constants.CCR_TYPES.contains(ccr.CCR_Type__c)){
                   ccr.Effective_End_Date__c = system.today();    
                   
               }
            if(oldCCRMap == null || (ccr.OwnerId != oldCCRMap.get(ccr.Id).OwnerId) || (ccr.Affective_Person__c != oldCCRMap.get(ccr.Id).Affective_Person__c)){ //SAL24-299
                ownerIds.add(ccr.OwnerId);
                ownerIds.add(ccr.Affective_Person__c); //SAL24-299
            }
        }
        if(!ownerIds.isEmpty()){
            //SAL24-299
            for(User u :[Select Id, ManagerId, Manager.ManagerId, Manager.Manager.ManagerId from User where Id in :ownerIds]){
                userToManagerMap.put(u.Id, u.ManagerId);
                userToMgrMgrMap.put(u.Id, u.Manager.ManagerId);
                userToMgrMgrMgrMap.put(u.Id, u.Manager.Manager.ManagerId);
            }
            for(CCR__c ccr : newCCRList){
                //SAL24-299
                CCR__c oldCCR = oldCCRMap != null ? oldCCRMap.get(ccr.Id) : null;
                //ccr.SecondLevelManager__c = (oldCCRMap == null || (ccr.OwnerId != oldCCRMap.get(ccr.Id).OwnerId)) ? userToManagerMap.get(ccr.OwnerId) : ccr.SecondLevelManager__c;
                ccr.SecondLevelManager__c = (oldCCRMap == null || (ccr.OwnerId != oldCCR.OwnerId)) ? userToMgrMgrMap.get(ccr.OwnerId) : ccr.SecondLevelManager__c;
                ccr.Affected_Person_Manager__c = (oldCCRMap == null || (ccr.Affective_Person__c != oldCCR.Affective_Person__c)) ? userToManagerMap.get(ccr.Affective_Person__c) : ccr.Affected_Person_Manager__c;
                ccr.Affected_Person_SecondLevel_Manager__c = (oldCCRMap == null || (ccr.Affective_Person__c != oldCCR.Affective_Person__c)) ? userToMgrMgrMap.get(ccr.Affective_Person__c) : ccr.Affected_Person_SecondLevel_Manager__c;
                ccr.Affected_Person_ThirdLevel_Manager__c = (oldCCRMap == null || (ccr.Affective_Person__c != oldCCR.Affective_Person__c)) ? userToMgrMgrMgrMap.get(ccr.Affective_Person__c) : ccr.Affected_Person_ThirdLevel_Manager__c;
            }
        }
    }
}