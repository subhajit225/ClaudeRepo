@isTest
public class ScaleEntitlementTriggerHelper_Test {
    
     @testSetup static void insertData() {
        insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Disable_Account_Old_Trigger__c = TRUE);
        insert new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getUserId(), 
              Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
              Disable_SBQQ_Quote_Triggers__c = TRUE,
              Disable_SBQQ_QuoteLine_Triggers__c=true,
              Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
              Disable_Order_Old_Trigger__c = true, Disable_OrderItem_Old_Trigger__c = true,
              Disable_Opportunity_Triggers__c=true);
        TriggerControl.stopOrderItemTrigger = true;
        TriggerControl.stopOrderTrigger = true;
        TriggerControl__c objOrderTrigger = new TriggerControl__c(Name = 'Entitlement', Disable_Trigger__c = true, 
                                                DisableTrigger__c = true, SendEmail__c = false);
        insert objOrderTrigger;
        
        
       Id accDistiRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account customer = new Account(
            Name = 'Customer',
            recordtypeId = accDistiRecTypeId,
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
        insert customer;
		
        //Contact cont = TestDataFactory.getContact(customer);
        //insert cont;
        
        Opportunity opp = TestDataFactory.getOpportunity();
        opp.Partner_Lookup__c = customer.Id;
        opp.AccountId = customer.Id;
        opp.Distributor_Lookup__c = opp.AccountId;
        //opp.Initial_Contacts_Name__c = cont.Id;
        opp.Pricebook2id = Test.getStandardPricebookId();
        insert opp;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__SubscriptionTerm__c = 12,
            Is_RWD_Polaris_Quote__c = true,
            SBQQ__Primary__c = true,
            Opportunity_Program__c = 'Conversion',
            ApprovalStatus__c = 'Recalled',
            SBQQ__Type__c = 'Quote',
            SBQQ__PriceBook__c = Test.getStandardPricebookId());
        insert quote;

        List<Product2> sampleProducts = new List<Product2>{
            // 0
                new Product2(
                    Name = 'RS-BT-FE-PE-PP',
                    ProductCode = 'RS-BT-FE-PE-PP',
                    Product_Level__c = 'Hybrid Software',
                    IsActive = true,
                    SBQQ__Hidden__c = true,
                    Support_Type__c = 'Premium',
                    SBQQ__ExcludeFromOpportunity__c = true,
                    New_CPQ_Product__c = true
                ),
                // 1
                new Product2(
                    Name = 'RH-6416S-02',
                    ProductCode = 'RH-6416S-02',
                    Category__c = 'Platform',
                    Family = 'R6000',
					Usable_Capacity__c = 50,
                    Product_Type__c = 'Hardware',
                    Product_Level__c = 'Hardware',
                    Appliance_Model__c='RBK-R6416S',
                    Appliance_Model_HW__c = 'RBK-R6416S',
                    SBQQ__AssetConversion__c = null,
                    SBQQSC__EntitlementConversion__c = 'None',
                    Create_Asset_Entitlement__c = true,
                    IsActive = true,
                    Asset_Priority__c = 0,
                    New_CPQ_Product__c = true
                ),
                // 2
                new Product2(
                    Name = 'RS-HW-SVC-PE',
                    ProductCode = 'RS-HW-SVC-PE',
                    Category__c = 'Support',
                    Product_Type__c = 'HW Support',
					Product_Level__c = 'Support',
                    SBQQ__AssetConversion__c = 'None',
                    SBQQSC__EntitlementConversion__c = 'One per unit',
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 12,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable',
                    IsActive = true,
                    Support_Type__c = 'L3',
                    Asset_Priority__c = 1,
                    New_CPQ_Product__c = true
                )                
        };
        insert sampleProducts;
        List<PricebookEntry>entries = new List<PricebookEntry>();

        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[0].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[1].Id, IsActive = true, UnitPrice = 200));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[2].Id, IsActive = true, UnitPrice = 300));
        
        insert entries;
        system.debug('entries****'+entries);
        
        List<Asset> assestIns = new List<Asset>{
            new Asset(Name = '09092019APMSP1250', SerialNumber = '09092019APMSP1250', serial_number__c= '09092019APMSP1250', AccountId = customer.Id, Product2Id = sampleProducts[1].Id)
        };
        insert assestIns;
        
        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, Special_Program__c = 'Conversion', SBQQ__Product__c = sampleProducts[0].Id, SBQQ__PricebookEntryId__c = entries[0].Id, SBQQ__Quantity__c = 300,  SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = 1, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[1].Id, SBQQ__PricebookEntryId__c = entries[1].Id, SBQQ__Quantity__c = 6, SBQQ__SubscriptionPricing__c = null,  SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__Optional__c = true, SBQQ__Existing__c = true));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, Special_Program__c = 'Conversion', SBQQ__Product__c = sampleProducts[2].Id, SBQQ__PricebookEntryId__c = entries[2].Id, SBQQ__Quantity__c = 6, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = 1, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        
        insert lines;

        lines[0].SBQQ__Bundle__c = true;
        lines[1].SBQQ__RequiredBy__c = lines[0].Id;
        lines[2].SBQQ__RequiredBy__c = lines[1].Id;
     
        update lines;
        
        quote.ApprovalStatus__c = 'Approved';
        update quote;
        
        Order orderInstance = new Order();
        orderInstance.AccountId = customer.Id;
        orderInstance.OpportunityId = opp.Id;
        orderInstance.SBQQ__Quote__c = quote.Id;
        orderInstance.EffectiveDate = system.today();  
        orderInstance.Status = 'Draft';
        orderInstance.Type = 'Revenue';
        orderInstance.Order_Status__c = 'Pending'; 
        orderInstance.Status='Draft';
        orderInstance.Pricebook2Id = Test.getStandardPricebookId(); 
        insert orderInstance;
        
        List<OrderItem> orderItemList = new List<OrderItem>{
            new OrderItem(OrderId = orderInstance.Id, Product2Id = sampleProducts[0].Id, UnitPrice = entries[0].UnitPrice, SBQQ__QuoteLine__c = lines[0].Id, SBQQ__SubscriptionTerm__c = 36, Quantity = 20, PricebookEntryId = entries[0].Id, Program__c = 'Conversion'),
            new OrderItem(OrderId = orderInstance.Id, Product2Id = sampleProducts[2].Id, UnitPrice = entries[2].UnitPrice, SBQQ__QuoteLine__c = lines[2].Id, SBQQ__SubscriptionTerm__c = 36, Quantity = 20, PricebookEntryId = entries[2].Id, Program__c = 'Conversion')
            };
		insert orderItemList;
       	
    ServiceContract objSC = new ServiceContract(Name = 'ServiceContract Test', AccountId = customer.Id, StartDate = Date.today(),
                                                   Term = 36, pricebook2Id = Test.getStandardPricebookId(), SBQQSC__Opportunity__c = opp.Id, SBQQSC__Order__c= orderInstance.Id,  SBQQSC__Quote__c = quote.Id);
       
    insert objSC;
    system.debug('::ServiceContract::'+objSC.pricebook2Id); 
    system.debug('::ServiceContract1::'+objSC); 
    List<ContractLineItem> lstCli = new List<ContractLineItem>();
        
    ContractLineItem cli2 = new ContractLineItem();
    cli2.Quantity = orderItemList[0].quantity;
    cli2.PricebookEntryId = orderItemList[0].PricebookEntryId;
    cli2.ServiceContractId= objSC.id;
    cli2.UnitPrice= orderItemList[0].UnitPrice; 
    cli2.StartDate = date.today();
    lstCli.add(cli2);
    
     ContractLineItem cli = new ContractLineItem();
     cli.Quantity = orderItemList[1].quantity;
     cli.PricebookEntryId = orderItemList[1].PricebookEntryId;
     cli.ServiceContractId= objSC.id;
    cli.UnitPrice= orderItemList[1].UnitPrice; 
    cli.StartDate = date.today();
    lstCli.add(cli);
    

    /*ContractLineItem cli1 = new ContractLineItem();
    cli1.Quantity = orderItemList[3].quantity;
    cli1.PricebookEntryId = orderItemList[3].PricebookEntryId;
    cli1.ServiceContractId= objSC.id;
    cli1.UnitPrice= orderItemList[3].UnitPrice;  
    cli1.StartDate = date.today();
    lstCli.add(cli1);
    system.debug('::Contraclines::'+lstCli); */
    insert lstCli;
    
        Id supportRecordTypeId = Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Support').getRecordTypeId();

        List<Entitlement> lstEntitlement = new List<Entitlement> {
            
            new Entitlement(Name = 'Ent Test1' , RecordTypeId = supportRecordTypeId , Type= 'Phone Support', AccountId= customer.Id, Product__c = sampleProducts[0].Id, 
                            StartDate= date.today(), ServiceContractId = objSC.Id, ContractLineItemId = lstCli[0].Id, Order_Service_Item__c=orderItemList[0].id),
             new Entitlement(Name = 'Ent Test2' , RecordTypeId = supportRecordTypeId , Type= 'Phone Support', AccountId= customer.Id, Product__c = sampleProducts[2].Id, 
                            StartDate= date.today(), AssetId = assestIns[0].Id, ServiceContractId= objSC.Id, ContractLineItemId = lstCli[1].Id, Order_Service_Item__c=orderItemList[1].id)
           /* new Entitlement(Name = 'Ent Test3' , RecordTypeId = supportRecordTypeId , Type= 'Phone Support', AccountId= customer.Id, Product__c = sampleProducts[3].Id, 
                            StartDate= date.today(), ServiceContractId = objSC.Id, ContractLineItemId = lstCli[2].Id, Order_Service_Item__c=orderItemList[3].id)*/
            
            
        };
        insert lstEntitlement; 
        
        orderInstance.Is_RWD_Polaris_Quote__c = true;
        orderInstance.SBQQ__Contracted__c = true;
        orderInstance.Status = 'Activated';
        update orderInstance;
        
         Scale_Entitlement__c objScaleEntitlement = new Scale_Entitlement__c();
         objScaleEntitlement.Contract_Line_Item__c = lstEntitlement[0].ContractLineItemId;
         objScaleEntitlement.Asset__c = assestIns[0].Id;
         objScaleEntitlement.Type__c = 'Non-Scale';
         objScaleEntitlement.Order_Product__c = lstEntitlement[0].Order_Service_Item__c;
         objScaleEntitlement.Entitlement__c = lstEntitlement[0].Id;
         insert objScaleEntitlement;
           
        
    }
        @isTest
        public static void method2(){
            Test.startTest();
              List<Asset> lstAsset = [Select id, SBQQSC__RequiredByLineItem__c from Asset];
            Test.stopTest();


        }
   

}