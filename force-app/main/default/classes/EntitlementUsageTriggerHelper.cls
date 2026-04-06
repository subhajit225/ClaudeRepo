public with sharing class EntitlementUsageTriggerHelper {
    public void updateEntitlementUsage(Set<Id> entitlementIds){
        Set<Id> recordsProcessed = new Set<Id>();
        List<Entitlement> entitlementsToUpdate = new List<Entitlement>();
        for(AggregateResult ar : [Select Count(Id), entitlement__c from Entitlement_Use__c where entitlement__c in :entitlementIds group by entitlement__c ]){
            entitlementsToUpdate.add(new Entitlement(Id = (Id)ar.get('entitlement__c'), Entitlement_Usage__c = (Decimal)ar.get('expr0')));
            recordsProcessed.add((Id)ar.get('entitlement__c'));
        }

        Boolean isSuccess = true;
        if(recordsProcessed.size()>0){
            isSuccess = entitlementIds.removeAll(recordsProcessed);
        }
        System.debug(isSuccess);
        if(isSuccess){
            for(Id remainingEnt: entitlementIds){
                entitlementsToUpdate.add(new Entitlement(Id = remainingEnt, Entitlement_Usage__c = 0));
            }
        }

        if(entitlementsToUpdate.size()>0){
            update entitlementsToUpdate;
        }
    }
}