/***********************************************************************************************************
* Method Name          : ReplacementCreateQuote
* Date Created/Modified: 28/03/2024
* @description         : Controller class to create Quote and Quote Lines for Renewal + Expansion quotes
* Test Class           :
*********************************************************************************************************/
Global without sharing class ReplacementCreateQuote {
   
    /***********************************************************************************************************
    * Method Name          : renewalCustomContract
    * Date Created/Modified: 01/10/2025
    * @description         : Controller class to create Quote and Quote Lines for Renewal + Expansion quotes.
    * @return              : Id
    * @param oppId
    * @param oppSubType
    * @param oppPriceBookId
    * @param oppContactId
    * @param oppOwnerId
    * @param oppAccId
    /**********************************************************************************************************/
    @AuraEnabled
    Webservice static Id renewalCustomContract(Id oppId, String oppSubType, Id oppPriceBookId, Id oppContactId, Id oppOwnerId, Id oppAccId){ 
        /*** Removed changes related to service contract checks when the quote is created from SMS UI : FY25SR-2251 ***/
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        try{
                /**** Quote Creation Logic *****/
            quote.SBQQ__Opportunity2__c = oppId;
                quote.SBQQ__Account__c = oppAccId;
                // quote.Amended_Renewed_Service_Contract__c = renewallist[0].Id;
            quote.SBQQ__QuoteTemplateId__c = SYSTEM.LABEL.Renewal_Expansion_Quote_Template_Id;
                quote.SBQQ__QuoteProcessId__c = label.PolarisProcessId;
            quote.SBQQ__SubscriptionTerm__c = 36; // ARY-398
            quote.SBQQ__LineItemsGrouped__c = true;
            quote.SBQQ__Type__c = ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION;
            quote.SBQQ__OrderByQuoteLineGroup__c = false;
            quote.SBQQ__OrderBy__c = ReplacementConstants.LINE_TYPE_ORDER_FIELD_API;
                quote.OpportunitySubType__c = oppSubType;
                quote.SBQQ__PriceBook__c = oppPriceBookId;
                quote.SBQQ__PrimaryContact__c = oppContactId;
                quote.SBQQ__SalesRep__c = oppOwnerId;
            quote.Update_Expires_On__c = true; // ARY-507 : to set Expiration date always to future date 

            SBQQ.TriggerControl.disable();
            if(Schema.sObjectType.SBQQ__Quote__c.isCreateable())
                insert quote;
                /**** Quote Creation Logic *****/

                /**** Quote LineGroup Creation Logic *****/
            List<SBQQ__QuoteLineGroup__c> quotelinegroupList = new List<SBQQ__QuoteLineGroup__c>();
            SBQQ__QuoteLineGroup__c qlg1 = new SBQQ__QuoteLineGroup__c();
            qlg1.Name = System.Label.Arry_renewal_Group;
            qlg1.Is_Renewal_Group__c = true;
            qlg1.SBQQ__Number__c = 2;//FY25SR-2230
            qlg1.SBQQ__Description__c = ReplacementConstants.DISCRIPTION_DONOTDELETE_LINES_RENEWAL_GRP;
            qlg1.SBQQ__Quote__c = quote.Id;
            quotelinegroupList.add(qlg1);
            
            SBQQ__QuoteLineGroup__c qlg2 = new SBQQ__QuoteLineGroup__c();
            qlg2.Name = System.Label.Arry_expansion_group;
            qlg2.Is_Expansion_Group__c = true;
            qlg2.SBQQ__Number__c = 1;//FY25SR-2230
            qlg2.SBQQ__Quote__c = quote.Id;
            quotelinegroupList.add(qlg2);
            if(Schema.sObjectType.SBQQ__QuoteLineGroup__c.isCreateable())
                insert quotelinegroupList;
                /**** Quote LineGroup Creation Logic *****/
        }
        catch (Exception e){
            if(quote != null){
                System.debug(LoggingLevel.DEBUG, 'Exception--->'+e.getMessage());
                return e.getMessage();
            }
        }
        return quote.Id;
    }
}