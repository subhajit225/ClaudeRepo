/**
* @Class Name :- ProductTriggerHelper 
*    
* @Created Date :- 04-08-2018 
* @description : Helper And Utility for Product  Trigger   
*   
//********************Change Logs*****************************************************************************
* 
* Change Request            Modified By          Date           Description 
* CPQ22-5418            Mustakim Shaikh        24-7-2025        Removed methods processProductChangeRequest, onProductChangeReqUpdate and removed references of Product Change Request related logic as its deprecated.
*  
//********************Change Logs Ends*************************************************************************
**/ 
public with sharing class ProductTriggerHelper {
    public static List<string> productCodeList = new List<string>();
    /**
     * @description Handles logic before updating Product2 records, including refreshing credit amounts,
     *              updating sales comp category change dates, and managing product code lists.
     * @param oldMap Map of existing Product2 records (before update)
     * @param newMap Map of new Product2 records (after update)
     */
    public static void beforeProductUpdate(Map<ID, Product2> oldMap, Map<ID, Product2> newMap){
    
            for(Product2 newObj: newMap.values()){
                if(newObj.Is_Refresh_Product_MinQnty__c == null && oldMap.get(newObj.id).Is_Refresh_Product_MinQnty__c != null){
                    newObj.Refresh_Credit_Amount__c = null;
                }else if(newObj.Is_Refresh_Product_MinQnty__c != oldMap.get(newObj.id).Is_Refresh_Product_MinQnty__c){
                    if(newObj.Productcode.contains('SE-')){
                        productCodeList.add(seProductCodeModifier(newObj.Productcode,'SE-','S-'));
                    }else{
                        productCodeList.add(newObj.Productcode);
                    }
                }
                if(newObj.Sales_Comp_Category__c != oldMap.get(newObj.id).Sales_Comp_Category__c){
                    newObj.SalesCompCategoryChangedDate__c = System.now();
                }                
            }
        if(productCodeList.isEmpty()){
            for(Product2 newObj: newMap.values()){
                if(newObj.Is_Refresh_Product_MinQnty__c == null && oldMap.get(newObj.id).Is_Refresh_Product_MinQnty__c != null){
                    newObj.Refresh_Credit_Amount__c = null;
                }else if(newObj.Is_Refresh_Product_MinQnty__c != oldMap.get(newObj.id).Is_Refresh_Product_MinQnty__c){
                    if(newObj.Productcode.contains('SE-')){
                        productCodeList.add(SEProductCodeModifier(newObj.Productcode,'SE-','S-'));
                    }else{
                        productCodeList.add(newObj.Productcode);
                    }
                }
            }
        }
        if(!productCodeList.isEmpty()){
            Map<string,Decimal> ProductPriceMap = new Map<string,Decimal>();
            if (Schema.sObjectType.PricebookEntry.isAccessible()) {
                for(Pricebookentry PBE : [select id,Unitprice,product2id,product2.productCode from Pricebookentry where pricebook2id  = : system.label.CPQ_Pricebook_ID AND product2.productCode IN : productCodeList AND product2.isActive = true AND isActive = true]){
                    ProductPriceMap.put(PBE.product2.productCode,PBE.Unitprice);
                }
            }
            
            if(!ProductPriceMap.values().isEmpty()){
                for(Product2 newObj: newMap.values()){
                    if(newObj.Productcode.contains('SE-')){
                        newObj.Refresh_Credit_Amount__c = ProductPriceMap.get(seProductCodeModifier(newObj.Productcode,'SE-','S-'));
                    }else{
                        newObj.Refresh_Credit_Amount__c = ProductPriceMap.get(newObj.Productcode);
                    }
                }
            }
        }
        
        
        
    }

    /**
     * @description Modifies the given product code by replacing the target substring with the replacement substring.
     * @param Productcode The original product code string.
     * @param target The substring to be replaced.
     * @param replacement The substring to replace with.
     * @return The modified product code string.
     */
    public static string seProductCodeModifier(String Productcode,String target,String replacement){
        String seProductCodeModify;
        seProductCodeModify = Productcode;
        return seProductCodeModify.replace(target,replacement);
        
    }
    

    
    /**
    * @description method is used to mark products where Bundle feature is updated - CS21-865 
    *              - Veera Gandi
    * @param    newList - trigger.new trigger context variable
    * @param    oldMap - trigger.oldmap trigger contect variable
    */
    public static void handleBundleFeatureUpdate(List<Product2> newList, Map<Id, Product2> oldMap) {       
        //collecting Product Ids where Bundle Feature is updated
        for (Product2 eachProduct : newList) {            
            if (eachProduct.Bundle_Features__c != oldMap.get(eachProduct.Id).Bundle_Features__c) {
                eachProduct.IsBundleFeaturesUpdated__c = true;
            }
        }
    }
    
    
//Added beforeProductInsert() method to th apex class as part of SF-10157 by Shaloo
    /**
     * @description Method to set default values for Product2 fields before insert.
     * @param ProdList List of Product2 records being inserted.
     */
    public static void beforeProductInsert(List<Product2> ProdList){
        for(Product2 newObj: ProdList){
            if(newObj.ProductCode != null){
                System.debug(LoggingLevel.INFO, '\n~~~~:');
                newObj.SBQQ__QuantityScale__c = 0;
                newObj.SBQQ__DescriptionLocked__c = TRUE;
            }
        }  
    }
    //Added method to set Quoting Restriction field as part of CPQ22-4821 by Ashwini B
    /**
     * @description Sets or updates the Quoting_Restriction__c field on Product2 records based on related profile, role, or user fields.
     * @param ProdList List of Product2 records to process.
     */
  public static void populateQuotingRestriction(List<Product2> ProdList){
      System.debug(LoggingLevel.INFO, 'Enter into populateQuotingRestriction method');
      System.debug(LoggingLevel.INFO, 'ProdList'+ProdList);
      List<Product2> toUpdateLst = new List<Product2>();
      string strValueToRemove ='User/Profile';
      System.debug(LoggingLevel.INFO, 'strValueToRemove'+strValueToRemove);
      
      
        for(Product2 newObj: ProdList){
            System.debug(LoggingLevel.INFO, 'profile'+newObj.Quotable_by_profiles__c);
            System.debug(LoggingLevel.INFO, 'role'+newObj.Quotable_By_Role__c);
            System.debug(LoggingLevel.INFO, 'user'+newObj.Quotable_by_users__c);
            System.debug(LoggingLevel.INFO, 'Restriction'+newObj.Quoting_Restriction__c);
            if(newObj.Quotable_by_profiles__c != null || newObj.Quotable_By_Role__c!= null || newObj.Quotable_by_users__c!= null){ 
                if(newObj.Quoting_Restriction__c == null){
                    newObj.Quoting_Restriction__c = 'User/Profile';
                }else{
                    newObj.Quoting_Restriction__c = !newObj.Quoting_Restriction__c.contains('User/Profile') ? newObj.Quoting_Restriction__c += ';' + 'User/Profile' : newObj.Quoting_Restriction__c; 
                }                   
            }else if(newObj.Quoting_Restriction__c != null && newObj.Quotable_by_profiles__c == null && newObj.Quotable_By_Role__c == null && newObj.Quotable_by_users__c == null){
                string strPickListValue = newObj.Quoting_Restriction__c;
                List<string> lstPicklistValues = strPickListValue.split(';');
                    if(lstPicklistValues.contains(strValueToRemove)){
                        lstPicklistValues.remove(lstPicklistValues.indexOf(strValueToRemove));
                    }   
                newObj.Quoting_Restriction__c = String.join(lstPicklistValues,';'); 
                System.debug(LoggingLevel.INFO, 'newObj.Quoting_Restriction__c'+newObj.Quoting_Restriction__c);                
                }                
            }          
            
    }
    /**
     * @description Populates the Pricebook_Entry_Id__c field on Product2 records with the corresponding PricebookEntry Id from the CPQ Pricebook.
     * @param ProdList List of Product2 records to update with PricebookEntry information.
     */
    public static void populatePricebookDetailsOnProduct(List<Product2> ProdList){
        system.debug(LoggingLevel.INFO, 'Inside populatePricebookDetailsOnProduct Method');
        Set<Id> prIds = new Set<Id>();
        Map<Id,Id> productPbeMap = new Map<Id,Id>();
        Map<Id,Pricebookentry> prodVsPbeMap = new Map<Id,Pricebookentry>();        
        for(Product2 newObj: ProdList){
            prIds.add(newObj.Id);           
        }       
        //fetch pricebook Id from custom label || CPQ Pricebook
        Id cpqPrId = System.Label.CPQ_Pricebook_ID;
        
        //fetch procebook entry for products present in ProdList
        List<Pricebookentry> pricebookentryLst = new List<Pricebookentry>();
        if (Schema.sObjectType.PricebookEntry.isAccessible()) {
            pricebookentryLst = [SELECT id,name, IsActive, Product2Id,Pricebook2Id,Product2.Pricebook_Entry_Id__c, Product2.Product_Level__c, Product2.IsActive, Product2.ProductCode
                                 FROM Pricebookentry 
                                 WHERE product2Id IN :prIds AND pricebook2Id=:cpqPrId];
        }
        
        //create map of product Id and pricebookentry Id
        for(Pricebookentry pbe: pricebookentryLst){
            //productPbeMap.put(pbe.Product2Id,pbe.Id);     
            prodVsPbeMap.put(pbe.Product2Id,pbe);      
        }
        
        //update pricebookwntry id on product
            for(Product2 prod: ProdList){
                if(prodVsPbeMap.containsKey(prod.Id)) {
                    //CPQ22-5083 updated logic to populate Pricebook_Entry_Id__c field on Product2 object
                    if((prodVsPbeMap.get(prod.Id).Product2.Product_Level__c != null ||
                     (prodVsPbeMap.get(prod.Id).Product2.Product_Level__c == null && prodVsPbeMap.get(prod.Id).IsActive)) &&
                      prod.Pricebook_Entry_Id__c != prodVsPbeMap.get(prod.Id).Id){
                            prod.Pricebook_Entry_Id__c = prodVsPbeMap.get(prod.Id).Id;
                    }
                    else if(prodVsPbeMap.get(prod.Id).Product2.Product_Level__c == null && prodVsPbeMap.get(prod.Id).IsActive == false){
                        prod.Pricebook_Entry_Id__c = '';
                    }
                }       
            }                 
    }

    /**
     * @description Tracks changes to specified Product2 fields and creates Product_Field_Modification_History__c records for each modification.
     * @param newRecords List of updated Product2 records (after update).
     * @param oldRecordMap Map of Product2 records before update, keyed by Id.
     */
    //Added as part of GLCR-80 for Tracking Product Field Modification
    public static void onUpdateProductHistory(List<Product2> newRecords,Map<ID, Product2> oldRecordMap){
        
        final List<Schema.FieldSetMember> trackedFields = SObjectType.Product2.FieldSets.HistoryTracking.getFields();
        
        if (trackedFields.isEmpty()) {
            System.debug(LoggingLevel.INFO, 
                'No data found in Product2.FieldSets.HistoryTracking'
            );
            return;
        }
        
        final List<Product_Field_Modification_History__c> fieldChanges = new List<Product_Field_Modification_History__c>();
        
        for (Product2 newProd : newRecords) {
            final Product2 oldProd = oldRecordMap.get(
                newProd.Id
            );
            
            for (Schema.FieldSetMember fsm : trackedFields) {
                String fieldName = fsm.getFieldPath();
                String fieldLabel = fsm.getLabel();
                
                if (
                    newProd.get(fieldName) ==
                    oldProd.get(fieldName)
                ) {
                    continue;
                }
                String oldValue = String.valueOf(oldProd.get(fieldName));
                String newValue = String.valueOf(newProd.get(fieldName));
                
                if (oldValue != null && oldValue.length() > 255) {
                    oldValue = oldValue.substring(0, 255);
                }
                
                if (newValue != null && newValue.length() > 255) {
                    newValue = newValue.substring(0, 255);
                }
                
                final Product_Field_Modification_History__c productFieldHistory = new Product_Field_Modification_History__c();
                
                productFieldHistory.Field_Label__c = fieldLabel; 
                productFieldHistory.Api_Name__c = fieldName;
                productFieldHistory.Product__c = newProd.Id;
                productFieldHistory.OldValue__c = oldValue;
                productFieldHistory.NewValue__c = newValue;
                
                fieldChanges.add(productFieldHistory);
            }
        }
        
        if (!fieldChanges.isEmpty()) {
            if (Schema.sObjectType.Product_Field_Modification_History__c.isCreateable()) {
                insert fieldChanges;
            } else {
                System.debug(LoggingLevel.INFO, 'User does not have create access to Product_Field_Modification_History__c.');
            }
        }
        
    }
}