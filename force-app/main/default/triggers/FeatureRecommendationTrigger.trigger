trigger FeatureRecommendationTrigger on Feature_Recommendation__c (before update, before insert)//, before delete, after update, after insert, after delete)
{
    new FeatureRecommendationTriggerHandler().run();
}