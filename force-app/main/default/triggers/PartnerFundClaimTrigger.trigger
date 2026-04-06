trigger PartnerFundClaimTrigger on PartnerFundClaim (before insert,after insert, before update, after update) {
    if(Trigger.isAfter && Trigger.isInsert){
        PartnerFundClaimTriggerHandler.replaceTitle(Trigger.new);
    }
    if(Trigger.isBefore && Trigger.isUpdate){
        PartnerFundClaimTriggerHandler.cannotExceedApprovedAmount(Trigger.new, Trigger.oldMap);
    }
    if(Trigger.isAfter && Trigger.isUpdate){
        PartnerFundClaimTriggerHandler.claimAfterApproved(Trigger.new, Trigger.oldMap); //ITMKT21-213 & 214
        PartnerFundClaimTriggerHandler.lockUnlockRecords(Trigger.new, Trigger.oldMap); 
        PartnerFundClaimTriggerHandler.sendMailAfterApproved(Trigger.new, Trigger.oldMap);  
        
    } 
}