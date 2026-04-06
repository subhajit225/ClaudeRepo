/**
 * @Author      : Vijay Kumar K R
 * @Description : 1378: Enable Escalation Management Team (EMT) Reporting within Salesforce Lightning
 * @TstClass    : 
 * -------------------------- @History --------------------------------------------------------------------------------------------
 * Story Number       Modified By              Date           Description
 * CS21-1378          Vijay Kumar K R          16th May 2023  There should only be one escalation per primary case, with a single lessons learned child case per escalation case. 
 * --------------------------------------------------------------------------------------------------------------------------------
 */
trigger EscalationTrigger on Escalation__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    if(!ShGl_DisableBusinessLogic__c.getInstance().Disable_Case_Triggers__c 
        && TriggerControl__c.getAll() != null 
        && TriggerControl__c.getAll().containsKey('Escalation') 
        && !TriggerControl__c.getInstance('Escalation').DisableTrigger__c){
            
        new EscalationTriggerHandler().run(); 
    }
}