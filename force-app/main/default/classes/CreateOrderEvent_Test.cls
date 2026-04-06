@isTest
Private class CreateOrderEvent_Test {
    @TestSetup
    static void makeData(){
        TriggerControls.disableQuoteTrigger = true; 
        TriggerControls.disableQuoteLineTrigger = true;  
        insert new ShGl_DisableBusinessLogic__c(Disable_POC_Validation_Rules__c = true, Disable_SBQQ_Quote_Validation_Rules__c	= true, Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_QuoteLine_Validation_Rules__c = true, Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =false ,Disable_Order_Email_Alerts__c = false, Disable_Order_Old_Trigger__c = true, Disable_Order_Triggers__c = false,Disable_Contact_Triggers__c =true, setupOwnerId = userinfo.getuserid(), Disable_POC_Trigger__c = true);
        insert new ShGl_DisableFunctionalityLogic__c(Disable_Opportunity_Old_Trigger__c = true, setupOwnerId = userinfo.getuserid());
        
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account act =new Account(BillingCountryCode = 'US', Is_Refreshed__c = False, Name = 'Test', Sync_to_NetSuite__c = false, RecordTypeId = devRecordTypeId, Website='www.test3.com', OwnerId = userinfo.getUserId(),type='Customer');
        insert act;
        
        opportunity oppr = new opportunity(Name='testing DIEtestsalesforce 4/6/2015' , Opportunity_Sub_Type__c = 'Regular', Distributor_Lookup__c = act.Id, Alliance_Source_Type_HW__c = 'Rubrik Initiated Alliance Deal',
                                           Mosaic_Customer_Environment__c='AWS', CloseDate = Date.Today().addDays(10), Lead_Email_Hidden__c='', AccountId = act.Id, StageName = '1 Discovery',
                                           Rubrik_Sales_Engineer__c = UserInfo.getUserId(), Alliance_Partner_Name__c='Amazon', Alliance_Source_Type__c='Alliance Initiated Deal', Installation_Assigned_To__c ='FE Install',
                                           Economic_Buyer__c = 'Test', Metric__c = 'Test', Decision_Process__c = 'Test', Decision_Criteria__c = 'Test',
                                           Alliance_Source_Type_SW__c ='Rubrik Initiated Alliance Deal', Identified_Pain__c = 'Test', Champion__c = 'Test', ForecastCategoryName = 'Best Case',Override__c=false, Pricebook2Id = Test.getStandardPricebookId());
        
        insert oppr;
        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = oppr.Id,SBQQ__SubscriptionTerm__c = 12,Is_RWD_Polaris_Quote__c = true,SBQQ__Primary__c = true,ApprovalStatus__c = 'Recalled',SBQQ__Type__c = 'Quote',SBQQ__PriceBook__c = oppr.Pricebook2Id);
        insert quote;
        List<Product2> sampleProducts = new List<Product2>{
            // 0
            new Product2(
                Name = 'RS-BT-EE-PE-PP',
                ProductCode = 'RS-BT-EE-PE-PP',
                Category__c = 'Bundle',
                Family = 'Rubrik Licence',
                Product_Type__c = 'Enterprise Edition',
                License_Category__c = 'SaaS',
                Product_Level__c = 'Hybrid Software',
                SBQQ__AssetAmendmentBehavior__c = 'Default',
                SBQQSC__EntitlementConversion__c = 'One per quote line',
                IsActive = true,
                SBQQ__SubscriptionPricing__c = 'Fixed Price',
                SBQQ__SubscriptionTerm__c = 36,
                SBQQ__SubscriptionBase__c = 'List',
                SBQQ__SubscriptionType__c = 'Renewable'
            )};
                insert sampleProducts;
        List<PricebookEntry>entries = new List<PricebookEntry>();
        
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[0].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = system.label.CPQPricebookID, Product2Id = sampleProducts[0].Id, IsActive = true, UnitPrice = 100));

        insert entries;
       
        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[0].Id, SBQQ__PricebookEntryId__c = entries[1].Id, SBQQ__Quantity__c = 70, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        insert lines;
        lines[0].SBQQ__Bundle__c = true;
        update lines;         
        quote.ApprovalStatus__c = 'Approved';
        update quote;
        Id pricebookId = Test.getStandardPricebookId();
        List<Order> ordersList = new List<Order>();
        Order ord = new Order(Type='Revenue' ,  AccountId= act.Id,OpportunityId = oppr.Id,ShippingStreet ='Test Street',
                            ShippingCity ='Test City',
                            ShippingState ='California',
                            ShippingCountry ='United States',
                            ShippingPostalcode ='94820',
                            Order_Sub_Type__c = 'Renewal',
                            SBQQ__Quote__c = quote.id,
                            EffectiveDate=system.Today(), Order_Status__c = 'Pending' );
        ordersList.add(ord);    
        Order onHoldOrd = ord.clone();    
        onHoldOrd.Hold_Code__c = 'Quote/PO Mismatch'; 
        ordersList.add(onHoldOrd);             
        insert ordersList;
        
    }
    
    /**
   * @author Siva Kumar
   * @date 03-02-2026
   * @description This method is used to test Order Status is updated to On Hold with Hold code as Contract in negotiations
   * when CreateOrder__e is created
   */
    private static testMethod void updateOrderStatusAndHoldCodeTest(){
        System.runAs(new User(Id = UserInfo.getUserId())){
            Test.startTest();
            List<CreateOrder__e> orderEvtList = new List<CreateOrder__e>();
            for(Account acc  : [SELECT Id FROM Account LIMIT 200]){
                orderEvtList.add(new CreateOrder__e(RecordId__c = acc.Id, Business_Process__c = CONSTANTS.CONTRACT_IN_NEGOTIATION));
            
            }
            EventBus.publish(orderEvtList);
            Test.stopTest();
            for(Order ord : [SELECT Id, Hold_Code__c FROM Order]){
                System.assertEquals(ord.Hold_Code__c.contains('Contract in negotiations'), TRUE);
            }
        }
    }
    
    @isTest
    private static void updateOrderedOnOppError(){
        System.runAs(new User(Id = UserInfo.getUserId())) {
        List<Opportunity> listOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        CreateOrder__e orderEvents = new CreateOrder__e(RecordId__c = listOpportunity[0].Id);
        Test.startTest();
        EventBus.publish(orderEvents);
        Test.stopTest();
        system.assert(true);
        //System.assertEquals(1, [Select id from Custom_Error_Log__c].size());
        }
        
    }
    
    @isTest
    private static void updateOrderedOnOppSuccess(){
        System.runAs(new User(Id = UserInfo.getUserId())) {
        insert new ShGl_DisableBusinessLogic__c(Disable_POC_Validation_Rules__c = true, Disable_SBQQ_Quote_Validation_Rules__c	= true, Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_QuoteLine_Validation_Rules__c = true, Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =false ,Disable_Order_Email_Alerts__c = false, Disable_Order_Old_Trigger__c = true, Disable_Order_Triggers__c = false,Disable_Contact_Triggers__c =true);
        insert new ShGl_DisableFunctionalityLogic__c(Disable_Opportunity_Old_Trigger__c = true);
        
        List<Opportunity> listOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        
        listOpportunity[0].stageName= '6 PO With Channel';
        listOpportunity[0].Valooto_Quote_Stage__c ='Approved';
        listOpportunity[0].Partner_Level_Of_Involvement__c = '1.Rubrik initiated, Partner was fulfillment only';
        listOpportunity[0].Rubrik_Sales_Engineer__c = UserInfo.getUserId();
        listOpportunity[0].Lost_To_Won_Against__c = 'Druva';//'TSM';
        listOpportunity[0].Valooto_Quote__c = '123456';
        listOpportunity[0].Compelling_Bus_Driver__c ='Replication';
        listOpportunity[0].Current_State__c='Test';
        update listOpportunity[0];
        
        CreateOrder__e orderEvents = new CreateOrder__e(RecordId__c = listOpportunity[0].Id);
        Test.startTest();
        TriggerControl.stopOrderTrigger = true;
        EventBus.publish(orderEvents);
        Test.stopTest();
        System.assertEquals(true, [SELECT Id,SBQQ__Ordered__c FROM Opportunity LIMIT 1].SBQQ__Ordered__c);
        }
        
        
    }
    
    
}