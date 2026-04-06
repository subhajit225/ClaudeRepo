/**
 * @author Paritosh
 * @Date Created/Modified: 06/05/25
 * @description test class for FutureRenewalGuidanceController
 * @Story FY25SR-1090
 */
 @isTest
public without sharing class FutureRenewalGuidanceControllerTest {

    /**
     * @description test method main
     */
    @isTest
    public static void testRenewalGuidance() {
        ShGl_DisableBusinessLogic__c dbl = ShGl_DisableBusinessLogic__c.getInstance();
        dbl.Disable_Account_Triggers__c = true;
        dbl.Disable_Opportunity_Triggers__c = true;
        dbl.Disable_ServiceContract_Trigger__c = true;
        dbl.Disable_SBQQ_Quote_Triggers__c = true;
        dbl.Disable_SBQQ_QuoteLine_Triggers__c = true;
        insert dbl;
	
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;

        //create account
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Type=ReplacementConstants.ACCOUNT_TYPE_DISTRIBUTOR;
        acc.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get(ReplacementConstants.PARTNER_DISTRIBUTOR).getRecordTypeId();
        insert acc;

        //create products   
        Product2 hybLicenseprod = new Product2(Name='RS-BT-EE-PE-PP',ProductCode = 'RS-BT-EE-PE-PP', 
            IsActive=true, Product_Level__c = ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE, 
            Product_Type__c=ReplacementConstants.ENTERPRISE_EDITION,
            Product_Subtype__c=ReplacementConstants.PRODUCT_SUBTYPE_SAAS_CLOUD, X0__c=true,
            Quotable_Date__c = Date.newInstance(2004, 11, 11), 
            IsHardwareNotRequiredForHybridLicense__c = false,Approval_Category__c = 'Zone1');

        List<Product2> prodList = new List<Product2>(); 
        prodList.add(hybLicenseprod);
        insert prodList;  

        //create pricebook entries
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        PricebookEntry pricebookObj = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pricebookObj.Product2Id = hybLicenseprod.Id;
        pricebookObj.UnitPrice = 100;
        pricebookObj.Pricebook2Id = Test.getStandardPricebookId();
        pricebookObj.IsActive = true;
        pbeList.add(pricebookObj);		
        insert pbeList;

        //create opp
        Opportunity opportunityObj = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opportunityObj.AccountId = acc.Id;
        opportunityObj.Name = 'Testing Opportunity';
        opportunityObj.CloseDate = System.today().addMonths(12);
        opportunityObj.StageName = ReplacementConstants.STAGENAME_PROSPECTING;
        opportunityObj.Pricebook2Id = Test.getStandardPricebookId();
        insert opportunityObj;

        //create quote 
        SBQQ__Quote__c quoteObj= new SBQQ__Quote__c(
            SBQQ__Account__c=acc.Id,
            SBQQ__Opportunity2__c=opportunityObj.Id,
            SBQQ__StartDate__c=System.today(),
            SBQQ__Primary__c=true,
            SBQQ__SubscriptionTerm__c = 36,
            SBQQ__ExpirationDate__c = System.today().addYears(1)
        );
        insert quoteObj;

        //create quotelines
        List<SBQQ__QuoteLine__c> lstQuoteLine = new List<SBQQ__QuoteLine__c>{
        new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteObj.id,
                                   SBQQ__Product__c = prodList[0].Id,
                                   SBQQ__Quantity__c = 1,
                                   SBQQ__ListPrice__c = 100,
                                   SBQQ__NetPrice__c = 100,
                                   SBQQ__StartDate__c = System.today().addMonths(12).addDays(-1),
                SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE,
                Product_Level__c = ReplacementConstants.HARDWARE, 
                SubscribedAssetNames__c = 'BB192863040046',
                                   Promo_Disc__c = 0.1
                                  )};
        insert lstQuoteLine;

        //creat quote template
        SBQQ__QuoteTemplate__c objQuoteTemplate = new SBQQ__QuoteTemplate__c(
                Name = 'Quote Document Test',
                SBQQ__DeploymentStatus__c = 'Deployed'
            );
        insert objQuoteTemplate;

        User admin = [SELECT Id FROM USER 
            WHERE Profile.Name=:ReplacementConstants.PROFILE_SYSTEM_ADMINISTRATOR 
              AND isActive=true LIMIT 1];
        Test.startTest();
        System.runAs(admin){
            PageReference futureRenewalGuidance = Page.FutureRenewalGuidance;
            futureRenewalGuidance.getParameters().put('qid', quoteObj.Id);
            futureRenewalGuidance.getParameters().put('tid', objQuoteTemplate.Id);
            Test.setCurrentPage(futureRenewalGuidance);

            FutureRenewalGuidanceController controller = new FutureRenewalGuidanceController();

            System.assert(controller.template != null);
        }
        Test.stopTest();
    }
    
    /**
     * @description test method main
     */
    testmethod static void testRenewalGuidanceException() {
        User admin = [SELECT Id FROM USER 
            WHERE Profile.Name=:ReplacementConstants.PROFILE_SYSTEM_ADMINISTRATOR 
              AND isActive=true LIMIT 1];
        Test.startTest();
        System.runAs(admin){
        
       ShGl_DisableBusinessLogic__c dbl = ShGl_DisableBusinessLogic__c.getInstance();
        dbl.Disable_Account_Triggers__c = true;
        dbl.Disable_Opportunity_Triggers__c = true;
        dbl.Disable_ServiceContract_Trigger__c = true;
        dbl.Disable_SBQQ_Quote_Triggers__c = true;
        dbl.Disable_SBQQ_QuoteLine_Triggers__c = true;
        insert dbl;
	
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;

        //create account
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Type=ReplacementConstants.ACCOUNT_TYPE_DISTRIBUTOR;
        acc.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get(ReplacementConstants.PARTNER_DISTRIBUTOR).getRecordTypeId();
        insert acc;

        //create products   
        Product2 hybLicenseprod = new Product2(Name='RS-BT-EE-PE-PP',ProductCode = 'RS-BT-EE-PE-PP', 
            IsActive=true, Product_Level__c = ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE, 
            Product_Type__c=ReplacementConstants.ENTERPRISE_EDITION,
            Product_Subtype__c=ReplacementConstants.PRODUCT_SUBTYPE_SAAS_CLOUD, X0__c=true,
            Quotable_Date__c = Date.newInstance(2004, 11, 11), 
            IsHardwareNotRequiredForHybridLicense__c = false,Approval_Category__c = 'Zone1');

        List<Product2> prodList = new List<Product2>(); 
        prodList.add(hybLicenseprod);
        insert prodList;  

        //create pricebook entries
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        PricebookEntry pricebookObj = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pricebookObj.Product2Id = hybLicenseprod.Id;
        pricebookObj.UnitPrice = 100;
        pricebookObj.Pricebook2Id = Test.getStandardPricebookId();
        pricebookObj.IsActive = true;
        pbeList.add(pricebookObj);		
        insert pbeList;

        //create opp
        Opportunity opportunityObj = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opportunityObj.AccountId = acc.Id;
        opportunityObj.Name = 'Testing Opportunity';
        opportunityObj.CloseDate = System.today().addMonths(12);
        opportunityObj.StageName = ReplacementConstants.STAGENAME_PROSPECTING;
        opportunityObj.Pricebook2Id = Test.getStandardPricebookId();
        insert opportunityObj;

        //create quote 
        SBQQ__Quote__c quoteObj= new SBQQ__Quote__c(
            SBQQ__Account__c=acc.Id,
            SBQQ__Opportunity2__c=opportunityObj.Id,
            SBQQ__StartDate__c=System.today(),
            SBQQ__Primary__c=true,
            SBQQ__SubscriptionTerm__c = 36,
            SBQQ__ExpirationDate__c = System.today().addYears(1)
        );
        insert quoteObj;
        
        ApexPages.currentPage().getParameters().put('qid',quoteObj.Id); //'a1z000000000000');

        FutureRenewalGuidanceController controller = new FutureRenewalGuidanceController();

        System.assert(controller != null);
        Test.stopTest();
    }
    }
    
}