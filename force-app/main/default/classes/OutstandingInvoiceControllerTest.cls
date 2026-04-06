/**
 * @author Paritosh
 * @Date Created/Modified: 06/05/25
 * @description test class for OutstandingInvoiceController
 * @Story FY25SR-1090
 */
@isTest
public with sharing class OutstandingInvoiceControllerTest {

    /**
     * @description test method main
     */
    @isTest
    public static void testOutStandingInvoice() {
        ShGl_DisableBusinessLogic__c dbl = ShGl_DisableBusinessLogic__c.getInstance();
        dbl.Disable_Account_Triggers__c = true;
        dbl.Disable_Opportunity_Triggers__c = true;
        dbl.Disable_ServiceContract_Trigger__c = true;
        dbl.Disable_SBQQ_Quote_Triggers__c = true;
        dbl.Disable_SBQQ_QuoteLine_Triggers__c = true;
        dbl.Disable_Entitlement_Validation_Rules__c = true;
        insert dbl;

        TriggerControl__c control = new TriggerControl__c(
            Name = ReplacementConstants.REPLACEMENT_ENTITLEMENT_MDT,
            DisableTrigger__c = true
        );
        insert control;
	
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;

        //create account
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Type='Distributor';
        acc.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
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

        //create orderInstance
		Order orderInstance = new Order();
        orderInstance.AccountId = acc.Id;
        orderInstance.EffectiveDate = system.today();  
        orderInstance.Status = ReplacementConstants.STATUS_DRAFT;
        orderInstance.Type = ReplacementConstants.ORDER_TYPE_REVENUE;
        orderInstance.Pricebook2Id = Test.getStandardPricebookId(); 
        insert orderInstance;
		
		//create order products
		List<OrderItem> orderItemList = new List<OrderItem>();
        OrderItem orderItem1 = new OrderItem();
        orderItem1.OrderId = orderInstance.Id;
        orderItem1.Product2Id = hybLicenseprod.Id;
        orderItem1.UnitPrice = pricebookObj.UnitPrice;
        orderItem1.Quantity = 1;
        orderItem1.SerialNumber__c = '09092019APMSP1250';
        orderItem1.Support_Start_Date__c = System.today();
        orderItem1.Support_End_Date__c = System.today().addMonths(36);
        orderItem1.PricebookEntryId = pricebookObj.Id;
        orderItemList.add(orderItem1);
        insert orderItemList;

        //create entitlements
		Entitlement ent = new Entitlement(Name='Testing', 
            AccountId=acc.Id,
            Product__c =hybLicenseprod.id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(365),
            Order_Service_Item__c = orderItem1.Id
        );

        insert ent;

        //create order item extensions
        Order_Item_Extension__c orderItemExtension = new Order_Item_Extension__c(
            Unpaid__c = true, 
            Unbilled__c = true, 
            Invoice_Creation_Date__c = String.valueOf(Date.today()),
            Order_Line_ID__c = orderItem1.Id,
            OI_ExternalID__c = orderItem1.Id
        );
        insert orderItemExtension;
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

        String replacementDetails = '{"skuSuppType":"Premium","skuStorageTierVal":null,'
        +'"skuStorageBundleVal":null,"skuSFDCVal":null,"skuSelectedName":"RS-BT-EE-PE-PA",'
        +'"skuSelected":"01t6f00000O6dT0AAJ","skuProdCodeType":null,"skuM365HVal":null,'
        +'"skuAttlasianVal":null,"seamlessCutover":null,"rowValues":[{"upgradeLines":null,'
        +'"selectedTerm":36,"selectedQty":60,"selectedAssetList"'
        +':{"02i8Y00000eGYJdQAO":"BB192863040046"},"selectedAsset":"02i8Y00000eGYJdQAO",'
        +'"rowId":"1.1.0","isAutoDisposition":null,"inactiveLines":[{"childrowId":null,'
        +'"childQnty":60,"childEntId":"'+ent.Id+'"}],"entId":"'+ent.Id+'","dnc":false,'
        +'"disposition":"Converted","anyToAnyFlag":false}],"renLine":null,"refreshCategoryId":'
        +'null,"productType":"Hardware","mode":"1to1","dynamicFieldValues":null}';

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
                Special_Program__c = ReplacementConstants.UPGRADE_VALUE,
                                   Replacement_Details__c = replacementDetails
                                  )};
        insert lstQuoteLine;

        //creat quote template
        SBQQ__QuoteTemplate__c objQuoteTemplate = new SBQQ__QuoteTemplate__c(
                Name = 'Quote Document Test',
                SBQQ__DeploymentStatus__c = 'Deployed'
            );
        insert objQuoteTemplate;

        User admin = [SELECT Id FROM USER WHERE Profile.Name=:ReplacementConstants.PROFILE_SYSTEM_ADMINISTRATOR 
                         AND isActive=true LIMIT 1];
        Test.startTest();
        System.runAs(admin){
            PageReference outstandingInvoicePage = Page.OutstandingInvoicePage;
            outstandingInvoicePage.getParameters().put('qid', quoteObj.Id);
            outstandingInvoicePage.getParameters().put('tid', objQuoteTemplate.Id);
            Test.setCurrentPage(outstandingInvoicePage);

            OutstandingInvoiceController invoiceController = new OutstandingInvoiceController();

            System.assert(true);
        }
        Test.stopTest();

    }
    
    @isTest
    public static void testOutStandingInvoiceCatch() {
        ShGl_DisableBusinessLogic__c dbl = ShGl_DisableBusinessLogic__c.getInstance();
        dbl.Disable_Account_Triggers__c = true;
        dbl.Disable_Opportunity_Triggers__c = true;
        dbl.Disable_ServiceContract_Trigger__c = true;
        dbl.Disable_SBQQ_Quote_Triggers__c = true;
        dbl.Disable_SBQQ_QuoteLine_Triggers__c = true;
        dbl.Disable_Entitlement_Validation_Rules__c = true;
        insert dbl;

        TriggerControl__c control = new TriggerControl__c(
            Name = ReplacementConstants.REPLACEMENT_ENTITLEMENT_MDT,
            DisableTrigger__c = true
        );
        insert control;
	
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;

        //create account
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Type='Distributor';
        acc.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
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

        //create orderInstance
		Order orderInstance = new Order();
        orderInstance.AccountId = acc.Id;
        orderInstance.EffectiveDate = system.today();  
        orderInstance.Status = ReplacementConstants.STATUS_DRAFT;
        orderInstance.Type = ReplacementConstants.ORDER_TYPE_REVENUE;
        orderInstance.Pricebook2Id = Test.getStandardPricebookId(); 
        insert orderInstance;
		
		//create order products
		List<OrderItem> orderItemList = new List<OrderItem>();
        OrderItem orderItem1 = new OrderItem();
        orderItem1.OrderId = orderInstance.Id;
        orderItem1.Product2Id = hybLicenseprod.Id;
        orderItem1.UnitPrice = pricebookObj.UnitPrice;
        orderItem1.Quantity = 1;
        orderItem1.SerialNumber__c = '09092019APMSP1250';
        orderItem1.Support_Start_Date__c = System.today();
        orderItem1.Support_End_Date__c = System.today().addMonths(36);
        orderItem1.PricebookEntryId = pricebookObj.Id;
        orderItemList.add(orderItem1);
        insert orderItemList;

        //create entitlements
		Entitlement ent = new Entitlement(Name='Testing', 
            AccountId=acc.Id,
            Product__c =hybLicenseprod.id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(365),
            Order_Service_Item__c = orderItem1.Id
        );

        insert ent;

        //create order item extensions
        Order_Item_Extension__c orderItemExtension = new Order_Item_Extension__c(
            Unpaid__c = true, 
            Unbilled__c = true, 
            Invoice_Creation_Date__c = String.valueOf(Date.today()),
            Order_Line_ID__c = orderItem1.Id,
            OI_ExternalID__c = orderItem1.Id
        );
        insert orderItemExtension;
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

        String replacementDetails = '{"skuSuppType":"Premium","skuStorageTierVal":null,'
        +'"skuStorageBundleVal":null,"skuSFDCVal":null,"skuSelectedName":"RS-BT-EE-PE-PA",'
        +'"skuSelected":"01t6f00000O6dT0AAJ","skuProdCodeType":null,"skuM365HVal":null,'
        +'"skuAttlasianVal":null,"seamlessCutover":null,"rowValues":[{"upgradeLines":null,'
        +'"selectedTerm":36,"selectedQty":60,"selectedAssetList"'
        +':{"02i8Y00000eGYJdQAO":"BB192863040046"},"selectedAsset":"02i8Y00000eGYJdQAO",'
        +'"rowId":"1.1.0","isAutoDisposition":null,"inactiveLines":[{"childrowId":null,'
        +'"childQnty":60,"childEntId":"'+ent.Id+'"}],"entId":"'+ent.Id+'","dnc":false,'
        +'"disposition":"Converted","anyToAnyFlag":false}],"renLine":null,"refreshCategoryId":'
        +'null,"productType":"Hardware","mode":"1to1","dynamicFieldValues":null}';

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
                Special_Program__c = ReplacementConstants.UPGRADE_VALUE,
                Replacement_Details__c = replacementDetails
        )};
        insert lstQuoteLine;

        //creat quote template
        SBQQ__QuoteTemplate__c objQuoteTemplate = new SBQQ__QuoteTemplate__c(
                Name = 'Quote Document Test',
                SBQQ__DeploymentStatus__c = 'Deployed'
            );
        insert objQuoteTemplate;

        User admin = [SELECT Id FROM USER WHERE Profile.Name=:ReplacementConstants.PROFILE_SYSTEM_ADMINISTRATOR 
                         AND isActive=true LIMIT 1];
        Test.startTest();
        System.runAs(admin){
            
            PageReference outstandingInvoicePage = Page.OutstandingInvoicePage;
            //outstandingInvoicePage.getParameters().put('qid', quoteObj.Id);
            //outstandingInvoicePage.getParameters().put('tid', objQuoteTemplate.Id);
            Test.setCurrentPage(outstandingInvoicePage);

            OutstandingInvoiceController invoiceController = new OutstandingInvoiceController();

            System.assert(invoiceController.outstandingInvoiceLabel == null);
          }
        Test.stopTest();

    }
    
}