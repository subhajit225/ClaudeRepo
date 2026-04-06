/**
 * @description       : Handler class of PartnerOnboardingRequestTrigger
 * @author            : Harshit Garg
 * @group             : 
 * @last modified on  : 02-06-2026
 * @last modified by  : Harshit Garg
**/

public class PartnerOnboardingRequestTriggerHandler extends TriggerManager.GenericTriggerHandler {
	PartnerOnboardingRequestTriggerHelper helper;

    private List<Partner_Onboarding_Request__c> newList = (List<Partner_Onboarding_Request__c>)Trigger.new;
    private List<Partner_Onboarding_Request__c> oldList = (List<Partner_Onboarding_Request__c>)Trigger.old;
    private Map<Id, Partner_Onboarding_Request__c> newMap = (Map<Id, Partner_Onboarding_Request__c>)Trigger.newMap;
    private Map<Id, Partner_Onboarding_Request__c> oldMap = (Map<Id, Partner_Onboarding_Request__c>)Trigger.oldMap;

    /**
     * description: constructor of PartnerOnboardingRequestTriggerHandler
     */
    public PartnerOnboardingRequestTriggerHandler() {
        helper = new PartnerOnboardingRequestTriggerHelper();
    }
    
    /**
     * description: to invoke the logic which need to run before insert
     * @param newRecords: List of new records
     * @return : void
     */
    public override void onBeforeInsert(List<sObject> newRecords) {
        helper.assignOwner(newList);
    }

    /**
     * description: to invoke the logic which need to run before update
     * @param oldRecordsMap: Map of old records
     * @param oldRecordsMap: Map of new records
     * @return : void
     */
    public override void onBeforeUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {
        helper.setComments(oldMap, newList);
    }

    /**
     * description: to invoke the logic which need to run after update
     * @param oldRecordsMap: Map of old records
     * @param oldRecordsMap: Map of new records
     * @return : void
     */
    public override void onAfterUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {
        helper.insightWebServiceCallOut(oldMap, newList);
        helper.convertPartnerOnBoarding(oldMap, newList);
    }
}