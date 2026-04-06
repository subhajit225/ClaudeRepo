@isTest
public class GenerateDocumentCustomExtTest {
    
    @isTest
    public static void testGenerateDocumentCustomExt(){
        //triggers
        ShGl_DisableBusinessLogic__c dbl = ShGl_DisableBusinessLogic__c.getInstance();
        dbl.Disable_Account_Triggers__c = true;
        dbl.Disable_Opportunity_Triggers__c = true;
        dbl.Disable_SBQQ_Quote_Triggers__c = true;
        dbl.Disable_SBQQ_QuoteLine_Triggers__c = true;
        insert dbl;
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        
        
        //create account
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Type='Distributor';
        acc.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        insert acc;
        
        //create opp
        Opportunity opportunityObj = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opportunityObj.AccountId = acc.Id;
        opportunityObj.Name = 'Testing Opportunity';
        opportunityObj.CloseDate = System.today().addMonths(12);
        opportunityObj.StageName = 'Prospecting';
        opportunityObj.Pricebook2Id = Test.getStandardPricebookId();
        insert opportunityObj;
        
        //create products    
        Product2 hybLicenseprod = new Product2(Name='RS-BT-EE-PE-PP',ProductCode = 'RS-BT-EE-PE-PP', IsActive=true, Product_Level__c = 'Hybrid Software', 
                                               Product_Type__c='Enterprise Edition',Product_Subtype__c='Saas Cloud', X0__c=true,
                                               Quotable_Date__c = Date.newInstance(2004, 11, 11), IsHardwareNotRequiredForHybridLicense__c = false,Approval_Category__c = 'Zone1'); 
        
        List<Product2> prodList = new List<Product2>();
        prodList.add(hybLicenseprod);
        
        insert prodList;  
        
        //create pricebook entries
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        PricebookEntry pricebookObj = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pricebookObj.Product2Id = prodList[0].Id;
        pricebookObj.UnitPrice = 100;
        pricebookObj.Pricebook2Id = Test.getStandardPricebookId();
        pricebookObj.IsActive = true;
        pbeList.add(pricebookObj);		
        
        //create Quote Template
        SBQQ__QuoteTemplate__c QuoteTemplate1 = new SBQQ__QuoteTemplate__c();
        QuoteTemplate1.name = 'Test1';
        QuoteTemplate1.SBQQ__CompanyStreet__c = 'Test1';
        QuoteTemplate1.SBQQ__CompanyCity__c = 'Test3';
        QuoteTemplate1.SBQQ__CompanyState__c = 'Test4';
        QuoteTemplate1.SBQQ__CompanyPostalCode__c = '12344';
        QuoteTemplate1.SBQQ__CompanyPhone__c = '234545';
        insert QuoteTemplate1;
        
        //create quote 
        SBQQ__Quote__c quoteObj= new SBQQ__Quote__c(SBQQ__Account__c=acc.Id,
                                                    SBQQ__Opportunity2__c=opportunityObj.Id,
                                                    SBQQ__StartDate__c=System.today(),
                                                    SBQQ__Primary__c=true,
                                                    SBQQ__SubscriptionTerm__c = 36,
                                                    SBQQ__ExpirationDate__c = System.today().addYears(1),
                                                    SBQQ__QuoteTemplateId__c = QuoteTemplate1.Id
                                                   );
        insert quoteObj;
        
        //create Quote Document
        SBQQ__QuoteDocument__c doc = new SBQQ__QuoteDocument__c(
            SBQQ__QuoteTemplate__c = QuoteTemplate1.Id,
            SBQQ__Quote__c = quoteObj.Id
        );
        insert doc;
        
        //create quotelines
        List<SBQQ__QuoteLine__c> lstQuoteLine = new List<SBQQ__QuoteLine__c>{
            new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteObj.id,
                                   SBQQ__Product__c = prodList[0].Id,
                                   SBQQ__Quantity__c = 1,
                                   SBQQ__ListPrice__c = 100,
                                   SBQQ__NetPrice__c = 100,
                                   SBQQ__StartDate__c = System.today().addMonths(12).addDays(-1),
                                   SBQQ__SubscriptionPricing__c='Fixed Price',
                                   Product_Level__c = 'Hardware', SubscribedAssetNames__c = 'BB192863040046'
                                  )};
                                      insert lstQuoteLine;
        
        
        
        Test.setCurrentPage(Page.GenerateDocumentCustom);
        ApexPages.StandardController sc = new ApexPages.StandardController(quoteObj);
        GenerateDocumentCustomExt ext = new GenerateDocumentCustomExt(sc);
        
        Test.startTest();
        ext.init();
        ext.resolve('Completed','');
        ext.resolve('Failed', 'error...');
        ext.getGeneratePage();
        Test.stopTest();
    }
    
}