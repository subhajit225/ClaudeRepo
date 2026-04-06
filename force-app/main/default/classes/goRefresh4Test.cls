/** Test class for DisplayAllAssetsControllerPaginated2_v4*/
@isTest
public class goRefresh4Test{
    @testSetup static void setup() {
        
        
        /*TriggerHandler.bypass('SBQQ_QuoteLineTrigger'); 
        TriggerHandler.bypass('SBQQ_QuoteLineTriggerHandler');
        TriggerHandler.bypass('QuoteTriggerHelper');
        TriggerHandler.bypass('QuoteTriggerHandler');
        TriggerHandler.bypass('TriggerHandler');
        TriggerHandler.bypass('QuoteTrigger');
        TriggerHandler.bypass('AssetTriggerHelper');
        TriggerHandler.bypass('AssetTriggerHandler');
        TriggerHandler.bypass('AssetTrigger');
        TriggerHandler.bypass('QuoteService');
        SBQQ.TriggerControl.disable();*/
        
        //TriggerControls.disableQuoteLineGroupTrigger = true;
        checkRecursive.stopOrderTriggerOnRMAInsert = true;
        
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Validation_Rules__c = True,Disable_SBQQ_Quote_Triggers__c = true
                                                                           );  
        insert cdf;
        List<Account> newAccList = new List<Account>();
        Account testAcc = new account();
        testAcc.Name = 'Test';
        testAcc.Is_L3_Eligible_Account__c = true;
        testAcc.ETM_Area__c = 'AMER-FED';
        newAccList.add(testAcc);
        
        Account testAcc1 = new account();
        testAcc1.Name = 'Rubrik';
        testAcc1.Is_L3_Eligible_Account__c = true;
        testAcc1.ETM_Area__c = 'AMER-FED';
        newAccList.add(testAcc1);
        insert newAccList;
        
        Contact createCon = new Contact();
        createCon.AccountId = testAcc.Id;
        createCon.Email='test.user@rurbrik.com';
        createCon.FirstName='test';
        createCon.LastName='TestContact01';
        createCon.Phone = '8971371780';
        insert createCon;
        
        Opportunity opp = new Opportunity();
        opp.AccountId = testAcc.Id;
        opp.CloseDate = Date.today()+1;
        opp.Deal_Registration_Type__c = 'Rubrik Sourced';
        opp.LeadSource = 'Channel Marketing';
        opp.Polaris_Portal_Contact__c = createCon.Id;
        opp.Initial_Contacts_Name__c = createCon.Id;
        opp.Name = 'Test01'; 
        opp.StageName = '1 Discovery';
        opp.Opportunity_Sub_Type__c = 'Regular';
        opp.Opportunity_Type__c = 'New Customer';
        opp.Installation_Assigned_To__c = 'FE Install'; 
        opp.Partner_Level_Of_Involvement__c = '1.Rubrik initiated, Partner was fulfillment only'; 
        opp.Lost_To_Won_Against__c = 'Actifio';
        opp.Aspen_Eligibility__c = 'Proposed Aspen';
        insert opp;
        
        List<Product2> newProdList = new List<Product2>();
        List<PricebookEntry> newPBEntryList = new List<PricebookEntry>();
        
        Pricebook2 customPB = new Pricebook2(Name='CPQ PriceBook', isActive=true);
        insert customPB;
        Id pricebookId = Test.getStandardPricebookId(); 
        System.debug(pricebookId);
        Product2 prod = new Product2();
        prod.Name = 'test';
        prod.Description = 'testtest';
        prod.SBQQ__DefaultQuantity__c = 10;
        prod.ProductCode = 'test';
        prod.Product_Type__c = 'Hardware';
        prod.License_Type__c = 'Perpetual';
        prod.Family = 'R6000';
        prod.Product_NIC_Type__c = 'SFP+';
        prod.Support_Tier__c = 'S2';
        prod.Usable_Capacity__c = 60;
        prod.Capacity__c = '96TB';
        prod.RWD_Version__c = 'v21.0';
        prod.Category__c = 'Support';
        prod.Product_Level__c = 'Wrapper';
        newProdList.add(prod);
        
                
        
        Product2 prod2 = new Product2();
        prod2.Name = 'test1';
        prod2.Description = 'testtest';
        prod2.ProductCode = 'test1';
        prod2.Product_Type__c = 'Hardware';
        prod2.License_Type__c = 'Perpetual';
        prod2.Family = 'R6000';
        prod2.Product_NIC_Type__c = '10GBase-T';
        prod2.Support_Tier__c = 'S1';
        prod2.Usable_Capacity__c = 60;
        prod2.Capacity__c = '120TB';
        prod2.Category__c = 'Hardware';
        prod2.Product_Level__c = 'Hardware';
        prod2.X0__c = false;
        prod2.RWD_Rubrik_Edition_Offerings__c = 'Business Edition';
        prod2.Product_Payment_Option__c = 'Prepay';
        prod2.Support_Type__c = 'Premium';
        //prod2.Product_Level__c = 'Wrapper';
        newProdList.add( prod2);
        
        
        Product2 prod3 = new Product2();
        prod3.Name = 'test2';
        prod3.Description = 'testtest';
        prod3.ProductCode = 'test2';
        prod3.Product_Type__c = 'Accessories';
        prod3.License_Type__c = 'Perpetual';
        prod3.Family = 'R6000';
        prod3.Product_NIC_Type__c = '10GBase-T';
        prod3.Support_Tier__c = 'S1';
        prod3.Usable_Capacity__c = 60;
        prod3.Capacity__c = '120TB';
        prod3.Category__c = 'Hardware';
        prod.Product_Level__c = 'Support';
        newProdList.add(prod3);
        
        
        Product2 prod4 = new Product2();
        prod4.Name = 'test2';
        prod4.Description = 'testtest';
        prod4.ProductCode = 'test2';
        prod4.Product_Type__c = 'Accessories';
        prod4.License_Type__c = 'Perpetual';
        prod4.Family = 'R6000';
        prod4.Product_NIC_Type__c = '10GBase-T';
        prod4.Support_Tier__c = 'S1';
        prod4.Usable_Capacity__c = 60;
        prod4.Capacity__c = '120TB';
        prod4.Category__c = 'Hardware';
        //prod4.Product_Level__c = 'Hybrid Software';
        prod4.isActive = true;
        newProdList.add(prod4);
        
        Product2 prod5 = new Product2();
        prod5.Name = 'test456';
        prod5.Description = 'testtest';
        prod5.ProductCode = 'RBK-DATA-MIGRATION1';
        prod5.Product_Type__c = 'RBK-DATA-MIGRATION';
        prod5.License_Type__c = 'Perpetual';
        prod5.Family = 'R6000';
        prod5.Product_NIC_Type__c = '10GBase-T';
        prod5.Support_Tier__c = 'S1';
        prod5.Usable_Capacity__c = 60;
        prod5.Capacity__c = '120TB';
        prod5.Category__c = 'Hardware';
        prod5.Product_Level__c = 'Hybrid Software';
        prod5.isActive = true;
        newProdList.add(prod5);

        Product2 prod6 = new Product2();
        prod6.Name = 'test678';
        prod6.Description = 'testtest';
        prod6.ProductCode = 'RBK-DATA-MIGRATION1';
        prod6.Product_Type__c = 'RBK-DATA-MIGRATION';
        prod6.License_Type__c = 'Perpetual';
        prod6.Family = 'R6000';
        prod6.Product_NIC_Type__c = '10GBase-T';
        prod6.Support_Tier__c = 'S1';
        prod6.Usable_Capacity__c = 60;
        prod6.Capacity__c = '120TB';
        prod6.Category__c = 'Hardware';
        prod6.isActive = true;
        newProdList.add(prod6);

		Product2 prod7 = new Product2();
        prod7.Name = 'test6789';
        prod7.Description = 'testtest';
        prod7.ProductCode = 'RBK-DATA-MIGRATION1';
        prod7.Product_Type__c = 'RBK-DATA-MIGRATION';
        prod7.License_Type__c = 'Perpetual';
        prod7.Family = 'R6000';
        prod7.Product_NIC_Type__c = '10GBase-T';
        prod7.Support_Tier__c = 'S1';
        prod7.Usable_Capacity__c = 60;
        prod7.Capacity__c = '120TB';
        prod7.Category__c = 'Support';
		prod7.Support_Type__c = 'Premium';
        prod7.isActive = true;
        newProdList.add(prod7);

        insert newProdList;
        for (Product2 prod1 : newProdList) {
            System.debug('NAME'+prod1.name+'ID'+prod1.id);
        }
        PricebookEntry pbEntry = new PricebookEntry();
        pbEntry.Product2Id = prod.Id;
        pbEntry.UnitPrice = 10;
        pbEntry.IsActive = TRUE;
        pbEntry.Pricebook2id = pricebookId;
        newPBEntryList.add(pbEntry);
        
        PricebookEntry pbEntry1 = new PricebookEntry();
        pbEntry1.Product2Id = prod.Id;
        pbEntry1.UnitPrice = 11;
        pbEntry1.IsActive = TRUE;
        pbEntry1.Pricebook2id = customPB.ID;
        newPBEntryList.add(pbEntry1) ;

        PricebookEntry pbEntry2 = new PricebookEntry();
        pbEntry2.Product2Id = prod2.Id;
        pbEntry2.UnitPrice = 10;
        pbEntry2.IsActive = TRUE;
        pbEntry2.Pricebook2id = pricebookId;
        newPBEntryList.add(pbEntry2);
        
        PricebookEntry pbEntry22 = new PricebookEntry();
        pbEntry22.Product2Id = prod2.Id;
        pbEntry22.UnitPrice = 10;
        pbEntry22.IsActive = TRUE;
        pbEntry22.Pricebook2id = customPB.ID;
        newPBEntryList.add(pbEntry22) ;
        
        PricebookEntry pbEntry4 = new PricebookEntry();
        pbEntry4.Product2Id = prod4.Id;
        pbEntry4.UnitPrice = 10;
        pbEntry4.IsActive = TRUE;
        pbEntry4.Pricebook2id = pricebookId;
        newPBEntryList.add(pbEntry4);
        
        PricebookEntry pbEntry3 = new PricebookEntry();
        pbEntry3.Product2Id = prod3.Id;
        pbEntry3.UnitPrice = 10;
        pbEntry3.Pricebook2id = pricebookId;
        pbEntry3.IsActive = TRUE;
        newPBEntryList.add(pbEntry3);
        
        PricebookEntry pbEntry5 = new PricebookEntry();
        pbEntry5.Product2Id = prod5.Id;
        pbEntry5.UnitPrice = 10;
        pbEntry5.Pricebook2id = pricebookId;
        pbEntry5.isactive = true;
        newPBEntryList.add(pbEntry5);

		PricebookEntry pbEntry6 = new PricebookEntry();
        pbEntry6.Product2Id = prod6.Id;
        pbEntry6.UnitPrice = 10;
        pbEntry6.Pricebook2id = pricebookId;
        pbEntry6.isactive = true;
        newPBEntryList.add(pbEntry6);
		
		PricebookEntry pbEntry7 = new PricebookEntry();
        pbEntry7.Product2Id = prod7.Id;
        pbEntry7.UnitPrice = 10;
        pbEntry7.Pricebook2id = pricebookId;
        pbEntry7.isactive = true;
        newPBEntryList.add(pbEntry7);	

		insert newPBEntryList;
        System.debug(newPBEntryList);
        
        SBQQ__ProductFeature__c prodFeature = new SBQQ__ProductFeature__c();
        prodFeature.Name = 'R6000 Series';
        prodFeature.SBQQ__ConfiguredSKU__c = prod.Id;
        prodFeature.SBQQ__Number__c = 1;
        insert prodFeature;
        
        SBQQ__ProductFeature__c prodFeature1 = new SBQQ__ProductFeature__c();
        prodFeature1.Name = 'Support';
        prodFeature1.SBQQ__ConfiguredSKU__c = prod.Id;
        prodFeature1.SBQQ__Number__c = 2;
        insert prodFeature1;
        
        SBQQ__ProductOption__c prodOpt = new SBQQ__ProductOption__c();
        prodOpt.Refresh_Default_Option__c = false;
        prodOpt.Refresh_Rubrik_Suite_Availability__c = 'Enterprise';
        prodOpt.SBQQ__ConfiguredSKU__c = prod.Id;
        prodOpt.SBQQ__OptionalSKU__c = prod2.Id;
        prodOpt.SBQQ__Type__c = 'Related Product';
        prodOpt.SBQQ__Feature__c = prodFeature.Id;
        prodOpt.Support_Type__c = 'Premium';
        prodOpt.SBQQ__Number__c = 1;
        insert prodOpt;
        
        SBQQ__ProductOption__c prodOpt2 = new SBQQ__ProductOption__c();
        prodOpt2.Refresh_Default_Option__c = false;
        prodOpt2.SBQQ__ConfiguredSKU__c = prod.Id;
        prodOpt2.SBQQ__OptionalSKU__c = prod2.Id;
        prodOpt2.Refresh_Rubrik_Suite_Availability__c = 'Enterprise';
        prodOpt2.SBQQ__Type__c = 'Related Product';
        prodOpt2.SBQQ__Feature__c = prodFeature.Id;
        prodOpt2.Support_Type__c = 'Premium';
        prodOpt2.SBQQ__Number__c = 2;
		prodOpt2.Refresh_Default_Option__c = true;
        insert prodOpt2;

		/*SBQQ__ProductOption__c prodOpt3 = new SBQQ__ProductOption__c();
        prodOpt3.Refresh_Default_Option__c = false;
        prodOpt3.SBQQ__ConfiguredSKU__c = prod.Id;
        prodOpt3.SBQQ__OptionalSKU__c = prod7.Id;
        prodOpt3.SBQQ__Type__c = 'Related Product';
        prodOpt3.SBQQ__Feature__c = prodFeature.Id;
        prodOpt3.Support_Type__c = 'Premium';
        prodOpt3.SBQQ__Number__c = 2;
		prodOpt3.Refresh_Default_Option__c = true;
        insert prodOpt3;*/
        
        
        List<Custom_Upgrade_Source__c> customUpgradeSourceList = new List<Custom_Upgrade_Source__c>();
        Custom_Upgrade_Source__c customUpgradeSource = new Custom_Upgrade_Source__c();
        customUpgradeSource.Active__c = true;
        customUpgradeSource.UpgradeProduct__c = prod.id;
        customUpgradeSource.Source_Product__c = prod4.id;
        
        customUpgradeSourceList.add(customUpgradeSource);
        
        Custom_Upgrade_Source__c customUpgradeSource1 = new Custom_Upgrade_Source__c();
        customUpgradeSource1.Active__c = true;
        customUpgradeSource1.Source_Product__c = prod.id;
        customUpgradeSource1.UpgradeProduct__c = prod4.id;
        
        customUpgradeSourceList.add(customUpgradeSource1);
        
        Custom_Upgrade_Source__c customUpgradeSource2 = new Custom_Upgrade_Source__c();
        customUpgradeSource2.Active__c = true;
        customUpgradeSource2.Source_Product__c = prod2.id;
		customUpgradeSource2.UpgradeProduct__c = prod4.id;
		
		customUpgradeSourceList.add(customUpgradeSource2);

		Custom_Upgrade_Source__c customUpgradeSource3 = new Custom_Upgrade_Source__c();
        customUpgradeSource3.Active__c = true;
        customUpgradeSource3.Source_Product__c = prod7.id;
		customUpgradeSource3.UpgradeProduct__c = prod2.id;
        
        customUpgradeSourceList.add(customUpgradeSource3);
        
        insert customUpgradeSourceList;
        
        
        Opportunity testOpp = new Opportunity(Id = opp.Id);
        testOpp.Pricebook2Id = pbEntry.Pricebook2id;
        update testOpp;
        
        Order od = new Order();
        od.Status = 'Draft';
        od.AccountId = testAcc.Id;
        od.OpportunityId = opp.Id;
        od.EffectiveDate = Date.Today();
        od.ShippingStreet ='Test Street';
        od.ShippingCity ='Test City';
        od.ShippingState ='California';
        od.ShippingCountry ='United States';
        od.ShippingPostalcode ='94820';
        od.Est_Ship_Date__c = system.today();
        od.Actual_Order_Ship_Date__c=system.today();
        od.Pricebook2Id = pricebookId;
        insert od;
        
        List<OrderItem> NewOrderItemList = new List<OrderItem>();
        OrderItem oritem = new OrderItem();
        oritem.OrderId=od.Id;
        oritem.Quantity=10;
        oritem.PricebookEntryId=pbEntry.Id;
        oritem.UnitPrice = 10;
        oritem.Product2Id = prod.Id;
        NewOrderItemList.add(oritem) ;
        
        OrderItem oritem1 = new OrderItem();
        oritem1.OrderId=od.Id;
        oritem1.Quantity=10;
        oritem1.PricebookEntryId=pbEntry.Id;
        oritem1.UnitPrice = 10;
        oritem1.Product2Id = prod2.Id;
        oritem1.SBQQ__RequiredBy__c = oritem.Id;
        NewOrderItemList.add(oritem1) ;
        
        OrderItem oritem2 = new OrderItem();
        oritem2.OrderId=od.Id;
        oritem2.Quantity=10;
        oritem2.PricebookEntryId=pbEntry.Id;
        oritem2.UnitPrice = 10;
        oritem2.Product2Id = prod3.Id;
        oritem2.SBQQ__RequiredBy__c = oritem1.Id;
        NewOrderItemList.add(oritem2) ;
        insert NewOrderItemList;
        
        
        List<Asset> NewAssetList = new List<Asset>();
        Asset asset = new Asset();
        asset.Name = '123456';
        asset.Serial_Number__c = '123456';
        asset.SerialNumber = '123456';
        asset.Quantity = 1;
        asset.Licensing_Model__c = prod.License_Type__c;
        asset.Rubrik_Suite__c = 'Enterprise';
        asset.Payment_Options__c = 'Prepay';
        asset.Support_Type__c = 'Premium';
        asset.AccountId = testAcc.id;
        asset.Product2Id = prod.Id;
        asset.Order_Service_Item__c = oritem.Id;
        asset.Support_Start_Date__c = Date.Today();
        asset.Premium_Support_End_Date__c = Date.Today() +10;
        asset.UsageEndDate = null;
        asset.Status = 'Purchased';
        NewAssetList.add(asset);
        
        Asset asset2 = new Asset();
        asset2.Name = '1234567';
        asset2.SerialNumber = '1234567';
        asset2.Serial_Number__c = '1234567';
        asset2.Quantity = 1;
        asset2.Licensing_Model__c = prod2.License_Type__c;
        asset2.Rubrik_Suite__c = 'Enterprise';
        asset2.Payment_Options__c = 'Prepay';
        asset2.Support_Type__c = 'L3';
        asset2.AccountId = testAcc.id;
        asset2.Product2Id = prod2.Id;
        asset2.Order_Service_Item__c = oritem1.Id;
        asset2.Support_Start_Date__c = Date.Today();
        asset2.Premium_Support_End_Date__c = Date.Today() +11;
        asset2.UsageEndDate = null;
        asset2.Status = 'Dispatched';
        NewAssetList.add(asset2);
        insert NewAssetList;

		
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Account__c = testAcc.Id;
        quote.SBQQ__Opportunity2__c = testOpp.Id;
        quote.SBQQ__Type__c = 'Quote';
        quote.SBQQ__PriceBook__c = pricebookId;
        quote.RCDMT_EOL_Date__c = System.today()+365;
        quote.RWD_Sales_Rep_Exception__c = 'Exception for On-Prem Quoting';
        quote.RWD_Sales_Rep_Exception_Justification__c = 'test';
        insert quote;
        System.debug('Quoteeeeee'+quote);
        List<SBQQ__QuoteLine__c> NewQlsList = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c();
        qli.SBQQ__Quote__c=quote.Id;
        qli.SBQQ__Product__c=prod.Id;
        qli.SBQQ__Quantity__c=10;
        qli.SBQQ__Number__c=1;
        qli.SBQQ__SubscribedAssetIds__c=asset.Id;
        qli.SubscribedAssetNames__c = 'BB192863040046';
        qli.SBQQ__PricebookEntryId__c = customPB.ID;
        qli.Product_Type__c = 'Appliance';
        qli.Arroyo_Subscribed_Asset_Name__c = '123456789987654321'; 
        NewQlsList.add(qli);
        
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c();
        qli1.SBQQ__Quote__c=quote.Id;
        qli1.SBQQ__Product__c=prod2.Id;
        qli1.SBQQ__Quantity__c=10;
        qli1.SBQQ__Number__c=1;
        qli1.SBQQ__SubscribedAssetIds__c=asset2.Id;
        qli1.SubscribedAssetNames__c = 'BB192863040047';
        qli1.SBQQ__PricebookEntryId__c = customPB.ID;
        qli1.Product_Type__c = 'Support';
        qli1.Arroyo_Subscribed_Asset_Name__c = '123456'; 
        qli1.SBQQ__RequiredBy__c = qli.Id;
        NewQlsList.add(qli1);
        
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c();
        qli2.SBQQ__Quote__c=quote.Id;
        qli2.SBQQ__Product__c=prod5.Id;
        qli2.SBQQ__Quantity__c=10;
        qli2.SBQQ__Number__c=1;
        qli2.SBQQ__SubscribedAssetIds__c=asset2.Id;
        qli2.SubscribedAssetNames__c = 'BB192863040047';
        qli2.SBQQ__PricebookEntryId__c = customPB.ID;
        qli2.Product_Type__c = 'Support';
        qli2.Arroyo_Subscribed_Asset_Name__c = '123456'; 
        qli2.SBQQ__RequiredBy__c = qli.Id;
        NewQlsList.add(qli2);
		Insert NewQlsList;
        List<SBQQ__QuoteLineGroup__c> newQLGList = new List<SBQQ__QuoteLineGroup__c>();
        SBQQ__QuoteLineGroup__c qliGrp = new SBQQ__QuoteLineGroup__c();
        qliGrp.SBQQ__Quote__c = quote.Id;
        qliGrp.Name = 'Renewal Quote';
        newQLGList.add(qliGrp);
        SBQQ__QuoteLineGroup__c qliGrp1 = new SBQQ__QuoteLineGroup__c();
        qliGrp1.SBQQ__Quote__c = quote.Id;
        qliGrp1.Name = 'Expansion Quote';
        newQLGList.add(qliGrp1);
        insert newQLGList;

    }
    
    @isTest static void testMethod1() {
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser;
        
            Test.startTest();
            SBQQ__Quote__C quote = [SELECT Id from SBQQ__Quote__C limit 1];
            SBQQ__QuoteLine__c[] qtline = [SELECT Id from SBQQ__QuoteLine__c limit 4];
            PricebookEntry[] pbentry = [SELECT Id,Product2Id from PricebookEntry limit 4];
            List<SBQQ__Quote__C> quoteList = new List<SBQQ__Quote__C>();
            quoteList.add(quote);
            Assert.areEqual(1, quoteList.size());
            DisplayAllAssetsControllerPaginated2_v4 cnt = new DisplayAllAssetsControllerPaginated2_v4();
            
            List<asset> asstlst= [SELECT Id,Product2Id, Name from Asset LIMIT 100];
			cnt.JsonMapAssetName = asstlst[0].name+','+asstlst[1].name;
			cnt.JsonMapLicenseType = asstlst[0].name+','+ 'SaaS';
            cnt.JsonMapRubrikSuite = asstlst[0].name+','+ 'Business';
			cnt.JsonMapPaymentOption = asstlst[0].name+','+ 'Prepay';  
			cnt.JsonMapSupportType = asstlst[0].name+','+ 'Premium';
			cnt.JsonMapAssetGroup = asstlst[0].name+','+ 'Group-1'; 


            cnt.quoteId=quote.id; 
            cnt.selectedID = asstlst[0].id;   
            cnt.populateSelectedAsset = asstlst[0].id+','+asstlst[1].id;   
            cnt.selectedoptionsstr = asstlst[0].Product2Id+'_'+asstlst[0].id;
            PageReference pgRef1 = Page.DisplayAllAssetsClone2_v4;
            Test.setCurrentPage(pgRef1);             
            ApexPages.currentPage().getParameters().put('newid', quote.id);
            System.runAs(listUser[0]) {
            cnt.fetchAllAssets();
            cnt.getValidProducts();
            cnt.saveAssets();
            cnt.CreateUpgradeAsssets(); 
            DisplayAllAssetsControllerPaginated2_v4.updateDispositionReasons(quote.id);
            DisplayAllAssetsControllerPaginated2_v4.consolidateQuoteLineItems(quote.id);
            DisplayAllAssetsControllerPaginated2_v4.consolidateQuoteLineItemsFF(quote.id);
            cnt.isOldCustomUpgradeSourceActive = false;
            cnt.fetchAllAssets();
            cnt.clear();
            cnt.searchAsset();
            cnt.cancel();
            cnt.backToAssets();
            
            Test.stopTest();
        }
    }
    
    @isTest static void testMethod2() {
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser;
        
            Test.startTest();
            SBQQ__Quote__C quote = [SELECT Id from SBQQ__Quote__C limit 1];
            SBQQ__ProductOption__c potion = [SELECT Id from SBQQ__ProductOption__c limit 1];
            List<SBQQ__Quote__C> quoteList = new List<SBQQ__Quote__C>();
            quoteList.add(quote);
            Assert.areEqual(1, quoteList.size()); 
            DisplayAllAssetsControllerPaginated2_v4.QLIWrapper qliWrapper = new DisplayAllAssetsControllerPaginated2_v4.QLIWrapper();
            qliWrapper.upgradedAsset = 'Asset001';
            qliWrapper.productId = 'Product123';
            qliWrapper.dynamicOptionID = 'OptionXYZ';
            qliWrapper.option = potion;
            qliWrapper.strAssetId = 'Asset987';
            qliWrapper.lineNumber = 5;
            qliWrapper.strRubrikEdition = 'Business';
            qliWrapper.subsAssetNames = 'Asset A, Asset B';

            DisplayAllAssetsControllerPaginated2_v4 cnt = new DisplayAllAssetsControllerPaginated2_v4();
            List<asset> asstlst= [SELECT Id,Product2Id,Rubrik_Suite__c from Asset LIMIT 2];
            List<Product2> prodList= [SELECT Id from Product2 where Name = 'test' LIMIT 100 ];
            List<PriceBookEntry> pbentryList= [SELECT Id,Product2.SBQQ__DefaultQuantity__c,Product2.SBQQ__SubscriptionPricing__c,Product2.SBQQ__SubscriptionType__c,Product2.ProductCode,Product2.SBQQ__NonDiscountable__c,Product2.SBQQ__SubscriptionTerm__c from PriceBookEntry Where UnitPrice = 11 LIMIT 10 ];
            List<SBQQ__QuoteLine__c> qlinelist= [SELECT Id,SBQQ__SubscriptionPricing__c,SBQQ__BundledQuantity__c from SBQQ__QuoteLine__c where SBQQ__Quote__c =: quote.Id LIMIT 10 ];
            DisplayAllAssetsControllerPaginated2_v4.AssetWrapper assetWrapper = new DisplayAllAssetsControllerPaginated2_v4.AssetWrapper();
            assetWrapper.selectedAsset = true;
            assetWrapper.objAsset = asstlst[1];
            assetWrapper.supportTypeInput = 'Premium';
            assetWrapper.selectedSource = 'New Source';
            assetWrapper.options = new List<SelectOption> { new SelectOption('1', 'Option 1'), new SelectOption('2', 'Option 2') };
            assetWrapper.NIC_Type = 'Type B';
            assetWrapper.upgradeExists = true;
            assetWrapper.selectedGroup = asstlst[0].id;
            assetWrapper.licenseType = 'Perpetual';
            assetWrapper.rubrikEditionInput = 'Enterprise';
            cnt.quoteId=quote.id; 
            cnt.selectedID = asstlst[0].id;   
            cnt.populateSelectedAsset = asstlst[1].id+'SupportType##Premium'+'@AssetGroup##'+asstlst[1].id+','+asstlst[0].id;
            cnt.selectedoptionsstr = asstlst[0].Product2Id+'_'+asstlst[0].id;
            cnt.lstAssetWrapper = new list<DisplayAllAssetsControllerPaginated2_v4.AssetWrapper>{assetWrapper};
            cnt.selectedAssets = new list<DisplayAllAssetsControllerPaginated2_v4.AssetWrapper>{assetWrapper};
            PageReference pgRef1 = Page.DisplayAllAssetsClone2_v4;
            Test.setCurrentPage(pgRef1);             
            ApexPages.currentPage().getParameters().put('newid', quote.id);
            System.runAs(listUser[0]) {
            cnt.fetchAllAssets();
            cnt.saveAssets();
            List<Custom_Upgrade_Source__c>  cusList = [SELECT Id from Custom_Upgrade_Source__c LIMIT 2];
            Delete cusList;
            cnt.isOldCustomUpgradeSourceActive = false;
            cnt.CreateUpgradeAsssets(); 
            
            cnt.fetchAllAssets();
            DisplayAllAssetsControllerPaginated2_v4.updateGroupOnQuoteLineItems(quote.Id);
            DisplayAllAssetsControllerPaginated2_v4.updatelineNumberForDataMigSKU(quote.Id);
            DisplayAllAssetsControllerPaginated2_v4.quoteLineSubs(qlinelist[0],pbentryList[0],quoteList);
                Pricebook2[] pricebooks = [Select id,Name from Pricebook2];
                System.debug('pricebooksssssss'+pricebooks);
                SBQQ__Quote__C[] quotes = [Select id,SBQQ__PriceBook__r.name from SBQQ__Quote__C];
                System.debug('asstlsttttttt'+asstlst);
            cnt.AddQuoteLines((String)quote.Id,new list<String>{prodList[0].id+'_'+asstlst[0].id},new list<DisplayAllAssetsControllerPaginated2_v4.AssetWrapper>{assetWrapper});

            
            //DisplayAllAssetsControllerPaginated2_v4.boosterMethod();
            
            Test.stopTest();
        }
    }
}