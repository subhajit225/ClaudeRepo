/**
* @Description        : This is the Utility class which update Opportunity where multiple Primary Quote is associated
* @Author             : Shivani
* Ver       Date            Author                 Modification
* 1.0      06-20-2022       Shivani               Intial Draft
**/  
public class UpdatePrimaryQuotesBatchUtility { 
    public static List<String> errr= new List<String>();
/**
* Method : updateQuotesOnOpportunity
* Parameters : opportunityRecords- This parameter holds all Opportunities where multiple Primary Quote
* Description :  This method is to set only 1 Quote as primary and unche
*/
    public static set<Id> updateQuotesOnOpportunity(List<Opportunity> opportunityRecords) {
        System.debug('Opportunity records recieved' + opportunityRecords);
        
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<SBQQ__Quote__c> quoteToUpdateAsNonPrimary = new List<SBQQ__Quote__c>();
        List<SBQQ__Quote__c> quoteLst = new List<SBQQ__Quote__c>();
        List<SBQQ__Quote__c> quoteToUpdateAsPrimary = new List<SBQQ__Quote__c>();
        Map<Id, SBQQ__Quote__c> oppQuoteMap = new Map<Id, SBQQ__Quote__c>();
		Map<Id, Map<Id, Boolean>> opportunityQuotePrimaryMap = new Map<Id, Map<Id, Boolean>>();//CPQ22-3862
		Set<Id> quoteUpdatedAsNonPrimary = new Set<Id>();//CPQ22-3862
		Set<Id> quoteUpdatedAsPrimary = new Set<Id>();//CPQ22-3862
		Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>(opportunityRecords);//CPQ22-3862
        Integer countPrimary = 0;//CPQ22-3862
        Map<Id, Boolean> quotePrimaryMap; // CPQ22-3862       
       /* Filter out opportunity where more than 1 Non Zero acv quote is associated 
from logic as this will be handled manually by Renewal Team */
        
        for (Opportunity opp : opportunityRecords) {
            Integer countNonZeroQuote = 0;
            if (opp.sbqq__Quotes2__r.size() > 1) {
                for(SBQQ__Quote__c quoteObj : opp.sbqq__Quotes2__r) 
                {
                    System.debug('Quote in loop' + quoteObj);
                    if(quoteObj.SBQQ__Primary__c == true && quoteObj.SBQQ__NetAmount__c  != 0) {
                        countNonZeroQuote = countNonZeroQuote + 1;
                    }
                    if(countNonZeroQuote > 1) {
                        break;
                    }
                }
                if(countNonZeroQuote <= 1) {
                    opportunityList.add(opp);
                }
            }
        }
        
        //Logic - set Quote with Non Zero amount as primary OR set latest created quote as Primary
        for (Opportunity opp : opportunityList) {
            if (opp.sbqq__Quotes2__r.size() > 1) {
                for(Sbqq__quote__c quoteObj : opp.sbqq__Quotes2__r) {
                    //CPQ22-3862 Created original map<opportunity, map<quote,isPrimary>>
					if(opportunityQuotePrimaryMap.containsKey(opp.Id)){
						if(!opportunityQuotePrimaryMap.get(opp.Id).containsKey(quoteObj.Id)){
							quotePrimaryMap =  opportunityQuotePrimaryMap.get(opp.Id);
							quotePrimaryMap.put(quoteObj.Id, quoteObj.SBQQ__Primary__c);
							opportunityQuotePrimaryMap.put(opp.Id, quotePrimaryMap);
						}
					}else{
						 quotePrimaryMap =  new Map<Id, Boolean>();
						quotePrimaryMap.put(quoteObj.Id, quoteObj.SBQQ__Primary__c);
						opportunityQuotePrimaryMap.put(opp.Id, quotePrimaryMap);
					}
                    //--End of CPQ22-3862
                    System.debug('Quote in second loop' + quoteObj);
                    if(quoteObj.SBQQ__Primary__c == true) {
                        quoteObj.SBQQ__Primary__c = false;
                        quoteToUpdateAsNonPrimary.add(quoteObj);
                    }
                    if(quoteObj.SBQQ__NetAmount__c > 0 && !oppQuoteMap.containsKey(opp.Id) ) {
                        oppQuoteMap.put(opp.Id,quoteObj);
                    }
                }
                if(!oppQuoteMap.containsKey(opp.Id)) {
                    oppQuoteMap.put(opp.Id,opp.sbqq__Quotes2__r[0]);
                }
            }
        }
        
        if (!quoteToUpdateAsNonPrimary.isEmpty()) {
            SBQQ.TriggerControl.disable();
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            Database.SaveResult[] srList = Database.update(quoteToUpdateAsNonPrimary, false);
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    errr.add('<b>' + sr.getId() + '</b> ::'+ JSON.serialize(sr.getErrors()));
                    for (Database.Error objErr : sr.getErrors()) {
                        System.debug(objErr.getStatusCode() + ': ' + objErr.getMessage());
                    }
                }else{
					quoteUpdatedAsNonPrimary.add(sr.getId());
				}
            } 
            SBQQ.TriggerControl.enable();
        } 
        
        for(SBQQ__Quote__c quoteObj : oppQuoteMap.values()) {
            quoteObj.SBQQ__Primary__c = true;
            quoteToUpdateAsPrimary.add(quoteObj );
        }
        
        if (!quoteToUpdateAsPrimary.isEmpty()) {
            Database.SaveResult[] srList = Database.update(quoteToUpdateAsPrimary, false);
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    errr.add('<b>' + sr.getId() + '</b> ::'+ JSON.serialize(sr.getErrors()));
                    for(Database.Error objErr : sr.getErrors()) {
                        System.debug(objErr.getStatusCode() + ': ' + objErr.getMessage());
                    }
                }else{
					quoteUpdatedAsPrimary.add(sr.getId());
				}
            } 
        }
		//CPQ22-3862 Get count of primary quotes and update Number_of_valid_Primary_Quotes__c on opportunity
		List<Opportunity> opportunityToBeUpdatedList = new List<Opportunity>(); 
		for(Id oppId: opportunityQuotePrimaryMap.keySet()){
			countPrimary = 0;
			for(Id quoteID : opportunityQuotePrimaryMap.get(oppId).keyset()){
				if(quoteUpdatedAsPrimary.contains(quoteId)){
					countPrimary  = countPrimary + 1;
				}else if(opportunityQuotePrimaryMap.get(oppId).get(quoteID) == true && !quoteUpdatedAsNonPrimary.contains(quoteId)){
					countPrimary  = countPrimary + 1;
				}
			}
            
         	if(opportunityMap.containskey(oppId) && opportunityMap.get(oppId).Number_of_valid_Primary_Quotes__c != countPrimary ){
				Opportunity opp =  new opportunity();
				opp.Id = oppId;
				opp.Number_of_valid_Primary_Quotes__c = countPrimary;
				opportunityToBeUpdatedList.add(opp);
			}
		}
		//--End of CPQ22-3862
		
		if (!opportunityToBeUpdatedList.isEmpty()) {
            Database.SaveResult[] srList = Database.update(opportunityToBeUpdatedList, false);
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    errr.add('<b>' + sr.getId() + '</b> ::'+ JSON.serialize(sr.getErrors()));
                    for(Database.Error objErr : sr.getErrors()) {
                        System.debug(objErr.getStatusCode() + ': ' + objErr.getMessage());
                    }
                }
            } 
        }
        return oppQuoteMap.keyset();
	}
}