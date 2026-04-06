public with sharing class FeatureRecommendationTriggerHelper {
    public static void updateStatusAndCloseDate(List<Feature_Recommendation__c> newFeatureRecommendation, Map<Id,Feature_Recommendation__c> oldFeatureRecommendation){
        for(Feature_Recommendation__c FR : newFeatureRecommendation) {
            if(FR.First_Use_Date__c != null && FR.First_Use_Date__c != oldFeatureRecommendation.get(FR.Id).First_Use_Date__c) {
                FR.Status__c = 'In Use';
                FR.Close_Date__c = DateTime.now();
            }
            if(FR.Status__c == 'Suspended' && FR.Status__c != oldFeatureRecommendation.get(FR.Id).Status__c) {
                FR.Suspended_Date__c = FR.Close_Date__c = DateTime.now();
            }
            // system.debug('-------------------closed date-----------------'+FR.Close_Date__c);
        }
    }
}