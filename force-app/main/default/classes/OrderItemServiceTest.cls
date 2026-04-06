/*Created By : SHADAB HUSSAIN
  Purpose : Test class for OrderItemService Class
*/
@isTest(SeeAllData=false)
public class OrderItemServiceTest {

    public static testMethod void testOrderItemService(){
        
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Triggers__c = true, Disable_Order_Old_Trigger__c = true, Disable_Account_Triggers__c = true);
      disableLogic.Name = 'System Administrator';   
        disableLogic.Disable_Opportunity_Validation_Rules__c = TRUE; 

        insert disableLogic;

        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account acct = new Account(Name='NetApp', RecordTypeId = partnerRecordTypeId);
        insert acct;
        Date closeDt = System.Today()+30;

        opportunity oppr = new opportunity(Name='testing DIEtestsalesforce 27/1/2017' , Sell_to_Partner__c = acct.Id,  AccountId= acct.Id, StageName = '1 Discovery',
                                            CloseDate = closeDt, Lead_Email_Hidden__c='', Partner_Lookup__c =acct.id, Alliance_Partner_Name__c='Amazon', 
                                            Alliance_Source_Type__c='Alliance Initiated Deal', Alliance_Source_Type_HW__c = 'Rubrik Initiated Alliance Deal',
                                            Economic_Buyer__c = 'Test', Metric__c = 'Test', Decision_Process__c = 'Test', Decision_Criteria__c = 'Test',
                                            Identified_Pain__c = 'Test', Champion__c = 'Test', Why_Rubrik__c = 'Why_Rubrik',
                                            Why_do_anything__c = 'Why_do_anything', Why_now__c = 'Why_now', Alliance_HW_Partner__c = 'Cisco', Partner_Representative__c = 'Test');
        insert oppr;

        Id standardPriceBookId = Test.getStandardPricebookId();//pb2Standard.Id;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        List<Product2> lstProducts = new List<Product2>{
            new Product2(Name = 'Product XY', ProductCode = 'Pro-XY', isActive = true),
            new Product2(Name = 'RBK-R304-01', ProductCode = 'RBK-R304-01', isActive = true),
            new Product2(Name = 'Premium Support 1-Yr Prepaid, r304', ProductCode = 'RBK-SVC-PREM-R304', isActive = true)
        };

        insert lstProducts;

        List<PricebookEntry> lstPricebooks = new List<PricebookEntry>{
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[0].Id, UnitPrice = 100.00, IsActive = true),
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[1].Id, UnitPrice = 100.00, IsActive = true),
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[2].Id, UnitPrice = 100.00, IsActive = true)
        };
        
        insert lstPricebooks;

        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = oppr.Id,
            SBQQ__StartDate__c = System.today(),
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__Primary__c = true,
            SBQQ__PriceBook__c = Test.getStandardPricebookId());
        insert quote;

        test.startTest();

        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = lstProducts[0].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = lstProducts[1].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = lstProducts[2].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        insert lines;

        lines[0].SBQQ__Bundle__c = true;
        lines[1].SBQQ__RequiredBy__c = lines[0].Id;
        lines[2].SBQQ__RequiredBy__c = lines[0].Id;
        update lines;

        Order ordr = new Order(Type='Revenue' ,  AccountId= acct.Id,OpportunityId =oppr.Id,ShippingStreet ='Test Street',
                            ShippingCity ='Test City',
                            ShippingState ='California',
                            ShippingCountry ='United States',
                            ShippingPostalcode ='94820',
                            Order_Sub_Type__c = 'Renewal',
                            SBQQ__Quote__c = quote.id,
                            EffectiveDate=system.Today(), Order_Status__c = 'Pending' );
        insert ordr;

        Order od = [ SELECT Id,Pricebook2Id FROM Order where id=:ordr.id LIMIT 1 ];
        od.Pricebook2Id = standardPriceBookId;
        update od;

        List<OrderItem> lstOrderItems = new List<OrderIteM>();
        OrderItem oli = new OrderItem(
            OrderId = ordr.Id,
            Quantity = 5,
            PricebookEntryId = lstPricebooks[0].Id,
            UnitPrice = lstPricebooks[0].UnitPrice,
            SerialNumber__c = 'Test1234567Asset2',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today(),
            SBQQ__QuoteLine__c = lines[0].Id
        );
        lstOrderItems.add(oli);

        OrderItem oli2 = new OrderItem(
            OrderId = ordr.Id,
            Quantity = 5,
            PricebookEntryId = lstPricebooks[1].Id,
            UnitPrice =  lstPricebooks[1].UnitPrice,
            SerialNumber__c = 'Test1234567Asset',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today(),
            SBQQ__SegmentIndex__c =1,
            SBQQ__QuoteLine__c = lines[1].Id
        );
        lstOrderItems.add(oli2);

        OrderItem oli3 = new OrderItem(
            OrderId = ordr.Id,
            Quantity = 5,
            PricebookEntryId = lstPricebooks[2].Id,
            UnitPrice =  lstPricebooks[2].UnitPrice,
            SerialNumber__c = 'Test1234567Asset3',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today(),
            SBQQ__QuoteLine__c = lines[1].Id,
            SBQQ__SegmentIndex__c =1
        );
        lstOrderItems.add(oli3);

        insert lstOrderItems;
        
        lstOrderItems[1].SerialNumber__c = 'Test1234567Asset2';
        update lstOrderItems[1];
        
        lstOrderItems[2].SerialNumber__c= 'Test1234567Asset4';
        lstOrderItems[2].Engagement_Date__c = date.newInstance(2021, 01, 01);
        update lstOrderItems[2];

        test.stopTest();
    }

    /* Old Method
    public static testMethod void updateRelatedAssetsTest(){
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account acct = new Account(Name='testAccount', RecordTypeId = partnerRecordTypeId);
        insert acct;
        Date closeDt = System.Today()+30;

        opportunity oppr = new opportunity(Name='testing DIEtestsalesforce 27/1/2017' ,  AccountId= acct.Id,StageName = '4 Business Justification',
                                           CloseDate = closeDt, Lead_Email_Hidden__c='', Partner_Lookup__c =acct.id, Alliance_Partner_Name__c='Amazon', Alliance_Source_Type__c='Alliance Initiated Deal');
        insert oppr;
        Product2 pd = new Product2(Name='Pord B',ProductCode='Product123XYZ',isActive=true);
        pd.IsActive = true;
        insert pd;

        PriceBook2 pb2Standard = [select Id,isStandard,name from Pricebook2 where name ='Standard Price Book' and isStandard=true];
        Id standardPriceBookId = pb2Standard.Id;

        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=standardPriceBookId, Product2Id=pd.Id, UnitPrice=99, isActive=true);
        insert pbe;

        Product2 p2ex = [SELECT Name FROM Product2 WHERE Id = :pd.Id];
        System.assertEquals(pd.Name,p2ex.Name);
        Id pricebookId = Test.getStandardPricebookId();

        //Create your product
        Product2 prod = new Product2(
            Name = 'Product XY',
            ProductCode = 'Pro-XY',
            isActive = true
        );
        insert prod;

        //Create your product
        Product2 prod2 = new Product2(
            Name = 'RBK-R304-01',
            ProductCode = 'RBK-R304-01',
            isActive = true
        );
        insert prod2;

        //Create your product
        Product2 prod3 = new Product2(
            Name = 'Premium Support 1-Yr Prepaid, r304',
            ProductCode = 'RBK-SVC-PREM-R304',
            isActive = true
        );
        insert prod3;

        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry;
        //Create your pricebook entry
        PricebookEntry pbEntry2 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        insert pbEntry2;
        //Create your pricebook entry
        PricebookEntry pbEntry3 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        insert pbEntry3;

        Order ordr = new Order(Type='Revenue' ,  AccountId= acct.Id,OpportunityId =oppr.Id,ShippingStreet ='Test Street',
                            ShippingCity ='Test City',
                            ShippingState ='California',
                            ShippingCountry ='United States',
                            ShippingPostalcode ='94820',
        //                    EffectiveDate=system.Today(), Status='Pending' );
                            EffectiveDate=system.Today(), Order_Status__c = 'Pending' );
        insert ordr;
        Order od = [ SELECT Id,Pricebook2Id FROM Order where id=:ordr.id LIMIT 1 ];
         od.Pricebook2Id = pb2Standard.Id;
     update od;


        Asset asst = new Asset(
                     Name= 'Test1234567Asset', SerialNumber= 'Test1234567Asset',Serial_Number__c= 'Test1234567Asset',Product2ID=prod3.Id,
                     Accountid =acct.Id
                    );
        insert asst;
        Asset asst3 = new Asset(
         Name= 'Test1234567Asset3', SerialNumber= 'Test1234567Asset3',Serial_Number__c= 'Test1234567Asset3',Product2ID=prod3.Id,
         Accountid =acct.Id
        );
        insert asst3;

        Asset asst4 = new Asset(
         Name= 'Test1234567Asset4', SerialNumber= 'Test1234567Asset4',Serial_Number__c= 'Test1234567Asset4',Product2ID=prod3.Id,
         Accountid =acct.Id
        );
        insert asst4;

        Asset asst2 = new Asset(
         Name= 'Test1234567Asset2', SerialNumber= 'Test1234567Asset2',Serial_Number__c= 'Test1234567Asset2',Product2ID=prod3.Id,
         Accountid =acct.Id
        );
        insert asst2;

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
        ordr.Order_Status__c = 'Order Accepted';

        //update ordr;
        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OrderItem oli = new OrderItem(

            OrderId = ordr.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry.Id,
            UnitPrice = pbEntry.UnitPrice,
            SerialNumber__c = 'Test1234567Asset2',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        insert oli;

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OrderItem oli2 = new OrderItem(
            OrderId = ordr.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry.Id,
            UnitPrice =  pbEntry.UnitPrice,
            SerialNumber__c = 'Test1234567Asset',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        insert oli2;

        OrderItem oli3 = new OrderItem(
            OrderId = ordr.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry.Id,
            UnitPrice =  pbEntry.UnitPrice,
            SerialNumber__c = 'Test1234567Asset3',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        insert oli3;

        oli2.SerialNumber__c= 'Test1234567Asset2';
        update oli2;
        oli3.SerialNumber__c= 'Test1234567Asset4';
        update oli3;

        Set<ID> ordrSet = new Set<ID>();
        ordrSet.add(ordr.ID);
        //OrderItemService.updateOrdersChanged(ordrSet);


    }*/


    /* OrderLineEntry is covered by OrderLineEntry_Test - Nithin
    public static testMethod void test_OrderLineEntry() {

        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account acct = new Account(Name='test Account', RecordTypeId = partnerRecordTypeId);
        insert acct;

        Contact objContact = new Contact(AccountId = acct.Id, LastName = 'Test Contact', Email = 'test_OrderLineEntry.OrderItemService@test.com',
                                         Contact_Status__c = 'Marketing Nurture', ContactRejectReason__c = 'Contacted/No Interest');
        System.debug(objContact);
        insert objContact;
        Decimal decAmount = 999999;
        Date closeDt = System.Today()+30;
        opportunity oppr = new opportunity( Name='Testing', AccountId= acct.Id, StageName = '1 Discovery', partner_lookup__c=acct.id,
                                            Alliance_Source_Type_HW__c = 'Rubrik Initiated Alliance Deal', CloseDate = closeDt,
                                            Cloud_Type__c = 'Microsoft Azure', Lead_Email_Hidden__c='', Alliance_HW_Partner__c = 'Cisco', 
                                            Initial_Contacts_Name__c = objContact.Id, Alliance_Partner_Name__c='Amazon', Amount = decAmount,
                                            Champion__c = 'Test', Partner_Representative__c = 'Test', Alliance_Source_Type__c='Alliance Initiated Deal',
                                            Economic_Buyer__c = 'Test', Metric__c = 'Test', Decision_Process__c = 'Test', Decision_Criteria__c = 'Test',
                                            Identified_Pain__c = 'Test', Why_Rubrik__c = 'Why_Rubrik',
                                            Why_do_anything__c = 'Why_do_anything', Why_now__c = 'Why_now');
        insert oppr;
        // SBQQ__Quote__c objQuote = new SBQQ__Quote__c( SBQQ__Primary__c = true, ApprovalStatus__c = 'Approved',
        //                                              SBQQ__NetAmount__c = decAmount);  

        // insert objQuote; 
        // objQuote.put('SBQQ__Opportunity2__c',  oppr.Id);
        // SBQQ_QuoteLine__c objQuoteLine = new SBQQ_QuoteLine__c(SBQQ__Quote__c = objQuote.Id, );
        // update objQuote;
        // oppr.put('SBQQ__PrimaryQuote__c', (Id) objQuote.get('Id'));
        oppr.Pricebook2Id = Test.getStandardPricebookId();
        update oppr;

        Product2 pd = new Product2(Name='Pord A',ProductCode='ProductXYZ',isActive=true);
        pd.IsActive = true;
        insert pd;

        //PriceBook2 pb2Standard = [select Id from Pricebook2 where isStandard=true];
        Id standardPriceBookId = Test.getStandardPricebookId(); //pb2Standard.Id;

        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=standardPriceBookId, Product2Id=pd.Id, UnitPrice=99, isActive=true);
        insert pbe;

        Product2 p2ex = [SELECT Name FROM Product2 WHERE Id = :pd.Id];
        System.assertEquals(pd.Name,p2ex.Name);
        Id pricebookId = Test.getStandardPricebookId();

        //Create your product
        Product2 prod = new Product2(
            Name = 'Product X',
            ProductCode = 'Pro-X',
            isActive = true
        );
        //insert prod;

        //Create your product
        Product2 prod2 = new Product2(
            Name = 'Product Y',
            ProductCode = 'Pro-Y',
            isActive = true
        );
        insert new List<Product2>{prod, prod2};

        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        //insert pbEntry;
        //Create your pricebook entry
        PricebookEntry pbEntry2 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        insert new List<PricebookEntry>{pbEntry, pbEntry2};

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = oppr.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry.Id,
            TotalPrice = 5 * pbEntry.UnitPrice
        );
        //insert oli;

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli2 = new OpportunityLineItem(
            OpportunityId = oppr.Id,
            Quantity = 10,
            PricebookEntryId = pbEntry.Id,
            TotalPrice = 5 * pbEntry.UnitPrice
        );
        insert new List<OpportunityLineItem>{oli, oli2};

        Test.startTest();

    String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
    Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
    User u = new User(Alias = 'standt', Email='standarduser@testorg.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName=uniqueUserName, Theatre__c='US & Canada');
    insert u;

        oppr.stageName= '6 PO With Channel';
        oppr.Valooto_Quote_Stage__c ='Approved';
        oppr.Partner_Level_Of_Involvement__c = '1.Rubrik initiated, Partner was fulfillment only';
        oppr.Rubrik_Sales_Engineer__c = UserInfo.getUserId();
        oppr.POC_Conversion__c='No';
        oppr.OwnerId=u.Id;
        oppr.Installation_Assigned_To__c = 'FE Install';
        oppr.ForecastCategoryName = 'Best Case';
        update oppr;

        shipping_Address__C sAddr = new Shipping_Address__C(Account__c = acct.Id,Name='Test 1',Shipping_State__C ='CA',Shipping_Country__c='United States');
        insert sAddr;

        delete [select id from OrderItem where Order.OpportunityId = :oppr.id limit 1];

        List<Order> orderIDauto = [select id,Order.OpportunityId from Order where OpportunityId = :oppr.id];

        /*
        PageReference pageRef = Page.AddOrderLineItems;
        pageRef.getParameters().put('Id',orderIDauto[0].Id);
        pageRef.getParameters().put('oppId',orderIDauto[0].OpportunityId);

        Test.setCurrentPageReference(pageRef);

        Order q = [select id,Order.OpportunityId from Order where OpportunityId = :oppr.id];
        ApexPages.StandardController ord = new ApexPages.StandardController(q);
        OrderLineEntry ordlie  = new OrderLineEntry(ord);

        ordlie.initWrapper();
        ordlie.reset();
        ordlie.saveRecord();

        Test.stopTest();
        //OrderLineEntry.wrapLines psec = new OrderLineEntry.wrapLines();
        //psec.emailCategoryList = new List<String>();
    }*/
}