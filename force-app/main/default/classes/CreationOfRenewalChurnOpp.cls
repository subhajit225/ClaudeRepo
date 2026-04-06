/**
* @description class to create churn opportunity from ordered Renewal opportunity
*              JIRA -FY25SR-1109/FY25SR-1857 dot release
* test class - BatchToUpdateQLIQtyTest
* @CreatedDate 04 May 2025/ ModifiedDate 28 July 2025 
**/
public class CreationOfRenewalChurnOpp implements Queueable {
    private Set<Id> oppIds;
    /** 
* @description constructor to get OppIds
* @param oppIds
* **/
    public CreationOfRenewalChurnOpp(Set<Id> oppIds){
        this.oppIds=oppIds;  
    }
    /**
* @description Async execute function to create churn opp and its opp. product. 
* dot release Activities - Khushboo
* @param context
**/
    public void execute(QueueableContext context) {
        Set<Id> quoteIdsToCalculate=new Set<Id>();
        ShGl_DisableBusinessLogic__c csInstanceToUpdate,csInstanceToDelete = null;
        ShGl_DisableBusinessLogic__c existingSetting = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId());
        if (existingSetting.Id == null) {
            csInstanceToDelete = new ShGl_DisableBusinessLogic__c();
            csInstanceToDelete.Disable_Opportunity_Validation_Rules__c = true;
            csInstanceToDelete.SetupOwnerId = userinfo.getUserId();
            insert csInstanceToDelete;
        } else {
            if (!existingSetting.Disable_Opportunity_Validation_Rules__c) {
                csInstanceToUpdate = existingSetting;
                csInstanceToUpdate.Disable_Opportunity_Validation_Rules__c = true;
                csInstanceToUpdate.SetupOwnerId = userinfo.getUserId();
                update csInstanceToUpdate;
            }
        }
        try {
            Replacement_Field_Mapping__mdt objectData= 
                Replacement_Field_Mapping__mdt.getInstance(ReplacementConstants.RENEWAL_OPP_CREATION_CHURN);
            String firstWhereClause= objectData.First_Filter_Criteria__c;
            String query='SELECT Id,SBQQ__PrimaryQuote__c FROM Opportunity WHERE Id IN :oppIds ';
            query+= firstWhereClause;
            List<Opportunity> listOfOpp= Database.Query(query.trim());
            
            
            flowControll.opportunityTriggerHandler = false;
            flowControll.opportunityLineItemHandler = false;
            
            if (listOfOpp != null && !listOfOpp.isEmpty()) {
                Set<Id> quoteIds = new Set<Id>();
                Map<Id, List<CPQ_Disposition_Quote_Line__c>> quoteToCPQMap = 
                    new Map<Id, List<CPQ_Disposition_Quote_Line__c>>();
                Map<Id, List<SBQQ__QuoteLine__c>> quoteToSBQQMap = new Map<Id, List<SBQQ__QuoteLine__c>>();
                Map<Id, Id> quoteToOpportunityMap = new Map<Id, Id>();
                Map<Id, Decimal> pbeMap = new Map<Id, Decimal>();
                for (Opportunity op :listOfOpp)
                {
                    if (op.SBQQ__PrimaryQuote__c != null) {
                        quoteIds.add(op.SBQQ__PrimaryQuote__c);
                        quoteToOpportunityMap.put(op.SBQQ__PrimaryQuote__c, op.Id);
                    }
                }
                Map<Id,Id> prodIdVsPriceBookId= new Map<Id,Id>();
                Map<Id,Id> prodIdVsPBEId= new Map<Id,Id>();
                if (!quoteIds.isEmpty()) {
                    for (CPQ_Disposition_Quote_Line__c disposeLine : 
                         [SELECT Id, Quantity__c, Quote__c, Quote__r.Amended_Renewed_Service_Contract__c,
                          Arroyo_Subscribed_Asset_Name__c, RenewedContractLine__c,Quote__r.SBQQ__PricebookId__c, 
                          Replacement_Detail__c, Product__c, PricebookEntryId__c
                          FROM CPQ_Disposition_Quote_Line__c 
                          WHERE Quote__c IN :quoteIds 
                          AND Quote__r.OpportunitySubType__c = :ReplacementConstants.QUOTE_TYPE_RENEWAL])
                    {
                        prodIdVsPriceBookId.put(disposeLine.Product__c,disposeLine.Quote__r.SBQQ__PricebookId__c);
                        if (!quoteToCPQMap.containsKey(disposeLine.Quote__c)) {
                            quoteToCPQMap.put(disposeLine.Quote__c, new List<CPQ_Disposition_Quote_Line__c>());
                        }
                        quoteToCPQMap.get(disposeLine.Quote__c).add(disposeLine);
                    }
                    for (SBQQ__QuoteLine__c qli : 
                         [SELECT Id, Replacement_Details__c, SBQQ__Quote__c 
                          FROM SBQQ__QuoteLine__c 
                          WHERE SBQQ__Quote__c IN :quoteToCPQMap.keySet()])
                    {
                        if (!quoteToSBQQMap.containsKey(qli.SBQQ__Quote__c)) {
                            quoteToSBQQMap.put(qli.SBQQ__Quote__c, new List<SBQQ__QuoteLine__c>());
                        }
                        quoteToSBQQMap.get(qli.SBQQ__Quote__c).add(qli);
                    }
                }
                if(prodIdVsPriceBookId!=null && !prodIdVsPriceBookId.isEmpty()){
                    for(PricebookEntry pbe:[SELECT Id,Product2Id,Pricebook2Id, UnitPrice FROM PricebookEntry WHERE Product2Id IN :prodIdVsPriceBookId.keySet()]){
                        if(pbe.Pricebook2Id == prodIdVsPriceBookId.get(pbe.Product2Id)){
                            pbeMap.put(pbe.Id,pbe.UnitPrice);
                            prodIdVsPBEId.put(pbe.Product2Id,pbe.Id);   
                        }
                    }
                }
                //call function createOppAndOppProducts
                createOppAndOppProducts(quoteToOpportunityMap,pbeMap,prodIdVsPBEId,
                                        quoteToCPQMap,quoteToSBQQMap,quoteIdsToCalculate);
                if(quoteIdsToCalculate!=null && !quoteIdsToCalculate.isEmpty()){
                    calculateQuotes(quoteIdsToCalculate);
                }
            }
            if (csInstanceToDelete != null) {
                delete csInstanceToDelete;
            }
            if (csInstanceToUpdate != null) {
                csInstanceToUpdate.Disable_Opportunity_Validation_Rules__c = false;
                update csInstanceToUpdate;
            }
        } catch (Exception ex) {
            LogError.logCustomError('CreationOfRenewalChurnOpp',ex.getMessage(),ex.getStackTraceString(),'Failed to create Renewal Chuen Opportunity');
            if (csInstanceToDelete != null) {
                delete csInstanceToDelete;
            }
            if (csInstanceToUpdate != null) {
                csInstanceToUpdate.Disable_Opportunity_Validation_Rules__c = false;
                update csInstanceToUpdate;
            }
       }
    }
    
    /**
* @description Helper function to process the quote and create opportunity
* @param quoteIdToOppIdMap
* @param pbeMap
* @param prodIdVsPBEId
* @param quoteToCPQMap
* @param quoteToSBQQMap
* @param quoteIdsToCalculate
**/
    public static void createOppAndOppProducts(
        Map<Id,Id> quoteIdToOppIdMap,Map<Id, Decimal> pbeMap,
        Map<Id,Id> prodIdVsPBEId,
        Map<Id,List<CPQ_Disposition_Quote_Line__c>> quoteToCPQMap,
        Map<Id,List<SBQQ__QuoteLine__c>> quoteToSBQQMap,Set<Id> quoteIdsToCalculate) {
            if(quoteToCPQMap!=null && !quoteToCPQMap.isEmpty()){
                Set<Id> quoteIds = quoteIdToOppIdMap.keySet();
                List<Opportunity> newOpps = new List<Opportunity>();
                Map<Id, Opportunity> quoteToNewOpp = new Map<Id, Opportunity>();
                Map<Id, Opportunity> childParentLinkage = new Map<Id, Opportunity>();//for opportunity link obj.
                List<CPQ_Disposition_Quote_Line__c> matchingCPQList = new List<CPQ_Disposition_Quote_Line__c>();
                Map<Id,CPQ_Disposition_Quote_Line__c> oliIdToCPQMap= new  Map<Id,CPQ_Disposition_Quote_Line__c>();
                for (Id quoteId : quoteIds) {
                    Id sourceOppId = quoteIdToOppIdMap.get(quoteId);
                    List<CPQ_Disposition_Quote_Line__c> cpqLines = quoteToCPQMap.get(quoteId);
                    List<SBQQ__QuoteLine__c> sbqqLines = quoteToSBQQMap.get(quoteId);
                    Set<Id> entIds = new Set<Id>();
                    Boolean isFullChurn = true;
                    if (cpqLines != null) {
                        for (CPQ_Disposition_Quote_Line__c cli : cpqLines) {
                            if (cli.Replacement_Detail__c != null) {
                                ReplacementJson parsed = 
                                    (ReplacementJson)JSON.deserialize(cli.Replacement_Detail__c, ReplacementJson.class);
                                if (parsed != null && parsed.rowValues != null) {
                                    for (ReplacementJson.RowDetail row : parsed.rowValues) {
                                        if (row.entId != null) {
                                            entIds.add(row.entId);
                                        }
                                    }
                                }
                            }
                        }
                    }
                    if (sbqqLines != null) {
                        for (SBQQ__QuoteLine__c qli : sbqqLines) {
                            if (qli.Replacement_Details__c != null) {
                                ReplacementJson parsed = 
                                    (ReplacementJson)JSON.deserialize(qli.Replacement_Details__c, ReplacementJson.class);
                                if (parsed != null && parsed.rowValues != null) {
                                    for (ReplacementJson.RowDetail row : parsed.rowValues) {
                                        if (entIds.contains(row.entId)) {
                                            isFullChurn = false;
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Opportunity newOpp = createOpportunity(sourceOppId, isFullChurn);
                    newOpp.StageName=System.Label.ChurnOpportunityStage;//2 Consensus
                    newOpps.add(newOpp);
                    quoteToNewOpp.put(quoteId, newOpp);
                    //added parent-child relation in the obj Opportunity_Link__c
                    childParentLinkage.put(sourceOppId,newOpp);
                }
               insert newOpps;
                List<Opportunity_Link__c> opportunityLinkage = new List<Opportunity_Link__c>();
                for (Id opp : childParentLinkage.keySet()){
                    Id childOppId =childParentLinkage.get(opp).Id;
                    opportunityLinkage.add(new Opportunity_Link__c(
                        Parent_Opportunity__c = opp,
                        Child_Opportunity__c= childOppId,
                        Link_Type__c=System.Label.OpportunityLinkType,//Churn-Renewal
                        Name=System.Label.OpportunityLinkName //Renewal Opp Churn Linkage
                    ));
                }
                if (!opportunityLinkage.isEmpty()) {
                   insert opportunityLinkage;
                 }
                List<OpportunityLineItem> allOppProducts = new List<OpportunityLineItem>();
                for (Id quoteId : quoteToNewOpp.keySet()) {
                    Opportunity opp = quoteToNewOpp.get(quoteId);
                    if(opp.Id != null){
                        for (CPQ_Disposition_Quote_Line__c cli : quoteToCPQMap.get(quoteId)) {
                            Id pbeId=prodIdVsPBEId.get(cli.Product__c);
                            Decimal unitPrice = pbeMap.get(pbeId);
                            OpportunityLineItem oli=createOpportunityProduct(opp.Id, cli, unitPrice,pbeId);
                            allOppProducts.add(oli);
                            matchingCPQList.add(cli);
                        }
                    }
                }
                if (!allOppProducts.isEmpty()) {
                    Database.SaveResult[] results = Database.insert(allOppProducts, true);
                    for (Integer i = 0; i < results.size(); i++) {
                        if (results[i].isSuccess()) {
                            oliIdToCPQMap.put(allOppProducts[i].Id, matchingCPQList[i]);
                        }
                    }
                }
               
                if(oliIdToCPQMap!=null && !oliIdToCPQMap.isEmpty()){
                    quoteIdsToCalculate.addAll(OpportunityClosedAdminHelperClass.buildQuotesAndLines(null,oliIdToCPQMap));
                }
             }
        }
    
    /**
* @description Helper function to clone the opportunity
* @param opportunityId
* @param isFullChurn
* @return clonedOpportunity
**/ 
    public static Opportunity createOpportunity(Id opportunityId,Boolean isFullChurn) {
        Opportunity clonedOpportunity = new Opportunity();
        if(isFullChurn==true){
            clonedOpportunity = 
                OpportunityClosedAdminHelperClass.cloneOpportunity(
                    opportunityId, OpportunityClosedAdminHelperClass.CloneType.FULL_CHURN);
        }
        else
        {
            clonedOpportunity = 
                OpportunityClosedAdminHelperClass.cloneOpportunity(
                    opportunityId, OpportunityClosedAdminHelperClass.CloneType.PARTIAL_CHURN);
        }
        return clonedOpportunity;   
    }
    /**
* @description Helper function to create the opportunity product 
* @param opportunityId
* @param cli
* @param unitPrice
* @param pbeId
* @return oppProduct
**/
    public static OpportunityLineItem createOpportunityProduct(Id opportunityId,CPQ_Disposition_Quote_Line__c cli,
                                                               Decimal unitPrice,Id pbeId) {
                                                                   OpportunityLineItem oppProduct = new OpportunityLineItem();
                                                                   oppProduct.OpportunityId = opportunityId;
                                                                   oppProduct.Quantity = cli.Quantity__c;
                                                                   oppProduct.Product2Id=cli.Product__c;
                                                                   oppProduct.Amended_Service_Contract_Id_Text__c=cli.Quote__r.Amended_Renewed_Service_Contract__c;
                                                                   oppProduct.ContractLine_Id__c = cli.RenewedContractLine__c;
                                                                   oppProduct.pricebookentryid=pbeId;
                                                                   oppProduct.TotalPrice=cli.Quantity__c*unitPrice;
                                                                   return oppProduct;
                                                               }
    /**
* @description Helper function to calculate quote
* @param quoteIds
**/
    public static void calculateQuotes(Set<Id> quoteIds){
        QuoteCalculateAndSubmitBatch rqc=new QuoteCalculateAndSubmitBatch(quoteIds,null);
        Database.executeBatch(rqc,1);
    }    
    
}