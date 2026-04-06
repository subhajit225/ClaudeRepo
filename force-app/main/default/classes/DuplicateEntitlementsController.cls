public with sharing class DuplicateEntitlementsController {
    public Map<String, List<Entitlement>> duplicateMap{get;set;}
    public duplicateEntitlementsController(){
        //Identify duplicate entitlements
        List<AggregateResult> results = [Select Count(Id) cnt, ContractLineItemId, AssetId from Entitlement group by ContractLineItemId, AssetId having Count(Id)>1];
        if(results == null || results.size() == 0){
            return;
        }

        Set<Id> contractLineIds = new Set<Id>();
        for(AggregateResult result: results){
            String contractLineId = (Id)result.get('ContractLineItemId');
            String assetId = (Id)result.get('AssetId');
            if(String.isNotBlank(contractLineId) && String.isNotBlank(assetId)){
                contractLineIds.add(contractLineId);
            }
        }
        duplicateMap = new Map<String, List<Entitlement>>();
        for(ContractLineItem cli: [Select Id, SBQQSC__OrderProduct__r.Quantity, (Select Id, ContractLineItemId, ContractLineItem.LineItemNumber, AssetId, Name, Asset.Name, 
        		Order_Service_Item__c, Order_Service_Item__r.OrderItemNumber, Order_Service_Item__r.OrderId, 
        		ServiceContractId, ServiceContract.Name, Order_Service_Item__r.Order.OrderNumber, StartDate, EndDate, Status,AnnualContractValue__c,Renewal_Price__c 
        		from Entitlements) from ContractLineItem where Id in :contractLineIds]){
                    if(cli.SBQQSC__OrderProduct__r.Quantity == cli.Entitlements.size()){
                        continue;
                    }
                    for(Entitlement ent: cli.Entitlements){
                        String key = String.valueOf(cli.Id) + ent.AssetId;
                        if(duplicateMap.containsKey(key)){
                            duplicateMap.get(key).add(ent);
                        }
                        else{
                            List<Entitlement> entitlements = new List<Entitlement>();
                            entitlements.add(ent);
                            duplicateMap.put(key, entitlements);
                        }
                    }
        }
        
        for(String key: duplicateMap.keySet()){
            if(duplicateMap.get(key).size() < 2){
                duplicateMap.remove(key);
            }
        }
    }	
}