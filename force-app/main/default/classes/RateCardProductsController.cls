/**
* @File Name : RateCardProductsController.cls
* @description : Used to handle the Rate Card Products data for custom App and MSP PayGo ORder Confirmation notification
* @Test Class : RateCardProductsController_Test.cls
* @Author : Shailesh Kumar
* @Modification Log :
********************Change Logs ********************************************
* User Story            Modified By          Date               Description
* CS21-3905             Shailesh Kumar	     January 28,2026	Code for requirements added in jira
********************Change Logs Ends****************************************
**/
/**
* @description Used to handle Rate Card Products and Add Products to Template
* added without sharing as user was not able to delete the records of another user which is required for this ticket
*/
public without sharing class RateCardProductsController{
    /**
    * @description orderId
    */
    public Id ordId { get; set; }
    
    /**
    * @description : Get List of Rate Card Products
    * @return  List of Rate Card Products in a Sorting order
    */
    @AuraEnabled(cacheable=true)
    public static List<Rate_Card_Product__c> getProducts() {

        String sortDirection = 'asc';

        // Read stored sort order (global preference)
        List<Rate_Card_Product__c> cfg = [
            SELECT Sort_Order__c
            FROM Rate_Card_Product__c
            WHERE Sort_Order__c != NULL
            LIMIT 1
        ];

        if (!cfg.isEmpty() && cfg[0].Sort_Order__c == 'desc') {
            sortDirection = 'desc';
        }

        String soql = String.escapeSingleQuotes('SELECT Id, Product_Name__c, Product_Description__c, Sort_Order__c FROM Rate_Card_Product__c ORDER BY Product_Name__c ') + String.escapeSingleQuotes(sortDirection);
        return Database.query(soql);
    }
    
    /**
	* @description  Add a new Rate Card Product Record from the custom App.
    * @param  productId
    * @param  sortOrder
    * @return RateCardObject
    */
    @AuraEnabled
    public static ProductWrapper addRateCardProduct(String productId, String sortOrder) {
        ProductWrapper prodWrap = new ProductWrapper();
        prodWrap.isDuplicate = false;
        Product2 prodRec = [SELECT Id, Name, Description FROM Product2 WHERE Id=:productId];
        List<Rate_Card_Product__c> existingRec = [SELECT Id, Product_Name__c, Product_Description__c FROM Rate_Card_Product__c WHERE Product_Name__c =:prodRec.Name LIMIT 1];
        if(!existingRec.isEmpty()){
            prodWrap.isDuplicate = existingRec[0].Product_Name__c == prodRec.Name ? true : false;
        }else{
            Rate_Card_Product__c rateCardObj = new Rate_Card_Product__c();
            rateCardObj.Product_Name__c = prodRec.Name;
            rateCardObj.Product_Description__c = prodRec.Description;
            rateCardObj.Sort_Order__c = sortOrder;
            insert rateCardObj;
            prodWrap.recId = rateCardObj.Id;
        }
        return prodWrap;
    }

    /**
    * @description  Save Inline Edit made on Rate Card Product record using custom App( Manage Rate Card Products)
    * @param  products
    */
    @AuraEnabled
    public static void saveProducts(List<Rate_Card_Product__c> products) {
        if (products == null || products.isEmpty()) return;
        update products;
    }

    /**
	* @description  Delete the Rate Card Products
    * @param  productIds
    */
    @AuraEnabled
    public static void deleteProducts(List<Id> productIds) {
        if (productIds == null || productIds.isEmpty()) return;

        delete [
            SELECT Id
            FROM Rate_Card_Product__c
            WHERE Id IN :productIds
        ];
    }

    /**
	* @description  Update sort direction as we need the same sorting order in the Email Template
    * @param  sortDirection
    */
    @AuraEnabled
    public static void updateSortOrder(String sortDirection) {

        if (sortDirection != 'asc' && sortDirection != 'desc') return;

        List<Rate_Card_Product__c> records = [
            SELECT Id, Sort_Order__c
            FROM Rate_Card_Product__c
        ];

        for (Rate_Card_Product__c r : records) {
            r.Sort_Order__c = sortDirection;
        }

        if (!records.isEmpty()) {
            update records;
        }
    }

    /**
	* @description  Wrapper for Add Rate Card Product result
    */
    public class ProductWrapper{
        /**
        * @description  To store record id if record is added
        */
        @AuraEnabled public String recId {get;set;}
        /**
        * @description  To check if record is dupicate or not
        */
        @AuraEnabled public Boolean isDuplicate {get;set;}
    }
}