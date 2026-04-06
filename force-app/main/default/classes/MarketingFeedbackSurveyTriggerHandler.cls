public inherited sharing class MarketingFeedbackSurveyTriggerHandler 
                        extends TriggerManager.GenericTriggerHandler{
    
    public override void onAfterInsert(Map<ID, sObject> newRecordsMap) {
        MarketingFeedbackSurveyTriggerHelper helper = new MarketingFeedbackSurveyTriggerHelper();

        Map<Id, Marketing_GetFeedback_Survey__c> newMap = (Map<Id, Marketing_GetFeedback_Survey__c>)newRecordsMap;
        
        helper.updateContactLastFeedbackDate( newMap.values() );
    }
}