global with sharing class AssetUpdateManufacturingEntitlements implements Database.Batchable<sObject>, System.schedulable{

    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new AssetUpdateManufacturingEntitlements());
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        if(Test.isRunningTest()){
            return Database.getQueryLocator('Select node__c, node__r.asset__r.AccountId, entitlement__c, node__r.asset__c, entitlement__r.Type, entitlement__r.AccountId from Entitlement_Use__c where entitlement__r.Type = \'Manufacturing Entitlement\' LIMIT 1');
        }
        return Database.getQueryLocator('Select node__c, node__r.asset__r.AccountId, entitlement__c, node__r.asset__c, entitlement__r.Type, entitlement__r.AccountId from Entitlement_Use__c where entitlement__r.Type = \'Manufacturing Entitlement\'');
    }

    global void execute(Database.BatchableContext bc, List<Entitlement_Use__c> scope){
        List<Asset> assetsToUpdate = new List<Asset>();
        for(Entitlement_Use__c usageRecord : scope){
            if(usageRecord.node__c != null && usageRecord.node__r.asset__c != null && 
                usageRecord.entitlement__c != null && 
                usageRecord.node__r.asset__r.AccountId != usageRecord.entitlement__r.AccountId){
                    assetsToUpdate.add(new Asset(Id = usageRecord.node__r.asset__c, AccountId = usageRecord.entitlement__r.AccountId));
            }
        }

        if(assetsToUpdate.size()>0){
            update assetsToUpdate;
        }
    }

    global void finish(Database.BatchableContext bc){
    }

}