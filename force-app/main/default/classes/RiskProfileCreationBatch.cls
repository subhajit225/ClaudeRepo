/**
 * @author Sushant Arora
 * @date 2025-08-01
 * @description Batch and schedulable class to create Risk Profiles based on Account_Risk__c records.
 * This batch process checks for Account_Risk__c records that require updates, initiates Risk Profile creation,
 * handles conditional logic based on sync types (CX, ML), and respects configuration constraints.
 * Implements Database.Batchable<sObject>, Schedulable, and Database.Stateful.
 * @TestClass - RiskProfileCreationBatchTest
 */

public class RiskProfileCreationBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful {

    /**
     * @description Tracks types of risk syncs processed during the batch (e.g., ML, CX).
     */
    public Set<String> syncType = new Set<String>();
    
    /**
     * @description Defines the query to select Account_Risk__c records that need updates.
     * @param bc Batchable context (not used in this method).
     * @return Database.QueryLocator pointing to Account_Risk__c records with Need_Update__c = true.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Account__c, Risk_Type__c 
            FROM Account_Risk__c 
            WHERE Need_Update__c = true AND Account__c != null
        ]);
    }
    
    /**
     * @description Processes each batch of Account_Risk__c records:
     *  - Adds Account__c to a Set for profile creation.
     *  - Collects sync types (ML, CX).
     *  - Marks records as updated.
     *  - Calls risk profile creation logic and updates the records.
     * @param bc Batchable context.
     * @param scope List of Account_Risk__c records in the current batch scope.
     */
    public void execute(Database.BatchableContext bc, List<Account_Risk__c> scope) {
        Set<Id> accountIds = new Set<Id>();
        List<Account_Risk__c> toUpdate = new List<Account_Risk__c>();
        
        for (Account_Risk__c ar : scope) {
            accountIds.add(ar.Account__c);
            if (!syncType.contains('ML') && ar.Risk_Type__c == 'ML') {
                syncType.add('ML');
            }
            if (!syncType.contains('CX') && ar.Risk_Type__c == 'CX') {
                syncType.add('CX');
            }
            
            toUpdate.add(new Account_Risk__c(
                Id = ar.Id,
                Need_Update__c = false
            ));
        }
        
        if (!accountIds.isEmpty()) {
            CS_AutomaticRiskProfileCreation.createRiskProfile(accountIds, 'Account');
        }
        
        if (!toUpdate.isEmpty()) {
            try {
                TriggerConditionsBypass.addFlag('ByPassAccountRiskTrigger');
                Database.update(toUpdate,false);
            }
            finally{
                TriggerConditionsBypass.removeFlag('ByPassAccountRiskTrigger');
            }
        }
    }
    
    /**
     * @description Final method of the batch job. Performs post-processing:
     *  - Checks configuration settings to determine if CX/ML sync is allowed.
     *  - Handles expiration of ML Risk Profiles if configured.
     *  - Updates next run date for configuration if applicable.
     * @param bc Batchable context.
     */
    public void finish(Database.BatchableContext bc) {
        Boolean allowCX = true;
        Boolean allowExpRun = true;
        Boolean allowML = true;
        Custom_Configuration_Change__c freqConfig = new Custom_Configuration_Change__c();
        Id recordTypeId = Schema.SObjectType.Custom_Configuration_Change__c
            .getRecordTypeInfosByName()
            .get('RP Frequency Config')
            .getRecordTypeId();
        
        List<Custom_Configuration_Change__c> configList = [
            SELECT Config_For__c, Config_Type__c, Next_Run__c, Config_Disabled__c
            FROM Custom_Configuration_Change__c 
            WHERE RecordTypeId = :recordTypeId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        if (!configList.isEmpty() && configList[0].Config_Disabled__c == false) {
            freqConfig = configList[0];
            Date today = Date.today();            
            Boolean blockedUntilFuture = freqConfig.Next_Run__c != null && freqConfig.Next_Run__c > today;
            
            if (freqConfig.Config_For__c == 'CX Sync' && syncType.contains('CX')) {
                allowCX = !blockedUntilFuture;
            } else if (freqConfig.Config_For__c == 'ML Sync' && syncType.contains('ML')) {
                allowML = !blockedUntilFuture;
            } else if (freqConfig.Config_For__c == 'CX & ML Both' && (syncType.contains('ML') || syncType.contains('CX'))) {
                allowCX = !blockedUntilFuture;
                allowML = !blockedUntilFuture;
            }
        }

        // Check Risk_ML_Expiry label to determine if ML expiry should be run
        String expiryLabel = System.Label.Risk_ML_Expiry;
        if (!String.isBlank(expiryLabel)) {
            allowExpRun = expiryLabel.toLowerCase() == 'true';
        } else {
            allowExpRun = false; 
        }

        // Try to expire previous ML Risk Profiles
        try {
            if (allowExpRun && allowML) {
                AccountRiskTriggerHelper.expirePreviousMLRiskProfiles();
            }
        } catch (Exception e) {
            AccountRiskTriggerHelper.logError(e, 'Risk_Profile__c', 'handleBatch - expirePreviousMLRiskProfiles');
        }
        
        // Try to update next run date if sync allowed
        try {
            if ((freqConfig != null && (allowCX || allowML) && AccountRiskTriggerHelper.isApiOrderAutomationUser())) {
                AccountRiskTriggerHelper.updateNextRun();
            }
        } catch (Exception e) {
            AccountRiskTriggerHelper.logError(e, 'Custom_Configuration_Change__c', 'handleBatch - updateNextRun');
        } 
    }
    
    /**
     * @description Schedulable interface implementation. Triggers the batch job with a batch size of 200.
     * @param sc Schedulable context.
     */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new RiskProfileCreationBatch(), 200);
    }
}