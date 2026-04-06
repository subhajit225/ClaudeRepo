/**
* Name     : ConvertAssetControllerTest
* @description  : test class for ConvertAssetController
*/
@isTest
public class ConvertAssetControllerTest{
 //public static User usr1 = new User();
        /**
        * Name     : setTriggerSwitch
        * @description  : trigger controls
        * @param vobject
        * @param value
        */
    public static void setTriggerSwitch(String vobject, boolean value){
        TriggerControl__c se= TriggerControl__c.getValues(vobject);
        if(se == null){
            TriggerControl__c setting = new TriggerControl__c();
            setting.Name = vobject;
            setting.DisableTrigger__c = value;
            INSERT setting; 
        }
    } 
    
    /**
    * @description  : data setup for test class
    */
    @testSetup 
    public static void setupMethod() {
        
        ShGl_DisableBusinessLogic__c objCustomSetting = new ShGl_DisableBusinessLogic__c();
        objCustomSetting.Disable_Opportunity_Triggers__c = true;
        objCustomSetting.Disable_Product2_Trigger__c = true;
        objCustomSetting.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
        objCustomSetting.Disable_Account_Triggers__c = true;
        objCustomSetting.Disable_Contact_Triggers__c = true;
        objCustomSetting.Disable_Contract_Line_Item_Triggers__c = true;
        objCustomSetting.Disable_Opportunity_Old_Trigger__c = true;  
        objCustomSetting.Disable_SBQQ_QuoteLine_Triggers__c = true;
        objCustomSetting.Disable_SBQQ_Quote_Triggers__c = true;
        objCustomSetting.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
        objCustomSetting.Disable_ServiceContract_Trigger__c  = true; 
        //objCustomSetting.Disable_Entitlement_Trigger__c = true;
        //objCustomSetting.Disable_Entitlement_Usage_Trigger__c = true;
        insert objCustomSetting;
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.Disable();
        
        /*
         */
        
        List<Product2> prodList = new List<Product2>();
        Product2 prod = new Product2();
        prod.Name = 'RBK-R6412SE-HW-01';
        prod.Description = 'testtest';
        prod.ProductCode = 'RBK-R6412SE-HW-01';
        prod.Product_Type__c = 'Hardware';
        prod.License_Type__c = 'Perpetual';
        prod.Family = 'R6000';
        prod.Product_NIC_Type__c = 'SFP+';
        prod.Support_Type__c = '';
        prod.Support_Tier__c = 'SE1';
        prod.Usable_Capacity__c = 90.0;
        prod.Capacity__c = '144TB';
        prod.RWD_Version__c = '';
        prod.Category__c = 'Support';
        prod.Product_Level__c = '';
        prod.IsActive = True;
        //prod.Pricebook_Entry_Id__c = 
        //insert prod; 
        prodList.add(prod);
        
        Product2 prod2 = new Product2();
        prod2.Name = 'RBK-SVC-PREM-APPLIANCE';
        prod2.Description = 'testtest';
        prod2.ProductCode = 'RBK-SVC-PREM-HW';
        prod2.Product_Type__c = 'HW Support';
        prod2.License_Type__c = '';
        prod2.Support_Type__c = 'Premium';
        prod2.Family = 'Support';
        prod2.Product_NIC_Type__c = '';
        prod2.Support_Tier__c = '';
        //prod2.Usable_Capacity__c = ;
        //prod2.Capacity__c = '120TB';
        prod2.Category__c = 'Support';
        prod2.IsActive = True;
        //prod.Product_Level__c = 'Hardware';
        //insert prod2;
        prodList.add(prod2);
        
        Product2 prod3 = new Product2();
        prod3.Name = 'Rubrik Appliance SFP+ (Fiber)';
        prod3.Description = 'testtest';
        prod3.ProductCode = 'RBK-RWRAPPER4_1';
        prod3.Product_Type__c = '';
        prod3.License_Type__c = '';
        prod3.Family = '';
        prod3.Product_NIC_Type__c = 'SFP+ NIC (Fiber)';
        prod3.Support_Type__c = '';
        prod3.Support_Tier__c = '';
        prod3.Category__c = 'Bundle';
        prod3.Product_Level__c = '';
        prod3.IsActive = True;
        //insert prod3;
        prodList.add(prod3);
        insert prodList;
        
        List<PricebookEntry> pbEntryList = new List<PricebookEntry>();
        
        PricebookEntry pbEntry = new PricebookEntry();
        pbEntry.Product2Id = prodList[0].Id; //prod
        pbEntry.UnitPrice = 10;
        pbEntry.Pricebook2Id = Test.getStandardPricebookId();
        pbEntry.IsActive = true;
        //insert pbEntry;
        pbEntryList.add(pbEntry);
        
        PricebookEntry pbEntry2 = new PricebookEntry();
        pbEntry2.Product2Id = prodList[1].Id; //prod2
        pbEntry2.UnitPrice = 10;
        pbEntry2.Pricebook2Id = Test.getStandardPricebookId();
        pbEntry2.IsActive = true;
        //insert pbEntry2;
        pbEntryList.add(pbEntry2);
        
        PricebookEntry pbEntry3 = new PricebookEntry();
        pbEntry3.Product2Id = prodList[2].Id; //prod3
        pbEntry3.UnitPrice = 10;
        pbEntry3.Pricebook2Id = Test.getStandardPricebookId();
        pbEntry3.IsActive = true;
        //insert pbEntry3;
        pbEntryList.add(pbEntry3);
        
        Pricebook2 customPB = new Pricebook2(Name='CPQ PriceBook', isActive=true);
        insert customPB;
        
        PricebookEntry pbEntry4 = new PricebookEntry();
        pbEntry4.Product2Id = prodList[0].Id;
        pbEntry4.UnitPrice = 10;
        pbEntry4.Pricebook2id = customPB.Id;
        pbEntry4.IsActive = true;
        //insert pbEntry4;
        pbEntryList.add(pbEntry4);
        
        PricebookEntry pbEntry5 = new PricebookEntry();
        pbEntry5.Product2Id = prodList[1].Id;
        pbEntry5.UnitPrice = 10;
        pbEntry5.Pricebook2id = customPB.Id;
        pbEntry5.IsActive = true;
        //insert pbEntry5;
        pbEntryList.add(pbEntry5);
        
        PricebookEntry pbEntry6 = new PricebookEntry();
        pbEntry6.Product2Id = prodList[2].Id;
        pbEntry6.UnitPrice = 10;
        pbEntry6.Pricebook2id = customPB.Id;
        pbEntry6.IsActive = true;
        //insert pbEntry6;
        pbEntryList.add(pbEntry6);
        insert pbEntryList;
        
        List<SBQQ__ProductFeature__c> featureList = new List<SBQQ__ProductFeature__c>();
        SBQQ__ProductFeature__c prodFeature = new SBQQ__ProductFeature__c();
        prodFeature.Name = 'Appliances - Increased Flash';
        prodFeature.SBQQ__ConfiguredSKU__c = prodList[2].Id;
        prodFeature.SBQQ__Number__c = 10;
        prodFeature.SBQQ__Category__c = 'R6000';
        //insert prodFeature;
        featureList.add(prodFeature);
        
        SBQQ__ProductFeature__c prodFeature1 = new SBQQ__ProductFeature__c();
        prodFeature1.Name = 'Support';
        prodFeature1.SBQQ__ConfiguredSKU__c = prodList[0].Id;
        prodFeature1.SBQQ__Number__c = 30;
        prodFeature.SBQQ__Category__c = 'Support';
        //insert prodFeature1;
        featureList.add(prodFeature1);
        insert featureList;
        
        List<SBQQ__ProductOption__c> optionList = new List<SBQQ__ProductOption__c>();
        SBQQ__ProductOption__c prodOpt = new SBQQ__ProductOption__c();
        prodOpt.Refresh_Default_Option__c = false;
        prodOpt.SBQQ__ConfiguredSKU__c = prodList[2].Id;
        prodOpt.SBQQ__OptionalSKU__c = prodList[0].Id;
        prodOpt.SBQQ__Type__c = 'Related Product';
        prodOpt.SBQQ__Feature__c = featureList[0].Id;
        prodOpt.Support_Type__c = '';
        prodOpt.SBQQ__Number__c = 7;
        prodOpt.Licensing_Model__c = 'Subscription';
        prodOpt.Rubrik_Suite__c = 'Foundation';
        prodOpt.Payment_Options__c = 'Prepay';
        //insert prodOpt;
        optionList.add(prodOpt);
        
        SBQQ__ProductOption__c prodOpt1 = new SBQQ__ProductOption__c();
        prodOpt1.Refresh_Default_Option__c = false;
        prodOpt1.SBQQ__ConfiguredSKU__c = prodList[0].Id;
        prodOpt1.SBQQ__OptionalSKU__c = prodList[1].Id;
        prodOpt1.SBQQ__Type__c = 'Component';
        prodOpt1.SBQQ__Feature__c = featureList[1].Id;
        prodOpt1.Support_Type__c = 'Premium';
        prodOpt1.SBQQ__Number__c = 210;
        prodOpt.Licensing_Model__c = 'Subscription';
        prodOpt.Rubrik_Suite__c = 'Foundation';
        prodOpt.Payment_Options__c = 'Prepay';
        //insert prodOpt1;
        optionList.add(prodOpt1);
        insert optionList;

        /*Account accObj = TestDataFactory.getAccount();
        accObj.Eligible_for_RCDM_T__c = true;
        insert accObj;

        Opportunity opp = TestDataFactory.getOpportunity(accObj);
        //opp.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
        opp.Pricebook2Id = customPB.Id;
        insert opp; */

        Account testAcc = new account();
        testAcc.Name = 'CDK Global, Inc.';
        testAcc.Is_L3_Eligible_Account__c = true;
        testAcc.ETM_Area__c = 'AMER-FED';
        testAcc.ParentId = null;
        testAcc.Eligible_for_RCDM_T__c = true;
        insert testAcc;
        
        Contact createCon = new Contact();
        createCon.AccountId = testAcc.Id;
        createCon.Email='test.user@rurbriktest.com.sandbox';
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
        opp.Pricebook2Id = customPB.Id;
        opp.Partner_Lookup__c = null;
        opp.MSP_End_User_Lookup__c = null;
        insert opp;

        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Account__c = testAcc.Id;
        quote.SBQQ__Opportunity2__c = opp.Id;
        quote.SBQQ__Type__c = 'Renewal+Expansion';
        quote.SBQQ__Primary__c = true;
        quote.SBQQ__PriceBook__c = customPB.Id;
        quote.RCDMT_EOL_Date__c = System.today()+365;
        //quote.Is_Federal_Eligible_Quote__c = 'True';    
        quote.RWD_Sales_Rep_Exception__c = 'Exception for On-Prem Quoting';
        quote.RWD_Sales_Rep_Exception_Justification__c = 'test';
        insert quote;
        
        SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c();
        qli.SBQQ__Quote__c = quote.Id;
        qli.SBQQ__Product__c = prodList[2].Id; //prod3
        qli.SBQQ__Quantity__c = 1;
        qli.SBQQ__Number__c = 1;
        qli.SubscribedAssetNames__c = 'AA210664120013';
        qli.SubsAstNameInt__c = 'AA210664120013';
        qli.SBQQ__PricebookEntryId__c = pbEntryList[2].Id;
        insert qli;
        
        
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c();
        qli1.SBQQ__Quote__c = quote.Id;
        qli1.SBQQ__Product__c = prodList[0].Id; //prod
        qli1.SBQQ__Quantity__c = 10;
        qli1.SBQQ__Number__c = 2;
        //qli1.Arroyo_Subscribed_Asset_Name__c = 'AA210664120014';
        qli1.SubscribedAssetNames__c = 'AA165203480094';//'AA210664120014';
        qli.SubsAstNameInt__c = 'AA165203480094';//'AA210664120014';
        qli1.SBQQ__PricebookEntryId__c = pbEntryList[0].Id;
        qli1.Product_Type__c = 'Hardware';
        //qli1.Arroyo_Subscribed_Asset_Name__c = 'Test'; 
        qli1.SBQQ__RequiredBy__c = qli.Id;
        qli1.SBQQ__ProductOption__c = optionList[0].Id;
        //qli1.SBQQ__SubscriptionTerm__c = 36;
        //qli1.Special_Program__c = 'Conversion';
        insert qli1;
        
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c();
        qli2.SBQQ__Quote__c=quote.Id;
        qli2.SBQQ__Product__c=prodList[1].Id; //prod2
        qli2.SBQQ__Quantity__c=10;
        qli2.SBQQ__Number__c=3;
        //qli2.SBQQ__SubscribedAssetIds__c=asset.Id;
        //qli2.SubscribedAssetNames__c = 'BB192863040047';
        qli2.SBQQ__PricebookEntryId__c = pbEntryList[1].Id;
        qli2.SBQQ__ProductOption__c = optionList[1].Id;
        qli2.Product_Type__c = 'HW Support';
        //qli2.Arroyo_Subscribed_Asset_Name__c = '123456'; 
        qli2.SBQQ__RequiredBy__c = qli1.Id;
        insert qli2;
        
        opp.SBQQ__PrimaryQuote__c = quote.Id;
        UPDATE opp;

        SBQQ__QuoteLine__c qliR = new SBQQ__QuoteLine__c();
        qliR.SBQQ__Quote__c = quote.Id;
        qliR.SBQQ__Product__c = prodList[0].Id;
        qliR.SBQQ__Quantity__c = 10;
        qliR.SBQQ__Number__c = 2;
        //qliR.Quote_Line_Type__c = 'Renewal';
        qliR.SBQQ__PricebookEntryId__c = pbEntryList[3].Id;
        qliR.Product_Type__c = 'HW Support';
        qliR.SBQQ__RequiredBy__c = qli.Id;
        qliR.SBQQ__ProductOption__c = optionList[0].Id;
        qliR.Arroyo_Subscribed_Asset_Name__c = 'AA210664120099';
        qliR.SubscribedAssetNames__c = 'AA210664120099';
        insert qliR;

        Order od = new Order();
        od.Status = 'Shipped';
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
        od.Pricebook2Id = customPB.Id;
        od.SBQQ__Quote__c = quote.Id;
        insert od;
        
        OrderItem oritem = new OrderItem();
        oritem.OrderId = od.Id;
        oritem.Quantity = 5;
        oritem.PricebookEntryId = pbEntryList[3].Id;
        oritem.UnitPrice = 10;
        oritem.Product2Id = prodList[0].Id;
        oritem.SBQQ__QuoteLine__c = qli1.Id;
        oritem.SBQQ__QuotedQuantity__c = 10;
        insert oritem;
        
        OrderItem oritem1 = new OrderItem();
        oritem1.OrderId = od.Id;
        oritem1.Quantity = 5;
        oritem1.PricebookEntryId = pbEntryList[4].Id;
        oritem1.UnitPrice = 10;
        oritem1.Product2Id = prodList[1].Id;
        oritem1.SBQQ__RequiredBy__c = oritem.Id;
        oritem.SBQQ__QuoteLine__c = qli2.Id;
        oritem.SBQQ__QuotedQuantity__c = 10;
        insert oritem1;
        
        od.ActivatedDate = System.today();
        od.Status = 'Activated';
        update od;
        
        ServiceContract objContract = new ServiceContract();
        objContract.AccountId = testAcc.Id;
        objContract.SBQQSC__Opportunity__c = opp.Id;
        objContract.SBQQSC__Quote__c = quote.Id;
        objContract.SBQQSC__Order__c = od.Id;
        objContract.Term = 60;
        objContract.Name = 'Contract0101';
        objContract.Pricebook2Id = customPB.Id;
        insert objContract;
        
        ContractLineItem obhContractLine = new ContractLineItem();
        obhContractLine.ServiceContractId = objContract.Id;
        obhContractLine.SBQQSC__Product__c = prodList[1].Id;
        obhContractLine.SBQQSC__ProductOption__c = optionList[1].Id;
        obhContractLine.SBQQSC__Account__c = testAcc.Id;
        obhContractLine.SBQQSC__OptionLevel__c = 2;
        obhContractLine.SBQQSC__OptionType__c = 'Component';
        obhContractLine.SBQQSC__OrderProduct__c = oritem1.Id;
        obhContractLine.SBQQSC__Quantity__c = 5;
        obhContractLine.Quantity = 5;
        obhContractLine.UnitPrice = 10.00;
        obhContractLine.SBQQSC__QuoteLine__c = qli2.Id;
        obhContractLine.PricebookEntryId = pbEntryList[4].Id;
        insert obhContractLine;
        
        Asset asset = new Asset();
        asset.Name = 'AA210664120014';
        asset.Serial_Number__c = 'AA210664120014';
        asset.SerialNumber = 'AA210664120014';// SF-72381
        //asset.Quantity = 1;
        asset.Licensing_Model__c = prodList[0].License_Type__c;
        asset.Rubrik_Suite__c = 'Foundation';
        asset.Payment_Options__c = 'Prepay';
        asset.Support_Type__c = 'Premium';
        asset.AccountId = testAcc.id;
        asset.Product2Id = prodList[0].Id;
        asset.Order_Service_Item__c = oritem.Id;
        asset.Support_Start_Date__c = Date.Today();
        asset.Premium_Support_End_Date__c = Date.Today() +10;
        //asset.Arroyo_Subscribed_Asset_Name__c = 'AA210664120014';
        insert asset;
        
        /*Asset assetx = new Asset();
        assetx.Name = 'AA165203480094';
        assetx.Serial_Number__c = 'AA165203480094';
        assetx.SerialNumber = 'AA165203480094';
        assetx.Licensing_Model__c = prodList[0].License_Type__c;
        assetx.Rubrik_Suite__c = 'Foundation';
        assetx.Payment_Options__c = 'Prepay';
        assetx.Support_Type__c = 'Premium';
        assetx.AccountId = testAcc.id;
        assetx.Product2Id = prodList[0].Id;
        assetx.Order_Service_Item__c = oritem.Id;
        assetx.Support_Start_Date__c = Date.Today();
        assetx.Premium_Support_End_Date__c = Date.Today() +10;
        
        insert assetx;*/
        
        SBQQ__QuoteLineGroup__c quoteLineGrp = new SBQQ__QuoteLineGroup__c(Name='Renewal Quote', SBQQ__Number__c= 2, 
            SBQQ__ListTotal__c= 100, SBQQ__CustomerTotal__c= 100,
            SBQQ__NetTotal__c= 200, SBQQ__Quote__c= quote.Id);
        insert quoteLineGrp;

        //Entitlement 
        List<Entitlement> entList= new List<Entitlement>();

        String recordTypeEntId= Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Manufacturing Entitlement').getRecordTypeId();
      
        setTriggerSwitch('Entitlement', false);
        Entitlement ent = new Entitlement();
        ent.Name= 'Test Entitlement';
        ent.AccountId = testAcc.Id;
        ent.Product__c = prodList[0].Id;
        ent.AssetId= asset.Id;
        ent.StartDate = Date.today().addDays(-365);
        ent.EndDate = Date.today().addDays(365);
        ent.Type ='Phone';
        ent.Renewal_Category__c= null;
        //ent.Terminated_Date__c= null;
        ent.Order_Service_Item__c= oritem.Id;
        ent.ServiceContractId= objContract.Id;
        ent.ContractLineItemId= obhContractLine.Id;
        ent.RecordTypeId=recordTypeEntId;
        entList.add(ent);

        setTriggerSwitch('Entitlement', false);
        Entitlement ent1 = new Entitlement();
        ent1.Name= 'Test Entitlement1';
        ent1.AccountId = testAcc.Id;
        ent1.Product__c = prodList[1].Id;
        ent1.AssetId= null;
        ent1.StartDate = Date.today().addDays(-365);
        ent1.EndDate = Date.today().addDays(365);
        ent1.Type ='Phone';
        ent1.Renewal_Category__c= null;
        //ent.Terminated_Date__c= null;
        ent1.Order_Service_Item__c= oritem1.Id;
        ent1.ServiceContractId= objContract.Id;
        ent1.ContractLineItemId= obhContractLine.Id;
        ent1.RecordTypeId=recordTypeEntId;
        entList.add(ent1);

        setTriggerSwitch('Entitlement', false);
        Entitlement ent2 = new Entitlement();
        ent2.Name= 'Test Entitlement2';
        ent2.AccountId = testAcc.Id;
        ent2.Product__c = prodList[2].Id;
        ent2.AssetId= asset.Id;
        ent2.StartDate = Date.today().addDays(-365);
        ent2.EndDate = Date.today();
        ent2.Type ='Phone';
        ent2.Renewal_Category__c= '';
        //ent.Terminated_Date__c= null;
        ent2.Order_Service_Item__c= oritem1.Id;
        ent2.ServiceContractId= objContract.Id;
        ent2.ContractLineItemId= obhContractLine.Id;
        ent2.RecordTypeId=recordTypeEntId;
        entList.add(ent2);
        
        INSERT entList;

        //Creating conversion opportuntiy and quote
        Opportunity convertOpp = new Opportunity();
        convertOpp.AccountId = testAcc.Id;
        convertOpp.CloseDate = Date.today()+1;
        convertOpp.Deal_Registration_Type__c = 'Rubrik Sourced';
        convertOpp.LeadSource = 'Referral';
        convertOpp.Polaris_Portal_Contact__c = createCon.Id;
        //convertOpp.Initial_Contacts_Name__c = createCon.Id;
        convertOpp.Name = 'CDK - Oracle'; 
        convertOpp.StageName = '1 Discovery';
        convertOpp.Opportunity_Sub_Type__c = 'Regular';
        convertOpp.Opportunity_Type__c = 'Existing Customer';
        convertOpp.Aspen_Eligibility__c = 'Proposed Aspen';
        convertOpp.Pricebook2Id = customPB.Id;
        convertOpp.Partner_Lookup__c = null;
        convertOpp.MSP_End_User_Lookup__c = null;
        insert convertOpp;
        
        SBQQ__Quote__c convertQuote = new SBQQ__Quote__c();
        convertQuote.SBQQ__Account__c = testAcc.Id;
        convertQuote.SBQQ__Opportunity2__c = convertOpp.Id;
        convertQuote.SBQQ__Type__c = 'Quote';
        quote.RCDMT_EOL_Date__c = System.today()+365;
        convertQuote.SBQQ__PriceBook__c = customPB.Id;
        convertQuote.RCDMT_EOL_Date__c = System.today()+365;
        convertQuote.RWD_Deal_Ops_Exception__c = 'RCDM-T - Adding sku to transitioned account';
        convertQuote.RWD_Deal_Ops_Exception_Justification__c = 'test';
        convertQuote.RWD_Sales_Rep_Exception__c = 'Exception for On-Prem Quoting';
        convertQuote.RWD_Sales_Rep_Exception_Justification__c = 'testtttttttttttttt ugfkjdflkhhhhhhhhhhhh';
        insert convertQuote;
        
        SBQQ__Quote__c convertQuoteR = new SBQQ__Quote__c();
        convertQuoteR.SBQQ__Account__c = testAcc.Id;
        convertQuoteR.SBQQ__Opportunity2__c = convertOpp.Id;
        convertQuoteR.SBQQ__Type__c = 'Renewal+Expansion';
        quote.RCDMT_EOL_Date__c = System.today()+365;
        convertQuoteR.SBQQ__PriceBook__c = customPB.Id;
        convertQuoteR.RCDMT_EOL_Date__c = System.today()+365;
        //convertQuote.Eligible_for_RCDM_T__c = true;
        convertQuoteR.RWD_Deal_Ops_Exception__c = 'RCDM-T - Adding sku to transitioned account';
        convertQuoteR.RWD_Deal_Ops_Exception_Justification__c = 'test';
        convertQuoteR.RWD_Sales_Rep_Exception__c = 'Exception for On-Prem Quoting';
        convertQuoteR.RWD_Sales_Rep_Exception_Justification__c = 'testtttttttttttttt ugfkjdflkhhhhhhhhhhhh';
        insert convertQuoteR;
        
        SBQQ__QuoteLineGroup__c conversionQuoteGroupRen = new SBQQ__QuoteLineGroup__c(Name='Renewal Quote', SBQQ__Number__c= 2, 
            SBQQ__ListTotal__c= 100, SBQQ__CustomerTotal__c= 100,
            SBQQ__NetTotal__c= 200, SBQQ__Quote__c= convertQuoteR.Id);
        insert conversionQuoteGroupRen;
        SBQQ__QuoteLineGroup__c conversionQuoteGroupExp = new SBQQ__QuoteLineGroup__c(Name='Expansion Quote', SBQQ__Number__c= 2, 
            SBQQ__ListTotal__c= 100, SBQQ__CustomerTotal__c= 100,
            SBQQ__NetTotal__c= 200, SBQQ__Quote__c= convertQuoteR.Id);
        insert conversionQuoteGroupExp;

        List<Product2> convProdList = new List<Product2>();
        Product2 objProd1 = new Product2();
        objProd1.Name = 'RS-BT-EE-PE-PP';
        objProd1.Description = 'testtest';
        objProd1.ProductCode = 'RS-BT-EE-PE-PP';
        objProd1.Product_Type__c = 'Enterprise Edition';
        objProd1.License_Type__c = 'Subscription';
        objProd1.Family = 'Rubrik Licence';
        objProd1.Product_NIC_Type__c = '';
        objProd1.Support_Type__c = 'Premium';
        objProd1.Support_Tier__c = '';
        objProd1.Category__c = 'Bundle';
        objProd1.Product_Level__c = 'Hybrid Software';
        objProd1.Eligible_for_RCDM_T__c = true;
        objProd1.X0__c = true;
        objProd1.IsActive = True;
        //insert objProd1;
        convProdList.add(objProd1);
        
        Product2 objProd2 = new Product2();
        objProd2.Name = 'RH-6412SE-01';
        objProd2.Description = 'testtest';
        objProd2.ProductCode = 'RH-6412SE-01';
        objProd2.Product_Type__c = 'Hardware';
        objProd2.License_Type__c = '';
        objProd2.Family = 'R6000';
        objProd2.Product_NIC_Type__c = 'SFP+';
        objProd2.Support_Type__c = '';
        objProd2.Support_Tier__c = '';
        objProd2.Usable_Capacity__c = 90.0;
        objProd2.Capacity__c = '144TB';
        objProd2.RWD_Version__c = 'v21.0';
        objProd2.Category__c = 'Hardware';
        objProd2.Product_Level__c = 'Hardware';
        objProd2.IsActive = True;
        //insert objProd2; 
        convProdList.add(objProd2);
        
        Product2 objProd3 = new Product2();
        objProd3.Name = 'RS-HW-SVC-PE-SE1';
        objProd3.Description = 'testtest';
        objProd3.ProductCode = 'RS-HW-SVC-PE-SE1';
        objProd3.Product_Type__c = 'HW Support';
        objProd3.License_Type__c = '';
        objProd3.Support_Type__c = 'Premium';
        objProd3.Family = 'Support';
        objProd3.Product_NIC_Type__c = '';
        objProd3.Support_Tier__c = 'SE1';
        objProd3.Category__c = 'Support';
        objProd3.IsActive = True;
        objProd3.Product_Level__c = 'Support';
        //insert objProd3;
        convProdList.add(objProd3);
        insert convProdList;
        
        List<PricebookEntry> pbConvEntryList = new List<PricebookEntry>();
        
        PricebookEntry conEntry1 = new PricebookEntry();
        conEntry1.Product2Id = convProdList[0].Id;
        conEntry1.UnitPrice = 10;
        conEntry1.Pricebook2Id = Test.getStandardPricebookId();
        conEntry1.IsActive = true;
        //insert conEntry1;
        pbConvEntryList.add(conEntry1);
        
        PricebookEntry conEntry2 = new PricebookEntry();
        conEntry2.Product2Id = convProdList[1].Id;
        conEntry2.UnitPrice = 10;
        conEntry2.Pricebook2Id = Test.getStandardPricebookId();
        conEntry2.IsActive = true;
        //insert conEntry2;
        pbConvEntryList.add(conEntry2);
        
        PricebookEntry conEntry3 = new PricebookEntry();
        conEntry3.Product2Id = convProdList[2].Id;
        conEntry3.UnitPrice = 10;
        conEntry3.Pricebook2Id = Test.getStandardPricebookId();
        conEntry3.IsActive = true;
        //insert conEntry3;
        pbConvEntryList.add(conEntry3);
        
        PricebookEntry conEntry4 = new PricebookEntry();
        conEntry4.Product2Id = convProdList[0].Id;
        conEntry4.UnitPrice = 10;
        conEntry4.Pricebook2id = customPB.Id;
        conEntry4.IsActive = true;
        //insert conEntry4;
        pbConvEntryList.add(conEntry4);
        
        PricebookEntry conEntry5 = new PricebookEntry();
        conEntry5.Product2Id = convProdList[1].Id;
        conEntry5.UnitPrice = 10;
        conEntry5.Pricebook2id = customPB.Id;
        conEntry5.IsActive = true;
        //insert conEntry5;
        pbConvEntryList.add(conEntry5);
        
        PricebookEntry conEntry6 = new PricebookEntry();
        conEntry6.Product2Id = convProdList[2].Id;
        conEntry6.UnitPrice = 10;
        conEntry6.Pricebook2id = customPB.Id;
        conEntry6.IsActive = true;
        //insert conEntry4;
        pbConvEntryList.add(conEntry6);
        insert pbConvEntryList;
        
        SBQQ__ProductFeature__c prodSupportFeature1 = new SBQQ__ProductFeature__c();
        prodSupportFeature1.Name = 'Support';
        prodSupportFeature1.SBQQ__ConfiguredSKU__c = convProdList[1].Id;
        prodSupportFeature1.SBQQ__Number__c = 3;
        prodSupportFeature1.SBQQ__Category__c = 'Support';
        insert prodSupportFeature1;
        
        SBQQ__ProductOption__c prodSupportOpt1 = new SBQQ__ProductOption__c();
        prodSupportOpt1.Refresh_Default_Option__c = false;
        prodSupportOpt1.SBQQ__ConfiguredSKU__c = convProdList[1].Id;
        prodSupportOpt1.SBQQ__OptionalSKU__c = convProdList[2].Id;
        prodSupportOpt1.SBQQ__Type__c = 'Related Product';
        prodSupportOpt1.SBQQ__Feature__c = prodSupportFeature1.Id;
        prodSupportOpt1.Support_Type__c = 'Premium';
        prodSupportOpt1.SBQQ__Number__c = 10;
        prodSupportOpt1.Licensing_Model__c = 'Subscription';
        prodSupportOpt1.Rubrik_Suite__c = 'Foundation';
        prodSupportOpt1.Payment_Options__c = 'Prepay';
        insert prodSupportOpt1;

        SBQQ__QuoteLine__c qlcon1 = new SBQQ__QuoteLine__c(Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010, AA165203480097',Product_Type__c = 'Enterprise Edition', Special_Program__c = 'Refresh', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',SBQQ__Quote__c = convertQuoteR.Id, SBQQ__Product__c = objProd1.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(10),Prior_Net_Total__c = 21000);
        insert qlcon1;
        SBQQ__QuoteLine__c qlcon2 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = 'AA165203480094', SubsAstNameInt__c='AA165203480094', Arroyo_Subscribed_Asset_Name__c = null,Product_Type__c = 'Hardware', Special_Program__c = 'Refresh', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',SBQQ__Quote__c = convertQuoteR.Id, SBQQ__Product__c = objProd2.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(10),Prior_Net_Total__c = 21000);
        insert qlcon2;
        // SF-72381 original SBQQ__QuoteLine__c qlcon3 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = 'AA165203480099', SubsAstNameInt__c='AA1652034800941x', Arroyo_Subscribed_Asset_Name__c = null,Product_Type__c = 'HW Support', Special_Program__c = 'Refresh', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',SBQQ__Quote__c = convertQuoteR.Id, SBQQ__Product__c = objProd3.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(10),Prior_Net_Total__c = 21000);
        
        SBQQ__QuoteLine__c qlcon3 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = 'AA165203480099', SubsAstNameInt__c='AA210664120014, AA165203480094'/* SF-72381 'AA1652034800941x'*/, RTAwithoutUplift__c = 2, Arroyo_Subscribed_Asset_Name__c = null,Product_Type__c = 'HW Support', Special_Program__c = 'Refresh', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',SBQQ__Quote__c = convertQuoteR.Id, SBQQ__Product__c = objProd3.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(10),Prior_Net_Total__c = 21000, Prior_Net_Total_With_Uplift__c = 5, PriorACVwithUplift__c = 6, SBQQ__ProratedListPrice__c = 8, SBQQ__Discount__c = 2);
        
        insert qlcon3;
        

        //Custom conversion upgrade source: v1- v2
        List<Custom_Conversion_Upgrade_Source__c> upgradeList = new List<Custom_Conversion_Upgrade_Source__c>();
        Custom_Conversion_Upgrade_Source__c conUpgradeprod1 = new Custom_Conversion_Upgrade_Source__c();
        conUpgradeprod1.Old_Product__c = prodList[0].Id;
        conUpgradeprod1.New_Product__c = convProdList[1].Id;
        conUpgradeprod1.Product_Upgrade_Type__c = 'Hardware';
        //insert conUpgradeprod1;
        upgradeList.add(conUpgradeprod1);
        
        Custom_Conversion_Upgrade_Source__c conUpgradeprod2 = new Custom_Conversion_Upgrade_Source__c();
        conUpgradeprod2.Old_Product__c = prodList[1].Id;
        conUpgradeprod2.New_Product__c = convProdList[2].Id;
        conUpgradeprod2.Product_Upgrade_Type__c = 'Support';
        conUpgradeprod2.Support_Tier__c = 'SE1';
        conUpgradeprod2.Support_Type__c = 'Premium';
        //insert conUpgradeprod2;
        upgradeList.add(conUpgradeprod2);
        
        Custom_Conversion_Upgrade_Source__c conUpgradeprod4 = new Custom_Conversion_Upgrade_Source__c();
        conUpgradeprod4.Old_Product__c = prodList[1].Id;
        conUpgradeprod4.New_Product__c = convProdList[1].Id;
        conUpgradeprod4.Product_Upgrade_Type__c = 'Support';
        //insert conUpgradeprod1;
        upgradeList.add(conUpgradeprod4);

        Custom_Conversion_Upgrade_Source__c conUpgradeprod3 = new Custom_Conversion_Upgrade_Source__c();
        conUpgradeprod3.Edition__c = 'Enterprise';
        conUpgradeprod3.Payment_Option__c = 'Prepay';
        conUpgradeprod3.License_Type__c = 'SaaS';
        conUpgradeprod3.Support_Type__c = 'Premium';
        conUpgradeprod3.Program__c = 'Convert';
        conUpgradeprod3.Saas_SKU__c = convProdList[0].Id;
        //insert conUpgradeprod3;
        upgradeList.add(conUpgradeprod3);
        insert upgradeList;
        
        //Covering Renewal Scenario 
        Product2 prodRen = new Product2(
            Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
            ProductCode = 'RBK-SVC-PREM-R304',
            isActive = true,
            SBQQ__SubscriptionTerm__c = 1,
            Product_Type__c = 'HW Support'
        );
        insert prodRen;
        Product2 prodRen1 = new Product2(
            Name = 'RBK-NRD-R6000F',
            ProductCode = 'RBK-NRD-R6000F',
            isActive = true,
            SBQQ__SubscriptionTerm__c = 1,
            Product_Type__c = 'HW Support'
        );
        insert prodRen1;
        Product2 subProd = new Product2(
            Name = 'Subscription',
            ProductCode = 'RS-BT-RCDM-T',
            isActive = true,
            SBQQ__SubscriptionTerm__c = 12
        );
        insert subProd;
        
        PricebookEntry pbStanEntry2 = new PricebookEntry();
        pbStanEntry2.Pricebook2Id = Test.getStandardPricebookId();
        pbStanEntry2.Product2Id = prodRen.Id;
        pbStanEntry2.UnitPrice = 1000.00;
        pbStanEntry2.IsActive = true;
        insert pbStanEntry2;

        PricebookEntry pbStanEntry3 = new PricebookEntry();
        pbStanEntry3.Pricebook2Id = Test.getStandardPricebookId();
        pbStanEntry3.Product2Id = prodRen1.Id;
        pbStanEntry3.UnitPrice = 1000.00;
        pbStanEntry3.IsActive = true;
        insert pbStanEntry3;
        
        PricebookEntry pbStanEntry4 = new PricebookEntry();
        pbStanEntry4.Pricebook2Id = Test.getStandardPricebookId();
        pbStanEntry4.Product2Id = subProd.Id;
        pbStanEntry4.UnitPrice = 1000.00;
        pbStanEntry4.IsActive = true;
        insert pbStanEntry4;

        SBQQ__Quote__c qt1 = new SBQQ__Quote__c();
        qt1.SBQQ__Account__c = testAcc.Id;
        qt1.SBQQ__Opportunity2__c = opp.Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__PriceBook__c = Test.getStandardPricebookId();
        qt1.SBQQ__Status__c = 'Draft';
        qt1.SBQQ__Type__c = 'Renewal+Expansion';
        qt1.RCDMT_EOL_Date__c = System.today()+365;
        qt1.SBQQ__StartDate__c = Date.today();
        qt1.Manual_Billing__c = false;
        qt1.Consolidate_Lines__c = false;
        //quote.Is_Federal_Eligible_Quote__c = 'True';    
        insert qt1;        
        
        SBQQ__QuoteLine__c ql3 = new SBQQ__QuoteLine__c(Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010, AA165203480097',Product_Type__c = 'HW Support', Special_Program__c = 'Refresh', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prodRen.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(10),Prior_Net_Total__c = 21000);
        insert ql3;
        SBQQ__QuoteLine__c ql4 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = 'AA165203480094', SubsAstNameInt__c='AA165203480094', Arroyo_Subscribed_Asset_Name__c = 'AA165203480094',Product_Type__c = 'HW Support', Special_Program__c = 'Refresh', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prodRen1.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(10),Prior_Net_Total__c = 21000);
        insert ql4;
        SBQQ__QuoteLine__c ql11 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = 'AA165203480099', SubsAstNameInt__c='AA1652034800942x', Arroyo_Subscribed_Asset_Name__c = 'AA165203480094',Product_Type__c = 'HW Support', Special_Program__c = 'Refresh', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prodRen1.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(10),Prior_Net_Total__c = 21000);
        insert ql11;
        SBQQ__QuoteLine__c ql5 = new SBQQ__QuoteLine__c(Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010, AA165203480097',Product_Type__c = 'HW Support', Special_Program__c = 'Refresh', Sales_Comp_Category__c = 'HW SUPPORT', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prodRen.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(10),Prior_Net_Total__c = 21000);
        insert ql5;
        SBQQ__QuoteLine__c ql6 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = null, SubsAstNameInt__c='AA165203480094', Arroyo_Subscribed_Asset_Name__c = 'AA165203480094',Product_Type__c = 'HW Support', Special_Program__c = 'Refresh', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prodRen1.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(10),Prior_Net_Total__c = 21000);
        insert ql6;
        SBQQ__QuoteLine__c ql7 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = null, SubsAstNameInt__c='AA165203480094', Arroyo_Subscribed_Asset_Name__c = 'AA165203480094',Product_Type__c = 'HW Support', Special_Program__c = 'Refresh', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prodRen.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(10),Prior_Net_Total__c = 21000);
        insert ql7;
        SBQQ__QuoteLine__c ql8 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = null, SubsAstNameInt__c='AA165203480094', Arroyo_Subscribed_Asset_Name__c = 'AA165203480094',Product_Type__c = 'HW Support', Special_Program__c = 'Refresh', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prodRen.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(10),Prior_Net_Total__c = 21000);
        insert ql8;
        SBQQ__QuoteLine__c ql9 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = null, SubsAstNameInt__c='AA165203480096', Arroyo_Subscribed_Asset_Name__c = 'AA165203480094',Product_Type__c = 'HW Support', Special_Program__c = 'Conversion', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',SBQQ__Quote__c = convertQuoteR.Id, SBQQ__Product__c = prodRen.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(10),Prior_Net_Total__c = 21000);
        insert ql9;
        SBQQ__QuoteLine__c qliNewH = new SBQQ__QuoteLine__c(SBQQ__Quote__c=qt1.Id, SBQQ__Product__c=prodRen.Id, SBQQ__Number__c=4, 
                                                            Disposition_Reason__c='None', SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__Quantity__c=1, Product_Type__c = 'Hardware'); 
        qliNewH.SBQQ__Existing__c = true;
        insert qliNewH;
        
        SBQQ__QuoteLineGroup__c qlGroup1 = new SBQQ__QuoteLineGroup__c(Name='Renewal Quote', SBQQ__Number__c= 2, 
            SBQQ__ListTotal__c= 100, SBQQ__CustomerTotal__c= 100,
            SBQQ__NetTotal__c= 200, SBQQ__Quote__c= qt1.Id);
        insert qlGroup1;

        List<ServiceContract> lstServiceContract = new List<ServiceContract>();
        ServiceContract serviceContractObj = new ServiceContract();
        serviceContractObj.Name = 'EntitlementTriggerHelper Contract';
        serviceContractObj.SBQQSC__Opportunity__c = opp.Id;
        serviceContractObj.AccountId = testAcc.Id;
        serviceContractObj.StartDate = Date.Today().addmonths(-30);
        serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj.Term = 36;
        serviceContractObj.SBQQSC__RenewalOpportunity__c = opp.Id;
        serviceContractObj.EndDate = System.today().addDays(360);
        serviceContractObj.SBQQSC__RenewalForecast__c = false;
        //insert serviceContractObj;
        lstServiceContract.add(serviceContractObj);
                
        ServiceContract renewServiceContractObj = new ServiceContract();
        renewServiceContractObj.Name = 'EntitlementTriggerHelper Contract';
        renewServiceContractObj.SBQQSC__Opportunity__c = opp.Id;
        renewServiceContractObj.AccountId = testAcc.Id;
        renewServiceContractObj.StartDate = System.today();
        renewServiceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        renewServiceContractObj.Term = 36;
        renewServiceContractObj.SBQQSC__Quote__c = qt1.Id;
        renewServiceContractObj.EndDate = System.today().addDays(360);
        //insert renewServiceContractObj
        lstServiceContract.add(renewServiceContractObj);
        insert lstServiceContract; 
        

        Asset newAsset1 = new Asset(Name = 'AA165203480094', SerialNumber = 'AA165203480094', Product2Id = prodRen.Id, AccountId = testAcc.Id, SBQQ__CombineKey__c = 'AA165203480094');
        insert newAsset1;
        
        //SF-72381 start
        
        List<SBQQ__Quote__c> qtlst = new List<SBQQ__Quote__c>();

        SBQQ__Quote__c qtx = new SBQQ__Quote__c();
        qtx.SBQQ__Account__c = testAcc.Id;
        qtx.SBQQ__Opportunity2__c = opp.Id;
        qtx.SBQQ__Primary__c = true;
        qtx.SBQQ__PriceBook__c = Test.getStandardPricebookId();
        qtx.SBQQ__Status__c = 'Draft';
        qtx.SBQQ__Type__c = 'Renewal+Expansion';
        qtx.RCDMT_EOL_Date__c = System.today()+365;
        qtx.SBQQ__StartDate__c = Date.today();
        qtx.Manual_Billing__c = false;
        qtx.Consolidate_Lines__c = false;
        qtx.Original_Quote_Names__c = 'tst121';
            
        qtlst.add(qtx);
        insert qtlst;   


        List<SBQQ__QuoteLine__c> qlinexst = new List<SBQQ__QuoteLine__c>();
        
        SBQQ__QuoteLine__c qliNewHx = new SBQQ__QuoteLine__c(SBQQ__Quote__c=qtx.Id, SBQQ__Product__c=prodRen.Id, SBQQ__Number__c=4, 
                                                                    SBQQ__Existing__c = false, SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__Quantity__c=1, Product_Type__c = 'Hardware',Arroyo_Subscribed_Asset_Name__c = 'AA16440345555'); 
        
        SBQQ__QuoteLine__c qlx1 = new SBQQ__QuoteLine__c(Arroyo_Subscribed_Asset_Name__c = null,Product_Type__c = 'HW Support', Special_Program__c = 'Refresh', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',SBQQ__Quote__c = qtx.Id, SBQQ__Product__c = prodRen1.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(10),Prior_Net_Total__c = 21001,SubscribedAssetNames__c = 'AA16440345555');
        
        
        //esle case
        SBQQ__QuoteLine__c qliNewHx2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=qtx.Id, SBQQ__Product__c=prodRen.Id, SBQQ__Number__c=4, 
                                                            Disposition_Reason__c='None', SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__Quantity__c=1, Product_Type__c = 'Hardware',Arroyo_Subscribed_Asset_Name__c = 'AA16440345555'); 

        SBQQ__QuoteLine__c qlx12 = new SBQQ__QuoteLine__c(Arroyo_Subscribed_Asset_Name__c = null,Product_Type__c = 'HW Support', Special_Program__c = 'Refresh', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',SBQQ__Quote__c = qtx.Id, SBQQ__Product__c = prodRen.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(10),Prior_Net_Total__c = 21002,SubscribedAssetNames__c = 'AA16440345555');
        
        
        //if else if 
        SBQQ__QuoteLine__c qliNewHx3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=qtx.Id, SBQQ__Product__c=prodRen.Id, SBQQ__Number__c=4, 
                                                            Disposition_Reason__c='None', SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__Quantity__c=1, Product_Type__c = 'Hardware',Arroyo_Subscribed_Asset_Name__c = 'AA16440345555'); 

        SBQQ__QuoteLine__c qlx13 = new SBQQ__QuoteLine__c(Arroyo_Subscribed_Asset_Name__c = null,Product_Type__c = 'HW Support', Special_Program__c = 'Refresh', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',SBQQ__Quote__c = qtx.Id, SBQQ__Product__c = prodRen1.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(10),Prior_Net_Total__c = 21003,SubscribedAssetNames__c = null,SubsAstNameInt__c = 'AA16440345555');
        
                SBQQ__QuoteLine__c qlx14 = new SBQQ__QuoteLine__c(Arroyo_Subscribed_Asset_Name__c = null,Product_Type__c = 'HW Support', Special_Program__c = 'Refresh', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',SBQQ__Quote__c = qtx.Id, SBQQ__Product__c = prodRen.Id, SBQQ__Quantity__c = 334, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(10),Prior_Net_Total__c = 21004,SubscribedAssetNames__c = null,SubsAstNameInt__c = 'AA16440345555');

        SBQQ__QuoteLine__c qlx15 = new SBQQ__QuoteLine__c(Arroyo_Subscribed_Asset_Name__c = null,Product_Type__c = 'HW Support', Special_Program__c = 'Refresh', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',SBQQ__Quote__c = qtx.Id, SBQQ__Product__c = prodRen.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(10),Prior_Net_Total__c = 21005,SubscribedAssetNames__c = null,SubsAstNameInt__c = 'AA16440345555',SBQQ__Existing__c = true);
        
        qlinexst.add(qliNewHx);        
        qlinexst.add(qlx1);
        qlinexst.add(qliNewHx2);        
        qlinexst.add(qlx12);
        qlinexst.add(qliNewHx3);        
        qlinexst.add(qlx13);
        qlinexst.add(qlx14);
        qlinexst.add(qlx15);
        insert qlinexst;
        
        qlx1.SBQQ__RequiredBy__c = qlx15.Id;
        update qlx1;
        SBQQ.TriggerControl.enable();
    }   
    
    /*Method to test the conversion functionality*/
    @isTest
    public static void assetConvert(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser;

        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        List<SBQQ__QuoteLine__c> quoteLineList = new List<SBQQ__QuoteLine__c>();

        SBQQ__Quote__c quoteCon = [SELECT Id,
                                SBQQ__Account__c 
                                FROM SBQQ__Quote__c
                                WHERE SBQQ__Opportunity2__r.Name = 'CDK - Oracle' LIMIT 1];
        quoteList.add(quoteCon);
        Assert.areEqual(1, quoteList.size());
        
     
        SBQQ__QuoteLineGroup__c qlGroup1 = new SBQQ__QuoteLineGroup__c(Name='Renewal Quote', SBQQ__Number__c= 2, 
            SBQQ__ListTotal__c= 100, SBQQ__CustomerTotal__c= 100,
            SBQQ__NetTotal__c= 200, SBQQ__Quote__c= quoteCon.Id);
        insert qlGroup1;
        SBQQ__QuoteLineGroup__c conversionQuoteGroupExp = new SBQQ__QuoteLineGroup__c(Name='Expansion Quote', SBQQ__Number__c= 2, 
            SBQQ__ListTotal__c= 100, SBQQ__CustomerTotal__c= 100,
            SBQQ__NetTotal__c= 200, SBQQ__Quote__c= quoteCon.Id);
        insert conversionQuoteGroupExp;

        SBQQ__Quote__c quoteR = [SELECT Id,
                                SBQQ__Account__c 
                                FROM SBQQ__Quote__c
                                WHERE SBQQ__Opportunity2__r.Name = 'Test01' LIMIT 1];

        quoteList.add(quoteR);

        quoteLineList = [Select Id, Quote_Line_Type__c, Product_Type__c, Arroyo_Subscribed_Asset_Name__c 
                        from SBQQ__QuoteLine__c 
                        Where SBQQ__Quote__c =: quoteR.Id];
        
        Test.startTest();
        PageReference pgRef1 = Page.ConvertAssetPage;
        Test.setCurrentPage(pgRef1);             
        ApexPages.currentPage().getParameters().put('newid', quoteCon.id);
        
        System.runAs(listUser[0]) {
            ConvertAssetController  testConvertAssetController = new ConvertAssetController();
            testConvertAssetController.strSearchAsset = 'AA165203480094';
            
            List<ConvertAssetController.AssetWrapper>lstWrapperAssets1 = testConvertAssetController.lstWrapperAssets;
            for(ConvertAssetController.AssetWrapper objAssetWrapper : lstWrapperAssets1){
                objAssetWrapper.selected = true;
                objAssetWrapper.asset.Rubrik_Suite__c = 'Enterprise';
                objAssetWrapper.asset.Payment_Options__c = 'Prepay';
                objAssetWrapper.asset.Support_Type__c = 'Premium';
                objAssetWrapper.licenseType = 'SaaS';
                objAssetWrapper.assetGroup = 'test';//SF-72381
                objAssetWrapper.conversionError = 'test';//SF-72381
                
            }
            testConvertAssetController.lstWrapperAssets = lstWrapperAssets1;
            testConvertAssetController.fetchConversionProducts();
            testConvertAssetController.getShowAssetEndDate();
            testConvertAssetController.clearSearch();
            testConvertAssetController.cancelAndReturn();
            SBQQ.TriggerControl.disable();
            testConvertAssetController.convertAssets();
            ConvertAssetController.updateDispositionReasonsNew(quoteR.Id, quoteLineList);
            SBQQ.TriggerControl.enable();
            testConvertAssetController.cancelAndBack();
            Test.StopTest();
        }
    }
    @isTest
    public static void assetConvertTEST(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser;

        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        List<SBQQ__QuoteLine__c> quoteLineList = new List<SBQQ__QuoteLine__c>();

        SBQQ__Quote__c quoteCon = [SELECT Id,
                                SBQQ__Account__c 
                                FROM SBQQ__Quote__c
                                WHERE SBQQ__Opportunity2__r.Name = 'CDK - Oracle' 
                                AND SBQQ__Type__c = 'Renewal+Expansion' LIMIT 1];
        quoteList.add(quoteCon);
        Assert.areEqual(1, quoteList.size());

        SBQQ__QuoteLineGroup__c qlGroup1 = new SBQQ__QuoteLineGroup__c(Name='Renewal Quote', SBQQ__Number__c= 2, 
            SBQQ__ListTotal__c= 100, SBQQ__CustomerTotal__c= 100,
            SBQQ__NetTotal__c= 200, SBQQ__Quote__c= quoteCon.Id);
        insert qlGroup1;
        SBQQ__QuoteLineGroup__c conversionQuoteGroupExp = new SBQQ__QuoteLineGroup__c(Name='Renewal Quote', SBQQ__Number__c= 2, 
            SBQQ__ListTotal__c= 100, SBQQ__CustomerTotal__c= 100,
            SBQQ__NetTotal__c= 200, SBQQ__Quote__c= quoteCon.Id);
        insert conversionQuoteGroupExp;

        SBQQ__Quote__c quoteR = [SELECT Id,
                                SBQQ__Account__c 
                                FROM SBQQ__Quote__c
                                WHERE SBQQ__Opportunity2__r.Name = 'Test01' LIMIT 1];

        quoteList.add(quoteR);

        quoteLineList = [Select Id, Quote_Line_Type__c, Product_Type__c, Arroyo_Subscribed_Asset_Name__c 
                        from SBQQ__QuoteLine__c 
                        Where SBQQ__Quote__c =: quoteCon.Id];
        
        Test.startTest();
        PageReference pgRef1 = Page.ConvertAssetPage;
        Test.setCurrentPage(pgRef1);             
        ApexPages.currentPage().getParameters().put('newid', quoteCon.id);
        System.runAs(listUser[0]) {
            ConvertAssetController  testConvertAssetController = new ConvertAssetController();
            testConvertAssetController.strSearchAsset = 'AA165203480094';
            
            List<ConvertAssetController.AssetWrapper>lstWrapperAssets1 = testConvertAssetController.lstWrapperAssets;
            for(ConvertAssetController.AssetWrapper objAssetWrapper : lstWrapperAssets1){
                objAssetWrapper.selected = true;
                objAssetWrapper.asset.Rubrik_Suite__c = 'Enterprise';
                objAssetWrapper.asset.Payment_Options__c = 'Prepay';
                objAssetWrapper.asset.Support_Type__c = 'Premium';
                objAssetWrapper.licenseType = 'SaaS';
            }
            testConvertAssetController.lstWrapperAssets = lstWrapperAssets1;
            testConvertAssetController.fetchConversionProducts();
            testConvertAssetController.getShowAssetEndDate();
            testConvertAssetController.clearSearch();
            testConvertAssetController.cancelAndReturn();
            SBQQ.TriggerControl.disable();
            testConvertAssetController.convertAssets();
            //ConvertAssetController.updateDispositionReasonsNew(quoteCon.Id, quoteLineList);
            SBQQ.TriggerControl.enable();
            testConvertAssetController.cancelAndBack();
            Test.StopTest();
        }
    }
    
    @isTest
    public static void assetConvert3(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser;

        Id quoteId = null;
        Assert.areEqual(null, quoteId);
        Test.startTest();
        PageReference pgRef1 = Page.ConvertAssetPage;
        Test.setCurrentPage(pgRef1);             
        ApexPages.currentPage().getParameters().put('newid', quoteId);
        
        System.runAs(listUser[0]) {
            ConvertAssetController  testConvertAssetController = new ConvertAssetController();
            testConvertAssetController.strSearchAsset = 'AA165203480094';//'AA210664120014';
        Test.StopTest();
       }
    }
    
    /**
    * @description  : assetConvert4 - //SF-72381
    */
    @isTest
    public static void assetConvert4(){
    
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser;
        System.runAs(listUser[0]) {
    
    List<SBQQ__QuoteLine__c> quoteLineList = new List<SBQQ__QuoteLine__c>();
    List<SBQQ__QuoteLine__c> qLExistingList = new List<SBQQ__QuoteLine__c>();
    List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();

    SBQQ__Quote__c quoteR = [SELECT Id,
                                SBQQ__Account__c 
                                FROM SBQQ__Quote__c
                                WHERE Original_Quote_Names__c = 'tst121' LIMIT 1];
    quoteList.add(quoteR);


    quoteLineList = [Select Id, Quote_Line_Type__c, Product_Type__c, Arroyo_Subscribed_Asset_Name__c 
                        from SBQQ__QuoteLine__c 
                        Where SBQQ__Quote__c =: quoteR.Id];
     
    
    ConvertAssetController.updateDispositionReasonsNew(quoteR.Id, quoteLineList);
    qLExistingList = [Select Id, Quote_Line_Type__c,SBQQ__RequiredBy__c, Product_Type__c, Arroyo_Subscribed_Asset_Name__c 
                        from SBQQ__QuoteLine__c 
                        Where SBQQ__Quote__c =: quoteR.Id ];
    ConvertAssetController.updateDispositionReasonsNew(quoteR.Id, qLExistingList);
    //ConvertAssetController st = new ConvertAssetController();
    ConvertAssetController.AssetWrapper sft = new ConvertAssetController.AssetWrapper(); //SF-72381
    Assert.areEqual(1, quoteList.size());
        }
    } 
}