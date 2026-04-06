@isTest//(seeAllDAta=true)
public class EntilementTriggerHandler_Batch_Test {
    static testMethod void testMethodforBatch(){
		FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        TriggerControl__c setting1 = new TriggerControl__c();
        setting1.Name = 'Opportunity';
        setting1.DisableTrigger__c = False;
        //insert setting1;

        TriggerControl__c setting2 = new TriggerControl__c();
        setting2.Name = 'Contact';
        setting2.DisableTrigger__c = False;
        //insert setting2;

        TriggerControl__c setting3 = new TriggerControl__c();
        setting3.Name = 'Entitlement';
        setting3.DisableTrigger__c = False;
        insert new List<TriggerControl__c>{setting1, setting2, setting3};
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account acct = new Account(Name='testAccount', RecordTypeId = partnerRecordTypeId);
        //insert acct;

        Account acc = new Account(Name='testAccount1');
        insert new List<Account>{acct, acc};

        Contact con = new Contact(FirstName='john', LastName='doe', Email='john@doe.com', AccountId=acct.Id);
        insert con;

        Date closeDt = System.Today()+30;
        Opportunity oppr = new opportunity(Name='testing DIEtestsalesforce 27/1/2017' ,  AccountId= acct.Id,StageName = '1 Discovery',
                                           //EXCL-6
                                           Alliance_HW_Partner__c='None', Partner_Representative__c='Test', Initial_Contacts_Name__c=con.Id,
                                           CloseDate = closeDt, Lead_Email_Hidden__c='', Partner_Lookup__c =acct.id, Alliance_Partner_Name__c='Amazon',Alliance_Source_Type_SW__c = 'Alliance Initiated Deal', Alliance_Source_Type__c='Alliance Initiated Deal', Installation_Assigned_To__c='FE Install');
        insert oppr;

        Product2 pd = new Product2(Name='Pord B',ProductCode='Product123XYZ',isActive=true);
        pd.IsActive = true;
        insert pd;

        Id standardPriceBookId =  Test.getStandardPricebookId();

        PriceBook2 pb1  = new Pricebook2(Name = 'V68_2017_08_09_12_26_43', Description = 'Price Book 2009 Products 1', IsActive = true);
        insert pb1;

        //PriceBook2 pb2Standard = [select Id,isStandard,name from Pricebook2 where name ='Standard Price Book' and isStandard=true];
        //Id standardPriceBookId = pb2Standard.Id;

        PricebookEntry pbestandard = new PricebookEntry(Pricebook2Id=standardPriceBookId, Product2Id=pd.Id, UnitPrice=99, isActive=true);
        //insert pbestandard;

        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=pb1.id, Product2Id=pd.Id, UnitPrice=99, isActive=true);
        insert new List<PricebookEntry>{pbestandard, pbe};

        Product2 p2ex = [SELECT Name FROM Product2 WHERE Id = :pd.Id];
        System.assertEquals(pd.Name,p2ex.Name);
        Id pricebookId = Test.getStandardPricebookId();



        //Create your product
        Product2 prod1 = new Product2(
            Name = 'Premium Support 1-Yr Prepaid, r304',
            ProductCode = 'RBK-SVC-PREM-R304',
            isActive = true
        );
        //insert prod1;
        Product2 prod2 = new Product2(
            Name = 'Premium Support 1-Yr Prepaid, r304',
            ProductCode = 'RBK-SVC-PREM-R304',
            isActive = true
        );
        //insert prod2;

        //Create your product
        Product2 prod3 = new Product2(
            Name = 'RBK-EDGE-10-MO',
            ProductCode = 'RBK-EDGE-10-MO',
            isActive = true
        );
        //insert prod3;

        //Create your product
        Product2 prod4 = new Product2(
            Name = 'RBK-RCDM-10-MO',
            ProductCode = 'RBK-RCDM-AWS-MO',
            isActive = true
        );
        Product2 prod5 = new Product2(
            Name = 'RBK-NRD',
            ProductCode = 'RBK-NRD',
            isActive = true
        );
        insert new List<Product2>{prod1, prod2, prod3, prod4,prod5};

        //Create your pricebook entry
        PricebookEntry pbStanEntry1 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod1.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        //insert pbStanEntry1;
        //Create your pricebook entry
        PricebookEntry pbStanEntry2 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        //insert pbStanEntry2;
        //Create your pricebook entry
        PricebookEntry pbStanEntry3 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        //insert pbStanEntry3;

        //Create your pricebook entry
        PricebookEntry pbStanEntry4 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod4.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        //insert pbStanEntry4;
			
        //Create your pricebook entry
        PricebookEntry pbStanEntry5 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod5.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        
        //Create your pricebook entry
        PricebookEntry pbEntry1 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod1.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        //insert pbEntry1;
        //Create your pricebook entry
        PricebookEntry pbEntry2 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        //insert pbEntry2;
        //Create your pricebook entry
        PricebookEntry pbEntry3 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        //insert pbEntry3;

        //Create your pricebook entry
        PricebookEntry pbEntry4 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod4.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
         //Create your pricebook entry
        PricebookEntry pbEntry5 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod5.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        insert new List<PricebookEntry>{pbStanEntry1, pbStanEntry2, pbStanEntry3, pbStanEntry4,pbStanEntry5, pbEntry1, pbEntry2, pbEntry3, pbEntry4, pbEntry5};

        Order ordr = new Order(Type='Revenue' ,  AccountId= acct.Id,OpportunityId =oppr.Id,ShippingStreet ='Test Street',
                            ShippingCity ='Test City',
                            ShippingState =null,
                            ShippingCountry ='Austria',
                            ShippingPostalcode ='94820',
        //                    EffectiveDate=system.Today(), Status='Pending' );
                            EffectiveDate=system.Today(), Order_Status__c = 'Pending' );
        insert ordr;

        Order od = [ SELECT Id,Pricebook2Id FROM Order where id=:ordr.id LIMIT 1 ];
        od.Pricebook2Id = pb1.Id;
        update od;


        Asset asst = new Asset(
            Name= 'Test1234567Asset', SerialNumber= 'Test1234567Asset',Serial_Number__c= 'Test1234567Asset',Product2ID=prod3.Id,
            Accountid =acct.Id
        );
        //insert asst;

        Asset asst3 = new Asset(
            Name= 'Test1234567Asset3', SerialNumber= 'Test1234567Asset3',Serial_Number__c= 'Test1234567Asset3',Product2ID=prod3.Id,
            Accountid =acct.Id
        );
        //insert asst3;

        Asset asst4 = new Asset(
            Name= 'Test1234567Asset4', SerialNumber= 'Test1234567Asset4',Serial_Number__c= 'Test1234567Asset4',Product2ID=prod3.Id,
            Accountid =acct.Id
        );
        //insert asst4;

        Asset asst2 = new Asset(
            Name= 'Test1234567Asset2', SerialNumber= 'Test1234567Asset2',Serial_Number__c= 'Test1234567Asset2',Product2ID=prod3.Id,
            Accountid =acct.Id
        );
        
         Asset asst5 = new Asset(
            Name= 'Test123456777Asset2', SerialNumber= 'Test123456777Asset2',Serial_Number__c= 'Test1234567777Asset2',Product2ID=prod5.Id,
            Accountid =acct.Id
        );
        insert new List<Asset>{asst, asst3, asst4, asst2, asst5};

        oppr.StageName ='6 PO Recieved';
        //update oppr;

        //ordr.Ship_To_Name__c = acct.id;
        ordr.ShipToContactName__c = 'sh';
        ordr.Shipping_Method__c ='EXW';
        ordr.Shipping_Carrier__c ='AIT';
        ordr.Service_Level__c ='Same Day';
        ordr.Bill_To_Name__C =acct.id;
        ordr.est_Ship_Date__C =System.Today().addDays(7);
        //ordr.Status='Order Accepted' ;
        ordr.Order_Status__c = 'Order Accepted' ;

        //update ordr;
        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OrderItem oli1 = new OrderItem(

            OrderId = ordr.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry1.Id,
            UnitPrice = pbEntry1.UnitPrice,
            SerialNumber__c = 'Test1234567Asset2',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        //insert oli1;

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OrderItem oli2 = new OrderItem(
            OrderId = ordr.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry2.Id,
            UnitPrice =  pbEntry2.UnitPrice,
            SerialNumber__c = 'Test1234567Asset',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        //insert oli2;

        OrderItem oli3 = new OrderItem(
            OrderId = ordr.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry3.Id,
            UnitPrice =  pbEntry3.UnitPrice,
            SerialNumber__c = 'Test1234567Asset',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        //insert oli3;

        OrderItem oli4 = new OrderItem(
            OrderId = ordr.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry4.Id,
            UnitPrice =  pbEntry4.UnitPrice,
            SerialNumber__c = 'Test1234567Asset',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        
         OrderItem oli5 = new OrderItem(
            OrderId = ordr.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry4.Id,
            UnitPrice =  pbEntry5.UnitPrice,
            SerialNumber__c = 'Test123456777Asset',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        insert new List<OrderItem>{oli1, oli2, oli3, oli4, oli5};

        Entitlement ent1 = new Entitlement(Name='Testing', AccountId=acct.Id, StartDate=Date.valueof(System.now().addDays(-2)), EndDate=Date.valueof(System.now().addYears(2)), AssetId=asst.Id, Product__C = prod1.Id,Order_Service_Item__c = oli1.id);
        //insert ent1;
        Entitlement ent2 = new Entitlement(Name='Testing', AccountId=acct.Id, StartDate=Date.valueof(System.now().addDays(-2)), EndDate=Date.valueof(System.now().addYears(2)), AssetId=asst.Id, Product__C = prod2.Id,Order_Service_Item__c = oli2.id);
        //insert ent2;
        Entitlement ent3 = new Entitlement(Name='test2', AccountId=acct.Id, StartDate=Date.valueof(System.now().addDays(-10)), EndDate=Date.valueof(System.now().addMonths(4)), Product__C = prod3.Id,Order_Service_Item__c = oli3.id);
        //insert ent3;
        Entitlement ent4 = new Entitlement(Name='test2', AccountId=acct.Id, StartDate=Date.valueof(System.now().addMonths(4).addDays(1)), EndDate=Date.valueof(System.now().addMonths(8)), Product__C = prod4.Id,Order_Service_Item__c = oli4.id);
        Entitlement ent5 = new Entitlement(Name='test5', AccountId=acct.Id, StartDate=Date.valueof(System.now().addMonths(4).addDays(1)), EndDate=Date.valueof(System.now().addMonths(8)), Product__C = prod5.Id,Order_Service_Item__c = oli5.id);
        insert new List<Entitlement>{ent1, ent2, ent3, ent4, ent5};

        ent1.EndDate = System.today().addYears(2);
        update ent1;

        //ent4.StartDate = ent4.StartDate.addDays(1);
        //update ent4;


        EntitlementContact ec = new EntitlementContact(EntitlementId=ent1.Id, ContactId=con.Id);
        insert ec;


        /*List<Asset> assetList = [select id,name,Product2Id,AccountId from Asset Limit 4];
        List<Account> accountList = [select id,name from Account Limit 2];
        List<Product2> ProductSVCList = [select id,name from Product2 where ProductCode LIKE 'RBK-SVC%' Limit 1];
        List<Product2> ProductNRDList = [select id,name from Product2 where ProductCode LIKE 'RBK-NRD%' Limit 1];
        List<Product2> ProductEDGEList = [select id,name from Product2 where ProductCode LIKE 'RBK-EDGE-10%' Limit 1];
        List<Product2> ProductRCDMList = [select id,name from Product2 where ProductCode LIKE 'RBK-RCDM%' Limit 1];

        Entitlement ent1 = new Entitlement(Name='Testing', AccountId=AssetList[0].AccountId, StartDate=Date.valueof(System.now().addDays(-2)), EndDate=Date.valueof(System.now().addYears(2)), AssetId=AssetList[0].Id, Product__C = ProductSVCList[0].Id);
        insert ent1;

        Entitlement ent2 = new Entitlement(Name='Testing', AccountId=AssetList[0].AccountId, StartDate=Date.valueof(System.now().addDays(-2)), EndDate=Date.valueof(System.now().addYears(2)), AssetId=AssetList[0].Id, Product__C = ProductNRDList[0].Id);
        insert ent2;

        Entitlement ent3 = new Entitlement(Name='test2', AccountId=accountList[0].Id, StartDate=Date.valueof(System.now().addDays(-10)), EndDate=Date.valueof(System.now().addMonths(4)), Product__C = ProductEDGEList[0].id);
        insert ent3;

        Entitlement ent4 = new Entitlement(Name='test2', AccountId=accountList[0].Id, StartDate=Date.valueof(System.now().addDays(-10)), EndDate=Date.valueof(System.now().addMonths(4)), Product__C = ProductRCDMList[0].Id);
        insert ent4;

        ent4.EndDate = System.today().addYears(2);
        update ent4;*/

        Test.startTest();
            Entititlement_isRenewal_Update_Batch batch_renewal = new Entititlement_isRenewal_Update_Batch();
            DataBase.executeBatch(batch_renewal,100);
            Entititlement_Price_Update_Batch batch_price = new Entititlement_Price_Update_Batch();
            DataBase.executeBatch(batch_price,100);
            EntlmentIsRenewalUpdateBatchSchedular sch1 = new EntlmentIsRenewalUpdateBatchSchedular();
            String sch = '0  00 3 4 * ?';
            system.schedule('Test', sch, sch1);
        Test.stopTest();
        delete ent4;
    }


}