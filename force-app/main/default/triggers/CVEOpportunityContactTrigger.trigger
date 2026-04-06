/**
 * @description trigger on CVE_Opportunity_Contact object
 * @createdDate 21-July-2025
 */
trigger CVEOpportunityContactTrigger on CVE_Opportunity_Contact__c (before insert, before update, before delete, after insert, after update, after delete) {
    
    ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId());
    if(!disableBusinessLogicCS.Disable_CVE_Engagement_Trigger__c){
        if(FlowControll.CVEOpportunityContactTriggerHandler && TriggerManager.isTriggerExecutionAllowed('CVE_Opportunity_Contact__c')){
            TriggerManager.invokeHandler(new CVEOpportunityContactTriggerHandler());
        }
    }
}