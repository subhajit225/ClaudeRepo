@isTest
public class ProcessTradeUpCalcController_Test {

    testMethod static void testMethod_1() {
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Validation_Rules__c = True,
        Disable_SBQQ_Quote_Triggers__c = True,
        Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
        Disable_SBQQ_QuoteLine_Triggers__c = True,
        Disable_Opportunity_Validation_Rules__c = True,
        Disable_Opportunity_Triggers__c = True,
        Disable_Entitlement_Validation_Rules__c=true);
        insert cdf;
         system.assert(cdf.Id != null);
        TriggerControl__c TC = new TriggerControl__c();
        TC.Name = 'Entitlement';
        TC.DisableTrigger__c = true;
        TC.DisableTrigger__c = true;
        TC.Last_Batch_Run_Date__c = Date.newInstance(2021,04,30);
        TC.SendEmail__c = false;
        insert TC;
        User usr1 = Replacement_TestDataFactory.getUser();
        insert usr1;
        System.runAs(usr1) {
            Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            insert act;
            system.assert(act.Id != null);
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
            Assert.areEqual(2, accountList.size());
            
            Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
            opp.AccountId = act.Id;
            opp.CloseDate = Date.newInstance(2021,04,30);
            opp.Partner_Lookup__c = vAccount2.id;
            opp.Distributor_Lookup__c = vAccount.id;
            insert opp;
            
            Map<String, Object> prdMap1 = new Map<String, Object> {
                'Name' => 'Subscription', 
                    'IsActive' => true, 
                    'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                    'SBQQ__SubscriptionTerm__c' => 12, 
                    'SBQQ__SubscriptionType__c' => 'Renewable'
                    };
            Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
            insert prdSubs;
                
            Product2 prdHW = new Product2(Name='Pord-GO-B',ProductCode='Product-GO-123XYZ',isActive=true,Eligible_For_Trade_Up__c=true, Product_Type__c = 'Hardware', Product_Level__c = 'Hardware', Eligible_HW_for_Expansion__c = 'R6416S,R6416SE', Usable_Capacity__c = 12,Appliance_Model_HW__c='R6416S',Trade_Up_HW_Value__c=10 );
            prdHW.IsActive = true;
            insert prdHW;
            
            Product2 prdLic = new Product2(Name='Pord-GO-B',ProductCode='Product-GO-123XZ',isActive=true, Product_Level__c = 'Hybrid Software', Category__c = 'Bundle', Trade_Up_Multiplier__c = 1.00,Eligible_For_Trade_Up__c=true,Tradeup_Pattern__c = 'License');
            prdLic.IsActive = true;
            insert prdLic;

            List<PricebookEntry> pBList = new List<PricebookEntry> ();

            PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeHW.Product2Id = prdHW.Id;
            PricebookEntry pbeLic = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeLic.Product2Id = prdLic.Id;
            PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeSubs.Product2Id = prdSubs.Id;
            pBList.add(pbeSubs);
            pBList.add(pbeHW);
            pBList.add(pbeLic);

            insert pBList;
            
            Assert.areEqual(3, pBList.size());   
            Asset asst = new Asset(
            Name= 'Test1234567Asset', SerialNumber= 'Test1234567Asset',Serial_Number__c= 'Test1234567Asset',Product2ID=prdHW.Id,
            Accountid =act.Id, Rubrik_Suite__c = 'Business', Free_HW_Refresh_Forfeited__c = false, Eligible_for_Free_HW__c = 'True'
            );
            Asset asst2 = new Asset(
            Name= 'XYX', SerialNumber= 'XYX',Serial_Number__c= 'XYX',Product2ID=prdHW.Id,
            Accountid =act.Id, Rubrik_Suite__c = 'Business', Free_HW_Refresh_Forfeited__c = false, Eligible_for_Free_HW__c = 'True'
            );
            insert new List<Asset>{asst,asst2};
            


            List<ServiceContract> contractList = new List<ServiceContract>();
            ServiceContract serviceContractObj = new ServiceContract();
            serviceContractObj.Name = 'PolarisContractRenewalQuotesUpdateTests';
            serviceContractObj.SBQQSC__Opportunity__c = opp.Id;
            //serviceContractObj.SBQQSC__Quote__c = quoteRec1.Id;
            //serviceContractObj.SBQQSC__RenewalOpportunity__c = lstOpportunity[1].Id;
            //serviceContractObj.AccountId = customer.Id;
            serviceContractObj.StartDate = System.today();
            serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
            serviceContractObj.Term = 36;
            //serviceContractObj.SBQQSC__RenewalOpportunity__c = opp.Id;
            serviceContractObj.EndDate = System.today().addDays(365);
            serviceContractObj.SBQQSC__RenewalForecast__c = false;
            serviceContractObj.SBQQSC__RenewalTerm__c = 12;
            
            
            contractList.add(serviceContractObj);
            insert contractList;
            Assert.areEqual(1, contractList.size());        
            List<contractLineItem> cliList = new List<contractLineItem>(); 
            ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObj.SBQQSC__Account__c = vAccount2.Id;
            ContractLineItemObj.PricebookEntryId = pbeHW.Id;
            ContractLineItemObj.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObj.Quantity = 10;
            ContractLineItemObj.UnitPrice = 100;
            ContractLineItemObj.StartDate = System.today();
            ContractLineItemObj.EndDate = System.today().addDays(120);
            //insert ContractLineItemObj;
            cliList.add(ContractLineItemObj);
            
                ContractLineItem ContractLineItemObj1 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObj1.SBQQSC__Account__c = vAccount2.Id;
            ContractLineItemObj1.PricebookEntryId = pbeHW.Id;
            ContractLineItemObj1.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObj1.Quantity = 10;
            ContractLineItemObj1.UnitPrice = 100;
            ContractLineItemObj1.StartDate = System.today();
            ContractLineItemObj1.EndDate = System.today().addDays(120);
            //insert ContractLineItemObj;
            cliList.add(ContractLineItemObj1);
            
            insert cliList;
            Assert.areEqual(2, cliList.size());
            
            Entitlement ent = new Entitlement(Name='Testing', 
                                                AccountId=act.Id,
                                                AssetId = asst.Id,
                                                ServiceContractId = serviceContractObj.id,
                                                ContractLineItemId = ContractLineItemObj.id,
                                                Product__c =prdHW.id,
                                                StartDate = Date.today(),
                                                EndDate = Date.today().addDays(365));
            insert ent;
            
                Entitlement ent1 = new Entitlement(Name='Testing', 
                                                AccountId=act.Id,
                                                AssetId = asst2.Id,
                                                ServiceContractId = serviceContractObj.id,
                                                ContractLineItemId = ContractLineItemObj1.id,
                                                Product__c =prdHW.id,
                                                StartDate = Date.today(),
                                                EndDate = Date.today().addDays(365));
            insert ent1;

            List<SBQQ__Quote__c>lstQuote = new List<SBQQ__Quote__c>();
            SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
            qt.SBQQ__Account__c = act.Id;
            qt.SBQQ__Opportunity2__c = opp.Id;
            qt.SBQQ__SubscriptionTerm__c = 12;
            qt.SBQQ__Primary__c = true;
            qt.SBQQ__Type__c = 'Quote';
            qt.RecordTypeId=Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Draft Quote').getRecordTypeId();
            qt.Amended_Renewed_Service_Contract__c = serviceContractObj.Id;
            lstQuote.add(qt);
            
            
            insert qt;
            system.assert(qt.Id != null);

            Test.starttest();
            SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id,Category__c = 'Bundle',Expected_Trade_Up_Discount__c=10,Trade_Up_Discount__c = 10, SBQQ__Product__c = prdLic.Id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046', Product_Level__c = 'Hardware' , Product_Type__c = 'Hardware',Trade_Up_Multiplier__c =1,SBQQ__SubscriptionTerm__c=12,Trade_Up_Serial_Number__c='XYX' );  
            insert qli2;
            SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id,Category__c = 'Bundle',SBQQ__RequiredBy__c=qli2.Id,Expected_Trade_Up_Discount__c=10,Trade_Up_Discount__c = 10, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046', Product_Level__c = 'Hardware' , Product_Type__c = 'Hardware',Trade_Up_Multiplier__c =1,SBQQ__SubscriptionTerm__c=12 );  
            insert qli1;
            
            SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id,Category__c = 'Bundle',Expected_Trade_Up_Discount__c=10,Trade_Up_Discount__c = 10, SBQQ__Product__c = prdLic.Id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046', Product_Level__c = 'Hardware' , Product_Type__c = 'Hardware',Trade_Up_Multiplier__c =1,SBQQ__SubscriptionTerm__c=12,Trade_Up_Serial_Number__c='XYX', Trade_Up_Serial_Number_on_HW__c = 'XYX' );  
            insert qli3;

            list<SBQQ__QuoteLine__c> qlList = new list<SBQQ__QuoteLine__c>();
            qlList.add(qli2);
            qlList.add(qli1);
            qlList.add(qli3);
            
            Assert.areEqual(3, qlList.size());

            Map<Id,Decimal> maptredeup = new Map<Id,Decimal>();
            QuoteTriggerHandler.isRecursiveLinkOppEnt = false;
            system.debug(System.logginglevel.DEBUG,'check after this'+ QuoteTriggerHandler.isRecursiveLinkOppEnt);
            qt.SBQQ__Primary__c = true;
            update qt;
            system.debug(System.logginglevel.DEBUG,'check after this here 1');
            String jsonVal ='' ; 
            Map<Id,List<Id>> mapOfReqByVsEnt = new Map<Id,List<Id>>();
            mapOfReqByVsEnt.put(qli1.Id,new List<Id>{ent.Id});
            Map<Id,Integer> mapOfReqByVsCount = new  Map<Id,Integer>();
            mapOfReqByVsCount.put(qli1.Id,1);
            
                maptredeup.put(qli1.Id,qli1.Expected_Trade_Up_Discount__c);
                maptredeup.put(qli2.Id,qli2.Expected_Trade_Up_Discount__c);
                List < ProcessTradeUpCalcController.QuotelineData > QuotelineDataList = new List < ProcessTradeUpCalcController.QuotelineData > ();
                QuotelineDataList.add(new ProcessTradeUpCalcController.QuotelineData(qli1, qli1.Expected_Trade_Up_Discount__c));
                QuotelineDataList.add(new ProcessTradeUpCalcController.QuotelineData(qli2, qli2.Expected_Trade_Up_Discount__c));
                jsonVal = String.valueOf(QuotelineDataList);
            String mujson =  JSON.serialize(QuotelineDataList);
            System.debug(System.logginglevel.DEBUG,'jsonVal'+jsonVal);
                    system.debug(System.logginglevel.DEBUG,'QLS >> '+ [Select Id,SBQQ__Quote__c,Category__c,Line_Type__c,SBQQ__Product__r.Eligible_For_Trade_Up__c from SBQQ__QuoteLine__c]);
                    ProcessTradeUpCalcController.fetchRecords(qt.id,qli1.Id,'BB','[]');
                    ProcessTradeUpCalcController.fetchQuoteLineRecords(qt.id);
                    ProcessTradeUpCalcController.getNumberOfBundles(qt.id);
                    ProcessTradeUpCalcController.validateAssets(qt.id,mapOfReqByVsEnt,mapOfReqByVsCount);
                    ProcessTradeUpCalcController.callCalcConfirmationFromMap(qt.id,mapOfReqByVsEnt);
                    ProcessTradeUpCalcController.callFinalUpdate(mujson,mapOfReqByVsEnt,qt.id);
                    ProcessTradeUpCalcController.clearRecords (qt.id,qli1.Id);

                    ProcessTradeUpCalcController.RecordsData rd = new ProcessTradeUpCalcController.RecordsData('Test', 'Test');
                    mapOfReqByVsEnt.put(qli2.Id,new List<Id>{ent1.Id});
                    ProcessTradeUpCalcController.callCalcConfirmationFromMap(qt.id,mapOfReqByVsEnt);
                    ProcessTradeUpCalcController.fetchRecords(qt.id,qli2.Id,'XYX','[]');
            Test.stoptest();
        }
    }

    testMethod static void testMethod2() {
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Validation_Rules__c = True,
        Disable_SBQQ_Quote_Triggers__c = True,
        Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
        Disable_SBQQ_QuoteLine_Triggers__c = True,
        Disable_Opportunity_Validation_Rules__c = True,
        Disable_Opportunity_Triggers__c = True,
        Disable_Entitlement_Validation_Rules__c=true);
        insert cdf;
        system.assert(cdf.Id != null);
        TriggerControl__c TC = new TriggerControl__c();
        TC.Name = 'Entitlement';
        TC.DisableTrigger__c = true;
        TC.DisableTrigger__c = true;
        TC.Last_Batch_Run_Date__c = Date.newInstance(2021,04,30);
        TC.SendEmail__c = false;
        insert TC;
        User usr1 = Replacement_TestDataFactory.getUser();
        insert usr1;
        System.runAs(usr1) {

        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        system.assert(act.Id != null);
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
        Assert.areEqual(2, accountList.size());

        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opp.AccountId = act.Id;
        opp.CloseDate = Date.newInstance(2021,04,30);
        opp.Partner_Lookup__c = vAccount2.id;
        opp.Distributor_Lookup__c = vAccount.id;
        insert opp;

        Map<String, Object> prdMap1 = new Map<String, Object> {
            'Name' => 'Subscription', 
                'IsActive' => true, 
                'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                'SBQQ__SubscriptionTerm__c' => 12, 
                'SBQQ__SubscriptionType__c' => 'Renewable'
                };
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        insert prdSubs;
            
        Product2 prdHW = new Product2(Name='Pord-GO-B',ProductCode='Product-GO-123XYZ',isActive=true,Eligible_For_Trade_Up__c=true, Product_Type__c = 'Hardware', Product_Level__c = 'Hardware', Eligible_HW_for_Expansion__c = 'R6416S,R6416SE',
                                        Usable_Capacity__c = 12,Appliance_Model_HW__c='R6416S',Trade_Up_HW_Value__c=10,Tradeup_Pattern__c = 'Addon' );
        prdHW.IsActive = true;
        insert prdHW;

        Product2 prdLic = new Product2(Name='Pord-GO-B',ProductCode='Product-GO-123XZ',isActive=true, Product_Level__c = 'Hybrid Software', Category__c = 'Bundle', 
                                    Trade_Up_HW_Value__c=30,     Trade_Up_Multiplier__c = 1.00,Eligible_For_Trade_Up__c=true,Tradeup_Pattern__c = 'Addon');
        prdLic.IsActive = true;
        insert prdLic;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();

        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        PricebookEntry pbeLic = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeLic.Product2Id = prdLic.Id;
        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pBList.add(pbeSubs);
        pBList.add(pbeHW);
        pBList.add(pbeLic);

        insert pBList;

        Assert.areEqual(3, pBList.size());   
        Asset asst = new Asset(
        Name= 'Test1234567Asset', SerialNumber= 'Test1234567Asset',Serial_Number__c= 'Test1234567Asset',Product2ID=prdHW.Id,
        Accountid =act.Id, Rubrik_Suite__c = 'Foundation', Free_HW_Refresh_Forfeited__c = false, Eligible_for_Free_HW__c = 'True'
        );
        Asset asst2 = new Asset(
        Name= 'XYX', SerialNumber= 'XYX',Serial_Number__c= 'XYX',Product2ID=prdHW.Id,
        Accountid =act.Id, Rubrik_Suite__c = 'Foundation', Free_HW_Refresh_Forfeited__c = false, Eligible_for_Free_HW__c = 'True'
        );
        insert new List<Asset>{asst,asst2};



        List<ServiceContract> contractList = new List<ServiceContract>();
        ServiceContract serviceContractObj = new ServiceContract();
        serviceContractObj.Name = 'PolarisContractRenewalQuotesUpdateTests';
        serviceContractObj.SBQQSC__Opportunity__c = opp.Id;
        //serviceContractObj.SBQQSC__Quote__c = quoteRec1.Id;
        //serviceContractObj.SBQQSC__RenewalOpportunity__c = lstOpportunity[1].Id;
        //serviceContractObj.AccountId = customer.Id;
        serviceContractObj.StartDate = System.today();
        serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj.Term = 36;
        //serviceContractObj.SBQQSC__RenewalOpportunity__c = opp.Id;
        serviceContractObj.EndDate = System.today().addDays(365);
        serviceContractObj.SBQQSC__RenewalForecast__c = false;
        serviceContractObj.SBQQSC__RenewalTerm__c = 12;


        contractList.add(serviceContractObj);
        insert contractList;
        Assert.areEqual(1, contractList.size());        
        List<contractLineItem> cliList = new List<contractLineItem>(); 
        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj.SBQQSC__Account__c = vAccount2.Id;
        ContractLineItemObj.PricebookEntryId = pbeHW.Id;
        ContractLineItemObj.ServiceContractId = serviceContractObj.Id;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.UnitPrice = 100;
        ContractLineItemObj.StartDate = System.today();
        ContractLineItemObj.EndDate = System.today().addDays(120);
        //insert ContractLineItemObj;
        cliList.add(ContractLineItemObj);

        ContractLineItem ContractLineItemObj1 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj1.SBQQSC__Account__c = vAccount2.Id;
        ContractLineItemObj1.PricebookEntryId = pbeHW.Id;
        ContractLineItemObj1.ServiceContractId = serviceContractObj.Id;
        ContractLineItemObj1.Quantity = 10;
        ContractLineItemObj1.UnitPrice = 100;
        ContractLineItemObj1.StartDate = System.today();
        ContractLineItemObj1.EndDate = System.today().addDays(120);
        //insert ContractLineItemObj;
        cliList.add(ContractLineItemObj1);

        insert cliList;
        Assert.areEqual(2, cliList.size());

        Entitlement ent = new Entitlement(Name='Testing', 
                                            AccountId=act.Id,
                                            AssetId = asst.Id,
                                            ServiceContractId = serviceContractObj.id,
                                            ContractLineItemId = ContractLineItemObj.id,
                                            Product__c =prdHW.id,
                                            StartDate = Date.today(),
                                            EndDate = Date.today().addDays(365));
        insert ent;

            Entitlement ent1 = new Entitlement(Name='Testing', 
                                            AccountId=act.Id,
                                            AssetId = asst2.Id,
                                            ServiceContractId = serviceContractObj.id,
                                            ContractLineItemId = ContractLineItemObj1.id,
                                            Product__c =prdHW.id,
                                            StartDate = Date.today(),
                                            EndDate = Date.today().addDays(365));
        insert ent1;

        List<SBQQ__Quote__c>lstQuote = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__SubscriptionTerm__c = 12;
        qt.SBQQ__Primary__c = true;
        // qt.SBQQ__Type__c = 'Quote';
        qt.SBQQ__Type__c = 'Renewal+Expansion';
        //qt.SBQQ__EffectiveQuantity__c = 0;
        qt.RecordTypeId=Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Draft Quote').getRecordTypeId();
        qt.Amended_Renewed_Service_Contract__c = serviceContractObj.Id;
        lstQuote.add(qt);        
        insert qt;
            
        system.assert(qt.Id != null);

        Test.starttest();
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id,Category__c = 'Bundle',SBQQ__ProrateMultiplier__c=44,Expected_Trade_Up_Discount__c=10,Trade_Up_Discount__c = 10, SBQQ__Product__c = prdLic.Id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046', Product_Level__c = 'Hardware' , Product_Type__c = 'Hardware',Trade_Up_Multiplier__c =1,SBQQ__SubscriptionTerm__c=12,Trade_Up_Serial_Number__c='XYX' );  
        insert qli2;
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id,Category__c = 'Bundle',SBQQ__RequiredBy__c=qli2.Id,Expected_Trade_Up_Discount__c=10,SBQQ__ProrateMultiplier__c=44,Trade_Up_Discount__c = 10, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 0, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046', Product_Level__c = 'Hardware' , Product_Type__c = 'Hardware',Trade_Up_Multiplier__c =1,SBQQ__SubscriptionTerm__c=12);  
        insert qli1;

        SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id,Category__c = 'Bundle',Expected_Trade_Up_Discount__c=10,Trade_Up_Discount__c = 10,SBQQ__ProrateMultiplier__c=36, SBQQ__Product__c = prdLic.Id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046', Product_Level__c = 'Hardware' , Product_Type__c = 'Hardware',Trade_Up_Multiplier__c =1,SBQQ__SubscriptionTerm__c=12,Trade_Up_Serial_Number__c='XYX', Trade_Up_Serial_Number_on_HW__c = 'XYX' );  
        insert qli3;

        list<SBQQ__QuoteLine__c> qlList = new list<SBQQ__QuoteLine__c>();
        qlList.add(qli2);
        qlList.add(qli1);
        qlList.add(qli3);

        Assert.areEqual(3, qlList.size());

        Map<Id,Decimal> maptredeup = new Map<Id,Decimal>();
        QuoteTriggerHandler.isRecursiveLinkOppEnt = false;
        qt.SBQQ__Primary__c = true;
        update qt;
        String jsonVal ='' ; 
        Map<Id,List<Id>> mapOfReqByVsEnt = new Map<Id,List<Id>>();
        mapOfReqByVsEnt.put(qli1.Id,new List<Id>{ent.Id});
        Map<Id,Integer> mapOfReqByVsCount = new  Map<Id,Integer>();
        mapOfReqByVsCount.put(qli1.Id,1);

        maptredeup.put(qli1.Id,qli1.Expected_Trade_Up_Discount__c);
        maptredeup.put(qli2.Id,qli2.Expected_Trade_Up_Discount__c);
        List < ProcessTradeUpCalcController.QuotelineData > QuotelineDataList = new List < ProcessTradeUpCalcController.QuotelineData > ();
            QuotelineDataList.add(new ProcessTradeUpCalcController.QuotelineData(qli1, qli1.Expected_Trade_Up_Discount__c));
            QuotelineDataList.add(new ProcessTradeUpCalcController.QuotelineData(qli2, qli2.Expected_Trade_Up_Discount__c));
            jsonVal = String.valueOf(QuotelineDataList);
            String mujson =  JSON.serialize(QuotelineDataList);
            
            ProcessTradeUpCalcController.callCalcConfirmationFromMap(qt.id,mapOfReqByVsEnt);
            
        }
   }

  testMethod static void testMethod3() {
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Validation_Rules__c = True,
        Disable_SBQQ_Quote_Triggers__c = True,
        Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
        Disable_SBQQ_QuoteLine_Triggers__c = True,
        Disable_Opportunity_Validation_Rules__c = True,
        Disable_Opportunity_Triggers__c = True,
        Disable_Entitlement_Validation_Rules__c=true);
        insert cdf;
        system.assert(cdf.Id != null);
        TriggerControl__c TC = new TriggerControl__c();
        TC.Name = 'Entitlement';
        TC.DisableTrigger__c = true;
        TC.DisableTrigger__c = true;
        TC.Last_Batch_Run_Date__c = Date.newInstance(2021,04,30);
        TC.SendEmail__c = false;
        insert TC;
        User usr1 = Replacement_TestDataFactory.getUser();
        insert usr1;
        System.runAs(usr1) {

        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        system.assert(act.Id != null);
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
            
        Account vAccount3 = new Account();
        vAccount3.Name = 'Test Account';
        vAccount3.ParentId = act.id;  
        vAccount3.recordTypeId = vAccount.recordTypeId;
        accountList.add(vAccount3);
        insert accountList;

        Assert.areEqual(3, accountList.size());

        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opp.AccountId = act.Id;
        opp.CloseDate = Date.newInstance(2021,04,30);
        opp.Partner_Lookup__c = vAccount2.id;
        opp.Distributor_Lookup__c = vAccount.id;
        insert opp;

        Map<String, Object> prdMap1 = new Map<String, Object> {
            'Name' => 'Subscription', 
                'IsActive' => true, 
                'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                'SBQQ__SubscriptionTerm__c' => 12, 
                'SBQQ__SubscriptionType__c' => 'Renewable',
                'Product_Type__c' => 'Edition Upgrade'
                };
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        insert prdSubs;
            
        Product2 prdHW = new Product2(Name='Pord-GO-B',ProductCode='Product-GO-123XYZ',isActive=true,Eligible_For_Trade_Up__c=true, Product_Type__c = 'Edition Upgrade', Product_Level__c = 'Addon', Eligible_HW_for_Expansion__c = 'R6416S,R6416SE',
                                        Usable_Capacity__c = 12,Appliance_Model_HW__c='R6416S',Trade_Up_HW_Value__c=10,Tradeup_Pattern__c = 'Addon' );
        prdHW.IsActive = true;
        insert prdHW;

        Product2 prdLic = new Product2(Name='Pord-GO-B',ProductCode='Product-GO-123XZ',isActive=true, Product_Type__c = 'Edition Upgrade', Product_Level__c = 'Addon', Category__c = 'Bundle', 
                                    Trade_Up_HW_Value__c=30,     Trade_Up_Multiplier__c = 1.00,Eligible_For_Trade_Up__c=true,Tradeup_Pattern__c = 'Addon');
        prdLic.IsActive = true;
        insert prdLic;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();

        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        PricebookEntry pbeLic = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeLic.Product2Id = prdLic.Id;
        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pBList.add(pbeSubs);
        pBList.add(pbeHW);
        pBList.add(pbeLic);

        insert pBList;

        Assert.areEqual(3, pBList.size());   
        Asset asst = new Asset(
        Name= 'Test1234567Asset', SerialNumber= 'Test1234567Asset',Serial_Number__c= 'Test1234567Asset',Product2ID=prdHW.Id,
        Accountid =act.Id, Rubrik_Suite__c = 'Enterprise', Free_HW_Refresh_Forfeited__c = false, Eligible_for_Free_HW__c = 'True'
        );
        Asset asst2 = new Asset(
        Name= 'XYX', SerialNumber= 'XYX',Serial_Number__c= 'XYX',Product2ID=prdHW.Id,
        Accountid =act.Id, Rubrik_Suite__c = 'Enterprise', Free_HW_Refresh_Forfeited__c = false, Eligible_for_Free_HW__c = 'True'
        );
        insert new List<Asset>{asst,asst2};



        List<ServiceContract> contractList = new List<ServiceContract>();
        ServiceContract serviceContractObj = new ServiceContract();
        serviceContractObj.Name = 'PolarisContractRenewalQuotesUpdateTests';
        serviceContractObj.SBQQSC__Opportunity__c = opp.Id;
        //serviceContractObj.SBQQSC__Quote__c = quoteRec1.Id;
        //serviceContractObj.SBQQSC__RenewalOpportunity__c = lstOpportunity[1].Id;
        //serviceContractObj.AccountId = customer.Id;
        serviceContractObj.StartDate = System.today();
        serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj.Term = 36;
        //serviceContractObj.SBQQSC__RenewalOpportunity__c = opp.Id;
        serviceContractObj.EndDate = System.today().addDays(365);
        serviceContractObj.SBQQSC__RenewalForecast__c = false;
        serviceContractObj.SBQQSC__RenewalTerm__c = 12;


        contractList.add(serviceContractObj);
        insert contractList;
        Assert.areEqual(1, contractList.size());        
        List<contractLineItem> cliList = new List<contractLineItem>(); 
        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj.SBQQSC__Account__c = vAccount2.Id;
        ContractLineItemObj.PricebookEntryId = pbeHW.Id;
        ContractLineItemObj.ServiceContractId = serviceContractObj.Id;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.UnitPrice = 100;
        ContractLineItemObj.StartDate = System.today();
        ContractLineItemObj.EndDate = System.today().addDays(120);
        //insert ContractLineItemObj;
        cliList.add(ContractLineItemObj);

        ContractLineItem ContractLineItemObj1 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj1.SBQQSC__Account__c = vAccount2.Id;
        ContractLineItemObj1.PricebookEntryId = pbeHW.Id;
        ContractLineItemObj1.ServiceContractId = serviceContractObj.Id;
        ContractLineItemObj1.Quantity = 10;
        ContractLineItemObj1.UnitPrice = 100;
        ContractLineItemObj1.StartDate = System.today();
        ContractLineItemObj1.EndDate = System.today().addDays(120);
        //insert ContractLineItemObj;
        cliList.add(ContractLineItemObj1);

        insert cliList;
        Assert.areEqual(2, cliList.size());

        Entitlement ent = new Entitlement(Name='Testing', 
                                            AccountId=act.Id,
                                            AssetId = asst.Id,
                                            ServiceContractId = serviceContractObj.id,
                                            ContractLineItemId = ContractLineItemObj.id,
                                            Product__c =prdHW.id,
                                            StartDate = Date.today(),
                                            EndDate = Date.today().addDays(365));
        insert ent;

            Entitlement ent1 = new Entitlement(Name='Testing', 
                                            AccountId=act.Id,
                                            AssetId = asst2.Id,
                                            ServiceContractId = serviceContractObj.id,
                                            ContractLineItemId = ContractLineItemObj1.id,
                                            Product__c =prdHW.id,
                                            StartDate = Date.today(),
                                            EndDate = Date.today().addDays(365));
        insert ent1;

        List<SBQQ__Quote__c>lstQuote = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__SubscriptionTerm__c = 12;
        qt.SBQQ__Primary__c = true;
        // qt.SBQQ__Type__c = 'Quote';
        qt.SBQQ__Type__c = 'Renewal+Expansion';
        //qt.SBQQ__EffectiveQuantity__c = 0;
        qt.RecordTypeId=Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Draft Quote').getRecordTypeId();
        qt.Amended_Renewed_Service_Contract__c = serviceContractObj.Id;
        lstQuote.add(qt);        
        insert qt;
            
        system.assert(qt.Id != null);

        Test.starttest();
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id,Category__c = 'Bundle',SBQQ__ProrateMultiplier__c=10,Expected_Trade_Up_Discount__c=10,Trade_Up_Discount__c = 10, SBQQ__Product__c = prdLic.Id, SBQQ__Quantity__c = 1,
                                                        SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046', Max_Credit_Amount__c = null, Existing_TB__c = null,
                                                        Product_Level__c = 'Hardware' , Product_Type__c = 'Edition Upgrade',Trade_Up_Multiplier__c =1,SBQQ__SubscriptionTerm__c=12,Trade_Up_Serial_Number__c='XYX' );  
        insert qli2;
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id,Category__c = 'Bundle',SBQQ__RequiredBy__c=qli2.Id,Expected_Trade_Up_Discount__c=10,SBQQ__ProrateMultiplier__c=10,
                                                        Trade_Up_Discount__c = 10, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 0, SBQQ__Number__c = 1, Max_Credit_Amount__c = null, Existing_TB__c = null,
                                                        SubscribedAssetNames__c = 'BB192863040046', Product_Level__c = 'Hardware' , Product_Type__c = 'Edition Upgrade',Trade_Up_Multiplier__c =1,SBQQ__SubscriptionTerm__c=12);  
        insert qli1;

        SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id,Category__c = 'Bundle',Expected_Trade_Up_Discount__c=10,Trade_Up_Discount__c = 10,SBQQ__ProrateMultiplier__c=12,
                                                        SBQQ__Product__c = prdLic.Id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046', Max_Credit_Amount__c = null, Existing_TB__c = null,
                                                        Product_Level__c = 'Hardware' , Product_Type__c = 'Edition Upgrade',Trade_Up_Multiplier__c =1,SBQQ__SubscriptionTerm__c=12,Trade_Up_Serial_Number__c='XYX', Trade_Up_Serial_Number_on_HW__c = 'XYX' );  
        insert qli3;

        list<SBQQ__QuoteLine__c> qlList = new list<SBQQ__QuoteLine__c>();
        qlList.add(qli2);
        qlList.add(qli1);
        qlList.add(qli3);

        Assert.areEqual(3, qlList.size());

        Map<Id,Decimal> maptredeup = new Map<Id,Decimal>();
        QuoteTriggerHandler.isRecursiveLinkOppEnt = false;
        qt.SBQQ__Primary__c = true;
        update qt;
        String jsonVal ='' ; 
        Map<Id,List<Id>> mapOfReqByVsEnt = new Map<Id,List<Id>>();
        mapOfReqByVsEnt.put(qli1.Id,new List<Id>{ent.Id});
        Map<Id,Integer> mapOfReqByVsCount = new  Map<Id,Integer>();
        mapOfReqByVsCount.put(qli1.Id,1);

        maptredeup.put(qli1.Id,qli1.Expected_Trade_Up_Discount__c);
        maptredeup.put(qli2.Id,qli2.Expected_Trade_Up_Discount__c);
        List < ProcessTradeUpCalcController.QuotelineData > QuotelineDataList = new List < ProcessTradeUpCalcController.QuotelineData > ();
            QuotelineDataList.add(new ProcessTradeUpCalcController.QuotelineData(qli1, qli1.Expected_Trade_Up_Discount__c));
            QuotelineDataList.add(new ProcessTradeUpCalcController.QuotelineData(qli2, qli2.Expected_Trade_Up_Discount__c));
            jsonVal = String.valueOf(QuotelineDataList);
            String mujson =  JSON.serialize(QuotelineDataList);
            
            ProcessTradeUpCalcController.callCalcConfirmationFromMap(qt.id,mapOfReqByVsEnt);
            ProcessTradeUpCalcController.fetchRecords(qt.id,qli1.Id,'BB','[]');
                ProcessTradeUpCalcController.callFinalUpdate(mujson,mapOfReqByVsEnt,qt.id);
            
        }
    }
}