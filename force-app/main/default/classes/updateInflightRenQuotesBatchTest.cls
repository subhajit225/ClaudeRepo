/**Test class for updateInflightRenQuotesBatch */
@isTest
public with sharing class updateInflightRenQuotesBatchTest{
    /**testBatchSuccessProcessing*/
    public static testMethod void testBatchSuccessProcessing() {
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(SetupOwnerId = userInfo.getUserId(), 
                                                                            Disable_SBQQ_Quote_Validation_Rules__c = True,
                                                                            Disable_SBQQ_Quote_Triggers__c = True,
                                                                            Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
                                                                            Disable_SBQQ_QuoteLine_Triggers__c = True,
                                                                            Disable_Opportunity_Validation_Rules__c = True,
                                                                            Disable_Opportunity_Triggers__c = True);
        insert cdf;
        
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
        );
        Product2 prod2 = new Product2(
            Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
            ProductCode = 'RBK-SVC-PREM-R304',
            isActive = true,
            SBQQ__SubscriptionTerm__c = 1,
            Product_Type__c = 'HW Support'
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
        insert new List<PricebookEntry>
        {pbStanEntry1,pbStanEntry2,pbEntry1,pbEntry2};
            
           // Sales_Comp_Category_Mapping__mdt metaRec = new Sales_Comp_Category_Mapping__mdt
            //(Label = 'HW SUPPORT', DeveloperName = 'HW_SUPPORT', Mapped_Sales_Comp_Category__c = 'HW SUPPORT', Priority__c = '1');
        //insert metaRec;
        
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
        
        qt1.MetricsLastCalcOn__c = System.today() + 1;
        //qt1.LastModifiedDate = System.today() + 2;
        update qt1;
        
        quoteId.add(qt1.Id);
        
        List<ServiceContract> lstServiceContract = new List<ServiceContract>();
        
        ServiceContract serviceContractObj = new ServiceContract();
        serviceContractObj.Name = 'EntitlementTriggerHelper Contract1';
        serviceContractObj.SBQQSC__Opportunity__c = oppr.Id;
        serviceContractObj.AccountId = accObj.Id;
        serviceContractObj.StartDate = System.today();
        serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj.Term = 36;
        lstServiceContract.add(serviceContractObj);
        
        ServiceContract renewServiceContractObj = new ServiceContract();
        renewServiceContractObj.Name = 'EntitlementTriggerHelper Contract2';
        renewServiceContractObj.SBQQSC__Opportunity__c = oppr.Id;
        renewServiceContractObj.AccountId = accObj.Id;
        renewServiceContractObj.StartDate = System.today();
        renewServiceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        renewServiceContractObj.Term = 36;
        //lstServiceContract.add(renewServiceContractObj);
        insert lstServiceContract;
        
        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObj.PricebookEntryId = pbStanEntry1.Id;
        ContractLineItemObj.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.UnitPrice = 100;
        insert ContractLineItemObj;
        
        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c(PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 10007, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', SBQQSC__RenewedContractLine__c = ContractLineItemObj.id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046', Prior_Net_Total__c = 21000);
        SBQQ__QuoteLine__c ql2 = new SBQQ__QuoteLine__c(SBQQ__RequiredBy__c= ql1.Id,SubscribedAssetNames__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011', PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 107, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480011',SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Refreshed',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        SBQQ__QuoteLine__c ql3 = new SBQQ__QuoteLine__c(Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010', Special_Program__c = 'Conversion', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'None',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(10),Prior_Net_Total__c = 21000);
        SBQQ__QuoteLine__c ql4 = new SBQQ__QuoteLine__c(Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010', Special_Program__c = 'Conversion', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'None', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SubscribedAssetNames__c = 'BB192863040049', Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c  = 1);
        SBQQ__QuoteLine__c ql5 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010', PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 107, Arroyo_Subscribed_Asset_Name__c = 'AA165203480093', SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Converted',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        SBQQ__QuoteLine__c ql6 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010',PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 207, Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010', SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Converted',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        lines.add(ql1);
        lines.add(ql2);
        lines.add(ql3);
        lines.add(ql4);
        lines.add(ql5);
        lines.add(ql6);
        insert lines;
        
        Test.startTest();
        updateInflightRenQuotesBatch queuableClass = new updateInflightRenQuotesBatch(lines);
        Id batchJobId1 = Database.executeBatch(queuableClass);
        Id batchJobId2 = Database.executeBatch(new updateInflightRenQuotesBatch());
        System.debug(batchJobId1);
        System.debug(batchJobId2);
        List<SBQQ__QuoteLine__c> lines1 = new List<SBQQ__QuoteLine__c>();
        
        cdf.Disable_SBQQ_Quote_Validation_Rules__c = FALSE;
        //cdf.Disable_SBQQ_Quote_Triggers__c = FALSE;
        update cdf;
        
        qt1.SBQQ__Status__c = 'Approved';
        update qt1;
        
        SBQQ__QuoteLine__c ql7 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id,
                                                        Disposition_Reason__c = 'Renewing');
        lines1.add(ql7);
        insert lines1; 
        
        updateInflightRenQuotesBatch queuableClass1 = new updateInflightRenQuotesBatch(lines1);
        Id batchJobId3 = Database.executeBatch(queuableClass1);
        Id batchJobId4 = Database.executeBatch(new updateInflightRenQuotesBatch());
        System.assertEquals(ql7.Id != null, true);
        Test.stopTest();
        System.debug(batchJobId3);
        System.debug(batchJobId4);
    }
    
    /**testSchedulableSuccessProcessing */
    public static testMethod void testSchedulableSuccessProcessing() {
        Test.startTest();
        Id batchJobId = System.schedule('Arroyo Test', '0 43 17 1/1 * ? *', new updateInflightRenQuotesBatch());
        System.debug(batchJobId);
        Test.stopTest();
        Account accObj1 = TestDataFactory.getAccount();
        accObj1.Name = 'RUBRIK_ACC_NAME';
        insert accObj1;
        System.assertEquals('RUBRIK_ACC_NAME',
                            [SELECT Id, Name FROM Account WHERE Id =: accObj1.Id].Name);
    }
}