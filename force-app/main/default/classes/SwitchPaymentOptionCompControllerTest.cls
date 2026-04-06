@isTest
public with sharing class SwitchPaymentOptionCompControllerTest {
    
    @TestSetup
    public static void testData(){
        
        
        ShGl_TestFactoryHelper.insertTriggerControls();
        
        insert new ShGl_DisableBusinessLogic__c(SetupOwnerId=UserInfo.getOrganizationId(),Disable_Opportunity_Old_Trigger__c=false);
        
        Account account = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        account.Name ='NewAccount';
        insert account;
        
        List<Account> accountList = new List<Account>();
        Account vAccount = new Account();
        accountList.add(vAccount);
        vAccount.Name = 'Test Account';
        vAccount.Type='Distributor';
        vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
        Account vAccount2 = new Account();
        vAccount2.Name = 'Test Account';
        vAccount2.recordTypeId = vAccount.recordTypeId;
        accountList.add(vAccount2);
        insert accountList;
        
        List<Product2> lstProduct = new List<Product2>();
        Product2 productObj = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        productObj.ProductCode = 'RS-FE-GO-PE-PP';
        productObj.Product_Subtype__c = 'GO';
        productObj.Name = 'RS-FE-GO-PE-PP';
        productObj.IsActive = true;
        productObj.Product_Payment_Option__c = 'Prepay';
        lstProduct.add(productObj);
        
        Product2 productNewObj = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        productNewObj.ProductCode = 'RS-FE-GO-PE-PA';
        productNewObj.Product_Subtype__c = 'GO';
        productNewObj.Name = 'RS-FE-GO-PE-PA';
        productNewObj.IsActive = true;
        productObj.Product_Payment_Option__c = 'Annual';
        lstProduct.add(productNewObj);
        
        Product2 productNewObjsecond = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        productNewObjsecond.ProductCode = 'RBH-SVC-test';
        productNewObjsecond.Product_Subtype__c = 'GO';
        productNewObjsecond.Name = 'RBH-SVC-test';
        productNewObjsecond.IsActive = true;
        productObj.Product_Payment_Option__c = 'Annual';
        lstProduct.add(productNewObjsecond);
        insert lstProduct;
        
        Pricebook2 CPQPricebook = new Pricebook2();
        CPQPricebook.Name='CPQ PriceBook';
        CPQPricebook.IsActive=true;
        insert CPQPricebook;
        
        List<PricebookEntry> priceBookjEntryList = new List<PricebookEntry>();
        PricebookEntry pricebookObj1 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pricebookObj1.Product2Id = productObj.Id;
        pricebookObj1.UnitPrice = 100;
        pricebookObj1.Pricebook2Id = Test.getStandardPricebookId();
        pricebookObj1.IsActive = true;
        priceBookjEntryList.add(pricebookObj1);
        
        PricebookEntry pricebookObj2 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pricebookObj2.Product2Id = productNewObj.Id;
        pricebookObj2.UnitPrice = 100;
        pricebookObj2.Pricebook2Id = Test.getStandardPricebookId();
        pricebookObj2.IsActive = true;
        priceBookjEntryList.add(pricebookObj2);
        
        PricebookEntry pricebookObj3 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);new PricebookEntry();
        pricebookObj3.Product2Id = productNewObjsecond.Id;
        pricebookObj3.UnitPrice = 100;
        pricebookObj3.Pricebook2Id = Test.getStandardPricebookId();
        pricebookObj3.IsActive = true;
        priceBookjEntryList.add(pricebookObj3);
        
        insert priceBookjEntryList;
        
        List<PricebookEntry> priceBookEntryCPQList = new List<PricebookEntry>();
        PricebookEntry CPQpricebookObj1 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        CPQpricebookObj1.Product2Id = productObj.Id;
        CPQpricebookObj1.UnitPrice = 100;
        CPQpricebookObj1.Pricebook2Id = CPQPricebook.Id;
        CPQpricebookObj1.IsActive = true;
        CPQpricebookObj1.UseStandardPrice=true;
        priceBookEntryCPQList.add(CPQpricebookObj1);
        
        PricebookEntry CPQpricebookObj2 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        CPQpricebookObj2.Product2Id = productNewObj.Id;
        CPQpricebookObj2.UnitPrice = 100;
        CPQpricebookObj2.Pricebook2Id = CPQPricebook.Id;
        CPQpricebookObj2.IsActive = true;
        CPQpricebookObj2.UseStandardPrice=true;
        priceBookEntryCPQList.add(CPQpricebookObj2);
        
        PricebookEntry CPQpricebookObj3 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        CPQpricebookObj3.Product2Id = productNewObjsecond.Id;
        CPQpricebookObj3.UnitPrice = 100;
        CPQpricebookObj3.Pricebook2Id = CPQPricebook.Id;
        CPQpricebookObj3.IsActive = true;
        CPQpricebookObj3.UseStandardPrice=true;
        priceBookEntryCPQList.add(CPQpricebookObj3);
        
        insert priceBookEntryCPQList;
        
        Asset assetObj = (Asset) ShGl_TestFactory.createSObject(new Asset(), null);
        assetObj.AccountId =account.Id;
        assetObj.Name = 'SwitchPaymentOptionAsset';
        assetObj.Product2Id = productObj.Id;
        // assetObj.Eligible_for_Free_HW__c = true; // add later with string value
        assetObj.Justification_for_HW_Eligibility_Overrid__c = '-';
        assetObj.serial_number__c = 'JAY8486304222k4';
        insert assetObj;
        
        List<Opportunity> lstOpportunity = new List<Opportunity>();
        Opportunity opportunityObj = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opportunityObj.AccountId = account.Id;
        opportunityObj.Name = 'SwitchPaymentOption Opportunity';
        opportunityObj.CloseDate = System.today().addMonths(12);
        opportunityObj.StageName = 'Prospecting';
        opportunityObj.Pricebook2Id = Test.getStandardPricebookId();
        opportunityObj.Partner_Lookup__c = vAccount2.id;
        opportunityObj.Distributor_Lookup__c = vAccount.id;
        lstOpportunity.add(opportunityObj);
        
        Opportunity opportunityNewObj = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opportunityNewObj.AccountId = account.Id;
        opportunityNewObj.Name = 'SwitchPaymentOption Opportunity2';
        opportunityNewObj.CloseDate = System.today().addMonths(12);
        opportunityNewObj.StageName = 'Prospecting';
        opportunityNewObj.Pricebook2Id = Test.getStandardPricebookId();
        opportunityNewObj.Partner_Lookup__c = vAccount2.id;
        opportunityNewObj.Distributor_Lookup__c = vAccount.id;
        lstOpportunity.add(opportunityNewObj);
        insert lstOpportunity;
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(),null); 
        qt.SBQQ__Account__c = account.Id;
        qt.SBQQ__Opportunity2__c = opportunityNewObj.Id;
        insert qt;
        
        List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c qlIneA = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt.id,
            SBQQ__StartDate__c = System.today(),
            SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
            SBQQ__DefaultSubscriptionTerm__c = 12,
            SBQQ__ListPrice__c = 210,
            SBQQ__NetPrice__c = 210,
            SBQQ__Product__c = lstProduct[0].Id,
            Payment_Options__c = 'Prepay',
            SBQQ__RequiredBy__c = null,
            Product_Level__c = 'Support',
            Product_Payment_Option__c = 'Prepay',
            Product_Type__c = 'Hardware',
            SBQQ__SubscriptionTerm__c=36,
            SBQQ__Quantity__c=110,
            SubscribedAssetNames__c = 'BB1928630400246'
        );
        SBQQ__QuoteLine__c qlIneA2 = new SBQQ__QuoteLine__c (
            SBQQ__Quote__c = qt.id,
            SBQQ__StartDate__c = System.today(),
            SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
            SBQQ__DefaultSubscriptionTerm__c = 12,
            SBQQ__ListPrice__c = 20,
            SBQQ__NetPrice__c = 20,
            SBQQ__Product__c=lstProduct[1].Id,
            Payment_Options__c = 'Annual',
            SBQQ__RequiredBy__c = null,
            Product_Level__c = 'Support',
            Product_Payment_Option__c = 'Annual',
            Product_Type__c = 'Hardware',
           // SBQQ__PricebookEntryId__c = priceBookjEntryList[0].Id,
            SBQQ__SubscriptionTerm__c=36,
            SBQQ__Quantity__c=120,
            SubscribedAssetNames__c = 'BB1928632040046'
        );

        SBQQ__QuoteLine__c qlIneA12 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt.id,
            SBQQ__StartDate__c = System.today(),
            SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
            SBQQ__DefaultSubscriptionTerm__c = 12,
            SBQQ__ListPrice__c = 2300,
            SBQQ__NetPrice__c = 2040,
            SBQQ__Product__c=lstProduct[0].Id,
            Payment_Options__c = 'Annual',
            SBQQ__RequiredBy__c = null,
            Product_Level__c = 'Support',
            Product_Payment_Option__c = 'Annual',
            Product_Type__c = 'Hardware',
            SBQQ__SubscriptionTerm__c=36,
            SBQQ__Quantity__c=150,
            SubscribedAssetNames__c = 'BB1928634040046'
        );


        lines.add(qlIneA);
        lines.add(qlIneA2);
        lines.add(qlIneA12);
        insert lines;
    }
    
    @isTest
    public static void insertEntitlementLinksTest() {
        
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        System.debug('+==quote'+  Id.valueOf(quote.Id));
        Test.startTest();
        SwitchPaymentOptionCompController.showQuotesLinesProducts(string.valueOf(quote.Id));
        Test.stopTest();
    }
    
    @isTest
    public static void SwitchPaymentOptionTest() {
        
        List<SBQQ__QuoteLine__c> quoteLineList = [SELECT Id,Product_Payment_Option__c,SBQQ__Product__c FROM SBQQ__QuoteLine__c];
        
        List<SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper> qlDataWrapper = new List<SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper>();
        
        SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper wrapper1 = new SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper();
        wrapper1.quoteLine = quoteLineList[0];
        wrapper1.changedName = 'RS-FE-GO-PE-PA';
        wrapper1.picklistValue = 'Annual';
        qlDataWrapper.add(wrapper1);
        
        SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper wrapper2 = new SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper();
        wrapper2.quoteLine = quoteLineList[1];
        wrapper2.changedName = 'RS-FE-GO-PE-PP';
        wrapper2.picklistValue = 'Annual';
        qlDataWrapper.add(wrapper2);
        
        SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper wrapper3 = new SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper();
        wrapper3.quoteLine = quoteLineList[1];
        wrapper3.changedName = 'RS-FE-GO-PE-PP';
        wrapper3.picklistValue = 'Annual';
        qlDataWrapper.add(wrapper3);
        
        String qlDataWrapperSerizlized = JSON.serialize(qlDataWrapper);
        
        Test.startTest();
        SwitchPaymentOptionCompController.switchPaymentOption(qlDataWrapperSerizlized);
        Test.stopTest();
    }
    
    @isTest
    public static void SwitchPaymentOptionNegativeTest() {
        
        List<SBQQ__QuoteLine__c> quoteLineList = [SELECT Id, SBQQ__Product__c FROM SBQQ__QuoteLine__c];
        
        List<SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper> qlDataWrapper = new List<SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper>();
        List<SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper> qlDataWrapper1 = new List<SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper>();
        
        SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper wrapper1 = new SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper();
        wrapper1.quoteLine = quoteLineList[0];
        wrapper1.changedName = 'RS-FE-GO-PE-PA';
        wrapper1.picklistValue = 'Prepay';
        qlDataWrapper.add(wrapper1); 
        
        String qlDataWrapperSerizlized = JSON.serialize(qlDataWrapper);
        String qlDataWrapperSerizlized1 = JSON.serialize(qlDataWrapper1);
        
        Test.startTest();
        SwitchPaymentOptionCompController.switchPaymentOption(qlDataWrapperSerizlized);
        SwitchPaymentOptionCompController.switchPaymentOption(qlDataWrapperSerizlized1);
        Test.stopTest();
    }
    @isTest
    public static void SwitchPaymentOptionTest1() {
        List<SBQQ__QuoteLine__c> quoteLineList = [SELECT Id,Product_Payment_Option__c,SBQQ__Product__c FROM SBQQ__QuoteLine__c ORDER BY Id];
        
        List<SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper> qlDataWrapper = new List<SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper>();
        
        SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper wrapper1 = new SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper();
        wrapper1.quoteLine = quoteLineList[0];
        wrapper1.changedName = 'RS-FE-GO-PE-PA';
        wrapper1.picklistValue = 'Annual';
        qlDataWrapper.add(wrapper1);
        
        SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper wrapper2 = new SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper();
        wrapper2.quoteLine = quoteLineList[1];
        wrapper2.changedName = 'RS-FE-GO-PE-PP';
        wrapper2.picklistValue = 'Prepay';
        qlDataWrapper.add(wrapper2);
        
        String qlDataWrapperSerizlized = JSON.serialize(qlDataWrapper);
        
        Test.startTest();
        SwitchPaymentOptionCompController.switchPaymentOption(qlDataWrapperSerizlized);
        Test.stopTest();
    }
    
    @isTest
    public static void SwitchPaymentOptionNegativeTest1() {
        
        List<Product2> productList = [Select Id,
                                      IsActive
                                      FROM Product2
                                      WHERE NAME='RS-FE-GO-PE-PA'];
        productList[0].IsActive=false;
        update productList;
        
        List<SBQQ__QuoteLine__c> quoteLineList = [SELECT Id,Product_Payment_Option__c,SBQQ__Product__c FROM SBQQ__QuoteLine__c];
        
        List<SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper> qlDataWrapper = new List<SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper>();
        
        SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper wrapper1 = new SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper();
        wrapper1.quoteLine = quoteLineList[0];
        wrapper1.changedName = 'RS-FE-GO-PE-PP';
        wrapper1.picklistValue = 'Prepay';
        qlDataWrapper.add(wrapper1);
        
        String qlDataWrapperSerizlized = JSON.serialize(qlDataWrapper);
        
        Test.startTest();
        SwitchPaymentOptionCompController.switchPaymentOption(qlDataWrapperSerizlized);
        Test.stopTest();
    }
    /*@isTest
    public static void SwitchPaymentOptionNegativeTest2() {
        
        List<Product2> productList = [Select Id,
                                      IsActive
                                      FROM Product2
                                      WHERE NAME='RS-FE-GO-PE-PA'];
        productList[0].Name='Product';
        update productList;
        
        List<SBQQ__QuoteLine__c> quoteLineList = [SELECT Id,Product_Payment_Option__c,SBQQ__Product__c FROM SBQQ__QuoteLine__c];
        
        List<SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper> qlDataWrapper = new List<SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper>();
        
        SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper wrapper1 = new SwitchPaymentOptionCompController.SelectedQuoteLineDataWrapper();
        wrapper1.quoteLine = quoteLineList[0];
        wrapper1.changedName = 'Product';
        wrapper1.picklistValue = 'Annual';
        qlDataWrapper.add(wrapper1);
        
        String qlDataWrapperSerizlized = JSON.serialize(qlDataWrapper);
        
        Test.startTest();
        SwitchPaymentOptionCompController.switchPaymentOption(qlDataWrapperSerizlized);
        Test.stopTest();
    }*/
}