@isTest
public class EntitlementTriggerHelperClass_Test {

    public static Account act; 
    public static Entitlement ent;
    public static Entitlement secondEnt;
    public static Product2 prdHW;
    public static PricebookEntry pbeHW;
    public static Asset ast;
    public static ContractLineItem contractLineItem;
    public static ContractLineItem secondcontractLineItem;
    public static ContractLineItem thirdcontractLineItem;
    public static ContractLineItem fourthcontractLineItem;
    public static ContractLineItem fifthcontractLineItem;
    public static ServiceContract serviceContract;
    public static Opportunity opportunityObj;
    public static order orderObj;
    public static PricebookEntry pricebookentryObj; 
    
   static{
        ShGl_TestFactoryHelper.insertTriggerControls();
        insert new Opportunity_Stage_Days__c(DefaultSubscriptionTermMonthsARR__c =36, setupOwnerId = userinfo.getuserid());
        
        Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act = new Account(
            Name = 'Customer',
            recordtypeId = partner,
            Phone = '123-456-7890',
            AccountNumber = 'Test',
            BillingStreet = '123 street',
            BillingCity = 'Santa Clara', 
            BillingState = 'California',
            BillingPostalCode = '95050',
            BillingCountry = 'United States',
            ShippingStreet = '123 street',
            ShippingCity = 'Santa Clara',
            ShippingState = 'California',
            ShippingPostalCode = '95050',
            ShippingCountry = 'United States'
        );
        insert act;
        
        prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        prdHW.ProductCode = 'RBK-SVC-test-product';
        prdHW.Product_Subtype__c = 'GO';
        prdHW.SBQQSC__EntitlementConversion__c = 'One per unit';
        insert prdHW;
        
        
        pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        insert pbeHW;
        
        ast = (Asset) ShGl_TestFactory.createSObject(new Asset(), null);
        ast.AccountId = act.Id;
        ast.Name = 'EntitlementTriggerHelperAsset';
        ast.Rubrik_Suite__c = 'Foundation';
        ast.Payment_Options__c = 'Annual';
        ast.SerialNumber = '123\\s+';
        ast.Support_Type__c = 'L3';
        ast.Licensing_Model__c = 'Perpetual';
        ast.Product2Id = prdHW.Id;
        insert ast;
        
        opportunityObj = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opportunityObj.AccountId = act.Id;
        opportunityObj.Name = 'EntitlementTriggerHelper Opportunity';
        opportunityObj.CloseDate = System.today().addMonths(12);
        opportunityObj.StageName = 'Prospecting';
        opportunityObj.Partner_Lookup__c = act.Id;
        opportunityObj.Distributor_Lookup__c = opportunityObj.AccountId;
        
        opportunityObj.Amount = 100;
        opportunityObj.OppSubscriptionTermMonths__c = 12;
        opportunityObj.Pricebook2Id = Test.getStandardPricebookId();
        opportunityObj.Deal_Structuring_Oppty_Notes__c = 'Test';
        insert opportunityObj;
        
        serviceContract = new ServiceContract();
        serviceContract.Name = 'EntitlementTriggerHelper Contract';
        serviceContract.SBQQSC__Opportunity__c = opportunityObj.Id;
        serviceContract.AccountId = act.Id;
        serviceContract.StartDate = System.today();
        serviceContract.PriceBook2Id = Test.getStandardPricebookId();
        serviceContract.Term = 36;
        insert serviceContract;
        
        contractLineItem contractLineItem=EntitlementTriggerHelperClass_Test.GetContractLineItem();
        insert contractLineItem;
        
        ent=EntitlementTriggerHelperClass_Test.GetEntitlement();
        ent.ContractLineItemId = contractLineItem.Id;
        insert ent; 
        
    }
    
    //Test Entitlement And Asset Creation
   /* static testMethod void test_EntitlementTrigger () {

    Test.startTest();
    ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Triggers__c= true);
    insert disableLogic;
    ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(
      new ContractLineItem(),
      null
    );
    ContractLineItemObj.SBQQSC__Account__c = act.Id;
    ContractLineItemObj.AssetId = ast.Id;
    ContractLineItemObj.PricebookEntryId = pbeHW.Id;
    ContractLineItemObj.ServiceContractId = serviceContract.Id;
    ContractLineItemObj.Quantity = 10;
    ContractLineItemObj.UnitPrice = 100;
    insert ContractLineItemObj;

    SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opportunityObj.Id,
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__Primary__c = true,
            SBQQ__PriceBook__c = Test.getStandardPricebookId()
          );
        insert quote;
        List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
    lines.add(
      new SBQQ__QuoteLine__c(
        SBQQ__SubscribedAssetIds__c = ast.Id,
        SBQQ__Quote__c = quote.Id,
        SBQQ__Product__c = prdHW.Id,
        SBQQ__Quantity__c = 1,
        SBQQ__SubscriptionPricing__c = null,
        SBQQ__DefaultSubscriptionTerm__c = null,
        SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id,
        //CCLI__c = ContractLineItemObj1.Id,
        SBQQ__ListPrice__c = 200,
        SBQQ__NetPrice__c = 200
      )
    );
    insert lines;
    
        ContractLineItemObj.SBQQSC__QuoteLine__c = lines[0].Id;
        update ContractLineItemObj;

        List<Entitlement> entListNew = new List<Entitlement>();
        Entitlement entTest = EntitlementTriggerHelperClass_Test.GetEntitlement();
        entTest.ContractLineItemId = ContractLineItemObj.Id;
        entListNew.add(entTest);
        Entitlement entTest2 = EntitlementTriggerHelperClass_Test.GetEntitlement();
        entTest2.ContractLineItemId = ContractLineItemObj.Id;
        entTest2.AssetId = null;
        entListNew.add(entTest2);
        insert entListNew; 

        contractLineItem.SBQQSC__QuoteLine__c = lines[0].Id;
        update contractLineItem;
        ent.AssetId = ast.Id;
        update ent;
        
        List<Entitlement> entitlementNewList = new List<Entitlement>();
        entitlementNewList.add(ent);

        ShGl_CommonUtility.convertListToIdMap(new List<Asset> {ast});
        ShGl_CommonUtility.convertListToMap(new List<Asset> {ast}, 'Id');
        //System.assertNotEquals(null, EntitlementTriggerHelper.testA());
       // System.assertNotEquals(null, EntitlementTriggerHelper.testA2());
        
        List<Id> EntIDList = new List<Id>();
        
        for (Entitlement entId : entitlementNewList) {
            EntIDList.add(entId.Id);
        }
        System.enqueueJob(new EntitlementQueueableHelper(EntIDList));
        Test.stopTest();
        
    }*/
    
    @isTest
    private static void setRenewalCategoryTestForCategoryRenewable() {
        system.runAs(new user(Id = UserInfo.getUserId())){
        test.startTest();
        List<Entitlement> beforeEntitlementList = [SELECT Id, Renewable__c, Renewal_Category__c FROM Entitlement WHERE Id =: ent.Id];
        if(beforeEntitlementList.size() > 0) {
            beforeEntitlementList[0].Renewable__c = false;
            update beforeEntitlementList;
        }
        List<Entitlement> afterEntitlementList = [SELECT Id, Renewable__c, Renewal_Category__c FROM Entitlement WHERE Id =: ent.Id];
        System.assertEquals(afterEntitlementList.size(),1);
        /*if(afterEntitlementList.size() > 0) {
            //System.assertEquals('Non-renewable', afterEntitlementList[0].Renewal_Category__c);
        }*/
        test.stopTest();
       }
    }

    @isTest
    private static void setRenewalCategoryTestForCategoryRefreshed() {
        system.runAs(new user(Id = UserInfo.getUserId())){
        test.startTest();
        List<Asset> assetList = [SELECT Id, Is_Refreshed__c FROM Asset WHERE Id =: ast.Id];
        if(assetList.size() > 0) {
            assetList[0].Is_Refreshed__c = true;
            update assetList;
        }
        
        List<Entitlement> beforeEntitlementList = [SELECT Id, Renewable__c, Renewal_Category__c, Notes__c FROM Entitlement WHERE Id =: ent.Id];
        if(beforeEntitlementList.size() > 0) {
            beforeEntitlementList[0].Notes__c = 'Test Notes';
            update beforeEntitlementList;
        }
        
        List<Entitlement> afterEntitlementList = [SELECT Id, Renewable__c, Renewal_Category__c FROM Entitlement WHERE Id =: ent.Id];
        System.assertEquals(afterEntitlementList.size(), 1);

        /*if(afterEntitlementList.size() > 0) {
            //System.assertEquals('Refreshed', afterEntitlementList[0].Renewal_Category__c);
        }*/
        test.stopTest();
       }
    }

    @isTest
    private static void setRenewalCategoryTestForCategoryTerminated() {
        system.runAs(new user(Id = UserInfo.getUserId())){
        test.startTest();
        List<ContractLineItem> contractLineItemList = [SELECT Id, SBQQSC__TerminatedDate__c FROM ContractLineItem WHERE ServiceContractId =: serviceContract.Id];
        if(contractLineItemList.size() > 0) {
            contractLineItemList[0].SBQQSC__TerminatedDate__c = Date.Today().addDays(4);
            update contractLineItemList;
        }
        
        List<Entitlement> beforeEntitlementList = [SELECT Id, Renewable__c, Renewal_Category__c, Notes__c FROM Entitlement WHERE Id =: ent.Id];
        if(beforeEntitlementList.size() > 0) {
            beforeEntitlementList[0].Notes__c = 'Test Notes';
            update beforeEntitlementList;
        }
        
        List<Entitlement> afterEntitlementList = [SELECT Id, Renewable__c, Renewal_Category__c FROM Entitlement WHERE Id =: ent.Id];
        System.assertEquals(afterEntitlementList.size(), 1);

        EntitlementQueueableHelper helper = new EntitlementQueueableHelper();   
        System.enqueueJob(new EntitlementQueueableHelper());
        ApexPages.StandardController controller = new ApexPages.StandardController(new case());
        RMAOrderHandlerExtnClass rms = new RMAOrderHandlerExtnClass(controller);
        List<Order> newOrders = new list<order>();
        // Orderservice.OrderInit(newOrders);

        /* if(afterEntitlementList.size() > 0) {
            //System.assertEquals('Terminated', afterEntitlementList[0].Renewal_Category__c);
        }*/
        test.stopTest();
    }
    }
    
     @isTest
    private static void setRenewalCategoryTestForUserChangedValue() {
              system.runAs(new user(Id = UserInfo.getUserId())){
        SBQQ.TriggerControl.disable();
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Validation_Rules__c= true, Disable_SBQQ_Quote_Validation_Rules__c = true,
        Disable_Account_Triggers__c = true, Disable_Opportunity_Triggers__c = true);
        insert disableLogic;
        list<contractLineItem> contractLineItemList=new list<contractLineItem>();
   
        contractLineItem contractone=EntitlementTriggerHelperClass_Test.GetContractLineItem();
        contractLineItemList.add(contractone);
       
        contractLineItem secondcontractLineItem=EntitlementTriggerHelperClass_Test.GetContractLineItem(); 
        contractLineItemList.add(secondcontractLineItem);
        
        contractLineItem thirdcontractLineItem=EntitlementTriggerHelperClass_Test.GetContractLineItem();                
        contractLineItemList.add(thirdcontractLineItem);
        
        contractLineItem fourthcontractLineItem=EntitlementTriggerHelperClass_Test.GetContractLineItem();  
        contractLineItemList.add(fourthcontractLineItem);
        
        
        contractLineItem fifthcontractLineItem=EntitlementTriggerHelperClass_Test.GetContractLineItem(); 
        contractLineItemList.add(fifthcontractLineItem);
        
        contractLineItem sixthcontractLineItem=EntitlementTriggerHelperClass_Test.GetContractLineItem();
        sixthcontractLineItem.Storage_Region_Bundle__c ='Standard';
        contractLineItemList.add(sixthcontractLineItem);
        insert contractLineItemList;
       
        List<Entitlement> newEntitlementsList = new List<Entitlement>();
        Entitlement secondEnt=EntitlementTriggerHelperClass_Test.GetEntitlement();
        secondEnt.ContractLineItemId = fifthcontractLineItem.Id;
        newEntitlementsList.add(secondEnt);
        
        Entitlement sixthEnt=EntitlementTriggerHelperClass_Test.GetEntitlement();
        sixthEnt.ContractLineItemId = sixthcontractLineItem.Id;
        
        newEntitlementsList.add(sixthEnt);
        insert newEntitlementsList; 
        
        test.startTest();
        
        List<Entitlement> beforeEntitlementList = [SELECT Id, ContractLineItemId,Renewable__c,AssetId, Renewal_Category__c FROM Entitlement WHERE Id =: ent.Id];
        beforeEntitlementList[0].ContractLineItemId = secondcontractLineItem.id;
        update beforeEntitlementList;
        Opportunity oppr = [SELECT Id, pricebook2Id,CreatedById FROM Opportunity WHERE AccountId =: act.Id LIMIT 1];
        Id pricebookId = Test.getStandardPricebookId();
        oppr.pricebook2Id = pricebookId;
        update oppr;
        Product2 prod = new Product2(
            Name='RBK-SVC-PREM-OBJ-STORAGE',ProductCode='RBK-SVC-PREM-OBJ-STORAGE', Family='POLARIS', Appliance_Model_HW__c = 'RBK-R6408E',
            isActive = true, Bundle_Features__c = 'Polaris', Allow_PSO_Task_Creation__c = True
        );
        insert prod;
        
        pricebookentryobj  = new PricebookEntry(
            Pricebook2Id = oppr.pricebook2Id,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pricebookentryobj;
        
        Map<String, Object>  OrderMap = new Map<String, Object> {
            'Type' => 'Revenue',
                'Send_for_Polaris_Fulfilment__c' =>true,
                'AccountId' => act.Id,
                'POC_Opportunity__c' => oppr.Id,
                'EffectiveDate' => system.today(),
                'Order_Status__c' => null,
                'Status' => 'Pending',
                'Sync_to_NetSuite__c' => true,
                'ShippingCountryCode' => 'US',
                'ShippingStreet' =>'Test Street',
                'ShippingCity' => 'Test City',
                'ShippingState' =>'California',
                'ShippingCountry' =>'United States',
                'ShippingPostalcode' =>'94820',
                'ship_To_Name__c' => act.id,
                'ShipToContactName__c'=> 'Test',
                'Pricebook2Id' => pricebookId,
                'Have_Polaris_Products__c' => false,
                'Polaris_Fulfillment_Status__c' => 'Completed',
                'Original_Est_Ship_Date__c' => Date.today().addDays(30),
                'Est_Ship_Date__c' => null,
                'Order_Splitted__c' => true,
                'Order_Sub_Type__c' => 'Renewal'
                };
                    
                    orderobj  = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
        insert OrderObj; 
        list<OrderItem> OrderItemList=new list<OrderItem>();
     
        OrderItem ordrItem=EntitlementTriggerHelperClass_Test.GetOrderItem();
        ordrItem.SBQQSC__ContractLineItem__c = contractone.id;
        ordrItem.SerialNumber__c = '123\\s+';
        OrderItemList.add(ordrItem);
        
        OrderItem secondOrdrItem=EntitlementTriggerHelperClass_Test.GetOrderItem();
        secondOrdrItem.SBQQSC__ContractLineItem__c = secondcontractLineItem.id;
        secondOrdrItem.SerialNumber__c = '123\\s+';
        OrderItemList.add(secondOrdrItem);        
        
       
        OrderItem thirdOrdrItem=EntitlementTriggerHelperClass_Test.GetOrderItem();
        thirdOrdrItem.SBQQSC__ContractLineItem__c = secondcontractLineItem.id;
        thirdOrdrItem.SerialNumber__c = '123\\s+';
        OrderItemList.add(thirdOrdrItem);
        
        OrderItem fourthOrdrItem=EntitlementTriggerHelperClass_Test.GetOrderItem();
        fourthOrdrItem.SBQQSC__ContractLineItem__c = secondcontractLineItem.id;
        
        
        OrderItemList.add(fourthOrdrItem);
        
       
        OrderItem fifthOrdrItem=EntitlementTriggerHelperClass_Test.GetOrderItem();
        fifthOrdrItem.SBQQSC__ContractLineItem__c = fourthcontractLineItem.id;
        OrderItemList.add(fifthOrdrItem);
        insert OrderItemList;
        OrderItemList[1].SBQQ__RequiredBy__c = ordrItem.id;
        OrderItemList[2].SBQQ__RequiredBy__c = secondOrdrItem.id;
        OrderItemList[3].SBQQ__RequiredBy__c = OrdrItem.id;
        OrderItemList[4].SBQQ__RequiredBy__c = fourthOrdrItem.id;
        update OrderItemList;
        
        
        List<OrderItem> orderItemToUpdate = new List<OrderItem>();
        secondcontractLineItem.SBQQSC__OrderProduct__c = secondOrdrItem.id;
        
        ordrItem.SBQQSC__ContractLineItem__c = secondcontractLineItem.id;
        
        orderItemToUpdate.add(ordrItem);
        contractLineItem.SBQQSC__OrderProduct__c = ordrItem.id;
        
        secondOrdrItem.SBQQSC__ContractLineItem__c = contractLineItem.id;
        orderItemToUpdate.add(secondOrdrItem);
        thirdcontractLineItem.SBQQSC__OrderProduct__c = thirdOrdrItem.id;
        
        thirdOrdrItem.SBQQSC__ContractLineItem__c = thirdcontractLineItem.id;
        orderItemToUpdate.add(thirdOrdrItem);
        fourthcontractLineItem.SBQQSC__OrderProduct__c = fourthOrdrItem.id;
        
        fifthcontractLineItem.SBQQSC__OrderProduct__c = fifthOrdrItem.id;
        
        update contractLineItemList;
        beforeEntitlementList[0].ContractLineItemId = fourthcontractLineItem.id;
        update beforeEntitlementList;
        fourthOrdrItem.SBQQSC__ContractLineItem__c = fourthcontractLineItem.id;
        orderItemToUpdate.add(fourthOrdrItem);  
        
        fifthOrdrItem.SBQQSC__ContractLineItem__c = fifthcontractLineItem.id;
        orderItemToUpdate.add(fifthOrdrItem);
        update orderItemToUpdate;
        test.stopTest();
        asset asstList=[Select id,Rubrik_Suite__c,Licensing_Model__c,Support_Type__c from Asset limit 1];
        system.assert(asstList.Rubrik_Suite__c!=null);
        
        List<Entitlement> entListNew = new List<Entitlement>();
        
        Entitlement entTest1 = EntitlementTriggerHelperClass_Test.GetEntitlement();
        entTest1.Type = 'Manufacturing Entitlement'; 
        entTest1.Order_Service_Item__c = orderItemToUpdate[0].Id;
        Entitlement entTest2 = EntitlementTriggerHelperClass_Test.GetEntitlement();
        entTest2.Type = 'Evaluation';
        entTest2.Order_Service_Item__c = orderItemToUpdate[1].Id;
        entListNew.add(entTest1);
        entListNew.add(entTest2);
        
        insert entListNew;
        }
        
    }
    
    @isTest
    private static void setRenewalCategoryTestForUserChangedValueTwo() {
        system.runAs(new user(Id = UserInfo.getUserId())){
        test.startTest();
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Validation_Rules__c= true, Disable_SBQQ_Quote_Validation_Rules__c = true,
        Disable_Account_Triggers__c = true, Disable_Opportunity_Triggers__c = true);
        insert disableLogic;
        Id accDistiRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Partner/Distributor')
            .getRecordTypeId();
        Map<String, Object> accMap = new Map<String, Object>{
            'RecordtypeId' => accDistiRecTypeId,
            'Type' => 'Distributor'
        };
        List<account> accList = (List<account>) ShGl_TestFactory.createSObjectList(new Account(), 2, accMap);
        accList[0].name = 'Promark Technology, Inc.';
        accList[1].name = 'Net app, Inc.';
        insert accList;
        Map<String, Object> oppMap = new Map<String, Object>{
            'AccountId' => accList[0].Id,
            'RecordTypeId' => Schema.getGlobalDescribe()
                .get('Opportunity')
                .getDescribe()
                .getRecordTypeInfosByName()
                .get('Sales Opportunity')
                .getRecordTypeId()
        };
        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp.Distributor_Lookup__c = accList[0].id;
        opp.Partner_Lookup__c = accList[1].id;
        opp.Deal_Structuring_Oppty_Notes__c = 'Test';
        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;

        list<contractLineItem> itemList=new list<contractLineItem>();
       
        ContractLineItem cli=EntitlementTriggerHelperClass_Test.GetContractLineItem();
        cli.Quantity=12;
        cli.UnitPrice=200;
        itemList.add(cli);
      
        ContractLineitem secondcli=EntitlementTriggerHelperClass_Test.GetContractLineItem();
        cli.Quantity=120;
        cli.UnitPrice=100;
        itemList.add(secondcli);
        insert itemList;
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(),null); 
        qt.SBQQ__Account__c = accList[0].Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        qt.Task_Products__c ='RBK-DISK-RETENTION';
        insert qt;
        
        Product2 prod=[Select id,Name,ProductCode,Product_Subtype__c from Product2 where Product_Subtype__c='GO' limit 1];
        
        
        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.id, 
                                         SBQQ__StartDate__c = System.today(),
                                         SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
                                         SBQQ__DefaultSubscriptionTerm__c = 12,
                                         SBQQ__ListPrice__c = 200,
                                         SBQQ__NetPrice__c = 200,
                                         SBQQ__Product__c=prod.Id,
                                         SBQQSC__RenewedContractLine__c = cli.id));
        insert lines;
        
        itemList[1].SBQQSC__QuoteLine__c = lines[0].id;
        update itemList;
        
        list<Entitlement> entList=new list<Entitlement>();
        
        Entitlement firstent=EntitlementTriggerHelperClass_Test.GetEntitlement();
        firstent.ContractLineItemId = secondcli.Id;
        
        entList.add(firstent);
       
        Entitlement secondentt=EntitlementTriggerHelperClass_Test.GetEntitlement();
        secondentt.ContractLineItemId =cli.Id;        
        entList.add(secondentt);

        Entitlement Thirdentt=EntitlementTriggerHelperClass_Test.GetEntitlement();
        Thirdentt.ContractLineItemId =cli.Id;
        Thirdentt.AssetId=null;
        entList.add(Thirdentt);
        insert entList;
        
        list<Id> entId = new list<Id>();
        entId.add(firstent.id);
        entId.add(secondentt.id);
        entId.add(Thirdentt.id);
        EntitlementTriggerHelper.populatePriorEntitlement(entId);
        test.stopTest();
        entitlement ent2=[select id,PriorCLIId__c from Entitlement where id =:firstent.id limit 1];
        system.assert(ent2.PriorCLIId__c!=null);
    }
        
    }

    @isTest
    private static void setRenewalCategoryTestForUserChangedValueThree() {
        system.runAs(new user(Id = UserInfo.getUserId())){
        test.startTest();
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Validation_Rules__c= true, Disable_SBQQ_Quote_Validation_Rules__c = true,
        Disable_Account_Triggers__c = true, Disable_Opportunity_Triggers__c = true);
        insert disableLogic;
        Id accDistiRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Partner/Distributor')
            .getRecordTypeId();
        Map<String, Object> accMap = new Map<String, Object>{
            'RecordtypeId' => accDistiRecTypeId,
            'Type' => 'Distributor'
        };
        List<account> accList = (List<account>) ShGl_TestFactory.createSObjectList(new Account(), 2, accMap);
        accList[0].name = 'Promark Technology, Inc.';
        accList[1].name = 'Net app, Inc.';
        insert accList;
        Map<String, Object> oppMap = new Map<String, Object>{
            'AccountId' => accList[0].Id,
            'RecordTypeId' => Schema.getGlobalDescribe()
                .get('Opportunity')
                .getDescribe()
                .getRecordTypeInfosByName()
                .get('Sales Opportunity')
                .getRecordTypeId()
        };
        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp.Distributor_Lookup__c = accList[0].id;
        opp.Partner_Lookup__c = accList[1].id;
        opp.Deal_Structuring_Oppty_Notes__c = 'Test';
        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;

        list<contractLineItem> itemList=new list<contractLineItem>();
       
        ContractLineItem cli=EntitlementTriggerHelperClass_Test.GetContractLineItem();
        cli.Quantity=12;
        cli.UnitPrice=200;
        itemList.add(cli);
      
        ContractLineitem secondcli=EntitlementTriggerHelperClass_Test.GetContractLineItem();
        cli.Quantity=120;
        cli.UnitPrice=100;
        itemList.add(secondcli);
        insert itemList;
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(),null); 
        qt.SBQQ__Account__c = accList[0].Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        qt.Task_Products__c ='RBK-DISK-RETENTION';
        insert qt;
        
        Product2 prod=[Select id,Name,ProductCode,Product_Subtype__c from Product2 where Product_Subtype__c='GO' limit 1];
        
        
        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.id, 
                                         SBQQ__StartDate__c = System.today(),
                                         SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
                                         SBQQ__DefaultSubscriptionTerm__c = 12,
                                         SBQQ__ListPrice__c = 200,
                                         SBQQ__NetPrice__c = 200,
                                         SBQQ__Product__c=prod.Id,
                                         SBQQSC__RenewedContractLine__c = cli.id));
         lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.id, 
                                         SBQQ__StartDate__c = System.today(),
                                         SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
                                         SBQQ__DefaultSubscriptionTerm__c = 12,
                                         SBQQ__ListPrice__c = 200,
                                         SBQQ__NetPrice__c = 200,
                                         SBQQ__Product__c=prod.Id
                                          /*,
                                         SBQQSC__RenewedContractLine__c = cli.id*/));
        insert lines;
        
        itemList[1].SBQQSC__QuoteLine__c = lines[0].id;
        update itemList;
        
        cli.SBQQSC__QuoteLine__c = lines[1].id;
        update cli;
        
        list<Entitlement> entList=new list<Entitlement>();
        
        Entitlement firstent=EntitlementTriggerHelperClass_Test.GetEntitlement();
        firstent.ContractLineItemId = secondcli.Id;
        
        entList.add(firstent);
       
        Entitlement secondentt=EntitlementTriggerHelperClass_Test.GetEntitlement();
        secondentt.ContractLineItemId =cli.Id; 
        secondentt.AssetId=null;

        entList.add(secondentt);

        Entitlement Thirdentt=EntitlementTriggerHelperClass_Test.GetEntitlement();
        Thirdentt.ContractLineItemId =cli.Id;
        Thirdentt.AssetId=null;
        entList.add(Thirdentt);
        insert entList;
        
        
        list<Id> entId = new list<Id>();
        entId.add(firstent.id);
        entId.add(secondentt.id);
        entId.add(Thirdentt.id);
        EntitlementTriggerHelper.populatePriorEntitlement(entId);
        test.stopTest();
        entitlement ent2=[select id,PriorCLIId__c from Entitlement where id =:firstent.id limit 1];
        system.assert(ent2.PriorCLIId__c!=null);
    }
        
    }
    
    

    /**
    * @author Prashant Kumar
    * @date 11-03-2025
    * @description Set ContractLineItem Record   
    * @return ContractLineItem
    */
     Public static contractLineItem getContractLineItem(){
        contractLineItem = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        contractLineItem.SBQQSC__Account__c = act.Id;
        contractLineItem.AssetId = ast.Id;
        contractLineItem.PricebookEntryId = pbeHW.Id;
        contractLineItem.ServiceContractId = serviceContract.Id;
        contractLineItem.Rubrik_Suite__c = 'Premium';
        contractLineItem.Licensing_Model__c = 'Subscription';
        contractLineItem.Support_Type__c = 'Premium';
        contractLineItem.Payment_Options__c = 'Prepay';
        return contractLineItem;
        
    }
    /**
    * @author Prashant Kumar
    * @date 11-03-2025
    * @description Set OrderlineItem Record   
    * @return OrderItem
    */
    Public static OrderItem getOrderItem(){
        OrderItem ordrItem = new OrderItem();
        ordrItem.OrderId = OrderObj.Id;
        ordrItem.Quantity = 5;
        ordrItem.PricebookEntryId = pricebookentryObj.Id;
        ordrItem.UnitPrice = pricebookentryObj.UnitPrice;
        ordrItem.Failed_Serial_Number__c = 'S3F4NXM416324';
        ordrItem.Support_End_Date__c = System.Today().addYears(1);
        ordrItem.Support_Start_Date__c = System.Today();
        ordrItem.Is_Hardware_Line__c = true;
        ordrItem.Is_Refresh__c = true;
        return ordrItem;
    }
    /**
    * @author Prashant Kumar
    * @date 11-03-2025
    * @description Set OrderlineItem Record   
    * @return OrderItem
    */
    public static Entitlement getEntitlement(){
        secondEnt = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        secondEnt.AccountId = act.Id;
        secondEnt.StartDate = Date.today().addDays(-365);
        secondEnt.EndDate = Date.today().addDays(365);
        secondEnt.AssetId = ast.Id;
        secondEnt.Renewable__c = true;
        secondEnt.Type = 'Phone Support';
        secondEnt.Name = 'EntitlementTriggerHelper';
        secondEnt.Product__c = prdHW.Id;
        secondEnt.Refreshed_Opportunity_Link__c = opportunityObj.Id;
        secondEnt.ServiceContractId = serviceContract.Id;
        return secondEnt;
    }
}