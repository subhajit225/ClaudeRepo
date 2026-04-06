/**
* @Author      : Vijay Kumar K R (Customer)
* @CreatedDate : Apr 06, 2023 
* @TstClass    : BatchPopulateGetFeedbackSurveyOwnerTest
* @Description : BatchPopulateGetFeedbackSurveyOwner objBatch = new BatchPopulateGetFeedbackSurveyOwner(); 
                    database.executeBatch(objBatch, 1000); 
* -------------------------- @History -------------------------------------
* Story Number       Modified By              Date           Description
* CS21-1452        Vijay Kumar K R        July 21 2023     Case Survey Feedback Owner Reassignment: If Case Owner changes in case of a transfer of ownership, the new Survey Owner field should capture the change (last case owner).
* -------------------------------------------------------------------------
*/
global class BatchPopulateGetFeedbackSurveyOwner implements Database.Batchable<sObject>{

    global Database.QueryLocator start(Database.BatchableContext bc){

        List<String> allowedProfileNameList = new List<String>{'Rubrik Customer Support manager', 'Rubrik Customer Support User'};

        // Query String
        String userQueryString = 'SELECT Id, Case_ID__c, Case_ID__r.OwnerId, Survey_Owner__c ';
                userQueryString += ' FROM GetFeedback_Survey_Response__c ';
                userQueryString +=' WHERE Case_ID__c != null AND Case_ID__r.OwnerId != null AND Case_ID__r.Owner.ProfileId != null ';
                userQueryString +=' AND Case_ID__r.Owner.Profile.Name IN: allowedProfileNameList AND Case_ID__c != null AND Survey_Owner__c = null '+(Test.isRunningTest()?' LIMIT 150':'') ;
        return Database.getQueryLocator(userQueryString);
    }
    
    global void execute(Database.BatchableContext bc, List<GetFeedback_Survey_Response__c> scope){

        try {
            Map<Id, GetFeedback_Survey_Response__c> updateGetFeedbackMap = new Map<Id, GetFeedback_Survey_Response__c>();

            for(GetFeedback_Survey_Response__c objgf : scope){
                objgf.Survey_Owner__c = objgf.Case_ID__r.OwnerId;
                updateGetFeedbackMap.put(objgf.Id, objgf);
            }
            
            if(!updateGetFeedbackMap.isEmpty()){
                UPDATE updateGetFeedbackMap.values();
            }

        } catch (Exception e) {
            System.debug('BatchPopulateGetFeedbackSurveyOwner Exception: '+e.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc){
        
    }
}