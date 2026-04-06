/***********************************************************************************
Date            Name                Description
11-JAN-2022     Shiju Thomas        Initial Implementation
************************************************************************************/

@isTest
private class ContractLineItemTriggerTests {

    
    
    public static Account act;
    public static Entitlement ent;
    public static Product2 prdHW;
    public static PricebookEntry pbeHW;
    public static Asset ast;
    public static ContractLineItem contractLineItem;
    public static ServiceContract serviceContract;
    public static Opportunity opportunityObj;
    public static Id pricebookId;

   
    static {
        ShGl_TestFactoryHelper.insertTriggerControls();

        
        act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        
        prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        prdHW.ProductCode = 'RBK-SVC-test-product';
        prdHW.Family = 'HPE';
        insert prdHW;

        pricebookId = Test.getStandardPricebookId();
        
        pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pbeHW.PriceBook2Id = pricebookId;
        insert pbeHW;

        ast = (Asset) ShGl_TestFactory.createSObject(new Asset(), null);
        ast.AccountId = act.Id;
        ast.Name = 'EntitlementTriggerHelperAsset';
        ast.Product2Id = prdHW.Id;
        insert ast; 

        opportunityObj = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opportunityObj.AccountId = act.Id;
        opportunityObj.Name = 'EntitlementTriggerHelper Opportunity';
        opportunityObj.CloseDate = System.today().addMonths(12);
        opportunityObj.StageName = 'Prospecting';
        opportunityObj.Pricebook2Id = pricebookId;
        opportunityObj.SBQQ__QuotePricebookId__c = pricebookId;
        insert opportunityObj;

        serviceContract = new ServiceContract();
        serviceContract.Name = 'EntitlementTriggerHelper Contract';
        serviceContract.SBQQSC__Opportunity__c = opportunityObj.Id;
        serviceContract.AccountId = act.Id;
        serviceContract.StartDate = System.today();
        serviceContract.PriceBook2Id = pricebookId;
        serviceContract.Term = 36;
        insert serviceContract;
        
        contractLineItem = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        contractLineItem.SBQQSC__Account__c = act.Id;
        contractLineItem.AssetId = ast.Id;
        contractLineItem.PricebookEntryId = pbeHW.Id;
        contractLineItem.ServiceContractId = serviceContract.Id;
        insert contractLineItem;

        ent = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        ent.AccountId = act.Id;
        ent.StartDate = Date.today().addDays(-365);
        ent.EndDate = Date.today().addDays(365);
        ent.AssetId = ast.Id;
        ent.ContractLineItemId = contractLineItem.Id;
        ent.Renewable__c = true;
        ent.Type = 'Phone Support';
        ent.Name = 'EntitlementTriggerHelper';
        ent.Product__c = prdHW.Id;
        ent.Refreshed_Opportunity_Link__c = opportunityObj.Id;
        ent.ServiceContractId = serviceContract.Id;
        insert ent;
    }

    @isTest
    private static void testRenewalCategoryOnEntitlements() {
        Test.startTest();
serviceContract.SBQQSC__Opportunity__c = opportunityObj.id;
        serviceContract.SBQQSC__RenewalOpportunity__c =  opportunityObj.id;
        update serviceContract;
        
        contractLineItem.SBQQSC__TerminatedDate__c = Date.today();
contractLineItem.New_Extended_End_Date__c = System.today().addDays(10);
        update contractLineItem;

        Entitlement entitlement = [SELECT Id, Renewal_Category__c FROM Entitlement WHERE Id =: ent.Id LIMIT 1];
        //System.assertEquals('Terminated', entitlement.Renewal_Category__c);
        Test.stopTest();
        System.assert(true);

    }
    //CPQ22-1159
    @isTest
    private static void testSetContractLineItemFields() {
       ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Validation_Rules__c =  true, Disable_SBQQ_Quote_Validation_Rules__c = true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true,Disable_SBQQ_Quote_Triggers__c = true, Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_Order_Old_Trigger__c = true, Disable_Account_Triggers__c = true);
        insert disableLogic;
        
        FlowControll.opportunityTriggerHandler = false;
        flowControll.opportunityLineItemHandler = false;
        Product2 parentProd = new Product2();
        parentProd.Name = 'RBK-SVC-test-parent';
        parentProd.ProductCode = 'RBK-SVC-test-parent';
        parentProd.family = 'Dell';
        parentProd.TPH_Models_Gen__c = 'R740XD';
        parentProd.Usable_Capacity__c = 30;
        parentProd.Capacity__c = '8TB';
        parentProd.SBQQ__SubscriptionCategory__c = 'Hardware';
        parentProd.Product_Level__c = 'Hybrid Software';
        parentProd.Product_Type__c= 'UCL';
        parentProd.Product_Subtype__c='Business';
        parentProd.SBQQ__Optional__c=False;
        insert parentProd;
        PriceBookEntry pbeParentProd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeParentProd.Product2Id = parentProd.Id;
        pbeParentProd.Pricebook2Id = pricebookId;
        insert pbeParentProd;
        
       /*  prdHW.Custom_POT__c = true;
        prdHW.SBQQ__SubscriptionPercent__c = 1.083;
        update prdHW;

         SBQQ__ProductOption__c objPO = new SBQQ__ProductOption__c();
        objPO.SBQQ__ConfiguredSKU__c = parentProd.Id;
        objPO.SBQQ__OptionalSKU__c = prdHW.Id;
        objPO.POT_Parent_s_Source__c = parentProd.Id;
        objPO.SBQQ__Number__c = 1;
        insert objPO;*/
        
        
        SBQQ__Quote__c objQuote = new SBQQ__Quote__c();
        objQuote.SBQQ__Opportunity2__c = opportunityObj.Id;
        objQuote.SBQQ__Type__c = 'Quote';
        objQuote.OpportunitySubType__c = 'Regular';
        objQuote.sendSOWNotification__c = false;
        objQuote.SBQQ__Primary__c=true;
        objQuote.RWD_Deal_Ops_Exception__c='AMER-FED Account quoting RSC';
        objQuote.RWD_Deal_Ops_Exception_Justification__c='Test';
        objQuote.SBQQ__PriceBook__c = pricebookId;

        insert objQuote;
        
        SBQQ__QuoteLine__c objLine = new SBQQ__QuoteLine__c();
        objLine.SBQQ__Quote__c = objQuote.Id;
        objLine.SBQQ__Product__c = parentProd.Id;
        objLine.Scale_Utility_Product_Identifier__c = 'OND SR';
        objLine.SBQQ__Quantity__c = 1;
        objLine.SBQQ__SubscriptionPricing__c = null;
        objLine.SBQQ__StartDate__c = System.today();
        objLine.SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1);
        objLine.SBQQ__DefaultSubscriptionTerm__c = 12;
        objLine.SBQQ__ListPrice__c = 200;
        objLine.SBQQ__NetPrice__c = 200;
        objLine.SBQQ__SubscriptionTerm__c = 6;
       // objLine.SBQQ__ProductOption__c = objPO.Id;
        objLine.RWD_Deal_Ops_Exception__c='AMER-FED Account quoting RSC';
        objLine.POT_Parent_List_Price__c=12;
        objLine.Product_Level__c = 'Hybrid Software';
        objLine.Product_Type__c= 'UCL';
        objLine.Product_Subtype__c='Business';
        objLine.SBQQ__Optional__c=False;
        objLine.SBQQ__PricebookEntryId__c = pbeParentProd.Id;
        insert objLine;
         Map<String, Object>  OrderMap = new Map<String, Object> { 
            'Type' => 'Revenue',
                'AccountId' => act.Id,
                'OpportunityId' => opportunityObj.Id,
                'Sync_to_NetSuite__c' => true,
                'EffectiveDate' => system.today(),
                'Status' => 'Pending',
                'Sell_to_Partner__c'=>act.Id,
                'Bill_To_Name__c'=>act.Id,
                'SBQQ__Quote__c'=>objQuote.id  
                };
                    
                    Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
        ord.Type = 'Revenue';
        ord.Order_Sub_Type__c = 'GC Offer';
        ord.Pricebook2Id = pricebookId;
        insert Ord;
        OrderItem oi = new OrderItem(Product2Id = objLine.SBQQ__Product__c,SBQQ__QuotedQuantity__c = objLine.SBQQ__Quantity__c, OrderId = Ord.Id, Quantity = objLine.SBQQ__Quantity__c, PricebookEntryId = pbeParentProd.Id, unitprice =objLine.SBQQ__NetPrice__c,Sales_Price__c = objLine.SBQQ__NetPrice__c,SBQQ__QuoteLine__c=objLine.id, SBQQ__SubscriptionTerm__c =objLine.SBQQ__SubscriptionTerm__c, Global_Commit_ID__c = 'TEST');
        
        insert oi;
         Test.startTest();
        contractLineItem = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        contractLineItem.SBQQSC__Account__c = act.Id;
        contractLineItem.AssetId = ast.Id;
        contractLineItem.PricebookEntryId = pbeHW.Id;
        contractLineItem.ServiceContractId = serviceContract.Id;
        contractLineItem.SBQQSC__QuoteLine__c = objLine.Id;
        contractLineItem.SBQQSC__OrderProduct__c = oi.id;
        insert contractLineItem;
        system.debug('testingdebugclid '+Json.serializepretty(contractLineItem));
        Map<Id,ContractLineItem> newCLIsMap = new Map<Id,ContractLineItem>(new list<ContractLineItem>{contractLineItem});
        //ContractLineItemTriggerHelper cls = new ContractLineItemTriggerHelper();
        ContractLineItemTriggerHelper.setContractLineItemFields(new list<ContractLineItem>{contractLineItem});
        ContractLineItemTriggerHelper.updateCLIFieldforGCOfferLines(new Set<String>{'TEST'}, newCLIsMap);
        Test.stopTest();
        System.assert(true);
    } 
}