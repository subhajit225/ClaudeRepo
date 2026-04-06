public class EntitlementTriggerHelperClass {
    
    public static void isRenewalableAssignmentWithAsset (Set<Id> assetIds, Set<String> productCodeSet, Set<Id> productIdSet, Map<Id, Boolean> mapAssetEntlStatus) {

        try {
            List<Entitlement> entList = [SELECT Id, Name, EndDate, AssetId, Product__c, Product__r.ProductCode 
                                         FROM Entitlement 
                                         WHERE AssetId in :assetIds 
                                         ORDER BY EndDate DESC];
            Map<String, SObject> astIdEntMap = (Map<String, SObject>) ShGl_CommonUtility.convertListToFieldMap(entList, 'AssetId');
            Map<String, SObject> prdIdEntMap = (Map<String, SObject>) ShGl_CommonUtility.convertListToFieldMap(entList, 'Product__c');
            
            for(Id astId : assetIds) {
                if(astIdEntMap != NULL && astIdEntMap.size() > 0 && astIdEntMap.containsKey(astId)) {
                    Entitlement ent = (Entitlement) astIdEntMap.get(astId);
                    for(Id prodId : productIdSet) {
                        system.debug('ent.Product__c == prodId --> '+ent.Product__c+' == '+prodId);
                        if(ent.Product__c == prodId) {
                            mapAssetEntlStatus.put(ent.Id, true);
                        }
                    }
                    for(String prodCode : productCodeSet) {
                        system.debug('ent.Product__r.ProductCode == prodCode --> '+ent.Product__r.ProductCode+' == '+prodCode);
                        if(ent.Product__r.ProductCode == prodCode) {
                            mapAssetEntlStatus.put(ent.Id, true);
                        }
                    }
    
                }
            }
        } catch (Exception ex) {
            System.debug('Exception ex : '+ex.getMessage());
            System.debug('Exception ex : '+ex.getStackTraceString());
        }

/*
 * AK 10/4/2018: Production Issue fix - refactored above code - query inside for loop
        for(Id ast : assetIds) {
            for(Product2  prod : [SELECT Id, Name, (SELECT Id, Name, EndDate FROM Entitlements__r WHERE assetId = :ast ORDER BY EndDate DESC LIMIT 1) FROM Product2 WHERE Id IN :productIdSet]) {
                if(!(prod.Entitlements__r.isEmpty()) && prod.Entitlements__r != null) {
                    system.debug('prod.Entitlements__r == '+prod.Entitlements__r);
                    mapAssetEntlStatus.put(prod.Entitlements__r[0].Id, true);
                }
            }
        }
        
        for(String prod : productCodeSet) {
            for(Asset ast : [SELECT Id, Name, (SELECT Id, Name, EndDate, Product__r.ProductCode FROM Entitlements WHERE Product__r.ProductCode LIKE :prod ORDER BY EndDate DESC LIMIT 1) FROM Asset WHERE Id = :assetIds ]) { 
                if(!(ast.Entitlements.isEmpty()) && ast.Entitlements != null) {
                    system.debug('entl == '+ast.Entitlements[0]);
                    mapAssetEntlStatus.put(ast.Entitlements[0].Id, true);
                }   
            }
        }
*/
    }
    
    public static void isRenewalableAssignmentWithOutAsset (Map<Id, Set<Entitlement>> mapAccountEntitlement_ProdCode, Map<Id, Boolean> mapAssetEntlStatus) {
        
        for(Id accId : mapAccountEntitlement_ProdCode.keySet()) {
            Id finalUpdateId = null;
            Date compareDate = null;
            for(Entitlement entl : mapAccountEntitlement_ProdCode.get(accId)) {
                if(entl.EndDate != null && compareDate == null) {
                    compareDate = entl.EndDate;
                    finalUpdateId = entl.Id;
                } else if(entl.StartDate == compareDate.addDays(1)) {
                    compareDate = entl.EndDate;
                    finalUpdateId = entl.Id;
                } else {
                    compareDate = entl.EndDate;
                    mapAssetEntlStatus.put(entl.id, true);
                }
            }
            
            if(finalUpdateId != null) {
                mapAssetEntlStatus.put(finalUpdateId, true);
            }
        }
    }
    
}