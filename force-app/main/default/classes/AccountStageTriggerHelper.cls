/**
 * @description
 * Added as part of SAL26-323.
 * This Apex class is the helper class of Account_Stage__c object.
 */ 
public without sharing class AccountStageTriggerHelper {

    /** 
     * @description
     * @param oldRecordsMap
     * @param newAccountStage
     * SAL26-323 Method to update Operations_Request__c record status to "Complete" if Account stage is Success or with error message- Data already available.
     */
    public static void updateAccountStageStatus(Map<ID, Account_Stage__c> oldRecordsMap, List<Account_Stage__c> newAccountStage){
        try{
            List<Id> operationRequestIds = new List<Id>();
            for(Account_Stage__c acctStage : newAccountStage){
                if(acctStage.Operations_Request__c != null && (acctStage.Status__c == 'Success' && acctStage.Status__c != oldRecordsMap.get(acctStage.Id).Status__c) || (acctStage.Status__c == 'Failure' && acctStage.Status__c != oldRecordsMap.get(acctStage.Id).Status__c && acctStage.Error_message__c.contains('Data already available'))){
                    operationRequestIds.add(acctStage.Operations_Request__c);
                }
            }
            if(!operationRequestIds.IsEmpty()){
                List<Operations_Request__c> opList = [select id, Status__c from Operations_Request__c where Id IN :operationRequestIds and Status__c != 'Complete'];
                if(!opList.IsEmpty()){
                    for(Operations_Request__c opRequest : opList){
                        opRequest.Status__c = 'Complete';
                    }

                    update opList;
                }
            }
        }catch(exception ex){
            insert LogError.CreateGenericErrorLog('AccountStageTriggerHelper',ex,'updateAccountStageStatus class is failed');
        }
    }
}