public class UpgradeSourceHelper{


    public static void AfterUpgradeSourceUpdate(Map<ID, Custom_Upgrade_Source__c> oldMap, Map<ID, Custom_Upgrade_Source__c> newMap){
     
    }
    public static void AfterUpgradeSourceinsert(Map<ID, Custom_Upgrade_Source__c> newMap){
            goRefreshMinquantityUpdate(null,newMap);
    }
    
    public static void AfterUpgradeSourceDelete(Map<ID, Custom_Upgrade_Source__c> oldMap){
        goRefreshDeactivateProductIfDeleted(oldMap);
    }
    
    public static void goRefreshMinquantityUpdate(Map<ID, Custom_Upgrade_Source__c> oldMap, Map<ID, Custom_Upgrade_Source__c>newMap){
        
        List<Product2> ProductList = new List<Product2>();
        List<Id> ProductIdList = new List<Id>();
        system.debug('i am newMap'+newMap);
        system.debug('i am oldMap'+oldMap);
        
        for(Custom_Upgrade_Source__c UpgSrc: newMap.values()){
            if(UpgSrc.UpgradeProduct__c != null && (Trigger.isInsert || Trigger.isUpdate)){
                ProductIdList.add(UpgSrc.UpgradeProduct__c);
            }
        }
    

       
        for(Product2 Prod : [select id,Is_Refresh_Product_MinQnty__c,Is_Eligible_for_Refreshed__c,Productcode from product2 where id IN : ProductIdList]){
            system.debug('i am here');
            if(Prod.Is_Refresh_Product_MinQnty__c != null && Prod.Is_Eligible_for_Refreshed__c == false){
                Prod.Is_Eligible_for_Refreshed__c = true;
                ProductList.add(Prod);
            }
        }

        
        if(!ProductList.isEmpty()){
            update ProductList;
        }
        
    }
    public static void goRefreshDeactivateProductIfDeleted(Map<ID, Custom_Upgrade_Source__c> oldMap){
        List<Id> ProductIdList = new List<Id>();
        List<Product2> ProductList = new List<Product2>();
        List<Id> UpgradeSourceIdList = new List<Id>();
        for(Custom_Upgrade_Source__c UpgSrc: oldMap.values()){
            if(UpgSrc.UpgradeProduct__c != null && Trigger.isDelete){
                ProductIdList.add(UpgSrc.UpgradeProduct__c);
                UpgradeSourceIdList.add(UpgSrc.id);
            }
        }
        for(Product2 Prod : [select id,Is_Refresh_Product_MinQnty__c,Is_Eligible_for_Refreshed__c,Productcode,(select id from UpgradeSources__r where id NOT IN : UpgradeSourceIdList) from product2 where id IN : ProductIdList]){
            if(!Prod.UpgradeSources__r.isEmpty()){
                // do not update anything
            }else{
                Prod.Is_Refresh_Product_MinQnty__c = '';
                Prod.Is_Eligible_for_Refreshed__c = false;
                Prod.Refresh_Credit_Amount__c = null;
                ProductList.add(Prod);
            }
        }
        
        if(!ProductList.isEmpty()){
            update ProductList;
        }
    }
}