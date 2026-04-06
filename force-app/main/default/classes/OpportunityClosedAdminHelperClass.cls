/**
* @description this class is a helper class of BatchToUpdateQLIQty and BatchRenewalOppCrreationChurn batch
* JIRA-> FY25SR-1109,FY25SR-1111,FY25SR-1154,FY25SR-1730
* Test class BatchToUpdateQLIQtyTest
* @CreatedDate 23 May 2025
**/
public class OpportunityClosedAdminHelperClass {
    
    public enum CloneType {
        PARTIAL_REPLACEMENT,
            FULL_REPLACEMENT,
            PARTIAL_CHURN,
            FULL_CHURN
            }
    /**
* @description cloneOpportunity Helper function 
* @param opportunityId
* @param cloneType
* @return clonedOpportunity
**/
    public static Opportunity cloneOpportunity(Id opportunityId,OpportunityClosedAdminHelperClass.CloneType cloneType) {
        Opportunity originalOpportunity = [
            SELECT Id, Name, AccountId, CloseDate, StageName, Pricebook2Id, ACV_Amount__c,
            Opportunity_Sub_Type__c, Opportunity_Type__c, OwnerId, RecordTypeId,
            SBQQSC__RenewedServiceContract__c 
            FROM Opportunity 
            WHERE Id = :opportunityId 
            LIMIT 1
        ];
        
        Opportunity clonedOpportunity = originalOpportunity.clone(false, true, false, false);
        clonedOpportunity.StageName = '1 Discovery';
        
        if (cloneType == OpportunityClosedAdminHelperClass.CloneType.PARTIAL_REPLACEMENT) {
            clonedOpportunity.Name = adjustOppName(originalOpportunity.Name, '- Partial Replacement');
            clonedOpportunity.Closed_Admin_Opporutinty__c = 'Partial Replacement';
        } else if (cloneType == OpportunityClosedAdminHelperClass.CloneType.FULL_REPLACEMENT) {
            clonedOpportunity.Name = adjustOppName(originalOpportunity.Name, '- Full Replacement');
            clonedOpportunity.Closed_Admin_Opporutinty__c = 'Partial Replacement'; 
        } else if (cloneType == OpportunityClosedAdminHelperClass.CloneType.PARTIAL_CHURN) {
            clonedOpportunity.Name = adjustOppName(originalOpportunity.Name, ' - Partial Churn');
            clonedOpportunity.Renewals_Sentiment__c = 'Red';
        } else if (cloneType == OpportunityClosedAdminHelperClass.CloneType.FULL_CHURN) {
            clonedOpportunity.Name = adjustOppName(originalOpportunity.Name, ' - Full Churn');
            clonedOpportunity.Renewals_Sentiment__c = 'Red';
        }
        
        return clonedOpportunity;
    }
    /**
* @description adjustOppName Helper function to decide opp. name 
* @param originalName
* @param suffix
* @return oppName
**/ 
    public static String adjustOppName(String originalName, String suffix) {
        Integer maxLength = 120;
        // Check total length after appending suffix
        if ((originalName + suffix).length() <= maxLength) {
            return originalName + suffix;
        } else {
            // Calculate the max allowed length for the original name part
            Integer allowedLength = maxLength - suffix.length();
            String trimmedName = originalName.substring(0, allowedLength);
            return trimmedName + suffix;
        }
    }
    
    /**
* @description getLicenseLinesPostAssetRefresh Helper function to replace asset details in case of r6K refresh 
*  FY25SR-1154
* @param refreshEntIds
* @return row.selectedQty
**/ 
    public static List<SBQQ__QuoteLine__c> getLicenseLinesPostAssetRefresh(Set<Id> refreshEntIds){
        //system.debug('@@inside getLicenseLinesPostAssetRefresh '+refreshEntIds);
        Map<String, Map<String,String>> assetr6kVsr7k = new Map<String, Map<String,String>>();
        for(Entitlement_Links__c el : [SELECT Id, Previous_Entitlement__r.Name,Previous_Entitlement__r.Renewal_Category__c,Previous_Entitlement__r.AssetId,Previous_Entitlement__r.Asset.Name,Renewed_Entitlement__r.Asset.Name,
                                       Renewed_Entitlement__r.Name,Renewed_Entitlement__r.AssetId FROM Entitlement_Links__c WHERE Previous_Entitlement__r.Resync_Line__c = 'Required' AND Previous_Entitlement__r.Renewal_Category__c = 'Refreshed' AND Previous_Entitlement__r.Product__r.Product_Type__c ='HW Support' AND Previous_Entitlement__c IN: refreshEntIds AND Renewed_Entitlement__r.AssetId!=null ]) 
        {
            Map<String,String> assetNameVsId=assetr6kVsr7k.containsKey(el.Previous_Entitlement__r.Asset.Name)?
                assetr6kVsr7k.get(el.Previous_Entitlement__r.Asset.Name)
                :new Map<String,String>();
            assetNameVsId.put(el.Renewed_Entitlement__r.AssetId,el.Renewed_Entitlement__r.Asset.Name);
            assetr6kVsr7k.put(el.Previous_Entitlement__r.Asset.Name,assetNameVsId);
        }
        if(assetr6kVsr7k!=null && !assetr6kVsr7k.isEmpty()){
            Set<String> assetNamesofR6k = assetr6kVsr7k.keySet();
            Replacement_Field_Mapping__mdt objectData= Replacement_Field_Mapping__mdt.getInstance('QLI_Closed_Admin_Filter');
            String firstWhereClause= objectData.First_Filter_Criteria__c;
            String secondWhereClause= objectData.Second_Filter_Criteria__c;
            String thirdWhereClause= objectData.Third_Filter_Criteria__c;
            String qliQuery = 'SELECT SBQQ__Quote__c, Id, SBQQSC__RenewedContractLine__c, SBQQ__ProductCode__c, Subscribed_Asset_Name__c, SubscribedAssetNames__c, '
                + 'SBQQ__Quantity__c, SBQQ__Quote__r.Amended_Renewed_Service_Contract__c, Replacement_Details__c FROM SBQQ__QuoteLine__c '
                + 'WHERE SBQQSC__RenewedContractLine__c IN (SELECT Contract_Line_Item__c FROM Scale_Entitlement__c WHERE Asset__r.Name IN :assetNamesofR6k) '
                + firstWhereClause + ' ' + secondWhereClause + ' ' + thirdWhereClause;
            
            List<SBQQ__QuoteLine__c> qLIList = Database.query(qliQuery.trim());
            if (!qLIList.isEmpty()) {
                for (SBQQ__QuoteLine__c qli : qLIList) {
                    if (String.isNotBlank(qli.Subscribed_Asset_Name__c) && qli.Replacement_Details__c!=null) {
                        List<String> assetNames = qli.Subscribed_Asset_Name__c.split(',');
                        List<String> newAssetList = new List<String>();
                        Set<String> newAssetSet =new Set<String>();
                        List<ReplacementJson.RowDetail> newRowValues = new List<ReplacementJson.RowDetail>();
                        for (String assetName : assetNames) {
                            assetName = assetName.trim(); // Optional: clean up whitespace
                            if (assetr6kVsr7k.containsKey(assetName)) {
                                // newAssetList.addAll(assetr6kVsr7k.get(assetName).values());
                                for (String value : assetr6kVsr7k.get(assetName).values()) {
                                    if (!newAssetSet.contains(value)) {//to avoide duplicated in case of manyToMany
                                        newAssetList.add(value);
                                        newAssetSet.add(value);
                                    }
                                }
                            } else {
                                newAssetList.add(assetName);
                            }
                        }
                        ReplacementJson qliReplaceJSON = (ReplacementJson)JSON.deserialize(qli.Replacement_Details__c, ReplacementJson.class);
                        if (qliReplaceJSON != null && qliReplaceJSON.rowValues != null) {
                            for (ReplacementJson.RowDetail childRow : qliReplaceJSON.rowValues) {
                                if(childRow.selectedAssetList!=null){
                                    Map<String, String> newlistOfAsset = new Map<String, String>();
                                    for (String s : childRow.selectedAssetList.keySet()) {
                                        String value = childRow.selectedAssetList.get(s);
                                        Map<String, String> newlist = new Map<String, String>();
                                        newlist.put(s, value);
                                        if (assetr6kVsr7k.containsKey(value)) {
                                            newlistOfAsset.putAll(assetr6kVsr7k.get(value));
                                        } else {
                                            newlistOfAsset.put(s, value);
                                        }
                                    }
                                    childRow.selectedAssetList = newlistOfAsset;
                                    childRow.selectedAsset = String.join(newlistOfAsset.keySet(), ',');
                                }
                                newRowValues.add(childRow);  
                            }
                        }
                        
                        if (!newAssetList.isEmpty()) {
                            String joinedAssets = String.join(newAssetList, ',');
                            qli.Subscribed_Asset_Name__c = joinedAssets;
                            qli.SubscribedAssetNames__c = joinedAssets;
                        }
                        if(newRowValues!=null && !newRowValues.isEmpty()){
                            qliReplaceJSON.rowValues = new List<ReplacementJson.RowDetail>(newRowValues);
                            qli.Replacement_Details__c = qliReplaceJSON!=null? JSON.serialize(qliReplaceJSON):null;  
                        }
                    }
                }
            }
            return qLIList;
        }
        return null;
    }
 
     /**
* @description buildQuotesAndLines Helper function to create quote and quote lines on closed admin opportunities. 
* JIRA FY25SR-1730-> FY25SR-1109 and FY25SR-1111
* @param oppIds
* @param oliToCPQMap
* @return quoteIds
**/
    public static set<Id> buildQuotesAndLines(Set<Id> oppIds,Map<Id, CPQ_Disposition_Quote_Line__c> oliToCPQMap) {
            set<Id> quoteIds=new set<Id>();
        try{
            //Disable quoteTriggers
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            SBQQ.TriggerControl.disable();
            flowControll.opportunityTriggerHandler = false;
            flowControll.opportunityLineItemHandler = false;
            List<OpportunityLineItem> oppProducts =new List<OpportunityLineItem>(); 
            if(oppIds!=null && !oppIds.isEmpty()){
             oppProducts = [SELECT Id, OpportunityId, Quantity, Product2Id, Amended_Service_Contract_Id_Text__c, 
                                                     ContractLine_Id__c, PricebookEntryId, Opportunity.AccountId, Opportunity.Pricebook2Id 
                                                     FROM OpportunityLineItem WHERE OpportunityId IN :oppIds];
            }
            else{
              oppProducts = [SELECT Id, OpportunityId, Quantity, Product2Id, Amended_Service_Contract_Id_Text__c, 
                                                     ContractLine_Id__c, PricebookEntryId, Opportunity.AccountId, Opportunity.Pricebook2Id 
                                                     FROM OpportunityLineItem WHERE Id IN :oliToCPQMap.keySet()];  
            }
            
            Map<Id, SBQQ__Quote__c> oppIdToQuoteMap = new Map<Id, SBQQ__Quote__c>();
            List<SBQQ__QuoteLine__c> quoteLineItems = new List<SBQQ__QuoteLine__c>();
            Map<Id, Map<String, String>> cliVsAssets = new Map<Id, Map<String, String>>();
            Map<Id, Decimal> ClIIdtoTerm = new Map<Id, Decimal>();
            Set<Id> cliIds = new Set<Id>();
            Map<Id, Id> oppToQuoteIdMap = new Map<Id, Id>();
            //Update Opportunity with Primary Quote
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            
            //update quote lines ids on OLI
            List<OpportunityLineItem> oppLineItemsToUpdate = new List<OpportunityLineItem>();
             if (oppProducts != null && !oppProducts.isEmpty()) {
                //Create quotes per opportunity
                for (OpportunityLineItem oppProduct : oppProducts) {
                    if(oppIds!=null && !oppIds.isEmpty()){cliIds.add(oppProduct.ContractLine_Id__c);}
                    if (!oppIdToQuoteMap.containsKey(oppProduct.OpportunityId)) {
                        SBQQ__Quote__c q = new SBQQ__Quote__c(
                            SBQQ__Account__c = oppProduct.Opportunity.AccountId,
                            SBQQ__Opportunity2__c = oppProduct.OpportunityId,
                            SBQQ__Primary__c = true,
                            SBQQ__PriceBook__c = oppProduct.Opportunity.Pricebook2Id,
                            SBQQ__PricebookId__c = oppProduct.Opportunity.Pricebook2Id,
                            SBQQ__ExpirationDate__c = System.today(),
                            SBQQ__StartDate__c = Date.Today(),
                            SBQQ__SubscriptionTerm__c = 36,
                            Amended_Renewed_Service_Contract__c = oppProduct.Amended_Service_Contract_Id_Text__c,
                            OpportunitySubType__c = 'Renewal',
                            SBQQ__Type__c = 'Renewal',
                            SBQQ__Status__c='Approved',
                            ApprovalStatus__c='Approved'
                        );
                        oppIdToQuoteMap.put(oppProduct.OpportunityId, q);
                        }
                }
                
                Database.insert(oppIdToQuoteMap.values(), false);
                for (Id oppId : oppIdToQuoteMap.keySet()) {
                    oppToQuoteIdMap.put(oppId, oppIdToQuoteMap.get(oppId).Id);
                }
                 //Process entitlements
                if (cliIds != null && !cliIds.isEmpty()) {
                    Set<Id> entids = new Set<Id>();
                    for (Entitlement e : [
                        SELECT Id, ContractLineItemId, Product__c, Product__r.ProductCode, Product__r.Product_Level__c, 
                        Name, Renewal_Category__c, Quantity__c, ContractLineItem.Subscription_Term__c,Asset.Name, AssetId, Status, Resync_Line__c, Product__r.Product_Type__c
                        FROM Entitlement WHERE ContractLineItemId IN :cliIds
                    ]) {
                        if (e.Renewal_Category__c == 'Upgraded' || e.Renewal_Category__c == 'Converted' || e.Renewal_Category__c == 'Replaced') {
                            entids.add(e.Id);
                            if (e.AssetId != null) {
                                Map<String, String> selectedAssetList = new Map<String, String>();
                                selectedAssetList.put(e.AssetId, e.Asset.Name);
                                cliVsAssets.put(e.ContractLineItemId, selectedAssetList);
                            }
                            ClIIdtoTerm.put(e.ContractLineItemId, e.ContractLineItem.Subscription_Term__c);
                        }
                    }
                    
                    if (!entids.isEmpty()) {
                        for (Scale_Entitlement__c sc : [
                            SELECT Id, Asset__r.Name, Asset__c, Entitlement__c, Entitlement__r.Renewal_Category__c, Entitlement__r.Resync_Line__c,
                            Entitlement__r.Product__c, Entitlement__r.Product__r.Product_Level__c, Entitlement__r.ContractLineItemId 
                            FROM Scale_Entitlement__c WHERE Entitlement__c IN :entids
                        ]) {
                            Map<String, String> selectedAssetList = cliVsAssets.containsKey(sc.Entitlement__r.ContractLineItemId) 
                                ? cliVsAssets.get(sc.Entitlement__r.ContractLineItemId) 
                                : new Map<String, String>();
                            selectedAssetList.put(sc.Asset__c, sc.Asset__r.Name);
                            cliVsAssets.put(sc.Entitlement__r.ContractLineItemId, selectedAssetList);
                        }
                    }
                }
                
                //create quote lines
                for (OpportunityLineItem oppProduct : oppProducts) {
                    Id parentQuoteId = oppToQuoteIdMap.get(oppProduct.OpportunityId);
                    CPQ_Disposition_Quote_Line__c sourceCPQ = oliToCPQMap != null ? oliToCPQMap.get(oppProduct.Id) : null;
                     SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c(
                        SBQQ__Quote__c = parentQuoteId,
                        SBQQ__Product__c = oppProduct.Product2Id,
                        SBQQ__Quantity__c = oppProduct.Quantity,
                        SBQQSC__RenewedContractLine__c = oppProduct.ContractLine_Id__c,
                        SBQQ__SubscriptionTerm__c = !ClIIdtoTerm.isEmpty() && ClIIdtoTerm.containsKey(oppProduct.ContractLine_Id__c) ? ClIIdtoTerm.get(oppProduct.ContractLine_Id__c) : 12 ,
                        Arroyo_Subsumed_Old_Contract_Line_Items__c=oppProduct.ContractLine_Id__c,
                        SBQQ__PricebookEntryId__c = oppProduct.PricebookEntryId,
                        Disposition_Reason__c = 'Renewing',
                        Replacement_Motion__c='Upgrade'
                       );
                    
                    if (sourceCPQ != null) {
                        qli.SubscribedAssetNames__c = sourceCPQ.Arroyo_Subscribed_Asset_Name__c;
                        qli.Subscribed_Asset_Name__c = sourceCPQ.Arroyo_Subscribed_Asset_Name__c;
                        qli.Replacement_details__c = sourceCPQ.Replacement_Detail__c;
                    } else if (cliVsAssets!=null && cliVsAssets.containsKey(oppProduct.ContractLine_Id__c)) {
                        String assetNames = String.join(new List<String>(cliVsAssets.get(oppProduct.ContractLine_Id__c).values()), ',');
                        qli.SubscribedAssetNames__c = assetNames;
                        qli.Subscribed_Asset_Name__c = assetNames;
                     }
                    quoteLineItems.add(qli);
                    }
                
                
                // Update OpportunityLineItem with QuoteLine Ids
                List<Database.SaveResult> qliResults = Database.insert(quoteLineItems, false);
                Integer index = 0;
                for (OpportunityLineItem oppProduct : oppProducts) {
                    if (qliResults[index].isSuccess()) {
                        OpportunityLineItem oli = new OpportunityLineItem(Id = oppProduct.Id);
                        oli.SBQQ__QuoteLine__c = quoteLineItems[index].Id;
                        oppLineItemsToUpdate.add(oli);
                    }
                    index++;
                }
                
                if (!oppLineItemsToUpdate.isEmpty()) {
                    Database.update(oppLineItemsToUpdate,false);
                }
                
                for (Id oppId : oppToQuoteIdMap.keySet()) {
                    Opportunity opp = new Opportunity(Id = oppId);
                    opp.SBQQ__PrimaryQuote__c = oppToQuoteIdMap.get(oppId); // Assumes CPQ primary quote relationship field
                    oppsToUpdate.add(opp);
                    quoteIds.add( oppToQuoteIdMap.get(oppId));//added
                }
                if (!oppsToUpdate.isEmpty()) {
                    Database.update(oppsToUpdate,false);
                }
                return quoteIds;
              } 
         }catch (Exception ex) {
            System.debug(LoggingLevel.DEBUG, 'Error in buildQuotesAndLines: ' + ex.getMessage());
        }
        return quoteIds;
    }

}