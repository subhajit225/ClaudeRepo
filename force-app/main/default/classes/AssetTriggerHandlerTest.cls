@isTest
private class AssetTriggerHandlerTest {
    /*
    @testSetup
    static void testSetup() {

    }

    @isTest
    static void testPreventChangeAssetFields() {
        insert new list<TriggerControl__c> {
           new TriggerControl__c(Name='Contact', DisableTrigger__c=false),
           new TriggerControl__c(Name='Opportunity', DisableTrigger__c=false),
           new TriggerControl__c(Name='Entitlement', DisableTrigger__c=false),
           new TriggerControl__c(Name='Asset', DisableTrigger__c=false)
        };
        insert new Test_Controls__c(Bypass_Pricebook_Setting_on_Opp__c = true, Bypass_Pricebook_Setting_on_Quote__c = true);

        insert new PatchManagerSettings__c(Default_User_Id__c = UserInfo.getUserId(), Default_Account_User__c = UserInfo.getUserId());

        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Allow_Asset_Product_Account_Updates__c = true;
        insert disableFuncCS;

        Account acct = new Account(
            Name = 'Test Account',
            Phone = '123-456-7890',
            AccountNumber = 'Test',
            BillingStreet = '123 street',
            BillingCity = 'Santa Clara',
            BillingState = 'California',
            BillingPostalCode = '95050',
            BillingCountry = 'United States'
        );
        Account acctUnassigned = new Account(
            Name = 'Unassigned',
            Phone = '123-456-7890',
            AccountNumber = 'Test',
            BillingStreet = '123 street',
            BillingCity = 'Santa Clara',
            BillingState = 'California',
            BillingPostalCode = '95050',
            BillingCountry = 'United States'
        );
        insert new List<Account>{acct, acctUnassigned};

        OpportunityStage stage = [Select MasterLabel From OpportunityStage Where IsWon=false and IsClosed=false and isActive=true Limit 1];
        Opportunity opp = TestDataFactory.getOpportunity(acctUnassigned);
        
        opp.StageName = stage.MasterLabel;
        opp.PriceBook2Id = Test.getStandardPricebookId();
        opp.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
        insert opp;
        List<Order> ordList = new List<Order>();
        ordList.add(new Order(Type='Revenue',  AccountId=ACCT.Id, OpportunityId=OPP.Id, ShippingStreet ='123 Shipping Street', ShippingCity ='Shipping City',
            ShippingState ='California', ShippingCountry ='United States', ShippingPostalcode ='94820', EffectiveDate=system.Today(), Status='Pending'));
        ordList.add(new Order(Type='POC',  AccountId=ACCT.Id, OpportunityId=OPP.Id, ShippingStreet ='123 Shipping Street', ShippingCity ='Shipping City',
            ShippingState ='California', ShippingCountry ='United States', ShippingPostalcode ='94820', EffectiveDate=system.Today(), Status='Pending',
             recordtypeId=Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId()));
        insert ordList;

        ordList[0].PriceBook2Id = ordList[1].PriceBook2Id =Test.getStandardPricebookId();
        update ordList;

        List<Product2> products = new List<Product2> {
            //apliance
            new Product2(
                Name = 'RBK-R348-01',
                ProductCode = 'RBK-R348-01',
                Category__c = 'Platform',
                Family = 'R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'R348',
                Appliance_Model_HW__c = 'R348',
                Create_Asset_Entitlement__c = true,
                Asset_Priority__c = 0,
                IsActive = true
            ),
            new Product2(
                Name = 'RBK-R348S-UG-01',
                ProductCode = 'RBK-R348S-UG-01',
                Category__c = 'Software',
                Family = 'R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'RBK-R348S',
                Appliance_Model_HW__c = 'R348',
                Single_Entitlement__c = true,
                Asset_Priority__c = 0,
                IsActive = true
            ),
            new Product2(Name = 'RBK-R348-01-NFR',
                ProductCode = 'RBK-R348-01-NFR',
                Category__c = 'NFR',
                Family = 'RBK-R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'R348',
                Appliance_Model_HW__c = 'R348',
                Create_Asset_Entitlement__c = true,
                Asset_Priority__c = 0,
                IsActive = true
            )
        };
        insert products;
        products.get(1).Asset_Upgrade_Product__c = products.get(0).Id;
        update products.get(1);

        Test.startTest();

        PricebookEntry pbEntry1 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = products.get(1).Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry1;

        OrderItem ordItem = new OrderItem(
            OrderId = ordList[0].Id,
            Quantity = 1,
            PricebookEntryId = pbEntry1.Id,
            UnitPrice = pbEntry1.UnitPrice,
            SerialNumber__c = 'SN1',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        OrderItem ordItem2 = new OrderItem(
            OrderId = ordList[0].Id,
            Quantity = 1,
            PricebookEntryId = pbEntry1.Id,
            UnitPrice = pbEntry1.UnitPrice,
            SerialNumber__c = 'SN2',
            Support_End_Date__c = System.Today().addYears(2),
            Support_Start_Date__c = System.Today().addYears(1)
        );
        OrderItem ordItem3 = new OrderItem(
            OrderId = ordList[1].Id,
            Quantity = 1,
            PricebookEntryId = pbEntry1.Id,
            UnitPrice = pbEntry1.UnitPrice,
            SerialNumber__c = 'SN2',
            Support_End_Date__c = System.Today().addYears(2),
            Support_Start_Date__c = System.Today().addYears(1)
        );
        insert new List<OrderItem>{ordItem, ordItem2,ordItem3};


        List<Asset> assets = new list<Asset> {
            new Asset(Name = 'SN1', PurchaseDate = System.today(), Support_Start_Date__c = System.today(), SerialNumber = 'SN1', Serial_Number__c = 'SN1', Product2Id = products[1].Id, Accountid = acct.Id, Order_Service_Item__c = ordItem.Id),
            new Asset(Name = 'SN2', PurchaseDate = System.today(), Support_Start_Date__c = System.today(), SerialNumber = 'SN2', Serial_Number__c = 'SN2', Product2Id = products[1].Id, Accountid = acct.Id, Order_Service_Item__c = ordItem.Id),
            new Asset(Name = 'SN3', PurchaseDate = System.today(), Support_Start_Date__c = System.today(), SerialNumber = 'SN3', Serial_Number__c = 'SN3', Product2Id = products[0].Id, Accountid = acctUnassigned.Id),
            new Asset(Name = 'SN4', PurchaseDate = System.today(), Support_Start_Date__c = System.today(), SerialNumber = 'SN4', Serial_Number__c = 'SN4', Product2Id = products[0].Id, Accountid = acctUnassigned.Id),
            new Asset(Name = 'SN5', PurchaseDate = System.today(), Support_Start_Date__c = System.today(), SerialNumber = 'SN5', Serial_Number__c = 'SN5', Product2Id = products[0].Id, Order_Service_Item__c = ordItem3.Id)
        };
        insert assets;
        AssetTriggerHelper.preventChangeFields(assets);
        List<Entitlement> entitlements = new List<Entitlement> {
            new Entitlement(Name = 'ENT-1', Type = 'Phone Support', AccountId = acct.Id, StartDate = Date.valueof(System.now().addDays(-2)), EndDate = Date.valueof(System.now().addYears(2)), AssetId = assets.get(0).Id, Product__c = products.get(1).Id,Order_Service_Item__c = ordItem.id),
            new Entitlement(Name = 'ENT-2', Type = 'Phone Support', AccountId = acct.Id, StartDate = Date.valueof(System.now().addDays(-2)), EndDate = Date.valueof(System.now().addYears(2)), AssetId = assets.get(1).Id, Product__c = products.get(1).Id,Order_Service_Item__c = ordItem.id),
            new Entitlement(Name = 'ENT-3', Type = 'Web Support', AccountId = acct.Id, StartDate = Date.valueof(System.now().addDays(-2)), EndDate = Date.valueof(System.now().addYears(2)), AssetId = assets.get(2).Id, Product__c = products.get(0).Id,Order_Service_Item__c = ordItem.id),
            new Entitlement(Name = 'ENT-4', Type = 'Web Support', AccountId = acct.Id, StartDate = Date.valueof(System.now().addDays(-2)), EndDate = Date.valueof(System.now().addYears(2)), AssetId = assets.get(3).Id, Product__c = products.get(0).Id,Order_Service_Item__c = ordItem.id)
        };
        insert entitlements;


        List<Asset> assetsBefore = [SELECT Id, PurchaseDate, Support_Start_Date__c,Order_Service_Item__c FROM Asset WHERE Name IN ('SN1','SN2','SN3','SN4','SN5')];
        //Test.startTest();
        for(Asset asset : assetsBefore) {
            asset.PurchaseDate = asset.PurchaseDate.addYears(1);
            asset.Support_Start_Date__c = asset.Support_Start_Date__c.addYears(1);
            asset.Order_Service_Item__c = ordItem2.Id;
            asset.Product2Id = products.get(2).Id;
            asset.SBQQ__QuoteLine__c =null;   
            if(asset.name =='SN5'){
             asset.Order_Service_Item__c = assetsBefore[0].Order_Service_Item__c;
            }
            asset.Is_Refreshed__c =true;
            asset.UsageEndDate = system.today().addmonths(1);
        }
        system.debug('CP GoREfresh check'+assetsBefore);
        update assetsBefore;
        Test.stopTest();

        for(Asset asset : [SELECT Id, Account.Name, Name, PurchaseDate, Support_Start_Date__c, Product2Id, Order_Service_Item__c FROM Asset WHERE Id IN :assetsBefore]) {
            if('SN1' == asset.Name) {
                System.assertNotEquals(null, asset.Account.Name);
                System.assertEquals(System.today(), asset.PurchaseDate);
                System.assertEquals(System.today(), asset.Support_Start_Date__c);
                System.assertEquals(ordItem.Id, asset.Order_Service_Item__c);
                //System.assertEquals(products.get(0).Id, asset.Product2Id);
            }
            else if('SN2' == asset.Name) {
                System.assertNotEquals(null, asset.Account.Name);
                System.assertEquals(System.today(), asset.PurchaseDate);
                System.assertEquals(System.today(), asset.Support_Start_Date__c);
                System.assertEquals(ordItem.Id, asset.Order_Service_Item__c);
                //System.assertEquals(products.get(0).Id, asset.Product2Id);
            }
            else if('SN3' == asset.Name) {
                System.assertEquals('Unassigned', asset.Account.Name);
                System.assertEquals(System.today().addYears(1), asset.PurchaseDate);
                System.assertEquals(System.today().addYears(1), asset.Support_Start_Date__c);
                System.assertEquals(ordItem2.Id, asset.Order_Service_Item__c);
                System.assertEquals(products.get(2).Id, asset.Product2Id);
            }
            else if('SN4' == asset.Name) {
                System.assertEquals('Unassigned', asset.Account.Name);
                System.assertEquals(System.today().addYears(1), asset.PurchaseDate);
                System.assertEquals(System.today().addYears(1), asset.Support_Start_Date__c);
                System.assertEquals(ordItem2.Id, asset.Order_Service_Item__c);
                System.assertEquals(products.get(2).Id, asset.Product2Id);
            }
        }
        delete assetsBefore;
        undelete assetsBefore;
        AssetTriggerHelper.allowAssetOIUpdates(true);
        AssetTriggerHelper.allowSupportStartDateUpdate(true);
    }

    @isTest
    static void testBypassPreventChangeAssetFieldsByCustomSetting() {
        insert new list<TriggerControl__c> {
           new TriggerControl__c(Name='Contact', DisableTrigger__c=false),
           new TriggerControl__c(Name='Opportunity', DisableTrigger__c=false),
           new TriggerControl__c(Name='Entitlement', DisableTrigger__c=false),
           new TriggerControl__c(Name='Asset', DisableTrigger__c=false)
        };
        insert new Test_Controls__c(Bypass_Pricebook_Setting_on_Opp__c = true, Bypass_Pricebook_Setting_on_Quote__c = true);

        insert new PatchManagerSettings__c(Default_User_Id__c = UserInfo.getUserId(), Default_Account_User__c = UserInfo.getUserId());

        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Allow_Asset_Product_Account_Updates__c = false;
        insert disableFuncCS;

        Account acct = new Account(
            Name = 'Test Account',
            Phone = '123-456-7890',
            AccountNumber = 'Test',
            BillingStreet = '123 street',
            BillingCity = 'Santa Clara',
            BillingState = 'California',
            BillingPostalCode = '95050',
            BillingCountry = 'United States'
        );
        insert new List<Account>{acct};

        OpportunityStage stage = [Select MasterLabel From OpportunityStage Where IsWon=false and IsClosed=false and isActive=true Limit 1];
        Opportunity opp = TestDataFactory.getOpportunity(acct);
        
        opp.StageName = stage.MasterLabel;
        opp.PriceBook2Id = Test.getStandardPricebookId();
        opp.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
        insert opp;

        Order ord = new Order(Type='Revenue',  AccountId=ACCT.Id, OpportunityId=OPP.Id, ShippingStreet ='123 Shipping Street', ShippingCity ='Shipping City',
            ShippingState ='California', ShippingCountry ='United States', ShippingPostalcode ='94820', EffectiveDate=system.Today(), Status='Pending');
        insert ord;

        ord.PriceBook2Id = Test.getStandardPricebookId();
        update ord;

        List<Product2> products = new List<Product2> {
            //apliance
            new Product2(
                Name = 'RBK-R348-01',
                ProductCode = 'RBK-R348-01',
                Category__c = 'Platform',
                Family = 'R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'R348',
                Appliance_Model_HW__c = 'R348',
                Create_Asset_Entitlement__c = true,
                Asset_Priority__c = 0,
                IsActive = true
            ),
            new Product2(
                Name = 'RBK-R348S-UG-01',
                ProductCode = 'RBK-R348S-UG-01',
                Category__c = 'Software',
                Family = 'R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'RBK-R348S',
                Appliance_Model_HW__c = 'R348',
                Single_Entitlement__c = true,
                Asset_Priority__c = 0,
                IsActive = true
            ),
            new Product2(Name = 'RBK-R348-01-NFR',
                ProductCode = 'RBK-R348-01-NFR',
                Category__c = 'NFR',
                Family = 'RBK-R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'R348',
                Appliance_Model_HW__c = 'R348',
                Create_Asset_Entitlement__c = true,
                Asset_Priority__c = 0,
                IsActive = true
            )
        };
        insert products;
        products.get(1).Asset_Upgrade_Product__c = products.get(0).Id;
        update products.get(1);

        Test.startTest();

        PricebookEntry pbEntry1 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = products.get(1).Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry1;

        OrderItem ordItem = new OrderItem(
            OrderId = ord.Id,
            Quantity = 1,
            PricebookEntryId = pbEntry1.Id,
            UnitPrice = pbEntry1.UnitPrice,
            SerialNumber__c = 'SN1',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        OrderItem ordItem2 = new OrderItem(
            OrderId = ord.Id,
            Quantity = 1,
            PricebookEntryId = pbEntry1.Id,
            UnitPrice = pbEntry1.UnitPrice,
            SerialNumber__c = 'SN2',
            Support_End_Date__c = System.Today().addYears(2),
            Support_Start_Date__c = System.Today().addYears(1)
        );
        insert new List<OrderItem>{ordItem, ordItem2};


        List<Asset> assets = new list<Asset> {
            new Asset(Name = 'SN1', PurchaseDate = System.today(), Support_Start_Date__c = System.today(), SerialNumber = 'SN1', Serial_Number__c = 'SN1', Product2Id = products[1].Id, Accountid = acct.Id, Order_Service_Item__c = ordItem.Id),
            new Asset(Name = 'SN2', PurchaseDate = System.today(), Support_Start_Date__c = System.today(), SerialNumber = 'SN2', Serial_Number__c = 'SN2', Product2Id = products[1].Id, Accountid = acct.Id, Order_Service_Item__c = ordItem.Id)
        };
        insert assets;

        List<Entitlement> entitlements = new List<Entitlement> {
            new Entitlement(Name = 'ENT-1', Type = 'Phone Support', AccountId = acct.Id, StartDate = Date.valueof(System.now().addDays(-2)), EndDate = Date.valueof(System.now().addYears(2)), AssetId = assets.get(0).Id, Product__c = products.get(1).Id,Order_Service_Item__c = ordItem.id),
            new Entitlement(Name = 'ENT-2', Type = 'Phone Support', AccountId = acct.Id, StartDate = Date.valueof(System.now().addDays(-2)), EndDate = Date.valueof(System.now().addYears(2)), AssetId = assets.get(1).Id, Product__c = products.get(1).Id,Order_Service_Item__c = ordItem.id)
        };
        insert entitlements;

        List<Asset> assetsBefore = [SELECT Id, PurchaseDate, Support_Start_Date__c FROM Asset WHERE Name IN ('SN1','SN2')];
        System.assertEquals(2, assetsBefore.size());
        for(Asset asset : assetsBefore) {
            System.assertEquals(System.today(), asset.PurchaseDate);
            System.assertEquals(System.today(), asset.Support_Start_Date__c);
        }

        //Test.startTest();
        for(Asset asset : assetsBefore) {
            asset.PurchaseDate = asset.PurchaseDate.addYears(1);
            asset.Support_Start_Date__c = asset.Support_Start_Date__c.addYears(1);
            asset.Order_Service_Item__c = ordItem2.Id;
            asset.Product2Id = products.get(2).Id;
        }
        update assetsBefore;
        Test.stopTest();

        for(Asset asset : [SELECT Id, Account.Name, Name, PurchaseDate, Support_Start_Date__c, Product2Id, Order_Service_Item__c FROM Asset WHERE Id IN :assetsBefore]) {
            if('SN1' == asset.Name) {
                System.assertNotEquals(null, asset.Account.Name);
                System.assertEquals(System.today(), asset.PurchaseDate);
                System.assertEquals(System.today(), asset.Support_Start_Date__c);
                System.assertEquals(ordItem.Id, asset.Order_Service_Item__c);
                //System.assertEquals(products.get(0).Id, asset.Product2Id);
            }
            else if('SN2' == asset.Name) {
                System.assertNotEquals(null, asset.Account.Name);
                System.assertEquals(System.today(), asset.PurchaseDate);
                System.assertEquals(System.today(), asset.Support_Start_Date__c);
                System.assertEquals(ordItem.Id, asset.Order_Service_Item__c);
                //System.assertEquals(products.get(0).Id, asset.Product2Id);
            }
        }
        delete assetsBefore;
        undelete assetsBefore;

    }

    @isTest
    static void testBypassPreventChangeAssetFieldsByAssetFlag() {
        insert new list<TriggerControl__c> {
           new TriggerControl__c(Name='Contact', DisableTrigger__c=false),
           new TriggerControl__c(Name='Opportunity', DisableTrigger__c=false),
           new TriggerControl__c(Name='Entitlement', DisableTrigger__c=false),
           new TriggerControl__c(Name='Asset', DisableTrigger__c=false)
        };
        insert new Test_Controls__c(Bypass_Pricebook_Setting_on_Opp__c = true, Bypass_Pricebook_Setting_on_Quote__c = true);

        insert new PatchManagerSettings__c(Default_User_Id__c = UserInfo.getUserId(), Default_Account_User__c = UserInfo.getUserId());

        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Allow_Asset_Product_Account_Updates__c = true;
        insert disableFuncCS;

        Account acct = new Account(
            Name = 'Test Account',
            Phone = '123-456-7890',
            AccountNumber = 'Test',
            BillingStreet = '123 street',
            BillingCity = 'Santa Clara',
            BillingState = 'California',
            BillingPostalCode = '95050',
            BillingCountry = 'United States'
        );
        insert acct;

        OpportunityStage stage = [Select MasterLabel From OpportunityStage Where IsWon=false and IsClosed=false and isActive=true Limit 1];
        Opportunity opp = TestDataFactory.getOpportunity(acct);
        
        opp.StageName = stage.MasterLabel;
        opp.PriceBook2Id = Test.getStandardPricebookId();
        opp.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
        insert opp;

        Order ord = new Order(Type='Revenue',  AccountId=ACCT.Id, OpportunityId=OPP.Id, ShippingStreet ='123 Shipping Street', ShippingCity ='Shipping City',
            ShippingState ='California', ShippingCountry ='United States', ShippingPostalcode ='94820', EffectiveDate=system.Today(), Status='Pending');
        insert ord;

        ord.PriceBook2Id = Test.getStandardPricebookId();
        update ord;

        List<Product2> products = new List<Product2> {
            //apliance
            new Product2(
                Name = 'RBK-R348-01',
                ProductCode = 'RBK-R348-01',
                Category__c = 'Platform',
                Family = 'R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'R348',
                Appliance_Model_HW__c = 'R348',
                Create_Asset_Entitlement__c = true,
                Asset_Priority__c = 0,
                IsActive = true
            ),
            new Product2(
                Name = 'RBK-R348S-UG-01',
                ProductCode = 'RBK-R348S-UG-01',
                Category__c = 'Software',
                Family = 'R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'RBK-R348S',
                Appliance_Model_HW__c = 'R348',
                Single_Entitlement__c = true,
                Asset_Priority__c = 0,
                IsActive = true
            ),
            new Product2(Name = 'RBK-R348-01-NFR',
                ProductCode = 'RBK-R348-01-NFR',
                Category__c = 'NFR',
                Family = 'RBK-R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'R348',
                Appliance_Model_HW__c = 'R348',
                Create_Asset_Entitlement__c = true,
                Asset_Priority__c = 0,
                IsActive = true
            )
        };
        insert products;
        products.get(1).Asset_Upgrade_Product__c = products.get(0).Id;
        update products.get(1);

        Test.startTest();

        PricebookEntry pbEntry1 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = products.get(1).Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry1;

        OrderItem ordItem = new OrderItem(
            OrderId = ord.Id,
            Quantity = 1,
            PricebookEntryId = pbEntry1.Id,
            UnitPrice = pbEntry1.UnitPrice,
            SerialNumber__c = 'SN1',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        OrderItem ordItem2 = new OrderItem(
            OrderId = ord.Id,
            Quantity = 1,
            PricebookEntryId = pbEntry1.Id,
            UnitPrice = pbEntry1.UnitPrice,
            SerialNumber__c = 'SN2',
            Support_End_Date__c = System.Today().addYears(2),
            Support_Start_Date__c = System.Today().addYears(1)
        );
        insert new List<OrderItem>{ordItem, ordItem2};


        List<Asset> assets = new list<Asset> {
            new Asset(Bypass_Account_and_Product_Update__c = false, Name = 'SN1', PurchaseDate = System.today(), Support_Start_Date__c = System.today(), SerialNumber = 'SN1', Serial_Number__c = 'SN1', Product2Id = products[1].Id, Accountid = acct.Id, Order_Service_Item__c = ordItem.Id),
            new Asset(Bypass_Account_and_Product_Update__c = true, Name = 'SN2', PurchaseDate = System.today(), Support_Start_Date__c = System.today(), SerialNumber = 'SN2', Serial_Number__c = 'SN2', Product2Id = products[1].Id, Accountid = acct.Id, Order_Service_Item__c = ordItem.Id)
        };
        insert assets;

        List<Entitlement> entitlements = new List<Entitlement> {
            new Entitlement(Name = 'ENT-1', Type = 'Phone Support', AccountId = acct.Id, StartDate = Date.valueof(System.now().addDays(-2)), EndDate = Date.valueof(System.now().addYears(2)), AssetId = assets.get(0).Id, Product__c = products.get(1).Id,Order_Service_Item__c = ordItem.id),
            new Entitlement(Name = 'ENT-2', Type = 'Phone Support', AccountId = acct.Id, StartDate = Date.valueof(System.now().addDays(-2)), EndDate = Date.valueof(System.now().addYears(2)), AssetId = assets.get(1).Id, Product__c = products.get(1).Id,Order_Service_Item__c = ordItem.id)
        };
        insert entitlements;

        List<Asset> assetsBefore = [SELECT Id, PurchaseDate, Support_Start_Date__c FROM Asset WHERE Name IN ('SN1','SN2')];
        System.assertEquals(2, assetsBefore.size());
        for(Asset asset : assetsBefore) {
            System.assertEquals(System.today(), asset.PurchaseDate);
            System.assertEquals(System.today(), asset.Support_Start_Date__c);
        }

        //Test.startTest();
        for(Asset asset : assetsBefore) {
            asset.PurchaseDate = asset.PurchaseDate.addYears(1);
            asset.Support_Start_Date__c = asset.Support_Start_Date__c.addYears(1);
            asset.Order_Service_Item__c = ordItem2.Id;
            asset.Product2Id = products.get(2).Id;
        }
        update assetsBefore;
        Test.stopTest();

        for(Asset asset : [SELECT Id, Account.Name, Name, PurchaseDate, Support_Start_Date__c, Product2Id, Order_Service_Item__c FROM Asset WHERE Id IN :assetsBefore]) {
            if('SN1' == asset.Name) {
                System.assertNotEquals(null, asset.Account.Name);
                System.assertEquals(System.today(), asset.PurchaseDate);
                System.assertEquals(System.today(), asset.Support_Start_Date__c);
                System.assertEquals(ordItem.Id, asset.Order_Service_Item__c);
                //System.assertEquals(products.get(0).Id, asset.Product2Id);
            }
            else if('SN2' == asset.Name) {
                System.assertNotEquals(null, asset.Account.Name);
                System.assertEquals(System.today(), asset.PurchaseDate);
                System.assertEquals(System.today(), asset.Support_Start_Date__c);
                System.assertEquals(ordItem.Id, asset.Order_Service_Item__c);
                //System.assertEquals(products.get(0).Id, asset.Product2Id);
            }
        }
        delete assetsBefore;
        undelete assetsBefore;

    }
    */
    @testSetup
    static void testSetup() {
        insert new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Triggers__c = true, 
                                                Disable_SBQQ_QuoteLine_Triggers__c = true,
                                                Disable_Account_Triggers__c = true,
                                                Disable_POC_Trigger__c = true,
                                                Disable_Lead_Triggers__c = true,
                                                Disable_Lead_Validation_Rules__c = true,
                                                Disable_OrderItem_Old_Trigger__c = true,
                                                Disable_Opportunity_Triggers__c = true ,
                                                Disable_Opportunity_Validation_Rules__c = true,
                                                Disable_Order_Email_Alerts__c = true, 
                                                Disable_Order_Old_Trigger__c = true, 
                                                Disable_Order_Triggers__c = true, 
                                                Disable_Asset_Triggers__c = false,
                                                setupOwnerId = userinfo.getuserid()); 
        
        ShGl_TestFactoryHelper.WorkflowTriggerBypass();
        TriggerControl__c custsetting = new TriggerControl__c(Name='Opportunity',DisableTrigger__c=true);
        TriggerControl__c PortalUserCreation = new TriggerControl__c(Name='PortalUserCreation');
        insert new List<TriggerControl__c>{custsetting,PortalUserCreation};
        
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance(); 
        disableFuncCS.Disable_Order_Old_Trigger__c = true;
        insert disableFuncCS;
        
        StateNameCode__c custset = new StateNameCode__c(Name='California',Code__c='US-CA');
        insert custset;
        
        //Generate Account
        Account acct = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        acct.Contract_Status__c = 'Not signed';
        acct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Distributor').getRecordTypeId();
        insert acct;
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => acct.Id,
                'Email'  =>'leademail@hidden.com'
                };
        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);        
        insert cnt1;
        User user = new User();
        user.Id ='00540000003tvRQ';
        
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => acct.Id,
                'Initial_Contacts_Name__c' => cnt1.Id,
                'Primary_Competitor__c' => 'Other',
                'Other_Primary_Competitor__c' => 'Other',
                'Other_Competitor_Field__c' => 'Other',
                'Lost_To_Won_Against__c' => 'Other',
                'Polaris_Region__c' => 'US'        
            };
        Opportunity oppty = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        oppty.ForecastCategoryName = 'Best Case';
		oppty.Partner_Lookup__c = acct.Id; 
		oppty.Opportunity_Sub_Type__c = 'Renewal'; 
        insert oppty;
        
        //Generate POC records
        Map<String, Object>  pocMap = new Map<String, Object> {
            'POC_Duration__c' => '60 Days',
            'Planned_Installation_Date__c' => System.Today()+30,
            'Support_Awareness_needed__c' => 'Yes'
        };
        Map<String, Object>  pocMap2 = new Map<String, Object> {
            'POC_Duration__c' => '30 Days',
            'Planned_Installation_Date__c' => System.Today()+30,
            'Support_Awareness_needed__c' => 'Yes'
        };  
        User testUser = new User();
        testUser.id='00540000003tvRQ';
        POC__c poc1 = (POC__c) ShGl_TestFactory.createSObject(new POC__c(), pocMap);
        poc1.POC_Type__c = 'Standard POC';        
        POC__c poc2 = (POC__c) ShGl_TestFactory.createSObject(new POC__c(), pocMap2);     
        poc2.POC_Type__c = 'Standard POC';
         system.runAs(testUser)
      {
           
          insert new List<POC__c>{poc1,poc2};
            
        }
        Map<String, Object>  prodMap = new Map<String, Object> {
            'Name' => 'X-0001-01',
            'ProductCode' => 'ProductXYZ',
            'isActive' => true,
            'Family' => 'POLARIS',
            'Product_Type__c' => 'Appliance'
        };            
        Map<String, Object>  prodMap2 = new Map<String, Object> {
            'Name' => 'X-0001-01',
            'ProductCode' => 'ProductXYZ',
            'isActive' => true,
            'Family' => 'POLARIS',
            'Product_Type__c' => 'GPS'
        };                
        Map<String, Object>  prodMap3 = new Map<String, Object> {
            'Name' => 'X-0001-01',
            'ProductCode' => 'ProductXYZ',
            'isActive' => true,
            'Family' => 'POLARIS',
            'Product_Type__c' => 'RADAR'
        };
                    
        Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);  
        Product2 pd2 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap2);
        Product2 pd3 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap3); 
        
        insert new List<Product2>{pd, pd2, pd3};
        
        //Generate SBQQ
        Map<String, Object>  quoteMap = new Map<String, Object> {
            'SBQQ__Account__c' => acct.Id,
                'SBQQ__Opportunity2__c' => oppty.Id
        };
            
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppty.Id;
        qt1.SBQQ__Primary__c = true;
		qt1.SBQQ__Account__c = acct.Id;
        qt1.SBQQ__PriceBook__c = Test.getStandardPricebookId();
        insert qt1;
        
        qt1.ApprovalStatus__c = 'Approved';
        update qt1;
        
        //Generate Lead
        Lead led = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
        led.Country = 'USA';
        insert led;
        
        oppty.Deal_Registration_Link__c = led.Id;
        oppty.Partner_Lookup__c = acct.Id; 
        oppty.pricebook2Id = Test.getStandardPricebookId();
        oppty.StageName = System.Label.Order_Creation_Stage;
        oppty.Partner_Level_Of_Involvement__c = '4.Partner or joint initiated opportunity, partner brought substantial value in sales cycle and getting deal closed';
        oppty.SBQQ__PrimaryQuote__c = qt1.Id;
        oppty.Installation_Assigned_To__c = 'Partner Install';
        update oppty;
        
        //Generate Order
        Map<String, Object>  orderMap = new Map<String, Object> {
            'Status' => 'Draft',
            'AccountId' => acct.Id,
            'OpportunityId' => oppty.Id,
            'EffectiveDate' => Date.Today(),
            /*'ship_To_Name__c' => acct.Id,*/
            'Type' => 'Revenue',
            'Est_Ship_Date__c' => system.today(),
            'Order_Status__c' => 'Change Needed',
            'Hold_Code__c' => 'Delayed Ship Date',
            'POC_Request__c' => poc2.id,
            'RecordTypeId' => Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId(),
            'Pricebook2Id' => Test.getStandardPricebookId()
        };
        Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), orderMap);
        ord.Order_Status__c = 'Pending';
        ord.Hold_Code__c = 'End Customer PO# Missing';
        insert ord;
        
        Order ord1 = [ SELECT Id,Pricebook2Id FROM Order where id = :ord.id LIMIT 1 ];
        ord1.Pricebook2Id = Test.getStandardPricebookId();
        update ord1;
        
        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = pd.Id, UnitPrice = 100.00, IsActive = true);
        insert pbEntry;
        
        //insert oritem
        OrderItem oitem1 = new OrderItem(product2Id = pd.id,Support_Start_Date__c =System.today(),Support_End_Date__c  =System.today()+2, orderid = ord.id, Quantity = 2, PricebookEntryId = pbEntry.id, UnitPrice = pbEntry.UnitPrice);
        OrderItem oitem2 = new OrderItem(product2Id = pd.id,Support_Start_Date__c =System.today(),Support_End_Date__c  =System.today()+2, orderid = ord.id, Quantity = 2, PricebookEntryId = pbEntry.id, UnitPrice = pbEntry.UnitPrice);
        insert new List<OrderItem>{oitem1, oitem2};
        
        //Generate Assets
        List<Asset> assetList = (List<Asset>) ShGl_TestFactory.createSObjectList(new Asset(), 6, null);
        for(Asset ast : assetList){
            ast.Order_Service_Item__c = oitem1.Id;
            ast.Accountid = acct.Id;
            ast.Product2id = pd.Id; 
        }
        
        system.runAs(testUser)
      {
            
          insert assetList;
           
        }
        
        
    }

    @isTest
    static void createAssetTest() {
        ShGl_TestFactoryHelper.WorkflowTriggerBypass();
        TriggerControl__c custsetting = new TriggerControl__c(Name='Opportunity',DisableTrigger__c=true);
        TriggerControl__c PortalUserCreation = new TriggerControl__c(Name='PortalUserCreation');
        insert new List<TriggerControl__c>{custsetting,PortalUserCreation};
        
        StateNameCode__c custset = new StateNameCode__c(Name='California',Code__c='US-CA');
        insert custset;
        
        //Generate Account
        Account acct = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        acct.Contract_Status__c = 'Not signed';
        acct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Distributor').getRecordTypeId();
        insert acct;
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => acct.Id,
                'Email'  =>'leademail2@hidden.com'
                };
        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);        
        insert cnt1;
        
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => acct.Id,
                'Initial_Contacts_Name__c' => cnt1.Id,
                'Primary_Competitor__c' => 'Other',
                'Other_Primary_Competitor__c' => 'Other',
                'Other_Competitor_Field__c' => 'Other',
                'Lost_To_Won_Against__c' => 'Other',
                'Polaris_Region__c' => 'US',
                'Economic_Buyer__c' => 'Other'
            };
        Opportunity oppty = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        oppty.ForecastCategoryName = 'Best Case';
		oppty.Partner_Lookup__c = acct.Id; 
		oppty.Opportunity_Sub_Type__c = 'Renewal'; 
        insert oppty;
        
        //Generate POC records
        Map<String, Object>  pocMap = new Map<String, Object> {
            'POC_Duration__c' => '60 Days',
            'Planned_Installation_Date__c' => System.Today()+30,
            'Support_Awareness_needed__c' => 'Yes'
        };
        Map<String, Object>  pocMap2 = new Map<String, Object> {
            'POC_Duration__c' => '30 Days',
            'Planned_Installation_Date__c' => System.Today()+30,
            'Support_Awareness_needed__c' => 'Yes'
        };
       
        POC__c poc1 = (POC__c) ShGl_TestFactory.createSObject(new POC__c(), pocMap);
        poc1.POC_Type__c = 'Standard POC';        
        POC__c poc2 = (POC__c) ShGl_TestFactory.createSObject(new POC__c(), pocMap2);     
        poc2.POC_Type__c = 'Standard POC';
        User testUser = new User();
        testUser.id='00540000003tvRQ';
        
        system.runAs(testUser)
      {
            
          insert new List<POC__c>{poc1,poc2};
           
        }
        
       
          
        
        
        
        
        Map<String, Object>  prodMap = new Map<String, Object> {
            'Name' => 'X-0001-01',
            'ProductCode' => 'ProductXYZ',
            'isActive' => true,
            'Family' => 'POLARIS',
            'Product_Type__c' => 'Appliance'
        };            
        Map<String, Object>  prodMap2 = new Map<String, Object> {
            'Name' => 'X-0001-01',
            'ProductCode' => 'ProductXYZ',
            'isActive' => true,
            'Family' => 'POLARIS',
            'Product_Type__c' => 'GPS'
        };                
        Map<String, Object>  prodMap3 = new Map<String, Object> {
            'Name' => 'X-0001-01',
            'ProductCode' => 'ProductXYZ',
            'isActive' => true,
            'Family' => 'POLARIS',
            'Product_Type__c' => 'RADAR'
        };
                    
        Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);  
        Product2 pd2 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap2);
        Product2 pd3 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap3); 
        
        insert new List<Product2>{pd, pd2, pd3};
        
        //Generate SBQQ
        Map<String, Object>  quoteMap = new Map<String, Object> {
            'SBQQ__Account__c' => acct.Id,
                'SBQQ__Opportunity2__c' => oppty.Id
        };
            
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppty.Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__PriceBook__c = Test.getStandardPricebookId();
        insert qt1;
        
        qt1.ApprovalStatus__c = 'Approved';
        update qt1;
        
        //Generate Lead
        Lead led = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
        led.LastName = '111Test 0022';
        led.Country = 'Israel';
        //insert led;
        
        //oppty.Deal_Registration_Link__c = led.Id;
        oppty.Partner_Lookup__c = acct.Id; 
        oppty.pricebook2Id = Test.getStandardPricebookId();
        oppty.StageName = System.Label.Order_Creation_Stage;
        oppty.Partner_Level_Of_Involvement__c = '4.Partner or joint initiated opportunity, partner brought substantial value in sales cycle and getting deal closed';
        oppty.SBQQ__PrimaryQuote__c = qt1.Id;
        oppty.Installation_Assigned_To__c = 'Partner Install';
        update oppty;
        
        //Generate Order
        Map<String, Object>  orderMap = new Map<String, Object> {
            'Status' => 'Draft',
            'AccountId' => acct.Id,
            'OpportunityId' => oppty.Id,
            'EffectiveDate' => Date.Today(),
            /*'ship_To_Name__c' => acct.Id,*/
            'Type' => 'Revenue',
            'Est_Ship_Date__c' => system.today(),
            'Order_Status__c' => 'Change Needed',
            'Hold_Code__c' => 'Delayed Ship Date',
            'POC_Request__c' => poc2.id,
            'RecordTypeId' => Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId(),
            'Pricebook2Id' => Test.getStandardPricebookId()
        };
        Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), orderMap);
        ord.Order_Status__c = 'Pending';
        ord.Hold_Code__c = 'End Customer PO# Missing';
        insert ord;
        
        Order ord1 = [ SELECT Id,Pricebook2Id FROM Order where id = :ord.id LIMIT 1 ];
        ord1.Pricebook2Id = Test.getStandardPricebookId();
        update ord1;
        
        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = pd.Id, UnitPrice = 100.00, IsActive = true);
        insert pbEntry;
        
        //insert oritem
        OrderItem oitem1 = new OrderItem(product2Id = pd.id,Support_Start_Date__c =System.today(),Support_End_Date__c  =System.today()+2, orderid = ord.id, Quantity = 2, PricebookEntryId = pbEntry.id, UnitPrice = pbEntry.UnitPrice);
        OrderItem oitem2 = new OrderItem(product2Id = pd.id,Support_Start_Date__c =System.today(),Support_End_Date__c  =System.today()+2, orderid = ord.id, Quantity = 2, PricebookEntryId = pbEntry.id, UnitPrice = pbEntry.UnitPrice);
        insert new List<OrderItem>{oitem1, oitem2};
        
        //Generate Assets
        List<Asset> assetList = (List<Asset>) ShGl_TestFactory.createSObjectList(new Asset(), 6, null);
        for(Asset ast : assetList){
            ast.Order_Service_Item__c = oitem1.Id;
            ast.Accountid = acct.Id;
            ast.Product2id = pd.Id; 
        }
         system.runAs(testUser)
      {
           
           insert assetList;
            
        }
        
       
    }
    @isTest
    static void updateAssetTest() {
        List<Asset> assetList = [SELECT Id FROM Asset];
        update assetList;
    }
    @isTest
    static void deleteAssetTest() {
        List<Asset> assetList = [SELECT Id FROM Asset];
        delete assetList;
    }
}