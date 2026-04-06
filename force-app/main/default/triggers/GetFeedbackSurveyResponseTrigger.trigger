/** 
 * @Author      : Vijay Kumar K R
 * @CreatedDate : 8th June 2023
 * @Description : Case Survey Feedback Owner Reassignment
 * @Handler     : GetFeedbackSurveyResponseHandler
 * @TstClass    : GetFeedbackSurveyResponseHandlerTest
 * -------------------------- @History --------------------------------------------------------------------------------------------
 * Story Number       Modified By              Date           Description
 * CS21-1261   		  Vijay Kumar K R          June 8, 2023   Case Survey Feedback Owner Reassignment
 * --------------------------------------------------------------------------------------------------------------------------------
 */
trigger GetFeedbackSurveyResponseTrigger on GetFeedback_Survey_Response__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    if(!TriggerControl__c.getInstance('GetFeedbackSurveyResponses').DisableTrigger__c) {
        new GetFeedbackSurveyResponseHandler().run();
    }
}