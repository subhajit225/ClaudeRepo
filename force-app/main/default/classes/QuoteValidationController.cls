/** @description 
* -------------------------- @History------------------------------------------------------------------------------------------------
* Story Number       Modified By              Date           Description
* FY26WL-353         Asif Hussain          2-Dec-2025      Compare quote line with entitlementIds
* --------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class QuoteValidationController {
    public static Set < Id > processedQuoteIds = new Set < Id > ();
    /**
    * Method Name          : compareEntitlementAllWithNewPrimaryQuote
    * Date Created/Modified: 5-Dec-2025
    * @description  Created as part of FY26WL-353 compare new Primary Quote with old Primary Quote line item with entitlement ids
    * @param quoteIds
    * @param oppids
    * @param accountIds
    * @param accIdWithQuoteIds
    * @return List<EntitlementResponseWrapper>
	*/ 
    @AuraEnabled
    public static List<EntitlementResponseWrapper> compareEntitlementAllWithNewPrimaryQuote(List<Id> quoteIds, List<Id> oppids,List<id> accountIds, Map<Id, Id> accIdWithQuoteIds){
        Map<Id, Set<String>> currentPrimaryQuoteWithEntitlementIds = new Map<Id, Set<String>>();
        Map<Id, Set<String>> accountWithEntitlementIds = new Map<Id, Set<String>>();
        Map<Id, Set<String>> invalidAccithEntitlmenIds = new Map<Id, Set<String>>();
        Map<Id, List<EntitlementResponseWrapper>> invalidAccWithWrapper = new Map<Id, List<EntitlementResponseWrapper>>();
        Map<Id, Id> quoteIdWithAccId = new Map<Id, Id>();
        Map<Id, List<EntitlementResponseWrapper>> quoteWithWrapper = new Map<Id, List<EntitlementResponseWrapper>>();
        List<EntitlementResponseWrapper> responseList = new List<EntitlementResponseWrapper>();
        List<String> oppClosedStages = new List<String>{'7 Closed Won','7 Closed Lost','7 Closed Admin'};
        //Fetching all quote line records based on accountId or quoteId and primary one
        for(SBQQ__QuoteLine__c quoteLineObj : [SELECT Id,Name, SBQQ__Quote__c, Replacement_Details__c, SBQQ__Quote__r.SBQQ__Opportunity2__c, 
                                            SBQQ__Quote__r.SBQQ__Opportunity2__r.Name,SBQQSC__RenewedContractLine__c, CCLI__c,SBQQ__Quote__r.SBQQ__Account__c,SBQQ__Quote__r.SBQQ__Primary__c,
                                            SBQQ__Product__r.name, SBQQ__Quote__r.SBQQ__Opportunity2__r.Renewals_Forecast_Risk__c
                                            FROM SBQQ__QuoteLine__c
                                            WHERE SBQQ__Quote__r.SBQQ__Opportunity2__r.Opportunity_Sub_Type__c  = 'Renewal'  
                                            AND SBQQ__Existing__c = false AND SBQQ__Quote__r.SBQQ__Opportunity2__r.StageName NOT IN :oppClosedStages                                        
                                            AND (SBQQ__Quote__r.SBQQ__Primary__c = true OR SBQQ__Quote__c IN: quoteIds)  AND SBQQSC__RenewedContractLine__c != null
                                            AND SBQQ__Quote__r.SBQQ__Account__c IN:accountIds ]){
            //Store Replacement_Details__c field value in string
            String jsonDetails = quoteLineObj.Replacement_Details__c;
                                        
            if (String.isBlank(jsonDetails)) {continue;}
            //Convert into JSON 
            ReplacementJson replacementMap = (ReplacementJson)JSON.deserialize(jsonDetails,ReplacementJson.class);
            
            if (replacementMap == null || replacementMap.rowValues.isEmpty()) {continue;}
            Set<String> entitleIds = new Set<String>();
            Id oppId = quoteLineObj.SBQQ__Quote__r.SBQQ__Opportunity2__c;
            Id quoteId = quoteLineObj.SBQQ__Quote__c;
            id accountId = quoteLineObj.SBQQ__Quote__r.SBQQ__Account__c;
            //loop and collect all the entitlement Ids and store in list
            for(ReplacementJson.RowDetail rowDetailObj : replacementMap.rowValues){
                if (rowDetailObj.entId == null) {continue;}                
                String entitlementId = String.valueOf(rowDetailObj.entId).trim();                                                                  
                entitleIds.add(entitlementId);                    
            }
            if(quoteLineObj.SBQQ__Quote__r.SBQQ__Opportunity2__r.Renewals_Forecast_Risk__c == 'Invalid Duplicate' ){            
                List<EntitlementResponseWrapper> ewList = new List<EntitlementResponseWrapper>();
                EntitlementResponseWrapper wrObj = new EntitlementResponseWrapper();
                if(invalidAccWithWrapper.containsKey(accountId)){
                    ewList = invalidAccWithWrapper.get(accountId);
                }
                //Setting up wrapper here
                wrObj.quoteLineId = quoteLineObj.Id;
                wrObj.quoteLineNumber = quoteLineObj.name;
                wrObj.productName = quoteLineObj.SBQQ__Product__r.name;            
                wrObj.opportunityId = quoteLineObj.SBQQ__Quote__r.SBQQ__Opportunity2__c;
                wrObj.opportunityName = quoteLineObj.SBQQ__Quote__r.SBQQ__Opportunity2__r.Name;
                wrObj.entitlementIds = new Set<String>(entitleIds);
                ewList.add(wrObj);
                invalidAccWithWrapper.put(accountId,ewList);
                if(invalidAccithEntitlmenIds.containsKey(accountId)){
                    entitleIds.addAll(invalidAccithEntitlmenIds.get(accountId));
                }
                invalidAccithEntitlmenIds.put(accountId,entitleIds);            
                continue;
            }
            //Preparing the maps one is for current primary quote with their entitlement Ids
            if(oppId != null && quoteId != null && oppIds.contains(oppId) && quoteLineObj.SBQQ__Quote__r.SBQQ__Primary__c == true){
                processedQuoteIds.add(quoteId);                         
                List<EntitlementResponseWrapper> ewList = new List<EntitlementResponseWrapper>();
                EntitlementResponseWrapper wrObj = new EntitlementResponseWrapper();
                if(quoteWithWrapper.containsKey(quoteId)){
                    ewList = quoteWithWrapper.get(quoteId);
                }
                //Setting up wrapper here
                wrObj.quoteLineId = quoteLineObj.Id;
                wrObj.quoteLineNumber = quoteLineObj.name;
                wrObj.productName = quoteLineObj.SBQQ__Product__r.name;
                wrObj.entitlementIds = new Set<String>(entitleIds);
                ewList.add(wrObj);
                quoteWithWrapper.put(quoteId,ewList);
                if(currentPrimaryQuoteWithEntitlementIds.containsKey(quoteId)){
                    entitleIds.addAll(currentPrimaryQuoteWithEntitlementIds.get(quoteId));
                }
                currentPrimaryQuoteWithEntitlementIds.put(quoteId,entitleIds);           
            }else if(accountId != null){// preparing another map accountId with rest entitlemts id of other opporunity primary quotes
                if(accountWithEntitlementIds.containsKey(accountId)){
                    entitleIds.addAll(accountWithEntitlementIds.get(accountId));
                }
                accountWithEntitlementIds.put(accountId,entitleIds);
                
            }
            //Quote Id with accountId Map 
            if(quoteId != null && !quoteIdWithAccId.containsKey(quoteId)){
                quoteIdWithAccId.put(quoteId,accountId);
            }
        }        
        if(currentPrimaryQuoteWithEntitlementIds.isEmpty()){return responseList;}
        //Loop on current primaryQuote record
        for(Id quoteObjId : currentPrimaryQuoteWithEntitlementIds.keySet()){
            if(!quoteIdWithAccId.containsKey(quoteObjId)){continue;}
            //using quoteIdWithAccId to fetch the account Id based on the quote Id
            id accId = quoteIdWithAccId.get(quoteObjId);

            if(!accountWithEntitlementIds.containsKey(accId)){continue;}
            //Based on account id fetching all entitlements id
            Set<String>allAccountEntitlement = accountWithEntitlementIds.get(accId);
            //Based on the quoteId fetching all current primary quote entitlement Ids
            Set<String>primaryQuoteEntitlement = currentPrimaryQuoteWithEntitlementIds.get(quoteObjId);
            //
            Set<String>invalidDuplicateEntitle = invalidAccithEntitlmenIds.get(accId);
            List<EntitlementResponseWrapper> ewList = new list<EntitlementResponseWrapper>();
            //Removing the common entitlement ids
            primaryQuoteEntitlement.removeAll(allAccountEntitlement);        
            if(!primaryQuoteEntitlement.isEmpty()){
                Set<String> remaingEntitleIds = new Set<String>();
                if(invalidDuplicateEntitle != null && !invalidDuplicateEntitle.isEmpty()){
                    remaingEntitleIds = new Set<String>(primaryQuoteEntitlement);
                    remaingEntitleIds.retainAll(invalidDuplicateEntitle);
                    ewList = invalidAccWithWrapper.get(accId);
                    responseList = compareEntitlementResponseWrapper(ewList, remaingEntitleIds, accIdWithQuoteIds,accId);                   
                }
                if(!quoteWithWrapper.containsKey(quoteObjId)){continue;}
                
                ewList = quoteWithWrapper.get(quoteObjId);
                responseList.addAll(compareEntitlementResponseWrapper(ewList, primaryQuoteEntitlement, accIdWithQuoteIds,accId));

            }
        }
        return responseList;
    }

    /**
    * Method Name          : compareEntitlementResponseWrapper
    * Date Created/Modified: 18-Dec-2025
    * @description  Created as part of FY26WL-353 compare new Primary Quote with old Primary Quote line item with entitlement ids
    * @param ewList
    * @param quoteEntitlement
    * @param accIdWithQuoteIds
    * @param accId
    * @return List<EntitlementResponseWrapper>
	*/ 
    public static List<EntitlementResponseWrapper> compareEntitlementResponseWrapper(List<EntitlementResponseWrapper> ewList, Set<String> quoteEntitlement, Map<Id, Id> accIdWithQuoteIds, id accId ){
        List<EntitlementResponseWrapper> responseList = new List<EntitlementResponseWrapper>();
        Set<String> remaingEntitleIds = new Set<String>();
        //Loop on warpper List
        for(EntitlementResponseWrapper ewObj : ewList){
            EntitlementResponseWrapper responseObj = new EntitlementResponseWrapper();
            Set<String> qLineItemEntitlIds = ewObj.entitlementIds;
            //Here we are checking in which quote line item record having unique entitlement ids
            remaingEntitleIds = new Set<String>(quoteEntitlement);
            remaingEntitleIds.retainAll(qLineItemEntitlIds);
            if(!remaingEntitleIds.isEmpty()){
                    List<String> tempList = new List<String>(remaingEntitleIds);
                    //storing the data in another wrapper object to send back trigger or LWC component
                    responseObj.entitlementIdsForResponse = String.join(tempList, ', ');
                    responseObj.quoteLineNumber = ewObj.quoteLineNumber;
                    responseObj.quoteLineId = ewObj.quoteLineId;
                    responseObj.productName = ewObj.productName;
                    if(String.isNotBlank(ewObj.opportunityId)){
                        responseObj.opportunityId = ewObj.opportunityId;
                        responseObj.opportunityName = ewObj.opportunityName;
                    }
                if(accIdWithQuoteIds != null && accIdWithQuoteIds.containsKey(accId)){
                    responseObj.quoteId = accIdWithQuoteIds.get(accId);   
                    responseList.add(responseObj);
                    return responseList;
                }
                responseList.add(responseObj);
            }
        }
        return responseList;
    }
}