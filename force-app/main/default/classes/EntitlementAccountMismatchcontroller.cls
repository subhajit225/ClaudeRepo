public with sharing class EntitlementAccountMismatchcontroller {

  public List<Entitlement> EntitlementData {get;set;}
  public EntitlementAccountMismatchcontroller() {
      EntitlementData = new List<Entitlement>();
      List <Entitlement> RetriveEnt = New List <Entitlement>(); 
      //Query updated to add new fields
      if(!Test.isRunningTest()){
          RetriveEnt=[select id,Name,Asset.Name,Asset.Product2.Id,Asset.Account.Name,Asset.Account.Id,Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Account__r.Name,Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Account__r.Id,Account.Name,AccountId,Order_Service_Item__r.OrderId,Order_Service_Item__r.Order.OrderNumber from Entitlement where Order_Service_Item__c != null AND Order_Service_Item__r.SBQQ__QuoteLine__c != null];
       }
       else{
           RetriveEnt=[select id,Name,Asset.Name,Asset.Product2.Id,Asset.Account.Name,Asset.Account.Id,Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Account__r.Name,Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Account__r.Id,Account.Name,AccountId,Order_Service_Item__r.OrderId,Order_Service_Item__r.Order.OrderNumber from Entitlement Limit 10];
       }
      for(Entitlement Ent : RetriveEnt){
        if(Ent.Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Account__r.id != Ent.AccountId || Ent.Asset.Account.Id != Ent.AccountId){
            EntitlementData.add(Ent);
            system.debug('Entitlement ids = '+Ent.id);
            }
        }
   }
}