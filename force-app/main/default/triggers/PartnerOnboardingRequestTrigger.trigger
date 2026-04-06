/**
 * @description       : Trigger for Partner_Onboarding_Request__c object
 * @author            : Harshit Garg
 * @group             : 
 * @last modified on  : 01-14-2026
 * @last modified by  : Harshit Garg
**/
trigger PartnerOnboardingRequestTrigger on Partner_Onboarding_Request__c (before insert, before update, before delete, after insert, after update, after delete) {
	ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId());
    if(flowControll.partnerOnBoardRequestTrigger && !disableBusinessLogicCS.Disable_Partner_Onboarding_Req_Triggers__c){
        TriggerManager.invokeHandler(new PartnerOnboardingRequestTriggerHandler());
    }
}