public without sharing class ProductFeatureTriggerHandler extends TriggerManager.GenericTriggerHandler{
    public override void onBeforeInsert(List<sObject> newRecords) {
        List<Product_Feature__c> pfList = (List<Product_Feature__c>) newRecords;
         List<String> allProductCode = new List<String>();
        Map<String,Id> productNameIdMap = new Map<String,Id>();
        for(Product_Feature__c pf : pfList){
            if(pf.Product_Code__c!=null){
                allProductCode.add(pf.Product_Code__c);
            }else{
                pf.addError('Product Code Should Not Be Empty');
            }
            
        }
        
        for(Product2 prod : [Select Id,Name from product2 where Name In : allProductCode]){
            productNameIdMap.put(prod.Name,prod.Id);
        }
        
        for(Product_Feature__c pf : pfList){
            if(productNameIdMap.containsKey(pf.Product_Code__c) && productNameIdMap.get(pf.Product_Code__c)!=null){
                pf.Product_Name__c	 = productNameIdMap.get(pf.Product_Code__c);
            }else{
                pf.addError('Product Code Should Not Be Empty');
                
            }
        }
    }
}