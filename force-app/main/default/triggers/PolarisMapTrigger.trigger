trigger PolarisMapTrigger on Polaris_SKU_Mapping_V2__c (after insert, after update) {

    Map<id,String> mapProdLevelToldPROD = new Map<id,String>();
    Map<id,String> mapFeatureToNewPROD = new Map<id,String>();
    for(Polaris_SKU_Mapping_V2__c mmc: trigger.new){
    
        if((trigger.oldMap != null && trigger.oldMap.get(mmc.id).After_Conversion_Product_Level__c != mmc.After_Conversion_Product_Level__c) || (trigger.isInsert)){
        
            mapProdLevelToldPROD.PUT(mmc.Old_Product__c, mmc.After_Conversion_Product_Level__c);
        }
        
       
        
        
    }
    
    Set<id> prodIds = new set<id>();
    if(mapProdLevelToldPROD.keyset().size()>0)
        prodIds.addAll(mapProdLevelToldPROD.keyset());
  
        
        
    List<Product2> prodList = [select id,After_Conversion_Product_Level__c from Product2 where id in: prodIds];
    List<Product2> ProdListToUpdate = new List<Product2>();
    
    if(prodList != null && prodList.size()>0){
    
        for(Product2 prod: prodList){
            
            
            
            
            if(mapProdLevelToldPROD.containsKey(prod.id)){
                prod.After_Conversion_Product_Level__c =  mapProdLevelToldPROD.get(prod.id) ;
                ProdListToUpdate.add(prod);
            }
            
          
        
        }
        
        if(ProdListToUpdate.size()>0)
            update ProdListToUpdate;
    }
    

}