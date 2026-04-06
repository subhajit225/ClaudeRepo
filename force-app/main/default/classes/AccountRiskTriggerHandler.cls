/**
* @author Sushant Arora
* @date 2024-06-12
* @description 
* A trigger handler class for the `Account_Risk__c` object. 
* This class provides methods to handle different trigger events 
* (before insert, before update, after insert, after update) 
* and delegates the processing logic to the helper class `RiskProfileTriggerHelper`.
* 
* 
* @TestClass - AccountRiskTriggerHandlerTest
*/
public class AccountRiskTriggerHandler {
    
     private Boolean isAllowedExecution = true;

    /**
     * @description constructor to check whether trigger execution is allowed or not
     */
    public AccountRiskTriggerHandler() {
        ShGl_DisableBusinessLogic__c disabledBusinessLogic = ShGl_DisableBusinessLogic__c.getInstance();
        Boolean ByPassAccountRiskTrigger = TriggerConditionsBypass.isByPassed('ByPassAccountRiskTrigger');
       
         if(disabledBusinessLogic?.Disable_Account_Risk_Triggers__c || ByPassAccountRiskTrigger == true){
            this.isAllowedExecution = false;
         }
    }
    
    /**
     * @description Central dispatcher method that routes trigger execution
     *              to the appropriate handler based on the TriggerOperation enum.
     *              Execution is skipped if logic is disabled via custom metadata.
     * @param operationType The trigger context operation (BEFORE_INSERT, AFTER_UPDATE, etc.)
     * @param newList List of current Account_Risk__c records (Trigger.new)
     * @param oldList List of previous Account_Risk__c records (Trigger.old)
     * @param newMap Map of current Account_Risk__c records by Id (Trigger.newMap)
     * @param oldMap Map of previous Account_Risk__c records by Id (Trigger.oldMap)
     */
    public void handleOperation(System.TriggerOperation operationType, List<Account_Risk__c> newList,List<Account_Risk__c> oldList,Map<Id, Account_Risk__c> newMap,Map<Id, Account_Risk__c> oldMap) {
        switch on operationType {
            when AFTER_INSERT {
                handleAfterInsert(newMap);
            }
            when AFTER_UPDATE {
                handleAfterUpdate(newList, oldMap);
            }
            when BEFORE_INSERT {
                handleBeforeInsert(newList);
            }
            when BEFORE_UPDATE {
                handleBeforeUpdate(newList, oldMap);
            }
            // Add other operations as needed
        }
    }
    
    /**
     * @description Handler for before-insert Account_Risk__c events.
     * @param newList List of newly inserted Account_Risk__c records
     */
    public void handleBeforeInsert(List<Account_Risk__c> newList) {
        if(isAllowedExecution){
            AccountRiskTriggerHelper.processBeforeInsert(newList);
        }
    }
    
        /**
     * @description Handler for before-update Account_Risk__c events.
     * @param newList List of updated Account_Risk__c records
     * @param oldMap Map of previous versions of Account_Risk__c records
     */
    public void handleBeforeUpdate(
        List<Account_Risk__c> newList,
        Map<Id, Account_Risk__c> oldMap
    ) {
        if(isAllowedExecution){
        AccountRiskTriggerHelper.processBeforeUpdate(newList, oldMap);
        }
    }

    /**
     * @description Handler for after-insert Account_Risk__c events.
     * @param newMap Map of newly inserted Account_Risk__c records
     */
    public void handleAfterInsert(Map<Id, Account_Risk__c> newMap) {
        if(isAllowedExecution){
        AccountRiskTriggerHelper.processAfterInsert(newMap);
        }
    }

    /**
     * @description Handler for after-update Account_Risk__c events.
     * @param newList List of updated Account_Risk__c records
     * @param oldMap Map of previous versions of Account_Risk__c records
     */
    public void handleAfterUpdate(
        List<Account_Risk__c> newList,
        Map<Id, Account_Risk__c> oldMap
    ) {
        if(isAllowedExecution){
        AccountRiskTriggerHelper.processAfterUpdate(newList, oldMap);
        }
    }
}