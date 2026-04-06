public class QuoteTriggerHelperQueueable implements Queueable{
  Private Map<Id, SBQQ__Quote__c> qtList;
  Private Map<Id, SBQQ__Quote__c> qtOldMap;

  public quoteTriggerHelperQueueable (Map<Id, SBQQ__Quote__c> qtOldMap, Map<Id, SBQQ__Quote__c> qtList) {
        this.qtList = qtList;
        this.qtOldMap = qtOldMap;
    }
    public void execute (QueueableContext context){
    //CPQ22-47(SF-10672) - Start
    set<Id> allQuoteIDs = new set<Id>();
    set<Id> opportunityIDs = new set<Id>();
    Map<Id, String> dealDeskUpdatedQuoteWithNotes = new Map<Id, String>();
    Map<id,sbqq__quote__c> allQuotesMap;
    List<sbqq__quote__c> quotesToBeUpdatedWithDDNotes = new List<sbqq__quote__c>();
    List<Opportunity> oppsToBeUpdatedWithDDNotes = new List<Opportunity>();
Map<Id, SBQQ__Quote__c> opportunityToPrimaryQuoteMap = new Map<Id, SBQQ__Quote__c>();
    List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
 Map<String, Boolean> opportunityToNonPrimaryQuoteMap = new Map<String, Boolean>();
        
      for(SBQQ__Quote__c qt : qtList.values()) {
                SBQQ__Quote__c oldQt = qtOldMap.get(qt.Id);
               
                /*allQuoteIDs.add(qt.Id);
                system.debug('ashwini allQuoteIDs: '+allQuoteIDs);
                             
                if(qt.Deal_Desk_Notes__c != oldQt.Deal_Desk_Notes__c){
                    dealDeskUpdatedQuoteWithNotes.put(qt.Id, qt.Deal_Desk_Notes__c);
                    opportunityIDs.add(qt.SBQQ__Opportunity2__c);
                }
                system.debug('ashwini dealDeskUpdatedQuoteWithNotes: '+dealDeskUpdatedQuoteWithNotes);*/
                  /*if ((qt.SBQQ__Primary__c && (oldQt == null || !oldQt.SBQQ__Primary__c )  || (qt.Pricing_Notes__c != oldQT.Pricing_Notes__c))
                       &&  qt.Pricing_Notes__c != qt.SBQQ__Opportunity2__r.Deal_Desk_Notes__c) */
                  if((qt.SBQQ__Primary__c && (qt.Pricing_Notes__c != oldQT.Pricing_Notes__c)  ) ||  ( qt.SBQQ__Primary__c && !oldQt.SBQQ__Primary__c &&  qt.Pricing_Notes__c != null )     )
                  { 
                    system.debug('In first ');
        			opportunityToPrimaryQuoteMap.put(qt.SBQQ__Opportunity2__c, qt);
}
                  if(!qt.SBQQ__Primary__c && oldQt.SBQQ__Primary__c)
                  { 
                       system.debug('In Second' );
                    opportunityToPrimaryQuoteMap.put(qt.SBQQ__Opportunity2__c, qt); 
        			opportunityToNonPrimaryQuoteMap.put(qt.SBQQ__Opportunity2__c, true);
                   }
            System.debug(opportunityToPrimaryQuoteMap +'opportunityToPrimaryQuoteMap');
System.debug(opportunityToNonPrimaryQuoteMap +'opportunityToNonPrimaryQuoteMap');
          }  

          /*if(!allQuoteIDs.isEmpty()){
              allQuotesMap = new Map<id,sbqq__quote__c>([select id,Deal_Desk_Notes__c,SBQQ__Opportunity2__c,Pricing_Notes__c from sbqq__quote__c where SBQQ__Opportunity2__c in :opportunityIDs]);
          }
          system.debug('ashwini allQuotesMap: '+allQuotesMap);
          for(sbqq__quote__c quote : allQuotesMap.values()){
              if(!dealDeskUpdatedQuoteWithNotes.containsKey(quote.Id) && dealDeskUpdatedQuoteWithNotes.size()>0){
          String tempstring = String.ValueOf(dealDeskUpdatedQuoteWithNotes.values());
          tempstring = tempstring.removeStart('(');
          tempstring = tempstring.removeEnd(')');

          Opportunity oppty = new Opportunity();
                    oppty.Id = quote.SBQQ__Opportunity2__c;

                    if(tempstring != 'null'){
                      quote.Deal_Desk_Notes__c = tempstring;   
            oppty.Deal_Desk_Notes__c = tempstring;
                    } else {
                        quote.Deal_Desk_Notes__c = ''; 
            oppty.Deal_Desk_Notes__c = '';
                    }
          quotesToBeUpdatedWithDDNotes.add(quote);
                    if(!oppsToBeUpdatedWithDDNotes.contains(oppty)){
            oppsToBeUpdatedWithDDNotes.add(oppty);  
                    }
              }
      
              
      }
      system.debug('ashwini quotesToBeUpdatedWithDDNotes: '+quotesToBeUpdatedWithDDNotes);*/ 
        
      for (Id opportunityId : opportunityToPrimaryQuoteMap.keySet()) {
          System.debug(opportunitiesToUpdate +'Enter in For **');
            SBQQ__Quote__c primaryQuote = opportunityToPrimaryQuoteMap.get(opportunityId);
            Opportunity relatedOpportunity = new Opportunity(Id = opportunityId);
if(!opportunityToNonPrimaryQuoteMap.containskey(opportunityId))
            {
            relatedOpportunity.Deal_Desk_Notes__c = primaryQuote.Pricing_Notes__c;
}
          else
            {
              relatedOpportunity.Deal_Desk_Notes__c = null;
            }
            
          System.debug(relatedOpportunity.Deal_Desk_Notes__c +'relatedOpportunity.Deal_Desk_Notes__c');
            opportunitiesToUpdate.add(relatedOpportunity);
      }
       System.debug(opportunitiesToUpdate +'opportunitiesToUpdate');

      QuoteTriggerHandler.inRecursiveQueueableUpdate = true;
          if( opportunitiesToUpdate.size()>0){
             update opportunitiesToUpdate;
         }// CPQ22-3498
         /* if(quotesToBeUpdatedWithDDNotes.size()>0){
        update quotesToBeUpdatedWithDDNotes;
            }
      if(oppsToBeUpdatedWithDDNotes.size()>0 ){
        update oppsToBeUpdatedWithDDNotes;
            
            }*/
        system.debug(opportunitiesToUpdate.size()+'0909');
         
      QuoteTriggerHandler.inRecursiveQueueableUpdate = false;
          //CPQ22-47(SF-10672) - End
  
  }
}