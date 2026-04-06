/**Test class for asyncSendNotification */
@IsTest
private class asyncSendNotificationTest{

    @isTest static void testAsyncSendNotification() {

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

      
        List<Product2> listProduct = TestDataFactory.getProducts('Prod', 2);
        listProduct[0].Legacy_Software_Bundle__c = TRUE;
        insert listProduct;
        
        List<Pricebook2> listPricebook = TestDataFactory.getPricebook('PriceBook', 1);
        listPricebook[0].Name = 'CPQ Pricebook';
        insert listPricebook;

        Assert.areEqual(1, listPricebook.size());
       
        
        List<PriceBookEntry> listPricebookentry = TestDataFactory.getPriceBookEntry(
            new List<Id>{listProduct[0].Id, listProduct[1].Id},
            new List<Id>{Test.getStandardPricebookId(), listPricebook[0].Id}
        );
        insert listPricebookentry;
        
        String partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
        Account acc = new Account(Name='MS Account');
        Account partnerAcc = new Account(Name='NetApp Inc (US Disti)', RecordTypeId =partnerRecordTypeId );
        System.debug(' MS 1>> partner acc name '+partnerAcc.Name);
        insert new List<Account>{acc,partnerAcc};
            
            Opportunity objOpportunity = TestDataFactory.getOpportunity(acc);
        insert objOpportunity;
        
        List<SBQQ__Quote__c> listQuote = TestDataFactory.getQuotes(new Set<Id>{objOpportunity.Id}, 1);
        listQuote[0].SBQQ__PriceBook__c = listPricebook[0].Id;
        listQuote[0].SBQQ__PricebookId__c = listPricebook[0].Id;
        insert listQuote;
        
        List<SBQQ__QuoteLine__c> listQuoteLine = TestDataFactory.getQuoteLines (
            new Map<Id, List<Id>>{
                listQuote[0].Id => new List<Id>{listProduct[0].Id, listProduct[1].Id}
            }
        );
        listQuoteLine[0].SBQQ__PricebookEntryId__c = listPricebookentry[1].Id;
        listQuoteLine[0].SBQQ__NetPrice__c = 100;
        listQuoteLine[1].SBQQ__PricebookEntryId__c = listPricebookentry[3].Id;
        listQuoteLine[1].SBQQ__NetPrice__c = 100;
        insert listQuoteLine;
        
        listQuoteLine[1].SBQQ__RequiredBy__c = listQuoteLine[0].Id;
        update listQuoteLine[1];
        
        list<SBQQ__QuoteLine__c> lstQl = [Select Id, SBQQ__PricebookEntryId__c  From SBQQ__QuoteLine__c where Id = :listQuoteLine[0].Id];
        system.debug('&&&' + lstQl + '--->' + listQuoteLine[0].Id);
        
        ServiceContract objServiceContract = new Servicecontract(
            Name = 'Test Contract',
            Pricebook2Id = listPricebook[0].Id,
            AccountId = acc.Id,
            StartDate = Date.Today().addmonths(-36) ,
            EndDate = Date.Today(),
            SBQQSC__RenewalOpportunity__c = objOpportunity.Id
        );
        insert objServiceContract;
        
        ContractLineItem objContractLineItem = new ContractLineItem(
            ServiceContractId = objServiceContract.Id,
            SBQQSC__Product__c = listProduct[1].Id,
            SBQQSC__QuoteLine__c = listQuoteLine[1].Id,
            PricebookEntryId = listPricebookentry[3].Id,
            Quantity = 1,
            UnitPrice = 100,
            StartDate = Date.Today().addmonths(-36) ,
            EndDate = Date.Today()
        );
        insert objContractLineItem;
        list<ContractLineItem> lst = [Select Id, SBQQSC__QuoteLine__r.SBQQ__RequiredBy__c, SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__PricebookEntryId__c From ContractLineItem LIMIT 1];
        system.debug('MS 1>>> cliList ' + lst);
        
        
        Opportunity arOpp = TestDataFactory.getOpportunity(acc);
        //arOpp.Sell_to_Partner__c = partnerAcc.Id;
        insert arOpp;
        //system.debug('MS 1>>> opp Sell to partner ' + arOpp.Sell_to_Partner__c);
        
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), new Map<String, Object> 
                                                                             {'SBQQ__Account__c' => acc.Id,'SBQQ__Opportunity2__c' => arOpp.Id});
        qt1.SBQQ__Opportunity2__c = arOpp.Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__PriceBook__c = listPricebook[0].Id;
        qt1.SBQQ__Status__c = 'Draft';
        qt1.SBQQ__Type__c = 'Renewal';
        qt1.SBQQ__StartDate__c = Date.today();
        qt1.Manual_Billing__c = false;
        qt1.Consolidate_Lines__c = false;
        insert qt1;
        
        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c(PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 10007, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', SBQQSC__RenewedContractLine__c = objContractLineItem.id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = listProduct[0].Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046', Prior_Net_Total__c = 21000);
        SBQQ__QuoteLine__c ql2 = new SBQQ__QuoteLine__c(SBQQ__RequiredBy__c= ql1.Id,SubscribedAssetNames__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011', PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 107, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480011',SBQQSC__RenewedContractLine__c = objContractLineItem.Id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Refreshed',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = listProduct[1].Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        SBQQ__QuoteLine__c ql3 = new SBQQ__QuoteLine__c(Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010', Special_Program__c = 'Conversion', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'None',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = listProduct[0].Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(10),Prior_Net_Total__c = 21000);
        SBQQ__QuoteLine__c ql4 = new SBQQ__QuoteLine__c(Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010', Special_Program__c = 'Conversion', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'None', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = listProduct[1].Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SubscribedAssetNames__c = 'BB192863040049', Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c  = 1);
        SBQQ__QuoteLine__c ql5 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010', PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 107, Arroyo_Subscribed_Asset_Name__c = 'AA165203480093', SBQQSC__RenewedContractLine__c = objContractLineItem.Id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Converted',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = listProduct[1].Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        SBQQ__QuoteLine__c ql6 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010',PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 207, Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010', SBQQSC__RenewedContractLine__c = objContractLineItem.Id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Converted',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = listProduct[1].Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        
        lines.add(ql1);
        lines.add(ql2);
        lines.add(ql3);
        lines.add(ql4);
        lines.add(ql5);
        lines.add(ql6);
        insert lines;
        
        SBQQ__Quote__c testQuote = qt1; //listQuote[0];
        Set<Id> quoteIds = new Set<Id>{testQuote.Id};
            Map<Id,SBQQ__Quote__c> createdQuoteMap = new Map<Id,SBQQ__Quote__c>{testQuote.Id => testQuote};
                Map<Id,SBQQ__Quote__c> approvedQuoteMap = new Map<Id,SBQQ__Quote__c>{testQuote.Id => testQuote};
                    
                    Test.startTest();
        asyncSendNotification job = new asyncSendNotification(createdQuoteMap, approvedQuoteMap, quoteIds);
        System.enqueueJob(job);
        Test.stopTest();
    }
}