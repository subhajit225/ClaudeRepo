@isTest
public class BatchCreatePSProjectTest {
    
    @testSetup static void createTestData() {
        /*TriggerControl__c custsetting = new TriggerControl__c();
        custsetting.Name = 'Opportunity';
        //custsetting.Disable_Trigger__c =
        custsetting.DisableTrigger__c = true;
        insert custsetting; 
        
        TriggerControl__c custsettingEnt = new TriggerControl__c();
        custsettingEnt.Name = 'Entitlement';
        //custsetting.Disable_Trigger__c =
        custsettingEnt.DisableTrigger__c = true;
        insert custsettingEnt; 
        
        TriggerControl__c PortalUserCreation = new TriggerControl__c();
        PortalUserCreation.Name = 'PortalUserCreation';
        // PortalUserCreation.DisableTrigger__c = true;
        insert PortalUserCreation; 
        
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance(); 
        disableFuncCS.Disable_Order_Old_Trigger__c = true;
        insert disableFuncCS;
        StateNameCode__c custset = new StateNameCode__c();
        custset.Name = 'California';
        custset.Code__c = 'US-CA';
        insert custset;
        
        Date closeDt = System.Today()+30;
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        */
        ShGl_DisableBusinessLogic__c disableFuncCS = ShGl_DisableBusinessLogic__c.getInstance(); 
        disableFuncCS.Disable_OrderItem_Old_Trigger__c = true;
        disableFuncCS.Disable_Order_Old_Trigger__c = true;
        disableFuncCS.Disable_Order_Triggers__c = true;
        disableFuncCS.Disable_Opportunity_Validation_Rules__c = true;
        insert disableFuncCS;
        Account acct = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        acct.Type = 'Marketplace';
        insert acct;
        List<Account> acclist = new List<Account>();
        acclist.add(acct);
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => acct.Id,
                'Email'  =>'leademail@hidden.com'
                };
                    Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);        
        insert cnt1;
        List<Contact> conlist = new List<Contact>();
        conlist.add(cnt1);
        
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => acct.Id,
                'Initial_Contacts_Name__c' => cnt1.Id,
                'Primary_Competitor__c' => 'Other',
                'Other_Primary_Competitor__c' => 'Other',
                
                'StageName' => '1 Discovery',
                'Other_Competitor_Field__c' => 'Other',
                'ForecastCategoryName' => 'Best Case',
                'SE_Forecast_Category__c' =>'Commit'
                };
                    Id opportunityRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Renewal_Opportunity').getRecordTypeId();
                    Opportunity oppty = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        oppty.RecordTypeId = opportunityRecordTypeId;
        insert oppty;
        List<Opportunity> opplist = new List<Opportunity>();
        opplist.add(oppty);
        
        list<Product2> prodlist = new list<Product2>();
        Map<String, Object>  prodMap = new Map<String, Object> {
            'Name' => 'RBK-INSTALL-RE',
                'ProductCode' => 'RBK-INSTALL-RE',
                'isActive' => true
                };
                    Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);  
        pd.Allow_PSO_Task_Creation__c = true;
        pd.ProductCode = 'RBK-INSTALL';
        prodlist.add(pd);
        Map<String, Object>  prodMap2 = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true
                };
                    Product2 pd2 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap2); 
        pd2.Allow_PSO_Task_Creation__c = true;
        pd2.ProductCode = 'RBK-PS-CNSLT-RMOT-PD';
        prodlist.add(pd2);
        Map<String, Object>  prodMap3 = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'POLARIS',
                'Product_Type__c' => 'RADAR'
                };
                    Product2 pd3 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap3);  
        pd3.Allow_PSO_Task_Creation__c = true;
        pd3.ProductCode = 'RBK-PS-CNSLT-ONST-PD';
        prodlist.add(pd3);
        Map<String, Object>  prodMap4 = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'POLARIS',
                'Product_Type__c' => 'RADAR'
                };
                    Product2 pd4 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap4);  
        pd4.Allow_PSO_Task_Creation__c = true;
        pd4.ProductCode = 'RBK-PS-RCDM-INST';
        prodlist.add(pd4);
        Map<String, Object>  prodMap5 = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'POLARIS',
                'Product_Type__c' => 'RADAR'
                };
                    Product2 pd5 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap5);  
        pd5.Allow_PSO_Task_Creation__c = true;
        pd5.ProductCode = 'RBK-DATA-MIGRATION';
        prodlist.add(pd5);
        Map<String, Object>  prodMap6 = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'POLARIS',
                'Product_Type__c' => 'RADAR'
                };
                    Product2 pd6 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap6);  
        pd6.Allow_PSO_Task_Creation__c = true;
        pd6.ProductCode = 'RBK-PS-RES-PD';
        prodlist.add(pd6);
        Map<String, Object>  prodMap7 = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'POLARIS',
                'Product_Type__c' => 'RADAR'
                };
                    Product2 pd7 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap7);  
        pd7.Allow_PSO_Task_Creation__c = true;
        pd7.ProductCode = 'RBK-PS-CONSULT';
        prodlist.add(pd7);
        Map<String, Object>  prodMap8 = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'POLARIS',
                'Product_Type__c' => 'RADAR'
                };
                    Product2 pd8 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap8);  
        pd8.Allow_PSO_Task_Creation__c = true;
        pd8.ProductCode = 'RBK-PS-TE-PD';
        prodlist.add(pd8);
        insert prodlist;
        Id pricebookId = Test.getStandardPricebookId();
        Map<String, Object>  quoteMap = new Map<String, Object> {
            'SBQQ__Account__c' => acct.Id,
                'SBQQ__Opportunity2__c' => oppty.Id
                };
                    SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppty.Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__PriceBook__c = pricebookId;
        qt1.ApprovalStatus__c = 'Approved';
        //insert qt1;
        
        oppty.Pricebook2Id = pricebookId;
        oppty.StageName = '1 Discovery';
        oppty.Partner_Level_Of_Involvement__c = '1.Rubrik initiated, Partner was fulfillment only';
        //oppty.SBQQ__PrimaryQuote__c = qt1.Id;
        oppty.Cloud_Partner_Impact__c = 'None';
       // oppty.Cloud_Partner_Led_Activity__c = 'No';
        oppty.Distributor_Lookup__c = acct.Id;
        //oppty.Partner_Lookup__c = acct.Id;
        update oppty;
        
        Id PSExternalRecId = Schema.SObjectType.PS_Project__c.getRecordTypeInfosByName().get('External').getRecordTypeId();
        PS_Project__c proj = new PS_Project__c();
        proj.Name = 'East West Bank - East West Ransomware Project(1)';
        proj.RecordTypeId = PSExternalRecId;
        proj.Project_Status__c = 'Not Started';
        proj.Project_Expected_Start_Date__c = system.today();
        proj.Project_Expected_End_Date__c = system.today();
        proj.Billable_Hours_Override__c = false;
        proj.Account__c = acct.Id;
        proj.Welcome_Letter_Contact__c = cnt1.Id;
        proj.opportunity__c = oppty.Id;
        proj.PO_Number__c = '4356666777' ;
        insert proj;
        
        Order od = new Order();
        od.Status = 'Draft';
        od.AccountId = acct.Id;
        od.OpportunityId = oppty.Id;
        od.EffectiveDate = Date.Today();
        od.ShippingStreet ='Test Street';
        od.ShippingCity ='Test City';
        od.ShippingState ='California';
        od.ShippingCountry ='United States';
        od.ShippingPostalcode ='94820';
        //od.ship_To_Name__c = acct.id;
        od.Type = 'Revenue';
        od.Est_Ship_Date__c = system.today();
        od.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId();
        od.Pricebook2Id = pricebookId;
        od.Order_Status__c = 'Order Accepted';
        od.POC_Opportunity__c = oppty.Id;
        od.Bill_To_Name__c = acct.Id;
        od.Actual_Order_Ship_Date__c = system.today();
        insert od;
        List<PricebookEntry> peList = new List<PricebookEntry>();
        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prodlist[0].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        peList.add(pbEntry);
        PricebookEntry pbEntry2 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prodlist[1].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        peList.add(pbEntry2);
        PricebookEntry pbEntry3 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prodlist[2].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        peList.add(pbEntry3);
        PricebookEntry pbEntry4 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prodlist[3].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        peList.add(pbEntry4);
        PricebookEntry pbEntry5 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prodlist[4].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        peList.add(pbEntry5);
        PricebookEntry pbEntry6 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prodlist[5].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        peList.add(pbEntry6);
        PricebookEntry pbEntry7 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prodlist[6].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        peList.add(pbEntry7);
        PricebookEntry pbEntry8 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prodlist[7].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        peList.add(pbEntry8);
        insert peList;
        
        od.Pricebook2Id = pricebookId;
        //update od;
        List<OrderItem> oiTems = new List<OrderItem>();
        OrderItem oritem = new OrderItem(OrderId=od.Id, Quantity=10, PricebookEntryId=peList[0].Id, UnitPrice = 10, Product2Id = prodlist[0].Id, SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009');
        OrderItem oritem1 = new OrderItem(OrderId=od.Id, Quantity=10, PricebookEntryId=peList[1].Id, UnitPrice = 10, Product2Id = prodlist[1].Id, SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009');
        OrderItem oritem2 = new OrderItem(OrderId=od.Id, Quantity=10, PricebookEntryId=peList[2].Id, UnitPrice = 10, Product2Id = prodlist[2].Id, SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009');
        OrderItem oritem3 = new OrderItem(OrderId=od.Id, Quantity=10, PricebookEntryId=peList[3].Id, UnitPrice = 10, Product2Id = prodlist[3].Id, SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009');
        OrderItem oritem4 = new OrderItem(OrderId=od.Id, Quantity=10, PricebookEntryId=peList[4].Id, UnitPrice = 10, Product2Id = prodlist[4].Id, SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009');
        OrderItem oritem5 = new OrderItem(OrderId=od.Id, Quantity=10, PricebookEntryId=peList[5].Id, UnitPrice = 10, Product2Id = prodlist[5].Id, SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009');
        OrderItem oritem6 = new OrderItem(OrderId=od.Id, Quantity=10, PricebookEntryId=peList[6].Id, UnitPrice = 10, Product2Id = prodlist[6].Id, SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009');
        OrderItem oritem7 = new OrderItem(OrderId=od.Id, Quantity=10, PricebookEntryId=peList[7].Id, UnitPrice = 10, Product2Id = prodlist[7].Id, SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009');
        oiTems.add(oritem);
        oiTems.add(oritem1);
        oiTems.add(oritem2);
        oiTems.add(oritem3);
        oiTems.add(oritem4);
        oiTems.add(oritem5);
        oiTems.add(oritem6);
        oiTems.add(oritem7);
        insert oiTems;
       // List<PS_Project__c> Pspro1 = CustomTestDataFactory.createPS_Projectwithopp(opplist,conlist,acclist);
    }
    @isTest
    static void testMethod1(){
        Test.startTest();
        BatchCreatePSProject batchPS = new BatchCreatePSProject('');
        Database.executeBatch(batchPS, 1);
        Test.stopTest();
    }
    @isTest
    static void testMethod2(){
        Test.startTest();
        BatchCreatePSProject batchPS = new BatchCreatePSProject('SELECT ID, AccountId, Type,PS_Project__c, POC_Opportunity__c, Bill_To_Name__c, OpportunityId, Account_Billing_Address_Region__c, PONumber FROM Order');
        Database.executeBatch(batchPS, 1);
        Test.stopTest();
    }
    @isTest
    static void testMethod3(){
        Test.startTest();
        System.schedule('Test', '0 0 0 ? * * *' , new ScheduleBatchCreatePSProject(''));
        Test.stopTest();
    }
    @isTest
    static void testMethod4(){
        Test.startTest();
        System.schedule('Test', '0 0 0 ? * * *' , new ScheduleBatchCreatePSProject());
        Test.stopTest();
    }
    
}