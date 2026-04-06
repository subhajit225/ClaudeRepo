/* Test Class for metricCalcForArroyoBatch and Queueable */

@isTest
public with sharing class metricCalcForArroyoBatchTest{
    
    @TestSetUp
    static void initialDataSetup() {
        TriggerControl__c setting1 = new TriggerControl__c();
        setting1.Name = 'Opportunity';
        setting1.DisableTrigger__c = TRUE;
        insert setting1;
        
        TriggerControl__c setting2 = new TriggerControl__c();
        setting2.Name = 'Entitlement';
        setting2.DisableTrigger__c = TRUE;
        insert setting2;
        
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        upsert disableFuncCS;
        
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Validation_Rules__c = True,
                                                                            Disable_SBQQ_Quote_Triggers__c = True,
                                                                            Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
                                                                            Disable_SBQQ_QuoteLine_Triggers__c = True,
                                                                            Disable_Opportunity_Validation_Rules__c = True,
                                                                            Disable_Opportunity_Triggers__c = True);
        insert cdf;
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User usr = new user(
            alias = 'std',
            email = 'cpqadmin@testclass.com',
            emailencodingkey = 'UTF-8',
            firstname = 'CPQ',
            lastname = 'Admin',
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            profileid = p.Id,
            timezonesidkey = 'America/Los_Angeles',
            username = 'cpqadmin@rbktest.com'
        );
        insert usr;
        ShGl_DisableBusinessLogic__c sdbl = new ShGl_DisableBusinessLogic__c(
            setupownerid = usr.Id,
            Disable_Account_Triggers__c = true,
            Disable_Asset_Triggers__c = true,
            Disable_SBQQ_QuoteLine_Triggers__c = true,
            Disable_SBQQ_Quote_Triggers__c = true,
            Disable_Order_Old_Trigger__c = true,
            Disable_OrderItem_Old_Trigger__c = true,
            Disable_Opportunity_Triggers__c = true,
            Disable_Opportunity_Validation_Rules__c = true,
            Enable_Logs__c = true
        );
        insert sdbl;
        
        Account accObj = TestDataFactory.getAccount();
        insert accObj;
        
        Opportunity oppr = TestDataFactory.getOpportunity(accObj);
        insert oppr;
        
        Id standardPriceBookId =  Test.getStandardPricebookId();
        
        PriceBook2 pb1  = new Pricebook2(Name = 'V68_2017_08_09_12_26_43', Description = 'Price Book 2009 Products 1', IsActive = true);
        insert pb1;
        
        Product2 prod1 = new Product2(
            Name = 'RBK-GO-BE-R6408',
            ProductCode = 'RBK-GO-BE-R6408',
            isActive = true
        );
        Product2 prod2 = new Product2(
            Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
            ProductCode = 'RBK-SVC-PREM-R304',
            isActive = true
        );
        
        insert new List<Product2>{prod1, prod2};
            
            PricebookEntry pbStanEntry1 = new PricebookEntry(
                Pricebook2Id = standardPriceBookId,
                Product2Id = prod1.Id,
                UnitPrice = 100.00,
                IsActive = true
            );
        PricebookEntry pbStanEntry2 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbEntry1 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod1.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        PricebookEntry pbEntry2 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        insert new List<PricebookEntry>{pbStanEntry1, pbStanEntry2, pbEntry1, pbEntry2};
            
            Map<String, Object>  quoteMap = new Map<String, Object> {'SBQQ__Account__c' => accObj.Id,'SBQQ__Opportunity2__c' => oppr.Id};
                
                List<SBQQ__Quote__c> listArroyoQuotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppr.Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__PriceBook__c = pb1.Id;
        qt1.ApprovalStatus__c = 'Approved';
        qt1.SBQQ__Type__c = 'Renewal';
        qt1.SBQQ__StartDate__c = Date.today();
        qt1.Manual_Billing__c = false;
        qt1.Consolidate_Lines__c = false;
        insert qt1;
        listArroyoQuotes.add(qt1);
        
        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c ql0 = new SBQQ__QuoteLine__c(Product_Level__c = 'Wrapper', SBQQ__Quote__c = qt1.Id, Prior_Net_Total__c = 10, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10));
        SBQQ__QuoteLine__c ql00 = new SBQQ__QuoteLine__c(SBQQ__RequiredBy__c = ql0.Id, SBQQ__Quote__c = qt1.Id, Prior_Net_Total__c = 10, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10));
        SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, Prior_Net_Total__c = 10, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046' );
        SBQQ__QuoteLine__c ql2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, Prior_Net_Total__c = 0, SBQQ__Product__c = prod2.Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SubscribedAssetNames__c = 'BB192863040047');
        SBQQ__QuoteLine__c ql3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040048');
        SBQQ__QuoteLine__c ql4 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SubscribedAssetNames__c = 'BB192863040049');
        lines.add(ql1);
        lines.add(ql0);
        lines.add(ql00);
        insert lines;
        
        Datetime yesterday = Datetime.now().addDays(-1);
        Test.setCreatedDate(qt1.Id, yesterday);
    }
    
    /* testBatchSuccessProcessing */
    public static testMethod void testBatchSuccessProcessing() {
        TriggerControl__c setting1a = new TriggerControl__c();
        setting1a.Name = 'Opportunity';
        setting1a.DisableTrigger__c = TRUE;
        insert setting1a;
        
        ShGl_DisableFunctionalityLogic__c disableFuncCSa = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCSa.Disable_Opportunity_Old_Trigger__c = true;
        upsert disableFuncCSa;
        
        ShGl_DisableBusinessLogic__c cdfa = new ShGl_DisableBusinessLogic__c(SetupOwnerId = userInfo.getUserId(), 
                                                                             Disable_SBQQ_Quote_Validation_Rules__c = True,
                                                                             Disable_SBQQ_Quote_Triggers__c = True,
                                                                             Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
                                                                             Disable_SBQQ_QuoteLine_Triggers__c = True,
                                                                             Disable_Opportunity_Validation_Rules__c = True,
                                                                             Disable_Opportunity_Triggers__c = True);
        insert cdfa;
        
        Account accObj1 = TestDataFactory.getAccount();
        insert accObj1;
        
        Opportunity oppr1 = TestDataFactory.getOpportunity(accObj1);
        insert oppr1;
        
        Id standardPriceBookId =  Test.getStandardPricebookId();
        
        PriceBook2 pb1a  = new Pricebook2(Name = 'V68_2017_08_09_12_26_43', Description = 'Price Book 2009 Products 1', IsActive = true);
        insert pb1a;
        
        Product2 prod1a = new Product2(
            Name = 'RBK-GO-BE-R6408',
            ProductCode = 'RBK-GO-BE-R6408',
            isActive = true
        );
        Product2 prod2a = new Product2(
            Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
            ProductCode = 'RBK-SVC-PREM-R304',
            isActive = true
        );
        Product2 prod3a = new Product2(
            Name = 'RBK-SVC-PREM-APPLIANCE',
            ProductCode = 'RBK-SVC-PREM-APPLIANCE',
            isActive = true
        );
        insert new List<Product2>{prod1a, prod2a, prod3a};
            
            PricebookEntry pbStanEntrya1 = new PricebookEntry(
                Pricebook2Id = standardPriceBookId,
                Product2Id = prod1a.Id,
                UnitPrice = 100.00,
                IsActive = true
            );
        PricebookEntry pbStanEntrya2 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod2a.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbStanEntrya3 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod3a.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbEntrya1 = new PricebookEntry(
            Pricebook2Id = pb1a.id,
            Product2Id = prod1a.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        PricebookEntry pbEntrya2 = new PricebookEntry(
            Pricebook2Id = pb1a.id,
            Product2Id = prod2a.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbEntrya3 = new PricebookEntry(
            Pricebook2Id = pb1a.id,
            Product2Id = prod3a.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        insert new List<PricebookEntry>{pbStanEntrya1,pbStanEntrya2,pbStanEntrya3, pbEntrya1,pbEntrya2,pbEntrya3 };
            
            Map<String, Object>  quoteMap = new Map<String, Object> {'SBQQ__Account__c' => accObj1.Id,'SBQQ__Opportunity2__c' => oppr1.Id};
                
                
                Set<Id> quoteId = new Set<Id>();
        
        SBQQ__Quote__c qta1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qta1.SBQQ__Opportunity2__c = oppr1.Id;
        qta1.SBQQ__Primary__c = true;
        qta1.SBQQ__PriceBook__c = pb1a.Id;
        qta1.SBQQ__Status__c = 'Draft';
        qta1.SBQQ__Type__c = 'Renewal';
        qta1.SBQQ__StartDate__c = Date.today();
        qta1.Manual_Billing__c = false;
        qta1.Consolidate_Lines__c = false;
        insert qta1;
        
        qta1.MetricsLastCalcOn__c = System.today()+1;
        update qta1;
        
        quoteId.add(qta1.Id);
        Id quoteRecId = qta1.Id;
        
        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c qla1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qta1.Id, SBQQ__Product__c = prod1a.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046', 
                                                         //SubsAstNameInt__c = 'BB192863040046',
                                                         Prior_Net_Total__c = 10);
        SBQQ__QuoteLine__c qla2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qta1.Id, SBQQ__Product__c = prod2a.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SubscribedAssetNames__c = 'BB192863040047', 
                                                         //SubsAstNameInt__c = 'BB192863040047', 
                                                         Prior_Net_Total__c = 0, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        SBQQ__QuoteLine__c qla3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qta1.Id, SBQQ__Product__c = prod1a.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040048');
        SBQQ__QuoteLine__c qla4 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qta1.Id, SBQQ__Product__c = prod2a.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SubscribedAssetNames__c = 'BB192863040049', 
                                                         //SubsAstNameInt__c = 'BB192863040049', 
                                                         MSP_Segment_Product__c = true, SBQQ__Segmentindex__c  = 1);
        SBQQ__QuoteLine__c qla5 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qta1.Id, SBQQ__Product__c = prod3a.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SubscribedAssetNames__c = 'BB192863040047', 
                                                         //SubsAstNameInt__c = 'BB192863040047', 
                                                         Prior_Net_Total__c = 0, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        SBQQ__QuoteLine__c qla0 = new SBQQ__QuoteLine__c(Product_Level__c = 'Wrapper', SBQQ__Quote__c = qta1.Id, Prior_Net_Total__c = 10, SBQQ__Product__c = prod1a.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10));
        SBQQ__QuoteLine__c qla00 = new SBQQ__QuoteLine__c(SBQQ__RequiredBy__c = qla0.Id, SBQQ__Quote__c = qta1.Id, Prior_Net_Total__c = 10, SBQQ__Product__c = prod1a.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10));
        
        lines.add(qla1);
        lines.add(qla2);
        lines.add(qla3);
        lines.add(qla4);
        lines.add(qla5);
        lines.add(qla0);
        lines.add(qla00);
        Test.startTest();
        insert lines;
        
        
        //metricCalcForArroyoQueueable_v2 queuableClass = new metricCalcForArroyoQueueable_v2();
        metricCalcForArroyoBatch queuableClass = new metricCalcForArroyoBatch(quoteRecId);
        metricCalcForArroyoBatch queuableClassMulti = new metricCalcForArroyoBatch(new Set<Id>{quoteRecId});

        //metricCalcForArroyoBatch queuableClass = new metricCalcForArroyoBatch(new Set<Id>{quoteRecId});
        Id batchJobId1 = Database.executeBatch(queuableClass);
        //queuableClass.calculateMetrics(quoteId);
        Id batchJobId = Database.executeBatch(new metricCalcForArroyoBatch());
        System.assert(batchJobId != null);
        System.assert(batchJobId1 != null);
        Test.stopTest();   
    }
    
    /* testSchedulableSuccessProcessing */
    public static testMethod void testSchedulableSuccessProcessing() {
        Test.startTest();
        Id batchJobId = System.schedule('Arroyo Test', '0 43 17 1/1 * ? *', new metricCalcForArroyoBatch());
        System.assert(batchJobId != null);
        Test.stopTest();  
    }
    
    /* testQueuableSuccessProcessing */
    public static testMethod void testQueuableSuccessProcessing() {
        TriggerControl__c setting1 = new TriggerControl__c();
        setting1.Name = 'Opportunity';
        setting1.DisableTrigger__c = TRUE;
        insert setting1;
        TriggerControl__c setting2 = new TriggerControl__c();
        setting2.Name = 'Renewal Case';
        setting2.DisableTrigger__c = FALSE;
        insert setting2;
        
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        upsert disableFuncCS;
        
        ShGl_DisableBusinessLogic__c cdf1 = new ShGl_DisableBusinessLogic__c(SetupOwnerId = userInfo.getUserId(),
                                                                             Disable_SBQQ_Quote_Validation_Rules__c = True,
                                                                             Disable_SBQQ_Quote_Triggers__c = True,
                                                                             Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
                                                                             Disable_SBQQ_QuoteLine_Triggers__c = True,
                                                                             Disable_Opportunity_Validation_Rules__c = True,
                                                                             Disable_Opportunity_Triggers__c = True,
                                                                             Disable_ServiceContract_Trigger__c = True,
                                                                             Disable_Contract_Line_Item_Triggers__c = True);
        insert cdf1;
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        
        Account accObj = TestDataFactory.getAccount();
        insert accObj;
        Account accObj1 = TestDataFactory.getAccount();
        accObj1.Name = 'RUBRIK_ACC_NAME';
        insert accObj1;
        Account rbkAcc = new Account(Name='Rubrik');
        insert rbkAcc;
        
        Opportunity oppr = TestDataFactory.getOpportunity(accObj);
        insert oppr;
        
        Id standardPriceBookId =  Test.getStandardPricebookId();
        
        PriceBook2 pb1  = new Pricebook2(Name = 'V68_2017_08_09_12_26_43', Description = 'Price Book 2009 Products 1', IsActive = true);
        insert pb1;
        
        Product2 prod1 = new Product2(
            Name = 'RBK-GO-BE-R6408',
            ProductCode = 'RBK-GO-BE-R6408',
            isActive = true,
            SBQQ__SubscriptionTerm__c = 1
            //Product_Type__c = 'HW Support'
        );
        Product2 prod2 = new Product2(
            Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
            ProductCode = 'RBK-SVC-PREM-R304',
            isActive = true,
            SBQQ__SubscriptionTerm__c = 1,
            Product_Type__c = 'HW Support'
        );
        Product2 prod3 = new Product2(
            Name = 'RBK-SVC-PREM-APPLIANCE',
            ProductCode = 'RBK-SVC-PREM-APPLIANCE',
            isActive = true,
            SBQQ__SubscriptionTerm__c = 1,
            Product_Type__c = 'HW Support'
        );
        insert new List<Product2>{prod1, prod2, prod3};
            
            PricebookEntry pbStanEntry1 = new PricebookEntry(
                Pricebook2Id = standardPriceBookId,
                Product2Id = prod1.Id,
                UnitPrice = 100.00,
                IsActive = true
            );
        
        PricebookEntry pbStanEntry2 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        
        PricebookEntry pbStanEntry3 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        
        PricebookEntry pbEntry1 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod1.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        
        PricebookEntry pbEntry2 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbEntry3 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        insert new List<PricebookEntry>
        {pbStanEntry1, pbStanEntry2, pbStanEntry3, pbEntry1,pbEntry2, pbEntry3};
            
            
            
            Map<String, Object>  quoteMap = new Map<String, Object> 
        {'SBQQ__Account__c' => accObj.Id,'SBQQ__Opportunity2__c' => oppr.Id};
            
            Set<Id> quoteId = new Set<Id>();
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppr.Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__PriceBook__c = pb1.Id;
        qt1.SBQQ__Status__c = 'Draft';
        qt1.SBQQ__Type__c = 'Renewal';
        qt1.SBQQ__StartDate__c = Date.today();
        qt1.Manual_Billing__c = false;
        qt1.Consolidate_Lines__c = false;
        insert qt1;
        
        qt1.MetricsLastCalcOn__c = System.today()+1;
        //qt1.LastModifiedDate = System.today()+2;
        update qt1;
        
        quoteId.add(qt1.Id);
        
        List<ServiceContract> lstServiceContract = new List<ServiceContract>();
        
        ServiceContract serviceContractObj = new ServiceContract();
        serviceContractObj.Name = 'EntitlementTriggerHelper Contract';
        serviceContractObj.SBQQSC__Opportunity__c = oppr.Id;
        serviceContractObj.AccountId = accObj.Id;
        serviceContractObj.StartDate = System.today();
        serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj.Term = 36;
        lstServiceContract.add(serviceContractObj);
        
        ServiceContract renewServiceContractObj = new ServiceContract();
        renewServiceContractObj.Name = 'EntitlementTriggerHelper Contract';
        renewServiceContractObj.SBQQSC__Opportunity__c = oppr.Id;
        renewServiceContractObj.AccountId = accObj.Id;
        renewServiceContractObj.StartDate = System.today();
        renewServiceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        renewServiceContractObj.Term = 36;
        lstServiceContract.add(renewServiceContractObj);
        insert lstServiceContract;
        
        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObj.PricebookEntryId = pbStanEntry1.Id;
        ContractLineItemObj.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.UnitPrice = 100;
        insert ContractLineItemObj;
        ContractLineItem ContractLineItemObj1 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj1.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObj1.PricebookEntryId = pbEntry1.Id;
        ContractLineItemObj1.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj1.Quantity = 10;
        ContractLineItemObj1.UnitPrice = 100;
        
        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c(PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 10007, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', SBQQSC__RenewedContractLine__c = ContractLineItemObj.id, CCLI__c = ContractLineItemObj.id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046', 
                                                        //SubsAstNameInt__c = 'BB192863040046', 
                                                        Prior_Net_Total__c = 21000);
        SBQQ__QuoteLine__c ql11 = new SBQQ__QuoteLine__c(PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 10007, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', SBQQSC__RenewedContractLine__c = null, CCLI__c = ContractLineItemObj.id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046', 
                                                         //SubsAstNameInt__c = 'BB192863040046', 
                                                         Prior_Net_Total__c = 21000);
        
        SBQQ__QuoteLine__c ql2 = new SBQQ__QuoteLine__c(SBQQ__RequiredBy__c= ql1.Id,SubscribedAssetNames__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011', 
                                                        //SubsAstNameInt__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011',
                                                        PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 107, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480011',SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Refreshed',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        SBQQ__QuoteLine__c ql22 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011', 
                                                         //SubsAstNameInt__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011', 
                                                         PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 107, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480011',SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Refreshed',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod3.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, SBQQ__RequiredBy__c = ql2.Id);
        
        SBQQ__QuoteLine__c ql3 = new SBQQ__QuoteLine__c(Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010', Special_Program__c = 'Conversion', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'None',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(10),Prior_Net_Total__c = 21000);
        SBQQ__QuoteLine__c ql4 = new SBQQ__QuoteLine__c(Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010', Special_Program__c = 'Conversion', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'None', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SubscribedAssetNames__c = 'BB192863040049', 
                                                        //SubsAstNameInt__c = 'BB192863040049', 
                                                        Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c  = 1);
        SBQQ__QuoteLine__c ql5 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010', 
                                                        //SubsAstNameInt__c = 'AA165203480092, AA165203480109, AA164403480010',
                                                        PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 107, Arroyo_Subscribed_Asset_Name__c = 'AA165203480093', SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'HW SUPPORT', Product_Type__c = 'HW Support', Disposition_Reason__c = 'Converted',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        
        SBQQ__QuoteLine__c ql6 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010', 
                                                        //SubsAstNameInt__c = 'AA165203480092, AA165203480109, AA164403480010', 
                                                        PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 207, Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010', SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Replaced', Replace_By__c = prod2.ProductCode, SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        
        SBQQ__QuoteLine__c ql0 = new SBQQ__QuoteLine__c(Product_Level__c = 'Wrapper', PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 10007, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', SBQQSC__RenewedContractLine__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046', 
                                                        //SubsAstNameInt__c = 'BB192863040046', 
                                                        Prior_Net_Total__c = 21000);
        SBQQ__QuoteLine__c ql00 = new SBQQ__QuoteLine__c(SBQQ__RequiredBy__c = ql0.Id, PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 10007, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', SBQQSC__RenewedContractLine__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046', 
                                                         //SubsAstNameInt__c = 'BB192863040046', 
                                                         Prior_Net_Total__c = 21000);
        
        lines.add(ql1);
        lines.add(ql11);
        lines.add(ql2);
        lines.add(ql22);
        lines.add(ql3);
        lines.add(ql4);
        lines.add(ql5);
        lines.add(ql6);
        lines.add(ql0);
        lines.add(ql00);
        Test.startTest();
        insert lines;
        
        
        metricCalcForArroyoQueueable_v2 queueableClass = new metricCalcForArroyoQueueable_v2(quoteId);
        System.enqueueJob(queueableClass);
        
        
        ql1.Arroyo_Subscribed_Asset_Name__c = null;
        ql2.Arroyo_Subscribed_Asset_Name__c = null;
        ql22.Arroyo_Subscribed_Asset_Name__c = null;
        ql3.Arroyo_Subscribed_Asset_Name__c = null;
        ql4.Arroyo_Subscribed_Asset_Name__c = null;
        ql5.Arroyo_Subscribed_Asset_Name__c = null;
        ql6.Arroyo_Subscribed_Asset_Name__c = null;
        ql1.Disposition_Reason__c = null;
        update lines; 
        
        metricCalcForArroyoQueueable_v2 queueableClass1 = new metricCalcForArroyoQueueable_v2(quoteId);
        System.enqueueJob(queueableClass1);
        
        ql1.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql2.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql22.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql3.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql4.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql5.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql6.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        update lines; 
        
        metricCalcForArroyoQueueable_v2 queueableClass0 = new metricCalcForArroyoQueueable_v2(quoteId);
        System.enqueueJob(queueableClass0);
        
        ql1.SubscribedAssetNames__c = null;
        ql2.SubscribedAssetNames__c = null;
        ql22.SubscribedAssetNames__c = null;
        ql3.SubscribedAssetNames__c = null;
        ql4.SubscribedAssetNames__c = null;
        ql5.SubscribedAssetNames__c = null;
        ql6.SubscribedAssetNames__c = null;
        update lines;
        
        metricCalcForArroyoQueueable_v2 queueableClass2 = new metricCalcForArroyoQueueable_v2(quoteId);
        System.enqueueJob(queueableClass2);
        
        ql1.SubsRenAmt__c = 10;
        ql2.SubsRenAmt__c = 10;
        ql22.SubsRenAmt__c = 10;
        ql3.SubsRenAmt__c = 10;
        ql4.SubsRenAmt__c = 10;
        ql5.SubsRenAmt__c = 10;
        ql6.SubsRenAmt__c = 10;
        
        ql1.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        ql2.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        ql22.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        ql3.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        ql4.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        ql5.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        ql6.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        update lines;
        
        metricCalcForArroyoQueueable_v2 queueableClass3 = new metricCalcForArroyoQueueable_v2(quoteId);
        System.enqueueJob(queueableClass3);
        
        ql1.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        ql2.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        ql22.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        ql3.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        ql4.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        ql5.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        ql6.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        update lines;
        
        metricCalcForArroyoQueueable_v2 queueableClass4 = new metricCalcForArroyoQueueable_v2(quoteId);
        System.enqueueJob(queueableClass4);
        
        ql1.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        ql2.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        ql22.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        ql3.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        ql4.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        ql5.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        ql6.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        update lines;
        
        metricCalcForArroyoQueueable_v2 queueableClass5 = new metricCalcForArroyoQueueable_v2(quoteId);
        Id qJobId = System.enqueueJob(queueableClass5);
        System.assert(qJobId != null);
        Test.stopTest();
    }
    
    /* TestMethod 4 to cover metricCal Q */
    public static testMethod void testQProcessing() {
        TriggerControl__c setting1 = new TriggerControl__c();
        setting1.Name = 'Opportunity';
        setting1.DisableTrigger__c = TRUE;
        insert setting1;
        TriggerControl__c setting2 = new TriggerControl__c();
        setting2.Name = 'Renewal Case';
        setting2.DisableTrigger__c = FALSE;
        insert setting2;
        
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        upsert disableFuncCS;
        
        ShGl_DisableBusinessLogic__c cdf1 = new ShGl_DisableBusinessLogic__c(SetupOwnerId = userInfo.getUserId(),
                                                                             Disable_SBQQ_Quote_Validation_Rules__c = True,
                                                                             Disable_SBQQ_Quote_Triggers__c = True,
                                                                             Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
                                                                             Disable_SBQQ_QuoteLine_Triggers__c = True,
                                                                             Disable_Opportunity_Validation_Rules__c = True,
                                                                             Disable_Opportunity_Triggers__c = True,
                                                                             Disable_ServiceContract_Trigger__c = True,
                                                                             Disable_Contract_Line_Item_Triggers__c = True);
        insert cdf1;
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        
        Account accObj = TestDataFactory.getAccount();
        insert accObj;
        Account accObj1 = TestDataFactory.getAccount();
        accObj1.Name = 'RUBRIK_ACC_NAME';
        insert accObj1;
        Account rbkAcc = new Account(Name='Rubrik');
        insert rbkAcc;
        
        Opportunity oppr = TestDataFactory.getOpportunity(accObj);
        insert oppr;
        
        Id standardPriceBookId =  Test.getStandardPricebookId();
        
        PriceBook2 pb1  = new Pricebook2(Name = 'V68_2017_08_09_12_26_43', Description = 'Price Book 2009 Products 1', IsActive = true);
        insert pb1;
        
        Product2 prod1 = new Product2(
            Name = 'RBK-GO-BE-R6408',
            ProductCode = 'RBK-GO-BE-R6408',
            isActive = true,
            SBQQ__SubscriptionTerm__c = 1
            //Product_Type__c = 'HW Support'
        );
        Product2 prod112 = new Product2(
            Name = 'RBK-GO-BE-R6410',
            ProductCode = 'RBK-GO-BE-R6410',
            isActive = true,
            SBQQ__SubscriptionTerm__c = 1
            //Product_Type__c = 'HW Support'
        );
        Product2 prod2 = new Product2(
            Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
            ProductCode = 'RBK-SVC-PREM-R304',
            isActive = true,
            SBQQ__SubscriptionTerm__c = 1,
            Product_Type__c = 'HW Support'
        );
        Product2 prod3 = new Product2(
            Name = 'RBK-SVC-PREM-APPLIANCE',
            ProductCode = 'RBK-SVC-PREM-APPLIANCE',
            isActive = true,
            SBQQ__SubscriptionTerm__c = 1,
            Product_Type__c = 'HW Support'
        );
        insert new List<Product2>{prod1, prod2, prod3, prod112};
            
            PricebookEntry pbStanEntry1 = new PricebookEntry(
                Pricebook2Id = standardPriceBookId,
                Product2Id = prod1.Id,
                UnitPrice = 100.00,
                IsActive = true
            );
        PricebookEntry pbStanEntry112 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod112.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        PricebookEntry pbStanEntry2 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbStanEntry3 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbEntry1 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod1.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        PricebookEntry pbEntry112 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod112.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        PricebookEntry pbEntry2 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbEntry3 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        insert new List<PricebookEntry>
        {pbStanEntry1, pbStanEntry2, pbStanEntry3, pbEntry1,pbEntry2, pbEntry3, pbStanEntry112, pbEntry112};
            
            
            
            Map<String, Object>  quoteMap = new Map<String, Object> 
        {'SBQQ__Account__c' => accObj.Id,'SBQQ__Opportunity2__c' => oppr.Id};
            
            Set<Id> quoteId = new Set<Id>();
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppr.Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__PriceBook__c = pb1.Id;
        qt1.SBQQ__Status__c = 'Draft';
        qt1.SBQQ__Type__c = 'Renewal';
        qt1.SBQQ__StartDate__c = Date.today();
        qt1.Manual_Billing__c = false;
        qt1.Consolidate_Lines__c = false;
        insert qt1;
        
        qt1.MetricsLastCalcOn__c = System.today()+1;
        //qt1.LastModifiedDate = System.today()+2;
        update qt1;
        
        quoteId.add(qt1.Id);
        
        List<ServiceContract> lstServiceContract = new List<ServiceContract>();
        
        ServiceContract serviceContractObj = new ServiceContract();
        serviceContractObj.Name = 'EntitlementTriggerHelper Contract';
        serviceContractObj.SBQQSC__Opportunity__c = oppr.Id;
        serviceContractObj.AccountId = accObj.Id;
        serviceContractObj.StartDate = System.today();
        serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj.Term = 36;
        lstServiceContract.add(serviceContractObj);
        
        ServiceContract renewServiceContractObj = new ServiceContract();
        renewServiceContractObj.Name = 'EntitlementTriggerHelper Contract';
        renewServiceContractObj.SBQQSC__Opportunity__c = oppr.Id;
        renewServiceContractObj.AccountId = accObj.Id;
        renewServiceContractObj.StartDate = System.today();
        renewServiceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        renewServiceContractObj.Term = 36;
        lstServiceContract.add(renewServiceContractObj);
        insert lstServiceContract;
        
        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObj.PricebookEntryId = pbStanEntry1.Id;
        ContractLineItemObj.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.UnitPrice = 100;
        insert ContractLineItemObj;
        ContractLineItem ContractLineItemObj1 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj1.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObj1.PricebookEntryId = pbStanEntry112.Id;
        ContractLineItemObj1.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj1.Quantity = 10;
        ContractLineItemObj1.UnitPrice = 100;
        insert ContractLineItemObj1;
        
        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c(PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 10007, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', SBQQSC__RenewedContractLine__c = ContractLineItemObj.id, CCLI__c = ContractLineItemObj.id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046', 
                                                        //SubsAstNameInt__c = 'BB192863040046', 
                                                        Prior_Net_Total__c = 21000);
        SBQQ__QuoteLine__c ql11 = new SBQQ__QuoteLine__c(PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 10007, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', SBQQSC__RenewedContractLine__c = null, CCLI__c = ContractLineItemObj.id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046', 
                                                         //SubsAstNameInt__c = 'BB192863040046', 
                                                         Prior_Net_Total__c = 21000);
        SBQQ__QuoteLine__c ql112 = new SBQQ__QuoteLine__c(PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 10007, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', SBQQSC__RenewedContractLine__c = ContractLineItemObj1.id, CCLI__c = ContractLineItemObj.id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Churn', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod112.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046', 
                                                          //SubsAstNameInt__c = 'BB192863040046', 
                                                          Prior_Net_Total__c = 21000);
        
        
        SBQQ__QuoteLine__c ql2 = new SBQQ__QuoteLine__c(SBQQ__RequiredBy__c= ql1.Id,SubscribedAssetNames__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011', 
                                                        //SubsAstNameInt__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011',
                                                        PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 107, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480011',SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Refreshed',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        SBQQ__QuoteLine__c ql22 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011', 
                                                         //SubsAstNameInt__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011', 
                                                         PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 107, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480011',SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Refreshed',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod3.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, SBQQ__RequiredBy__c = ql2.Id);
        
        SBQQ__QuoteLine__c ql3 = new SBQQ__QuoteLine__c(Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010', Special_Program__c = 'Conversion', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'None',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(10),Prior_Net_Total__c = 21000);
        SBQQ__QuoteLine__c ql4 = new SBQQ__QuoteLine__c(Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010', Special_Program__c = 'Conversion', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'None', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SubscribedAssetNames__c = 'BB192863040049', 
                                                        //SubsAstNameInt__c = 'BB192863040049', 
                                                        Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c  = 1);
        SBQQ__QuoteLine__c ql5 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010', 
                                                        //SubsAstNameInt__c = 'AA165203480092, AA165203480109, AA164403480010',
                                                        PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 107, Arroyo_Subscribed_Asset_Name__c = 'AA165203480093', SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'HW SUPPORT', Product_Type__c = 'HW Support', Disposition_Reason__c = 'Converted',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        
        SBQQ__QuoteLine__c ql6 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010', 
                                                        //SubsAstNameInt__c = 'AA165203480092, AA165203480109, AA164403480010', 
                                                        PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 207, Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010', SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Replaced', Replace_By__c = prod2.ProductCode, SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        
        SBQQ__QuoteLine__c ql0 = new SBQQ__QuoteLine__c(Product_Level__c = 'Wrapper', PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 10007, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', SBQQSC__RenewedContractLine__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Churn', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046', 
                                                        //SubsAstNameInt__c = 'BB192863040046', 
                                                        Prior_Net_Total__c = 21000);
        SBQQ__QuoteLine__c ql00 = new SBQQ__QuoteLine__c(SBQQ__RequiredBy__c = ql0.Id, PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 10007, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', SBQQSC__RenewedContractLine__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Churn', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046', 
                                                         //SubsAstNameInt__c = 'BB192863040046', 
                                                         Prior_Net_Total__c = 21000);
        
        lines.add(ql1);
        lines.add(ql11);
        lines.add(ql2);
        lines.add(ql22);
        lines.add(ql3);
        lines.add(ql4);
        lines.add(ql5);
        lines.add(ql6);
        lines.add(ql0);
        lines.add(ql00);
        //lines.add(ql112);
        Test.startTest();
        insert lines;
        
        
        metricCalcForArroyoQueueable_v2 queueableClass = new metricCalcForArroyoQueueable_v2(quoteId);
        System.enqueueJob(queueableClass);
        
        
        ql1.Arroyo_Subscribed_Asset_Name__c = null;
        ql2.Arroyo_Subscribed_Asset_Name__c = null;
        ql22.Arroyo_Subscribed_Asset_Name__c = null;
        ql3.Arroyo_Subscribed_Asset_Name__c = null;
        ql4.Arroyo_Subscribed_Asset_Name__c = null;
        ql5.Arroyo_Subscribed_Asset_Name__c = null;
        ql6.Arroyo_Subscribed_Asset_Name__c = null;
        ql1.Disposition_Reason__c = null;
        
        ql112.Arroyo_Subscribed_Asset_Name__c = null;
        update lines; 
        
        metricCalcForArroyoQueueable_v2 queueableClass1 = new metricCalcForArroyoQueueable_v2(quoteId);
        System.enqueueJob(queueableClass1);
        
        ql1.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql2.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql22.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql3.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql4.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql5.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql6.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql112.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        update lines; 
        
        metricCalcForArroyoQueueable_v2 queueableClass0 = new metricCalcForArroyoQueueable_v2(quoteId);
        System.enqueueJob(queueableClass0);
        
        ql1.SubscribedAssetNames__c = null;
        ql2.SubscribedAssetNames__c = null;
        ql22.SubscribedAssetNames__c = null;
        ql3.SubscribedAssetNames__c = null;
        ql4.SubscribedAssetNames__c = null;
        ql5.SubscribedAssetNames__c = null;
        ql6.SubscribedAssetNames__c = null;
        ql112.SubscribedAssetNames__c = null;
        update lines;
        
        metricCalcForArroyoQueueable_v2 queueableClass2 = new metricCalcForArroyoQueueable_v2(quoteId);
        System.enqueueJob(queueableClass2);
        
        ql1.SubsRenAmt__c = 10;
        ql2.SubsRenAmt__c = 10;
        ql22.SubsRenAmt__c = 10;
        ql3.SubsRenAmt__c = 10;
        ql4.SubsRenAmt__c = 10;
        ql5.SubsRenAmt__c = 10;
        ql6.SubsRenAmt__c = 10;
        
        ql1.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        ql2.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        ql22.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        ql3.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        ql4.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        ql5.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        ql6.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        
        
        ql112.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj1.id;
        update lines;
        
        metricCalcForArroyoQueueable_v2 queueableClass3 = new metricCalcForArroyoQueueable_v2(quoteId);
        System.enqueueJob(queueableClass3);
        
        ql1.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        ql2.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        ql22.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        ql3.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        ql4.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        ql5.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        ql6.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        
        ql112.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        update lines;
        
        metricCalcForArroyoQueueable_v2 queueableClass4 = new metricCalcForArroyoQueueable_v2(quoteId);
        System.enqueueJob(queueableClass4);
        
        ql1.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        ql2.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        ql22.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        ql3.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        ql4.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        ql5.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        ql6.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        
        
        ql112.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        update lines;
        
        metricCalcForArroyoQueueable_v2 queueableClass5 = new metricCalcForArroyoQueueable_v2(quoteId);
        Id qJobId = System.enqueueJob(queueableClass5);
        System.assert(qJobId != null);
        Test.stopTest();
    }
    
    /* TestMethod 5 to cover metric Cal Que */
    public static testMethod void testPQProcessing() {
        TriggerControl__c setting1 = new TriggerControl__c();
        setting1.Name = 'Opportunity';
        setting1.DisableTrigger__c = TRUE;
        insert setting1;
        TriggerControl__c setting2 = new TriggerControl__c();
        setting2.Name = 'Renewal Case';
        setting2.DisableTrigger__c = FALSE;
        insert setting2;
        
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        upsert disableFuncCS;
        
        ShGl_DisableBusinessLogic__c cdf1 = new ShGl_DisableBusinessLogic__c(SetupOwnerId = userInfo.getUserId(),
                                                                             Disable_SBQQ_Quote_Validation_Rules__c = True,
                                                                             Disable_SBQQ_Quote_Triggers__c = True,
                                                                             Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
                                                                             Disable_SBQQ_QuoteLine_Triggers__c = True,
                                                                             Disable_Opportunity_Validation_Rules__c = True,
                                                                             Disable_Opportunity_Triggers__c = True,
                                                                             Disable_ServiceContract_Trigger__c = True,
                                                                             Disable_Contract_Line_Item_Triggers__c = True);
        insert cdf1;
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        
        Account accObj = TestDataFactory.getAccount();
        insert accObj;
        Account accObj1 = TestDataFactory.getAccount();
        accObj1.Name = 'RUBRIK_ACC_NAME';
        insert accObj1;
        Account rbkAcc = new Account(Name='Rubrik');
        insert rbkAcc;
        
        Opportunity oppr = TestDataFactory.getOpportunity(accObj);
        insert oppr;
        
        Id standardPriceBookId =  Test.getStandardPricebookId();
        
        PriceBook2 pb1  = new Pricebook2(Name = 'V68_2017_08_09_12_26_43', Description = 'Price Book 2009 Products 1', IsActive = true);
        insert pb1;
        
        Product2 prod1 = new Product2(
            Name = 'RBK-GO-BE-R6408',
            ProductCode = 'RBK-GO-BE-R6408',
            isActive = true,
            SBQQ__SubscriptionTerm__c = 1
            //Product_Type__c = 'HW Support'
        );
        Product2 prod112 = new Product2(
            Name = 'RBK-GO-BE-R6410',
            ProductCode = 'RBK-GO-BE-R6410',
            isActive = true,
            SBQQ__SubscriptionTerm__c = 1
            //Product_Type__c = 'HW Support'
        );
        Product2 prod2 = new Product2(
            Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
            ProductCode = 'RBK-SVC-PREM-R304',
            isActive = true,
            SBQQ__SubscriptionTerm__c = 1,
            Product_Type__c = 'HW Support'
        );
        Product2 prod3 = new Product2(
            Name = 'RBK-SVC-PREM-APPLIANCE',
            ProductCode = 'RBK-SVC-PREM-APPLIANCE',
            isActive = true,
            SBQQ__SubscriptionTerm__c = 1,
            Product_Type__c = 'HW Support'
        );
        Product2 prod4 = new Product2(
            Name = 'RBK-SUB-HYB-R3410-01',
            ProductCode = 'RBK-SUB-HYB-R3410-01',
            isActive = true,
            SBQQ__SubscriptionTerm__c = 1,
            Product_Type__c = 'HW Support'
        );
        
        insert new List<Product2>{prod1, prod2, prod3, prod4, prod112};
            
            PricebookEntry pbStanEntry1 = new PricebookEntry(
                Pricebook2Id = standardPriceBookId,
                Product2Id = prod1.Id,
                UnitPrice = 100.00,
                IsActive = true
            );
        PricebookEntry pbStanEntry112 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod112.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        PricebookEntry pbStanEntry2 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbStanEntry3 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbStanEntry4 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod4.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbEntry1 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod1.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        PricebookEntry pbEntry112 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod112.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        PricebookEntry pbEntry2 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbEntry3 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbEntry4 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod4.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        insert new List<PricebookEntry>
        {pbStanEntry1, pbStanEntry2, pbStanEntry3, pbStanEntry4, pbEntry1,pbEntry2, pbEntry3, pbEntry4, pbStanEntry112, pbEntry112};
            
            /*    Sales_Comp_Category_Mapping__mdt metaRec = new Sales_Comp_Category_Mapping__mdt
(Label = 'HW SUPPORT', DeveloperName = 'HW_SUPPORT', Mapped_Sales_Comp_Category__c = 'HW SUPPORT', Priority__c = '1');
//insert metaRec; */
            
            Map<String, Object>  quoteMap = new Map<String, Object> 
        {'SBQQ__Account__c' => accObj.Id,'SBQQ__Opportunity2__c' => oppr.Id};
            
            Set<Id> quoteId = new Set<Id>();
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppr.Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__PriceBook__c = pb1.Id;
        qt1.SBQQ__Status__c = 'Draft';
        qt1.SBQQ__Type__c = 'Renewal';
        qt1.SBQQ__StartDate__c = Date.today();
        qt1.Manual_Billing__c = false;
        qt1.Consolidate_Lines__c = false;
        insert qt1;
        
        qt1.MetricsLastCalcOn__c = System.today()+1;
        //qt1.LastModifiedDate = System.today()+2;
        update qt1;
        
        quoteId.add(qt1.Id);
        
        List<ServiceContract> lstServiceContract = new List<ServiceContract>();
        
        ServiceContract serviceContractObj = new ServiceContract();
        serviceContractObj.Name = 'EntitlementTriggerHelper Contract';
        serviceContractObj.SBQQSC__Opportunity__c = oppr.Id;
        serviceContractObj.AccountId = accObj.Id;
        serviceContractObj.StartDate = System.today();
        serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj.Term = 36;
        lstServiceContract.add(serviceContractObj);
        
        ServiceContract renewServiceContractObj = new ServiceContract();
        renewServiceContractObj.Name = 'EntitlementTriggerHelper Contract';
        renewServiceContractObj.SBQQSC__Opportunity__c = oppr.Id;
        renewServiceContractObj.AccountId = accObj.Id;
        renewServiceContractObj.StartDate = System.today();
        renewServiceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        renewServiceContractObj.Term = 36;
        lstServiceContract.add(renewServiceContractObj);
        insert lstServiceContract;
        
        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObj.PricebookEntryId = pbStanEntry1.Id;
        ContractLineItemObj.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.UnitPrice = 100;
        insert ContractLineItemObj;
        ContractLineItem ContractLineItemObj1 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj1.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObj1.PricebookEntryId = pbStanEntry112.Id;
        ContractLineItemObj1.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj1.Quantity = 10;
        ContractLineItemObj1.UnitPrice = 100;
        insert ContractLineItemObj1;
        
        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c(PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 10007, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', SBQQSC__RenewedContractLine__c = ContractLineItemObj.id, CCLI__c = ContractLineItemObj.id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Churn', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046', 
                                                        //SubsAstNameInt__c = 'BB192863040046', 
                                                        Prior_Net_Total__c = 21000);
        SBQQ__QuoteLine__c ql11 = new SBQQ__QuoteLine__c(PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 10007, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', SBQQSC__RenewedContractLine__c = null, CCLI__c = ContractLineItemObj.id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Churn', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046', 
                                                         //SubsAstNameInt__c = 'BB192863040046', 
                                                         Prior_Net_Total__c = 21000);
        SBQQ__QuoteLine__c ql112 = new SBQQ__QuoteLine__c(PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 10007, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', SBQQSC__RenewedContractLine__c = ContractLineItemObj1.id, CCLI__c = ContractLineItemObj.id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Churn', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod112.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046', 
                                                          //SubsAstNameInt__c = 'BB192863040046', 
                                                          Prior_Net_Total__c = 21000);
        
        
        SBQQ__QuoteLine__c ql2 = new SBQQ__QuoteLine__c(SBQQ__RequiredBy__c= ql1.Id,SubscribedAssetNames__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011', 
                                                        //SubsAstNameInt__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011',
                                                        PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 107, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480011',SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Churn',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        SBQQ__QuoteLine__c ql22 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011', 
                                                         //SubsAstNameInt__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011', 
                                                         PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 107, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480011',SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Churn',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod3.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, SBQQ__RequiredBy__c = ql2.Id);
        
        SBQQ__QuoteLine__c ql3 = new SBQQ__QuoteLine__c(Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010', Special_Program__c = 'Conversion', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Churn',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(10),Prior_Net_Total__c = 21000);
        SBQQ__QuoteLine__c ql4 = new SBQQ__QuoteLine__c(Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010', Special_Program__c = 'Conversion', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Churn', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SubscribedAssetNames__c = 'BB192863040049', 
                                                        //SubsAstNameInt__c = 'BB192863040049', 
                                                        Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c  = 1);
        SBQQ__QuoteLine__c ql5 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010', 
                                                        //SubsAstNameInt__c = 'AA165203480092, AA165203480109, AA164403480010',
                                                        PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 107, Arroyo_Subscribed_Asset_Name__c = 'AA165203480093', SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'HW SUPPORT', Product_Type__c = 'HW Support', Disposition_Reason__c = 'Churn',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        
        SBQQ__QuoteLine__c ql6 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010', 
                                                        //SubsAstNameInt__c = 'AA165203480092, AA165203480109, AA164403480010', 
                                                        PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 207, Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010', SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Churn', Replace_By__c = prod2.ProductCode, SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        SBQQ__QuoteLine__c ql7 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010', 
                                                        //SubsAstNameInt__c = 'AA165203480092, AA165203480109, AA164403480010', 
                                                        PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 207, Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010', SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'RUBRIK ENTERPRISE EDITION', Disposition_Reason__c = 'None', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod4.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        
        SBQQ__QuoteLine__c ql0 = new SBQQ__QuoteLine__c(Product_Level__c = 'Wrapper', PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 10007, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', SBQQSC__RenewedContractLine__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Churn', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046', 
                                                        //SubsAstNameInt__c = 'BB192863040046', 
                                                        Prior_Net_Total__c = 21000);
        SBQQ__QuoteLine__c ql00 = new SBQQ__QuoteLine__c(SBQQ__RequiredBy__c = ql0.Id, PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 10007, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', SBQQSC__RenewedContractLine__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Churn', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046', 
                                                         //SubsAstNameInt__c = 'BB192863040046', 
                                                         Prior_Net_Total__c = 21000);
        
        lines.add(ql1);
        lines.add(ql11);
        lines.add(ql2);
        lines.add(ql22);
        lines.add(ql3);
        lines.add(ql4);
        lines.add(ql5);
        lines.add(ql6);
        lines.add(ql0);
        lines.add(ql00);
        //lines.add(ql112);
        //lines.add(ql7);
        Test.startTest();
        insert lines;
        
        
        metricCalcForArroyoQueueable_v2 queueableClass = new metricCalcForArroyoQueueable_v2(quoteId);
        System.enqueueJob(queueableClass);
        
        
        ql1.Arroyo_Subscribed_Asset_Name__c = null;
        ql2.Arroyo_Subscribed_Asset_Name__c = null;
        ql22.Arroyo_Subscribed_Asset_Name__c = null;
        ql3.Arroyo_Subscribed_Asset_Name__c = null;
        ql4.Arroyo_Subscribed_Asset_Name__c = null;
        ql5.Arroyo_Subscribed_Asset_Name__c = null;
        ql6.Arroyo_Subscribed_Asset_Name__c = null;
        ql1.Disposition_Reason__c = null;
        ql7.Arroyo_Subscribed_Asset_Name__c = null;
        
        ql112.Arroyo_Subscribed_Asset_Name__c = null;
        update lines; 
        
        metricCalcForArroyoQueueable_v2 queueableClass1 = new metricCalcForArroyoQueueable_v2(quoteId);
        System.enqueueJob(queueableClass1);
        
        ql1.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql2.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql22.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql3.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql4.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql5.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql6.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql112.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        update lines; 
        
        metricCalcForArroyoQueueable_v2 queueableClass0 = new metricCalcForArroyoQueueable_v2(quoteId);
        System.enqueueJob(queueableClass0);
        
        ql1.SubscribedAssetNames__c = null;
        ql2.SubscribedAssetNames__c = null;
        ql22.SubscribedAssetNames__c = null;
        ql3.SubscribedAssetNames__c = null;
        ql4.SubscribedAssetNames__c = null;
        ql5.SubscribedAssetNames__c = null;
        ql6.SubscribedAssetNames__c = null;
        ql112.SubscribedAssetNames__c = null;
        ql7.SubscribedAssetNames__c = null;
        update lines;
        
        metricCalcForArroyoQueueable_v2 queueableClass2 = new metricCalcForArroyoQueueable_v2(quoteId);
        System.enqueueJob(queueableClass2);
        
        ql1.SubsRenAmt__c = 10;
        ql2.SubsRenAmt__c = 10;
        ql22.SubsRenAmt__c = 10;
        ql3.SubsRenAmt__c = 10;
        ql4.SubsRenAmt__c = 10;
        ql5.SubsRenAmt__c = 10;
        ql6.SubsRenAmt__c = 10;
        ql7.SubsRenAmt__c = 10;
        
        ql1.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        ql2.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        ql22.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        ql3.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        ql4.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        ql5.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        ql6.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        ql7.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        
        
        ql112.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj1.id;
        update lines;
        
        metricCalcForArroyoQueueable_v2 queueableClass3 = new metricCalcForArroyoQueueable_v2(quoteId);
        System.enqueueJob(queueableClass3);
        
        ql1.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        ql2.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        ql22.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        ql3.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        ql4.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        ql5.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        ql6.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        
        ql112.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        ql7.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        update lines;
        
        metricCalcForArroyoQueueable_v2 queueableClass4 = new metricCalcForArroyoQueueable_v2(quoteId);
        System.enqueueJob(queueableClass4);
        
        ql1.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        ql2.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        ql22.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        ql3.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        ql4.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        ql5.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        ql6.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        
        
        ql112.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        ql7.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        update lines;
        
        metricCalcForArroyoQueueable_v2 queueableClass5 = new metricCalcForArroyoQueueable_v2(quoteId);
        Id qJobId = System.enqueueJob(queueableClass5);
        System.assert(qJobId != null);
        Test.stopTest();
    }
    
    /* TestMethod 6 to cover metricCalc Queueable */
    public static testMethod void testMethod3Processing() {
        TriggerControl__c setting1 = new TriggerControl__c();
        setting1.Name = 'Opportunity';
        setting1.DisableTrigger__c = TRUE;
        insert setting1;
        TriggerControl__c setting2 = new TriggerControl__c();
        setting2.Name = 'Renewal Case';
        setting2.DisableTrigger__c = FALSE;
        insert setting2;
        
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        upsert disableFuncCS;
        
        ShGl_DisableBusinessLogic__c cdf1 = new ShGl_DisableBusinessLogic__c(SetupOwnerId = userInfo.getUserId(),
                                                                             Disable_SBQQ_Quote_Validation_Rules__c = True,
                                                                             Disable_SBQQ_Quote_Triggers__c = True,
                                                                             Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
                                                                             Disable_SBQQ_QuoteLine_Triggers__c = True,
                                                                             Disable_Opportunity_Validation_Rules__c = True,
                                                                             Disable_Opportunity_Triggers__c = True,
                                                                             Disable_ServiceContract_Trigger__c = True,
                                                                             Disable_Contract_Line_Item_Triggers__c = True);
        insert cdf1;
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        
        Account accObj = TestDataFactory.getAccount();
        insert accObj;
        Account accObj1 = TestDataFactory.getAccount();
        accObj1.Name = 'RUBRIK_ACC_NAME';
        insert accObj1;
        Account rbkAcc = new Account(Name='Rubrik');
        insert rbkAcc;
        
        Opportunity oppr = TestDataFactory.getOpportunity(accObj);
        insert oppr;
        
        Id standardPriceBookId =  Test.getStandardPricebookId();
        
        PriceBook2 pb1  = new Pricebook2(Name = 'V68_2017_08_09_12_26_43', Description = 'Price Book 2009 Products 1', IsActive = true);
        insert pb1;
        
        Product2 prod1 = new Product2(
            Name = 'RBK-GO-BE-R6408',
            ProductCode = 'RBK-GO-BE-R6408',
            isActive = true,
            SBQQ__SubscriptionTerm__c = 1
            //Product_Type__c = 'HW Support'
        );
        Product2 prod112 = new Product2(
            Name = 'RBK-GO-BE-R6410',
            ProductCode = 'RBK-GO-BE-R6410',
            isActive = true,
            SBQQ__SubscriptionTerm__c = 1
            //Product_Type__c = 'HW Support'
        );
        Product2 prod2 = new Product2(
            Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
            ProductCode = 'RBK-SVC-PREM-R304',
            isActive = true,
            SBQQ__SubscriptionTerm__c = 1,
            Product_Type__c = 'HW Support'
        );
        Product2 prod3 = new Product2(
            Name = 'RBK-SVC-PREM-APPLIANCE',
            ProductCode = 'RBK-SVC-PREM-APPLIANCE',
            isActive = true,
            SBQQ__SubscriptionTerm__c = 1,
            Product_Type__c = 'HW Support'
        );
        Product2 prod4 = new Product2(
            Name = 'RBK-SUB-HYB-R3410-01',
            ProductCode = 'RBK-SUB-HYB-R3410-01',
            isActive = true,
            SBQQ__SubscriptionTerm__c = 1,
            Product_Type__c = 'HW Support'
        );
        
        insert new List<Product2>{prod1, prod2, prod3, prod4, prod112};
            
            PricebookEntry pbStanEntry1 = new PricebookEntry(
                Pricebook2Id = standardPriceBookId,
                Product2Id = prod1.Id,
                UnitPrice = 100.00,
                IsActive = true
            );
        PricebookEntry pbStanEntry112 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod112.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        PricebookEntry pbStanEntry2 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbStanEntry3 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbStanEntry4 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod4.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbEntry1 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod1.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        PricebookEntry pbEntry112 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod112.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        PricebookEntry pbEntry2 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbEntry3 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbEntry4 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod4.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        insert new List<PricebookEntry>
        {pbStanEntry1, pbStanEntry2, pbStanEntry3, pbStanEntry4, pbEntry1,pbEntry2, pbEntry3, pbEntry4, pbStanEntry112, pbEntry112};
            
            
            
            Map<String, Object>  quoteMap = new Map<String, Object> 
        {'SBQQ__Account__c' => accObj.Id,'SBQQ__Opportunity2__c' => oppr.Id};
            
            Set<Id> quoteId = new Set<Id>();
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppr.Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__PriceBook__c = pb1.Id;
        qt1.SBQQ__Status__c = 'Draft';
        qt1.SBQQ__Type__c = 'Renewal';
        qt1.SBQQ__StartDate__c = Date.today();
        qt1.Manual_Billing__c = false;
        qt1.Consolidate_Lines__c = false;
        insert qt1;
        
        qt1.MetricsLastCalcOn__c = System.today()+1;
        //qt1.LastModifiedDate = System.today()+2;
        update qt1;
        
        quoteId.add(qt1.Id);
        
        List<ServiceContract> lstServiceContract = new List<ServiceContract>();
        
        ServiceContract serviceContractObj = new ServiceContract();
        serviceContractObj.Name = 'EntitlementTriggerHelper Contract';
        serviceContractObj.SBQQSC__Opportunity__c = oppr.Id;
        serviceContractObj.AccountId = accObj.Id;
        serviceContractObj.StartDate = System.today();
        serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj.Term = 36;
        lstServiceContract.add(serviceContractObj);
        
        ServiceContract renewServiceContractObj = new ServiceContract();
        renewServiceContractObj.Name = 'EntitlementTriggerHelper Contract';
        renewServiceContractObj.SBQQSC__Opportunity__c = oppr.Id;
        renewServiceContractObj.AccountId = accObj.Id;
        renewServiceContractObj.StartDate = System.today();
        renewServiceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        renewServiceContractObj.Term = 36;
        lstServiceContract.add(renewServiceContractObj);
        insert lstServiceContract;
        
        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObj.PricebookEntryId = pbStanEntry1.Id;
        ContractLineItemObj.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.UnitPrice = 100;
        insert ContractLineItemObj;
        ContractLineItem ContractLineItemObj1 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj1.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObj1.PricebookEntryId = pbStanEntry112.Id;
        ContractLineItemObj1.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj1.Quantity = 10;
        ContractLineItemObj1.UnitPrice = 100;
        insert ContractLineItemObj1;
        
        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c(PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 10007, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', SBQQSC__RenewedContractLine__c = ContractLineItemObj.id, CCLI__c = ContractLineItemObj.id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Churn', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046', 
                                                        //SubsAstNameInt__c = 'BB192863040046', 
                                                        Prior_Net_Total__c = 21000);
        insert ql1;
        SBQQ__QuoteLine__c ql11 = new SBQQ__QuoteLine__c(PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 10007, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', SBQQSC__RenewedContractLine__c = null, CCLI__c = ContractLineItemObj.id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Churn', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046', 
                                                         //SubsAstNameInt__c = 'BB192863040046', 
                                                         Prior_Net_Total__c = 21000);
        SBQQ__QuoteLine__c ql112 = new SBQQ__QuoteLine__c(PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 10007, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', SBQQSC__RenewedContractLine__c = ContractLineItemObj1.id, CCLI__c = ContractLineItemObj.id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Churn', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod112.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046', 
                                                          //SubsAstNameInt__c = 'BB192863040046', 
                                                          Prior_Net_Total__c = 21000);
        
        
        SBQQ__QuoteLine__c ql2 = new SBQQ__QuoteLine__c(SBQQ__RequiredBy__c= ql1.Id,SubscribedAssetNames__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011', 
                                                        //SubsAstNameInt__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011',
                                                        PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 107, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480011',SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Churn',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        SBQQ__QuoteLine__c ql22 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011', 
                                                         //SubsAstNameInt__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011', 
                                                         PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 107, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480011',SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Churn',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod3.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, SBQQ__RequiredBy__c = ql2.Id);
        
        SBQQ__QuoteLine__c ql3 = new SBQQ__QuoteLine__c(Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010', Special_Program__c = 'Conversion', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Churn',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(10),Prior_Net_Total__c = 21000);
        SBQQ__QuoteLine__c ql4 = new SBQQ__QuoteLine__c(SBQQ__RequiredBy__c= ql1.Id, Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010', Special_Program__c = 'Conversion', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Churn', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SubscribedAssetNames__c = 'BB192863040049', 
                                                        //SubsAstNameInt__c = 'BB192863040049', 
                                                        Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c  = 1);
        SBQQ__QuoteLine__c ql5 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010', 
                                                        //SubsAstNameInt__c = 'AA165203480092, AA165203480109, AA164403480010',
                                                        PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 107, Arroyo_Subscribed_Asset_Name__c = 'AA165203480093', SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'HW SUPPORT', Product_Type__c = 'HW Support', Disposition_Reason__c = 'None',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod4.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        
        SBQQ__QuoteLine__c ql6 = new SBQQ__QuoteLine__c(SBQQ__RequiredBy__c= ql1.Id, SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010', 
                                                        SubsAstNameInt__c = 'AA165203480092, AA165203480109, AA164403480010', 
                                                        PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 207, Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010', SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'RUBRIK ENTERPRISE EDITION', Disposition_Reason__c = 'None', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        SBQQ__QuoteLine__c ql7 = new SBQQ__QuoteLine__c(SBQQ__RequiredBy__c= ql1.Id, SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010', 
                                                        SubsAstNameInt__c = 'AA165203480092, AA165203480109, AA164403480010', 
                                                        PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 207, Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010', SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'RUBRIK ENTERPRISE EDITION', Disposition_Reason__c = 'None', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod4.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        
        SBQQ__QuoteLine__c ql0 = new SBQQ__QuoteLine__c(Product_Level__c = 'Wrapper', PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 10007, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', SBQQSC__RenewedContractLine__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Churn', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046', 
                                                        //SubsAstNameInt__c = 'BB192863040046', 
                                                        Prior_Net_Total__c = 21000);
        SBQQ__QuoteLine__c ql00 = new SBQQ__QuoteLine__c(SBQQ__RequiredBy__c = ql0.Id, PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 10007, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', SBQQSC__RenewedContractLine__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Churn', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046', 
                                                         //SubsAstNameInt__c = 'BB192863040046', 
                                                         Prior_Net_Total__c = 21000);
        
        lines.add(ql1);
        lines.add(ql11);
        lines.add(ql2);
        lines.add(ql22);
        lines.add(ql3);
        lines.add(ql4);
        lines.add(ql5);
        lines.add(ql6);
        lines.add(ql0);
        lines.add(ql00);
        //lines.add(ql112);
        lines.add(ql7);
        Test.startTest();
        upsert lines;
        
        
        metricCalcForArroyoQueueable_v2 queueableClass = new metricCalcForArroyoQueueable_v2(quoteId);
        System.enqueueJob(queueableClass);
        
        
        ql1.Arroyo_Subscribed_Asset_Name__c = null;
        ql2.Arroyo_Subscribed_Asset_Name__c = null;
        ql22.Arroyo_Subscribed_Asset_Name__c = null;
        ql3.Arroyo_Subscribed_Asset_Name__c = null;
        ql4.Arroyo_Subscribed_Asset_Name__c = null;
        ql5.Arroyo_Subscribed_Asset_Name__c = null;
        ql6.Arroyo_Subscribed_Asset_Name__c = null;
        ql1.Disposition_Reason__c = null;
        ql7.Arroyo_Subscribed_Asset_Name__c = null;
        
        ql112.Arroyo_Subscribed_Asset_Name__c = null;
        update lines; 
        
        metricCalcForArroyoQueueable_v2 queueableClass1 = new metricCalcForArroyoQueueable_v2(quoteId);
        System.enqueueJob(queueableClass1);
        
        ql1.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql2.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql22.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql3.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql4.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql5.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql6.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        ql112.Arroyo_Subscribed_Asset_Name__c = 'AA165203480092';
        update lines; 
        
        metricCalcForArroyoQueueable_v2 queueableClass0 = new metricCalcForArroyoQueueable_v2(quoteId);
        System.enqueueJob(queueableClass0);
        
        ql1.SubscribedAssetNames__c = null;
        ql2.SubscribedAssetNames__c = null;
        ql22.SubscribedAssetNames__c = null;
        ql3.SubscribedAssetNames__c = null;
        ql4.SubscribedAssetNames__c = null;
        ql5.SubscribedAssetNames__c = null;
        ql6.SubscribedAssetNames__c = null;
        ql112.SubscribedAssetNames__c = null;
        ql7.SubscribedAssetNames__c = null;
        update lines;
        
        metricCalcForArroyoQueueable_v2 queueableClass2 = new metricCalcForArroyoQueueable_v2(quoteId);
        System.enqueueJob(queueableClass2);
        
        ql1.SubsRenAmt__c = 10;
        ql2.SubsRenAmt__c = 10;
        ql22.SubsRenAmt__c = 10;
        ql3.SubsRenAmt__c = 10;
        ql4.SubsRenAmt__c = 10;
        ql5.SubsRenAmt__c = 10;
        ql6.SubsRenAmt__c = 10;
        ql7.SubsRenAmt__c = 10;
        
        ql1.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        ql2.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        ql22.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        ql3.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        ql4.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        ql5.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        ql6.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        ql7.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.id;
        
        
        ql112.Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj1.id;
        update lines;
        
        metricCalcForArroyoQueueable_v2 queueableClass3 = new metricCalcForArroyoQueueable_v2(quoteId);
        System.enqueueJob(queueableClass3);
        
        ql1.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        ql2.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        ql22.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        ql3.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        ql4.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        ql5.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        ql6.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        
        ql112.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        ql7.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
        update lines;
        
        metricCalcForArroyoQueueable_v2 queueableClass4 = new metricCalcForArroyoQueueable_v2(quoteId);
        System.enqueueJob(queueableClass4);
        
        ql1.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        ql2.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        ql22.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        ql3.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        ql4.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        ql5.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        ql6.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        
        
        ql112.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        ql7.Arroyo_Subsumed_Old_Contract_Line_Items__c = '';
        update lines;
        
        metricCalcForArroyoQueueable_v2 queueableClass5 = new metricCalcForArroyoQueueable_v2(quoteId);
        Id qJobId = System.enqueueJob(queueableClass5);
        System.assert(qJobId != null);
        Test.stopTest();
    }
}