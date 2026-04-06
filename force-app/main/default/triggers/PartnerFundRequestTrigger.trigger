trigger PartnerFundRequestTrigger on PartnerFundRequest (before insert, after insert, before update, after update) {
    if(flowControll.partnerFundRequestTrigger && !ShGl_DisableBusinessLogic__c.getInstance().Disable_Partner_Fund_Request_Triggers__c){
        if(Trigger.isBefore && Trigger.isInsert){
            PartnerFundRequestTriggerHandler.updateAllocation(Trigger.new);
        }
        if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
            PartnerFundRequestTriggerHandler.updateCDM(Trigger.new, Trigger.oldMap);
            PartnerFundRequestTriggerHandler.updateRequestedAmount(Trigger.new, Trigger.oldMap);
            PartnerFundRequestTriggerHandler.updateTLevelAndFMM(Trigger.new, Trigger.oldMap);
        }
        if(Trigger.isBefore && Trigger.isUpdate){
            PartnerFundRequestTriggerHandler.checkAmount(Trigger.new, Trigger.oldMap);
            PartnerFundRequestTriggerHandler.cancelRequest(Trigger.new, Trigger.oldMap);
            //PRIT25-229
            //PartnerFundRequestTriggerHandler.populatePONumber(Trigger.new,Trigger.oldMap); 
            
            //PRIT24-376 - sidhant.jain@rubrik.com
            PartnerFundRequestTriggerHandler.rejectionReasonCheck(Trigger.new,Trigger.oldMap);
        }
        if(Trigger.isAfter && Trigger.isUpdate){
            PartnerFundRequestTriggerHandler.unLockRecord(Trigger.new, Trigger.oldMap);
            PartnerFundRequestTriggerHandler.assignOwner(Trigger.new, Trigger.oldMap);
        }    
    }
}