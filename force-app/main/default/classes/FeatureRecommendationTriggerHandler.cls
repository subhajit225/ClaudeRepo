public with sharing class FeatureRecommendationTriggerHandler Extends TriggerHandler {
    public override void beforeUpdate() {
        List<Feature_Recommendation__c> newList = (List<Feature_Recommendation__c>) Trigger.new;
        Map<Id, Feature_Recommendation__c> oldMap = (Map<Id, Feature_Recommendation__c>) Trigger.oldMap;
        FeatureRecommendationTriggerHelper.updateStatusAndCloseDate(newList, oldMap);
    }
}