global class Entititlement_Price_Update_Batch implements Database.Batchable<sObject>, Database.stateful{
    
    public Set<Opportunity> processedEntitlements = new Set<Opportunity>();
    global Database.QueryLocator start(Database.BatchableContext BC){ //and OpportunityId = \'006S0000009yFdQ\' ,Order_Service_Item__r.Product2Id
     //FOR TEST PURPOSE ONLY
        /*string entl='02i4000000Pszb9';
        string whereClause = ' AssetId = \'' + entl + '\' ';
        String query = 'select id , Product__c,AssetId, EndDate,Renewable__c  from Entitlement where '+whereClause + (Test.isRunningTest()?' LIMIT 20':'');
        return Database.getQueryLocator(query);
       */
       
        String query = 'select id , Product__c,Product__r.Category__c,Product__r.ProductCode,AssetId, EndDate,Renewable__c,Order_Quantity__c  from Entitlement '+ (Test.isRunningTest()?' LIMIT 20':'');
        return Database.getQueryLocator(query);
    }
    // Execute Metjod to perform Logic on Batch
    global void execute(Database.BatchableContext BC, List<Entitlement> scope){
        Map<Id,Decimal> mapProductPrice = new Map<Id,Decimal>();
        Set<ID> productList = new Set<Id>();
        List<Entitlement> entitlementsToBeUpdated = new List<Entitlement>();
        for(Entitlement etl : scope){
          
          productList.add(etl.Product__c);
        }
        productList.remove(null);
        system.debug('productList=='+productList);
        for(PricebookEntry pbe : [SELECT Id, Product2Id,ProductCode, unitPrice 
                                             FROM PricebookEntry WHERE Product2Id in: productList AND Pricebook2.Name =:System.Label.Active_Price_Book ]){
            mapProductPrice.put(pbe.Product2Id,pbe.UnitPrice);
        }
        system.debug('mapProductPrice Size()==='+mapProductPrice.size()+'==Values ==='+mapProductPrice);
        for(Entitlement etl : scope){
          etl.PB_List_Price__c = mapProductPrice.get(etl.Product__c);
          system.debug('System.Label.Discount =='+System.Label.Discount);
          if( etl.Order_Quantity__c != null && (etl.Product__r.Category__c =='Subscription' || etl.Product__r.ProductCode.endsWith('-MO')))
          etl.Calculated_List_Price__c = mapProductPrice.get(etl.Product__c)!= null? ((mapProductPrice.get(etl.Product__c)*Integer.valueOf(System.Label.Discount))/100 * etl.Order_Quantity__c) : null;
          else {
              etl.Calculated_List_Price__c = mapProductPrice.get(etl.Product__c)!= null?((mapProductPrice.get(etl.Product__c)*Integer.valueOf(System.Label.Discount))/100) : null;
          }
          entitlementsToBeUpdated.add(etl);
        }
        system.debug('entitlementsToBeUpdated=='+entitlementsToBeUpdated);
        
        Database.update(entitlementsToBeUpdated,false);
      }
      global void finish(Database.BatchableContext processOpptys) {
      }
}