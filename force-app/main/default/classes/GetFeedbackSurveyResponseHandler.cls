/** 
 * @Author      : Vijay Kumar K R
 * @CreatedDate : 8th June 2023
 * @Description : Case Survey Feedback Owner Reassignment
 * @TstClass    : GetFeedbackSurveyResponseHandlerTest
 * -------------------------- @History --------------------------------------------------------------------------------------------
 * Story Number       Modified By              Date           Description
 * CS21-1261   		  Vijay Kumar K R          June 8, 2023   Case Survey Feedback Owner Reassignment
 * --------------------------------------------------------------------------------------------------------------------------------
 */
public without sharing class GetFeedbackSurveyResponseHandler extends TriggerHandler {
    
    public override void beforeInsert() {
        updateSurveyOwner();
    }

    public override void beforeUpdate() {
        updateSurveyOwner();
    }

    /**
    * @description method to get Case owner details of each case.
    * @Method   : updateSurveyOwner
    * @param    : 
    * @return void
    */
    public void updateSurveyOwner() {

        Set<Id> caseIdSet = new Set<Id>();
        for (GetFeedback_Survey_Response__c objGetFdbk : (List<GetFeedback_Survey_Response__c>)Trigger.new) {
            if(isChanged('Case_ID__c', objGetFdbk)){
                if(objGetFdbk.Case_ID__c != null){
                    caseIdSet.add(objGetFdbk.Case_ID__c);
                }
                // Updating Survey_Owner__c to null when  Case_ID__c removed from GetFeedback_Survey_Response__c
                else if(objGetFdbk.Case_ID__c == null){
                    objGetFdbk.Survey_Owner__c = null;
                }
            }
        }
        
        if(!caseIdSet.isEmpty()){
            Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, OwnerId FROM Case WHERE Id =: caseIdSet]);
            // The Survey Owner field defaulted to the same information as the current Case Owner. 
            for (GetFeedback_Survey_Response__c objGetFdbk : (List<GetFeedback_Survey_Response__c>)Trigger.new) {
                if(caseMap.containsKey(objGetFdbk.Case_ID__c)
                    && isChanged('Case_ID__c', objGetFdbk)){
                        Id caseOwnerId = caseMap.get(objGetFdbk.Case_ID__c).OwnerId;
                        // Updating Survey_Owner__c to caseOwnerId when Case_ID__c changed
                        if(caseOwnerId != null
                            && caseOwnerId.getSObjectType().getDescribe().getName() == 'User'){
                            objGetFdbk.Survey_Owner__c = caseOwnerId;
                        }
                        // Updating Survey_Owner__c to null when  Case_ID__c changed to QUEUE
                        else{
                            objGetFdbk.Survey_Owner__c = null;
                        }
                }
            }
        }
    }
}