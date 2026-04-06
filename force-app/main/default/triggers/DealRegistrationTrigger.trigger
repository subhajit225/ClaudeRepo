/**
 * @description       : Trigger of Deal_Registration__c object
 * @author            : Harshit Garg
 * @group             : 
 * @last modified on  : 03-02-2026
 * @last modified by  : Harshit Garg
**/
trigger DealRegistrationTrigger on Deal_Registration__c (before insert, before update, before delete, after insert, after update, after delete) {
    ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId());
    if(flowControll.DealRegistrationTrigger && !disableBusinessLogicCS.Disable_Deal_Registration_Trigger__c){
        TriggerManager.invokeHandler(new DealRegistrationTriggerHandler());
    }
    
}