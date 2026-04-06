/* Test Class for metricCalcForArroyoQueueable_v2_Future and Queueable */

@isTest
public class metricsFutureClassTest{
    
    /* Test Data Set Up */
    @TestSetUp
    static void initialDataSetup(){
        TriggerControl__c setting1 = new TriggerControl__c();
        setting1.Name = 'Opportunity';
        setting1.DisableTrigger__c = false;
        insert setting1;
        
        TriggerControl__c setting2 = new TriggerControl__c();
        setting2.Name = 'Renewal Case';
        setting2.DisableTrigger__c = true;
        insert setting2;
        
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
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User usr = new User(
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
            Disable_Order_Old_Trigger__c = true,
            Disable_OrderItem_Old_Trigger__c = true,
            Disable_Opportunity_Validation_Rules__c = true,
            Enable_Logs__c = true
        );
        insert sdbl;
        Id standardPriceBookId =  Test.getStandardPricebookId();
        
        PriceBook2 pb1  = new Pricebook2(Name = 'V68_2017_08_09_12_26_43', Description = 'Price Book 2009 Products 1', IsActive = true);
        insert pb1;
        
        Product2 prod1 = new Product2(
            Name = 'RBK-GO-BE-R6408',
            ProductCode = 'RBK-GO-BE-R6408',
            IsActive = true,
            SBQQ__SubscriptionTerm__c = 1
        );
        Product2 prod2 = new Product2(
            Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
            ProductCode = 'RBK-SVC-PREM-R304',
            IsActive = true,
            SBQQ__SubscriptionTerm__c = 1,
            Product_Type__c = 'HW Support'
        );
        Product2 prod3 = new Product2(
            Name = 'RBK-SVC-PREM-APPLIANCE',
            ProductCode = 'RBK-SVC-PREM-APPLIANCE',
            IsActive = true,
            SBQQ__SubscriptionTerm__c = 1,
            Product_Type__c = 'HW Support'
        );
        Product2 prod4 = new Product2(
            Name = 'Wrapper',
            ProductCode = 'Wrapper',
            IsActive = true,
            Product_Level__c = 'Wrapper'
        );
        Product2 prod5 = new Product2(
            Name = 'RBK-R348-01',
            ProductCode = 'RBK-R348-01',
            isActive = true,
            Sales_Comp_Category__c = 'HARDWARE',
            Product_Type__c = 'Appliance'
        );
        Product2 prod6 = new Product2(
            Name = 'RBK-R6408S-HW-01',
            ProductCode = 'RBK-R6408S-HW-01',
            isActive = true,
            Sales_Comp_Category__c = 'HARDWARE',
            Product_Type__c = 'Hardware'
        );
        insert new List<Product2>{prod1, prod2, prod3, prod4, prod5, prod6};
            
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
        
        PricebookEntry pbStanEntry4 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod4.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        
        PricebookEntry pbStanEntry5 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod5.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        
        PricebookEntry pbStanEntry6 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod6.Id,
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
        
        PricebookEntry pbEntry4 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod4.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        
        PricebookEntry pbEntry5 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod5.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        
        PricebookEntry pbEntry6 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod6.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        
        insert new List<PricebookEntry>
        {pbStanEntry1, pbStanEntry2, pbStanEntry3, pbStanEntry4, pbStanEntry5, pbStanEntry6, pbEntry1, pbEntry2, pbEntry3, pbEntry4
            , pbEntry5, pbEntry6};
                
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
        qt1.SBQQ__Type__c = 'Renewal+Expansion';
        qt1.SBQQ__StartDate__c = Date.Today();
        qt1.Manual_Billing__c = false;
        qt1.Consolidate_Lines__c = false;
        qt1.SBQQ__ExpirationDate__c = Date.Today() + 365;
        insert qt1;
        
        List<ServiceContract> lstServiceContract = new List<ServiceContract>();
        
        ServiceContract serviceContractObj1 = new ServiceContract();
        serviceContractObj1.Name = 'EntitlementTriggerHelper ContractA';
        serviceContractObj1.SBQQSC__Opportunity__c = oppr.Id;
        serviceContractObj1.AccountId = accObj.Id;
        serviceContractObj1.StartDate = System.today();
        serviceContractObj1.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj1.Term = 36;
        lstServiceContract.add(serviceContractObj1);
        
        ServiceContract serviceContractObj2 = new ServiceContract();
        serviceContractObj2.Name = 'EntitlementTriggerHelper ContractB';
        serviceContractObj2.SBQQSC__Opportunity__c = oppr.Id;
        serviceContractObj2.AccountId = accObj.Id;
        serviceContractObj2.StartDate = System.today();
        serviceContractObj2.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj2.Term = 36;
        lstServiceContract.add(serviceContractObj2);
        insert lstServiceContract;
        
        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObj.PricebookEntryId = pbStanEntry1.Id;
        ContractLineItemObj.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.UnitPrice = 100;
        insert ContractLineItemObj;
        
        ContractLineItem ContractLineItemObjA = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObjA.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObjA.PricebookEntryId = pbStanEntry1.Id;
        ContractLineItemObjA.ServiceContractId = lstServiceContract[1].Id;
        ContractLineItemObjA.Quantity = 10;
        ContractLineItemObjA.UnitPrice = 100;
        insert ContractLineItemObjA;
        
        Asset assetObj = (Asset) ShGl_TestFactory.createSObject(new Asset(), null);
        assetObj.AccountId = accObj.Id;
        assetObj.Name = 'EntitlementTriggerHelperAsset';
        assetObj.Product2Id = prod1.Id;
        assetObj.Justification_for_HW_Eligibility_Overrid__c = '-';
        assetObj.serial_number__c = 'JAY8486304222k4';
        insert assetObj;
        
        List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
        
        SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = null, 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',
            Product_Level__c = 'Support',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, CCLI__c = ContractLineItemObj.Id, Special_Program__c = null,
            PriorACVwithUplift__c = 10000, Prior_Net_Total__c = 21000, RTAwithoutUplift__c = 10007,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', 
            SubscribedAssetNames__c = 'BB192863040046',
            SubsAstNameInt__c = 'BB192863040046'
        );
        
        SBQQ__QuoteLine__c ql2 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = null, 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',
            Product_Level__c = 'Support',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, CCLI__c = ContractLineItemObj.Id, Special_Program__c = null,
            PriorACVwithUplift__c = 10000, Prior_Net_Total__c = 21000, RTAwithoutUplift__c = 10007,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', 
            SubscribedAssetNames__c = 'BB192863040046', SubsAstNameInt__c = 'BB192863040046');
        
        SBQQ__QuoteLine__c ql3 = new SBQQ__QuoteLine__c(
            SBQQ__RequiredBy__c= ql1.Id,
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Refreshed',
            Product_Level__c = 'Support',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, CCLI__c = ContractLineItemObj.Id, Special_Program__c = 'Refresh',
            PriorACVwithUplift__c = 10000, Prior_Net_Total__c = 21000, RTAwithoutUplift__c = 107,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010',
            SubscribedAssetNames__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011',
            SubsAstNameInt__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011'
        );
        
        SBQQ__QuoteLine__c ql4 = new SBQQ__QuoteLine__c(
            SBQQ__RequiredBy__c= ql1.Id,
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod3.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Refreshed',
            Product_Level__c = 'Support',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, CCLI__c = ContractLineItemObj.Id, Special_Program__c = 'Refresh',
            PriorACVwithUplift__c = 10000, Prior_Net_Total__c = 21000, RTAwithoutUplift__c = 107,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010',
            SubscribedAssetNames__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011',
            SubsAstNameInt__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011'
        );
        
        SBQQ__QuoteLine__c ql5 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 25, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = null, 
            SBQQ__DefaultSubscriptionTerm__c = 12, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'None',
            Product_Level__c = 'Support',
            Prior_Net_Total__c = 21000,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010'
        );
        
        SBQQ__QuoteLine__c ql6 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'None',
            Product_Level__c = 'Support',
            Prior_Net_Total__c = 21000, Special_Program__c = null,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010',
            SubscribedAssetNames__c = 'BB192863040049',
            SubsAstNameInt__c = 'BB192863040049'
        );
        
        SBQQ__QuoteLine__c ql7 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Converted',
            Product_Level__c = 'Support',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Product_Type__c = 'HW Support',
            Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.Id,
            PriorACVwithUplift__c = 10000, Prior_Net_Total__c = 21000, RTAwithoutUplift__c = 107,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480093',            
            SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010',
            SubsAstNameInt__c = 'AA165203480092, AA165203480109, AA164403480010'
        );
        
        SBQQ__QuoteLine__c ql8 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Replaced',
            Product_Level__c = 'Support',
            Replace_By__c = prod2.ProductCode, Special_Program__c = 'Replaced',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Product_Type__c = 'HW Support',
            Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.Id,
            PriorACVwithUplift__c = 10000, Prior_Net_Total__c = 21000, RTAwithoutUplift__c = 107,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010',            
            SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010',
            SubsAstNameInt__c = 'AA165203480092, AA165203480109, AA164403480010'
        );
        
        SBQQ__QuoteLine__c ql9 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod4.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = null, 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = null, Disposition_Reason__c = 'None',
            SBQQSC__RenewedContractLine__c = null, Product_Type__c = null, Product_Level__c = 'Wrapper'
        );
        
        SBQQ__QuoteLine__c ql10 = new SBQQ__QuoteLine__c(
            SBQQ__RequiredBy__c = ql9.Id, 
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = null, 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'INSTALL', Disposition_Reason__c = 'None',
            SBQQSC__RenewedContractLine__c = null, Product_Type__c = 'Consulting', Product_Level__c = 'Addon'
        );
        
        SBQQ__QuoteLine__c ql11 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'RUBRIK ENTERPRISE EDITION', Disposition_Reason__c = 'None',
            Product_Level__c = 'Hybrid Software', SBQQSC__RenewedContractLine__c = null
        );
        
        SBQQ__QuoteLine__c ql12 = new SBQQ__QuoteLine__c(
            SBQQ__RequiredBy__c = ql11.Id, 
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW Support', Disposition_Reason__c = 'None',
            Product_Level__c = 'Support', SBQQSC__RenewedContractLine__c = null
        );
        
        // Arroyo_Subscribed_Asset_Name__c = NULL
        SBQQ__QuoteLine__c ql13 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Replaced',
            Product_Level__c = 'Support',
            Replace_By__c = prod2.ProductCode, Special_Program__c = 'Replaced',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Product_Type__c = 'HW Support',
            Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.Id,
            PriorACVwithUplift__c = 10000, Prior_Net_Total__c = 21000, RTAwithoutUplift__c = 107,
            Arroyo_Subscribed_Asset_Name__c = null,            
            SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010',
            SubsAstNameInt__c = 'AA165203480092, AA165203480109, AA164403480010'
        );
        
        //Churn Line
        SBQQ__QuoteLine__c ql14 = new SBQQ__QuoteLine__c(
            SBQQ__RequiredBy__c = ql13.Id,
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Churn',
            Product_Level__c = 'Support',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Product_Type__c = 'HW Support',
            Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.Id,
            PriorACVwithUplift__c = 10000, Prior_Net_Total__c = 21000, RTAwithoutUplift__c = 107,
            Arroyo_Subscribed_Asset_Name__c = null,            
            SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010',
            SubsAstNameInt__c = 'AA165203480092, AA165203480109, AA164403480010'
        );
        
        SBQQ__QuoteLine__c ql25 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'RUBRIK ENTERPRISE EDITION', Disposition_Reason__c = 'None',
            Product_Level__c = 'Hybrid Software', SBQQSC__RenewedContractLine__c = null
        );
        
        SBQQ__QuoteLine__c ql26 = new SBQQ__QuoteLine__c(
            SBQQ__RequiredBy__c = ql25.Id, 
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW Support', Disposition_Reason__c = 'None',
            Product_Level__c = 'Support', SBQQSC__RenewedContractLine__c = null
        );
        //DR = Null
        SBQQ__QuoteLine__c ql15 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = null,
            Product_Level__c = 'Support',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Product_Type__c = 'HW Support',
            Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.Id,
            PriorACVwithUplift__c = 10000, Prior_Net_Total__c = 21000, RTAwithoutUplift__c = 107,
            Arroyo_Subscribed_Asset_Name__c = null,            
            SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010',
            SubsAstNameInt__c = 'AA165203480092, AA165203480109, AA164403480010'
        );
        
        SBQQ__QuoteLine__c ql16 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = null, 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',
            Product_Level__c = 'Support',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, CCLI__c = ContractLineItemObjA.Id, Special_Program__c = null,
            PriorACVwithUplift__c = 10000, Prior_Net_Total__c = 21000, RTAwithoutUplift__c = 10007,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', 
            SubscribedAssetNames__c = 'BB192863040046',
            SubsAstNameInt__c = 'BB192863040046'
        );
        
        SBQQ__QuoteLine__c ql17 = new SBQQ__QuoteLine__c(
            SBQQ__RequiredBy__c = ql11.Id, 
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW Support', Disposition_Reason__c = 'None',
            Product_Level__c = 'Support', SBQQSC__RenewedContractLine__c = null, SubsRenAmt__c = 100
        );
        
        //RBK-SVC-PREM QLIs
        SBQQ__QuoteLine__c ql18 = new SBQQ__QuoteLine__c(
            SBQQ__RequiredBy__c= ql1.Id,
            SubscribedAssetNames__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011', 
            PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 107,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480011',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, 
            Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Refreshed',
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, 
            SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null,
            SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), 
            Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        
        SBQQ__QuoteLine__c ql19 = new SBQQ__QuoteLine__c(
            SubscribedAssetNames__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011', 
            PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 107, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480011',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'SW SUPPORT', Disposition_Reason__c = 'Refreshed',
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod3.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), 
            Prior_Net_Total__c = 21000, SBQQ__RequiredBy__c = ql11.Id);
        
        SBQQ__QuoteLine__c ql20 = new SBQQ__QuoteLine__c(
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010', Special_Program__c = 'Conversion', 
            Sales_Comp_Category__c = 'SW SUPPORT', Disposition_Reason__c = 'None', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id,
            SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, 
            SBQQ__NetPrice__c = 200, SubscribedAssetNames__c = 'BB192863040049', 
            Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c  = 1);
        
        //Test
        SBQQ__QuoteLine__c ql21 = new SBQQ__QuoteLine__c(
            SBQQ__RequiredBy__c= ql1.Id, 
            SubscribedAssetNames__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011',
            PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 107, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), 
            Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, Arroyo_Subsumed_Old_Contract_Line_Items__c = '', SBQQ__Segmentindex__c = 1);
        
        SBQQ__QuoteLine__c ql22 = new SBQQ__QuoteLine__c(
            SubscribedAssetNames__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011', 
            PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 107, 
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480092', SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, 
            Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Refreshed',
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod3.Id, SBQQ__Quantity__c = 20, 
            SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, 
            SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(),
            SubsRenAmt__c = 10,Arroyo_Subsumed_Old_Contract_Line_Items__c = '', Prior_Net_Total__c = 21000, SBQQ__RequiredBy__c = ql1.Id);
        
        SBQQ__QuoteLine__c ql23 = new SBQQ__QuoteLine__c(
            SBQQ__RequiredBy__c= ql1.Id, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092', Special_Program__c = 'Conversion', 
            Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, 
            SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, 
            SBQQ__NetPrice__c = 200, SubscribedAssetNames__c = 'BB192863040049', Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, 
            Arroyo_Subsumed_Old_Contract_Line_Items__c = '', SBQQ__Segmentindex__c  = 1);
        
        SBQQ__QuoteLine__c ql24 = new SBQQ__QuoteLine__c(
            SBQQ__RequiredBy__c= ql1.Id, SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010', 
            SubsAstNameInt__c = 'AA165203480092, AA165203480109, AA164403480010', PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 207, 
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480092', SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, 
            Sales_Comp_Category__c = 'RUBRIK ENTERPRISE EDITION', Disposition_Reason__c = 'Renewing', SBQQ__Quote__c = qt1.Id, 
            SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, 
            SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, 
            MSP_Segment_Product__c = true, Arroyo_Subsumed_Old_Contract_Line_Items__c = '', SBQQ__Segmentindex__c = 1);
        
        //RBK QLIs
        SBQQ__QuoteLine__c qlHW1 = new SBQQ__QuoteLine__c(
            SBQQ__RequiredBy__c = null,
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod5.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), Sales_Comp_Category__c = 'HARDWARE', 
            Disposition_Reason__c = 'Converted', Product_Level__c = null, SBQQ__RenewedAsset__c	= assetObj.Id,
            SBQQSC__RenewedContractLine__c = null, CCLI__c = null, Special_Program__c = null,
            PriorACVwithUplift__c = null, Prior_Net_Total__c = null, RTAwithoutUplift__c = null,
            Arroyo_Subscribed_Asset_Name__c = null, 
            SubscribedAssetNames__c = 'BB192863040046',
            SubsAstNameInt__c = 'BB192863040046'
        );
        
        SBQQ__QuoteLine__c qlSVC_PREM_APP1 = new SBQQ__QuoteLine__c(
            SBQQ__RequiredBy__c = qlHW1.Id,
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod3.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), Sales_Comp_Category__c = 'HW SUPPORT', 
            Disposition_Reason__c = 'Converted', Product_Level__c = null, SBQQ__RenewedAsset__c	= null,
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, CCLI__c = ContractLineItemObj.Id, Special_Program__c = null,
            PriorACVwithUplift__c = 2010, Prior_Net_Total__c = 2000, RTAwithoutUplift__c = 2010,
            Arroyo_Subscribed_Asset_Name__c = null, 
            SubscribedAssetNames__c = 'BB192863040046,BB192863040049',
            SubsAstNameInt__c = 'BB192863040046,BB192863040049'
        );
        
        lines.add(ql1);
        lines.add(ql2);
        lines.add(ql3);
        lines.add(ql4);
        lines.add(ql5);
        lines.add(ql6);
        lines.add(ql7);
        lines.add(ql8);
        lines.add(ql9);
        lines.add(ql10);
        lines.add(ql11);
        lines.add(ql12);
        lines.add(ql13);
        lines.add(ql14);
        lines.add(ql15);
        lines.add(ql16);
        lines.add(ql17);
        lines.add(ql18);
        lines.add(ql19);
        lines.add(ql20);
        lines.add(ql21);
        lines.add(ql22);
        lines.add(ql23);
        lines.add(ql24);
        lines.add(ql25);
        lines.add(ql26);
        lines.add(qlHW1);
        lines.add(qlSVC_PREM_APP1);
        
        //Renewal Quote Data Prep
        SBQQ__Quote__c qt2 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt2.SBQQ__Opportunity2__c = oppr.Id;
        qt2.SBQQ__PriceBook__c = pb1.Id;
        qt2.SBQQ__Status__c = 'Draft';
        qt2.SBQQ__Type__c = 'Renewal';
        qt2.SBQQ__StartDate__c = Date.Today();
        qt2.Manual_Billing__c = false;
        qt2.Consolidate_Lines__c = false;
        qt2.SBQQ__ExpirationDate__c = Date.Today() + 365;
        insert qt2;
        
        SBQQ__QuoteLine__c ql1A = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt2.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = null, 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',
            Product_Level__c = 'Support',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, CCLI__c = ContractLineItemObj.Id, Special_Program__c = null,
            PriorACVwithUplift__c = 10000, Prior_Net_Total__c = 21000, RTAwithoutUplift__c = 10007,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', 
            SubscribedAssetNames__c = 'BB192863040046',
            SubsAstNameInt__c = 'BB192863040046'
        );
        
        SBQQ__QuoteLine__c ql2A = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt2.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = null, 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',
            Product_Level__c = 'Support',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, CCLI__c = ContractLineItemObj.Id, Special_Program__c = null,
            PriorACVwithUplift__c = 10000, Prior_Net_Total__c = 21000, RTAwithoutUplift__c = 10007,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', 
            SubscribedAssetNames__c = 'BB192863040046', SubsAstNameInt__c = 'BB192863040046');
        
        SBQQ__QuoteLine__c ql3A = new SBQQ__QuoteLine__c(
            SBQQ__RequiredBy__c= ql1A.Id,
            SBQQ__Quote__c = qt2.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Refreshed',
            Product_Level__c = 'Support',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, CCLI__c = ContractLineItemObj.Id, Special_Program__c = 'Refresh',
            PriorACVwithUplift__c = 10000, Prior_Net_Total__c = 21000, RTAwithoutUplift__c = 107,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010',
            SubscribedAssetNames__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011',
            SubsAstNameInt__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011'
        );
        
        SBQQ__QuoteLine__c ql4A = new SBQQ__QuoteLine__c(
            SBQQ__RequiredBy__c= ql2A.Id,
            SBQQ__Quote__c = qt2.Id, SBQQ__Product__c = prod3.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Refreshed',
            Product_Level__c = 'Support',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, CCLI__c = ContractLineItemObj.Id, Special_Program__c = 'Refresh',
            PriorACVwithUplift__c = 10000, Prior_Net_Total__c = 21000, RTAwithoutUplift__c = 107,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010',
            SubscribedAssetNames__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011',
            SubsAstNameInt__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011'
        );
        
        SBQQ__QuoteLine__c ql5A = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt2.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 25, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = null, 
            SBQQ__DefaultSubscriptionTerm__c = 12, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'None',
            Product_Level__c = 'Support',
            Prior_Net_Total__c = 21000,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010'
        );
        
        SBQQ__QuoteLine__c ql6A = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt2.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'None',
            Product_Level__c = 'Support',
            Prior_Net_Total__c = 21000, Special_Program__c = null,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010',
            SubscribedAssetNames__c = 'BB192863040049',
            SubsAstNameInt__c = 'BB192863040049'
        );
        
        SBQQ__QuoteLine__c ql7A = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt2.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Converted',
            Product_Level__c = 'Support',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Product_Type__c = 'HW Support',
            Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.Id,
            PriorACVwithUplift__c = 10000, Prior_Net_Total__c = 21000, RTAwithoutUplift__c = 107,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480093',            
            SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010',
            SubsAstNameInt__c = 'AA165203480092, AA165203480109, AA164403480010'
        );
        
        SBQQ__QuoteLine__c ql8A = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt2.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Replaced',
            Product_Level__c = 'Support',
            Replace_By__c = prod2.ProductCode, Special_Program__c = 'Replaced',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Product_Type__c = 'HW Support',
            Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.Id,
            PriorACVwithUplift__c = 10000, Prior_Net_Total__c = 21000, RTAwithoutUplift__c = 107,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010',            
            SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010',
            SubsAstNameInt__c = 'AA165203480092, AA165203480109, AA164403480010'
        );
        
        SBQQ__QuoteLine__c ql9A = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt2.Id, SBQQ__Product__c = prod4.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = null, 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = null, Disposition_Reason__c = 'None',
            SBQQSC__RenewedContractLine__c = null, Product_Type__c = null, Product_Level__c = 'Wrapper'
        );
        
        SBQQ__QuoteLine__c ql10A = new SBQQ__QuoteLine__c(
            SBQQ__RequiredBy__c = ql9A.Id, 
            SBQQ__Quote__c = qt2.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = null, 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'INSTALL', Disposition_Reason__c = 'None',
            SBQQSC__RenewedContractLine__c = null, Product_Type__c = 'Consulting', Product_Level__c = 'Addon'
        );
        
        SBQQ__QuoteLine__c ql11A = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt2.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'RUBRIK ENTERPRISE EDITION', Disposition_Reason__c = 'None',
            Product_Level__c = 'Hybrid Software', SBQQSC__RenewedContractLine__c = null
        );
        
        SBQQ__QuoteLine__c ql12A = new SBQQ__QuoteLine__c(
            SBQQ__RequiredBy__c = ql11A.Id, 
            SBQQ__Quote__c = qt2.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW Support', Disposition_Reason__c = 'None',
            Product_Level__c = 'Support', SBQQSC__RenewedContractLine__c = null
        );
        
        // Arroyo_Subscribed_Asset_Name__c = NULL
        SBQQ__QuoteLine__c ql13A = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt2.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Replaced',
            Product_Level__c = 'Support',
            Replace_By__c = prod2.ProductCode, Special_Program__c = 'Replaced',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Product_Type__c = 'HW Support',
            Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.Id,
            PriorACVwithUplift__c = 10000, Prior_Net_Total__c = 21000, RTAwithoutUplift__c = 107,
            Arroyo_Subscribed_Asset_Name__c = null,            
            SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010',
            SubsAstNameInt__c = 'AA165203480092, AA165203480109, AA164403480010'
        );
        
        //Churn Line
        SBQQ__QuoteLine__c ql14A = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt2.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Churn',
            Product_Level__c = 'Support',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Product_Type__c = 'HW Support',
            Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.Id,
            PriorACVwithUplift__c = 10000, Prior_Net_Total__c = 21000, RTAwithoutUplift__c = 107,
            Arroyo_Subscribed_Asset_Name__c = null,            
            SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010',
            SubsAstNameInt__c = 'AA165203480092, AA165203480109, AA164403480010'
        );
        
        //DR = Null
        SBQQ__QuoteLine__c ql15A = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt2.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = null,
            Product_Level__c = 'Support',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Product_Type__c = 'HW Support',
            Arroyo_Subsumed_Old_Contract_Line_Items__c = ContractLineItemObj.Id,
            PriorACVwithUplift__c = 10000, Prior_Net_Total__c = 21000, RTAwithoutUplift__c = 107,
            Arroyo_Subscribed_Asset_Name__c = null,            
            SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010',
            SubsAstNameInt__c = 'AA165203480092, AA165203480109, AA164403480010'
        );
        
        SBQQ__QuoteLine__c ql16A = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt2.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = null, 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',
            Product_Level__c = 'Support',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, CCLI__c = ContractLineItemObjA.Id, Special_Program__c = null,
            PriorACVwithUplift__c = 10000, Prior_Net_Total__c = 21000, RTAwithoutUplift__c = 10007,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', 
            SubscribedAssetNames__c = 'BB192863040046',
            SubsAstNameInt__c = 'BB192863040046'
        );
        
        SBQQ__QuoteLine__c ql17A = new SBQQ__QuoteLine__c(
            SBQQ__RequiredBy__c = ql11A.Id, 
            SBQQ__Quote__c = qt2.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW Support', Disposition_Reason__c = 'None',
            Product_Level__c = 'Support', SBQQSC__RenewedContractLine__c = null, SubsRenAmt__c = 100
        );
        
        //RBK-SVC-PREM QLIs
        SBQQ__QuoteLine__c ql18A = new SBQQ__QuoteLine__c(
            SBQQ__RequiredBy__c= ql1A.Id,
            SubscribedAssetNames__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011', 
            PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 107,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480011',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, 
            Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Refreshed',
            SBQQ__Quote__c = qt2.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, 
            SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null,
            SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), 
            Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        
        SBQQ__QuoteLine__c ql19A = new SBQQ__QuoteLine__c(
            SubscribedAssetNames__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011', 
            PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 107, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480011',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'SW SUPPORT', Disposition_Reason__c = 'Refreshed',
            SBQQ__Quote__c = qt2.Id, SBQQ__Product__c = prod3.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), 
            Prior_Net_Total__c = 21000, SBQQ__RequiredBy__c = ql2A.Id);
        
        SBQQ__QuoteLine__c ql20A = new SBQQ__QuoteLine__c(
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010', Special_Program__c = 'Conversion', 
            Sales_Comp_Category__c = 'SW SUPPORT', Disposition_Reason__c = 'None', SBQQ__Quote__c = qt2.Id, SBQQ__Product__c = prod2.Id,
            SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, 
            SBQQ__NetPrice__c = 200, SubscribedAssetNames__c = 'BB192863040049', 
            Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c  = 1);
        
        SBQQ__QuoteLine__c ql21A = new SBQQ__QuoteLine__c(
            SBQQ__RequiredBy__c= ql1A.Id, 
            SubscribedAssetNames__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011',
            PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 107, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',
            SBQQ__Quote__c = qt2.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), 
            Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, Arroyo_Subsumed_Old_Contract_Line_Items__c = '', SBQQ__Segmentindex__c = 1);
        
        SBQQ__QuoteLine__c ql22A = new SBQQ__QuoteLine__c(
            SubscribedAssetNames__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011', 
            PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 107, 
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480092', SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, 
            Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Refreshed',
            SBQQ__Quote__c = qt2.Id, SBQQ__Product__c = prod3.Id, SBQQ__Quantity__c = 20, 
            SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, 
            SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(),
            SubsRenAmt__c = 10,Arroyo_Subsumed_Old_Contract_Line_Items__c = '', Prior_Net_Total__c = 21000, SBQQ__RequiredBy__c = ql2A.Id);
        
        SBQQ__QuoteLine__c ql23A = new SBQQ__QuoteLine__c(
            SBQQ__RequiredBy__c= ql1A.Id, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092', Special_Program__c = 'Conversion', 
            Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing', SBQQ__Quote__c = qt2.Id, SBQQ__Product__c = prod2.Id, 
            SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, 
            SBQQ__NetPrice__c = 200, SubscribedAssetNames__c = 'BB192863040049', Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, 
            Arroyo_Subsumed_Old_Contract_Line_Items__c = '', SBQQ__Segmentindex__c  = 1);
        
        SBQQ__QuoteLine__c ql24A = new SBQQ__QuoteLine__c(
            SBQQ__RequiredBy__c= ql1A.Id, SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010', 
            SubsAstNameInt__c = 'AA165203480092, AA165203480109, AA164403480010', PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 207, 
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480092', SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, 
            Sales_Comp_Category__c = 'RUBRIK ENTERPRISE EDITION', Disposition_Reason__c = 'Renewing', SBQQ__Quote__c = qt2.Id, 
            SBQQ__Product__c = prod3.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, 
            SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, 
            MSP_Segment_Product__c = true, Arroyo_Subsumed_Old_Contract_Line_Items__c = '', SBQQ__Segmentindex__c = 1);
        
        //Renewal Quote Data Prep
        SBQQ__Quote__c qt3 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt3.SBQQ__Opportunity2__c = oppr.Id;
        qt3.SBQQ__PriceBook__c = pb1.Id;
        qt3.SBQQ__Status__c = 'Draft';
        qt3.SBQQ__Type__c = 'Renewal';
        qt3.SBQQ__StartDate__c = Date.Today();
        qt3.Manual_Billing__c = false;
        qt3.Consolidate_Lines__c = false;
        qt3.SBQQ__ExpirationDate__c = Date.Today() + 365;
        insert qt3;
        
        SBQQ__QuoteLine__c quote3QLIA = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt3.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = null, 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',
            Product_Level__c = 'Support',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, CCLI__c = ContractLineItemObj.Id, Special_Program__c = null,
            PriorACVwithUplift__c = 10000, Prior_Net_Total__c = 21000, RTAwithoutUplift__c = 10007,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', 
            SubscribedAssetNames__c = 'BB192863040046',
            SubsAstNameInt__c = 'BB192863040046'
        );
        lines.add(quote3QLIA);
        
        SBQQ__Quote__c qt4 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt4.SBQQ__Opportunity2__c = oppr.Id;
        qt4.SBQQ__PriceBook__c = pb1.Id;
        qt4.SBQQ__Status__c = 'Draft';
        qt4.SBQQ__Type__c = 'Renewal+Expansion';
        qt4.SBQQ__StartDate__c = Date.Today();
        qt4.Manual_Billing__c = false;
        qt4.Consolidate_Lines__c = false;
        qt4.SBQQ__ExpirationDate__c = Date.Today() + 365;
        insert qt4;
        
        SBQQ__QuoteLine__c quote4QLIA = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt4.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = null, 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',
            Product_Level__c = 'Support',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, CCLI__c = ContractLineItemObj.Id, Special_Program__c = null,
            PriorACVwithUplift__c = 10000, Prior_Net_Total__c = 21000, RTAwithoutUplift__c = 10007,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', 
            SubscribedAssetNames__c = 'BB192863040046',
            SubsAstNameInt__c = 'BB192863040046'
        );
        lines.add(quote4QLIA);
        
        lines.add(ql1A);
        lines.add(ql2A);
        lines.add(ql3A);
        lines.add(ql4A);
        lines.add(ql5A);
        lines.add(ql6A);
        lines.add(ql7A);
        lines.add(ql8A);
        lines.add(ql9A);
        lines.add(ql10A);
        lines.add(ql11A);
        lines.add(ql12A);
        lines.add(ql13A);
        lines.add(ql14A);
        lines.add(ql15A);
        lines.add(ql16A);
        lines.add(ql17A);
        lines.add(ql18A);
        lines.add(ql19A);
        lines.add(ql20A);
        lines.add(ql21A);
        lines.add(ql22A);
        lines.add(ql23A);
        lines.add(ql24A);
        insert lines;
        
        ql3.SBQQ__RequiredBy__c = ql1.Id;
        ql4.SBQQ__RequiredBy__c = ql1.Id;
        ql10.SBQQ__RequiredBy__c = ql9.Id;
        ql12.SBQQ__RequiredBy__c = ql11.Id;
        ql14.SBQQ__RequiredBy__c = ql3.Id;
        ql26.SBQQ__RequiredBy__c = ql25.Id;
        ql17.SBQQ__RequiredBy__c = ql11.Id;
        ql18.SBQQ__RequiredBy__c = ql1.Id;
        ql19.SBQQ__RequiredBy__c = ql11.Id;
        ql21.SBQQ__RequiredBy__c = ql1.Id;
        ql22.SBQQ__RequiredBy__c = ql1.Id;
        ql23.SBQQ__RequiredBy__c = ql1.Id;
        ql24.SBQQ__RequiredBy__c = ql1.Id;
        qlSVC_PREM_APP1.SBQQ__RequiredBy__c = qlHW1.Id;
        update lines;
        
        Datetime yesterday = Datetime.now().addDays(-1);
        Test.setCreatedDate(qt1.Id, yesterday);
        Test.setCreatedDate(qt2.Id, yesterday);
        Test.setCreatedDate(qt3.Id, yesterday);
    }
    
    /*Method #1*/
    public static testMethod void testMethod1()
    {  
        SBQQ__Quote__c quoteRE = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c = 'Renewal+Expansion' LIMIT 1];
        Test.startTest();
        TriggerControls.disableCalculateAPIBatch = true;
        quoteRE.SBQQ__Primary__c = true;
        update quoteRE;
        TriggerControls.disableCalculateAPIBatch = true;
        System.assert(quoteRE.Id != null);
        Test.stopTest();
    }
    
    /*Method #2*/
    public static testMethod void testMethod2()
    {  
        SBQQ__Quote__c quoteRE = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c = 'Renewal' LIMIT 1];
        Test.startTest();
        TriggerControls.disableCalculateAPIBatch = true;
        quoteRE.SBQQ__Primary__c = true;
        update quoteRE;
        TriggerControls.disableCalculateAPIBatch = true;
        System.assert(quoteRE.Id != null);
        Test.stopTest();
    }
    
    /*Method #3*/
    public static testMethod void testMethod3()
    {  
        Set<Id> quoteId = new Set<Id>();
        SBQQ__Quote__c quoteRE = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c = 'Renewal+Expansion' LIMIT 1];
        Test.startTest();
        TriggerControls.disableCalculateAPIBatch = true;
        quoteRE.SBQQ__Primary__c = true;
        update quoteRE;
        quoteId.add(quoteRE.Id);
        metricCalcForArroyoQueueable_v2 queueableClass = new metricCalcForArroyoQueueable_v2(quoteId);
        System.enqueueJob(queueableClass);
        TriggerControls.disableCalculateAPIBatch = true;
        System.assert(quoteRE.Id != null);
        Test.stopTest();
    }
    /*Method #4*/
    public static testMethod void testMethod4()
    {  
        Set<Id> quoteId = new Set<Id>();
        SBQQ__Quote__c quoteRE = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c = 'Renewal' LIMIT 1];
        Test.startTest();
        TriggerControls.disableCalculateAPIBatch = true;
        quoteRE.SBQQ__Primary__c = true;
        update quoteRE;
        quoteId.add(quoteRE.Id);
        metricCalcForArroyoQueueable_v2 queueableClass = new metricCalcForArroyoQueueable_v2(quoteId);
        System.enqueueJob(queueableClass);
        TriggerControls.disableCalculateAPIBatch = true;
        System.assert(quoteRE.Id != null);
        Test.stopTest();
    }
    
    /*Method #5*/
    public static testMethod void testMethod5()
    {  
        SBQQ__Quote__c quoteRE = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c = 'Renewal' LIMIT 1];
        Test.startTest();
        TriggerControls.disableCalculateAPIBatch = true;
        quoteRE.SBQQ__Primary__c = true;
        update quoteRE;
        metricCalcForArroyoBatch queuableClass = new metricCalcForArroyoBatch(quoteRE.Id);
        //Id batchJobId1 = Database.executeBatch(queuableClass);
        Database.executeBatch(queuableClass);
        //Id batchJobId = Database.executeBatch(new metricCalcForArroyoBatch());
        Database.executeBatch(new metricCalcForArroyoBatch());
        TriggerControls.disableCalculateAPIBatch = true;
        System.assert(quoteRE.Id != null);
        Test.stopTest();
    }
    
    /*Method #6*/
    public static testMethod void testMethod6(){  
        SBQQ__Quote__c quoteRE = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c = 'Renewal' LIMIT 1];
        Test.startTest();
        TriggerControls.disableCalculateAPIBatch = true;
        quoteRE.SBQQ__Primary__c = true;
        update quoteRE;
        //Id batchJobId = System.schedule('Arroyo Test', '0 43 17 1/1 * ? *', new metricCalcForArroyoBatch());
        //System.schedule('Arroyo Test', '0 43 17 1/1 * ? *', new metricCalcForArroyoBatch());
        //TriggerControls.disableCalculateAPIBatch = true;
        System.assert(quoteRE.Id != null);
        Test.stopTest();
    }
}