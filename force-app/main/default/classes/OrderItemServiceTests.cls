/*Created By : Chandra Prakash Chouksey
  Purpose : Test class for OrderItem trigger, OrderItemTriggerHandler, OrderItemTriggerHelper Class
*/
@isTest(SeeAllData=false)
public class OrderItemServiceTests { 
  @testSetup
  static void createTestData() {
    String uniqueUserName = 'TestUser' + DateTime.now().getTime() + '@rbk.com';
            Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
    User usr1 = new user(
            alias = 'std',
            email = 'testuser@testclass.com.invalid',
            emailencodingkey = 'UTF-8',
            firstname = 'test',
            lastname = 'user',
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            profileid = p.Id,
            timezonesidkey = 'America/Los_Angeles',
            username = uniqueUserName,
            RBAC_Department__c = 'Service Account',
            RBAC_Group__c = 'API'
        );
        insert usr1;
                System.runAs(usr1) {
      insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Disable_Account_Old_Trigger__c = true);
      insert new ShGl_DisableBusinessLogic__c(
        setupownerid = userinfo.getUserId(),
        Disable_Account_Triggers__c = true,
        Disable_Asset_Triggers__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_Order_Old_Trigger__c = true,
        Disable_OrderItem_Old_Trigger__c = true,
        Disable_Opportunity_Triggers__c = true,
                                                    Disable_SBQQ_QuoteLine_Validation_Rules__c =  true,
                                                    Disable_Product2_Validation_Rules__c = true,
                                                    Disable_Order_Validation_Rules__c = true,
                                                    Follow_Existing_EntCreate_Process__c = true,
                                                    Disable_SBQQ_Quote_Validation_Rules__c = true,
        Disable_Entitlement_Validation_Rules__c = true,
        Disable_Contract_Line_Item_Triggers__c = true
      );
            
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true; 
            SBQQ.TriggerControl.disable();  
            //triggerControl.stopEntitlementTrigger = true;
      insert new List<TriggerControl__c>{ new TriggerControl__c(Name = 'Entitlement', DisableTrigger__c = false) };
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
      Account acct = new Account(Name = 'NetApp', RecordTypeId = partnerRecordTypeId);
        insert acct;
      Id standardPriceBookId = Test.getStandardPricebookId(); //pb2Standard.Id;
        
        Id pricebookId = Test.getStandardPricebookId();
        
         List<Opportunity> lstOpportunitiesRecords = new List<Opportunity>{
        //0
        new Opportunity(
          Name = 'testing DIEtestsalesforce 27/1/2017',
          Sell_to_Partner__c = acct.Id,
          AccountId = acct.Id,
          StageName = '1 Discovery',
          CloseDate = System.Today().addDays(30),
          Lead_Email_Hidden__c = '',
          Partner_Lookup__c = acct.id,
          Alliance_Partner_Name__c = 'Amazon',
          Alliance_Source_Type__c = 'Alliance Initiated Deal',
          Alliance_Source_Type_HW__c = 'Rubrik Initiated Alliance Deal',
          Economic_Buyer__c = 'Test',
          Metric__c = 'Test',
          Decision_Process__c = 'Test',
          Decision_Criteria__c = 'Test',
          Identified_Pain__c = 'Test',
          Champion__c = 'Test',
          Why_Rubrik__c = 'Why_Rubrik',
          Why_do_anything__c = 'Why_do_anything',
          Why_now__c = 'Why_now',
          Alliance_HW_Partner__c = 'Cisco',
          Partner_Representative__c = 'Test'
        ),
        //1                                 
        new Opportunity(
          Name = 'TPH',
          CloseDate = System.Today().addDays(30),
          StageName = '1 Discovery',
          Partner_Lookup__c = acct.Id,
          AccountId = acct.Id,
          Distributor_Lookup__c = acct.Id,
          Pricebook2id = Test.getStandardPricebookId()
        ),
        //2                             
        new Opportunity(
          Name = 'TPH1',
          CloseDate = System.Today().addDays(30),
          StageName = '1 Discovery',
          Partner_Lookup__c = acct.Id,
          AccountId = acct.Id,
          Distributor_Lookup__c = acct.Id,
          Pricebook2id = Test.getStandardPricebookId()
        )
        };
        
        insert lstOpportunitiesRecords;   
        
        List<Product2> lstProducts = new List<Product2>{
            //0
        new Product2(
          Name = 'Product XY',
          Usable_Capacity__c = 30,
          ProductCode = 'Pro-XY',
          isActive = true,
          Product_Level__c = 'LOD Software',
          Quotable_Date__c = system.today(),
          Product_Subtype__c = 'Scale MSP'
        ),
            //1
        new Product2(
          Name = 'RBK-R304-01',
          Usable_Capacity__c = 30,
          ProductCode = 'RBK-R304-01',
          isActive = true,
          Product_Level__c = 'Hybrid Software',
          Quotable_Date__c = system.today(),
          Product_Subtype__c = 'Scale MSP'
        ),
            //2
        new Product2(
          Name = 'Premium Support 1-Yr Prepaid, r304',
          Usable_Capacity__c = 30,
          ProductCode = 'RBK-SVC-PREM-R304',
          isActive = true,
          Product_Level__c = 'Support',
          Quotable_Date__c = system.today(),
          Product_Subtype__c = 'Scale MSP'
        ),
            /*SKU-104*/
            //3
        new Product2(
          Name = 'RBK-SVC-PREM-APPLIANCE',
          Usable_Capacity__c = 60,
          ProductCode = 'Product SKU-104',
          isActive = true,
          Product_Level__c = 'Hybrid Software',
          Quotable_Date__c = system.today(),
          Product_Subtype__c = 'Scale MSP'
        ),
            //4
            /*new Product2(Name = 'Product SKU-104',ProductCode = 'Product SKU-104', isActive = true,Product_Level__c = 'Hybrid Software',
                         Product_Type__c = 'RCDM Support',Approval_Category__c = 'RCDM Support',Quotable_Date__c = system.today()),*/
        new Product2(
          Name = 'Product SKU-104',
          ProductCode = 'Product SKU-104',
          isActive = true,
          Product_Level__c = 'Support',
          Product_Type__c = 'RCDM Support',
          Approval_Category__c = 'RCDM Support',
          Quotable_Date__c = system.today(),
          Product_Subtype__c = 'Scale MSP'
        ),
            //5
        new Product2(
          Name = 'Product SKU-104',
          Usable_Capacity__c = 30,
          ProductCode = 'Product SKU-104',
          isActive = true,
          Product_Level__c = 'Hybrid Software',
          Product_Type__c = 'HW Support',
          Approval_Category__c = 'Hardware Support',
          Quotable_Date__c = system.today(),
          Product_Subtype__c = 'Scale MSP'
        ),
            //6
        new Product2(
          Name = 'RBK-SVC-PREM-R334S-3YR',
          Usable_Capacity__c = 90,
          ProductCode = 'RBK-SVC-PREM-OBJ-STORAGE',
          isActive = true,
          Product_Level__c = null,
          Product_Type__c = null,
          Bundle_Features__c = 'RCDM;Hardware Premium Support',
          Quotable_Date__c = system.today(),
          Product_Subtype__c = 'Scale MSP'
        ),
           //7 
        new Product2(
          Name = 'Product SKU-104',
          Usable_Capacity__c = 90,
          ProductCode = 'Product SKU-104',
          isActive = true,
          Product_Level__c = 'Support',
          Product_Type__c = 'HW Support',
          Product_Subtype__c = 'RCDM',
          Approval_Category__c = 'RCDM Support',
          Quotable_Date__c = system.today()
        ),
           //8
        new Product2(
          Name = 'RBK-TPH-BUE-PE-PA',
          Usable_Capacity__c = 30,
          Family = 'Third Party License',
          ProductCode = 'RBK-TPH-BUE-PE-PA',
          isActive = true,
          Product_Type__c = 'Edition Upgrade',
          Approval_Category__c = 'Edition Upgrade',
          Quotable_Date__c = system.today(),
          Product_Subtype__c = 'Scale MSP'
        ),
           //9
                           new Product2(
                    Name = 'RS-BT-BE-RSCP-TPH-PE-PP',
                    ProductCode = 'RS-BT-BE-RSCP-TPH-PE-PP',
                    Category__c = 'Bundle',
                    Family = 'Third Party License',
                    Product_Type__c = 'Business Edition',
                    License_Category__c = 'On Prem',
                    License_Type__c = 'Subscription',
                    Product_Level__c = 'OnPrem',
                    SBQQ__AssetAmendmentBehavior__c = 'Default',
                    SBQQSC__EntitlementConversion__c = 'One per quote line',
                    IsActive = true,
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 1,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable'
                ),
        //10
                 new Product2(
                    Name = 'RS-BT-RCDM-T',
                    ProductCode = 'RS-BT-RCDM-T',
                    License_Category__c = 'On Prem',
                    Category__c = 'Software',
                    Product_Level__c = 'OnPrem',
                    Family = 'OnPrem',
                    SBQQSC__EntitlementConversion__c = 'One per quote line',
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 1,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'One-time',
                    IsActive = true,
                    Support_Type__c = 'Premium',
                    New_CPQ_Product__c = false,
                    GPL_Name__c = 'NetApp'
                ),
        // 11
                new Product2(
                    Name = 'RS-BT-EE-PE-PP',
                    ProductCode = 'RS-BT-EE-PE-PP',
                    Category__c = 'Bundle',
                    Family = 'Rubrik Licence',
                    Product_Type__c = 'Enterprise Edition',
                    License_Category__c = 'SaaS',
                    Product_Subtype__c = null,
                    Product_Level__c = 'Hybrid Software',
                    SBQQ__AssetAmendmentBehavior__c = 'Default',
                    SBQQSC__EntitlementConversion__c = 'One per quote line',
                    IsActive = true,
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 36,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable'
                ),
        new Product2(
          Name = 'RBK-SVC-PREM-OBJ-STORAGE',
          Usable_Capacity__c = 90,
          ProductCode = 'RBK-SVC-PREM-OBJ-STORAGE',
          isActive = true,
          Product_Level__c = null,
          Product_Type__c = null,
          Bundle_Features__c = 'RCDM;Hardware Premium Support',
          Quotable_Date__c = system.today(),
          Product_Subtype__c = 'Scale MSP'
        ),
               //13

        new Product2(
          Name = 'RS-BT-BE-RSCP-TPH-PE-PP',
          Usable_Capacity__c = 90,
          ProductCode = 'RS-BT-BE-RSCP-TPH-PE-PP',
          isActive = true,
          Product_Level__c = 'Hardware',
          Product_Type__c = null,
          Bundle_Features__c = 'RCDM;Hardware Premium Support',
          Quotable_Date__c = system.today(),
          Product_Subtype__c = 'Scale MSP'
        )
        };

        insert lstProducts;

      List<Polaris_SKU_Mapping_V2__c> polarisSKUMappingObjList = new List<Polaris_SKU_Mapping_V2__c>();

      for (Product2 prod : lstProducts) {
        Polaris_SKU_Mapping_V2__c polarisSKUMappingObj = new Polaris_SKU_Mapping_V2__c();
        polarisSKUMappingObj.Name = 'Test Polaris';
        polarisSKUMappingObj.Old_Product__c = prod.id;
        polarisSKUMappingObj.New_Product__c = prod.id;
        polarisSKUMappingObj.Support_Tier__c = 'E1';
        polarisSKUMappingObj.Quantity_Mapping_Type__c = 'Ratio Based';
        polarisSKUMappingObj.Quantity_Ratio__c = 2;
        polarisSKUMappingObj.Support_Type__c = 'L3';
        polarisSKUMappingObj.Payment_Option__c = 'Annual';
        polarisSKUMappingObjList.add(polarisSKUMappingObj);
      }

      insert polarisSKUMappingObjList;

        List<PricebookEntry> lstPricebooks = new List<PricebookEntry>{
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[0].Id, UnitPrice = 100.00, IsActive = true),
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[1].Id, UnitPrice = 100.00, IsActive = true),
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[2].Id, UnitPrice = 100.00, IsActive = true),
            /*SKU-104*/    
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[3].Id, UnitPrice = 100.00, IsActive = true),
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[4].Id, UnitPrice = 100.00, IsActive = true),
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[5].Id, UnitPrice = 100.00, IsActive = true),
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[6].Id, UnitPrice = 100.00, IsActive = true),
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[7].Id, UnitPrice = 100.00, IsActive = true),
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[8].Id, UnitPrice = 100.00, IsActive = true),
            new PricebookEntry(UseStandardPrice = false, Pricebook2Id = pricebookId, Product2Id = lstProducts[9].Id, IsActive = true, UnitPrice = 100),
            new PricebookEntry(UseStandardPrice = false, Pricebook2Id = pricebookId, Product2Id = lstProducts[10].Id, IsActive = true, UnitPrice = 100),
            new PricebookEntry(UseStandardPrice = false, Pricebook2Id = pricebookId, Product2Id = lstProducts[11].Id, IsActive = true, UnitPrice = 100),
            new PricebookEntry(UseStandardPrice = false, Pricebook2Id = pricebookId, Product2Id = lstProducts[12].Id, IsActive = true, UnitPrice = 100)
        };
        
        insert lstPricebooks;

        List<SBQQ__Quote__c> lstQuoteRecords = new List<SBQQ__Quote__c>{
    //0
        new SBQQ__Quote__c(
          SBQQ__Opportunity2__c = lstOpportunitiesRecords[0].Id,
          SBQQ__StartDate__c = System.today(),
          SBQQ__SubscriptionTerm__c = 12,
          SBQQ__Primary__c = true,
          SBQQ__PriceBook__c = Test.getStandardPricebookId(),
          /*SKU-104*/ SBQQ__Type__c = 'Quote',
          Opportunity_Program__c = 'Conversion',
          Additional_Month_added__c = true
        ),
    //1
        new SBQQ__Quote__c(
          SBQQ__Opportunity2__c = lstOpportunitiesRecords[1].Id,
          SBQQ__SubscriptionTerm__c = 12,
          Is_RWD_Polaris_Quote__c = false,
          SBQQ__Primary__c = true,
          ApprovalStatus__c = 'Recalled',
          SBQQ__Type__c = 'Renewal+Expansion',
          SBQQ__PriceBook__c = Test.getStandardPricebookId()
        ),
    //2
        new SBQQ__Quote__c(
          SBQQ__Opportunity2__c = lstOpportunitiesRecords[2].Id,
          SBQQ__SubscriptionTerm__c = 12,
          Is_RWD_Polaris_Quote__c = false,
          SBQQ__Primary__c = true,
          ApprovalStatus__c = 'Recalled',
          SBQQ__Type__c = 'Renewal+Expansion',
          SBQQ__PriceBook__c = Test.getStandardPricebookId()
        ),
        new SBQQ__Quote__c(
          SBQQ__Opportunity2__c = lstOpportunitiesRecords[2].Id,
          SBQQ__SubscriptionTerm__c = 12,
          Is_RWD_Polaris_Quote__c = false,
          SBQQ__Primary__c = true,
          ApprovalStatus__c = 'Recalled',
          SBQQ__Type__c = 'Renewal+Expansion',
          SBQQ__PriceBook__c = Test.getStandardPricebookId(),
          RWD_Deal_Ops_Exception__c = 'RCDM-T Manual Extension',
          RWD_Deal_Ops_Exception_Justification__c = 'Test'
        )
      };
      insert lstQuoteRecords;
        TriggerControl.stopOrderTrigger = true;
      Order orgOrder = new Order(
        AccountId = acct.Id,
        Pricebook2Id = standardPriceBookId,
        OpportunityId = lstOpportunitiesRecords[1].Id,
        SBQQ__Quote__c = lstQuoteRecords[1].Id,
        EffectiveDate = System.today(),
        Status = 'Draft',
        Type = 'Revenue',
        Order_Status__c = 'Pending',
        Is_RWD_Polaris_Quote__c = true,
        Order_Sub_Type__c = null
      );
      insert orgOrder;
        TriggerControl.stopOrderTrigger = false;
      Asset ast = new Asset(Name = 'AA204063041111', serial_number__c = 'AA204063041111', SerialNumber = 'AA204063041111', AccountId = acct.Id, Product2Id = lstProducts[0].Id);
        insert ast;
      OrderItem oldOI = new OrderItem(
        OrderId = orgOrder.Id,
        Product2Id = lstProducts[0].Id,
        Quantity = 250,
        PricebookEntryId = lstPricebooks[0].Id,
        UnitPrice = lstPricebooks[0].UnitPrice,
        SerialNumber__c = 'AA204063041111',
        Support_End_Date__c = System.Today().addYears(1),
        Support_Start_Date__c = System.Today()
      );
        triggerControl.stopOrderItemTrigger = true;
        insert oldOI;
        triggerControl.stopOrderItemTrigger = false;
      ServiceContract sc = new ServiceContract(
        Name = 'Test opp - 30 Sept - Contract',
        AccountId = acct.Id,
        SBQQSC__Quote__c = lstQuoteRecords[0].Id,
        Pricebook2Id = Test.getStandardPricebookId(),
        Term = 36,
        StartDate = System.Today(),
        EndDate = System.today().addMonths(36)
      );
        insert sc;
      ContractLineItem cli = new ContractLineItem(
        ServiceContractId = sc.Id,
        SBQQSC__Account__c = acct.Id,
        SBQQSC__Product__c = lstProducts[1].Id,
        MSP_Segment_Product__c = true,
        PricebookEntryId = lstPricebooks[1].Id,
        Quantity = 10,
        UnitPrice = lstPricebooks[1].UnitPrice
      );
        insert cli;
      /*Entitlement oldEnt = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        //Entitlement ent = new Entitlement();
        oldEnt.Name='Product SKU-104';
        oldEnt.AccountId = acct.Id;
        oldEnt.StartDate = Date.today().addDays(-365);
        oldEnt.EndDate = Date.today().addDays(365);
        oldEnt.ContractLineItemId = cli.id;
        oldEnt.Product__c = lstProducts[3].id;
        oldEnt.Order_Service_Item__c = oldOI.id;
        oldEnt.Assetid = ast.id;
        insert oldEnt;*/
        List<Entitlement> entitlements = new List<Entitlement>{
        (Entitlement) ShGl_TestFactory.createSObject(
          new Entitlement(),
          new Map<String, Object>{
                'Name' => 'Product SKU-104',
                'AccountId' => acct.Id,
                'StartDate' => Date.today().addDays(-365),
                'EndDate' => Date.today().addDays(365),
                'ContractLineItemId' => cli.Id,
                'Product__c' => lstProducts[3].Id,
                'Order_Service_Item__c' => oldOI.Id,
                'AssetId' => ast.Id
          }
        ),
        (Entitlement) ShGl_TestFactory.createSObject(
          new Entitlement(),
          new Map<String, Object>{
                'Name' => 'Product SKU-104',
                'AccountId' => acct.Id,
                'StartDate' => Date.today().addDays(-365),
                'EndDate' => Date.today().addDays(365),
                'ContractLineItemId' => cli.Id,
                'Product__c' => lstProducts[3].Id,
                'Order_Service_Item__c' => oldOI.Id,
                'AssetId' => ast.Id
          }
        )
        };
        
        insert entitlements;
        
        Test.startTest();
        
      String replaceDet =
        '{"rowValues":[{"rowId":"20.0","partial_Quantity":"Yes","entId":"' +
        entitlements[0].Id +
        '","selectedQty":2,"selectedTerm":12,"isMismatch":null,"inactiveLines":[{"childrowId":null,"childQnty":4,"childEntId":"' +
        entitlements[1].Id +
        '"}]}],"mode":"1to1","skuSelectedName":"RS-BT-EE-SC-PE-PP","skuSelected":"01t6f00000NUivYAAT","targetProductType":"Hardware","disposition":"Converted"}';
                    
      //String replaceDet = '{"rowValues":[{"rowId":"20.0","partial_Quantity":"Yes","entId":"'+oldEnt.id+'","selectedQty":2,"selectedTerm":12}],"mode":"1to1", "skuSelectedName":"RS-BT-EE-SC-PE-PP", "skuSelected":"01t6f00000NUivYAAT","targetProductType" : "Hardware","disposition":"Converted"}';

      List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
      lines.add(
        new SBQQ__QuoteLine__c(
          Prepayment_Credit__c = 1000.00,
          SBQQ__Quote__c = lstQuoteRecords[0].Id,
          Arroyo_Subsumed_Old_Contract_Line_Items__c = cli.id,
          SBQQ__Product__c = lstProducts[0].Id,
          SBQQ__Quantity__c = 1,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__StartDate__c = System.today(),
          SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          Prepayment_Credit__c = 1000.00,
          SBQQ__Quote__c = lstQuoteRecords[0].Id,
          Arroyo_Subsumed_Old_Contract_Line_Items__c = cli.id,
          SBQQ__Product__c = lstProducts[1].Id,
          SBQQ__Quantity__c = 5,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__StartDate__c = System.today(),
          SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          Prepayment_Credit__c = 1000.00,
          SBQQ__Quote__c = lstQuoteRecords[0].Id,
          Arroyo_Subsumed_Old_Contract_Line_Items__c = cli.id,
          SBQQ__Product__c = lstProducts[2].Id,
          SBQQ__Quantity__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__StartDate__c = System.today(),
          SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
          SBQQ__DefaultSubscriptionTerm__c = 12,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Licensing_Model__c = 'Subscription'
        )
      );
        
        /*SKU-104*/
      lines.add(
        new SBQQ__QuoteLine__c(
          Prepayment_Credit__c = 1000.00,
          Replacement_Details__c = replaceDet,
          Arroyo_Subsumed_Old_Contract_Line_Items__c = cli.id,
          SBQQ__Quote__c = lstQuoteRecords[0].Id,
          SBQQ__Product__c = lstProducts[3].Id,
          SBQQ__Quantity__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__StartDate__c = System.today(),
          SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
          SBQQ__DefaultSubscriptionTerm__c = 12,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Special_Program__c = 'Conversion',
          Arroyo_Subscribed_Asset_Name__c = 'AA204063040011',
          SubscribedAssetNames__c = 'AA204063040011',
          Licensing_Model__c = 'Subscription'
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          Prepayment_Credit__c = 1000.00,
          Replacement_Details__c = replaceDet,
          Arroyo_Subsumed_Old_Contract_Line_Items__c = cli.id,
          SBQQ__Quote__c = lstQuoteRecords[0].Id,
          SBQQ__Product__c = lstProducts[5].Id,
          SBQQ__Quantity__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__StartDate__c = System.today(),
          SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
          SBQQ__DefaultSubscriptionTerm__c = 12,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Special_Program__c = 'Conversion',
          Arroyo_Subscribed_Asset_Name__c = 'AA204063040012',
          SubscribedAssetNames__c = 'AA204063040012',
          Licensing_Model__c = 'Subscription'
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          Prepayment_Credit__c = 1000.00,
          Replacement_Details__c = replaceDet,
          Arroyo_Subsumed_Old_Contract_Line_Items__c = cli.id,
          SBQQ__Quote__c = lstQuoteRecords[0].Id,
          SBQQ__Product__c = lstProducts[6].Id,
          SBQQ__Quantity__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__StartDate__c = System.today(),
          SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
          SBQQ__DefaultSubscriptionTerm__c = 12,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Special_Program__c = 'Conversion',
          Arroyo_Subscribed_Asset_Name__c = 'AA204063040013',
          SubscribedAssetNames__c = 'AA204063040013',
          Licensing_Model__c = 'Subscription'
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          Prepayment_Credit__c = 1000.00,
          Replacement_Details__c = replaceDet,
          Arroyo_Subsumed_Old_Contract_Line_Items__c = cli.id,
          SBQQ__Quote__c = lstQuoteRecords[0].Id,
          SBQQ__Product__c = lstProducts[4].Id,
          SBQQ__Quantity__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__StartDate__c = System.today(),
          SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
          SBQQ__DefaultSubscriptionTerm__c = 12,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Special_Program__c = 'Conversion',
          Arroyo_Subscribed_Asset_Name__c = 'AA204063040014',
          SubscribedAssetNames__c = 'AA204063040014',
          Licensing_Model__c = 'Subscription'
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          Prepayment_Credit__c = 1000.00,
          Replacement_Details__c = replaceDet,
          Arroyo_Subsumed_Old_Contract_Line_Items__c = cli.id,
          SBQQ__Quote__c = lstQuoteRecords[0].Id,
          SBQQ__Product__c = lstProducts[7].Id,
          SBQQ__Quantity__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__StartDate__c = System.today(),
          SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
          SBQQ__DefaultSubscriptionTerm__c = 12,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Special_Program__c = 'Conversion',
          Arroyo_Subscribed_Asset_Name__c = 'AA204063040015',
          SubscribedAssetNames__c = 'AA204063040015',
          Licensing_Model__c = 'Subscription'
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          Prepayment_Credit__c = 1000.00,
          Replacement_Details__c = replaceDet,
          Arroyo_Subsumed_Old_Contract_Line_Items__c = cli.id,
          SBQQ__Quote__c = lstQuoteRecords[0].Id,
          TPH_Quantity__c = '5',
          SBQQ__Product__c = lstProducts[8].Id,
          SBQQ__Quantity__c = 70,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__StartDate__c = System.today(),
          SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
          SBQQ__DefaultSubscriptionTerm__c = 12,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Licensing_Model__c = 'Subscription'
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          Prepayment_Credit__c = 1000.00,
          Replacement_Details__c = replaceDet,
          Arroyo_Subsumed_Old_Contract_Line_Items__c = cli.id,
          SBQQ__Quote__c = lstQuoteRecords[1].Id,
          SBQQ__PriorQuantity__c = 0,
          SBQQ__UpgradedQuantity__c = 0,
          SBQQ__Product__c = lstProducts[9].Id,
          SBQQ__PricebookEntryId__c = lstPricebooks[0].Id,
          SBQQ__Quantity__c = 600,
          TPH_Quantity__c = '40',
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Arroyo_Subscribed_Asset_Name__c = 'AAA8976565434',
          SubscribedAssetNames__c = 'AAA8976565434',
          Licensing_Model__c = 'Subscription'
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          Prepayment_Credit__c = 1000.00,
          Replacement_Details__c = replaceDet,
          Arroyo_Subsumed_Old_Contract_Line_Items__c = cli.id,
          SBQQ__Quote__c = lstQuoteRecords[2].Id,
          SBQQ__PriorQuantity__c = 0,
          SBQQ__UpgradedQuantity__c = 0,
          SBQQ__Product__c = lstProducts[9].Id,
          SBQQ__PricebookEntryId__c = lstPricebooks[0].Id,
          SBQQ__Quantity__c = 600,
          TPH_Quantity__c = '40',
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Arroyo_Subscribed_Asset_Name__c = 'AAA8976565434',
          SubscribedAssetNames__c = 'AAA8976565434',
          Licensing_Model__c = 'Subscription'
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          Prepayment_Credit__c = 1000.00,
          Replacement_Details__c = replaceDet,
          Arroyo_Subsumed_Old_Contract_Line_Items__c = cli.id,
          SBQQ__Quote__c = lstQuoteRecords[3].Id,
          SBQQ__PriorQuantity__c = 0,
          SBQQ__UpgradedQuantity__c = 0,
          SBQQ__Product__c = lstProducts[10].Id,
          SBQQ__PricebookEntryId__c = lstPricebooks[0].Id,
          SBQQ__Quantity__c = 600,
          TPH_Quantity__c = '40',
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          RWD_Deal_Ops_Exception__c = 'RCDM-T Manual Extension' /*, Arroyo_Subsumed_Old_Contract_Line_Items__c = lstCli[0].Id+','+lstCli[0].Id*/
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          Prepayment_Credit__c = 1000.00,
          Replacement_Details__c = replaceDet,
          Arroyo_Subsumed_Old_Contract_Line_Items__c = cli.id,
          SBQQ__Quote__c = lstQuoteRecords[3].Id,
          SBQQ__PriorQuantity__c = 0,
          SBQQ__UpgradedQuantity__c = 0,
          SBQQ__Product__c = lstProducts[11].Id,
          SBQQ__PricebookEntryId__c = lstPricebooks[0].Id,
          SBQQ__Quantity__c = 600,
          TPH_Quantity__c = '40',
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          RWD_Deal_Ops_Exception__c = 'RCDM-T Manual Extension' /*, Arroyo_Subsumed_Old_Contract_Line_Items__c = lstCli[0].Id+','+lstCli[0].Id*/
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          Prepayment_Credit__c = 1000.00,
          Replacement_Details__c = replaceDet,
          Arroyo_Subsumed_Old_Contract_Line_Items__c = cli.id,
          SBQQ__Quote__c = lstQuoteRecords[0].Id,
          TPH_Quantity__c = '5',
          SBQQ__Product__c = lstProducts[12].Id,
          SBQQ__Quantity__c = 70,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__StartDate__c = System.today(),
          SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
          SBQQ__DefaultSubscriptionTerm__c = 12,
          Licensing_Model__c = 'Subscription',
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          Prepayment_Credit__c = 1000.00,
          Replacement_Details__c = replaceDet,
          Arroyo_Subsumed_Old_Contract_Line_Items__c = cli.id,
          SBQQ__Quote__c = lstQuoteRecords[1].Id,
          SBQQ__PriorQuantity__c = 0,
          SBQQ__UpgradedQuantity__c = 0,
          SBQQ__Product__c = lstProducts[13].Id,
          SBQQ__PricebookEntryId__c = lstPricebooks[0].Id,
          SBQQ__Quantity__c = 600,
          TPH_Quantity__c = '40',
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Arroyo_Subscribed_Asset_Name__c = 'AAA8976565434',
          SubscribedAssetNames__c = 'AAA8976565434'
        )
      );

      lines.add(
        new SBQQ__QuoteLine__c(
          Prepayment_Credit__c = 1000.00,
          Replacement_Details__c = replaceDet,
          Arroyo_Subsumed_Old_Contract_Line_Items__c = cli.id,
          SBQQ__Quote__c = lstQuoteRecords[1].Id,
          SBQQ__PriorQuantity__c = 0,
          SBQQ__UpgradedQuantity__c = 0,
          SBQQ__Product__c = lstProducts[13].Id,
          SBQQ__PricebookEntryId__c = lstPricebooks[0].Id,
          SBQQ__Quantity__c = 500,
          TPH_Quantity__c = '50',
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Arroyo_Subscribed_Asset_Name__c = 'AAA8976565434',
          SubscribedAssetNames__c = 'AAA8976565434'
        )
      );
        insert lines;

        lines[0].SBQQ__Bundle__c = true;
        lines[1].SBQQ__RequiredBy__c = lines[0].Id;
        lines[2].SBQQ__RequiredBy__c = lines[0].Id;
        lines[3].SBQQ__RequiredBy__c = lines[0].Id;
      lines[15].SBQQ__RequiredBy__c = lines[14].Id;  
        update lines;
        
        List<Asset> lstAsset = new List<Asset>{
        new Asset(
          Name = 'AA204063040011',
          serial_number__c = 'AA204063040011',
          SerialNumber = 'AA204063040011',
          AccountId = acct.Id,
          Product2Id = lstProducts[3].id,
          SBQQ__QuoteLine__c = lines[3].Id
        ),
        new Asset(
          Name = 'AA204063040012',
          serial_number__c = 'AA204063040012',
          SerialNumber = 'AA204063040012',
          AccountId = acct.Id,
          Product2Id = lstProducts[5].id,
          SBQQ__QuoteLine__c = lines[4].Id
        ),
        new Asset(
          Name = 'AA204063040013',
          serial_number__c = 'AA204063040013',
          SerialNumber = 'AA204063040013',
          AccountId = acct.Id,
          Product2Id = lstProducts[6].id,
          SBQQ__QuoteLine__c = lines[5].Id
        ),
        new Asset(
          Name = 'AA204063040014',
          serial_number__c = 'AA204063040014',
          SerialNumber = 'AA204063040014',
          AccountId = acct.Id,
          Product2Id = lstProducts[4].id,
          SBQQ__QuoteLine__c = lines[6].Id
        ),
        new Asset(
          Name = 'AA204063040015',
          serial_number__c = 'AA204063040015',
          SerialNumber = 'AA204063040015',
          AccountId = acct.Id,
          Product2Id = lstProducts[7].id,
          SBQQ__QuoteLine__c = lines[7].Id
        ),
        new Asset(
          Name = 'AA204063040016',
          serial_number__c = 'AA204063040016',
          SerialNumber = 'AA204063040016',
          AccountId = acct.Id,
          Product2Id = lstProducts[12].id,
          SBQQ__QuoteLine__c = lines[12].Id
        ),
        new Asset(Name = 'AAA8976565434', serial_number__c = 'AAA8976565434', SerialNumber = 'AAA8976565434', AccountId = acct.Id, Product2Id = lstProducts[8].id)
      };

      insert lstAsset;

      //0
      Order objOrd = new Order(
        Type = 'Revenue',
        AccountId = acct.Id,
        OpportunityId = lstOpportunitiesRecords[0].Id,
        ShippingStreet = 'Test Street',
        ShippingCity = 'Test City',
        ShippingState = 'California',
        ShippingCountry = 'United States',
        ShippingPostalcode = '94820',
                            Order_Sub_Type__c = 'Renewal',
                            SBQQ__Quote__c = lstQuoteRecords[0].id,
                            Is_RWD_Polaris_Quote__c = true,   
                            EffectiveDate = System.today(), 
                            Order_Status__c = 'Pending',
        Order_Accepted_Timestamp__c = null,
        Status = 'Draft',
        ProcessType__c = 'Aspen'
      );

      insert objOrd;
    
      Order objOrd1 = new Order(
        AccountId = acct.Id,
        ProcessType__c = 'Aspen',
        OpportunityId = lstOpportunitiesRecords[1].Id,
        SBQQ__Quote__c = lstQuoteRecords[1].Id,
        EffectiveDate = System.today().addDays(2),
        Status = 'Draft',
        Type = 'Revenue',
        Order_Status__c = 'Pending',
        Is_RWD_Polaris_Quote__c = true,
        Order_Sub_Type__c = Constants.ORDER_SUB_TYPE_GC_OFFER
      );
    insert objOrd1;
                    
      Order objOrd2 = new Order(
        AccountId = acct.Id,
        ProcessType__c = 'Aspen',
        OpportunityId = lstOpportunitiesRecords[1].Id,
        SBQQ__Quote__c = lstQuoteRecords[2].Id,
        EffectiveDate = System.today().addDays(3),
        Status = 'Draft',
        Type = 'Revenue',
        Order_Status__c = 'Pending',
        Is_RWD_Polaris_Quote__c = true,
        Order_Sub_Type__c = Constants.ORDER_SUB_TYPE_GC_OFFER
      );
    insert objOrd2;
   
      Order objOrd3 = new Order(
        AccountId = acct.Id,
        ProcessType__c = 'Aspen',
        OpportunityId = lstOpportunitiesRecords[1].Id,
        SBQQ__Quote__c = lstQuoteRecords[3].Id,
        EffectiveDate = System.today().addDays(3),
        Status = 'Draft',
        Type = 'Revenue',
        Order_Status__c = 'Pending',
        Is_RWD_Polaris_Quote__c = true
      );
    insert objOrd3;
      Set<Id> setOrderId = new Set<Id>{ objOrd.Id, objOrd1.Id, objOrd2.Id, objOrd3.Id };
      List<Order> lstOrderToUpdate = [SELECT Id, Pricebook2Id FROM Order WHERE Id IN :setOrderId];
      lstOrderToUpdate[0].Pricebook2Id = standardPriceBookId;
      lstOrderToUpdate[1].Pricebook2Id = standardPriceBookId;
      lstOrderToUpdate[2].Pricebook2Id = standardPriceBookId;
      lstOrderToUpdate[3].Pricebook2Id = standardPriceBookId;

                    update lstOrderToUpdate;
                    
                        List<ServiceContract> lstSCRecords = new List<ServiceContract>{
        new ServiceContract(
          Name = 'Test opp - 30 Sept - Contract',
          AccountId = acct.Id,
          SBQQSC__Order__c = objOrd.Id,
          SBQQSC__Quote__c = lstQuoteRecords[0].Id,
          Pricebook2Id = Test.getStandardPricebookId(),
          Term = 36,
          StartDate = System.Today(),
          EndDate = System.today().addMonths(36)
        ),
                //TPH
        new ServiceContract(
          Name = 'ServiceContractTest2',
          AccountId = acct.Id,
          StartDate = Date.today(),
          Term = 36,
          pricebook2Id = Test.getStandardPricebookId(),
          SBQQSC__Opportunity__c = lstOpportunitiesRecords[1].Id,
          SBQQSC__Order__c = objOrd1.Id,
          SBQQSC__Quote__c = lstQuoteRecords[1].Id
        )
            };
            
            insert lstSCRecords;        
        List<ContractLineItem> cliList = new List<ContractLineItem>{
        new ContractLineItem(
          ServiceContractId = lstSCRecords[0].Id,
          SBQQSC__QuoteLine__c = lines[1].Id,
          SBQQSC__Account__c = acct.Id,
          SBQQSC__Product__c = lstProducts[1].Id,
          MSP_Segment_Product__c = true,
          PricebookEntryId = lstPricebooks[1].Id,
          Quantity = 10,
          UnitPrice = lstPricebooks[1].UnitPrice
        ),
        new ContractLineItem(
          ServiceContractId = lstSCRecords[0].Id,
          SBQQSC__QuoteLine__c = lines[2].Id,
          SBQQSC__Account__c = acct.Id,
          SBQQSC__Product__c = lstProducts[2].Id,
          MSP_Segment_Product__c = true,
          PricebookEntryId = lstPricebooks[2].Id,
          Quantity = 10,
          UnitPrice = lstPricebooks[2].UnitPrice
        ),
        new ContractLineItem(
          ServiceContractId = lstSCRecords[0].Id,
          SBQQSC__QuoteLine__c = lines[3].Id,
          SBQQSC__Account__c = acct.Id,
          SBQQSC__Product__c = lstProducts[3].Id,
          MSP_Segment_Product__c = true,
          PricebookEntryId = lstPricebooks[3].Id,
          Quantity = 10,
          UnitPrice = lstPricebooks[3].UnitPrice
        ),
        new ContractLineItem(
          Quantity = 10,
          PricebookEntryId = lstPricebooks[9].Id,
          ServiceContractId = lstSCRecords[1].Id,
          UnitPrice = lstPricebooks[9].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          ServiceContractId = lstSCRecords[0].Id,
          SBQQSC__QuoteLine__c = lines[4].Id,
          SBQQSC__Account__c = acct.Id,
          SBQQSC__Product__c = lstProducts[4].Id,
          MSP_Segment_Product__c = true,
          PricebookEntryId = lstPricebooks[4].Id,
          Quantity = 10,
          UnitPrice = lstPricebooks[4].UnitPrice
        ),
        new ContractLineItem(
          ServiceContractId = lstSCRecords[0].Id,
          SBQQSC__QuoteLine__c = lines[12].Id,
          SBQQSC__Account__c = acct.Id,
          SBQQSC__Product__c = lstProducts[12].Id,
          MSP_Segment_Product__c = true,
          PricebookEntryId = lstPricebooks[12].Id,
          Quantity = 10,
          UnitPrice = lstPricebooks[12].UnitPrice
        )
            };
 
        insert cliList;
        Test.stopTest();
      lines[9].Arroyo_Subsumed_Old_Contract_Line_Items__c = cliList[3].Id + ',' + cliList[3].Id;
        update lines[9];
       
      List<OrderItem> lstOrderItems = new List<OrderItem>{
        //0
        new OrderItem(
          OrderId = objOrd.Id,
          Credit_Amount__c = 1000.00,
          Product2Id = lstProducts[0].Id,
          Quantity = 5,
          PricebookEntryId = lstPricebooks[0].Id,
          UnitPrice = lstPricebooks[0].UnitPrice,
          SerialNumber__c = 'AA204063040011',
          Support_End_Date__c = System.Today().addYears(1),
          Support_Start_Date__c = System.Today(),
          SBQQ__QuoteLine__c = lines[0].Id
        ),
        //1
        new OrderItem(
          OrderId = objOrd.Id,
          Credit_Amount__c = 1000.00,
          SBQQ__QuoteLine__c = lines[1].Id,
          SBQQ__SegmentIndex__c = 1,
          Support_Start_Date__c = System.Today(),
          Support_End_Date__c = System.Today().addYears(1),
          Product2Id = lstProducts[1].Id,
          Quantity = 1,
          PricebookEntryId = lstPricebooks[1].Id,
          UnitPrice = lstPricebooks[1].UnitPrice,
          SerialNumber__c = 'Test1234567Asset'
        ),
        //2
        new OrderItem(
          SBQQ__SegmentIndex__c = 1,
          Credit_Amount__c = 1000.00,
          SBQQ__QuoteLine__c = lines[1].Id,
          Support_Start_Date__c = System.Today(),
          Support_End_Date__c = System.Today().addYears(1),
          OrderId = objOrd.Id,
          SerialNumber__c = 'Test1234567Asset3',
          UnitPrice = lstPricebooks[2].UnitPrice,
          Product2Id = lstProducts[2].Id,
          PricebookEntryId = lstPricebooks[2].Id,
          Quantity = 5
        ),
        /*SKU-104*/ //3
        new OrderItem(
          Support_End_Date__c = System.Today().addYears(1),
          Credit_Amount__c = 1000.00,
          Support_Start_Date__c = System.Today(),
          PricebookEntryId = lstPricebooks[3].Id,
          UnitPrice = lstPricebooks[3].UnitPrice,
          SerialNumber__c = 'Test1234567Asset104',
          SBQQ__QuoteLine__c = lines[3].Id,
          SBQQ__SegmentIndex__c = 1,
          OrderId = objOrd.Id,
          Quantity = 5,
          Product2Id = lstProducts[3].Id
        ),
        //4
        new OrderItem(
          SBQQ__SegmentIndex__c = 1,
          Credit_Amount__c = 1000.00,
          SBQQ__QuoteLine__c = lines[4].Id,
          Support_End_Date__c = System.Today().addYears(1),
          Support_Start_Date__c = System.Today(),
          OrderId = objOrd.Id,
          SerialNumber__c = 'Test1234567Asset104',
          Quantity = 5,
          Product2Id = lstProducts[5].Id,
          PricebookEntryId = lstPricebooks[5].Id,
          UnitPrice = lstPricebooks[5].UnitPrice
        ),
        //5
        new OrderItem(
          SerialNumber__c = 'Test1234567Asset104',
          Credit_Amount__c = 1000.00,
          UnitPrice = lstPricebooks[6].UnitPrice,
          OrderId = objOrd.Id,
          Quantity = 5,
          Product2Id = lstProducts[6].Id,
          PricebookEntryId = lstPricebooks[6].Id,
          Support_End_Date__c = System.Today().addYears(1),
          Support_Start_Date__c = System.Today(),
          SBQQ__QuoteLine__c = lines[5].Id,
          SBQQ__SegmentIndex__c = 1
        ),
        //6
        new OrderItem(
          OrderId = objOrd.Id,
          Credit_Amount__c = 1000.00,
          Support_End_Date__c = System.Today().addYears(1),
          SBQQ__QuoteLine__c = lines[6].Id,
          SerialNumber__c = 'Test1234567Asset104',
          UnitPrice = lstPricebooks[4].UnitPrice,
          PricebookEntryId = lstPricebooks[4].Id,
          Support_Start_Date__c = System.Today(),
          SBQQ__SegmentIndex__c = 1,
          Quantity = 5,
          Product2Id = lstProducts[4].Id
        ),
        //7
        new OrderItem(
          OrderId = objOrd.Id,
          Credit_Amount__c = 1000.00,
          SBQQ__QuoteLine__c = lines[7].Id,
          SBQQ__SegmentIndex__c = 1,
          Support_End_Date__c = System.Today().addYears(1),
          Support_Start_Date__c = System.Today(),
          SerialNumber__c = 'Test1234567Asset105',
          UnitPrice = lstPricebooks[7].UnitPrice,
          PricebookEntryId = lstPricebooks[7].Id,
          Product2Id = lstProducts[7].Id,
          Quantity = 5
        ),
        //TPH8
        new OrderItem(
          OrderId = objOrd3.Id,
          Credit_Amount__c = 1000.00,
          Product2Id = lstProducts[10].Id,
          UnitPrice = lstPricebooks[10].UnitPrice,
          SBQQ__QuoteLine__c = lines[11].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Previous_Contract_Line_Items__c = cliList[0].id,
          Quantity = 500,
          PricebookEntryId = lstPricebooks[10].Id
        ),
        new OrderItem(
          OrderId = objOrd3.Id,
          Credit_Amount__c = 1000.00,
          Product2Id = lstProducts[11].Id,
          UnitPrice = lstPricebooks[11].UnitPrice,
          SBQQ__QuoteLine__c = lines[12].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Quantity = 500,
          PricebookEntryId = lstPricebooks[11].Id
        ),
        new OrderItem(
          OrderId = objOrd3.Id,
          Credit_Amount__c = 1000.00,
          Product2Id = lstProducts[12].Id,
          UnitPrice = lstPricebooks[12].UnitPrice,
          SBQQ__QuoteLine__c = lines[12].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Quantity = 500,
          PricebookEntryId = lstPricebooks[12].Id
        )
      };
      insert lstOrderItems;

        List<Entitlement> entitlementList = new List<Entitlement>();

      for (contractlineItem cliRec : cliList) {
            Entitlement ent = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            //Entitlement ent = new Entitlement();
        ent.Name = 'Product SKU-104';
            ent.AccountId = acct.Id;
            ent.StartDate = Date.today().addDays(-365);
            ent.EndDate = Date.today().addDays(365);
            ent.ContractLineItemId = cliRec.id;
        if (cli.SBQQSC__Product__c == lstProducts[12].Id) {
                 ent.Product__c = lstProducts[12].id;
        } else {
                 ent.Product__c = lstProducts[3].id;
            }
            ent.Assetid = lstAsset[0].id;
        // ent.Order_Service_Item__c = lstOrderItems[3].id;
            entitlementList.add(ent);
        }
        Entitlement ent = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        //Entitlement ent = new Entitlement();
      ent.Name = 'Product SKU-104';
        ent.AccountId = acct.Id;
        ent.StartDate = Date.today().addDays(-365);
        ent.EndDate = Date.today().addDays(365);
        ent.ContractLineItemId = cliList[0].id;
        ent.Product__c = lstProducts[3].id;
        ent.Assetid = lstAsset[0].id;
        //ent.Order_Service_Item__c = lstOrderItems[3].id;
        entitlementList.add(ent);
        
        Entitlement ent1 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        //Entitlement ent = new Entitlement();
      ent1.Name = 'Product SKU-104';
        ent1.AccountId = acct.Id;
        ent1.StartDate = Date.today().addDays(-365);
        ent1.EndDate = Date.today().addDays(365);
        ent1.ContractLineItemId = cliList[0].id;
        ent1.Product__c = lstProducts[4].id;
        ent1.Assetid = lstAsset[0].id;
      //ent1.Order_Service_Item__c = lstOrderItems[4].id;
        entitlementList.add(ent1);
        
        Entitlement ent2 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        //Entitlement ent = new Entitlement();
      ent2.Name = 'Product SKU-104';
        ent2.AccountId = acct.Id;
        ent2.StartDate = Date.today().addDays(-365);
        ent2.EndDate = Date.today().addDays(365);
        ent2.ContractLineItemId = cliList[0].id;
        ent2.Product__c = lstProducts[5].id;
        ent2.Assetid = lstAsset[0].id;
      //ent2.Order_Service_Item__c = lstOrderItems[5].id;
        entitlementList.add(ent2);
        
        Entitlement ent3 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        //Entitlement ent = new Entitlement();
      ent3.Name = 'Product SKU-104';
        ent3.AccountId = acct.Id;
        ent3.StartDate = Date.today().addDays(-365);
        ent3.EndDate = Date.today().addDays(365);
        ent3.ContractLineItemId = cliList[0].id;
        ent3.Product__c = lstProducts[6].id;
        ent3.Assetid = lstAsset[1].id;
      //ent3.Order_Service_Item__c = lstOrderItems[6].id;
        entitlementList.add(ent3);
        
        Entitlement ent4 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        //Entitlement ent = new Entitlement();
      ent4.Name = 'Product SKU-104';
        ent4.AccountId = acct.Id;
        ent4.StartDate = Date.today().addDays(-365);
        ent4.EndDate = Date.today().addDays(365);
        ent4.ContractLineItemId = cliList[0].id;
        ent4.Product__c = lstProducts[6].id;
        ent4.Assetid = lstAsset[2].id;
      //ent4.Order_Service_Item__c = lstOrderItems[6].id;
        entitlementList.add(ent4);
        
        Entitlement ent5 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        //Entitlement ent = new Entitlement();
      ent5.Name = 'Product SKU-104';
        ent5.AccountId = acct.Id;
        ent5.StartDate = Date.today().addDays(-365);
        ent5.EndDate = Date.today().addDays(365);
        ent5.ContractLineItemId = cliList[0].id;
        ent5.Product__c = lstProducts[4].id;
        ent5.Assetid = lstAsset[3].id;
      //ent5.Order_Service_Item__c = lstOrderItems[4].id;
        entitlementList.add(ent5);
        
        Entitlement ent6 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        //Entitlement ent = new Entitlement();
      ent6.Name = 'Product SKU-104';
        ent6.AccountId = acct.Id;
        ent6.StartDate = Date.today().addDays(-365);
        ent6.EndDate = Date.today().addDays(365);
        ent6.ContractLineItemId = cliList[0].id;
        ent6.Product__c = lstProducts[7].id;
        ent6.Assetid = lstAsset[4].id;
      //ent6.Order_Service_Item__c = lstOrderItems[7].id;
        entitlementList.add(ent6);
                    
        Id supportRecordTypeId = Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Support').getRecordTypeId();
      Entitlement entTPH = new Entitlement(
        Name = lstProducts[9].ProductCode,
        RecordTypeId = supportRecordTypeId,
        Type = 'Phone Support',
        AccountId = acct.Id,
        Product__c = lstProducts[9].Id,
        StartDate = date.today(),
        AssetId = lstAsset[5].Id,
        ServiceContractId = lstSCRecords[1].Id,
        ContractLineItemId = cliList[3].Id
      );

          entitlementList.add(entTPH);  
            insert entitlementList;
       
        cliList[0].SBQQSC__OrderProduct__c = lstOrderItems[0].Id;
        cliList[1].SBQQSC__OrderProduct__c = lstOrderItems[1].Id;
        cliList[2].SBQQSC__OrderProduct__c = lstOrderItems[3].Id;       
        cliList[3].Quantity = lstOrderItems[8].quantity;     
        cliList[5].SBQQSC__OrderProduct__c = lstOrderItems[10].Id;
        update cliList;
        
      entitlementList[7].Order_Service_Item__c = lstOrderItems[8].Id;
        update entitlementList[7];
                }
        
    }
    @isTest
  private static void testOrderItemServiceMethod1() {
    user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com.invalid' LIMIT 1];

      System.runAs(usr1) {
          test.startTest();
      List<SBQQ__Quote__c> lstQuote = [SELECT Id, SBQQ__ContractingMethod__c FROM SBQQ__Quote__c LIMIT 1];
      List<Asset> lstAsset = [SELECT Id, Serial_Number__c, SerialNumber FROM Asset WHERE SerialNumber IN ('AA204063040011', 'AA204063040012', 'AA204063040013')];
           
      List<Order> lstOrder = [
        SELECT Id, SBQQ__ContractingMethod__c, Polaris_Fulfillment_Status__c, Status, SBQQ__Quote__c, Order_Status__c
        FROM Order
        WHERE SBQQ__Quote__c = :lstQuote[0].Id
      ];
            List<OrderItem> lstOrderItem1 = [SELECT Id, Support_End_Date__c  FROM OrderItem LIMIT 10];
      List<ContractLineItem> lstofcli = [SELECT id FROM ContractLineItem LIMIT 10];
      lstQuote[0].ApprovalStatus__c = 'Approved';
      lstQuote[0].Is_RWD_Polaris_Quote__c = false;
      update lstQuote[0];
      Order_Item_Extension__c lstOIEToInsert = new Order_Item_Extension__c(
        OI_ExternalID__c = lstOrderItem1[0].Id,
        Order_Line_ID__c = lstOrderItem1[0].Id,
        Paid_Quantity__c = 3,
        Credit_Calculation_Status__c = 'To Process',
        End_of_Paid_Term__c = System.today().addYears(2)
      );
            insert lstOIEToInsert;
          lstOrder[0].Is_RWD_Polaris_Quote__c = false;
          lstOrder[0].Pricebook2Id = Test.getStandardPricebookId();
          update lstOrder[0];
      for (Asset ast : lstAsset) {
              ast.Order_Service_Item__c = lstOrderItem1[1].Id;
        if (ast.SerialNumber == 'AA204063040014') {
                  ast.Order_Service_Item__c = lstOrderItem1[3].Id;
              }
          }
          update lstAsset;
      lstOrderItem1[1].Previous_Transaction_Reference__c =
        '[{"usedEntitlementQuantity":60.00,"phantomOrderItemId":null,"orderItemId":' +
        lstOrderItem1[0].Id +
        ',"orderItemRemainingQuantity":20.00,"entId":"5508Y000005cMw0QAE"}]';
            lstOrderItem1[1].SBQQSC__ContractLineItem__c = lstofcli[0].id;
      lstOrderItem1[1].SBQQ__RequiredBy__c = lstOrderItem1[0].Id;
            
      lstOrderItem1[3].Previous_Transaction_Reference__c =
        '[{"usedEntitlementQuantity":60.00,"phantomOrderItemId":null,"orderItemId":' +
        lstOrderItem1[1].Id +
        ',"orderItemRemainingQuantity":20.00,"entId":"5508Y000005cMw0QAE"}]';
            lstOrderItem1[3].SBQQSC__ContractLineItem__c = lstofcli[3].id;
           update lstOrderItem1;
          test.stopTest();
         system.assert(!lstOrderItem1.isempty());
      }

  }

  private static testMethod void testOrderItemService() {
    user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com.invalid' LIMIT 1];
        System.runAs(usr1) {
        test.startTest();
      List<OrderItem> lstOrderItem = [
        SELECT Id, ServiceDate, Support_Start_Date__c, product2.productcode
        FROM OrderItem
        WHERE product2.Productcode IN ('RBK-SVC-PREM-OBJ-STORAGE', 'Product SKU-104')
        LIMIT 10
      ];
      List<Order> ordList = [SELECT Id, Is_RWD_Polaris_Quote__c FROM Order LIMIT 1];
      //  List<Product2> prodLst = [select Id, Name, ProductCode from Product2 Limit 4];
      List<Asset> lstAsset = [SELECT Id, Serial_Number__c, SerialNumber FROM Asset WHERE SerialNumber IN ('AA204063040011', 'AA204063040012', 'AA204063040013')];
      List<ContractLineItem> lstofcli = [
        SELECT id, SBQQSC__OrderProduct__r.Product_Code_Formula__c
        FROM ContractLineItem
        /* where SBQQSC__OrderProduct__r.Product_Code_Formula__c IN ('RBK-SVC-PREM-OBJ-STORAGE', 'Product SKU-104')*/ LIMIT 10
      ];
       
      List<OrderItem> lstOIToupdate = new List<OrderItem>();
        
        List<OrderItem> v1skuOI = new List<OrderItem>();
        List<OrderItem> v2skuOI = new List<OrderItem>();
        List<Contractlineitem> v1cli = new List<Contractlineitem>();
        List<Contractlineitem> v2cli = new List<Contractlineitem>();
      for (OrderItem oi : lstOrderItem) {
        if (oi.product2.productcode == 'RBK-SVC-PREM-OBJ-STORAGE') {
                    v1skuOI.add(oi);
        } else {
                    v2skuOI.add(oi);
                }
            }
      for (Contractlineitem cli : lstofcli) {
        if (cli.SBQQSC__OrderProduct__r.Product_Code_Formula__c == 'RBK-SVC-PREM-OBJ-STORAGE') {
                    v1cli.add(cli);
        } else {
                    v2cli.add(cli);
                }
            }
      for (Asset ast : lstAsset) {
                ast.Order_Service_Item__c = v1skuOI[0].Id;
                /*if(ast.SerialNumber == 'AA204063040014'){
                    ast.Order_Service_Item__c = lstOrderItem1[3].Id;
                    }*/
            }
        update lstAsset;
        v1skuOI[0].SerialNumber__c = null;
        v1skuOI[0].SBQQSC__ContractLineItem__c = v1cli[0].id;
        v1skuOI[0].SBQQ__RequiredBy__c = v2skuOI[0].Id;
      v1skuOI[0].servicedate = system.today();

        v2skuOI[0].SerialNumber__c = 'AA204063040013';
        v2skuOI[0].SBQQSC__ContractLineItem__c = v2cli[0].id;
        v2skuOI[0].SBQQ__RequiredBy__c = v2skuOI[1].Id;

      v2skuOI[1].Engagement_Date__c = date.newInstance(2021, 1, 1);
        v2skuOI[1].SerialNumber__c = 'AA204063040012'; 
        v2skuOI[1].SBQQ__RequiredBy__c = v2skuOI[2].Id;
        v2skuOI[1].SBQQSC__ContractLineItem__c = v2cli[0].id;
        lstOIToupdate.addall(v1skuOI);
        lstOIToupdate.addall(v2skuOI);

        ordList[0].Is_RWD_Polaris_Quote__c =  false;
        update ordList;
       
        update lstOIToupdate;
        
        test.stopTest();
      system.assertEquals(lstOIToupdate[0].ServiceDate, [SELECT Id, Support_Start_Date__c, Quantity FROM OrderItem WHERE Id = :lstOIToupdate[0].Id].Support_Start_Date__c);
        }
    }
    
  private static testMethod void testPhantomOrders() {
    user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com.invalid' LIMIT 1];
        System.runAs(usr1) {
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true; 
      List<Order> lstofOrder = [SELECT id, Ordernumber FROM order LIMIT 1];
        
      List<OrderItem> lstOrderItems = [
        SELECT
          Id,
          Order.AccountId,
          Order.SBQQ__Quote__c,
          Order.OpportunityId,
          SerialNumber__c,
          SBQQ__QuoteLine__c,
          SBQQ__QuoteLine__r.Replacement_Details__c,
          SBQQ__QuoteLine__r.Arroyo_Subscribed_Asset_Name__c
        FROM OrderItem
        LIMIT 10
      ];
      String recordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Phantom Order').getRecordTypeId();
      Map<String, Object> OrderMap = new Map<String, Object>{
            'Type' => 'Revenue Internal',
            'recordTypeId' => recordTypeId,
            'AccountId' => lstOrderItems[0].order.AccountId,
            'OpportunityId' => lstOrderItems[0].order.OpportunityId,
            'Sync_to_NetSuite__c' => true,
            'EffectiveDate' => system.today(),
            'Status' => 'Pending',
        'Bill_To_Name__c' => lstOrderItems[0].order.AccountId,
        'SBQQ__Quote__c' => lstOrderItems[0].Order.SBQQ__Quote__c,
        'Line_Types__c' => 'Partial Surviving'
            };
      List<PricebookEntry> lstofpricebookentry = [SELECT id, Pricebook2Id, Product2Id, UnitPrice, IsActive FROM PricebookEntry];
        Order phantomOrd =  (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
        phantomOrd.Type = 'Revenue Internal';
        phantomOrd.Associated_Order_Numbers__c = lstofOrder[0].Ordernumber;
        //lstofOrdToInsert.add(phantomOrd);
        insert phantomOrd;
        Test.startTest();
        //List<Order> phantOrd = [Select id,Ordernumber from order where Order_Sub_type__c = 'Surviving Partial' limit 1];
        lstofOrder[0].order_sub_type__c = 'Replacement';
        //lstofOrder[0].Associated_Order_Numbers__c  = phantOrd[0].Ordernumber;
      List<Entitlement> lstofEnt = [SELECT id, Order_Service_Item__c FROM Entitlement WHERE Order_Service_Item__c != NULL LIMIT 1];
        
      OrderItem oiToUpdate = new OrderItem(Id = lstofEnt[0].Order_Service_Item__c, Support_Start_Date__c = System.today(), Support_End_Date__c = System.today().addDays(180));
         update oiToUpdate;
            
      OrderItem phantomoi = new OrderItem(
        SBQQ__QuotedQuantity__c = 10,
        OrderId = phantomOrd.Id,
        Quantity = 10,
        PricebookEntryId = lstofpricebookentry[0].id,
        unitprice = lstofpricebookentry[0].unitprice,
        Sales_Price__c = lstofpricebookentry[0].unitprice
      );
      phantomoi.Previous_Transaction_Reference__c = '{\"orderItemId\":\"' + lstofEnt[0].Order_Service_Item__c + '\",\"entId\":\"' + lstofEnt[0].id + '\"}';
        phantomoi.Support_Start_Date__c = system.today();
        phantomoi.Support_End_Date__c = system.today().addMonths(1).addDays(-1);
        phantomoi.orderid = phantomOrd.Id;
        insert phantomoi;
        
      List<OrderItem> phantOIToUpdate = [SELECT id, Support_Start_Date__c, Support_End_Date__c FROM orderitem WHERE order.Type = 'Revenue Internal'];
      phantOIToUpdate[0].Support_Start_Date__c = system.today().addDays(1);
      phantOIToUpdate[0].Support_End_Date__c = system.today().addDays(1).addMonths(1).addDays(-1);
        update phantOIToUpdate;
         
       // SplitOrder.hasPreValidatedSN = true;
        
      if (!lstofOrder.isEmpty()) {
            update lstofOrder;
        }
      if (!lstOrderItems.isEmpty()) {
            update lstOrderItems;
        }
        System.assert(phantomoi.Id != null);
        Test.stopTest();
    }
        }
   
  @isTest
  private static void testRefreshAndReplacementOI1() {
    user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com.invalid' LIMIT 1];
      
      System.runAs(usr1) {
          test.startTest();
          List<Scale_Entitlement__c> linkedAssetToInsert = new List<Scale_Entitlement__c>();
      List<Entitlement> entList = [SELECT id, ContractLineItemId, Order_Service_Item__c FROM Entitlement];
          
          List<SBQQ__Quote__c> lstQuote = [SELECT Id, SBQQ__ContractingMethod__c FROM SBQQ__Quote__c LIMIT 1];
          List<Asset> lstAsset = [SELECT Id, Serial_Number__c, SerialNumber FROM Asset WHERE SerialNumber IN ('AA204063040011', 'AA204063040012', 'AA204063040013')];
      for (Entitlement ent : entList) {
        linkedAssetToInsert.add(
          new Scale_Entitlement__c(
            Entitlement__c = ent.id,
            Contract_Line_Item__c = ent.ContractLineItemId,
            Order_Product__c = ent.Order_Service_Item__c,
            Asset__c = lstAsset[0].id,
            Type__c = 'Non-Scale'
          )
        );
              }
      insert linkedAssetToInsert;
      List<Order> lstOrder = [
        SELECT Id, SBQQ__ContractingMethod__c, Polaris_Fulfillment_Status__c, Status, SBQQ__Quote__c, Order_Status__c
        FROM Order
        WHERE SBQQ__Quote__c = :lstQuote[0].Id
      ];
      List<OrderItem> lstOrderItem1 = [SELECT Id, Support_End_Date__c FROM OrderItem LIMIT 10];
      List<ContractLineItem> lstofcli = [SELECT id FROM ContractLineItem LIMIT 10];
          lstQuote[0].ApprovalStatus__c = 'Approved';
          lstQuote[0].Is_RWD_Polaris_Quote__c = false;
          update lstQuote[0];
         Order_Item_Extension__c lstOIEToInsert = new Order_Item_Extension__c(
        OI_ExternalID__c = lstOrderItem1[0].Id,
        Order_Line_ID__c = lstOrderItem1[0].Id,
        Paid_Quantity__c = 3,
        Credit_Calculation_Status__c = 'To Process',
        End_of_Paid_Term__c = System.today().addYears(2)
      );
            insert lstOIEToInsert;
          lstOrder[0].Is_RWD_Polaris_Quote__c = false;
          lstOrder[0].Pricebook2Id = Test.getStandardPricebookId();
          update lstOrder[0];
          for (Asset ast : lstAsset) {
              ast.Order_Service_Item__c = lstOrderItem1[1].Id;
             if (ast.SerialNumber == 'AA204063040014') {
                  ast.Order_Service_Item__c = lstOrderItem1[3].Id;
              }
          }
          update lstAsset;
          
      lstOrderItem1[1].SerialNumber__c = 'AA204063040011,AA204063040012,AA204063040013';
      lstOrderItem1[1].Upgraded_From__c = 'TestAsset1,TestAset2';
      lstOrderItem1[1].Program__c = 'Conversion';
      lstOrderItem1[1].SBQQSC__ContractLineItem__c = lstofcli[0].id;
      lstOrderItem1[1].SBQQ__RequiredBy__c = lstOrderItem1[0].Id;

      lstOrderItem1[3].SerialNumber__c = 'AA204063040014';
      lstOrderItem1[3].Upgraded_From__c = 'TestAsset1,TestAset2';
      lstOrderItem1[3].Program__c = 'Conversion';
      lstOrderItem1[3].SBQQSC__ContractLineItem__c = lstofcli[3].id;
      lstOrderItem1[3].SBQQ__RequiredBy__c = lstOrderItem1[0].Id;

      lstOrderItem1[4].SerialNumber__c = null;
      lstOrderItem1[4].SBQQSC__ContractLineItem__c = lstofcli[2].id;
      lstOrderItem1[4].SBQQ__RequiredBy__c = lstOrderItem1[0].Id;

      lstOrderItem1[2].SerialNumber__c = null;
      lstOrderItem1[2].Upgraded_From__c = 'TestAsset1,TestAset2';
      lstOrderItem1[2].Program__c = 'Refresh';
      lstOrderItem1[2].SBQQSC__ContractLineItem__c = lstofcli[1].id;
      lstOrderItem1[2].Engagement_Date__c = date.newInstance(2021, 1, 1);
      update lstOrder[0];
      update lstOrderItem1;

      lstOrderItem1[2].SerialNumber__c = 'AA204063040015';

          update lstOrderItem1;
          
          test.stopTest();
         system.assert(!lstOrderItem1.isempty());
      }
      
    }
  @isTest
  private static void testNonAssetToAssetWithReplacement() {
    user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com.invalid' LIMIT 1];
  
    System.runAs(usr1) {
      test.startTest();
      List<Product2> lstofProducts = [SELECT id, Product_type__c, Product_Level__c FROM Product2];
      lstofProducts[0].Product_type__c = 'Hardware';
      lstofProducts[0].Product_Level__c = 'Hardware';

      lstofProducts[1].Product_type__c = 'HW Support';
      lstofProducts[1].Product_Level__c = 'Support';

      update lstofProducts;
      List<SBQQ__Quote__c> lstQuote = [SELECT Id, SBQQ__ContractingMethod__c FROM SBQQ__Quote__c LIMIT 1];
      List<Asset> lstAsset = [SELECT Id, Serial_Number__c, SerialNumber FROM Asset WHERE SerialNumber IN ('AA204063040011', 'AA204063040012', 'AA204063040013')];
      List<SBQQ__QuoteLine__c> lstofQli = [SELECT id FROM SBQQ__QuoteLine__c];

      List<Order> lstOrder = [
        SELECT Id, SBQQ__ContractingMethod__c, Polaris_Fulfillment_Status__c, Status, SBQQ__Quote__c, Order_Status__c
        FROM Order
        WHERE SBQQ__Quote__c = :lstQuote[0].Id
      ];
      List<OrderItem> queriedOi = new List<OrderItem>();
      List<OrderItem> lstofOrderitem = [SELECT id, SBQQ__QuoteLine__r.Replacement_Details__c FROM Orderitem];
      List<Entitlement> lstofEnt = [SELECT id, Order_Service_Item__c FROM Entitlement];
      for (OrderItem oi : lstofOrderitem) {
        if (oi.SBQQ__QuoteLine__r.Replacement_Details__c != null) {
          queriedOi.add(oi);
        }
      }
      for (Entitlement ent : lstofEnt) {
        ent.Order_Service_Item__c = queriedOi[0].id;
      }
      update lstofEnt;
      List<OrderItem> lstOrderItem1 = [
        SELECT
          Id,
          Program__c,
          SBQQ__QuoteLine__r.SBQQ__Quote__c,
          SerialNumber__c,
          product2.Product_Level__c,
          product2.Product_Type__c,
          product2.Product_Subtype__c,
          product2Id,
          Support_End_Date__c,
          SBQQ__QuoteLine__c,
          SBQQ__QuoteLine__r.Replacement_Details__c,
          Line_Type__c,
          (SELECT id, Name, AccountId FROM Entitlements__r)
        FROM OrderItem
      ];
      Map<Id, OrderItem> orderItemMap = new Map<Id, OrderItem>(lstOrderItem1);
      OrderItemTriggerHelper.mapOfIdtoOrderItem = orderItemMap;
      OrderItemTriggerHelper.createLinkedAssetForLicenseNonAssetToAsset(orderItemMap);
      List<OrderItem> orderItmwithReplacementDet = new List<OrderItem>();
      for (OrderItem oi : lstOrderItem1) {
        if (oi.SBQQ__QuoteLine__c != null && oi.SBQQ__QuoteLine__r.Replacement_Details__c != null) {
          orderItmwithReplacementDet.add(oi);
        }
      }
      OrderItemTriggerHelper.updateSerialNumOnLicenseLine(orderItmwithReplacementDet, true);
      List<ContractLineItem> lstofcli = [SELECT id FROM ContractLineItem LIMIT 10];
      lstQuote[0].ApprovalStatus__c = 'Approved';
      lstQuote[0].Is_RWD_Polaris_Quote__c = false;
      update lstQuote[0];
      Order_Item_Extension__c lstOIEToInsert = new Order_Item_Extension__c(
        OI_ExternalID__c = lstOrderItem1[0].Id,
        Order_Line_ID__c = lstOrderItem1[0].Id,
        Paid_Quantity__c = 3,
        Credit_Calculation_Status__c = 'To Process',
        End_of_Paid_Term__c = System.today().addYears(2)
      );
      insert lstOIEToInsert;
      SBQQ.TriggerControl.disable();
      lstOrder[0].Is_RWD_Polaris_Quote__c = false;
      lstOrder[0].Pricebook2Id = Test.getStandardPricebookId();
      lstOrder[0].SBQQ__Contracted__c = true;
      update lstOrder[0];
      for (Asset ast : lstAsset) {
        ast.Order_Service_Item__c = lstOrderItem1[1].Id;
        if (ast.SerialNumber == 'AA204063040014') {
          ast.Order_Service_Item__c = lstOrderItem1[3].Id;
        }
      }
      update lstAsset;
      for (orderItem oi : lstOrderItem1) {
        oi.SerialNumber__c = 'AA204063040011,AA204063040012,AA204063040013';
        if (oi?.Line_Type__c == 'New') {
          oi.SBQQ__Contracted__c = true;
        }
      }
      update lstOrderItem1;

      lstOrderItem1[0].SerialNumber__c = 'AA204063040014';
      update lstOrderItem1[0];
      SBQQ.TriggerControl.enable();
      test.stopTest();
      system.assert(!lstOrderItem1.isempty());
    }

  }
  
    @isTest
  private static void testReplacementmethods() {
    user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com.invalid' LIMIT 1];

    System.runAs(usr1) {
      List<OrderItem> lstofOrdItm = [SELECT id, SerialNumber__c FROM OrderItem];

      Set<Id> setofIdsToProcess = new Set<Id>();
      Map<Id, Set<String>> serialNumsByOrderItemId = new Map<Id, Set<String>>();
      Set<String> assetSerialNums = new Set<String>();
      Map<String, Asset> assetBySerialNum = new Map<String, Asset>();
      for (orderItem oi : lstofOrdItm) {
        setofIdsToProcess.add(oi.id);
        if (oi.SerialNumber__c != null) {
          assetSerialNums.addall(oi.SerialNumber__c.trim().split(','));
          serialNumsByOrderItemId.put(oi.id, assetSerialNums);
        }
      }

      List<Asset> lstAsset = [SELECT Id, Serial_Number__c, SerialNumber FROM Asset WHERE SerialNumber IN :assetSerialNums];
      for (Asset ast : lstAsset) {
        assetBySerialNum.put(ast.Serial_Number__c, ast);
      }
      OrderItemTriggerHelper.createScaleEntOnLicenses(setofIdsToProcess, serialNumsByOrderItemId, assetBySerialNum);
    }
  }

  @isTest
  private static void testPOCOrderTestMethod() {
    user usr = [SELECT Id FROM User WHERE email = 'testuser@testclass.com.invalid' LIMIT 1];

        System.runAs(usr) {
            test.startTest();       
        
      /*  Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            Account objAccount = new Account(Name = 'POC Account',recordtypeId = partner,Phone = '123-456-7890',AccountNumber = 'Test',BillingStreet = '123 street',BillingCity = 'Santa Clara',BillingState = 'California',BillingPostalCode = '95050',BillingCountry = 'United States',ShippingStreet = '123 street',ShippingCity = 'Santa Clara',ShippingState = 'California',ShippingPostalCode = '95050',ShippingCountry = 'United States');
            insert objAccount;
        
        Opportunity opp = TestDataFactory.getOpportunity();
            opp.Partner_Lookup__c = objAccount.Id;
            opp.AccountId = objAccount.Id;
            opp.Distributor_Lookup__c = opp.AccountId;
            opp.Pricebook2id = Test.getStandardPricebookId();
            FlowControll.opportunityTriggerHandler = false;
            insert opp;
             FlowControll.opportunityTriggerHandler = true;*/
         List<Opportunity> lstOpportunity = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
            
        //Generate POC    
      Map<String, Object> pocMap = new Map<String, Object>{
            'POC_Duration__c' => '60 Days',
        'Planned_Installation_Date__c' => System.Today() + 30,
                'Support_Awareness_needed__c' => 'Yes'
                };
         POC__c poc1 = (POC__c) ShGl_TestFactory.createSObject(new POC__c(), pocMap);
        poc1.POC_Type__c = 'Standard POC';  
      poc1.Planned_Installation_Date__c = System.Today() + 40;
        poc1.Account__c = lstOpportunity[0].AccountId;
        poc1.Opportunity__c = lstOpportunity[0].Id;
      poc1.Most_Recent_End_Date__c = System.Today().addMonths(1);
        insert poc1;

      Order ordr = new Order(
        Type = 'POC',
        AccountId = lstOpportunity[0].AccountId,
        ShippingStreet = 'Test Street',
                               POC_Request__c = poc1.Id,
        ShippingCity = 'Test City',
        ShippingState = 'California',
        ShippingCountry = 'United States',
        ShippingPostalcode = '94820',
                            Order_Sub_Type__c = 'POC',
                            Is_RWD_Polaris_Quote__c = true,   
        EffectiveDate = date.Today(),
                            Order_Status__c = 'Pending',
        Status = 'Draft',
                            Pricebook2Id = Test.getStandardPricebookId(),
        RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order')?.getRecordTypeId()
      );
        insert ordr;
            
         List<Product2> sampleProducts = new List<Product2>{
                // 0
                new Product2(
                    Name = 'RS-BT-CVB-BS-PP',
                    ProductCode = 'RS-BT-CVB-BS-PP',
                    Category__c = 'Subscription',
                    Family = 'POLARIS',
                    Product_Type__c = 'Cloud Vault Backup',
                    License_Category__c = 'SaaS',
                    Product_Level__c = 'SaaS Software Addon',
                    SBQQ__AssetAmendmentBehavior__c = 'Default',
                    SBQQSC__EntitlementConversion__c = 'One per quote line',
                    IsActive = true,
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = null,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable'
        )
      };
                    insert sampleProducts;
            
      List<PricebookEntry> entries = new List<PricebookEntry>();
                   entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[0].Id, IsActive = true, UnitPrice = 100));
                 insert entries;
                
            List<OrderItem> orderItemList = new List<OrderItem>{
        new OrderItem(OrderId = ordr.Id, Product2Id = sampleProducts[0].Id, UnitPrice = entries[0].UnitPrice, Quantity = 600, PricebookEntryId = entries[0].Id)
            };
        //SBQQ__QuoteLine__c  objQLI = [SELECT Id, TPH_Quantity__c FROM SBQQ__QuoteLine__c LIMIT] 
         
        insert orderItemList;
        orderItemList[0].Quantity = 4;

        update orderItemList;
            
      system.assertEquals(1, [SELECT Id, SBQQ__SubscriptionTerm__c FROM OrderItem WHERE Id = :orderItemList[0].Id].SBQQ__SubscriptionTerm__c);
               
        Test.stopTest();
    }
            
  }
    
   @isTest
  private static void testTPHQuantity() {
    user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com.invalid' AND alias = 'std' LIMIT 1];

            System.runAs(usr1) {
            test.startTest();    
                
            Account objAccount = [SELECT Id FROM Account LIMIT 1];  
            List<Opportunity> lstOpp = [SELECT Id FROM Opportunity LIMIT 2];
      List<PricebookEntry> entries = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Product2.ProductCode = 'RS-BT-BE-RSCP-TPH-PE-PP' LIMIT 1];
      List<SBQQ__Quote__c> lstQuoteRecord = [SELECT Id, name FROM SBQQ__Quote__c LIMIT 3];
               
      List<SBQQ__QuoteLine__c> lines = [
        SELECT Id, TPH_Quantity__c, SBQQ__NetTotal__c, SBQQ__ProductCode__c, SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__NetPrice__c
        FROM SBQQ__QuoteLine__c
        WHERE SBQQ__Product__r.ProductCode = 'RS-BT-BE-RSCP-TPH-PE-PP' AND SBQQ__Quote__c = :lstQuoteRecord[2].Id
      ];
      List<Order> lstOrders = [SELECT Id FROM Order WHERE SBQQ__Quote__c = :lstQuoteRecord[2].Id];
                
      PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage(
        'Promark Technology, Inc.',
        'test123',
        system.today().addDays(10),
        2,
        'test@test.com',
        'test partner',
        system.today(),
        1,
        'test12345',
        lstQuoteRecord[0].name,
        lines[0].SBQQ__NetTotal__c
      );
      pos.Bill_To_Name__c = objAccount.Id;
            pos.Payment_schedule_type__c = 'test';
            pos.Expected_number_of_POs__c = 1;
            insert pos;

             PO_Item_Stage__c poItem = ShGl_TestFactoryHelper.createPOItem(
                                        '1234',
                                        '0001',
                                        lines[0].SBQQ__ProductCode__c,
                                        lines[0].SBQQ__Quantity__c,
                                        pos.Id,
                                        lines[0].SBQQ__SubscriptionTerm__c,
        lines[0].SBQQ__NetPrice__c
      );
            poItem.Quote_Line__c = lines[0].Id;

            insert poItem;
            OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = lstOpp[1].Id,
                Quantity = 600,
                PricebookEntryId = entries[0].Id,
                TotalPrice = 600 * entries[0].UnitPrice,
                SBQQ__QuoteLine__c = lines[0].Id
            );
            insert oli; 
            List<OrderItem> orderItemList = new List<OrderItem>{
        new OrderItem(
          OrderId = lstOrders[0].Id,
          UnitPrice = entries[0].UnitPrice,
          SerialNumber__c = 'ABCWEES',
          SBQQ__QuoteLine__c = lines[0].Id,
          SBQQ__SubscriptionTerm__c = 1,
          Quantity = 600,
          PricebookEntryId = entries[0].Id
        )
            };
            insert orderItemList;
            orderItemList[0].SerialNumber__c = '';
            orderItemList[0].Quantity = 500;

            lstOrders[0].Type = 'POC';
            SBQQ.TriggerControl.disable();
            
            update orderItemList;
                
            SBQQ.TriggerControl.enable();
      system.assertEquals(orderItemList[0].Quantity, [SELECT Id, SBQQ__OrderedQuantity__c, Quantity FROM OrderItem WHERE Id = :orderItemList[0].Id].SBQQ__OrderedQuantity__c);
            
            test.stopTest();       
        }

    }

    @isTest
    private static void testAssetAndEntitlement() {
    user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com.invalid' LIMIT 1];

            System.runAs(usr1) {
      List<Asset> lstAsset = [SELECT Id, Serial_Number__c, accountId, Order_Service_Item__c FROM Asset WHERE SerialNumber = 'AA204063040011'];
        lstAsset[0].AccountId = Label.Unassigned_Account_Id;
        update lstAsset[0];
        List<SBQQ__Quote__c> lstQuoteRec = [SELECT Id, SBQQ__ContractingMethod__c FROM SBQQ__Quote__c LIMIT 1];
        lstQuoteRec[0].SBQQ__ContractingMethod__c = 'By Subscription End Date';
        lstQuoteRec[0].ApprovalStatus__c = 'Approved';
        lstQuoteRec[0].Is_RWD_Polaris_Quote__c = false;
        update lstQuoteRec;
        List<Order> lstOrdersList = [SELECT Id, SBQQ__ContractingMethod__c FROM Order LIMIT 1];
        lstOrdersList[0].SBQQ__ContractingMethod__c = 'By Subscription End Date';
        lstOrdersList[0].Polaris_Fulfillment_Status__c = 'Completed';
        lstOrdersList[0].Status = 'Activated';
        lstOrdersList[0].Order_Status__c = 'Shipped';
        lstOrdersList[0].SBQQ__Contracted__c = true;     
        lstOrdersList[0].Is_RWD_Polaris_Quote__c = true;
        Test.startTest();
        update lstOrdersList;
      List<Entitlement> entitlement = [SELECT Id, AssetId, Type, StartDate, EndDate, Order_Service_Item__c, Product__c, Quantity__c FROM Entitlement LIMIT 5];
      List<OrderItem> lstorderItemList1 = [
        SELECT
          Id,
          Program__c,
          Quantity,
          product2Id,
          OrderId,
          Order.Actual_Order_Ship_Date__c,
          Order.ShippingCity,
          Order.AccountId,
          SBQQ__RequiredBy__r.SBQQ__QuoteLine__c,
          SBQQ__RequiredBy__c
        FROM OrderItem
        WHERE order.Order_Status__c = 'Shipped'
        LIMIT 10
      ];
      List<ContractLineItem> cliList = [
        SELECT
          Id,
          SBQQSC__OrderProduct__r.Quantity,
          SBQQSC__OrderProduct__r.Product2.Product_Subtype__c,
          SBQQSC__Product__c,
          SBQQSC__OrderProduct__r.Product2.SBQQSC__EntitlementConversion__c,
          SBQQSC__OrderProduct__r.Product2.Entitlement_Conversion_Non_CPQ__c,
          SBQQSC__OrderProduct__r.PricebookEntry.Product2Id,
          SBQQSC__QuoteLine__r.SBQQ__Product__r.Product_Level__c,
          SBQQSC__OrderProduct__r.Program__c,
          SBQQSC__RequiredByProduct__r.Asset_Upgrade_Product__c,
          SBQQSC__OrderProduct__r.Order.Order_Sub_Type__c,
          SBQQSC__OrderProduct__r.Order.Status,
          SBQQSC__RequiredByProduct__c,
          SBQQSC__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__c,
          SBQQSC__OrderProduct__r.Order.Is_RWD_Polaris_Quote__c,
          SBQQSC__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c,
          SBQQSC__OrderProduct__r.PricebookEntry.Product2.License_Subtype__c,
          SBQQSC__OrderProduct__r.Support_Start_Date__c,
          SBQQSC__OrderProduct__r.Support_End_Date__c,
          SBQQSC__OrderProduct__r.PricebookEntry.Product2.Product_Level__c
        FROM ContractLineItem
        WHERE SBQQSC__OrderProduct__r.SBQQ__QuoteLine__c != NULL
        LIMIT 5
      ];
        
        lstorderItemList1[0].SBQQSC__ContractLineItem__c = cliList[0].id;
       // lstorderItemList1[0].OrderId = lstOrdersList[0].Id;
        lstorderItemList1[0].SBQQ__Contracted__c = true;
      /*  lstorderItemList1[1].SBQQSC__ContractLineItem__c = cliList[1].id;
        lstorderItemList1[1].SBQQ__Contracted__c = true;
       lstorderItemList1[1].OrderId = lstOrdersList[0].Id;
        lstorderItemList1[2].SBQQSC__ContractLineItem__c = cliList[2].id;
        lstorderItemList1[2].SBQQ__Contracted__c = true;
        lstorderItemList1[2].SerialNumber__c = '';
        lstorderItemList1[2].OrderId = lstOrdersList[0].Id;*/
        update lstorderItemList1;
      system.assertEquals(cliList[0].Id, [SELECT id, SBQQSC__ContractLineItem__c FROM OrderItem WHERE Id = :lstorderItemList1[0].Id].SBQQSC__ContractLineItem__c);
        List<Duplicate_Entitlement_Handler__e> linesToProcess = new List<Duplicate_Entitlement_Handler__e>();
      linesToProcess.add(new Duplicate_Entitlement_Handler__e(Order_Item_Id__c = lstorderItemList1[0].id));
        //linesToProcess.add(new Duplicate_Entitlement_Handler__e(Order_Item_Id__c = lstorderItemList1[1].id));
       // linesToProcess.add(new Duplicate_Entitlement_Handler__e(Order_Item_Id__c = lstorderItemList1[2].id));
        EventBus.publish(linesToProcess);

        Map<Id, Date> assetStartDateMap = new Map<Id, Date>();
        assetStartDateMap.put(lstAsset[0].Id, Date.today());        
        Map<Id, Date> assetEndDateMap = new Map<Id, Date>();
      assetEndDateMap.put(lstAsset[0].Id, Date.today() + 120);
      OrderItemTriggerHelper.deleteBookingLineItems(new Map<Id, OrderItem>(lstorderItemList1));
        OrderItemTriggerHelper.updateAsset(lstAsset[0], lstorderItemList1[0], cliList[0], assetStartDateMap, assetEndDateMap);
        OrderItemTriggerHelper.updateEntitlementDetails(entitlement[0], lstAsset[0], cliList[0], new Map<Id, Entitlement>());
		lstOrdersList[0].Order_Sub_Type__c = Constants.ORDER_SUB_TYPE_GC_OFFER;
		//Product2 prodObj = new Product2 (id = lstorderItemList1[0].product2Id,Product_Subtype__c = Constants.PROD_SUB_TYPE_SCALE_MSP, License_Category__c='');
		//update prodObj;
		update lstOrdersList[0];
        
      PreviousTransRefWrapper wrapper = new PreviousTransRefWrapper(lstorderItemList1[0].id, 20.00, entitlement[0].Id, 30.00, lstorderItemList1[0].Id, null, null, false);
        // Step 2: Serialize the wrapper to JSON
      List<PreviousTransRefWrapper> wrapperList = new List<PreviousTransRefWrapper>{ wrapper };
        String jsonString = JSON.serialize(wrapperList);
        // Step 3: Test the deserializeJSON method
        
        List<PreviousTransRefWrapper> deserializedList = PreviousTransRefWrapper.deserializeJSON(jsonString);
        Test.stopTest();
            }
       
    }
  private static testMethod void testOrderItemDeletion() {
    user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com.invalid' LIMIT 1];

            System.runAs(usr1) {
         test.startTest();
      List<Order> ordList = [SELECT Id, NetSuite_Order__c, Order_Accepted_Timestamp__c FROM Order LIMIT 2];
      List<OrderItem> lstOLI = [
        SELECT Id, OrderId, Order.Deleted_Line_ID__c, Order.NetSuite_Order__c, Order.Order_Status__c, Global_Commit_ID__c
        FROM OrderItem
        WHERE OrderId = :ordList
      ];
        ordList[0].NetSuite_Order__c = '45745621';
        ordList[0].Deleted_Line_ID__c = String.valueOf(lstOLI[0].Id);
        ordList[1].NetSuite_Order__c = '78234626';
        update ordList;
        
      OrderItemTriggerHelper.updateDeletedLineIds(new Map<Id, OrderItem>(lstOLI));
      //  OrderItemTriggerHelper.processOrderItemData(json.serialize(lstOLI));
      system.assertEquals(2, ordList.size());

      ordList[0].Order_Accepted_Timestamp__c = Datetime.now();
      update ordList;

      delete lstOLI;

        test.stopTest();
            }
    }
    
     @isTest
  private static void testRCDMTExtensionMethod() {
    user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com.invalid' AND alias = 'std' LIMIT 1];
    System.runAs(usr1) {
      Account acc = [SELECT Id FROM account LIMIT 1];
      List<Orderitem> OIList = [
        SELECT id, product2.name, Previous_Contract_Line_Items__c, SBQQ__QuoteLine__r.SBQQ__Quote__r.RWD_Deal_Ops_Exception__c
        FROM orderitem
        WHERE product2.name = 'RS-BT-RCDM-T'
        LIMIT 10
      ];
      List<ContractlineItem> cliList = [SELECT id FROM contractlineitem LIMIT 10];
      TriggerControl.stopQuoteAndOrderStagingTrigger = true;
        List<Quote_and_Order_Staging__c> QuoteAndOrderStagingList = new List<Quote_and_Order_Staging__c>();
      for (Contractlineitem cli : cliList) {
        for (OrderItem oi : OIList) {
          QuoteAndOrderStagingList.add(
            new Quote_and_Order_Staging__c(
              Account_OM__c = acc.Id,
              Process_Type__c = 'Initial RCDM-T Processing',
              EOL_EndDate__c = system.today().addYears(1),
              Contract_Line_Item__c = cli.id,
              RSC_OrderItem__c = OI.ID
            )
          );
          QuoteAndOrderStagingList.add(
            new Quote_and_Order_Staging__c(
              Account_OM__c = acc.Id,
              Process_Type__c = 'QLI & Order Processing',
              EOL_EndDate__c = system.today().addYears(1),
              Contract_Line_Item__c = cli.id,
              RSC_OrderItem__c = OI.ID
            )
          );
            	 OI.Previous_Contract_Line_Items__c = cliList[0].Id;
            }
        }
        insert QuoteAndOrderStagingList;
        Test.startTest();
        TriggerControl.stopQuoteAndOrderStagingTrigger = false;
        update OIList;
      system.assert(OIList.size() > 0);
        Test.stopTest();
    }
  }

  private static List<OrderItem> getOrderItems(Id orderId) {
    return [
      SELECT
        Id,
                Credit_Amount__c,
        Previous_Contract_Line_Items__c,
                SBQQ__Contracted__c,
        OrderId,
        OrderItemNumber,
                Previous_Transaction_Reference__c,
                Replacement_Type__c,
                EndDate,
                ServiceDate,
                Cluster_Order_Type__c,
                Global_Commit_ID__c,
                NTAP_Part_number__c,
                NTAP_Order_number__c,
                Create_Entitlement__c,
                Quantity,
                Sales_Price__c,
                Line_Type__c,
        Program__c,
                UnitPrice,
                Support_Start_Date__c,
                Support_End_Date__c,
                POC_Option__c,
                Is_Refresh__c,
                Upgraded_From__c,
                Create_Asset__c,
                SBQQ__RequiredBy__c,
                Required_by_Product_Code__c,
                RMA_Component_Type__c,
                Is_Hardware_Line__c,
                SBQQ__SubscriptionTerm__c,
                PricebookEntryId,
        SBQQ__QuoteLine__c,
        Failed_Serial_Number__c,
        SerialNumber__c,
        Trade_Up_SerialNumber__c,
        Product2Id,
        Product_Type__c,
        SBQQ__SegmentIndex__c,
        Need_manual_fulfilment__c,
        TotalPrice,
        SBQQSC__ContractLineItem__c,
        Storage_Tier__c,
        TPH_Quantity__c,
        TPH_Models_Gen__c,
        TPH_OEM__c,
        Support_Term__c,
        SBQQSC__ContractLineItem__r.SBQQSC__RequiredById__c,
        /* ----------------- Order Fields ----------------- */
        Order.AccountId,
        Order.OpportunityId,
        Order.Opportunity.RecordTypeId,
        Order.Bill_To_Name__r.Name,
        Order.Sell_to_Partner__r.Name,
        Order.Order_Status__c,
        Order.SBQQ__Quote__c,
        Order.Order_Sub_Type__c,
        Order.Actual_Order_Ship_Date__c,
                Order.EffectiveDate,
                Order.Order_Start_Date__c,
        Order.Type,
        Order.Stage_PO__r.PO_Validation_Status__c,
        Order.Is_Amendment_Order__c,
        Order.Has_Third_Party_Hardware_Product__c,
        Order.Is_RWD_Polaris_Quote__c,
        /* ----------------- Opportunity via Order ----------------- */
                Order.Opportunity.New_Expansion_TCV__c,
                Order.Opportunity.Subsumed_Renewal_TCV__c,
                Order.Opportunity.ACV_Amount__c,
                Order.Opportunity.New_Expansion_ACV__c,
                Order.Opportunity.Renewal_Subsumed_ACV__c,
        /* ----------------- Product2 Fields ----------------- */
        PricebookEntry.Product2.Product_Type__c,
                Product2.Name,
                Product2.License_Category__c,
                Product2.Single_Entitlement__c,
        Product2.PDM_Feature_Enabled__c,
                Product2.Asset_Priority__c,
                Product2.SBQQ__SubscriptionPricing__c,
                Product2.Product_Level__c,
                Product2.License_Type__c,
                Product2.SBQQ__SubscriptionTerm__c,
                Product2.ProductCode,
                Product2.SBQQSC__EntitlementConversion__c,
                Product2.Bundle_Features__c,
                Product2.Appliance_Model_HW__c,
                Product2.Family,
                Product2.One_time_Entitlement__c,
                Product2.Product_Payment_Option__c,
                Product2.Category__c,
                Product2.Support_Type__c,
                Product2.Allow_PSO_Task_Creation__c,
                Product2.MSP_Std_Actual__c,
                Product2.Shipping_Lead_Time__c,
        Product2.OrderSubmission__c,
        Product2.Product_Subtype__c,
                Product2.Description,
                Product2.Edition__c,
                Product2.Eligible_for_RCDM_T__c,
        Product2.Entitlement_Conversion_Non_CPQ__c,
        Product2.Product_Type__c,
        /* ----------------- Quote Line Fields ----------------- */
        SBQQ__QuoteLine__r.Special_Program__c,
        SBQQ__QuoteLine__r.SBQQ__Quote__c,
        SBQQ__QuoteLine__r.SBQQ__Quote__r.Opportunity_Program__c,
        SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Primary__c,
        SBQQ__QuoteLine__r.GPL__c,
        SBQQ__QuoteLine__r.SBQQ__ListTotal__c,
        SBQQ__QuoteLine__r.SBQQ__TotalDiscountRate__c,
        SBQQ__QuoteLine__r.SBQQ__NetPrice__c,
        SBQQ__QuoteLine__r.RWD_Deal_Ops_Exception__c,
        SBQQ__QuoteLine__r.Name,
        SBQQ__QuoteLine__r.Replacement_Details__c,
        SBQQ__QuoteLine__r.Licensing_Model__c,
        SBQQ__QuoteLine__r.Rubrik_Suite__c,
        SBQQ__QuoteLine__r.Support_Type__c,
        SBQQ__QuoteLine__r.Payment_Options__c,
        SBQQ__QuoteLine__r.Line_Type__c,
        SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c,
        SBQQ__QuoteLine__r.SBQQ__Quote__r.Renewal_Opportunity__c,
        SBQQ__QuoteLine__r.SBQQ__Quote__r.Co_Term__c,
        SBQQ__QuoteLine__r.Arroyo_Subscribed_Asset_Name__c,
        SBQQ__QuoteLine__r.Arroyo_Subsumed_Old_Contract_Line_Items__c, // ✅ added back
        /* ----------------- RequiredBy Hierarchy ----------------- */
        SBQQ__RequiredBy__r.SerialNumber__c,
        SBQQ__RequiredBy__r.Product2.Product_Level__c,
        SBQQ__RequiredBy__r.Product2.Family,
        SBQQ__RequiredBy__r.Product2.Product_Subtype__c,
                SBQQ__RequiredBy__r.Product2.Eligible_for_RCDM_T__c,
        SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c,
        SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Subtype__c,
        SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c,
        SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Subtype__c,
        /* ----------------- Opportunity Product ----------------- */
                Opportunity_Product__r.OpportunityId,
                Opportunity_Product__r.Quantity,
                Opportunity_Product__r.Subsumed_Renewal_TCV__c,
                Opportunity_Product__r.New_Expansion_TCV__c,
                Opportunity_Product__r.ACV_Amount__c,
                Opportunity_Product__r.New_Expansion_ACV__c,
                Opportunity_Product__r.SubsRenAmt__c,
                Opportunity_Product__r.Subsumed_Renewal_Amount__c,
                Opportunity_Product__r.PromoDiscTCV__c,
                Opportunity_Product__r.Prepayment_Credit__c,
                Opportunity_Product__r.Oppty_Trade_Up_Discount__c
      FROM OrderItem
      WHERE OrderId = :orderId
    ];
    }
  private static List<Order> getOrders() {
    return [
      SELECT
        Id,
        AccountId,
        Contract_Manufacturer__c,
        Type,
        POC_Type__c,
        Actual_Order_Ship_Date__c,
        ShippingCity,
        Order_Sub_Type__c,
        Bill_To_Name__c,
        POC_Completion_Date__c,
        PS_Project__c,
        OrderNumber,
        SBQQ__Quote__c,
        ProcessType__c,
        Order_Status__c,
        SBQQ__Contracted__c,
        Partner_Name__c
      FROM Order
      LIMIT 1
    ];
    }
    /**
     * @description method to cover OrderUpdateHelper apex methods
     */
    @isTest
  private static void testOrderUpdateHelper() {
    user usr = [SELECT Id FROM User WHERE email = 'testuser@testclass.com.invalid' LIMIT 1];
        System.runAs(usr) {
            test.startTest();
            Id pricebookId = Test.getStandardPricebookId();
            DemandMatrixCalculation.distiMetadataMap = CMAllocation_For_Non_Aspen_Products__mdt.getAll();
            
            String currentQuarter = GeneralUtility.determineFinancialYearAndQuarter(System.today());
            Order newOrder = getOrders()[0];
            
      Product2 prd1 = new Product2(
        Name = 'RBK_MSP_R6404SE_HW_01',
        Usable_Capacity__c = 30,
        ProductCode = 'RBK-PS-CONSULT',
        Product_Type__c = 'HW Support',
        Product_Level__c = 'Support',
        isActive = true,
        Quotable_Date__c = system.today(),
        Product_Subtype__c = Constants.PROD_SUB_TYPE_SCALE_MSP,
                                         SBQQSC__EntitlementConversion__c = 'One per quote line',
        SBQQ__SubscriptionPricing__c = 'Fixed Price',
        Create_Entitlement__c = true,
        Create_Asset__c = true,
        Allow_PSO_Task_Creation__c = true
      );
            Product2 prd2 = prd1.clone();
            prd2.Create_Asset__c = false;
      insert new List<Product2>{ prd1, prd2 };
            PricebookEntry pb = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prd1.Id, UnitPrice = 100.00, IsActive = true);
      PricebookEntry pb1 = pb.clone();
            pb1.Product2Id = prd2.Id;
      insert new List<PricebookEntry>{ pb, pb1 };
      List<SBQQ__QuoteLine__c> quoteLines = [
        SELECT Id, SBQQ__Quote__r.Name, SBQQ__RequiredBy__r.SBQQ__ProductCode__c, SBQQ__Product__c, SBQQ__Product__r.Product_Level__c
        FROM SBQQ__QuoteLine__c
        WHERE SBQQ__Quote__c = :newOrder.SBQQ__Quote__c
        ORDER BY CreatedDate DESC
      ];
      //List<OrderItem> oiItems = new List<OrderItem>();
      OrderItem ordItem1 = new OrderItem(
        OrderId = newOrder.Id,
        Product2Id = prd1.Id,
        Quantity = 200,
        PricebookEntryId = pb.Id,
        UnitPrice = 100,
        Support_End_Date__c = System.Today().addYears(1),
        // Support_Start_Date__c = System.Today(),
        SBQQ__QuoteLine__c = quoteLines[0].Id
      );
      OrderItem ordItem2 = new OrderItem(
        OrderId = newOrder.Id,
        Product2Id = prd1.Id,
        Quantity = 100,
        PricebookEntryId = pb.Id,
        UnitPrice = 100,
        Support_End_Date__c = System.Today().addMonths(1),
        // Support_Start_Date__c = System.Today(),
        SBQQ__QuoteLine__c = quoteLines[0].Id
      );
      OrderItem ordItem3 = new OrderItem(
        OrderId = newOrder.Id,
        Product2Id = prd2.Id,
        Quantity = 10,
        PricebookEntryId = pb1.Id,
        UnitPrice = 100,
        Support_End_Date__c = System.Today().addMonths(1),
        // Support_Start_Date__c = System.Today(),
        SBQQ__QuoteLine__c = quoteLines[1].Id
      );
      List<OrderItem> oiItems = new List<OrderItem>{ ordItem1, ordItem2, ordItem3 };
      insert oiItems;
      for (orderItem oi : oiItems) {
        oi.Support_Start_Date__c = System.today();
      }
      update oiItems;
            List<OrderItem> orderItems = getOrderItems(newOrder.Id);    

            System.assert(orderItems.size() > 0);
            String key = currentQuarter + '-' + prd1.Id + '-' + newOrder.Contract_Manufacturer__c;
      Map<String, ContractManufacturerAllocation__c> cmAllocationForNonAspenMap = new Map<String, ContractManufacturerAllocation__c>();
      cmAllocationForNonAspenMap.put(key, new ContractManufacturerAllocation__c(TotalFulfillment__c = 100));
            DemandMatrixCalculation.cmAllocationForNonAspenMap = cmAllocationForNonAspenMap;
      OrderHandler.opptyHistoryMap = new Map<Id, String>{ orderItems[0].Order.OpportunityId => currentQuarter };
            OrderUpdateHelper ordUpdHelper = OrderUpdateHelper.getInstance();
            ordUpdHelper.updateCma(newOrder, newOrder, orderItems);
            Map<string, Asset> serialNumAsset = new Map<string, Asset>();
      List<Asset> assets = [
        SELECT Id, SerialNumber, Order_Service_Item__c, Premium_Support_End_Date__c, AccountId, Support_Start_Date__c
        FROM Asset
        LIMIT 1
      ];
      for (Asset assetRec : assets) {
                assetRec.Premium_Support_End_Date__c = System.Today(); 
            	serialNumAsset.put(assetRec.SerialNumber, assetRec);  
            }
      for (OrderItem ordItem : orderItems) {
            	ordItem.SerialNumber__c = ordItem.Trade_Up_SerialNumber__c = ordItem.Failed_Serial_Number__c = assets[0].SerialNumber;
                ordItem.RMA_Component_Type__c = 'Appliance';
            }            
      for (Integer count = 0; count < 2; count++) {
        if (count == 0) {
                	newOrder.Type = 'POC';    
        } else if (count == 1) {
                	newOrder.Type = 'Revenue'; 
                    newOrder.Order_Sub_Type__c = 'Renewal';
                }
        ordUpdHelper.processOrderItem(
          newOrder,
          orderItems,
          new Map<Id, List<Entitlement>>(),
                                            serialNumAsset,
          new Set<Entitlement>(),
                                            new Map<Id, Entitlement>(),
                                            new Map<string, Asset>(),
          new Map<Id, orderItem>()
        );
            }
            Map<String, List<Entitlement>> failedAssetWithEntitlement = new Map<String, List<Entitlement>>();
      List<Entitlement> entitlements = [SELECT Id FROM Entitlement ORDER BY CreatedDate ASC LIMIT 1];
            failedAssetWithEntitlement.put(assets[0].Id, entitlements);
      ordUpdHelper.rMAProcessShippedOrders(
        newOrder,
        orderItems,
        serialNumAsset,
        new Map<string, List<string>>(),
        new Map<string, Node__c>(),
        new Map<string, Chassis__c>(),
        new Map<string, Power_Supply__c>(),
        new Map<string, Drive__c>(),
        new Map<string, Memory__c>(),
        new Map<string, Asset>(),
        new Map<Id, Node__c>(),
        new Set<Chassis__c>(),
        new Set<Power_Supply__c>(),
        new Set<Drive__c>(),
        new Set<Memory__c>(),
        failedAssetWithEntitlement,
        new Map<Id, Entitlement>()
      );
            newOrder.Actual_Order_Ship_Date__c = System.Today();
      ordUpdHelper.createPSTask(newOrder, orderItems, new Set<PS_Task__c>(), new Map<Id, orderItem>());
      Id invalidId = Id.valueOf('001' + '000000000000' + 'AAA');
      ordUpdHelper.notifyTrainingSKU(new Set<Id>{ invalidId });
            ShipmentDetail__c sDetail1 = new ShipmentDetail__c(ProductName__c = Constants.INVALIDATE_ACCESSORIES[0]);
            ShipmentDetail__c sDetail2 = new ShipmentDetail__c(ProductName__c = 'test', ShippedDate__c = 'Today');
      ShipmentDetail__c sDetail3 = new ShipmentDetail__c(ProductName__c = 'RS-BT-BE-RSCP-TPH-PE-PP', ShippedDate__c = '07/23/2025', Type__c = 'Aspen');
      ShipmentDetail__c sDetail4 = new ShipmentDetail__c(
        ProductName__c = 'RS-BT-BE-RSCP-TPH-PE-PP',
        ShippedDate__c = '07/23/2025',
        Type__c = 'Aspen',
        Status__c = 'New',
        QuoteNumber__c = quoteLines[0].SBQQ__Quote__r.Name,
        HW_SerialNumber__c = serialNumAsset.values()[0].SerialNumber,
        ProcessHistory__c = 'Support and Hardware quantity mismatch',
        Product_Type__c = 'Spares'
      );
      List<ShipmentDetail__c> ShipmentDetails = new List<ShipmentDetail__c>{ sDetail1, sDetail2, sDetail3 };
      List<ShipmentDetail__c> ShipmentDetailsClone = new List<ShipmentDetail__c>(ShipmentDetails);
      ShipmentDetailsClone.add(sDetail4);
      String shipmentDetailsString = JSON.serialize(shipmentDetailsClone);
            newOrder.Type = 'POC';
            newOrder.ProcessType__c = 'Aspen';
            newOrder.Order_Status__c = 'Shipped';
            newOrder.SBQQ__Contracted__c = true;
      for (Integer counter = 0; counter < 2; counter++) {
        if (counter == 0) {
                	newOrder.Type = 'POC';    
        } else if (counter == 1) {
                	newOrder.Type = 'Revenue';  
                    newOrder.Order_Sub_Type__c = null;
                    ShipmentDetails.add(sDetail4);
                }
                
        ordUpdHelper.updateHardwareInfo(
          newOrder,
          orderItems,
          ShipmentDetails,
          new Map<string, Decimal>(),
          new Map<Id, orderItem>(),
          new Set<Scale_Entitlement__c>(),
          new Map<string, Asset>(),
          serialNumAsset,
          new Map<Id, List<Entitlement>>(),
          new Map<Id, Entitlement>()
        );
      }
      for (OrderItem ordItem : orderItems) {
        ordItem.Program__c = CONSTANTS.PROGRAM_REFRESH;
        ordItem.Upgraded_From__c = assets[0].SerialNumber;
        ordItem.SerialNumber__c = assets[0].SerialNumber;
            }
            
      shipmentDetailsClone = (List<ShipmentDetail__c>) JSON.deserialize(shipmentDetailsString, List<ShipmentDetail__c>.class);
      ordUpdHelper.updateHardwareInfo(
        newOrder,
        orderItems,
        shipmentDetailsClone,
        new Map<string, Decimal>(),
        new Map<Id, orderItem>(),
        new Set<Scale_Entitlement__c>(),
        new Map<string, Asset>(),
        new Map<string, Asset>(),
        new Map<Id, List<Entitlement>>(),
        new Map<Id, Entitlement>()
      );
            test.stopTest();
        }
    }
  @isTest
  public static void testoldCLI() {
    List<OrderItem> orderItemsToprocess = new List<OrderItem>();
    List<Order> lstofOrders = [SELECT id FROM Order];
    
    List<Entitlement> lstofEnt = [
      SELECT
        id,
        Asset.SerialNumber,
        Phantom_OrderItemID__c,
        Phantom_OrderItemID__r.Quantity,
        ContractLineItem.LinkedAssets__c,
        ContractLineItemId,
        EndDate,
        Asset.Name,
        Asset.serial_number__c,
        Product__r.Product_Type__c,
        Product__r.Name,
        Product__r.Approval_Category__c,
        product__r.Bundle_Features__c,
        Order_Service_Item__c,
        Order_Service_Item__r.Quantity,
        Product__r.Product_Level__c,
        Order_Service_Item__r.Order.OrderNumber,
        Quantity__c,
        (SELECT Id, Asset__r.SerialNumber, Asset__r.Name, Asset__c, Contract_Line_Item__c, Entitlement__c FROM Scale_Entitlements__r)
      FROM Entitlement
    ];

    Test.startTest();
    List<Contractlineitem> lstofcli = [SELECT id, SBQQSC__RequiredById__c FROM contractlineitem];
    /*for(Contractlineitem cli: lstofcli){
            cli.SBQQSC__RequiredById__c = lstofcli[0].id;
        }
		update lstofcli;*/

    for (Order ord : lstofOrders) {
      orderItemsToprocess.addAll(getOrderItems(ord.id));
    }

    for (Orderitem oi : orderItemsToprocess) {
      oi.SBQQSC__ContractLineItem__c = lstofcli[1].id;
    }
    update orderItemsToprocess;
    Map<Id, OrderItem> newMap = new Map<Id, OrderItem>(orderItemsToprocess);
    Test.stopTest();
    OrderItemTriggerhelper.mapOfIdToEnt = new Map<Id, Entitlement>(lstofEnt);
    OrderItemTriggerhelper.mapOfIdtoOrderItem = newMap;
    //OrderItemTriggerHelper.mapOfOrders = new Map<Id, Order>();
    OrderItemTriggerhelper.populateValuesOnCreatedOLI(newMap);

    OrderItemTriggerhelper.updateRequiredByLineItemOnCLI();
    //OrderItemTriggerhelper.getPrevTransRefJson(orderItemsToprocess);
  }
    @isTest
    public static void testV1Sku() {
    user usr = [SELECT Id FROM User WHERE email = 'testuser@testclass.com.invalid' LIMIT 1];
        System.runAs(usr) {
        // Fetch Quotes and set Is_RWD_Polaris_Quote__c = true
        SBQQ.TriggerControl.disable();
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true; 
        List<SBQQ__Quote__c> quoteRecords = [
            SELECT Id, Is_RWD_Polaris_Quote__c 
            FROM SBQQ__Quote__c
        ];
        for (SBQQ__Quote__c quote : quoteRecords) {
            quote.Is_RWD_Polaris_Quote__c = true;
        }
        if (!quoteRecords.isEmpty()) {
            update quoteRecords;
        }
        
        // Fetch Quote Lines
        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT Id, SBQQ__Product__r.Product_Level__c, SBQQ__RequiredBy__c 
            FROM SBQQ__QuoteLine__c
        ];
        
        // Collect Hardware QLIs
        List<SBQQ__QuoteLine__c> hwQuoteLines = new List<SBQQ__QuoteLine__c>();
        for (SBQQ__QuoteLine__c qli : quoteLines) {
            if (qli.SBQQ__Product__r.Product_Level__c == 'Hardware') {
                hwQuoteLines.add(qli);
            }
        }
        
        // Set RequiredBy for all QLIs if we found a hardware line
        if (!hwQuoteLines.isEmpty()) {
            Id requiredById = hwQuoteLines[0].Id;
            for (SBQQ__QuoteLine__c qli : quoteLines) {
          if (qli.SBQQ__Product__r.Product_Level__c != 'Hardware') {
                   qli.SBQQ__RequiredBy__c = requiredById;
                }  
            }
            update quoteLines;
        }
        SBQQ.TriggerControl.enable();
        TriggerControls.disableQuoteTrigger = false;
        TriggerControls.disableQuoteLineTrigger = false; 
        // Fetch Contract Line Items with deep references
        List<ContractLineItem> cliList = [
        SELECT
          Id,
            SBQQSC__OrderProduct__r.Quantity,
            SBQQSC__OrderProduct__r.Product2.Product_Subtype__c,
            SBQQSC__Product__c,
            SBQQSC__OrderProduct__r.Product2.SBQQSC__EntitlementConversion__c,
            SBQQSC__OrderProduct__r.Product2.Entitlement_Conversion_Non_CPQ__c,
            SBQQSC__OrderProduct__r.PricebookEntry.Product2Id,
            SBQQSC__QuoteLine__r.SBQQ__Product__r.Product_Level__c,
            SBQQSC__OrderProduct__r.Program__c,
            SBQQSC__RequiredByProduct__r.Asset_Upgrade_Product__c,
            SBQQSC__OrderProduct__r.Order.Order_Sub_Type__c,
            SBQQSC__OrderProduct__r.Order.Status,
            SBQQSC__RequiredByProduct__c,
            SBQQSC__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__c,
            SBQQSC__OrderProduct__r.Order.Is_RWD_Polaris_Quote__c,
            SBQQSC__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c,
            SBQQSC__OrderProduct__r.PricebookEntry.Product2.License_Subtype__c,
            SBQQSC__OrderProduct__r.Support_Start_Date__c,
            SBQQSC__OrderProduct__r.Support_End_Date__c,
            SBQQSC__OrderProduct__r.PricebookEntry.Product2.Product_Level__c,
            SBQQSC__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__DynamicOptionId__c,
            SBQQSC__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__OptionType__c,
            SBQQSC__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__OptionLevel__c
            FROM ContractLineItem
            WHERE SBQQSC__OrderProduct__r.SBQQ__QuoteLine__c != NULL
            LIMIT 5
        ];
            
        List<Order> lstOrdersList = [SELECT Id, SBQQ__ContractingMethod__c FROM Order LIMIT 1];
        lstOrdersList[0].SBQQ__ContractingMethod__c = 'By Subscription End Date';
        lstOrdersList[0].Polaris_Fulfillment_Status__c = 'Completed';
        lstOrdersList[0].Status = 'Activated';
        lstOrdersList[0].Order_Status__c = 'Shipped';
        lstOrdersList[0].SBQQ__Contracted__c = true;     
        lstOrdersList[0].Is_RWD_Polaris_Quote__c = true;
        Test.startTest();
         update lstOrdersList;
        
        // Fetch sample Order Items
        List<OrderItem> orderItems = [
        SELECT
          Id,
          Program__c,
          Quantity,
          Product2Id,
          OrderId,
          Order.Actual_Order_Ship_Date__c,
          Order.ShippingCity,
          Order.AccountId,
          SBQQ__RequiredBy__r.SBQQ__QuoteLine__c,
          SBQQ__RequiredBy__c
            FROM OrderItem
        WHERE order.Order_Status__c = 'Shipped'
            LIMIT 10
        ];
        
        // Fetch a sample Asset
        List<Asset> assets = [
        SELECT Id, product2Id, Serial_Number__c, AccountId, Order_Service_Item__c
            FROM Asset 
            WHERE SerialNumber = 'AA204063040011'
        ];

        if (!assets.isEmpty() && !orderItems.isEmpty() && !cliList.isEmpty()) {
            Asset asset = assets[0];
            OrderItem orderItem = orderItems[0];
            
            // Build start/end date maps
        Map<Id, Date> assetStartDateMap = new Map<Id, Date>{ asset.Id => Date.today() };
        Map<Id, Date> assetEndDateMap = new Map<Id, Date>{ asset.Id => Date.today().addDays(120) };
                                    
            // Update Assets for each CLI
            
            for (ContractLineItem cli : cliList) {
          Asset tempAsset = OrderItemTriggerHelper.updateAsset(asset, orderItem, cli, assetStartDateMap, assetEndDateMap);
          system.assertEquals('Purchased', tempAsset.Status);
          system.assertEquals(1, tempAsset.SBQQ__Number__c);
            }
            Test.stopTest();
        }
    }
    }
        
          
   @isTest
    public static void testExecuteQueableJobOnShipped(){
        user usr = [SELECT Id FROM User WHERE email = 'testuser@testclass.com.invalid' LIMIT 1];
    	System.runAs(usr) {
        Order objOrder = [Select id, Welcome_Letter_Status__c, ProcessType__c From Order Where Type = 'Revenue' limit 1];
        List<OrderItem> listOI = new List<OrderItem>();
        for(Integer i = 0; i <= 220 ; i++ ){
           OrderItem oi = new OrderItem(
            Quantity = 1,
            UnitPrice = 10,
            OrderId = objOrder.Id);
        	listOI.add(oi);
        }
        Map<Id, List<OrderItem>> mapOrderIdToListOI = new Map<Id, List<OrderItem>>{objOrder.Id => listOI};
        Test.startTest();
        OrderValidationService.executeQueableJobOnShipped(objOrder, mapOrderIdToListOI);
        Test.stopTest();
        system.assert(true);
        }
    }
        @isTest
    public static void testUpdateExpectedDateForReplacement(){
        user usr = [SELECT Id FROM User WHERE email = 'testuser@testclass.com.invalid' LIMIT 1];
    	System.runAs(usr) {
        Order objOrder = [Select id, Line_Types__c, ProcessType__c, SBQQ__Quote__c, SBQQ__Quote__r.LoD_refreshed_to_Subscription_Deal__c From Order Where Type = 'Revenue' limit 1];
        
        SBQQ.TriggerControl.disable();
      	TriggerControls.disableQuoteTrigger = true;
      	TriggerControls.disableQuoteLineTrigger = true;
		SBQQ__Quote__c objQuote = new SBQQ__Quote__c(Id = objOrder.SBQQ__Quote__c, LoD_refreshed_to_Subscription_Deal__c = false);
       	update objQuote;
        Date firstDayDate = Date.today().toStartOfMonth();
        objOrder.Line_Types__c = Constants.PROGRAM_CONVERSION;
        objOrder.Order_Accepted_Timestamp__c = System.now();
        update objOrder;
        List<OrderItem> listOI = new List<OrderItem>{
            new OrderItem(Quantity = 1, UnitPrice = 10, OrderId = objOrder.Id, Credit_Amount__c = 0),
            new OrderItem(Quantity = 1, UnitPrice = 10, OrderId = objOrder.Id, Credit_Amount__c = null),
            new OrderItem(Quantity = 1, UnitPrice = 10, OrderId = objOrder.Id, Credit_Amount__c = 1)
        };
        Map<Id, List<OrderItem>> mapOrderIdToListOI = new Map<Id, List<OrderItem>>{objOrder.Id => listOI};
        Test.startTest();
        OrderValidationService.updateExpectedDateForReplacement(objOrder, mapOrderIdToListOI);
        Test.stopTest();
        system.assert(true);
        }
    }

}