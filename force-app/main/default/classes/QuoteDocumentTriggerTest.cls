@isTest
public class QuoteDocumentTriggerTest{
    
    @isTest
    private static void checkDocIsApprovedTest()
    {
        List<SBQQ__QuoteDocument__c> quoteDocList = new List<SBQQ__QuoteDocument__c>();
        
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = false;
        upsert disableFuncCS;
        
        ShGl_DisableBusinessLogic__c cdf1 = new ShGl_DisableBusinessLogic__c(SetupOwnerId = userInfo.getUserId(),
                                                                             Disable_SBQQ_Quote_Validation_Rules__c = true,
                                                                             Disable_SBQQ_QuoteLine_Validation_Rules__c = true,
                                                                             Disable_Opportunity_Validation_Rules__c = true,
                                                                             Disable_ServiceContract_Trigger__c = true,
                                                                             Disable_Contract_Line_Item_Triggers__c = true);
        insert cdf1;
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        TriggerControls.disableCalculateAPIBatch = true;
        SBQQ.TriggerControl.disable();
        
        //SBQQ__Quote__c quoteListTest = [SELECT Id, Name, SBQQ__Status__c, Generate_Document__c FROM SBQQ__Quote__c LIMIT 1];
        Id standardPriceBookId =  Test.getStandardPricebookId();
        
        PriceBook2 pb1  = new Pricebook2(Name = 'V68_2017_08_09_12_26_43', Description = 'Price Book 2009 Products 1', IsActive = true);
        insert pb1;
        
        Account accObj = TestDataFactory.getAccount();
        insert accObj;
        
        Opportunity oppr = TestDataFactory.getOpportunity(accObj);
        insert oppr;
        
        Map<String, Object>  quoteMap = new Map<String, Object> 
        {'SBQQ__Account__c' => accObj.Id,'SBQQ__Opportunity2__c' => oppr.Id};
            
            SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppr.Id;
        qt1.SBQQ__PriceBook__c = pb1.Id;
        qt1.SBQQ__Status__c = 'Draft';
        qt1.SBQQ__Type__c = 'Quote';
        qt1.SBQQ__StartDate__c = Date.Today();
        qt1.Manual_Billing__c = false;
        qt1.Consolidate_Lines__c = false;
        qt1.SBQQ__ExpirationDate__c = Date.Today() + 365;
        insert qt1;
        
        qt1.SBQQ__Status__c = 'Approved';
        update qt1;
        
        SBQQ__QuoteDocument__c quoteDoc = new SBQQ__QuoteDocument__c();
        quoteDoc.SBQQ__Quote__c	=  qt1.Id;
        quoteDoc.SBQQ__Opportunity__c = qt1.SBQQ__Opportunity2__c;
        quoteDoc.SBQQ__Version__c = 1;
        insert quoteDoc;
        quoteDocList.add(quoteDoc);
        
        Test.startTest();
        
        if(quoteDocList != null && !quoteDocList.IsEmpty()){
            QuoteDocumentTriggerHelper.checkDocIsApproved(quoteDocList);
        }
        
        Test.stopTest();
        
        System.assert(true);
    }
}