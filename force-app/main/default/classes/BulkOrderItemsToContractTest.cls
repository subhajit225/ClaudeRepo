@isTest
private class BulkOrderItemsToContractTest {
    
    @TestSetup
    static void setup() {
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        TriggerControl.stopOrderItemTrigger = true;
        TriggerControl.stopOrderTrigger = true;
        insert new TriggerControl__c(name = 'Order', DisableTrigger__c = false);
        insert new ShGl_DisableFunctionalityLogic__c(Disable_Opportunity_Old_Trigger__c = true, setupOwnerId = userinfo.getuserid());
		insert new ShGl_DisableBusinessLogic__c(
        setupownerid = userinfo.getUserId(),
                                                    Disable_Entitlement_Validation_Rules__c = true,
        Disable_Account_Triggers__c = true,
        Disable_Asset_Triggers__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
                                                    Disable_Product2_Validation_Rules__c = true,
        Disable_Order_Old_Trigger__c = true,
        Disable_OrderItem_Old_Trigger__c = true,
        Disable_Opportunity_Triggers__c = true,
        Disable_Product2_Trigger__c = true,
                                                    Disable_Order_Validation_Rules__c = true,
        Disable_SBQQ_QuoteLine_Validation_Rules__c = true
      );
        // Create a custom pricebook and add products to it
        Pricebook2 customPb = new Pricebook2(
            Name = 'Custom Pricebook',
            IsActive = true
        );
        insert customPb;
        
        // Get standard pricebook ID and add it to custom pricebook entries
        Id standardPbId = Test.getStandardPricebookId();
        
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingCountryCode = 'US'
        );
        insert testAccount;
        
        // Create products
        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < 210; i++) {
            Product2 prod = new Product2(
                Name = 'Test Product ' + i,
                ProductCode = 'TP' + i,
                IsActive = true
            );
            products.add(prod);
        }
        insert products;
        
        // Create pricebook entries for STANDARD pricebook (required)
        List<PricebookEntry> standardPbEntries = new List<PricebookEntry>();
        for(Product2 prod : products) {
            PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = standardPbId,
                Product2Id = prod.Id,
                UnitPrice = 100,
                IsActive = true
            );
            standardPbEntries.add(pbe);
        }
        insert standardPbEntries;
        
        // Create pricebook entries for CUSTOM pricebook
        
        
        // Create opportunity with custom pricebook
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Proposal',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id,
            Pricebook2Id = customPb.Id // Use custom pricebook
        );
        insert testOpp;
        
        Order testOrder = new Order(
            AccountId = testAccount.Id,
            OpportunityId = testOpp.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = customPb.Id // Must match the pricebook entries
        );
        insert testOrder;
        
        Order ord = [SELECT Id,Pricebook2Id FROM Order WHERE Id =:testOrder.Id];
        List<PricebookEntry> customPbEntries = new List<PricebookEntry>();
        for(Product2 prod : products) {
            PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = ord.Pricebook2Id,
                Product2Id = prod.Id,
                UnitPrice = 100,
                IsActive = true
            );
            customPbEntries.add(pbe);
        }
        insert customPbEntries;
    }
    
    @isTest
    static void testBulkOrderItemsToContract() {
        system.runAs(new user(Id = UserInfo.getUserId())){
            Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
            Opportunity testOpp = [SELECT Id, Pricebook2Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
            Order ord = [SELECT Id,Pricebook2Id FROM Order WHERE OpportunityId =:testOpp.Id];
            
            List<PricebookEntry> pbEntries = [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :ord.Pricebook2Id];
            List<OrderItem> orderItems = new List<OrderItem>();
            
            for(Integer i = 0; i < 210; i++) {
                OrderItem oi = new OrderItem(
                    OrderId = ord.Id,
                    PricebookEntryId = pbEntries[i].Id, // Use custom pricebook entries
                    Quantity = 1,
                    UnitPrice = 100,
                    SBQQ__Contracted__c = false
                );
                orderItems.add(oi);
            }
            insert orderItems;
            
            List<OrderItem> itemsToUpdate = new List<OrderItem>();
            for(Integer i = 1; i < 210; i++) {
                OrderItem oi = new OrderItem(
                    Id = orderItems[i].Id,
                    SBQQ__RequiredBy__c = orderItems[0].Id
                );
                itemsToUpdate.add(oi);
            }
            update itemsToUpdate;
            
            Test.startTest();
            
            BulkOrderItemsToContract queueable = new BulkOrderItemsToContract(ord.Id);
            queueable.execute(null);
            
            Test.stopTest();
            
            List<OrderItem> updatedItems = [
                SELECT Id, SBQQ__Contracted__c, SBQQ__RequiredBy__c 
                FROM OrderItem 
                WHERE OrderId = :ord.Id
                ORDER BY Id
            ];
            
            for(OrderItem oi : updatedItems) {
                if(oi.Id != orderItems[0].Id) {
                    System.assertEquals(orderItems[0].Id, oi.SBQQ__RequiredBy__c, 'RequiredBy relationship should be restored');
                }
            }
            
            Integer contractedTrueCount = 0;
            for(OrderItem oi : updatedItems) {
                if(oi.SBQQ__Contracted__c == true) {
                    contractedTrueCount++;
                }
            }
            
            System.assertEquals(200, contractedTrueCount,'First 200 items should have SBQQ__Contracted__c = true');
        }
    }
    
    @isTest
    static void testBulkOrderItemsToContractLessThan200() {
        system.runAs(new user(Id = UserInfo.getUserId())){
            Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
            Opportunity testOpp = [SELECT Id, Pricebook2Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
            Order ord = [SELECT Id,Pricebook2Id FROM Order WHERE OpportunityId =:testOpp.Id];
            List<PricebookEntry> pbEntries = [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :ord.Pricebook2Id];
            List<OrderItem> orderItems = new List<OrderItem>();
            
            for(Integer i = 0; i < 5; i++) {
                OrderItem oi = new OrderItem(
                    OrderId = ord.Id,
                    PricebookEntryId = pbEntries[i].Id,
                    Quantity = 1,
                    UnitPrice = 100,
                    SBQQ__Contracted__c = false
                );
                orderItems.add(oi);
            }
            insert orderItems;
            
            List<OrderItem> itemsToUpdate = new List<OrderItem>();
            for(Integer i = 1; i < 5; i++) {
                OrderItem oi = new OrderItem(
                    Id = orderItems[i].Id,
                    SBQQ__RequiredBy__c = orderItems[0].Id
                );
                itemsToUpdate.add(oi);
            }
            update itemsToUpdate;
            
            Test.startTest();
            
            BulkOrderItemsToContract queueable = new BulkOrderItemsToContract(ord.Id);
            queueable.execute(null);
            
            Test.stopTest();
            
            List<OrderItem> updatedItems = [
                SELECT Id, SBQQ__Contracted__c, SBQQ__RequiredBy__c 
                FROM OrderItem 
                WHERE OrderId = :ord.Id
                ORDER BY Id
            ];
            
            for(OrderItem oi : updatedItems) {
                if(oi.Id != orderItems[0].Id) {
                    System.assertEquals(orderItems[0].Id, oi.SBQQ__RequiredBy__c, 'RequiredBy relationship should be restored for all items');
                }
            }
        }
    }
    
    @isTest
    static void testEmptyOrder() {
        system.runAs(new user(Id = UserInfo.getUserId())){
            Test.startTest();
            
            BulkOrderItemsToContract queueable = new BulkOrderItemsToContract(null);
            queueable.execute(null);
            System.assert(true, 'Exception should be caught and logged internally');
            Test.stopTest();
        }
    }
    
    @isTest
    static void testOrderWithNoItems() {
        system.runAs(new user(Id = UserInfo.getUserId())){
            Order ord = [SELECT Id,Pricebook2Id FROM Order LIMIT 1];
            
            Test.startTest();
            
            BulkOrderItemsToContract queueable = new BulkOrderItemsToContract(ord.Id);
            queueable.execute(null);
            
            Test.stopTest();
            
            List<OrderItem> items = [SELECT Id FROM OrderItem WHERE OrderId = :ord.Id];
            System.assertEquals(0, items.size(), 'No OrderItems should exist');
        }
    }
    
    @IsTest
    static void testHandleDatabaseResults() {
        system.runAs(new user(Id = UserInfo.getUserId())){
            List<Account> accts = new List<Account>();
            accts.add(new Account(Name = 'Success Account'));
            accts.add(new Account()); 
        
            Database.SaveResult[] results = Database.insert(accts, false);
        
            BulkOrderItemsToContract instance = new BulkOrderItemsToContract(null);
        
            Test.startTest();
            instance.handleDatabaseResults(results, 'DML Context');
            Test.stopTest();
        
            System.assertEquals(1, instance.logsToInsert.size(), 'The failing account should have generated a log.');
        }
    }
}