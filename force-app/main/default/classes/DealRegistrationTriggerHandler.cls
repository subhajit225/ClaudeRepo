/**
 * @description       : Handler class of DealRegistrationTrigger 
 * @author            : Harshit Garg
 * @group             : 
 * @last modified on  : 02-18-2026
 * @last modified by  : Harshit Garg
**/
public without sharing class DealRegistrationTriggerHandler extends TriggerManager.GenericTriggerHandler{
    DealRegistrationTriggerHelper helper;

    private List<Deal_Registration__c> newList = (List<Deal_Registration__c>)Trigger.new;
    private List<Deal_Registration__c> oldList = (List<Deal_Registration__c>)Trigger.old;
    private Map<Id, Deal_Registration__c> newMap = (Map<Id, Deal_Registration__c>)Trigger.newMap;
    private Map<Id, Deal_Registration__c> oldMap = (Map<Id, Deal_Registration__c>)Trigger.oldMap;

    /**
     * @description Constructor
     */
    public DealRegistrationTriggerHandler() {
        helper = new DealRegistrationTriggerHelper();
    }

    public static Set<ID> idSetToSkipValidation = new Set<ID>();

    public override void onBeforeInsert(List<sObject> newRecords) {
        helper.setDealRegistrationParameters(newList, null); 
        helper.autoPopulateEndUserInformation(newList);
        helper.populateDealPersonas(newList, null);
    }

    public override void onBeforeUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {
        helper.validateDeals(newList, oldMap);
        helper.setDealRegistrationParameters(newList, oldMap); 
		helper.populateDealPersonas(newList, oldMap);
        helper.setExpiryDateExtension(newList, oldMap); 
        helper.manageConvertedLeads(newList, oldMap);
        helper.changeDROwner(oldMap, newMap);
    }

    public override void onAfterInsert(Map<ID, sObject> newRecordsMap) {
        helper.dealRegL2AMatch(newList);
    }

    public override void onAfterUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {
        helper.updateOldLeadAndOppty(newList,oldMap);
        helper.updateRelatedOpportunity(newList,oldMap);
    }
}