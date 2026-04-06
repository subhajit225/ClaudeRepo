public with sharing class MissingEntitlementsController {
  public List<OrderItem> orderItems {get;set;}
  public List<OrderItem> missingContractOrderItems {get;set;}
  public MissingEntitlementsController() {
  String QueryMissingEntitlements;
  String QueryMissingContracts;
  List<StoreSOQLQuery__mdt> QueryRecord = new List <StoreSOQLQuery__mdt>();
  QueryRecord=[Select Id,label,Query__c from StoreSOQLQuery__mdt where label IN ('RetriveMissingContracts','RetriveMissingEntitlementsQuery')];
   
   if(QueryRecord.size()> 0){
   for(StoreSOQLQuery__mdt queryData:QueryRecord){
       if(queryData.label=='RetriveMissingEntitlementsQuery' && queryData.Query__c != NULL )
       {
        QueryMissingEntitlements = queryData.Query__c.trim();
       }
       else if(queryData.label=='RetriveMissingContracts'&& queryData.Query__c != NULL)
       {
       QueryMissingContracts = queryData.Query__c.trim();
       }
   }
   }
    orderItems = Database.query(QueryMissingEntitlements);
    missingContractOrderItems =Database.query(QueryMissingContracts);
    
  }
}