@isTest(SeeAllData=false)
public class LinkOrderControllerTest {
        
     @testSetup static void insertData() {
     	insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Disable_Account_Old_Trigger__c = TRUE);
        insert new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getUserId(), 
              Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
              Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
              Disable_Order_Old_Trigger__c = true, Disable_OrderItem_Old_Trigger__c = true,
              Disable_Opportunity_Triggers__c=true);
        TriggerControl.stopOrderItemTrigger = true;
        TriggerControl.stopOrderTrigger = true;
        //TriggerControl__c objOrderTrigger = new TriggerControl__c(Name = 'Order', Disable_Trigger__c = false, 
                                                           //  DisableTrigger__c = true, SendEmail__c = false);
        //insert objOrderTrigger;
        
        Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account customer = new Account(
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
            Contract_Status__c = 'Signed-Active',
            ShippingCountry = 'United States'
        );
        insert customer;

        Opportunity opp = TestDataFactory.getOpportunity();
        
        opp.Distributor_Lookup__c = customer.Id;
        opp.Partner_Lookup__c = customer.Id;
        opp.AccountId = customer.Id;
        insert opp;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__SubscriptionTerm__c = 12,
            Is_RWD_Polaris_Quote__c = true,
            SBQQ__Primary__c = true,
            SBQQ__PriceBook__c = Test.getStandardPricebookId());
        insert quote;

        List<Product2> sampleProducts = new List<Product2>{
                // 0
                new Product2(
                    Name = 'CPQ Bundle Product',
                    ProductCode = 'CPQ Bundle Product',
                    IsActive = true,
                    Product_Level__c = 'Hybrid Software',
                    MSP_Segment_Product__c = true,
                    SBQQ__Hidden__c = true,
                    SBQQ__ExcludeFromOpportunity__c = true,
                    New_CPQ_Product__c = true
                ),
                // 1
                new Product2(
                    Name = 'RBK-R6412-CONS',
                    ProductCode = 'RBK-R6412-CONS',
                    Category__c = 'Platform',
                    Family = 'r300',
                    Usable_Capacity__c= 1,
                    Product_Level__c ='Hardware',
                    Product_Type__c = 'Hardware',
                    Appliance_Model__c='RBK-R344',
                    Appliance_Model_HW__c = 'RBK-R344',
                    CPQ_MSP_Base_Price__c = 0.13,
                    SBQQSC__EntitlementConversion__c = 'None',
                    SBQQ__AssetAmendmentBehavior__c = 'Default',
                    IsActive = true,
                    Asset_Priority__c = 0,
                    MSP_Segment_Product__c = true,
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 1,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable'
                ),
                // 2
                 new Product2(
                    Name = 'RBK-RADAR-CONS',
                    ProductCode = 'RBK-RADAR-CONS',
                    Category__c = 'Support',
                    Product_Level__c ='Support',  
                    SBQQ__AssetAmendmentBehavior__c = 'Default',
                    SBQQSC__EntitlementConversion__c = 'One per quote line',
                    IsActive = true,
                    CPQ_MSP_Base_Price__c = 0.02,
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 36,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable'
                ),
                 new Product2(
                    Name = 'RBK-RADAR-CONS1',
                    ProductCode = 'RBK-RADAR-CONS1',
                    Category__c = 'Support',
                    SBQQ__AssetAmendmentBehavior__c = 'Default',
                    SBQQSC__EntitlementConversion__c = 'One per quote line',
                    IsActive = true,
                    CPQ_MSP_Base_Price__c = 0.02,
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 36,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable'
                )   
        };
        insert sampleProducts;
        system.debug('sampleProducts***'+sampleProducts);
        system.debug('sample3***'+sampleProducts[3]);
        List<PricebookEntry>entries = new List<PricebookEntry>();

        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[0].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[1].Id, IsActive = true, UnitPrice = 200));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[2].Id, IsActive = true, UnitPrice = 300));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[3].Id, IsActive = true, UnitPrice = 400));
        insert entries;
        system.debug('entries****'+entries);
        List<SBQQ__ProductOption__c>prodOptions = new List<SBQQ__ProductOption__c>();
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 20, SBQQ__ConfiguredSKU__c = sampleProducts[1].Id, SBQQ__OptionalSKU__c = sampleProducts[1].Id));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 30, SBQQ__ConfiguredSKU__c = sampleProducts[2].Id, SBQQ__OptionalSKU__c = sampleProducts[1].Id));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 30, SBQQ__ConfiguredSKU__c = sampleProducts[3].Id, SBQQ__OptionalSKU__c = sampleProducts[1].Id));
       //nsert prodOptions;
        //Test.startTest();
        Asset assestIns = new Asset();
        assestIns.Name = '09092019APMSP1250';
        assestIns.SerialNumber = '09092019APMSP1250';
        assestIns.serial_number__c= '09092019APMSP1250';
        assestIns.AccountId = customer.Id;
        assestIns.Product2Id = sampleProducts[0].Id;
        //sert assestIns;
        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[0].Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[1].Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[2].Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[3].Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        insert lines;

        lines[0].SBQQ__Bundle__c = true;
        lines[1].SBQQ__RequiredBy__c = lines[0].Id;
        lines[2].SBQQ__RequiredBy__c = lines[1].Id;
        lines[3].SBQQ__RequiredBy__c = lines[0].Id;
        update lines;
        
        system.debug('Lines***'+lines);      
        list<Order> orderList2 = new list<Order>();
        Order orderInstance = new Order();
        orderInstance.AccountId = customer.Id;
        orderInstance.OpportunityId = opp.Id;
        orderInstance.EffectiveDate = system.today();  
        orderInstance.Status = 'Draft';
        orderInstance.Type = 'Revenue';
        orderInstance.Order_Status__c = 'Pending'; 
        orderInstance.Pricebook2Id = Test.getStandardPricebookId(); 
        orderList2.add(orderInstance);
        orderList2.add(orderInstance.clone(false, false, false, false));
        orderList2.add(orderInstance.clone(false, false, false, false));
        //insert orderInstance;
        insert orderList2;
        
        

        OrderItem orderItemCons = new OrderItem();
        orderItemCons.OrderId = orderInstance.Id;
        orderItemCons.Product2Id = sampleProducts[0].Id;
        orderItemCons.UnitPrice = entries[0].UnitPrice;
        orderItemCons.SBQQ__QuoteLine__c = lines[0].Id;
        orderItemCons.SerialNumber__c = '09092019APMSP1250';        
        orderItemCons.Quantity = 20;
        orderItemCons.PricebookEntryId = entries[0].Id;
        insert orderItemCons;
        
        List<OrderItem> orderItemList = new List<OrderItem>();
        
        OrderItem orderItemAdd1 = new OrderItem();
        orderItemAdd1.OrderId = orderList2[1].Id;
        orderItemAdd1.Product2Id = sampleProducts[1].Id;
        orderItemAdd1.UnitPrice = entries[1].UnitPrice;
        orderItemAdd1.SBQQ__QuoteLine__c = lines[1].Id;
        orderItemAdd1.Quantity = 20;
        orderItemAdd1.SerialNumber__c = '09092019APMSP1251';
        orderItemAdd1.PricebookEntryId = entries[1].Id;
        orderItemList.add(orderItemAdd1);
        
        OrderItem orderItemAdd = new OrderItem();
        orderItemAdd.OrderId = orderList2[2].Id;
        orderItemAdd.Product2Id = sampleProducts[2].Id;
        orderItemAdd.UnitPrice = entries[2].UnitPrice;
       // orderItemAdd.SBQQ__RequiredBy__c = orderItemCons.Id;
        //orderItemAdd.SBQQ__Segmentindex__c = 2; 
        //orderItemAdd.Support_Start_Date__c = System.today();
        //orderItemAdd.MSP_Segment_Product__c = TRUE;
        orderItemAdd.Quantity = 20;
        orderItemAdd.SBQQ__QuoteLine__c = lines[2].Id;
        orderItemAdd.PricebookEntryId = entries[2].Id;
        //insert orderItemAdd;
        orderItemList.add(orderItemAdd);

        OrderItem oi = new OrderItem();
        oi.OrderId = orderList2[2].Id;
        oi.Product2Id = sampleProducts[3].Id;
        oi.UnitPrice = entries[3].UnitPrice;
        oi.SBQQ__Segmentindex__c = 3; 
        oi.Support_Start_Date__c = System.today();
        oi.Quantity = 20;
        //oi.SBQQ__QuoteLine__c = lines[3].Id;
        oi.PricebookEntryId = entries[3].Id;
        orderItemList.add(oi);
        system.debug('***orderItemList'+ orderItemList);
        insert orderItemList;
       
    }
    
    public static testMethod void method2(){ 
        
        List<order> orderList = [select id,(select id , Product2Id from orderItems) from order];
        List<orderItem> orderList1 = [select id , Product2Id from orderItem];
        system.debug('***orderItem*'+ orderList1);
        LinkOrderController.updateHWAndRelatedOrder(orderList[0].id);
    }  
    
    public static testMethod void method3(){ 
        
        List<order> orderList = [select id,(select id , Product2Id from orderItems) from order];
        List<orderItem> orderList1 = [select id , Product2Id,PricebookEntryId,Quantity,UnitPrice from orderItem];
        orderItem oi = orderList1[3].clone(false, false, false, false);
        delete orderList1[3];
        oi.OrderId = orderList[0].Id;
        insert oi; 
        system.debug('***orderItem*'+ orderList1);
        LinkOrderController.updateHWAndRelatedOrder(orderList[0].id);
    }
    
    public static testMethod void method4(){ 
        
        List<order> orderList = [select id,(select id , Product2Id from orderItems) from order];
        //List<orderItem> orderList1 = [select id , Product2Id,PricebookEntryId,Quantity,UnitPrice from orderItem];
        List<product2> prodList = [select id  from product2];
        //orderItem oi = orderList1[3].clone(false, false, false, false);
        //delete orderList1[3];
        //oi.OrderId = orderList[0].Id;
        prodList[0].Product_Level__c = 'LOD Software'; 
        //insert oi; 
        update prodList;
        List<SBQQ__QuoteLine__c>lines = [select id from SBQQ__QuoteLine__c];
        lines[2].SBQQ__RequiredBy__c = lines[0].Id;
        update lines;
        LinkOrderController.updateHWAndRelatedOrder(orderList[0].id);
    }
    @isTest
    Public static void testRefreshedLines(){
        System.runAs(new User(Id=UserInfo.getUserId())) {
            String replaceDet = '{"rowValues":[{"rowId":"20.0", "selectedAsset" : "test1" , "partial_Quantity":"Yes","selectedQty":2,"selectedTerm":12}],"mode":"1to1", "skuSelectedName":"RS-BT-EE-SC-PE-PP", "skuSelected":"01t6f00000NUivYAAT","disposition":"Converted"}';
        List<SBQQ__QuoteLine__c> lstofQli = [Select id,Special_Program__c,Replacement_Details__c from SBQQ__QuoteLine__c limit 5];
        for(SBQQ__QuoteLine__c qli : lstofQli){
            qli.Special_Program__c = Constants.PROGRAM_REFRESH;
            qli.Replacement_Details__c = replaceDet;
        }
        update lstofQli;
        
        List<Order> lstofOrder = [Select id,(select id,program__c from orderitems) from order];
        List<Orderitem> oiToupdate = new List<OrderItem>();
        for(order ord : lstofOrder){
            for(orderitem oi : ord.orderitems){
                oi.program__c = Constants.PROGRAM_REFRESH;
                oiToupdate.add(oi);
            }
        }
        Test.StartTest();
        if(!oiToupdate.isEmpty()){
            update oiToupdate;
        }
        LinkOrderController.updateHWAndRelatedOrder(lstofOrder[0].id);
        System.assert(oiToupdate[0].id != null);
        Test.stopTest();
        }
    }
    @isTest
    Public static void testReplacedLines(){
        System.runAs(new User(Id=UserInfo.getUserId())) {
            String replaceDet = '{"rowValues":[{"rowId":"20.0", "selectedAsset" : "test1" , "partial_Quantity":"Yes","selectedQty":2,"selectedTerm":12}],"mode":"1to1", "skuSelectedName":"RS-BT-EE-SC-PE-PP", "skuSelected":"01t6f00000NUivYAAT","disposition":"Converted"}';
            List<SBQQ__QuoteLine__c> lstofQli = [Select id,Special_Program__c,Replacement_Details__c from SBQQ__QuoteLine__c limit 5];
            for(SBQQ__QuoteLine__c qli : lstofQli){
                qli.Special_Program__c = Constants.PROGRAM_CONVERSION;
                qli.Replacement_Details__c = replaceDet;
            }
            update lstofQli;
            
            List<Order> lstofOrder = [Select id,Line_Types__c,(select id,program__c from orderitems) from order];
            for(Order ord : lstofOrder){
                ord.Line_Types__c = Constants.PROGRAM_CONVERSION;
            }
            
            List<Orderitem> oiToupdate = new List<OrderItem>();
            for(order ord : lstofOrder){
                for(orderitem oi : ord.orderitems){
                    oi.program__c = Constants.PROGRAM_CONVERSION;
                    oiToupdate.add(oi);
                }
            }
            Test.StartTest();
            if(!oiToupdate.isEmpty()){
                update oiToupdate;
            }
            
            if(!lstoforder.isEmpty()){
                update lstoforder;
            }
            LinkOrderController.updateHWAndRelatedOrder(lstofOrder[0].id);
            System.assert(oiToupdate[0].id != null);
            Test.stopTest();
        }
    }
}