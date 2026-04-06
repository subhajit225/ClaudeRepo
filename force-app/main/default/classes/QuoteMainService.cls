public  class QuoteMainService {

  public static void actionOnOppty(Set<id> oppIdSet) 
  {

    if(Test_Controls__c.getInstance() != null && Test_Controls__c.getInstance().Bypass_Pricebook_Setting_on_Opp__c == true) {
        return;
    }

     try{
     List<Opportunity> oppListToBeUpdated = new List<Opportunity>();
     List<OpportunityLineItem> oppProdToBeDeleted = new List<OpportunityLineItem >();
      if(!oppIdSet.isEmpty()){
        for(Opportunity opp : [select id,name, pricebook2Id,(select id,name from OpportunityLineItems) from opportunity where Id IN: oppIdSet]){
            system.debug('opp'+opp.OpportunityLineItems);
            system.debug('opp'+opp);
            if(opp.Pricebook2Id != System.Label.CPQ_PriceBook_Id){
                oppProdToBeDeleted.addAll(opp.OpportunityLineItems);
                opp.Pricebook2Id = System.Label.CPQ_PriceBook_Id;
                opp.SBQQ__QuotePricebookId__c = System.Label.CPQ_PriceBook_Id;
                oppListToBeUpdated.add(opp);
            }
        }
    }
    system.debug('oppProdToBeDeleted'+oppProdToBeDeleted);
    system.debug('oppListToBeUpdated'+oppListToBeUpdated);
    if(!oppProdToBeDeleted.isEmpty())
        delete oppProdToBeDeleted;
        
    if(!oppListToBeUpdated.isEmpty())
        update oppListToBeUpdated;
        
    system.debug('oppProdToBeDeleted'+oppProdToBeDeleted);
    system.debug('oppListToBeUpdated'+oppListToBeUpdated);
    }
    catch(Exception ex){
        system.debug('Error occured in QuoteMain Trigger'+ex);
    }
    
  }
}