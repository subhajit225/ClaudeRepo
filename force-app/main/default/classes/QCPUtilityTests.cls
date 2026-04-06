/**Test class for QCPUtility */
@isTest
private class QCPUtilityTests {
 
    @TestSetup
    static void setupData(){
        ShGl_DisableFunctionalityLogic__c disFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disFuncCS.DisableDemandMatrixCalculation__c = true;
        insert disFuncCS;
        insert new ShGl_DisableBusinessLogic__c(
            SetupOwnerId = UserInfo.getUserId(),
            Disable_Opportunity_Triggers__c = true
        );
        FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        TriggerControl__c setting1 = new TriggerControl__c();
        setting1.Name = 'Opportunity';
        setting1.DisableTrigger__c = False;

        TriggerControl__c setting2 = new TriggerControl__c();
        setting2.Name ='Contact';
        setting2.DisableTrigger__c= False;

        TriggerControl__c setting3 = new TriggerControl__c();
        setting3.Name = 'Entitlement';
        setting3.DisableTrigger__c = False;
        insert new List<TriggerControl__c>{setting1, setting2, setting3};
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account acct = new Account(Name='testAccount', RecordTypeId = partnerRecordTypeId);
        Account acc = new Account(Name='testAccount1');
        insert new List<Account>{acct, acc};

        Contact con = new Contact(FirstName='john', LastName='doe', Email='john@doe.com', AccountId=acct.Id);
        insert con;

        Opportunity oppr = TestDataFactory.getOpportunity(acct);
        insert oppr;

        Product2 pd = new Product2(Name='Pord B',ProductCode='Product123XYZ',isActive=true, Quotable_Date__c = Date.newInstance(2004, 11, 11));
        pd.IsActive = true;
        insert pd;

        Id standardPriceBookId =  Test.getStandardPricebookId();

        PriceBook2 pb1  = new Pricebook2(Name = 'V68_2017_08_09_12_26_43', Description = 'Price Book 2009 Products 1', IsActive = true);
        insert pb1;

        //PriceBook2 pb2Standard =[select Id,isStandard,name from Pricebook2 where name ='Standard Price Book' and isStandard=true];
        //Id standardPriceBookId = pb2Standard.Id;

        PricebookEntry pbestandard = new PricebookEntry(Pricebook2Id=standardPriceBookId, Product2Id=pd.Id, UnitPrice=99, isActive=true);
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=pb1.id, Product2Id=pd.Id, UnitPrice=99, isActive=true);
        insert new List<PricebookEntry>{pbestandard, pbe};

        Product2 p2ex = [SELECT Name FROM Product2 WHERE Id = :pd.Id];
        System.assertEquals(pd.Name,p2ex.Name);
        Id pricebookId = Test.getStandardPricebookId();
        System.debug(pricebookId);
        //Create your product
        Product2 prod1 = new Product2(
            Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
            ProductCode = 'RBK-SVC-PREM-R304',
            isActive = true,
            Quotable_Date__c = Date.newInstance(2004, 11, 11)
        );
                                          
        Product2 prod2 = new Product2(
            Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
            ProductCode = 'RBK-SVC-PREM-R304',
            isActive = true,
            Quotable_Date__c = Date.newInstance(2004, 11, 11)
        );
        //Create your product
        Product2 prod3 = new Product2(
            Name = 'RBK-REDGE-10-MO-CLOUT',
            ProductCode = 'RBK-REDGE-10-MO',
            isActive = true,
            Quotable_Date__c = Date.newInstance(2004, 11, 11));
        //Create your product
        Product2 prod4 = new Product2(
            Name = 'RBK-RCDM-10-MO-CLON',
            ProductCode = 'RBK-RCDM-AWS-MO',
            isActive = true,
            Quotable_Date__c = Date.newInstance(2004, 11, 11)
        );
        insert new List<Product2>{prod1, prod2, prod3, prod4};

        //Create your pricebook entry
        PricebookEntry pbStanEntry1 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod1.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        //Create your pricebook entry
        PricebookEntry pbStanEntry2 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        //Create your pricebook entry
        PricebookEntry pbStanEntry3 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        //Create your pricebook entry
        PricebookEntry pbStanEntry4 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod4.Id,
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
        //Create your pricebook entry
        PricebookEntry pbEntry2 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        //Create your pricebook entry
        PricebookEntry pbEntry3 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        //Create your pricebook entry
        PricebookEntry pbEntry4 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod4.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        insert new List<PricebookEntry>{
            pbStanEntry1,
            pbStanEntry2,
            pbStanEntry3,
            pbStanEntry4,
            pbEntry1,
            pbEntry2,
            pbEntry3,
            pbEntry4
        };

        Map<String, Object>  quoteMap = new Map<String, Object> {
            'SBQQ__Account__c' => acct.Id,
            'SBQQ__Opportunity2__c' => oppr.Id
        };
                                             

        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppr.Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__PriceBook__c = pb1.Id;
        qt1.ApprovalStatus__c = 'Approved';
        qt1.Task_Products__c='RBK-DISK-RETENTION';
        insert qt1;

        Order ordr = new Order(Type='Revenue' ,  AccountId= acct.Id,OpportunityId =oppr.Id,ShippingStreet ='Test Street',
            ShippingCity ='Test City',
            ShippingState =null,
            ShippingCountry ='Austria',
            ShippingPostalcode ='94820',
            EffectiveDate=system.Today(), Status='Pending'
        );

        insert ordr;
        Order od = [ SELECT Id,Pricebook2Id FROM Order where id=:ordr.id LIMIT 1 ];
        od.Pricebook2Id = pb1.Id;
        update od;


        Asset asst = new Asset(
            Name= 'Test1234567Asset', SerialNumber= 'Test1234567Asset',Serial_Number__c= 'Test1234567Asset',Product2ID=prod3.Id,
            Accountid =acct.Id
        );
        Asset asst3 = new Asset(
            Name= 'Test1234567Asset3', SerialNumber= 'Test1234567Asset3',Serial_Number__c= 'Test1234567Asset3',Product2ID=prod3.Id,
            Accountid =acct.Id
        );
        Asset asst4 = new Asset(
            Name= 'Test1234567Asset4', SerialNumber= 'Test1234567Asset4',Serial_Number__c= 'Test1234567Asset4',Product2ID=prod3.Id,
            Accountid =acct.Id
        );
        Asset asst2 = new Asset(
            Name= 'Test1234567Asset2', SerialNumber= 'Test1234567Asset2',Serial_Number__c= 'Test1234567Asset2',Product2ID=prod3.Id,
            Accountid =acct.Id
        );
        insert new List<Asset>{asst, asst3, asst4, asst2};

        oppr.StageName ='6 PO Recieved';
        //update oppr;

        //ordr.Ship_To_Name__c = acct.id;
        ordr.ShipToContactName__c = 'sh';
        ordr.Shipping_Method__c ='EXW';
        ordr.Shipping_Carrier__c ='AIT';
        ordr.Service_Level__c ='Same Day';
        ordr.Bill_To_Name__C =acct.id;
        ordr.est_Ship_Date__C =System.Today().addDays(7);
        ordr.Status='Order Accepted' ;

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
        OrderItem oli3 = new OrderItem(
            OrderId = ordr.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry3.Id,
            UnitPrice =  pbEntry3.UnitPrice,
            SerialNumber__c = 'Test1234567Asset',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        OrderItem oli4 = new OrderItem(
            OrderId = ordr.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry4.Id,
            UnitPrice =  pbEntry4.UnitPrice,
            SerialNumber__c = 'Test1234567Asset',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        insert new List<OrderItem>{oli1, oli2, oli3, oli4};     
        
        ServiceContract objSC = new ServiceContract(Name = 'ServiceContract Test', AccountId = acct.Id, StartDate = Date.today(),
                                                   Term = 36, pricebook2Id = pb1.Id, SBQQSC__Opportunity__c = oppr.Id, SBQQSC__Order__c= ordr.Id,  SBQQSC__Quote__c = qt1.Id);
       
        insert objSC;

        List<ContractLineItem> lstCli = new List<ContractLineItem>(); 
        ContractLineItem cli = new ContractLineItem();
        cli.Quantity = oli1.quantity;
        cli.PricebookEntryId = oli1.PricebookEntryId;
        cli.ServiceContractId= objSC.id;
        cli.UnitPrice=oli1.UnitPrice; 
        cli.StartDate = date.today();
        lstCli.add(cli);

        ContractLineItem cli2 = new ContractLineItem();
        cli2.Quantity = oli2.quantity;
        cli2.PricebookEntryId = oli2.PricebookEntryId;
        cli2.ServiceContractId= objSC.id;
        cli2.UnitPrice= oli2.UnitPrice; 
        cli2.StartDate = date.today();
        lstCli.add(cli2);

        ContractLineItem cli3 = new ContractLineItem();
        cli3.Quantity = oli2.quantity;
        cli3.PricebookEntryId = oli3.PricebookEntryId;
        cli3.ServiceContractId= objSC.id;
        cli3.UnitPrice= oli2.UnitPrice; 
        cli3.StartDate = date.today();
        lstCli.add(cli3);

        insert lstCli;

        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, Prior_Net_Total__c = 10, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__RenewedContractLine__c = cli.Id, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10));
        SBQQ__QuoteLine__c ql2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, Prior_Net_Total__c = 0, SBQQ__Product__c = prod2.Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__RenewedContractLine__c = cli.Id, SBQQ__StartDate__c =  Date.today());
        SBQQ__QuoteLine__c ql3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod3.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__RenewedContractLine__c = cli2.Id, SBQQ__EndDate__c = Date.today().addDays(10));
        SBQQ__QuoteLine__c ql4 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod4.Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__RenewedContractLine__c = cli2.Id);
        lines.add(ql1);
        lines.add(ql2);
        lines.add(ql3);
        lines.add(ql4);
        insert lines;

        /*Consolidated_Contract_Lines__c consolidateContractLines =  new Consolidated_Contract_Lines__c();
        consolidateContractLines.Quote_Line__c = ql1.Id;
        consolidateContractLines.Contract_Line_Item__c = cli3.Id;
        insert consolidateContractLines; */       
    }

    @isTest
    private static void testSetPriorNetTotal() {
        Test.startTest();
        List<SBQQ__Quote__c> lstQuote = new List<SBQQ__Quote__c>();
            SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
            lstQuote.add(quote);
            Assert.areEqual(1, lstQuote.size());
            
            QCPUtility.setPriorNetTotal(quote.Id);
        Test.stopTest();
    }
    @isTest
    private static void updateQuotePolarisConversationComplete() {
        Test.startTest();
            SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
            
        List<Id> quoteIds = new List<Id>();
        quoteIds.add(quote.Id);
        Assert.areEqual(1, quoteIds.size());

            QCPUtility.updateQuotePolarisConversationComplete(quoteIds);
        Test.stopTest();
    }
    
    

    @isTest
    private static void testSetDiscountMarginPercentChange() {
        Test.startTest();
            SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
            List<Id> quoteIds = new List<Id>();
        quoteIds.add(quote.Id);
        Assert.areEqual(1, quoteIds.size());
            QCPUtility.setDiscountMarginPercentChange(quote.Id);
        Test.stopTest();
    }

    @isTest
    private static void testUpdateSubscriptionTerm() {
        List<SBQQ__QuoteLine__c> quoteLineList = [SELECT Id, SBQQ__StartDate__c, SBQQ__EndDate__c FROM SBQQ__QuoteLine__c LIMIT 100];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        List<Id> quoteIds = new List<Id>();
        quoteIds.add(quote.Id);
        Assert.areEqual(1, quoteIds.size());
        List<Id> quoteLineIdsList =  new List<Id>();
        List<Date> startDateList =  new List<Date>();
        List<Date> endDateList =  new List<Date>();
        for(SBQQ__QuoteLine__c quoteLine : quoteLineList) {
            quoteLineIdsList.add(quoteLine.Id);
            startDateList.add(quoteLine.SBQQ__StartDate__c);
            endDateList.add(quoteLine.SBQQ__EndDate__c);
        }
        Test.startTest();
        QCPUtility.updateSubscriptionTerm(quoteLineIdsList, startDateList, endDateList);
        Test.stopTest();
    }

    @isTest
    private static void testUpdateSubscriptionTermForException() {
        List<SBQQ__QuoteLine__c> quoteLineList = [SELECT Id, SBQQ__StartDate__c, SBQQ__EndDate__c FROM SBQQ__QuoteLine__c LIMIT 100];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        List<Id> quoteIds = new List<Id>();
        quoteIds.add(quote.Id);
        Assert.areEqual(1, quoteIds.size());
        List<Id> quoteLineIdsList =  new List<Id>();
        List<Date> startDateList =  new List<Date>();
        List<Date> endDateList =  new List<Date>();
        for(SBQQ__QuoteLine__c quoteLine : quoteLineList) {
            quoteLineIdsList.add(quoteLine.Id);
            startDateList.add(quoteLine.SBQQ__StartDate__c);
            endDateList.add(quoteLine.SBQQ__EndDate__c);
        }
        Test.startTest();
        QCPUtility.updateSubscriptionTerm(null, startDateList, endDateList);
        Test.stopTest();
    }
}