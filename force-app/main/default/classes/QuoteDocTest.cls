/**
 * @author Paritosh
 * @Date Created/Modified: 06/05/25
 * @description test class for quote doc
 * @Story FY25SR-1090
 */
@isTest
public without sharing class QuoteDocTest {
    /**
     * @description test setup
     */
    @testSetup
    public static void testSetup() {
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
        acc.Type=ReplacementConstants.ACCOUNT_TYPE_DISTRIBUTOR;
        acc.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get(ReplacementConstants.PARTNER_DISTRIBUTOR).getRecordTypeId();
        insert acc;

        //create products   
        Product2 hybLicenseprodFE = new Product2(Name='RS-BT-FE-PE-PP',ProductCode = 'RS-BT-FE-PE-PP',
            IsActive=true, 
            // Product_Level__c = ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE, 
            Product_Type__c='FE Edition',
            Product_Subtype__c=ReplacementConstants.PRODUCT_SUBTYPE_SAAS_CLOUD, X0__c=true,
            Quotable_Date__c = Date.newInstance(2004, 11, 11), 
            IsHardwareNotRequiredForHybridLicense__c = false,
            Approval_Category__c = 'Zone1');

        //create products   
        Product2 hybLicenseprodEE = new Product2(Name='RS-BT-EE-PE-PP',ProductCode = 'RS-BT-EE-PE-PP', 
            IsActive=true, Product_Level__c = ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE, 
            Product_Type__c=ReplacementConstants.ENTERPRISE_EDITION,
            Product_Subtype__c=ReplacementConstants.PRODUCT_SUBTYPE_SAAS_CLOUD, 
            X0__c=true, Quotable_Date__c = Date.newInstance(2004, 11, 11), 
            IsHardwareNotRequiredForHybridLicense__c = false,Approval_Category__c = 'Zone1');

        List<Product2> prodList = new List<Product2>(); 
        prodList.add(hybLicenseprodFE);
        prodList.add(hybLicenseprodEE);
        insert prodList;  

        //create pricebook entries
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        PricebookEntry pricebookObj = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pricebookObj.Product2Id = hybLicenseprodFE.Id;
        pricebookObj.UnitPrice = 100;
        pricebookObj.Pricebook2Id = Test.getStandardPricebookId();
        pricebookObj.IsActive = true;
        pbeList.add(pricebookObj);	
        
        PricebookEntry pricebookObj2 = pricebookObj.clone();
        pricebookObj2.Product2Id = hybLicenseprodEE.Id;
        pbeList.add(pricebookObj2);

        insert pbeList;
        
        Asset asst= Replacement_TestDataFactory.getAsset('Asset1298', hybLicenseprodFE.Id, acc.Id);
        INSERT asst;

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
        orderItem1.Product2Id = hybLicenseprodFE.Id;
        orderItem1.UnitPrice = pricebookObj.UnitPrice;
        orderItem1.Quantity = 1;
        orderItem1.SerialNumber__c = '09092019APMSP1250';
        orderItem1.Support_Start_Date__c = System.today();
        orderItem1.Support_End_Date__c = System.today().addMonths(36);
        orderItem1.PricebookEntryId = pricebookObj.Id;
        orderItemList.add(orderItem1);
        insert orderItemList;
        
        //create opp
        Opportunity opportunityObj = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opportunityObj.AccountId = acc.Id;
        opportunityObj.Name = 'Testing Opportunity';
        opportunityObj.CloseDate = System.today().addMonths(12);
        opportunityObj.StageName = ReplacementConstants.STAGENAME_PROSPECTING;
        opportunityObj.Pricebook2Id = Test.getStandardPricebookId();
        insert opportunityObj;
        
        ServiceContract serviceContractObj = Replacement_TestDataFactory.getServiceContract(acc.Id, opportunityObj.Id,  Test.getStandardPricebookId());
        INSERT serviceContractObj;
        
        ContractLineItem contractLineItemObj = Replacement_TestDataFactory.getContractLineItem(acc.Id, asst.Id,pricebookObj.Id, serviceContractObj.Id);
        contractLineItemObj.EndDate = Date.today().addDays(365);
        contractLineItemObj.StartDate =  Date.today();
        contractLineItemObj.SBQQSC__Product__c = hybLicenseprodFE.id;
        contractLineItemObj.SBQQSC__RenewalQuantity__c=200;
        contractLineItemObj.SBQQSC__ListPrice__c=400;
        insert contractLineItemObj;
        
        //create entitlements
		Entitlement ent = new Entitlement(Name='Testing', 
            AccountId=acc.Id,
            Product__c =hybLicenseprodFE.id,
            StartDate = Date.today().addDays(1),
            EndDate = Date.today().addDays(366),
            Order_Service_Item__c = orderItem1.Id,
            ContractLineItem= contractLineItemObj,
            Quantity__c =10                              
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

        String replacementDetails = 
            '{"skuSuppType":"Premium","skuStorageTierVal":null,"skuStorageBundleVal":null,'
          + '"skuSFDCVal":null,"skuSelectedName":"RS-BT-EE-PE-PA","skuSelected":"01t6f00000O6dT0AAJ",'
          + '"skuProdCodeType":null,"skuM365HVal":null,"skuAttlasianVal":null,"seamlessCutover":null,'
          + '"rowValues":[{"upgradeLines":null,"selectedTerm":36,"selectedQty"'
          + ':60,"selectedAssetList":{"02i8Y00000eGYJdQAO":"BB192863040046"},"selectedAsset":'
          + '"02i8Y00000eGYJdQAO","rowId":"1.1.0","isAutoDisposition":null,"inactiveLines":'
          + '[{"childrowId":null,"childQnty":60,"childEntId":"'+ent.Id+'"}],"entId":"'+ent.Id
          + '","dnc":false,"disposition":"Converted","anyToAnyFlag":false}],"renLine":null,'
          + '"refreshCategoryId":null,"productType":"Hardware","mode":"1to1","dynamicFieldValues":null}';

        //create quotelines
        List<SBQQ__QuoteLine__c> lstQuoteLine = new List<SBQQ__QuoteLine__c>{
        new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteObj.id,
            SBQQ__Product__c = hybLicenseprodFE.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__ListPrice__c = 100,
            SBQQ__NetPrice__c = 100,
            SBQQ__StartDate__c = System.today().addMonths(12).addDays(-1),
            SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE, 
            Arroyo_Subsumed_Old_Contract_Line_Items__c = 'BB192863040046',
            Disposition_Reason__c = ReplacementConstants.UPGRADED,
            Promo_Disc__c = 0.1,
            Replacement_Details__c = '{"skuSuppType":null,"skuStorageTierVal":null,'
                + '"skuStorageBundleVal":null,"skuSFDCVal":null,"skuSelectedName":null,'
                + '"skuSelected":null,"skuM365HVal":null,"skuAttlasianVal":null,"seamlessCutover"'
                + ':null,"rowValues":[{"upgradeLines":null,"selectedTerm":12,'
                + '"selectedQty":60,"selectedAssetList":{"02i6f00000IrOveAAF":"BB192863040046"},'
                + '"selectedAsset":"02i6f00000IrOveAAF","rowId":"14.2.0","isAutoDisposition":null,'
                + '"inactiveLines":null,"entId":"5508Y000005cMw1QAE","disposition":"Refreshed",'
                + '"anyToAnyFlag":null}],"renLine":null,"refreshCategoryId":"01t6f00000Oa3G2AAJ","mode":null}',
            SBQQ__Description__c = 'test'
        ),
        new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteObj.id,
            SBQQ__Product__c = hybLicenseprodEE.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__ListPrice__c = 100,
            SBQQ__NetPrice__c = 100,
            SBQQ__StartDate__c = System.today().addMonths(12).addDays(-1),
            SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE, 
            Arroyo_Subsumed_Old_Contract_Line_Items__c = 'BB192863040046',
            Special_Program__c = ReplacementConstants.UPGRADE_VALUE,
            Replacement_Details__c = '{"skuSuppType":"Premium","skuStorageTierVal":null,'
             + '"skuStorageBundleVal":null,"skuSFDCVal":null,"skuSelectedName":"RS-BT-EE-PE-PA"'
             + ',"skuSelected":"01t6f00000O6dT0AAJ","skuProdCodeType":null,"skuM365HVal":null,'
             + '"skuAttlasianVal":null,"seamlessCutover":null,"rowValues":[{"upgradeLines":null,'
             + '"selectedTerm":36,"selectedQty":60,"selectedAssetList":'
             + '{"02i8Y00000eGYJdQAO":"BB192863040046"},"selectedAsset":"02i8Y00000eGYJdQAO",'
             + '"rowId":"1.1.0","isAutoDisposition":null,"inactiveLines":[{"childrowId":null,'
             + '"childQnty":60,"childEntId":"'+ent.Id+'"}],"entId":"'+ent.Id
             + '","dnc":false,"disposition":"Converted","anyToAnyFlag":false}],"renLine":null,'
             + '"refreshCategoryId":null,"productType":"Hardware","mode":"1to1","dynamicFieldValues":null}',
            SBQQ__Description__c = 'test',
            SBQQ__AdditionalDiscountAmount__c = 100
        ),
        new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteObj.id,
            SBQQ__Product__c = hybLicenseprodEE.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__ListPrice__c = 100,
            SBQQ__NetPrice__c = 100,
            SBQQ__StartDate__c = System.today().addMonths(12).addDays(-1),
            SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE, 
            Arroyo_Subsumed_Old_Contract_Line_Items__c = 'BB192863040046',
            Special_Program__c = ReplacementConstants.UPGRADE_VALUE,
            Replacement_Details__c = '{"skuSuppType":"Premium","skuStorageTierVal":null,'
            + '"skuStorageBundleVal":null,"skuSFDCVal":null,"skuSelectedName":"RS-BT-EE-PE-PA",'
            + '"skuSelected":"01t6f00000O6dT0AAJ","skuProdCodeType":null,"skuM365HVal":null,'
            + '"skuAttlasianVal":null,"seamlessCutover":null,"rowValues":[{"upgradeLines":null,'
            + '"selectedTerm":36,"selectedQty":60,"selectedAssetList":'
            + '{"02i8Y00000eGYJdQAO":"BB192863040046"},"selectedAsset":"02i8Y00000eGYJdQAO",'
            + '"rowId":"1.1.0","isAutoDisposition":null,"inactiveLines":[{"childrowId":null,'
            + '"childQnty":60,"childEntId":"'+ent.Id+'"}],"entId":"'+ent.Id
            + '","dnc":false,"disposition":"Converted","anyToAnyFlag":false}],"renLine":null,'
            + '"refreshCategoryId":null,"productType":"Hardware","mode":"1to1","dynamicFieldValues":null}',
            SBQQ__Description__c = 'test'
        ),
        new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteObj.id,
            SBQQ__Product__c = hybLicenseprodFE.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__ListPrice__c = 100,
            SBQQ__NetPrice__c = 100,
            SBQQ__StartDate__c = System.today().addMonths(12).addDays(-1),
            SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE, 
            Arroyo_Subsumed_Old_Contract_Line_Items__c = 'BB0000000001',
            Disposition_Reason__c = ReplacementConstants.UPGRADED,
            Promo_Disc__c = 0.1,
            Replacement_Details__c = '{"skuSuppType":null,"skuStorageTierVal":null,'
            + '"skuStorageBundleVal":null,"skuSFDCVal":null,"skuSelectedName":null,'
            + '"skuSelected":null,"skuM365HVal":null,"skuAttlasianVal":null,"seamlessCutover"'
            + ':null,"rowValues":[{"upgradeLines":null,"selectedTerm":12,'
            + '"selectedQty":60,"selectedAssetList":{"02i6f00000IrOveAAF":"BB0000000001"},'
            + '"selectedAsset":"02i6f00000IrOveAAF","rowId":"14.2.0","isAutoDisposition":null,'
            + '"inactiveLines":[{"childrowId":null,"childQnty":270,"childEntId":"'+ent.Id+'"}],'
            + '"entId":"5508Y000005cMw1QAE","disposition":"Refreshed",'
            + '"anyToAnyFlag":null}],"renLine":null,"refreshCategoryId":"01t6f00000Oa3G2AAJ","mode":null}',
            SBQQ__Description__c = 'test'
        ),
        new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteObj.id,
            SBQQ__Product__c = hybLicenseprodFE.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__ListPrice__c = 100,
            SBQQ__NetPrice__c = 100,
            SBQQ__StartDate__c = System.today().addMonths(12).addDays(-1),
            SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE, 
            Arroyo_Subsumed_Old_Contract_Line_Items__c = 'BB0000000002',
            Disposition_Reason__c = ReplacementConstants.UPGRADED,
            Promo_Disc__c = 0.1,
            Replacement_Details__c = '{"skuSuppType":null,"skuStorageTierVal":null,'
            + '"skuStorageBundleVal":null,"skuSFDCVal":null,"skuSelectedName":null,'
            + '"skuSelected":null,"skuM365HVal":null,"skuAttlasianVal":null,"seamlessCutover"'
            + ':null,"rowValues":[{"upgradeLines":null,"selectedTerm":12,'
            + '"selectedQty":60,"selectedAssetList":{"02i6f00000IrOveAAF":"BB0000000002"},'
            + '"selectedAsset":"02i6f00000IrOveAAF","rowId":"14.2.0","isAutoDisposition":null,'
            + '"inactiveLines":null,"entId":"5508Y000005cMw1QAE","disposition":"Refreshed",'
            + '"anyToAnyFlag":null}],"renLine":null,"refreshCategoryId":"01t6f00000Oa3G2AAJ","mode":null}',
            SBQQ__Description__c = 'test'
        ),
        new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteObj.id,
            SBQQ__Product__c = hybLicenseprodEE.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__ListPrice__c = 100,
            SBQQ__NetPrice__c = 100,
            SBQQ__StartDate__c = System.today().addMonths(12).addDays(-1),
            SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE, 
            Arroyo_Subsumed_Old_Contract_Line_Items__c = 'BB0000000001, BB0000000002',
            Special_Program__c = ReplacementConstants.UPGRADE_VALUE,
            Replacement_Details__c = '{"skuSuppType":"Premium","skuStorageTierVal":null,'
            + '"skuStorageBundleVal":null,"skuSFDCVal":null,"skuSelectedName":"RS-BT-EE-PE-PA",'
            + '"skuSelected":"01t6f00000O6dT0AAJ","skuProdCodeType":null,"skuM365HVal":null,'
            + '"skuAttlasianVal":null,"seamlessCutover":null,"rowValues":[{"upgradeLines":null,'
            + '"selectedTerm":36,"selectedQty":60,"selectedAssetList":'
            + '{"02i8Y00000eGYJdQAO":"BB0000000001", "02i8Y00000eGYJdQAO":"BB0000000002"},'
            + '"selectedAsset":"02i8Y00000eGYJdQAO, 02i8Y00000eGYJdQAO","rowId":"1.1.0",'
            + '"isAutoDisposition":null,"inactiveLines":[{"childrowId":null,"childQnty":60,"childEntId":"'
            + ent.Id+'"}],"entId":"'+ent.Id+'","dnc":false,"disposition":"Converted","anyToAnyFlag":false}],'
            + '"renLine":null,"refreshCategoryId":null,"productType":"Hardware","mode":"1to1","dynamicFieldValues":null}',
            SBQQ__Description__c = 'test'
        ),
        new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteObj.id,
            SBQQ__Product__c = hybLicenseprodFE.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__ListPrice__c = 100,
            SBQQ__NetPrice__c = 100,
            SBQQ__StartDate__c = System.today().addMonths(12).addDays(-1),
            SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE, 
            Arroyo_Subsumed_Old_Contract_Line_Items__c = 'BB0000000003',
            Disposition_Reason__c = ReplacementConstants.UPGRADED,
            Promo_Disc__c = 0.1,
            Replacement_Details__c = '{"skuSuppType":null,"skuStorageTierVal":null,'
            + '"skuStorageBundleVal":null,"skuSFDCVal":null,"skuSelectedName":null,'
            + '"skuSelected":null,"skuM365HVal":null,"skuAttlasianVal":null,"seamlessCutover"'
            + ':null,"rowValues":[{"upgradeLines":null,"selectedTerm":12,'
            + '"selectedQty":60,"selectedAssetList":{"02i6f00000IrOveAAF":"BB0000000003"},'
            + '"selectedAsset":"02i6f00000IrOveAAF","rowId":"14.2.0","isAutoDisposition":null,'
            + '"inactiveLines":null,'
            + '"entId":"5508Y000005cMw1QAE","disposition":"Refreshed",'
            + '"anyToAnyFlag":null}],"renLine":null,"refreshCategoryId":"01t6f00000Oa3G2AAJ","mode":null}',
            SBQQ__Description__c = 'test'
        ),
        new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteObj.id,
            SBQQ__Product__c = hybLicenseprodFE.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__ListPrice__c = 100,
            SBQQ__NetPrice__c = 100,
            SBQQ__StartDate__c = System.today().addMonths(12).addDays(-1),
            SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE, 
            Arroyo_Subsumed_Old_Contract_Line_Items__c = 'BB0000000003',
            Special_Program__c = ReplacementConstants.UPGRADE_VALUE,
            Promo_Disc__c = 0.1,
            Replacement_Details__c = '{"skuSuppType":null,"skuStorageTierVal":null,'
            + '"skuStorageBundleVal":null,"skuSFDCVal":null,"skuSelectedName":null,'
            + '"skuSelected":null,"skuM365HVal":null,"skuAttlasianVal":null,"seamlessCutover"'
            + ':null,"rowValues":[{"upgradeLines":null,"selectedTerm":12,'
            + '"selectedQty":60,"selectedAssetList":{"02i6f00000IrOveAAF":"BB0000000003"},'
            + '"selectedAsset":"02i6f00000IrOveAAF","rowId":"14.2.0","isAutoDisposition":null,'
            + '"inactiveLines":null,"entId":"5508Y000005cMw1QAE","disposition":"Refreshed",'
            + '"anyToAnyFlag":null}],"renLine":null,"refreshCategoryId":"01t6f00000Oa3G2AAJ","mode":null}',
            SBQQ__Description__c = 'test'
        )
        };

        insert lstQuoteLine;

        //creat quote template
        SBQQ__QuoteTemplate__c objQuoteTemplate = new SBQQ__QuoteTemplate__c(
            Name = 'Quote Document Test',
            SBQQ__DeploymentStatus__c = 'Deployed'
        );
        insert objQuoteTemplate;

    }

    /**
     * @description testcustom replace
     */
    @isTest
    public static void testCustomReplacement() {

        SBQQ__Quote__c quoteObj = [select id from sbqq__quote__c limit 1];
        SBQQ__QuoteTemplate__c objQuoteTemplate = [select id from SBQQ__QuoteTemplate__c limit 1];

        User admin = [SELECT Id FROM USER 
            WHERE Profile.Name=:ReplacementConstants.PROFILE_SYSTEM_ADMINISTRATOR 
              AND isActive=true LIMIT 1];
        Test.startTest();
        System.runAs(admin){
            PageReference customRepPage = Page.CustomReplacementPage;
            customRepPage.getParameters().put('qid', quoteObj.Id);
            customRepPage.getParameters().put('tid', objQuoteTemplate.Id);
            Test.setCurrentPage(customRepPage);

            CustomReplacementController controller = new CustomReplacementController();

            System.assert(controller.template != null);
        }
        Test.stopTest();

    }

    /**
     * @description test quotelines page
     */
    @isTest
    public static void testQuoteLinesPage() {

        SBQQ__Quote__c quoteObj = [select id from sbqq__quote__c limit 1];
        Entitlement ent=[SELECT Id, Name, Quantity__c,ContractLineItem.Product_Level__c,StartDate,EndDate,
                    ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__Quote__r.Name,
                    ContractLineItem.SBQQSC__OrderProduct__r.Order.OrderNumber,
                    ContractLineItem.StartDate, ContractLineItem.EndDate, 
                    ContractLineItem.SBQQSC__Quantity__c,Product__r.Product_Level__c,Product__r.ProductCode
                    FROM Entitlement Limit 1];
        SBQQ__QuoteTemplate__c objQuoteTemplate = [select id from SBQQ__QuoteTemplate__c limit 1];

        SBQQ__TemplateContent__c content = new SBQQ__TemplateContent__c(
            Name='Line Items New Custom',
            SBQQ__Type__c = 'Custom'
        );
        insert content;

        SBQQ__TemplateSection__c section = new SBQQ__TemplateSection__c(
            SBQQ__Template__c = objQuoteTemplate.Id,
            SBQQ__Content__c = content.Id,
            SBQQ__FilterField__c = 'Name',
            SBQQ__FilterOperator__c = 'not equals',
            SBQQ__FilterValue__c = 'test'
        );
        insert section;

        List<SBQQ__LineColumn__c> columns = new List<SBQQ__LineColumn__c>();
        SBQQ__LineColumn__c columnDesc = new SBQQ__LineColumn__c(
            SBQQ__Template__c = objQuoteTemplate.Id,
            Custom_Section__c = section.Id,
            SBQQ__FieldName__c = 'SBQQ__Description__c',
            SBQQ__ConditionalPrintField__c = 'SBQQ__Primary__c',
            SBQQ__Width__c = 0.1,
            SBQQ__DisplayOrder__c = 1,
            SBQQ__Alignment__c = 'Left'
        );
        columns.add(columnDesc);
        
        SBQQ__LineColumn__c columnDisc = new SBQQ__LineColumn__c(
            SBQQ__Template__c = objQuoteTemplate.Id,
            Custom_Section__c = section.Id,
            SBQQ__FieldName__c = 'SBQQ__Discount__c',
            SBQQ__Width__c = 0.1,
            SBQQ__DisplayOrder__c = 2,
            SBQQ__Alignment__c = 'Left'
        );
        columns.add(columnDisc);
        
        insert columns;

        User admin = [SELECT Id FROM USER 
         WHERE Profile.Name=:ReplacementConstants.PROFILE_SYSTEM_ADMINISTRATOR 
           AND isActive=true LIMIT 1];
        Test.startTest();
        System.runAs(admin){
            PageReference quoteLinesPage = Page.QuoteLinesPage;
            quoteLinesPage.getParameters().put('qid', quoteObj.Id);
            quoteLinesPage.getParameters().put('tid', objQuoteTemplate.Id);
            Test.setCurrentPage(quoteLinesPage);

            QuoteLinesController controller = new QuoteLinesController();
			
            CustomReplacementController objCustomReplacementController = new CustomReplacementController();
            objCustomReplacementController.populateReplacedSKU(null,null,null);//CPQ22-6053
            CustomReplacementController.ReplacedSKUWrapper inactiveWrap = new CustomReplacementController.ReplacedSKUWrapper();//CPQ22-6053
            CustomReplacementController.ReplacedSKUWrapper replacedSKUWrap = new CustomReplacementController.ReplacedSKUWrapper();
            replacedSKUWrap.assets='Asset123';
            replacedSKUWrap.productCode= 'RS-BT-FE-PE-PP';
            replacedSKUWrap.terminatedQty=1.0;
            objCustomReplacementController.populateInactiveEnt(ent,null,null);//CPQ22-6053
            objCustomReplacementController.populateInactiveEnt(ent,replacedSKUWrap,inactiveWrap);//CPQ22-6053
            System.assert(controller.template != null);
        }
        Test.stopTest();

    }
    @IsTest
    public static void createQuoteTermData() {
        User admin = [SELECT Id FROM USER 
                      WHERE Profile.Name=:ReplacementConstants.PROFILE_SYSTEM_ADMINISTRATOR 
                      AND isActive=true LIMIT 1];
        System.runAs(admin){
            //get Quote
            SBQQ__Quote__c quote = [select id from sbqq__quote__c limit 1];
            
            SBQQ__QuoteTerm__c term =new SBQQ__QuoteTerm__c(
                Quote_Term_Name__c = 'Custom_Replacement_Label',
                SBQQ__Body__c = '<p>This Quote includes the replacement of one or more product(s)...</p>',
                SBQQ__Active__c = true,
                SBQQ__PrintOrder__c= 1,
                SBQQ__Status__c = 'Approved',
                SBQQ__Quote__c = quote.Id
            );
            
            /*       // 2 — Future_Unbilled
terms.add(new SBQQ__QuoteTerm__c(
Quote_Term_Name__c = 'Future_Unbilled',
SBQQ__Body__c = '<p>With regard to the ‘Terminated SKU(s)...</p>',
SBQQ__Active__c = true,
SBQQ__PrintOrder__c= 1,
SBQQ__Status__c = 'Approved',
SBQQ__Quote__c = quote.Id
));

        // 3 — One_Time_Special_description
        terms.add(new SBQQ__QuoteTerm__c(
            Quote_Term_Name__c = 'One_Time_Special_description',
            SBQQ__Body__c = '<p>This Quote has a special One Time Discount or Credit...</p>',
            SBQQ__Active__c = true,
            SBQQ__Status__c = 'Approved',
            SBQQ__Quote__c = quote.Id
        ));

// 4 — One_Time_Special_SKU
terms.add(new SBQQ__QuoteTerm__c(
Quote_Term_Name__c = 'One_Time_Special_SKU',
SBQQ__Body__c = '<p>One-Time-Special</p>',
SBQQ__Active__c = true,
SBQQ__Status__c = 'Approved',
SBQQ__Quote__c = quote.Id
));

        // 5 — One_Time_Special_Terms
        terms.add(new SBQQ__QuoteTerm__c(
            Quote_Term_Name__c = 'One_Time_Special_Terms',
            SBQQ__Body__c = '<p>ONE-TIME PRICE REDUCTION...</p>',
            SBQQ__Active__c = true,
            SBQQ__Status__c = 'Approved',
            SBQQ__Quote__c = quote.Id
        ));

        // 6 — Outstanding_Invoice
        terms.add(new SBQQ__QuoteTerm__c(
            Quote_Term_Name__c = 'Outstanding_Invoice',
            SBQQ__Body__c = '<p>The amount remaining under invoice (&lt;invoice_info&gt;) ...</p>',
            SBQQ__Active__c = true,
            SBQQ__Status__c = 'Approved',
            SBQQ__Quote__c = quote.Id
        ));

// 7 — Renewal_Guidance
terms.add(new SBQQ__QuoteTerm__c(
Quote_Term_Name__c = 'Renewal_Guidance',
SBQQ__Body__c = '<p>This Quote includes the special one-time pricing consideration...</p>',
SBQQ__Active__c = true,
SBQQ__Status__c = 'Approved',
SBQQ__Quote__c = quote.Id
));

// 8 — Replacement_TNC
terms.add(new SBQQ__QuoteTerm__c(
Quote_Term_Name__c = 'Replacement_TNC',
SBQQ__Body__c = '<p>This Quote includes the replacement of one or more product(s)...</p>',
SBQQ__Active__c = true,
SBQQ__Status__c = 'Approved',
SBQQ__Quote__c = quote.Id
));*/
            insert term;
            
            term.SBQQ__Status__c = 'Approved';
            term.SBQQ__Active__c = true;
            Update term;
            
            Test.startTest();
            Map<String, String> results = QuoteDocumentHelper.getVerbiages(quote.Id);
            Test.stopTest();
            System.assertEquals(1, results.size(), 'Should return all provided terms.');
        }
    }
}