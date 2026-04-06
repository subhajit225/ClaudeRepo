public with sharing class AssetTriggerHelper {
    
    private static Map<Id, OrderItem> orderItemMap= new Map<Id, OrderItem>();
    private static Map<Id, Account> accountMap = new Map<Id, Account>();
    private static Map<Id, Product2> productMap = new Map<Id, Product2>();
    private static final String ACCOUNT_UNASSIGNED = 'Unassigned';
    private static boolean allowAssetOIUpdates = false;
    private static boolean allowSupportStartDateUpdate = false;
    public static boolean isUpdatedFromSystem = false ;
    public static boolean allowUpdateAsset = false; //to allow update the fields on Asset through Trigger
  private static final String ORDER_ITEM = 'OrderItem';
    
    public static void setFieldsOnAssetInsert (List<Asset> assetList) {
        
        populateRelationMaps(assetList,null); 
        
        Id pocOrderRecordId = (Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order') != null)
            ? Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId()
            : null;
        
        for(Asset newAsset : assetList) {
            if(newAsset.Order_Service_Item__c != null) {
                
                OrderItem vOrderItem = orderItemMap.get(newAsset.Order_Service_Item__c);
                
                if(vOrderItem.Order.ShippingCity != null && newAsset.Location__c == null) {
                    newAsset.Location__c = vOrderItem.Order.ShippingCity;
                }
                
                if(newAsset.Quantity == null) 
                {
                    newAsset.Quantity = 1;
                }
                
                if(newAsset.AccountId != vOrderItem.Order.AccountId) {
                    newAsset.AccountId = vOrderItem.Order.AccountId;
                }
                
                if(vOrderItem.Order.RecordTypeId == pocOrderRecordId && newAsset.Order_Service_Item__c != null) {
                    
                    if(vOrderItem.Order.RecordTypeId != null) {
                        newAsset.Status = getAssetStatus(vOrderItem.Order.POC_Request__r.POC_Type__c);
                    }
                    newAsset.POO_Ship_Date__c = vOrderItem.Order.Actual_Order_Ship_Date__c;
                    newAsset.InstallDate = vOrderItem.Order.Actual_Order_Ship_Date__c;
                    
                    if(vOrderItem.Support_Start_Date__c != null) {
                        newAsset.Support_Start_Date__c = vOrderItem.Support_Start_Date__c;
                    }
                    
                    if(vOrderItem.Support_End_Date__c != null) {
                        newAsset.Premium_Support_End_Date__c = vOrderItem.Support_End_Date__c;
                    }
                    
                }
            }
        }
    }
    public static void preventCombineKeyOverride (List<Asset> newAssets,Map<Id,Asset> oldAssetsById) {
        for(Asset newAsset : newAssets) {
            Asset oldAsset = oldAssetsById.get(newAsset.Id);
            Id newCombineKey = (Id)newAsset.SBQQ__CombineKey__c;
            Id oldCombineKey = (Id)oldAsset.SBQQ__CombineKey__c;
            if (
              String.isNotBlank(newCombineKey) 
              && newCombineKey.getSObjectType().getDescribe().getName() != ORDER_ITEM 
              && oldCombineKey.getSObjectType().getDescribe().getName() == ORDER_ITEM
            ) {
                newAsset.SBQQ__CombineKey__c = oldAsset.SBQQ__CombineKey__c;
            }  
        }
    }
    public static void setFieldsOnAssetUpdate(List<Asset> assetList, Map<Id, Asset> oldAssetMap) {
        
        populateRelationMaps(assetList, oldAssetMap);
        
        Id pocOrderRecordId = (Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order') != null)
            ? Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId()
            : null;
        
        for(Asset newAsset : assetList) {
            Asset oldAsset = (oldAssetMap != null) ? oldAssetMap.get(newAsset.Id) : null;
            
            if(newAsset.Order_Service_Item__c != oldAsset.Order_Service_Item__c && oldAsset.Order_Service_Item__c == null) {
                   
                   OrderItem vOrderItem = orderItemMap.get(newAsset.Order_Service_Item__c);
                   
                   if(vOrderItem.Order.ShippingCity != null && (oldAsset.Location__c == null || newAsset.Location__c == null)) {
                       newAsset.Location__c = vOrderItem.Order.ShippingCity;
                   }
                   
                   if(newAsset.Quantity == null) {
                       newAsset.Quantity = 1;
                   }
                   
                   if(newAsset.AccountId == null && newAsset.AccountId != vOrderItem.Order.AccountId) {
                       newAsset.AccountId = vOrderItem.Order.AccountId;
                   }
                   
                   if(newAsset.SBQQ__QuoteLine__c == null && vOrderItem.SBQQ__QuoteLine__c != null) {
                       newAsset.SBQQ__QuoteLine__c = vOrderItem.SBQQ__QuoteLine__c;
                       
                       //EL-300
                       newAsset.Licensing_Model__c = vOrderItem.SBQQ__QuoteLine__r.Licensing_Model__c;
                       newAsset.Rubrik_Suite__c = vOrderItem.SBQQ__QuoteLine__r.Rubrik_Suite__c;
                       newAsset.Support_Type__c = vOrderItem.SBQQ__QuoteLine__r.Support_Type__c;
                       newAsset.Payment_Options__c = vOrderItem.SBQQ__QuoteLine__r.Payment_Options__c;
                   }
                   
                   if(vOrderItem.Order.RecordTypeId == pocOrderRecordId && newAsset.Order_Service_Item__c != oldAsset.Order_Service_Item__c) {
                       
                       if(vOrderItem.Order.RecordTypeId != null) {
                           newAsset.Status = getAssetStatus(vOrderItem.Order.POC_Request__r.POC_Type__c);
                       }
                       newAsset.POO_Ship_Date__c = vOrderItem.Order.Actual_Order_Ship_Date__c;
                       newAsset.InstallDate = vOrderItem.Order.Actual_Order_Ship_Date__c;
                       
                       if(vOrderItem.Support_Start_Date__c != null) {
                           newAsset.Support_Start_Date__c = vOrderItem.Support_Start_Date__c;
                       }
                       
                       if(vOrderItem.Support_End_Date__c != null) {
                           newAsset.Premium_Support_End_Date__c = vOrderItem.Support_End_Date__c;
                       }
                       
                }
            }
            if (newAsset.AccountId != null && accountMap.get(newAsset.AccountId)!= Null && accountMap.get(newAsset.AccountId).Name !=ACCOUNT_UNASSIGNED && 
                    newAsset.SBQQ__Number__c == Null){
                    newAsset.SBQQ__Number__c = 1;
                }
        }
        preventChangeFields(assetList, oldAssetMap, accountMap, productMap);
    }
    
    public static void allowAssetOIUpdates(boolean value){
        allowAssetOIUpdates = value;
    }
    
    public static void allowUpdateAsset(boolean value){
        allowUpdateAsset = value;
    }

    public static void allowSupportStartDateUpdate(boolean value){
        allowSupportStartDateUpdate = value;
    }
    
    public static void preventChangeFields(List<Asset> assetsToUpdate) {
        preventChangeFields(assetsToUpdate, null, null, null);
    }
    public static Set<Id> bypassProductUpdate = new Set<Id>();
    
    public static void preventChangeFields(List<Asset> assetsToUpdate, Map<Id, Asset> oldAssetMapIn, Map<Id, Account> accountMapIn, Map<Id, Product2> productMapIn) {
        //List<Asset> result = new List<Asset>();
        
        Map<Id, Asset> oldAssetMap = (oldAssetMapIn == null) ? new Map<Id, Asset>() : oldAssetMapIn;
        Map<Id, Account> accountMap = (accountMapIn == null) ? new Map<Id, Account>() : accountMapIn;
        Map<Id, Product2> productMap = (productMapIn == null) ? new Map<Id, Product2>() : productMapIn;
        
        Map<Id, Asset> assets = new Map<Id, Asset>(assetsToUpdate);
        Set<Id> assetIds = (assets != null && !assets.isEmpty()) ? assets.keySet() : new Set<Id>();
        
        if(oldAssetMapIn == null && !assetIds.isEmpty()) {
            Set<Id> productIds = new Set<Id>();
            for(Asset ast : assetsToUpdate) {
                productIds.add(ast.Product2Id);
            }
            productIds.remove(null);
            if(!productIds.isEmpty()) {
                List<Product2> qProducts = [SELECT Id, Asset_Upgrade_Product__c FROM Product2 WHERE Id IN :productIds];
                for(Product2 pr : qProducts) {
                    productMap.put(pr.Id, pr);
                }
            }
            Set<String> fields = new Set<String>(getFieldsToRevertChnages());
            fields.add('Id');
            fields.add('AccountId');
            fields.add('Account.Name');
            fields.add('Product2Id');
            fields.add('Product2.Asset_Upgrade_Product__c');
            fields.add('Bypass_Account_and_Product_Update__c');
            fields.add('Order_Service_Item__c');
            fields.add('Product_Code_Custom__c');
            fields.add('Order_Service_Item__r.Order.Type');
            fields.add('Program__c');    
            fields.add('UsageEndDate');
            
            String query = 'SELECT ' + String.escapeSingleQuotes(String.join(new List<String>(fields), ',')) + ' FROM Asset WHERE Id IN :assetIds';
            List<Asset> qAssets = Database.query(query);
            
            oldAssetMap = new Map<Id, Asset>(qAssets);
            
            for(Id assetId : oldAssetMap.keySet()) {
                Id accountId = oldAssetMap.get(assetId).AccountId;
                String accountName = oldAssetMap.get(assetId).Account.Name;
                Id productId = oldAssetMap.get(assetId).Product2Id;
                Id upgradeProductId = oldAssetMap.get(assetId).Product2.Asset_Upgrade_Product__c;
                
                if(accountId != null) {
                    accountMap.put(accountId, new Account(Id = accountId, Name = accountName));
                }
                if(productId != null) {
                    productMap.put(productId, new Product2(Id = productId, Asset_Upgrade_Product__c = upgradeProductId));
                }
            }
        }
        
        
        for(Asset newAsset : assetsToUpdate) {
            
            Asset oldAsset = (oldAssetMap != null) ? oldAssetMap.get(newAsset.Id) : null;
            System.debug('---newAsset--'+json.serialize(newAsset));
            System.debug('---oldAsset--'+json.serialize(oldAsset));
            
            OrderItem vOrderItemNew = orderItemMap.get(newAsset.Order_Service_Item__c);
            OrderItem vOrderItemOld = orderItemMap.get(oldAsset.Order_Service_Item__c);
            
            if(oldAsset != null && (
                (vOrderItemNew != null && vOrderItemNew.Order != null && vOrderItemNew.Order.Type == 'Revenue')
                || (vOrderItemOld != null && vOrderItemOld.Order != null && vOrderItemOld.Order.Type == 'Revenue') )) {
                    
                    boolean isXProduct = false;
                    boolean allowFieldChanges = false;
                    boolean allowProductUpgrade = false;
                    boolean allowBypassAccountProductUpdate = (newAsset.Bypass_Account_and_Product_Update__c == true || oldAsset.Bypass_Account_and_Product_Update__c);
                    
                    Account acc = accountMap.containsKey(oldAsset.AccountId) ? accountMap.get(oldAsset.AccountId) : null;
                    Product2 productFullOld = productMap.containsKey(oldAsset.Product2Id) ? productMap.get(oldAsset.Product2Id) : null;
                    Product2 productFull = productMap.containsKey(newAsset.Product2Id) ? productMap.get(newAsset.Product2Id) : null;
                    System.debug(LoggingLevel.ERROR, '---productFull--'+json.serialize(productFull));
                    
                    if(acc == null || (acc != null && acc.Name == ACCOUNT_UNASSIGNED) || allowUpdateAsset) {
                        allowFieldChanges = true;
                    }
                    
                    if(productFull != null && productFull.Asset_Upgrade_Product__c != null || productFullOld != null && productFullOld.Asset_Upgrade_Product__c != null) {
                        allowProductUpgrade = true;
                    }
                    
                    //Map<String, Object> values = oldAsset.getPopulatedFieldsAsMap();
                    isXProduct = (oldAsset.Product_Code_Custom__c != null && oldAsset.Product_Code_Custom__c.startsWith('X-'));
                    System.debug('---isXProduct--'+isXProduct);
                    System.debug('---oldAsset--'+json.serialize(oldAsset));
                    //System.debug('---values--'+json.serialize(values));
                    
                    // prevent change order product detail
                    if(!allowAssetOIUpdates){
                        if(newAsset.Order_Service_Item__c != oldAsset.Order_Service_Item__c
                           && oldAsset.Order_Service_Item__c != null
                           && newAsset.Order_Service_Item__c != null) {
                               
                               newAsset.Order_Service_Item__c = oldAsset.Order_Service_Item__c;
                           }
                    }
                    
                    if(newAsset.Product2Id != oldAsset.Product2Id) {
                        // revert changes
                        if(!bypassProductUpdate.contains(newAsset.Id)
                           && !allowBypassAccountProductUpdate
                           && !isXProduct
                           && ((oldAsset.Product2Id != null && !allowFieldChanges) || (!allowFieldChanges && !allowProductUpgrade))) {
                               newAsset.Product2Id = oldAsset.Product2Id;
                               System.debug('---revert changes--246');
                           }
                        
                        if(allowProductUpgrade && !allowFieldChanges) {
                            newAsset.Product2Id = (productFull.Asset_Upgrade_Product__c != null) ? productFull.Asset_Upgrade_Product__c : newAsset.Product2Id;
                            System.debug('---upgrade product--251');
                            bypassProductUpdate.add(newAsset.Id);
                        }
                    }
                    //YSTONE-99
                    if(oldAsset.Program__c == 'Refreshed' && newAsset.UsageEndDate != oldAsset.UsageEndDate){
                        newAsset.UsageEndDate = oldAsset.UsageEndDate;
                    } 
                    for(String field : getFieldsToRevertChnages()) {
                        try{
                            if(newAsset.get(field) != null && oldAsset.get(field) != null
                               && newAsset.get(field) != oldAsset.get(field)
                               && oldAsset.get(field) != null
                               && !allowFieldChanges) {
                                   
                                   if('Status' == field && newAsset.get(field) != null && String.valueOf(newAsset.get(field)) == 'Dispatched') continue;
                                   //EL-219, Condition modified
                                   if('AccountId' == field && 
                                      (allowBypassAccountProductUpdate || 
                                       (String.valueOf(oldAsset.get('Status')) != 'Dispatched' &&
                                        String.valueOf(oldAsset.get('Status')) != 'Purchased' &&
                                        String.valueOf(oldAsset.get('Status')) != 'MSP'))) continue;
                                   
                                   if(field.equalsIgnoreCase('Support_Start_Date__c') && allowSupportStartDateUpdate){
                                       continue;
                                   }
                                   
                                   newAsset.put(field, oldAsset.get(field));
                               }
                        }
                        catch(Exception e){}
                    }
                }
        }
        if (oldAssetMapIn != null && !oldAssetMapIn.isEmpty()) {
            preventCombineKeyOverride(assetsToUpdate, oldAssetMapIn);
        }
    }
    
    private static List<String> getFieldsToRevertChnages() {
        List<String> result = new List<String>();
        
        Schema.FieldSet fieldSet = Schema.SObjectType.Asset.fieldSets.getMap().get('Fields_To_Revert_Changes');
        if (fieldSet != null) {
            for (Schema.FieldSetMember f : fieldSet.getFields()) {
                result.add(f.getFieldPath());
            }
        }
        return result;
    }
    
    private static void populateRelationMaps(List<Asset> assetList, Map<Id, Asset> oldAssetMap) {
        Set<Id> orderItemIdSet = new Set<Id>();
        Set<Id> checkAccounts = new Set<Id>();
        Set<Id> checkProducts = new Set<Id>();
        
        for(Asset asu : assetList) {
            Asset oldAsset = (oldAssetMap != null) ? oldAssetMap.get(asu.Id) : null;
            
            if(asu.Order_Service_Item__c != null) {
                orderItemIdSet.add(asu.Order_Service_Item__c);
            }
            
            if(oldAsset != null) {
                checkAccounts.add(asu.AccountId);
                checkAccounts.add(oldAsset.AccountId);
                checkProducts.add(oldAsset.Product2Id);
                checkProducts.add(asu.Product2Id);
            }
        }
        
        checkAccounts.remove(null);
        checkProducts.remove(null);
        
        if(!checkAccounts.isEmpty()) {
            accountMap = new Map<Id, Account>([SELECT Id, Name FROM Account WHERE Id IN :checkAccounts]);  
        }
        
        if(!checkProducts.isEmpty()) {
            productMap = new Map<Id, Product2>([SELECT Id, Asset_Upgrade_Product__c FROM Product2 WHERE Id IN :checkProducts]);
        }
        
        if(!orderItemIdSet.isEmpty()) {
            orderItemMap = new Map<Id, OrderItem>([
                SELECT Id, Order.Id, Order.ShippingCity,
                Order.RecordTypeId, Order.AccountId, Order.Actual_Order_Ship_Date__c,
                Support_Start_Date__c, Support_End_Date__c, SBQQ__QuoteLine__c,
                Order.POC_Request__r.POC_Type__c, SBQQ__QuoteLine__r.Licensing_Model__c,
                SBQQ__QuoteLine__r.Support_Type__c, SBQQ__QuoteLine__r.Rubrik_Suite__c, 
                SBQQ__QuoteLine__r.Payment_Options__c, Order.Type
                FROM OrderItem
                WHERE Id In:orderItemIdSet
            ]);
        }
    }
    
    private static String getAssetStatus(String pocType) {
        String assetStatus = null;
        assetStatus = (pocType != null && (pocType == 'Standard POC' ||  pocType == 'Standard POC : RSC-G')) ? 'POC' : assetStatus;
        assetStatus = (pocType != null && pocType == 'Conditional PO') ? 'Conditional' : assetStatus;
        assetStatus = (pocType != null && pocType == 'EA Test Unit') ? 'EA Test' : assetStatus;
        assetStatus = (pocType != null && pocType == 'Business Loaner Unit') ? 'Loaner' : assetStatus;
        assetStatus = (pocType != null && pocType == 'Support Loaner Unit') ? 'Loaner' : assetStatus;
        
        return assetStatus; 
    }
    
    public static void populatePOC(List<Asset> newAssets, Map<Id, Asset> oldAssets){
        Map<Id, List<Asset>> orderItemToAssets = new Map<Id, List<Asset>>();
        for(Asset asst: newAssets){
            if(asst.Order_Service_Item__c != null
               && (
                   oldAssets == null 
                   || asst.Order_Service_Item__c != oldAssets.get(asst.Id).Order_Service_Item__c
               )
              ){
                  if(orderItemToAssets.containsKey(asst.Order_Service_Item__c))
                      orderItemToAssets.get(asst.Order_Service_Item__c).add(asst);
                  else 
                      orderItemToAssets.put(asst.Order_Service_Item__c, new List<Asset>{asst});
              }
        }
        if(!orderItemToAssets.isEmpty()){
            Set<Id> orderproductIds = orderItemToAssets.keySet();
            Map<Id, POC__c> updatePOCs = new Map<Id, POC__c>();
            for(OrderItem oi : [SELECT Id, Order.POC_Request__c
                                FROM OrderItem 
                                WHERE Id IN :orderproductIds]){
                                    if(oi.Order.POC_Request__c != null){
                                        for(Asset asst : orderItemToAssets.get(oi.Id)){
                                            asst.POC_Request__c = oi.Order.POC_Request__c; 
                                            updatePOCs.put(asst.POC_Request__c, new POC__c(Id=asst.POC_Request__c, Has_Hardware__c= true));
                                        }
                                    }
                                }
            if(!updatePOCs.isEmpty())
                update updatePOCs.values();
        }
    }
    //PRDOPS25-734
    public static void  customValidationOnDeleteAsset(Map<Id, Asset> oldAssetMap) {
        system.debug('logic to prevent detetion');
         Boolean hasCustomPermission = FeatureManagement.checkPermission('Allow_Asset_Delete');
         for(Asset assetoRecord : oldAssetMap.values()){
                    system.debug(' hasCustomPermission is ##### ' + hasCustomPermission);
 
             if (!hasCustomPermission && !Test.isRunningTest()) {
                 assetoRecord.adderror('You are not authorized to delete this Asset data, hence please create support ticket with ProdOps Support or email "ProdOpsapps@rubrik.com" with details.');
             }
         }
     }
 }