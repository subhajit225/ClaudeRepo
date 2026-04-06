/**
* @description Batch Job to update the Quantity on Quote line items if Renewal quantity of Contract line item has been changed-> JIRA - REEN-25 
* Batch Job to create Opportunity and opportunity product for replaced quotelines-> JIRA - FY25SR-1111
* Batch Job to update Assets on License when the asset is refreshed from r6k to r7K-> JIRA - FY25SR-1154
* Batch Job to create Quote and quote line on Opportunity created for the ticket FY25SR-1111-> JIRA - FY25SR-1730     
* @CreatedDate 4th Dec 2023
**/
public with sharing class BatchToUpdateQLIQty implements Database.Batchable<sObject>,Database.Stateful,Schedulable {
    public String query;
    public List<String> errorsnewSCList = new List<String>();//to send email for failed records
    public Set<Id> successEntIds=new Set<Id>();//to update Resync_Line__c=Completed' after procesing
    public Set<Id> failedEntIds=new Set<Id>();//to update Resync_Line__c=ReplacementConstants.RESYNC_LINE_MANUAL_REVIEW_REQUIRED after procesing
    public Set<Id> quoteApproved=new Set<Id>();//to submit the quote for approval(passing quoteIds in quoteApprovalBatch from Finish method)
    public Set<Id> quoteIDs=new Set<Id>();//to recalculate the quote (passing quoteIds in calculateBatch from Finish method)
    public Set<Id> quoteLineIds=new Set<Id>();//to process only impacted quote lines of a quote
    public Set<Id> disposeLineIds=new Set<Id>();//to process only impacted CPQ Dispose lines of a quote
    public Set<Id> serviceContractIds=new Set<Id>();//to idnetify whether a closed admin created for this SC or not
    
    /** 
    * @description batch constructor for commor queries 
    * **/
    public BatchToUpdateQLIQty(){
        Set<Id> contractLineItemIDs=new Set<Id>();
        Set<String> qid=new Set<String>();
        //Fetch all entitlements needing resync (single query)
        for(Entitlement e : [SELECT Id, ContractLineItemId, Renewal_Category__c, 
                                    Quantity__c, Asset.Name, AssetId, Status, Resync_Line__c
                              FROM Entitlement 
                              WHERE Resync_Line__c = :ReplacementConstants.RESYNC_LINE_REQUIRED]){
            contractLineItemIDs.add(e.ContractLineItemId);
        }
        //System.debug(LoggingLevel.DEBUG, '@@contractLineItemIDs> '+contractLineItemIDs);
        if(contractLineItemIDs!=null && !contractLineItemIDs.isEmpty()){
            Replacement_Field_Mapping__mdt objectData= 
                Replacement_Field_Mapping__mdt.getInstance(
                        ReplacementConstants.REPLACEMENT_QLI_CLOSED_ADMIN_FILTER);
            String firstWhereClause= objectData.First_Filter_Criteria__c;
            String secondWhereClause= objectData.Second_Filter_Criteria__c;
            String thirdWhereClause= objectData.Third_Filter_Criteria__c;
            
            String qliQuery='SELECT id,SBQQ__Quote__c FROM SBQQ__QuoteLine__c WHERE SBQQSC__RenewedContractLine__c!=Null '
                + 'AND (SBQQSC__RenewedContractLine__c IN: contractLineItemIDs OR CCLI__c IN: contractLineItemIDs) '
                + firstWhereClause + ' '+ secondWhereClause + ' '+ thirdWhereClause;
            
            List<SBQQ__QuoteLine__c> QuoteLineList= Database.query(qliQuery.trim());                                
            if(QuoteLineList!=null && !QuoteLineList.isEmpty()){
                for(SBQQ__QuoteLine__c qli:QuoteLineList) {
                    qid.add('\''+qli.SBQQ__Quote__c+'\''); 
                    quoteLineIds.add(qli.Id);
                }
            }
            
            Replacement_Field_Mapping__mdt objectData1= 
                Replacement_Field_Mapping__mdt.getInstance(ReplacementConstants.REPLACEMENT_CPQDISPOSE_CLOSED_ADMIN);
            String firstWhereClause1= objectData1.First_Filter_Criteria__c;
            String secondWhereClause1= objectData1.Second_Filter_Criteria__c;
            String thirdWhereClause1= objectData1.Third_Filter_Criteria__c;
            
            String cpqDisposeQuery='SELECT Id,Quote__c from CPQ_Disposition_Quote_Line__c WHERE '
                +'RenewedContractLine__c!=Null AND RenewedContractLine__c IN: contractLineItemIDs '
                + firstWhereClause1 + ' '+ secondWhereClause1 + ' '+ thirdWhereClause1;
            
            List<CPQ_Disposition_Quote_Line__c> cpqDisposeLineList= Database.query(cpqDisposeQuery.trim()); 
            if(cpqDisposeLineList!=null && !cpqDisposeLineList.isEmpty()){
                for(CPQ_Disposition_Quote_Line__c cdqli:cpqDisposeLineList){
                    qid.add('\''+cdqli.Quote__c+'\'');   
                    disposeLineIds.add(cdqli.Id);
                } 
            }
            List<String> qIDList=new List<String>();
            qIDList.addAll(qid);
            // qIDList.add('\'a6TEc000000EuvBMAS\'');
            if(qIDList!=null && !qIDList.isEmpty()){
                query='SELECT id,SBQQ__Status__c,SBQQ__Type__c,OpportunitySubType__c,Amended_Renewed_Service_Contract__c,';
                query+=' SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.StageName FROM SBQQ__Quote__c';
                query+=' WHERE Id IN ('+String.join(qIDList,',')+')';
            }
        }
    }
    /**
    * @description Batch Job to update the Quantity on Quote line items-Start method
    * @param batchableContext
    * @return query
    **/
    public Database.QueryLocator start(Database.BatchableContext batchableContext){
        if(query!=null){
            return Database.getQueryLocator(query); 
        }
        return Database.getQueryLocator('SELECT Id FROM SBQQ__Quote__c WHERE IsDeleted=true AND IsDeleted=false');
    }
    /**
    * @description Batch Job to update the Quantity on Quote line items-Execute method
    * @param batchableContext
    * @param scope
    **/
    public void execute(Database.BatchableContext batchableContext, List<SBQQ__Quote__c> scope){
        try{
            Opportunity closedAdminOpp;	//added
            List<OpportunityLineItem> closedAdminOppProducts=new List<OpportunityLineItem>(); //added 
            List<CPQ_Disposition_Quote_Line__c> updatecpqDliList=new List<CPQ_Disposition_Quote_Line__c>();//added
            List<CPQ_Disposition_Quote_Line__c> updateQtyOncpqDLi=new List<CPQ_Disposition_Quote_Line__c>();
			List<SBQQ__QuoteLine__c> updateqLIList=new List<SBQQ__QuoteLine__c>();
            List<SBQQ__QuoteLine__c> updateQtyOnQLi=new List<SBQQ__QuoteLine__c>();
            List<Batch_Error_Log__c> batchErrLogList = new List<Batch_Error_Log__c>();
            Map<Id,Id> qLIQuoteId=new Map<Id,Id>();//to store QLI and its quote ids.
            Map<Id,Id> cpqQuoteId=new Map<Id,Id>();//to store cpqDisposeLineId and its quote ids.
            Set<ID> InReviewQuotes= new Set<ID>();
            List<sbaa__Approval__c> deleteInReview= new List<sbaa__Approval__c>();
            Set<ID> deleteCCLiSet= new Set<ID>();
            List<Consolidated_Contract_Lines__c> deleteCCLi=new List<Consolidated_Contract_Lines__c>();
            List<CPQ_Disposition_Quote_Line__c> deleteCPQdli=new List<CPQ_Disposition_Quote_Line__c>();//added
            List<SBQQ__Quote__c> qlList=new List<SBQQ__Quote__c>();
            Set<Id> allEntIds=new Set<Id>();
			Map<Id,Set<Id>> qliVsEntIds=new Map<Id,Set<Id>>();
			Map<Id,Set<Id>> cpqliVsEntIds=new Map<Id,Set<Id>>();
			Map<Id,Set<Id>> entVsEntLinkIds=new Map<Id,Set<Id>>();
			
            Map<Id,List<Entitlement>> cliReplacedENtList=new Map<Id,List<Entitlement>>();//needed
            Map<Id,Decimal> entVsqty=new Map<Id,Decimal>();//needed
            Map<Id,Map<String,String>> entVsAssets=new Map<Id,Map<String,String>>();//needed
            //needed//SC and its cLI which are replaced
            Map<Id,List<ContractLineItem>> scVsCLIs=new Map<Id,List<ContractLineItem>>();
            Map<Id,List<Id>> entLinks=new Map<Id,List<Id>>();
            Map<Id,Entitlement> entVsEntData =new Map<Id,Entitlement>();
            Map<Id,Asset> assetNameQuantityMap=new Map<Id,Asset>();
            Map<Id,Polaris_SKU_Mapping_V2__c> sourceSKUPolarisMapping=new Map<Id,Polaris_SKU_Mapping_V2__c>();
            Map<Id,Set<Id>> qscVSqlisc= new Map<Id,Set<Id>>();//added new
            if(scope!=null && !scope.isEmpty()){
                SBQQ__Quote__c quote= (SBQQ__Quote__c)scope[0];
                //get quotel ines
                updateqLIList=[SELECT id,Arroyo_Subsumed_Old_Contract_Line_Items__c,
                                      CCLI__c,SBQQ__Quantity__c,SBQQSC__RenewedContractLine__c,
                                      SBQQSC__RenewedContractLine__r.SBQQSC__RenewalQuantity__c,
                                      Product_Type__c,SBQQ__BundledQuantity__c,
                                      SBQQ__Quote__r.SBQQ__Opportunity2__c,
                                      SBQQ__Quote__r.Amended_Renewed_Service_Contract__c,
                                      SBQQSC__RenewedContractLine__r.ServiceContractId,//added new
                                      SBQQ__Quote__c,SBQQ__Optional__c,SBQQ__Existing__c,
                                      Disposition_Reason__c,Replacement_Details__c,
                                      RWD_Expected_Default_Quantity__c,SBQQ__Product__c,SBQQ__PriorQuantity__c,
                                      Related_Asset_Total_Capacity__c,SBQQ__PricebookEntryId__c,
                                      SBQQ__ListPrice__c,SBQQ__NetPrice__c
                                 FROM SBQQ__QuoteLine__c 
                                WHERE SBQQ__Quote__c IN:scope AND Id IN : quoteLineIds]; 
                //get CPQ Dispose lines
                updatecpqDliList=[SELECT Id,Quantity__c,Quote__c,Quote__r.OpportunitySubType__c,
                                  Quote__r.SBQQ__Opportunity2__c,Quote__r.SBQQ__Opportunity2__r.StageName,
                                  RenewedContractLine__c,Replacement_Detail__c,
                                  RenewedContractLine__r.ServiceContractId,//added new
                                  Quote__r.Amended_Renewed_Service_Contract__c,//added new
                                  Arroyo_Subsumed_Old_Contract_Line_Items__c,Product__c,
                                  PricebookEntryId__c from CPQ_Disposition_Quote_Line__c 
                                  WHERE Quote__c IN:scope AND Id IN : disposeLineIds]; 
                
                if(updateqLIList!=null && !updateqLIList.isEmpty()){
                    for(SBQQ__QuoteLine__c qli:updateqLIList){
                        if(qli.Arroyo_Subsumed_Old_Contract_Line_Items__c!=Null && qli.Replacement_Details__c!=null){
                            readReplacementDetails(qli.Replacement_Details__c,allEntIds);
                            Set<Id> scIds=qscVSqlisc.containsKey(qli.SBQQ__Quote__r.Amended_Renewed_Service_Contract__c)?
                                          qscVSqlisc.get(qli.SBQQ__Quote__r.Amended_Renewed_Service_Contract__c):new Set<Id>();
                            scIds.add(qli.SBQQSC__RenewedContractLine__r.ServiceContractId);
                            qscVSqlisc.put(qli.SBQQ__Quote__r.Amended_Renewed_Service_Contract__c,scIds);                            
                        }}				  
                }	
                if(updatecpqDliList!=null && !updatecpqDliList.isEmpty()){
                    for(CPQ_Disposition_Quote_Line__c qli:updatecpqDliList){
                        if(qli.Replacement_Detail__c!=null){
                            readReplacementDetails(qli.Replacement_Detail__c,allEntIds);
                            Set<Id> scIds=qscVSqlisc.containsKey(qli.Quote__r.Amended_Renewed_Service_Contract__c)?
                                          qscVSqlisc.get(qli.Quote__r.Amended_Renewed_Service_Contract__c):new Set<Id>();
                            scIds.add(qli.RenewedContractLine__r.ServiceContractId);
                            qscVSqlisc.put(qli.Quote__r.Amended_Renewed_Service_Contract__c,scIds);      
                        }
                    } 
                }
                if(allEntIds!=null && !allEntIds.isEmpty()){
                    //Start MoveToExecute	
                    Set<Id> assetIds=new Set<Id>();
                    Set<Id> oldProductIds=new Set<Id>();		
                    //Process Entitlement Links
                    for(Entitlement_Links__c el : 
                        [SELECT Id, Previous_Entitlement__c, Renewed_Entitlement__c,
                                Renewed_Entitlement__r.Quantity__c,
                                Renewed_Entitlement__r.Renewal_Category__c,
                                Renewed_Entitlement__r.Resync_Line__c
                           FROM Entitlement_Links__c
                          WHERE Previous_Entitlement__c IN: allEntIds]) {
                        if(el.Renewed_Entitlement__r.Resync_Line__c == ReplacementConstants.RESYNC_LINE_REQUIRED)
                        {
                            if(el.Renewed_Entitlement__r.Renewal_Category__c == null){
                                List<id> entId=entLinks.containsKey(el.Previous_Entitlement__c)
                                              ?entLinks.get(el.Previous_Entitlement__c):new List<Id>();
                                entId.add(el.Renewed_Entitlement__c);
                                entLinks.put(el.Previous_Entitlement__c,entId);
                            }
                            allEntIds.add(el.Renewed_Entitlement__c);
                            Set<id> entIdd=entVsEntLinkIds.containsKey(el.Previous_Entitlement__c)
                                          ?entVsEntLinkIds.get(el.Previous_Entitlement__c):new Set<Id>();
                            entIdd.add(el.Renewed_Entitlement__c);
                            entVsEntLinkIds.put(el.Previous_Entitlement__c,entIdd);
                        }
                    }
                    // Re-query Entitlements filtered by collected CLI IDs
                    for (Entitlement e : 
                            [SELECT Id, ContractLineItemId,Product__c, Product__r.ProductCode, 
                                    Product__r.Product_Level__c, Name, Renewal_Category__c,
                                    Quantity__c, Asset.Name, AssetId, Status, Resync_Line__c,
                                    Product__r.Product_Type__c
                               FROM Entitlement WHERE Id IN :allEntIds])
                    {
                        entVsEntData.put(e.Id, e);
                        if(e.Product__r.Product_Level__c == null){
                            if(e.AssetId != null){assetIds.add(e.AssetId);}
                            oldProductIds.add(e.Product__c);
                        }
                        if (e.Resync_Line__c == ReplacementConstants.RESYNC_LINE_REQUIRED) {
                            if (e.Renewal_Category__c != null) {
                                entVsqty.put(e.Id, 0); 
                                if (e.Renewal_Category__c == ReplacementConstants.UPGRADED || 
                                    e.Renewal_Category__c == ReplacementConstants.CONVERTED ||
                                    e.Renewal_Category__c == ReplacementConstants.DISPOSITION_REASON_REPLACED) {
                                        List<Entitlement> d=cliReplacedENtList.containsKey(e.ContractLineItemId)
                                                           ?cliReplacedENtList.get(e.ContractLineItemId)
                                                           :new List<Entitlement>();
                                        d.add(e);
                                        //to create opportunity product
                                        cliReplacedENtList.put(e.ContractLineItemId,d);
                                    }
                            } else {
                                entVsqty.put(e.Id, e.Quantity__c);
                            }
                            if (e.AssetId != null) {
                                Map<String,String> selectedAssetList=new Map<String,String>();
                                selectedAssetList.put(e.AssetId,e.Asset.Name);
                                entVsAssets.put(e.Id,selectedAssetList);
                            }
                        }
                    }
                    //collect assets for replacement_detail json
                    for(Scale_Entitlement__c sc:
                            [Select id,Asset__r.name,Asset__c,Entitlement__c,
                                    Entitlement__r.Renewal_Category__c,Entitlement__r.Resync_Line__c,
                                    Entitlement__r.Product__c,Entitlement__r.Product__r.Product_Level__c 
                               from Scale_Entitlement__c 
                              WHERE Entitlement__c IN:allEntIds AND Entitlement__r.Renewal_Category__c=null])
                    {
                        if(sc.Entitlement__r.Product__r.Product_Level__c == null){
                            if(sc.Asset__c != null){assetIds.add(sc.Asset__c);}
                            oldProductIds.add(sc.Entitlement__r.Product__c);
                        }
                        Map<String,String> selectedAssetList=entVsAssets.containsKey(sc.Entitlement__c)
                                    ? entVsAssets.get(sc.Entitlement__c):new Map<String,String>(); 
                        selectedAssetList.put(sc.Asset__c,sc.Asset__r.name);
                        entVsAssets.put(sc.Entitlement__c,selectedAssetList);
                    }  
                    if(cliReplacedENtList!=null && !cliReplacedENtList.isEmpty()){
                        for(ContractLineItem cc:
                                    [select Id,ServiceContractId,PricebookEntryId,
                                            SBQQSC__Product__c,SBQQSC__Product__r.Product_Level__c,
                                            SBQQSC__ListPrice__c,UnitPrice,SBQQSC__RenewalQuantity__c 
                                       from ContractLineItem where Id IN: cliReplacedENtList.keySet()]) 
                        {
                            List<ContractLineItem> cList=scVsCLIs.containsKey(cc.ServiceContractId)
                                                        ?scVsCLIs.get(cc.ServiceContractId)
                                                        :new List<ContractLineItem>(); 
                            cList.add(cc); 
                            scVsCLIs.put(cc.ServiceContractId,cList);
                        }
                    }
                    if(assetIds!=null && !assetIds.isEmpty()){
                        for(Asset a:[SELECT Id,Product2Id,Product_Usable_Capacity__c,
                                            SBQQSC__CurrentContractLineItem__c,
                                            SBQQSC__CurrentContractLineItem__r.SBQQSC__RequiredByProduct__c, 
                                            SBQQSC__CurrentContractLineItem__r.SBQQSC__RequiredByProduct__r.Usable_Capacity__c,
                                            SBQQSC__CurrentContractLineItem__r.SBQQSC__Quantity__c 
                                       FROM Asset
                                     WHERE Id IN :assetIds])
                        {assetNameQuantityMap.put(a.Id,a);}
                    }
                    if(oldProductIds!=null && !oldProductIds.isEmpty()){
                        for(Polaris_SKU_Mapping_V2__c p:
                                [SELECT Id,New_Product__c, New_Product__r.Productcode,Old_Product__c,
                                        Old_Product__r.Productcode,Quantity_Ratio__c,Quantity_Mapping_Type__c 
                                   FROM Polaris_SKU_Mapping_V2__c 
                                  WHERE Old_Product__r.IsActive =true 
                                    AND New_Product__r.IsActive =true 
                                    AND Old_Product__c IN : oldProductIds])
                        {sourceSKUPolarisMapping.put(p.Old_Product__c,p);}
                    }
                    
                List<ContractLineItem> cliList= new List<ContractLineItem>();
                List<SBQQ__QuoteLine__c> listofQLILinesTOCalculateV1Qty =new List<SBQQ__QuoteLine__c>();
                List<CPQ_Disposition_Quote_Line__c> listofDisposeLinesTOCalculateV1Qty =
                    new List<CPQ_Disposition_Quote_Line__c>();
                Map<Id,String> clivsV2Product=new Map<Id,String>();//for v2 productcode (ProductId+','+PricebookEntryId)
                Set<Id> EntIdOfRefreshed=new Set<Id>(); // FY25SR-1154
                for(SBQQ__Quote__c ql:scope){
                    if(ql.SBQQ__Status__c==ReplacementConstants.STATUS_APPROVED){
                        quoteApproved.add(ql.Id);// all the approved or In Review quote Ids.
                    }
                    if(ql.SBQQ__Status__c==ReplacementConstants.STATUS_IN_REVIEW){
                        InReviewQuotes.add(ql.Id);
                        quoteApproved.add(ql.Id);
                    }
                    // creation of Closed admin - replaced opportunity.
                    Set<Id> scIds=(qscVSqlisc!=null && 
                                                qscVSqlisc.containsKey(quote.Amended_Renewed_Service_Contract__c))?
                                                qscVSqlisc.get(quote.Amended_Renewed_Service_Contract__c):null;
                     if(scIds!=null && !scIds.isEmpty()){
                        for(Id sc:scIds){
                            if(!serviceContractIds.contains(sc) && 
                               scVsCLIs!=null && !scVsCLIs.isEmpty() &&  
                               scVsCLIs.containsKey(sc))
                            { 
                                Boolean isPartial=false;
                                cliList =scVsCLIs.containsKey(sc)
                                    ?scVsCLIs.get(sc):null;
                                if(cliList!=null && !cliList.isEmpty()){
                                    for (ContractLineItem c : cliList) {
                                        if(c.SBQQSC__RenewalQuantity__c!=0)
                                        {
                                            isPartial=true;
                                            break;
                                        } 
                                    }
                                }
                                closedAdminOpp=createOpportunity(quote.SBQQ__Opportunity2__c,isPartial,sc);
                                //insert
                                serviceContractIds.add(sc);
                                //opp. product
                            }
                        }
                    }
                    //insert
                    Set<Id> entIdsPresentInQLI=new Set<Id>();
					
                    //Updating QLI qty for opp.stage 5 and below
                    if(updateqLIList!=null && !updateqLIList.isEmpty()){
                        for(SBQQ__QuoteLine__c qli:updateqLIList){
                            boolean isV1sku=false;
                            String strNew=null;
                            String newCCLILIST=null;
                            Decimal qtyreduced=0;
                            String changeAssets;//added
                            Boolean isRefreshedhwsprt=false;
                            Decimal qtyOfRefreshhwsprt=0;
                            ReplacementJson qliReplaceJSON=new ReplacementJson();//added
                            List<String> newCCLI=new List<String>();
                            Map<Id,Decimal> cliReducedQty=new Map<Id,Decimal>();
							Set<Id> entIdsToMarkComplete=new Set<Id>();//qliVsEntIds
                            qLIQuoteId.put(qli.Id,qli.SBQQ__Quote__c);
                            
                            if(qli.Arroyo_Subsumed_Old_Contract_Line_Items__c!=Null && qli.Replacement_Details__c!=null){
                                List<ReplacementJson.RowDetail> newRowValues= new List<ReplacementJson.RowDetail>();
                                qliReplaceJSON = (ReplacementJson)JSON.deserialize(
                                                        qli.Replacement_Details__c, ReplacementJson.class);
                                if (qliReplaceJSON != null && qliReplaceJSON.rowValues != null) {
                                    for (ReplacementJson.RowDetail childRow : qliReplaceJSON.rowValues) {
                                        if (childRow.entId == null) continue;
                                        
                                        //to mark ent as Completed after processing
                                        if(entVsEntLinkIds!=null && entVsEntLinkIds.containsKey(childRow.entId)){
                                           entIdsToMarkComplete.addAll(entVsEntLinkIds.get(childRow.entId));
                                        }
                                        else{entIdsToMarkComplete.add(childRow.entId);}
                                        //end
                                        if(entVsEntData.get(childRow.entId).Product__r.Product_Level__c == null)
                                        {
                                            clivsV2Product.put(qli.SBQQSC__RenewedContractLine__c,
                                                    (qli.SBQQ__Product__c+','+qli.SBQQ__PricebookEntryId__c));
                                            if(entVsEntData.get(childRow.entId).Product__r.Product_Type__c 
                                                    !=ReplacementConstants.HW_SUPPORT)
                                            {isV1sku= true;}
                                        }
                                        List<Id> linkedEntIds = (entLinks != null && entLinks.containsKey(childRow.entId)) 
                                            ? entLinks.get(childRow.entId) 
                                            : new List<Id>{childRow.entId};
                                        for (Id entId : linkedEntIds) {
                                            if (!entVsqty.containsKey(entId)) continue;
                                            Id cliId = entVsEntData.get(entId).ContractLineItemId;
                                            Decimal qty = entVsqty.get(entId);
                                            Decimal currentQty = cliReducedQty.containsKey(cliId) 
                                                               ? cliReducedQty.get(cliId) : 0;
                                            cliReducedQty.put(cliId, currentQty + qty);
                                            entIdsPresentInQLI.add(childRow.entId);
                                            qtyreduced += qty;
                                            if(entVsEntData.get(entId).Renewal_Category__c ==ReplacementConstants.REFRESHED 
                                               && entVsEntData.get(entId).Product__r.Product_Type__c ==ReplacementConstants.HW_SUPPORT )
                                            {
                                                isRefreshedhwsprt=true;
                                                qtyOfRefreshhwsprt +=entVsEntData.get(childRow.entId).Quantity__c;
                                                EntIdOfRefreshed.add(entId);
                                            }    
                                            if (qty == 0) continue;
                                            childRow.entId = entId;
                                            childRow.selectedQty = (Integer) qty;
                                            if (entVsAssets.containsKey(entId)) {
                                                childRow.selectedAsset = new List<String>(entVsAssets.get(entId).keySet())[0];//change
                                                childRow.selectedAssetList = entVsAssets.get(entId);
                                                String assetNames = String.join(new List<String>(entVsAssets.get(entId).values()), ',');
                                                changeAssets = (changeAssets == null) 
                                                    ? assetNames : changeAssets + ',' + assetNames;
                                            }
                                            newRowValues.add(childRow);
                                        }
                                        
                                        // If entId not found in entVsqty or entLinks
                                        if (!entVsqty.containsKey(childRow.entId) && (entLinks == null || !entLinks.containsKey(childRow.entId)) && (entVsEntLinkIds==null || !entVsEntLinkIds.containsKey(childRow.entId))){//Khushboo added
                                            qtyreduced +=entVsEntData.get(childRow.entId).Quantity__c;
                                            Id cliId = entVsEntData.get(childRow.entId).ContractLineItemId;
                                            Decimal qty = entVsEntData.get(childRow.entId).Quantity__c;
                                            Decimal currentQty = cliReducedQty.containsKey(cliId) ? cliReducedQty.get(cliId) : 0;
                                            cliReducedQty.put(cliId, currentQty + qty);
                                            childRow.selectedQty=Integer.valueOf(qty);
                                            newRowValues.add(childRow);
                                            if (childRow.selectedAssetList != null) {
                                                String assetNames = String.join(new List<String>(childRow.selectedAssetList.values()), ',');
                                                changeAssets = (changeAssets == null) ? assetNames : changeAssets + ',' + assetNames;
                                            }
                                        }
                                    }
                                    
                                    if (!newRowValues.isEmpty()) {
                                        qliReplaceJSON.rowValues = new List<ReplacementJson.RowDetail>(newRowValues);
                                    }
                                }
                                 if(qli.CCLI__C!=null){ 
                                    List<String> ccliStr=qli.CCLI__C.split(',');
                                    for(String str1:ccliStr){
                                        str1=str1.trim();
                                        if(cliReducedQty!=null && cliReducedQty.containsKey(str1) && cliReducedQty.get(str1)!=0)
                                        {
                                            if(strNew==Null && cliReducedQty.get(qli.SBQQSC__RenewedContractLine__c)==0)
                                            {strNew=str1; deleteCCLiSet.add(str1);}
                                            else{ newCCLI.add(str1);}
                                        }
                                        else if(cliReducedQty!=null && cliReducedQty.get(str1)==0)
                                        { 
                                            deleteCCLiSet.add(str1); 
                                           }
                                    }
                                }
                                if(newCCLI!=null && !newCCLI.isEmpty()){
                                    newCCLIList=String.join(newCCLI,',');
                                   } 
                            }
                            if(entIdsToMarkComplete!=null && !entIdsToMarkComplete.isEmpty()){
							qliVsEntIds.put(qli.Id,entIdsToMarkComplete);
							}
							
                                SBQQ__QuoteLine__c qlupdate=new SBQQ__QuoteLine__c();
                                qlupdate.id=qli.id;
                                if(qtyreduced==0 && 
                                   qlupdate.Disposition_Reason__c != ReplacementConstants.DISPOSITION_REASON_R_E_TRANSACTED)
                                {
                                    //logic if renewal qty. reduced to zero 
                                    qlupdate.Related_Asset_Total_Capacity__c=0;
                                    qlupdate.SBQQ__Quantity__c=0;
                                     if(qli.SBQQ__BundledQuantity__c!=null)
                                    qlupdate.SBQQ__BundledQuantity__c=null;
                                    qlupdate.SBQQ__Optional__c=true;
                                    qlupdate.SBQQ__Existing__c=true;
                                    qlupdate.Disposition_Reason__c=ReplacementConstants.DISPOSITION_REASON_R_E_TRANSACTED;
                                    qlupdate.RWD_Expected_Default_Quantity__c=0;
                                    qlupdate.SBQQ__PriorQuantity__c=0;
                                    qlupdate.Replacement_Details__c =null;
                                    if(isRefreshedhwsprt==true){
                                        qlupdate.Disposition_Reason__c=ReplacementConstants.REFRESHED;   
                                    }
                                    updateQtyOnQLi.add(qlupdate);  
                                }
                                else{
                                    //logic if renewal qty. reduced but not equal to zero  
                                    if(strNew!=null && cliReducedQty.get(qli.SBQQSC__RenewedContractLine__c)==0){
                                        qlupdate.SBQQSC__RenewedContractLine__c=strNew;
                                    }
                                    qlupdate.CCLI__c=newCCLIList;
                                    if(qli.SBQQ__BundledQuantity__c!=null)
                                    qlupdate.SBQQ__BundledQuantity__c=null;
                                    qlupdate.SBQQ__Quantity__c=qtyreduced;
                                    qlupdate.SBQQ__PriorQuantity__c=qtyreduced;
                                    qlupdate.RWD_Expected_Default_Quantity__c=qtyreduced;
                                    qlupdate.Subscribed_Asset_Name__c= changeAssets!=null? changeAssets:null;  
                                    qlupdate.SubscribedAssetNames__c= changeAssets!=null? changeAssets:null; 
                                    qlupdate.Replacement_Details__c = qliReplaceJSON!=null
                                            ? JSON.serialize(qliReplaceJSON):null;
                                    if(qlupdate.CCLI__c!=null){//added Khushboo start
                                    qlupdate.Arroyo_Subsumed_Old_Contract_Line_Items__c= 
                                    qlupdate.SBQQSC__RenewedContractLine__c==null ? (qli.SBQQSC__RenewedContractLine__c +','+ qlupdate.CCLI__c) : (qlupdate.SBQQSC__RenewedContractLine__c+ ',' +qlupdate.CCLI__c);
                                    }
                                    else
                                    {
                                    qlupdate.Arroyo_Subsumed_Old_Contract_Line_Items__c= qlupdate.SBQQSC__RenewedContractLine__c==null 
                                          ? qli.SBQQSC__RenewedContractLine__c : qlupdate.SBQQSC__RenewedContractLine__c;  
                                    }//added Khushboo end
                                    if(isRefreshedhwsprt==true){
                                        qlupdate.Disposition_Reason__c=ReplacementConstants.REFRESHED; 
                                        if(qtyOfRefreshhwsprt > 0){
                                            SBQQ__QuoteLine__c newRefreshedQli= qlupdate.clone(false, true, false, false); 
                                            qlupdate.SBQQ__Quantity__c=qtyOfRefreshhwsprt;
                                            qlupdate.SBQQ__PriorQuantity__c=qtyOfRefreshhwsprt;
                                            qlupdate.RWD_Expected_Default_Quantity__c=qtyOfRefreshhwsprt;
                                            qlupdate.Subscribed_Asset_Name__c=null;  
                                            qlupdate.SubscribedAssetNames__c=null; 
                                            qlupdate.Replacement_Details__c =null;
                                            updateQtyOnQLi.add(newRefreshedQli);
                                        }
                                    }
                                    if(isV1sku == true){
                                        listofQLILinesTOCalculateV1Qty.add(qlupdate);
                                    }
                                    updateQtyOnQLi.add(qlupdate);  
                                }
                           }
                    } 
                     if(updatecpqDliList!=null && !updatecpqDliList.isEmpty()){
                        for(CPQ_Disposition_Quote_Line__c qli:updatecpqDliList){
                            cpqQuoteId.put(qli.Id,qli.Quote__c);
                            Boolean isDeleted=false;
                            Boolean updateQLi=false;
                            Decimal qtyreduced=0;
                            Boolean isV1sku=false;
                            ReplacementJson qliReplaceJSON=new ReplacementJson();//added
                            String changeAssets;//added
							Set<Id> entIdstoMarkComplete=new Set<Id>();
                            if(qli.Replacement_Detail__c!=null){
                                List<ReplacementJson.RowDetail> newRowValues= new List<ReplacementJson.RowDetail>();
                                qliReplaceJSON = 
                                    (ReplacementJson)JSON.deserialize(qli.Replacement_Detail__c, ReplacementJson.class);
                                if (qliReplaceJSON != null && qliReplaceJSON.rowValues != null){
                                    for (ReplacementJson.RowDetail childRow : qliReplaceJSON.rowValues){
                                        if(childRow.entId !=null)
                                        {
                                            //to mark ent as Completed after processing
                                            if(entVsEntLinkIds!=null && entVsEntLinkIds.containsKey(childRow.entId)){
                                                entIdstoMarkComplete.addAll(entVsEntLinkIds.get(childRow.entId));
                                            }
                                            else{entIdstoMarkComplete.add(childRow.entId);}
                                            //end
                                            if(entVsEntData.get(childRow.entId).Product__r.Product_Level__c == null)
                                            {
                                                clivsV2Product.put(qli.RenewedContractLine__c,
                                                        (qli.Product__c+','+qli.PricebookEntryId__c));
                                                if(entVsEntData.get(
                                                        childRow.entId)
                                                    .Product__r.Product_Type__c !=ReplacementConstants.HW_SUPPORT)
                                                {isV1sku= true;}
                                            }
                                            if(entIdsPresentInQLI.contains(childRow.entId)){
                                                isDeleted=true;
                                                deleteCPQdli.add(qli);//delete lines 
                                                break;
                                            }
                                            else if(entLinks!=null && entLinks.containsKey(childRow.entId))
                                            { //partial replacement/renewal -need to reduce the qty
                                                for(Id idd:entLinks.get(childRow.entId)){
                                                    if(entVsqty.containsKey(idd)){
                                                        updateQLi=true;
                                                        Decimal qty=entVsqty.get(idd);
                                                        qtyreduced+= qty;
                                                        if(qty!=0){
                                                            entIdsPresentInQLI.add(childRow.entId);
                                                            childRow.entId=idd;
                                                            childRow.selectedQty= (Integer)qty;
                                                            childRow.selectedAsset=entVsAssets.containsKey(idd)?  new List<String>(entVsAssets.get(idd).keySet())[0]
                                                                :null;
                                                            childRow.selectedAssetList=entVsAssets.containsKey(idd) ? entVsAssets.get(idd)
                                                                :null;
                                                            newRowValues.add(childRow);
                                                            String assetNames = entVsAssets.containsKey(idd)?String.join(new List<String>(entVsAssets.get(idd).values()), ',') :null;
                                                            changeAssets = (changeAssets == null) 
                                                                ? assetNames : changeAssets + ',' + assetNames;
                                                            //collect assets
                                                        }
                                                    } 
                                                }
                                            }
                                            else {
                                                if(entVsqty!=null && entVsqty.containsKey(childRow.entId)){
                                                    updateQLi=true;
                                                    entIdsPresentInQLI.add(childRow.entId);
                                                    Decimal qty=entVsqty.get(childRow.entId);
                                                    qtyreduced+= (Integer)qty;
                                                }
                                            }
                                        }
                                    }
                                    if(newRowValues!=null  && !newRowValues.isEmpty()){
                                        qliReplaceJSON.rowValues = new List<ReplacementJson.RowDetail>();
                                        qliReplaceJSON.rowValues.addAll(newRowValues);
                                    }
                                }
                            }
                            if(updateQLi == true){
                                if(qtyreduced==0 && isDeleted==false){
                                    deleteCPQdli.add(qli);//delete lines
                                }
                                else{
                                    if(entIdstoMarkComplete!=null && !entIdstoMarkComplete.isEmpty()){
                                        cpqliVsEntIds.put(qli.Id,entIdstoMarkComplete);
                                    }
                                    CPQ_Disposition_Quote_Line__c cpqDlines=
                                        new CPQ_Disposition_Quote_Line__c(Id=qli.Id, Quantity__c=qtyreduced);
                                    cpqDlines.Replacement_Detail__c=
                                        qliReplaceJSON!=null? JSON.serialize(qliReplaceJSON):null;
                                    cpqDlines.Arroyo_Subscribed_Asset_Name__c=changeAssets!=null?changeAssets:null;
                                    if(isV1sku == true){
                                        listofDisposeLinesTOCalculateV1Qty.add(cpqDlines);
                                    }
                                    updateQtyOncpqDLi.add(cpqDlines);
                                }
                            }
                         }
                    }
                } 
                if(!listofDisposeLinesTOCalculateV1Qty.isEmpty() || !listofQLILinesTOCalculateV1Qty.isEmpty()){
                    calculateQuantity(
                        listofQLILinesTOCalculateV1Qty,listofDisposeLinesTOCalculateV1Qty,
                        assetNameQuantityMap,sourceSKUPolarisMapping,entVsEntData);  
                }
                //start FY25SR-1154
                Map<String, SBQQ__QuoteLine__c> qliMap =new Map<String, SBQQ__QuoteLine__c>();
                if(EntIdOfRefreshed!=null && !EntIdOfRefreshed.isEmpty()){
                    List<SBQQ__QuoteLine__c> refreshedQliUpdate=
                        OpportunityClosedAdminHelperClass.getLicenseLinesPostAssetRefresh(EntIdOfRefreshed);
                        if(refreshedQliUpdate!=null && !refreshedQliUpdate.isEmpty()){
                             for (SBQQ__QuoteLine__c qli : refreshedQliUpdate) {
                                    qliMap.put(qli.Id, qli);
                                }
                             if(updateQtyOnQLi.isEmpty()){
                                updateQtyOnQLi.addAll(refreshedQliUpdate); 
                            }
                            else{
                                Set<Id> existingIds = new Set<Id>();
                                for (SBQQ__QuoteLine__c updateLine : updateQtyOnQLi){
                                    existingIds.add(updateLine.Id);
                                    if(updateLine.SBQQ__Quantity__c!=0){
                                        if (qliMap!=null && qliMap.containsKey(updateLine.Id)) {
                                            updateLine.Subscribed_Asset_Name__c=qliMap.get(updateLine.Id).Subscribed_Asset_Name__c;
                                            updateLine.SubscribedAssetNames__c=qliMap.get(updateLine.Id).SubscribedAssetNames__c;
                                            ReplacementJson qliRefreshJSON =  (ReplacementJson)JSON.deserialize(
                                                    qliMap.get(updateLine.Id).Replacement_Details__c, ReplacementJson.class);
                                            for (ReplacementJson.RowDetail childRow : qliRefreshJSON.rowValues) {
                                                childRow.selectedQty=(Integer)updateLine.SBQQ__Quantity__c;
                                            }
                                            updateLine.Replacement_Details__c= JSON.serialize(qliRefreshJSON);
                                        }
                                    }
                                }
                                if(existingIds!=null){
                                    for (SBQQ__QuoteLine__c refreshedLine : refreshedQliUpdate) {
                                        if (!existingIds.contains(refreshedLine.Id)) {
                                            updateQtyOnQLi.add(refreshedLine);
                                        }
                                    }
                                }
                            }
                        }
                }
                    //end FY25SR-1154
                    ShGl_DisableBusinessLogic__c csInstanceToUpdate,
                        csInstanceToDelete = null;
                    List<ShGl_DisableBusinessLogic__c> dflList = 
                        [SELECT Id, Disable_SBQQ_QuoteLine_Validation_Rules__c,
                                Disable_Opportunity_Validation_Rules__c, Name, SetupOwnerId 
                           FROM ShGl_DisableBusinessLogic__c WHERE SetupOwnerId = :UserInfo.getUserId()];
                    if (dflList.isEmpty()) {
                        csInstanceToDelete = new ShGl_DisableBusinessLogic__c();
                        csInstanceToDelete.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
                        csInstanceToDelete.Disable_Opportunity_Validation_Rules__c = true;
                        csInstanceToDelete.SetupOwnerId = userinfo.getUserId();
                        insert csInstanceToDelete;
                    } else {
                        if (!dflList[0].Disable_SBQQ_QuoteLine_Validation_Rules__c) {
                            csInstanceToUpdate = dflList[0];
                            csInstanceToUpdate.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
                            csInstanceToUpdate.Disable_Opportunity_Validation_Rules__c = true;
                            csInstanceToUpdate.SetupOwnerId = userinfo.getUserId();
                            update csInstanceToUpdate;
                        }
                }
                  
                if(closedAdminOpp!=null){
                    //disable Opportunity trigger
                    flowControll.opportunityTriggerHandler = false;
                    flowControll.opportunityLineItemHandler = false;
                    Database.SaveResult saveResultsopp=Database.insert(closedAdminOpp,false);
                    if(!saveResultsopp.isSuccess())
                    {
                      adderrorLogs(batchErrLogList,errorsnewSCList,batchableContext.getJobId(),saveResultsopp);
                    }
                   }
                
                //create opportunity product
                if(cliList!=null && !cliList.isEmpty()){
                    for (ContractLineItem c : cliList) {
                        if(cliReplacedENtList.containsKey(c.Id)){
                            String prdIdandPBEID= 
                                (clivsV2Product!=null && clivsV2Product.containsKey(c.Id))
                                ?clivsV2Product.get(c.Id):null;
                            closedAdminOppProducts.add(
                                createOpportunityProduct(
                                    closedAdminOpp.Id,cliReplacedENtList.get(c.Id),
                                    c,prdIdandPBEID,assetNameQuantityMap,sourceSKUPolarisMapping
                                ));
                         }   
                    }   
                }
                //Disable OpportunityProduct triggers
                if(closedAdminOppProducts!=null && !closedAdminOppProducts.isEmpty()){
                    flowControll.opportunityTriggerHandler = false;
                    flowControll.opportunityLineItemHandler = false;
                    List<Database.SaveResult> saveResults = Database.insert(closedAdminOppProducts,false);  
                    for (Database.SaveResult sr :saveResults){
                        if(!sr.isSuccess())
                        {
                           adderrorLogs(batchErrLogList,errorsnewSCList,batchableContext.getJobId(),sr);
                        }
                        
                    }
                } 
            //1730 Khushboo
            if(closedAdminOpp!=null && closedAdminOpp.Id!=null && closedAdminOppProducts!=null && 
             !closedAdminOppProducts.isEmpty()){
                Set<Id> oppId=new Set<Id>();
                oppId.add(closedAdminOpp.Id);
                quoteIDs.addAll(OpportunityClosedAdminHelperClass.buildQuotesAndLines(oppId,null));
            }
            //end 1730 Khushboo
                
                //delete CPQ Dispose lines if any
                if(deleteCPQdli!=null && !deleteCPQdli.isEmpty()){
                    Database.delete(deleteCPQdli);
                }
                //Disable quoteTriggers
                TriggerControls.disableQuoteTrigger = true;
                TriggerControls.disableQuoteLineTrigger = true;
                SBQQ.TriggerControl.disable();
                //delete Consolidated ContractLine items record where Contract_Line_Item__c's renewal qty=0
                if(deleteCCLiSet!=null && !deleteCCLiSet.isEmpty()){
                    deleteCCLi=[Select id,Quote_Line__c,Contract_Line_Item__c,Quote__c 
                                  from Consolidated_Contract_Lines__c 
                                 WHERE Contract_Line_Item__c IN:deleteCCLiSet AND  Quote__c=:quote.Id]; 
                }
                if(deleteCCLi!=null && !deleteCCLi.isEmpty()){
                    Database.delete(deleteCCLi, false);
                }
                
                //delete all the approval records
                if(InReviewQuotes!=null){
                    for(sbaa__Approval__c aa:
                        [Select id,Quote__c from sbaa__Approval__c where Quote__c IN: InReviewQuotes]){
                        deleteInReview.add(aa);
                    }
                    if(deleteInReview!=null && !deleteInReview.isEmpty()){
                        Database.delete(deleteInReview, false);
                    }
                }
                //Change status to Draft
                if(quoteApproved!=Null && !quoteApproved.isEmpty()){
                    for(Id idd:quoteApproved){
                        SBQQ__Quote__c qtObj = 
                            new SBQQ__Quote__c (Id = idd, SBQQ__Status__c = ReplacementConstants.STATUS_DRAFT,  
                                                ApprovalStatus__c = '');
                        qlList.add(qtObj);  
                    }
                    if(qlList!=null && !qlList.isEmpty()){
                        Database.update(qlList, false);
                    }
                }
                //update CPQ Dispose lines
                if(updateQtyOncpqDLi!=null && !updateQtyOncpqDLi.isEmpty()){
                    List<Database.SaveResult> saveResults = Database.update(updateQtyOncpqDLi, false); 
                    for (Database.SaveResult sr :saveResults){
                        if(sr.isSuccess()){
                            //set of success CLIs
                            successEntIds.addAll(cpqliVsEntIds.get(sr.getId()));
                            quoteIDs.add(cpqQuoteId.get(sr.getId()));// all the quote Ids
                        }  
                        else if(!sr.isSuccess())
                        {
                            //set of failed CLIs
                            failedEntIds.addAll(cpqliVsEntIds.get(sr.getId()));
                            //Added batch error log for failed records
                            adderrorLogs(batchErrLogList,errorsnewSCList,batchableContext.getJobId(),sr);
                        }
                    }
                }
                if(updateQtyOnQLi!=null && !updateQtyOnQLi.isEmpty()){
                    List<Database.SaveResult> saveResults = Database.update(updateQtyOnQLi, false);
                    for (Database.SaveResult sr :saveResults){
                        if(sr.isSuccess()){
                            //set of success CLIs
                            if(qliVsEntIds.containsKey(sr.getId())){successEntIds.addAll(qliVsEntIds.get(sr.getId()));} 
                            quoteIDs.add(qLIQuoteId.get(sr.getId()));// all the quote Ids
                        }  
                        else if(!sr.isSuccess())
                        {
                            //set of failed CLIs
                            failedEntIds.addAll(qliVsEntIds.get(sr.getId()));
                            //Added batch error log for failed records
                            adderrorLogs(batchErrLogList,errorsnewSCList,batchableContext.getJobId(),sr);
                        }
                    }
                }
                if (csInstanceToDelete!=null) {
                    delete csInstanceToDelete;
                }
                    
                if (csInstanceToUpdate!=null) {
                    csInstanceToUpdate.Disable_Opportunity_Validation_Rules__c = false;
                    csInstanceToUpdate.Disable_SBQQ_QuoteLine_Validation_Rules__c = false;
                    update csInstanceToUpdate;
                }
                try{
                    if(batchErrLogList!=null && !batchErrLogList.isEmpty()){
                        upsert batchErrLogList; 
                    }
                    if (Test.isRunningTest()) {
                        throw new NullPointerException();
                    }
                }
                catch(exception e){
                    errorsnewSCList.add('</b> ::'+ e.getStackTraceString()+' ' + JSON.serialize(e.getMessage()));
                }
            }
         }
        }
        catch(exception e)
        {errorsnewSCList.add('</b> ::'+ e.getStackTraceString()+' '+ JSON.serialize(e.getMessage()));}
    }
    /**
    * @description Batch Job to update the Quantity on Quote line items-Finish method
    * @param batchableContext
    **/
    public void finish(Database.BatchableContext batchableContext){
        List<Entitlement> updateENTStatus = new List<Entitlement>();//added
        ShGl_DisableBusinessLogic__c csInstanceToUpdate,
            csInstanceToDelete = null;
        List<ShGl_DisableBusinessLogic__c> dflList = 
            [SELECT Id, Disable_Entitlement_Validation_Rules__c, Name, SetupOwnerId 
              FROM ShGl_DisableBusinessLogic__c WHERE SetupOwnerId = :UserInfo.getUserId()];
        if (dflList.isEmpty()) {
            csInstanceToDelete = new ShGl_DisableBusinessLogic__c();
            csInstanceToDelete.Disable_Entitlement_Validation_Rules__c = true;
            csInstanceToDelete.SetupOwnerId = userinfo.getUserId();
            insert csInstanceToDelete;
        } else {
            if (!dflList[0].Disable_Entitlement_Validation_Rules__c) {
                csInstanceToUpdate = dflList[0];
                csInstanceToUpdate.Disable_Entitlement_Validation_Rules__c = true;
                csInstanceToUpdate.SetupOwnerId = userinfo.getUserId();
                update csInstanceToUpdate;
            }
        }
        Set<Id> removeIds=new Set<Id>();
         if(failedEntIds!=null && !failedEntIds.isEmpty()){
                for(Id entIds:failedEntIds){
                    removeIds.add(entIds);
                    Entitlement eUpdate=new Entitlement(Id=entIds, Resync_Line__c=ReplacementConstants.RESYNC_LINE_MANUAL_REVIEW_REQUIRED);
                    updateENTStatus.add(eUpdate);   
                }
          }
        if(successEntIds!=null && !successEntIds.isEmpty()){
            for(Id entIds:successEntIds){
                //Checking if all the QLIs are updating successfully to check the CLI id in successEntIds set
                if((removeIds!=null && !removeIds.contains(entIds)) || removeIds==null ){
                    Entitlement eUpdate=new Entitlement(Id=entIds,Resync_Line__c=ReplacementConstants.COMPLETED);
                    updateENTStatus.add(eUpdate); }   
              }  
        }
        
        
        if(updateENTStatus!=null && !updateENTStatus.isEmpty())
        {
            Database.update(updateENTStatus,false);
        }
        if (csInstanceToDelete != null ) {
            delete csInstanceToDelete;
        }
        if (csInstanceToUpdate != null) {
                csInstanceToUpdate.Disable_Entitlement_Validation_Rules__c = false;
                update csInstanceToUpdate;
            }
        Messaging.SingleEmailMessage emailmessage = new Messaging.SingleEmailMessage();
        //CPQ22-4074 starts
        String strEmails = System.Label.ServiceContractRenewalForecastBatch_Emails;
        // String strEmails ='khushboo.agrawal@rubrik.com';
        String strCPQAdmin = System.Label.CPQAdminEmailId;
        String[] toAddresses = !String.isBlank(strEmails) ? strEmails.split(',') : new List<String>{strCPQAdmin};
            emailmessage.setToAddresses(toAddresses);
        emailmessage.setSubject('BatchToUpdateQLIQty Errors - ' + Date.today().format());
        String Message = 'Below is a list of the Service Contracts that failed'
                       + ' to update renewal quantity on QLI: <br/><br/>';
        if(Test.isRunningTest()){
            errorsnewSCList.add('Failed due to Null PointerException');
        }
        if(!errorsnewSCList.isEmpty()) {
            Message += '<b>CLI Renewal Qty updated today:</b> <br/>';
            for(String eachError : errorsnewSCList) {
                Message += eachError + '<br/>';
            }
            Message += '<br/>';
        }
        Message += '<br/>Thank you';
        emailmessage.setHtmlBody(Message);
        
        if (!test.isRunningTest() && (!errorsnewSCList.isEmpty() )) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { emailmessage });
         }
        if(!test.isRunningTest() && (quoteIDs!=null || quoteApproved!=null)){
            QuoteCalculateAndSubmitBatch RQC=new QuoteCalculateAndSubmitBatch(quoteIDs,quoteApproved);
            Database.executeBatch(RQC,1);
        }
    }
    /**
    * @description Batch Job to update the Quantity on Quote line items-Execute method
    * @param schedulableContext
    **/
    public void execute(SchedulableContext schedulableContext) {
        BatchToUpdateQLIQty bC = new BatchToUpdateQLIQty();
        Database.executeBatch(bC,1);
    }
    /**
    * @description Helper function to clone the opportunity
    * @param opportunityId
    * @param isPartial
    * @param scId
    * @return clonedOpportunity
    **/ 
    public Opportunity createOpportunity(Id opportunityId,Boolean isPartial,Id scId) {
        Opportunity clonedOpportunity= new Opportunity();
        if(isPartial==true){
            clonedOpportunity =
                OpportunityClosedAdminHelperClass.cloneOpportunity(
                    opportunityId, OpportunityClosedAdminHelperClass.CloneType.PARTIAL_REPLACEMENT);
        }
        else
        {
            clonedOpportunity =
                OpportunityClosedAdminHelperClass.cloneOpportunity(
                    opportunityId, OpportunityClosedAdminHelperClass.CloneType.FULL_REPLACEMENT);
        }
        clonedOpportunity.SBQQSC__RenewedServiceContract__c =scId;
        return clonedOpportunity;
    }
    /**
    * @description Helper function to create the opportunity product 
    * @param opportunityId
    * @param entList
    * @param cli
    * @param prodIdANDPbeId
    * @param assetNameQuantityMap
    * @param sourceSKUPolarisMapping
    * @return oppProduct
    **/
    public OpportunityLineItem createOpportunityProduct(Id opportunityId, List<Entitlement> entList, 
           ContractLineItem cli,String prodIdANDPbeId,Map<Id,Asset> assetNameQuantityMap,
           Map<Id,Polaris_SKU_Mapping_V2__c> sourceSKUPolarisMapping) {
        Decimal renewalQuantity = 0;
        Id prodId,priceBookId;
        List<String> idds=new List<String>();
        if (entList != null && !entList.isEmpty()) {
            for (Entitlement e : entList) {
                Boolean isProductV1 = (e.Product__r != null && e.Product__r.Product_level__c == null);
                Boolean hasAsset = (e.AssetId != null && assetNameQuantityMap.containsKey(e.AssetId));
                
                if (isProductV1) {
                    if (hasAsset) {
                        Asset asset = assetNameQuantityMap.get(e.AssetId);
                        renewalQuantity += getUsableCapacityFromAsset(asset);
                    } else {
                        String oldProd = e.Product__c;
                        if (oldProd != null && sourceSKUPolarisMapping.containsKey(oldProd) && 
                            sourceSKUPolarisMapping.get(
                                oldProd
                            ).Quantity_Mapping_Type__c == ReplacementConstants.PRODUCT_QTY_MAPPING_TYPE) {
                            renewalQuantity += e.Quantity__c * sourceSKUPolarisMapping.get(oldProd).Quantity_Ratio__c;
                        } else {
                            renewalQuantity += e.Quantity__c;
                        }
                    }
                } else {
                    renewalQuantity += e.Quantity__c;
                }
            }
        }
        if(prodIdANDPbeId!=null){
            idds=prodIdANDPbeId.split(',');
        }
        if(!idds.isEmpty() && idds[0].trim() != 'null' && idds[1].trim() != 'null'){
            prodId =  idds[0].trim();
            priceBookId=  idds[1].trim();
        }
        else{
            prodId= cli.SBQQSC__Product__c;
            priceBookId= cli.PricebookEntryId;
        }
        OpportunityLineItem oppProduct = new OpportunityLineItem();
        oppProduct.OpportunityId = opportunityId;
        oppProduct.Quantity = renewalQuantity;
        oppProduct.Product2Id=prodId;
        oppProduct.Amended_Service_Contract_Id_Text__c=cli.ServiceContractId;
        oppProduct.ContractLine_Id__c = cli.Id;
        oppProduct.pricebookentryid= priceBookId;
        oppProduct.TotalPrice=renewalQuantity*cli.SBQQSC__ListPrice__c;
        return oppProduct;
    }
    /**
    * @description calculateQuantity Helper function to calculate qty of v1 sku 
    * @param qLIList
    * @param cpqDisposeLine
    * @param assetNameQuantityMap
    * @param sourceSKUPolarisMapping
    * @param entVsEntData
    **/
    public void calculateQuantity(List<SBQQ__QuoteLine__c> qLIList, 
                List<CPQ_Disposition_Quote_Line__c> cpqDisposeLine,
                Map<Id,Asset> assetNameQuantityMap,
                 Map<Id,Polaris_SKU_Mapping_V2__c> sourceSKUPolarisMapping,
                 Map<Id,Entitlement> entVsEntData) {
        if (qLIList != null) {
            for (SBQQ__QuoteLine__c qli : qLIList) {
                if (qli != null && qli.Replacement_Details__c != null) {
                    Decimal quantity = 
                        computeQuantityFromJson(
                            qli.Replacement_Details__c,assetNameQuantityMap,
                            sourceSKUPolarisMapping,entVsEntData);
                    qli.SBQQ__Quantity__c = quantity;
                    qli.SBQQ__PriorQuantity__c = quantity;
                    qli.RWD_Expected_Default_Quantity__c = quantity;
                }
            }
        }
        
        if (cpqDisposeLine != null) {
            for (CPQ_Disposition_Quote_Line__c cdli : cpqDisposeLine) {
                if (cdli != null && cdli.Replacement_Detail__c != null) {
                    Decimal quantity = 
                        computeQuantityFromJson(
                            cdli.Replacement_Detail__c,assetNameQuantityMap,
                            sourceSKUPolarisMapping,entVsEntData);
                    cdli.Quantity__c = quantity;
                }
            }
        }
    }

    /**
    * @description computeQuantityFromJson Helper function to process replacementJson 
    * @param jsonString
    * @param assetNameQuantityMap
    * @param sourceSKUPolarisMapping
    * @param entVsEntData
    * @return totalQuantity
    **/
    public Decimal computeQuantityFromJson(String jsonString,Map<Id,Asset> assetNameQuantityMap, 
            Map<Id,Polaris_SKU_Mapping_V2__c> sourceSKUPolarisMapping,Map<Id,Entitlement> entVsEntData) {
        Decimal totalQuantity = 0;
        ReplacementJson replaceJson = (ReplacementJson) JSON.deserialize(jsonString, ReplacementJson.class);
        if (replaceJson == null || replaceJson.rowValues == null) return totalQuantity;
        
        for (ReplacementJson.RowDetail row : replaceJson.rowValues) {
            if (row.selectedAsset != null) {
                for (String assetId : row.selectedAsset.split(',')) {
                    assetId = assetId.trim();
                    if (!assetNameQuantityMap.isEmpty() && assetNameQuantityMap.containsKey(assetId)) {
                        Asset asset = assetNameQuantityMap.get(assetId);
                        totalQuantity += getUsableCapacityFromAsset(asset);
                    }
                }
            } else {
                totalQuantity += getNonAssetBasedQuantity(row,sourceSKUPolarisMapping,entVsEntData);

            }
        }
        return totalQuantity;
    }
    /**
    * @description getUsableCapacityFromAsset Helper function to calculate asset based qty 
    * @param asset
    * @return qty
    **/
    public Decimal getUsableCapacityFromAsset(Asset asset) {
        if (asset.Product_Usable_Capacity__c != null && asset.Product_Usable_Capacity__c != 0) {
            return asset.Product_Usable_Capacity__c;
        }
        if (asset.SBQQSC__CurrentContractLineItem__c != null) {
            if (asset.SBQQSC__CurrentContractLineItem__r.SBQQSC__RequiredByProduct__r.Usable_Capacity__c != null) {
                return asset.SBQQSC__CurrentContractLineItem__r.SBQQSC__RequiredByProduct__r.Usable_Capacity__c;
            }
            if (asset.SBQQSC__CurrentContractLineItem__r.SBQQSC__RequiredByProduct__c == null) {
                return asset.SBQQSC__CurrentContractLineItem__r.SBQQSC__Quantity__c;
            }
        }
        return 0;
    }
    /**
    * @description getNonAssetBasedQuantity Helper function to calculate non-asset qty 
    * @param row
    * @param sourceSKUPolarisMapping
    * @param entVsEntData
    * @return row.selectedQty
    **/
    public Decimal getNonAssetBasedQuantity(ReplacementJson.RowDetail row, 
            Map<Id,Polaris_SKU_Mapping_V2__c> sourceSKUPolarisMapping,Map<Id,Entitlement> entVsEntData) {
        if (!entVsEntData.containsKey(row.entId)) return row.selectedQty;
        
        String oldProd = entVsEntData.get(row.entId).Product__r.Product_level__c == null 
            ? entVsEntData.get(row.entId).Product__c: null;
        
        if (oldProd != null && sourceSKUPolarisMapping.containsKey(oldProd)) {
            if (sourceSKUPolarisMapping.get(
                    oldProd
                ).Quantity_Mapping_Type__c == ReplacementConstants.PRODUCT_QTY_MAPPING_TYPE) {
                return row.selectedQty * sourceSKUPolarisMapping.get(oldProd).Quantity_Ratio__c;
            }
        }
        
        return row.selectedQty;
    }
   
    /**
    * @description readReplacementDetails Helper function to collect EntIds from Replacement_detial field
    * @param ReplaceJSON
    * @param allEntIds
    **/ 
    public void readReplacementDetails(String ReplaceJSON,Set<Id> allEntIds){
        ReplacementJson qliReplaceJSON = (ReplacementJson)JSON.deserialize(ReplaceJSON, ReplacementJson.class);
        if (qliReplaceJSON != null && qliReplaceJSON.rowValues != null) {
            for (ReplacementJson.RowDetail childRow : qliReplaceJSON.rowValues) {
                if (childRow.entId != null){
                    allEntIds.add(childRow.entId);					
                }
            }
        }
    }
     /**
    * @description adderrorLogs Helper function to collect batchErrLogList and errorsnewSCList
    * @param batchErrLogList
    * @param errorsnewSCList
    * @param jobId
    * @param sr
    **/ 
    public void adderrorLogs(List<Batch_Error_Log__c> batchErrLogList,List<String> errorsnewSCList,Id jobId,Database.SaveResult sr){	
		errorsnewSCList.add('<b>' + sr.getId() + '</b> ::'+ JSON.serialize(sr.getErrors()));   
        batchErrLogList.add(new Batch_Error_Log__c(Class_Name__c='BatchToUpdateQLIQty',
                            Failure_Job_ID__c=jobId,
                            Failure_Message__c=String.valueOf(sr.getErrors()),
                            Scenario__c='Renewal Qty. has been changed',
                            Service_Contract_Id__c=sr.getId(),
                            Failure_Date__c=Date.today()));
		}
    
}