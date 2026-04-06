/**
 * @Author      : Vijay Kumar K R
 * @Description : 1378: Enable Escalation Management Team (EMT) Reporting within Salesforce Lightning
 * @TstClass    : 
 * -------------------------- @History --------------------------------------------------------------------------------------------
 * Story Number       Modified By              Date           Description
 * CS21-1378          Vijay Kumar K R          16th May 2023  There should only be one Lessons_Learned per escalation 
 * --------------------------------------------------------------------------------------------------------------------------------
 */
trigger LessonsLearnedTrigger on Lessons_Learned__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    System.debug('TriggerControl__c:: '+TriggerControl__c.getInstance('LessonsLearned').DisableTrigger__c);
    if(!ShGl_DisableBusinessLogic__c.getInstance().Disable_Case_Triggers__c 
        && TriggerControl__c.getAll() != null 
        && TriggerControl__c.getAll().containsKey('LessonsLearned') 
        && !TriggerControl__c.getInstance('LessonsLearned').DisableTrigger__c){
            
        new LessonsLearnedTriggerHandler().run(); 
    }
}