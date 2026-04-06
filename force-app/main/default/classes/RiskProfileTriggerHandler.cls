/**
 * @author Sushant Arora
 * @date 2024-11-19
 * @description 
 * A trigger handler class for the `Risk_Profile__c` object. 
 * This class provides methods to handle different trigger events 
 * (before insert, before update, after insert, after update) 
 * and delegates the processing logic to the helper class `RiskProfileTriggerHelper`.
 * 
 * 
 * @TestClass - RiskProfileTriggerHandlerTest
 */
public class RiskProfileTriggerHandler {
    
    /**
     * @description Flag to check if email/slack notifications are enabled
     */
    public static final Boolean isNotificationEnabledForOrg;

    static {
        Risk_Profile_Assignment__c orgWideSetting = Risk_Profile_Assignment__c.getOrgDefaults();
        isNotificationEnabledForOrg = orgWideSetting != null && orgWideSetting.Send_Notifications__c;
    }

    /**
     * @description Handles logic before inserting new `Risk_Profile__c` records.
     * @param newRiskProfiles List of new `Risk_Profile__c` records being inserted.
     */
    public void onBeforeInsert(List<Risk_Profile__c> newRiskProfiles){
        RiskProfileTriggerHelper.validateDoNotTrigger(newRiskProfiles);
        RiskProfileTriggerHelper.changeRPOwner(newRiskProfiles);
        RiskProfileTriggerHelper.populateEarliestRenewalOpportunity(newRiskProfiles, null);
        RiskProfileTriggerHelper.populateCXScore(newRiskProfiles, null);
    }

    /**
     * @description Handles logic before updating existing `Risk_Profile__c` records.
     * @param newRiskProfiles List of `Risk_Profile__c` records being updated.
     * @param oldRecordMap Old state of `Risk_Profile__c` records being updated.
     */
    public void onBeforeUpdate(List<Risk_Profile__c> newRiskProfiles, Map<Id, Risk_Profile__c> oldRecordMap){
        RiskProfileTriggerHelper.checkExistingRP(newRiskProfiles);
        RiskProfileTriggerHelper.populateCXScore(newRiskProfiles, oldRecordMap);
        RiskProfileTriggerHelper.populateEarliestRenewalOpportunity(newRiskProfiles, oldRecordMap);
        RiskProfileTriggerHelper.updateValidationStatus(newRiskProfiles, oldRecordMap);
    }

    /**
     * @description Handles logic after updating `Risk_Profile__c` records.
     * @param newRiskProfiles List of updated `Risk_Profile__c` records.
     * @param oldRecordMap Map of old `Risk_Profile__c` records keyed by their IDs.
     */
    public void onAfterUpdate(List<Risk_Profile__c> newRiskProfiles, Map<Id, Risk_Profile__c> oldRecordMap){
        RiskProfileTriggerHelper.createCaseforValidRP(newRiskProfiles,oldRecordMap);
        if(RiskProfileTriggerHandler.isNotificationEnabledForOrg){
            RiskProfileTriggerHelper.notifyOnUpdate(newRiskProfiles,oldRecordMap);
        }
    }

    /**
     * @description Handles logic after inserting new `Risk_Profile__c` records.
     * @param newRecordMap Map of new `Risk_Profile__c` records keyed by their IDs.
     * @param oldRecordMap (Optional) Map of old `Risk_Profile__c` records. Typically empty for insert events.
     */
    public void onAfterInsert(Map<Id, Risk_Profile__c> newRecordMap, Map<Id, Risk_Profile__c> oldRecordMap){        
        if(RiskProfileTriggerHandler.isNotificationEnabledForOrg){
            RiskProfileTriggerHelper.notifyOnCreate(newRecordMap.keyset());
        }
        RiskProfileTriggerHelper.attachRiskProfileToOpportunity(newRecordMap.values());
    }

    /**
     * @description Handles logic after inserting new `Risk_Profile__c` records.
     * @param newRecordMap (Optional) Map of new `Risk_Profile__c` records keyed by their IDs.  Typically empty for delete events.
     * @param oldRecordMap Map of old `Risk_Profile__c` records.
     */
    public void onAfterDelete(Map<Id, Risk_Profile__c> newRecordMap, Map<Id, Risk_Profile__c> oldRecordMap){    
        RiskProfileTriggerHelper.removeRiskProfileFromOpportunity(oldRecordMap);
    }
}