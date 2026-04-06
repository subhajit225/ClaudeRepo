@isTest
public class ValootoContractUpdateTest {

    static testMethod void batchTestMethod() {            
        Product2 newProd = new Product2(Name = 'test product', family = 'test family', ProductCode='OPTY-SPLIT');
        insert newProd;
        
        Product2 newProd2 = new Product2(Name = 'test product', family = 'test family', ProductCode='OPTY-SPLIT');
        insert newProd2;

        Pricebook2 pricebook = new Pricebook2(name='Test Price Book', isActive=true);
        insert priceBook;
        
        Id standardPBId = test.getStandardPricebookId();
        PricebookEntry standardPBE = new PricebookEntry(Pricebook2Id = standardPBId, Product2Id = newProd.Id, UnitPrice = 300, IsActive = true);
        insert standardPBE;
        PricebookEntry standardPBE2 = new PricebookEntry(Pricebook2Id = standardPBId, Product2Id = newProd2.Id,UnitPrice = 300, IsActive = true);
        insert standardPBE2;
        
        PriceBookEntry pbEntry = new PriceBookEntry(UnitPrice = 300,PriceBook2Id = pricebook.id,Product2Id = newProd.Id,IsActive = true,
            UseStandardPrice=false);
        insert pbEntry;
        
        PriceBookEntry pbEntry2 = new PriceBookEntry(UnitPrice = 300,PriceBook2Id = pricebook.id,Product2Id = newProd2.Id,IsActive = true,UseStandardPrice=false);
        insert pbEntry2;
        
        Pricebook2 cpqpricebook= new Pricebook2(name='CPQ Pricebook',isActive=true);
        insert cpqpriceBook;
        
        PriceBookEntry cpqpbEntry = new PriceBookEntry(UnitPrice = 300,PriceBook2Id = cpqpriceBook.id,Product2Id = newProd.Id,IsActive = true,UseStandardPrice=false );
        insert cpqpbEntry;
         
        Profile prof = [select id from profile where name LIKE '%System Administrator%'];
        User user = new User(firstName = 'test1',lastName = 'test2',profileId = prof.id,username = 'testvalootoBatch@test.com',
            email = 'testvalootoBatch@test.com',Alias = 'testv', TimeZoneSidKey = 'America/Los_Angeles',EmailEncodingKey = 'UTF-8',LanguageLocaleKey = 'en_US',LocaleSidKey = 'en_US');
        insert user;
        
        ShGl_DisableBusinessLogic__c csIns = new ShGl_DisableBusinessLogic__c(
        Disable_Account_Triggers__c = true,Disable_Asset_Triggers__c = true,Disable_Opportunity_Triggers__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_QuoteLine_Triggers__c = true,Disable_Order_Triggers__c = true,
        setupOwnerId = user.Id);
        insert csIns;  
        
        TriggerControl__c trigCS = new TriggerControl__c(Name = 'Order',DisableTrigger__c = true);
        insert trigCS;
        
        system.runAs(user) {
            Account dummyAcc = new Account(Name='Dummy Account',Phone='123-456-7890', AccountNumber='Test',BillingStreet = '123 street', 
                BillingCity = 'Santa Clara', BillingState = 'California', BillingPostalCode = '95050', BillingCountry = 'United States');
            insert dummyAcc;
               
            Account acc = new Account(Name='Test Account', Phone='123-456-7890', AccountNumber='Test',BillingStreet = '123 street', 
                BillingCity = 'Santa Clara',BillingState = 'California', BillingPostalCode = '95050',BillingCountry = 'United States');
            insert acc;
            
            Opportunity opp= new Opportunity(name='Test Opp',OwnerID=UserInfo.getUserId(),accountId=acc.id,stagename='Approved',
                Amount=1000,closeDate=Date.today());
            insert opp;
            
            Order orderIns = new Order(Type='Revenue',AccountId= acc.Id,OpportunityId = opp.Id,ShippingStreet ='Test Street',
             ShippingCity ='Test City',ShippingState ='California',ShippingCountry ='United States',ShippingPostalcode ='94820',
             EffectiveDate=system.Today(), Order_Status__c = 'Pending', Status = 'Pending' );
            insert orderIns;
            Order od = [ SELECT Id,Pricebook2Id FROM Order where id=:orderIns.id LIMIT 1 ];
            od.Pricebook2Id = priceBook.Id;
            update od;
            
            OrderItem opIns = new OrderItem (Product2Id = newProd.Id,PricebookEntryId = pbEntry.Id,OrderId = od.Id,                    Quantity = 10, UnitPrice = pbEntry.UnitPrice
            );
            insert opIns;
            
            ServiceContract dummyContract = new ServiceContract( AccountId = dummyAcc.id,Name = 'Dummy Service Contract DO NOT DELETE',
            StartDate = System.today()+10,Term = 24,Pricebook2Id = cpqpriceBook.Id);
            insert dummyContract;
            
            ServiceContract testContract = new ServiceContract(AccountId = Acc.id,Name = 'Contract Test- Contract',StartDate = System.today()+10,Convert_Valooto_To_CPQ__c = true,Term = 24,SBQQSC__RenewalTerm__c = 24, Pricebook2Id = priceBook.Id,SBQQSC__Order__c = orderIns.Id);
            insert testContract;
            
            Asset assetIns = new Asset(Name = 'AA181003480111',SerialNumber = 'AA181003480111',Product2Id = newProd.Id,
            AccountId = acc.id);
            insert assetIns;
            
            ContractLineItem cliIns = new ContractLineItem( SBQQSC__Account__c = acc.Id,ServiceContractId = testContract.Id,
                PricebookEntryId = pbEntry.Id,StartDate = system.Today(), UnitPrice = 1000,EndDate = system.Today()+365,
                SBQQSC__Product__c = newProd.Id,SBQQSC__OrderProduct__c = opIns.Id,Quantity = 10,AssetId = assetIns.Id);
            insert cliIns;  
            
            Asset assetUpdate = [ SELECT Id,SBQQSC__CurrentContractLineItem__c  FROM Asset where id=:assetIns.id LIMIT 1 ];
            assetUpdate.SBQQSC__CurrentContractLineItem__c  = cliIns.Id;
            update assetUpdate;

            TriggerControl__c triggerIns = new TriggerControl__c(Name = 'Entitlement', DisableTrigger__c = true);
            insert triggerIns;
            Entitlement entIns = new Entitlement(Name = newProd.Name,AccountId = acc.Id,Product__c = newProd.Id, AssetId = assetUpdate.Id,ServiceContractId = testContract.Id, ContractLineItemId = cliIns.Id);
            insert entIns;
            
            Test.startTest();
                ValootoContractUpdateClass batchIns = new ValootoContractUpdateClass();
                Database.executeBatch(batchIns, 1);
            Test.stopTest();          
        }
    }
    static testMethod void batchTestMethod1() {            
        Product2 newProd = new Product2(Name = 'test product', family = 'test family', ProductCode='OPTY-SPLIT');
        insert newProd;

        Pricebook2 pricebook = new Pricebook2(name='Test Price Book', isActive=true);
        insert priceBook;
        
        Id standardPBId = test.getStandardPricebookId();
        PricebookEntry standardPBE = new PricebookEntry(Pricebook2Id = standardPBId, Product2Id = newProd.Id, UnitPrice = 300, IsActive = true);
        insert standardPBE;
        
        PriceBookEntry pbEntry = new PriceBookEntry(UnitPrice = 300,PriceBook2Id = pricebook.id,Product2Id = newProd.Id,IsActive = true,
            UseStandardPrice=false);
        insert pbEntry;
        
        Pricebook2 cpqpricebook= new Pricebook2(name='CPQ Pricebook',isActive=true);
        insert cpqpriceBook;
         
        Profile prof = [select id from profile where name LIKE '%System Administrator%'];
        User user = new User(firstName = 'test1',lastName = 'test2',profileId = prof.id,username = 'testvalootoBatch@test.com',
            email = 'testvalootoBatch@test.com',Alias = 'testv', TimeZoneSidKey = 'America/Los_Angeles',EmailEncodingKey = 'UTF-8',LanguageLocaleKey = 'en_US',LocaleSidKey = 'en_US');
        insert user;
        
        ShGl_DisableBusinessLogic__c csIns = new ShGl_DisableBusinessLogic__c(
        Disable_Account_Triggers__c = true,Disable_Asset_Triggers__c = true,Disable_Opportunity_Triggers__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_QuoteLine_Triggers__c = true,Disable_Order_Triggers__c = true,
        setupOwnerId = user.Id);
        insert csIns;  
        
        TriggerControl__c trigCS = new TriggerControl__c(Name = 'Order',DisableTrigger__c = true);
        insert trigCS;
        
        system.runAs(user) {
            Account dummyAcc = new Account(Name='Dummy Account',Phone='123-456-7890', AccountNumber='Test',BillingStreet = '123 street', 
                BillingCity = 'Santa Clara', BillingState = 'California', BillingPostalCode = '95050', BillingCountry = 'United States');
            insert dummyAcc;
               
            Account acc = new Account(Name='Test Account', Phone='123-456-7890', AccountNumber='Test',BillingStreet = '123 street', 
                BillingCity = 'Santa Clara',BillingState = 'California', BillingPostalCode = '95050',BillingCountry = 'United States');
            insert acc;
            
            Opportunity opp= new Opportunity(name='Test Opp',OwnerID=UserInfo.getUserId(),accountId=acc.id,stagename='Approved',
                Amount=1000,closeDate=Date.today());
            insert opp;
            
            Order orderIns = new Order(Type='Revenue',AccountId= acc.Id,OpportunityId = opp.Id,ShippingStreet ='Test Street',
             ShippingCity ='Test City',ShippingState ='California',ShippingCountry ='United States',ShippingPostalcode ='94820',
             EffectiveDate=system.Today(), Order_Status__c = 'Pending', Status = 'Pending' );
            insert orderIns;
            Order od = [ SELECT Id,Pricebook2Id FROM Order where id=:orderIns.id LIMIT 1 ];
            od.Pricebook2Id = priceBook.Id;
            update od;
            
            OrderItem opIns = new OrderItem (Product2Id = newProd.Id,PricebookEntryId = pbEntry.Id,OrderId = od.Id,                    Quantity = 10, UnitPrice = pbEntry.UnitPrice
            );
            insert opIns;
            
            ServiceContract dummyContract = new ServiceContract( AccountId = dummyAcc.id,Name = 'Dummy Service Contract DO NOT DELETE',
            StartDate = System.today()+10,Term = 24,Pricebook2Id = cpqpriceBook.Id);
            insert dummyContract;
            
            ServiceContract testContract = new ServiceContract(AccountId = Acc.id,Name = 'Contract Test- Contract',StartDate = System.today()+10,Convert_Valooto_To_CPQ__c = true,Term = 24,SBQQSC__RenewalTerm__c = 24, Pricebook2Id = priceBook.Id,SBQQSC__Order__c = orderIns.Id);
            insert testContract;
            
            Asset assetIns = new Asset(Name = 'AA181003480111',SerialNumber = 'AA181003480111',Product2Id = newProd.Id,
            AccountId = acc.id);
            insert assetIns;
            
            ContractLineItem cliIns = new ContractLineItem( SBQQSC__Account__c = acc.Id,ServiceContractId = testContract.Id,
                PricebookEntryId = pbEntry.Id,StartDate = system.Today(), UnitPrice = 1000,EndDate = system.Today()+365,
                SBQQSC__Product__c = newProd.Id,SBQQSC__OrderProduct__c = opIns.Id,Quantity = 10,AssetId = assetIns.Id);
            insert cliIns;  
            
            Asset assetUpdate = [ SELECT Id,SBQQSC__CurrentContractLineItem__c  FROM Asset where id=:assetIns.id LIMIT 1 ];
            assetUpdate.SBQQSC__CurrentContractLineItem__c  = cliIns.Id;
            update assetUpdate;

            TriggerControl__c triggerIns = new TriggerControl__c(Name = 'Entitlement', DisableTrigger__c = true);
            insert triggerIns;
            Entitlement entIns = new Entitlement(Name = newProd.Name,AccountId = acc.Id,Product__c = newProd.Id, AssetId = assetUpdate.Id,ServiceContractId = testContract.Id, ContractLineItemId = cliIns.Id);
            insert entIns;
            
            Test.startTest();
                ValootoContractUpdateClass batchIns = new ValootoContractUpdateClass();
                Database.executeBatch(batchIns, 1);
            Test.stopTest();          
        }
    }
}