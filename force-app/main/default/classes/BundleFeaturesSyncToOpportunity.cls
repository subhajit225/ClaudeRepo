/**
* @description Batch job to sync Bundle features change on product to be updated to 
*
* @CreatedDate 17th Feb 2022
* @Created By Veera Gandi
* 
* @Test Class BundleFeaturesSyncToOpportunityTest
*/
public class BundleFeaturesSyncToOpportunity implements Database.Batchable<sObject>, Database.stateful, Schedulable {
    public String query;
    public Set<Id> opportunitiesAlreadyProcessed;
    public Set<Id> productIds;
    
    /**
    * @description Constructor 
    */
    public BundleFeaturesSyncToOpportunity(){
        this(true);
    }
    
    /**
    * @description Constructor to get batch job query to be executed in start method.
    */
    public BundleFeaturesSyncToOpportunity(Boolean syncUpdatedProducts){ 
        this.productIds = new Set<Id>(); 
        this.opportunitiesAlreadyProcessed = new Set<Id>();
        
        for (Product2 eachProduct: [SELECT Id FROM Product2 WHERE IsBundleFeaturesUpdated__c = true]) {
            productIds.add(eachProduct.Id);
        }
        
        this.query = 'SELECT Id, OpportunityId FROM OpportunityLineItem WHERE'; 
        //Boolean used to bypass the products for running one time job to sync opportunities
        if (syncUpdatedProducts) {
            this.query += ' Product2Id IN :ProductIds AND';
        }        
        this.query += ' Opportunity.StageName IN (\'4 Business Justification\', \'5 Negotiate & Close\', \'6 PO With Channel\')';

        if (Test.isRunningTest()) {
            this.query += ' LIMIT 1';
        }
    }
    
    /**
    * @description start method runs at the beginning of a batch Apex job which collects the records or objects to pass to the execute method. 
    * @param  BatchableContext - Database.BatchableContext
    * @return Database.QueryLocator - List of Accounts
    */
    public Database.QueryLocator start(Database.BatchableContext batchableContext){
        return Database.getQueryLocator(query);
    }
    
    /**
    * @description execute method is called for each batch of records that you pass to it
    * @param  BatchableContext - Database.BatchableContext
    * @param  accounts - List of Accounts
    * @return void
    */
    public void execute(Database.BatchableContext batchableContext, List<OpportunityLineItem> opportunityProducts){
        Set<Id> productIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        List<Opportunity> opportunities = new List<Opportunity>();
                

        //collecting Opportunities where Opportunity is in Stage 4,5 or 6 and Bundle feature is updated and is associated to OLI
        for(OpportunityLineItem eachLineItem : opportunityProducts) {
            if (!opportunitiesAlreadyProcessed.contains(eachLineItem.OpportunityId)) {
                opportunityIds.add(eachLineItem.OpportunityId); 
            }
        }
        
        //If Opportunities are available
        if (!opportunityIds.isEmpty()) {
            for (Opportunity eachOpportunity : [SELECT Id, BundleFeatures__c, 
                                                (SELECT Id, Product2.Bundle_Features__c FROM OpportunityLineItems)
                                                FROM Opportunity WHERE Id IN :opportunityIds]) 
            {
                List<String> bundleFeatures;
                Set<String> uniqueFeatures = new Set<String>();
                
                for (OpportunityLineItem eachLineItem : eachOpportunity.OpportunityLineItems) {
                    if (eachLineItem.Product2.Bundle_Features__c != null) {
                        bundleFeatures = eachLineItem.Product2.Bundle_Features__c.split(';');//add all features
                        uniqueFeatures.addALL(bundleFeatures); // adding to set to get unique values
                    }
                }
                
                if (bundleFeatures != null) {
                    bundleFeatures.clear(); // clearing the earlier list to reuse
                    bundleFeatures.addAll(uniqueFeatures);
                    String bundleFeature = string.join(bundleFeatures, ';'); //converting unique bundle features to string
                    Integer bundleFeatureLength = Integer.valueOf(Label.BundleFeaturesLength); // to make sure length of the value doesn't exceed the field length
                    eachOpportunity.BundleFeatures__c = bundleFeature.length() > bundleFeatureLength ? bundleFeature.substring(0, bundleFeatureLength): bundleFeature;
                } else {
                    eachOpportunity.BundleFeatures__c = '';
                }
                
                Opportunities.add(eachOpportunity);
                opportunitiesAlreadyProcessed.add(eachOpportunity.Id);
            }
        }
        
        if(!Opportunities.isEmpty()){
            List<Database.SaveResult> results = Database.update(opportunities, false);
            
            for (Database.SaveResult result : results) {
                if (!result.isSuccess()) {
                    System.debug(LoggingLevel.ERROR, 'Error Occured :: '+ JSON.serialize(result.getErrors())); 
                }
            }
        }
    }
    
    /**
    * @description finish is to execute post-processing operations
    * @param  batchableContext - Database.BatchableContext
    * @return void
    */
    public void finish(Database.BatchableContext batchableContext){
        List<Product2> products = new List<Product2>();
        
        for (Product2 eachProduct: [SELECT Id FROM Product2 WHERE IsBundleFeaturesUpdated__c = true]) {
            eachProduct.IsBundleFeaturesUpdated__c = false;
            products.add(eachProduct);
        }
        
        List<Database.SaveResult> results = Database.update(products, false);
        
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                System.debug(LoggingLevel.ERROR, 'Error Occured :: '+ JSON.serialize(result.getErrors())); 
            }
        }  
    }
    
    /**
    * @description execute method to schedule the batch job
    * @param  SchedulableContext
    * @return void
    */
    public void execute(SchedulableContext sc) {
        BundleFeaturesSyncToOpportunity syncBundleFeatures = new BundleFeaturesSyncToOpportunity();
        Database.executeBatch(syncBundleFeatures, 200);
    }
    
}