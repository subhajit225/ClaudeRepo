public class Decommission_Nodeclass {
	@Auraenabled
    public static void clearUsagecounter(string entitlementusageId)
    {
        system.debug('Entitlement ID **'+entitlementusageId);
        Entitlement_Use__c entUsageData =[SELECT id,entitlement__r.Id,entitlement__r.Name,entitlement__r.Usage_Quantity__c,entitlement__r.Entitlement_Usage__c,entitlement__c from Entitlement_Use__c WHERE id =:entitlementusageId];
        system.debug('entUsageData **'+entUsageData);
        Entitlement updateEnt = New Entitlement();
        updateEnt.id =entUsageData.entitlement__c;
        updateEnt.Entitlement_Usage__c = null;
        update updateEnt;
        
        
    }
}