public with sharing class EntitlementUsageTriggerHandler extends TriggerHandler {
    private Boolean isDisabled = false;
    
    public EntitlementUsageTriggerHandler() {
        ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
        isDisabled = disabled.Disable_Entitlement_Usage_Trigger__c;

        ///// DO NOT RUN MORE THAN 2 TIME - Avoid Recursion /////
        //this.setMaxLoopCount(2);
    }
    
    public override void beforeInsert() {
    }
    
    public override void beforeUpdate() {
    }
    
    public override void beforeDelete() {}
    
    public override void afterInsert() {
        if(!isDisabled) {
            Set<Id> entitlementIds = new Set<Id>();
            EntitlementUsageTriggerHelper helperObj = new EntitlementUsageTriggerHelper();
            for(Entitlement_Use__c ent : (List<Entitlement_Use__c>)trigger.new){
                if(String.isNotBlank(ent.entitlement__c)){
                    entitlementIds.add(ent.entitlement__c);
                }
            }
            helperObj.updateEntitlementUsage(entitlementIds);
        }
    }
    
    public override void afterUpdate() {
        if(!isDisabled) {
            Set<Id> entitlementIds = new Set<Id>();
            EntitlementUsageTriggerHelper helperObj = new EntitlementUsageTriggerHelper();
            for(Entitlement_Use__c ent : (List<Entitlement_Use__c>)trigger.new){
                if(String.isNotBlank(ent.entitlement__c)){
                    entitlementIds.add(ent.entitlement__c);
                }
            }
            for(Entitlement_Use__c ent : (List<Entitlement_Use__c>)trigger.old){
                if(String.isNotBlank(ent.entitlement__c)){
                    entitlementIds.add(ent.entitlement__c);
                }
            }
            helperObj.updateEntitlementUsage(entitlementIds);
        }
    }
    
    public override void afterDelete() {
        if(!isDisabled) {
            Set<Id> entitlementIds = new Set<Id>();
            EntitlementUsageTriggerHelper helperObj = new EntitlementUsageTriggerHelper();
            for(Entitlement_Use__c ent : (List<Entitlement_Use__c>)trigger.old){
                if(String.isNotBlank(ent.entitlement__c)){
                    entitlementIds.add(ent.entitlement__c);
                }
            }
            helperObj.updateEntitlementUsage(entitlementIds);
        }
    }
    
    public override void afterUndelete() {
        if(!isDisabled) {
            Set<Id> entitlementIds = new Set<Id>();
            EntitlementUsageTriggerHelper helperObj = new EntitlementUsageTriggerHelper();
            for(Entitlement_Use__c ent : (List<Entitlement_Use__c>)trigger.new){
                if(String.isNotBlank(ent.entitlement__c)){
                    entitlementIds.add(ent.entitlement__c);
                }
            }
            helperObj.updateEntitlementUsage(entitlementIds);
        }
    }
}