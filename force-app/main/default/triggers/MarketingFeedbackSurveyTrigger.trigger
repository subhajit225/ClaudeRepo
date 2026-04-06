trigger MarketingFeedbackSurveyTrigger on Marketing_GetFeedback_Survey__c (before insert,
                                                                            before update,
                                                                            before delete,
                                                                            after insert,
                                                                            after update,
                                                                            after delete) {
    TriggerManager.invokeHandler(new MarketingFeedbackSurveyTriggerHandler());                                                                             
}