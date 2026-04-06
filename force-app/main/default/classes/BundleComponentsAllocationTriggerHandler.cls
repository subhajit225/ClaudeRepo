/**
 * @description Handler class for the BundleComponentsAllocation trigger.
 * Inherits generic trigger handling logic from TriggerManager.GenericTriggerHandler.
 * Used to process trigger logic for Bundle_Components_Allocation__c object.
 * It will fill the Product_Name__c field on Product2 object if component record will have value in Product_SKU__c which is ProductCode.
 * @author Shailesh Kumar
 * @test class BundleComponentTriggerHandler_Test
 * @lastModifieddate   03 June 2025
 * @lastModifiedBy   Shailesh Kumar
 */
public with sharing class BundleComponentsAllocationTriggerHandler extends TriggerManager.GenericTriggerHandler{
    /**
    * @description Executes logic before records are inserted.This override handles pre-insert operations for the trigger.
    * @param newRecords The list of sObjects being inserted.
    */
    public override void onBeforeInsert(List<sObject> newRecords) {
        List<Bundle_Components_Allocation__c> componentRecords = (List<Bundle_Components_Allocation__c>) newRecords;
        List<String> allProductCode = new List<String>();
        Map<String,Id> productNameIdMap = new Map<String,Id>();
        for(Bundle_Components_Allocation__c rec : componentRecords){
            if(rec.Product_SKU__c!=null){
                allProductCode.add(rec.Product_SKU__c);
            }
        }
        
        for(Product2 prod : [Select Id,Name from product2 where Name In : allProductCode]){
            productNameIdMap.put(prod.Name,prod.Id);
        }
        
        for(Bundle_Components_Allocation__c rec : componentRecords){
            if(productNameIdMap.containsKey(rec.Product_SKU__c) && productNameIdMap.get(rec.Product_SKU__c)!=null){
                rec.Product_Name__c   = productNameIdMap.get(rec.Product_SKU__c);
            }
        }
    }
}