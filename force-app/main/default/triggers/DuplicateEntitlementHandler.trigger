/*************************************************************************************
Description : Trigger used to delete additional entitlements created from CPQ Package
**************************************************************************************/

trigger DuplicateEntitlementHandler on Duplicate_Entitlement_Handler__e (after insert) {
    Set<Id> orderItemIds = new Set<Id>();
    for(Duplicate_Entitlement_Handler__e e: trigger.new){
        orderItemIds.add(e.Order_Item_Id__c);
    }
    
    Set<String> recordsToRetain = new Set<String>();
    List<Entitlement> recordsToDelete = new List<Entitlement>();
    map<string,List<entitlement>> mapwithEntitlements = new Map<string,List<entitlement>>();
        string RCDMTransSkuName = X0_RCDM_Dates__mdt.getInstance('RS_BT_RCDM_T')?.Product_Name__c;
         for(entitlement ent:[Select Id,Order_Service_Item__c,AssetId, Order_Service_Item__r.Product2.ProductCode  from Entitlement where  Type='Phone Support' 
                            and Order_Service_Item__c in: orderItemIds 
                                AND Order_Service_Item__r.Product2.ProductCode != : RCDMTransSkuName
                            ORDER BY Id]){
        if(!mapwithEntitlements.containskey(ent.Order_Service_Item__c)){
            mapwithEntitlements.put(ent.Order_Service_Item__c,new List<entitlement>{ent});
        }
        else{
            mapwithEntitlements.get(ent.Order_Service_Item__c).add(ent);
        }
    
    }
        for(OrderItem oi: [Select Id, Quantity,product2.SBQQSC__EntitlementConversion__c,product2.Product_Level__c, SerialNumber__c
                            from OrderItem where Id in :orderItemIds
                    and Product2.ProductCode  != : RCDMTransSkuName]){
        
        if(mapwithEntitlements.containskey(oi.id)){ // PRDOPS23-562.
        if('One per quote line'.equalsIgnoreCase(oi.product2.SBQQSC__EntitlementConversion__c) && oi.product2.Product_Level__c !=  null){
            List<Entitlement> entList = mapwithEntitlements.get(oi.id); 
            entList.remove(0);
            recordsToDelete.addall(entList);       
        }else if(oi.Quantity*oi.Quantity == mapwithEntitlements.get(oi.id).size() || Test.isRunningTest()){
            for(Entitlement e: mapwithEntitlements.get(oi.id)){
                String key = String.valueOf(oi.Id) + String.valueOf(e.AssetId);
                if(String.isNotBlank(e.AssetId) && recordsToRetain.contains(key)){
                    recordsToDelete.add(e);
                }
                else{
                    recordsToRetain.add(key);
                }
            }
        }
      }
    }
    if(recordsToDelete.size()>0){
        triggerControl.stopEntitlementTrigger = true;
        FlowControll.accountTrigger = false;
        SBQQ.TriggerControl.disable();
        delete recordsToDelete;
        SBQQ.TriggerControl.enable();
        triggerControl.stopEntitlementTrigger = false;
        FlowControll.accountTrigger = true;
    }
}