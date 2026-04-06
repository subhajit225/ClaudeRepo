/**
 * @Author      : Vijay Kumar K R
 * @Description : Change in EOD on release version should update CDM Software version on Case
 * @TstClass    : ReleaseVersionTriggerHandlerTest
 * -------------------------- @History --------------------------------------------------------------------------------------------
 * Story Number       Modified By              Date           Description
 * CS21-3039        Vijay Kumar K R          Jan 8, 2025      CS21-2619: Change in EOD on release version should update CDM Software version on Case
 * --------------------------------------------------------------------------------------------------------------------------------
 */
trigger ReleaseVersionTrigger on Release_Version__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
    if(TriggerControl__c.getAll() != null 
        && TriggerControl__c.getAll().containsKey('ReleaseVersion') 
        && !TriggerControl__c.getInstance('ReleaseVersion').DisableTrigger__c){
            
        new ReleaseVersionTriggerHandler().run(); 
    }
}