public with sharing class EntitlementsWithMissingAssestCtrl {
  

    public EntitlementsWithMissingAssestCtrl() {

    }
    @AuraEnabled
    public static List<Entitlement> getEntitlemetsWithMissingAssets(){
        System.debug('Invoked This Method');
        List<String> lstProdsExclude = Order_control__mdt.getInstance('Exclude_Products').Value__c.split(',');
        List<String> lstAccountsExclude = Order_control__mdt.getInstance('Exclude_Accounts').Value__c.split(',');

        String productName = Label.Product_Name_for_Report.deleteWhitespace();
        List<String> lstProductName = productName.split(',');

        //try {
            List<Entitlement> lstEntitlemets = [SELECT CreatedDate, Id, Name, Order_Service_Item__r.OrderItemNumber, Order_Service_Item__c, 
            StartDate, EndDate, Order_Service_Item__r.Order.OrderNumber,   Order_Service_Item__r.OrderId, 
             Order_Service_Item__r.Order.ProcessType__c, Order_Service_Item__r.Order.SD_Status__c, Notes__c 
            FROM  Entitlement 
            WHERE AssetId = null AND Product__r.Product_Type__c != 'Training' AND Entitlement_Status__c NOT IN ('Expired', 'Terminated')
            AND (NOT Notes__c LIKE '%reviewed by installed base%') 
            AND(
                (   
                    Order_Service_Item__r.Order.Is_RWD_Polaris_Quote__c = false
                    AND(
                        (   Product__r.Category__c ='Support' 
                            OR Product__r.Product_Subtype__c IN ('GO','Rubrik Promo','Saas Cloud') 
                            OR Product__r.Product_Type__c ='NFR'
                        )
                        OR(
                            Product__r.Product_Level__c = 'Hybrid Software'
                            AND (Product__r.Product_Subtype__c = 'SaaS Cloud' OR Product__r.Product_Type__c IN ('Complete','Complete Elite','Complete Pro') 
                                OR Product__r.Family = 'Third Party License')
                        )
                        OR(
                            Product__r.Product_Level__c = 'On Prem' AND  Product__r.Product_Type__c IN ('Foundation Edition','Business Edition','Enterprise Edition')
                        ) 
                        OR Product__r.Product_Level__c = 'LOD Software'
                    )
                )
                OR(
                    Order_Service_Item__r.Order.Is_RWD_Polaris_Quote__c = true 
                    AND(
                        (Product__r.Product_Type__c  = 'HW Support' AND Product__r.Product_Level__c = 'Support')
                        OR  
                        (Product__r.Product_Type__c  = 'RCDM Support' AND Product__r.Product_Level__c = 'Support')
                    )
                )
            ) 
            AND Name NOT IN : lstProductName
            AND Order_Service_Item__r.Order.Type != 'POC' 
            AND (NOT(Product__r.Product_Type__c  = 'NFR' AND Product__r.Product_Subtype__c  = 'RCDM' )) 
            AND (Product__r.Family not in ('CEM', 'Dell', 'HPE', 'UCS','ASE'))
            AND Product__r.Id NOT IN :lstProdsExclude
            AND AccountId NOT IN :lstAccountsExclude
            AND (Order_Service_Item__r.Required_by_Product_Code__c  != null   
            AND 
            (   Order_Service_Item__r.SBQQ__QuoteLine__r.Required_By_Product_Code__c != null 
                OR 
                (   Order_Service_Item__r.SBQQ__QuoteLine__r.Required_By_Product_Code__c = null 
                    AND
                    (
                        Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__ProductOption__r.SBQQ__ConfiguredSKU__r.Product_Type__c != 'Add-On Node' 
                        OR Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__ProductOption__r.SBQQ__ConfiguredSKU__r.Appliance_Model__c = null
                        OR Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__ProductOption__r.SBQQ__ConfiguredSKU__r.Item_Type__c = 'Serialized Inventory Item'
                    )
                )
            )    
        )
        ORDER BY CreatedDate desc];
        System.debug('lstEntitlemets :::>'+lstEntitlemets);
        return lstEntitlemets;
        /*} catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }*/
    }
}