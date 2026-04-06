trigger QuoteMain on SBQQ__Quote__c (after update, after insert) {
    //try{
    Set<Id> oppIdSet = new Set<Id>();
    
    
    for(SBQQ__Quote__c quote : Trigger.New){
      if(Trigger.isUpdate){
        SBQQ__Quote__c OldQuote = Trigger.OldMap.get(quote.Id);
        if(OldQuote.SBQQ__Primary__c!= quote.SBQQ__Primary__c && quote.SBQQ__Primary__c){
            oppIdSet.add(quote.SBQQ__Opportunity2__c );
        }
       }
       else if(Trigger.isInsert){
         if(quote.SBQQ__Primary__c){
            oppIdSet.add(quote.SBQQ__Opportunity2__c );
        }
       }
    }
    oppIdSet.remove(null);
    system.debug('oppIdSet'+oppIdSet);
    if(oppIdSet.size()>0)
        QuoteMainService.actionOnOppty(oppIdSet);
    //}
    //catch(Exception ex){
        
    //}    
}