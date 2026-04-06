/** Test classes for despositonLines2*/
@isTest
public class despositonLines2Test {
    @TestSetUp  
        static void initialDataSetup() { 
        TriggerControl__c setting1 = new TriggerControl__c();
        setting1.Name = 'Opportunity';
        setting1.DisableTrigger__c = TRUE;
        insert setting1;
        
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        upsert disableFuncCS;
        
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Validation_Rules__c = True,
                                                                            Disable_SBQQ_Quote_Triggers__c = True,
                                                                            Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
                                                                            Disable_SBQQ_QuoteLine_Triggers__c = True,
                                                                            Disable_Opportunity_Validation_Rules__c = True,
                                                                            Disable_Opportunity_Triggers__c = True,
                                                                            Disable_Campaign_Member_Triggers__c = true,
                                                                           Disable_Campaign_Trigger__c = true,
                                                                           Disable_Campaign_Validation_Rules__c = true);
        insert cdf;
        
        Account accObj = TestDataFactory.getAccount();
        insert accObj;
        
        Opportunity oppr = TestDataFactory.getOpportunity(accObj);
        insert oppr;
        Opportunity renOppr = TestDataFactory.getOpportunity(accObj);
        insert renOppr;
        
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
        Product2 prod3 = new Product2(
            Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
            ProductCode = 'RBK-SVC-PREM-APPLIANCE',
            isActive = true
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
        insert new List<PricebookEntry>{pbStanEntry1, pbStanEntry2, pbStanEntry3, pbEntry1, pbEntry2, pbEntry3};
                
                Map<String, Object>  quoteMap = new Map<String, Object> {'SBQQ__Account__c' => accObj.Id,'SBQQ__Opportunity2__c' => oppr.Id};
                
        //create Service Contract
        ServiceContract serviceContractObj = new ServiceContract(Name = 'sample SC', SBQQSC__Opportunity__c = oppr.Id,AccountId = accObj.Id,StartDate = System.today(),
                                                                PriceBook2Id = pb1.Id,Term = 36, EndDate = System.today() + 365,SBQQSC__RenewalOpportunity__c = renOppr.id);
        insert serviceContractObj;
        
        //Contract Line Items
        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObj.PricebookEntryId = pbEntry2.Id;
        ContractLineItemObj.ServiceContractId = serviceContractObj.Id;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.UnitPrice = 100;
        ContractLineItemObj.SBQQSC__SubscriptionPricing__c='Fixed Price';
        //ContractLineItemObj.SBQQSC__QuoteLine__c=quoteLine.Id;
        ContractLineItemObj.SBQQSC__Product__c = prod2.Id;
        ContractLineItemObj.Licensing_Model__c = 'Subscription';
        ContractLineItemObj.StartDate = System.today();
        ContractLineItemObj.EndDate = System.today().addMonths(36);
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        insert ContractLineItemObj;
        SBQQ.TriggerControl.enable();
                
        List<SBQQ__Quote__c> listArroyoQuotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppr.Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__PriceBook__c = pb1.Id;
        qt1.ApprovalStatus__c = 'Approved';
        qt1.SBQQ__Type__c = 'Renewal+Expansion';
        qt1.SBQQ__StartDate__c = Date.today();
        qt1.Manual_Billing__c = false;
        qt1.Consolidate_Lines__c = false;
        insert qt1;
        listArroyoQuotes.add(qt1);
        
        List<SBQQ__QuoteLineGroup__c> lstGroups = new List<SBQQ__QuoteLineGroup__c>();
        SBQQ__QuoteLineGroup__c  disposeGrp = new SBQQ__QuoteLineGroup__c  (Name = 'Disposition Quote', SBQQ__Quote__c = qt1.Id);
        SBQQ__QuoteLineGroup__c  renewGrp = new SBQQ__QuoteLineGroup__c  (Name = 'Renewal Quote', SBQQ__Quote__c = qt1.Id);
        SBQQ__QuoteLineGroup__c  expGrp = new SBQQ__QuoteLineGroup__c  (Name = 'Expansion Quote', SBQQ__Quote__c = qt1.Id);
        lstGroups.add(disposeGrp);
        lstGroups.add(renewGrp);
        lstGroups.add(expGrp);
        insert lstGroups;
        
        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, Prior_Net_Total__c = 10, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, 
                                                        SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = 1, SBQQ__ListPrice__c = 200,
                                                        SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), 
                                                        SubscribedAssetNames__c = 'BB192863040046',Disposition_Reason__c = 'Renewing', SBQQ__Group__c = renewGrp.Id );
        SBQQ__QuoteLine__c ql2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, Prior_Net_Total__c = 0, SBQQ__Product__c = prod2.Id, MSP_Segment_Product__c = true, 
                                                        SBQQ__Quantity__c = 20, SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', 
                                                        SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
                                                        SBQQ__StartDate__c =  Date.today(), SubscribedAssetNames__c = 'BB192863040047',
                                                        Disposition_Reason__c = 'Renewing', SBQQ__Group__c = renewGrp.Id);
        SBQQ__QuoteLine__c ql3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null,
                                                        SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
                                                        SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), 
                                                        SubscribedAssetNames__c = 'BB192863040048',Disposition_Reason__c = 'None', SBQQ__Group__c = renewGrp.Id);
        SBQQ__QuoteLine__c ql4 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, 
                                                        SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null,
                                                        SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SubscribedAssetNames__c = 'BB192863040049',
                                                        Disposition_Reason__c = 'None', SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, 
                                                        SBQQ__Group__c = renewGrp.Id, Product_Type__c = 'HW Support');
        SBQQ__QuoteLine__c ql5 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod3.Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, 
                                                        SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null,
                                                        SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SubscribedAssetNames__c = 'BB192863040060',
                                                        Disposition_Reason__c = 'Renew Later', SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, 
                                                        SBQQ__Group__c = renewGrp.Id);
        lines.add(ql1);
        lines.add(ql2);
        lines.add(ql3);
        lines.add(ql4);
        lines.add(ql5);
        insert lines;
        
        List<SBQQ__QuoteLine__c> updateLines = new List<SBQQ__QuoteLine__c>();
        ql3.SBQQ__RequiredBy__c = ql1.Id;
        ql4.SBQQ__RequiredBy__c = ql1.Id;
        ql5.SBQQ__RequiredBy__c = ql1.Id;
        updateLines.add(ql3);
        updateLines.add(ql4);
        updateLines.add(ql5);
        update updateLines;
        
        Datetime yesterday = Datetime.now().addDays(-1);
        Test.setCreatedDate(qt1.Id, yesterday);
        
        List<SAAS_To_SAAS__c> lstMapping = new List<SAAS_To_SAAS__c>();
        SAAS_To_SAAS__c saasRec1 = new SAAS_To_SAAS__c(From__c = prod2.Id, To__c = prod3.Id);
        SAAS_To_SAAS__c saasRec2 = new SAAS_To_SAAS__c(From__c = prod2.Id, To__c = prod1.Id);
        SAAS_To_SAAS__c saasRec3 = new SAAS_To_SAAS__c(From__c = prod3.Id, To__c = prod2.Id);
        SAAS_To_SAAS__c saasRec4 = new SAAS_To_SAAS__c(From__c = prod1.Id, To__c = prod3.Id);
        SAAS_To_SAAS__c saasRec5 = new SAAS_To_SAAS__c(From__c = prod3.Id, To__c = prod1.Id);
        lstMapping.add(saasRec1);
        lstMapping.add(saasRec2);
        lstMapping.add(saasRec3);
        lstMapping.add(saasRec4);
        lstMapping.add(saasRec5);
        insert lstMapping;
            
    }
    
    /**testgetQuoteLines_updateLineNumber */
    public static testMethod void testgetQuoteLines_updateLineNumber() {
        SBQQ__Quote__c quoteRec = [Select Id from SBQQ__Quote__c LIMIT 1];
        List<SBQQ__Quote__c> quoteRecList = new List<SBQQ__Quote__c>();
        quoteRecList.add(quoteRec);
        Assert.areEqual(1, quoteRecList.size());
        
        String quoteId = quoteRec.Id;
        despositonLines2.getQuoteLines(quoteId);  
        despositonLines2.updateLineNumberOnQuoteLines(quoteId);
    }
    
    /**testDesposeLines */
    public static testMethod void testDesposeLines() {
        SBQQ__Quote__c quoteRec = [Select Id from SBQQ__Quote__c LIMIT 1];
        String quoteId = quoteRec.Id;
        List<SBQQ__Quote__c> quoteRecList = new List<SBQQ__Quote__c>();
        quoteRecList.add(quoteRec);
        Assert.areEqual(1, quoteRecList.size());
        //List<SBQQ__QuoteLine__c> updateLst = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> oldQuoteLines = [Select Id, SBQQ__ProductCode__c, SBQQ__Quantity__c, SBQQ__RequiredBy__c, Special_Program__c,
                                           Required_By_Product_Code__c, Subscribed_Asset_Name__c, SBQQ__ListPrice__c, Product_Type__c, Product_Level__c,
                                           SBQQ__NetPrice__c, Do_not_Renew__c, Disposition_Reason__c, Quote_Line_Type__c, SubscribedAssetNames__c,
                                           SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQSC__RenewedContractLine__r.ServiceContractId, 
                                           SBQQSC__RenewedContractLine__r.ServiceContract.ContractNumber, Line_Type__c, 
                                           QuoteLine_Group_Name__c, SBQQ__Group__c, SBQQ__SubscriptionPricing__c,Is_Hardware_Product__c , SBQQ__Group__r.Name
                                           FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quoteId];
        
        System.debug('oldQuoteLines-'+oldQuoteLines);
        despositonLines2.desposeLines(oldQuoteLines, oldQuoteLines, quoteId);     
    }
    
    /** testgetPicklistValues*/
    public static testMethod void testgetPicklistValues() {
        SBQQ__Quote__c quoteRec = [Select Id from SBQQ__Quote__c LIMIT 1];
        String quoteId = quoteRec.Id;
        List<SBQQ__Quote__c> quoteRecList = new List<SBQQ__Quote__c>();
        quoteRecList.add(quoteRec);
        Assert.areEqual(1, quoteRecList.size());
        Test.startTest();
        despositonLines2.getPicklistValues('SBQQ__QuoteLine__c', 'Disposition_Reason__c');
        despositonLines2.getQuoteFieldValuesFromApex(quoteId);
        CPQ_Constants consts = new CPQ_Constants();
        System.debug(consts);
        Test.stopTest();
    }
    
    

}