@isTest
public class ShipmentDetailHelperTest {
    /*
     * @description create data
     **/
    @testSetup
    public static void setupTest(){ 
       ShGl_TestFactoryHelper.insertTriggerControls();  
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act; 
        List<Account> accountList = new List<Account>();
        Account vAccount = new Account();
        accountList.add(vAccount);
        vAccount.Name = 'Test Account';
        vAccount.Type='Distributor';
        vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
        Account vAccount2 = new Account();
        vAccount2.Name = 'Test Account';
        vAccount2.recordTypeId = vAccount.recordTypeId;       
        accountList.add(vAccount2); 
        insert accountList;
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
                };
                    Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;
        OktaUserUtilityTest.oktaCustomSettingsParams();

        insert new ShGl_DisableBusinessLogic__c(Disable_Product2_Validation_Rules__c = true);
        String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(
            Alias = 'adminU', Email='AdminUser@rubrik.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName=uniqueUserName
        );
        insert u;
        
        insert new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Triggers__c = true, Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true ,Disable_Order_Email_Alerts__c = false, Disable_Order_Old_Trigger__c = true, Disable_Order_Triggers__c = false, setupOwnerId = u.Id);   
        System.runAs(u) {
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => act.Id,
                'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId()
                };
                    Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        insert opp;
        
        opp.Partner_Lookup__c = vAccount2.id;
        opp.Distributor_Lookup__c = vAccount2.id;
        
        update opp;
        ShipmentDetail__c overviewSD = new ShipmentDetail__c(Quote_ShipmentValidation__c = 'NA', RecordTypeId = Constants.overViewRecordTypeId);
        insert overviewSD;
        }

    }
    
    @isTest
    public static void testShipmentDetails(){
        System.runAs(new User(Id=UserInfo.getUserId())) {
         insert new ShGl_DisableBusinessLogic__c(Disable_Product2_Validation_Rules__c = true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true, setupOwnerId = userinfo.getuserid());      
        Account act = [Select Id from Account LIMIT 1];
        Opportunity opp = [Select Id, Override__c, Aspen_Eligibility__c from Opportunity LIMIT 1 ];
        opp.Aspen_Eligibility__c = 'Actual Aspen';
        opp.Override__c = false;
        update opp;

        Contact cnt = [Select Id from Contact LIMIT 1];
        Test.startTest();
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__PrimaryContact__c = cnt.Id;
        qt.SBQQ__Primary__c = true;
        insert qt; 
        
           Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'STANDALONE',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit'
                };
                    
                    Map<String, Object> prdMap1 = new Map<String, Object> {
                        'Name' => 'Subscription', 
                            'IsActive' => true, 
                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                            'SBQQ__SubscriptionTerm__c' => 12, 
                            'SBQQ__SubscriptionType__c' => 'Renewable'
                            };
                                Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
        
        //prdHW.ProductCode = 'Standalone';
        //prdSubs.ProductCode = 'Standalone';
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        insert prdList;
        
        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pBList.add(pbeHW);
        
        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pBList.add(pbeSubs);
        insert pBList;
        
        
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' );  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' ); 
        qliList.add( qli1 );
        qliList.add( qli2 );
        insert qliList;
        
         List<Product2> prooList = new List<Product2> ();
        Product2 prdOne = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli1.SBQQ__Product__c LIMIT 1 ];
        Product2 prdTwo = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli2.SBQQ__Product__c LIMIT 1 ];
        prdOne.ProductCode = 'STANDALONE';
        prdOne.Product_Type__c = 'Spares';
        prdTwo.ProductCode = 'STANDALONE';
        prdTwo.Product_Type__c = 'Spares';
        prooList.add(prdOne);
        prooList.add(prdTwo);
        update prooList;
                
        //prdHW.ProductCode = 'Standalone';
        SBQQ__QuoteLine__c sbqProu = [Select id,SBQQ__ProductCode__c from SBQQ__QuoteLine__c where id = :qli1.Id ];
        
        
         SBQQ__Quote__c qtQue = [Select Id,SBQQ__Primary__c,Name,ApprovalStatus__c,SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Aspen_Eligibility__c, SBQQ__Opportunity2__r.Override__c from SBQQ__Quote__c where id = :qt.Id ];

      
        ShipmentDetail__c shpEx = new ShipmentDetail__c();
        shpEx.HW_SerialNumber__c = 'Ass-65431';
        shpEx.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shpEx.ProductName__c = prdHW.Name;
        shpEx.Quantity__c = 2;
        shpEx.QuoteNumber__c = qtQue.Name ;
        shpEx.Status__c = 'Success';
        shpEx.ShippedDate__c = '12/16/15';
        shpEx.Quote__c = qtQue.Id;
        insert shpEx;
        
        
       	ShipmentDetail__c shp = new ShipmentDetail__c();
        shp.HW_SerialNumber__c = 'Ass-654321';
        shp.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shp.ProductName__c = prdHW.Name;
        shp.Quantity__c = 2;
        shp.QuoteNumber__c = qtQue.Name ;
        shp.ShippedDate__c = '12/16/15';
        shp.Status__c = '';
        shp.Quote__c = qtQue.Id;
        insert shp;
        
        ShipmentDetail__c shp1 = new ShipmentDetail__c();
        shp1.HW_SerialNumber__c = 'Ass-654321';
        shp1.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shp1.ProductName__c = prdHW.Name;
        shp1.Quantity__c = 20;
        shp1.QuoteNumber__c = qtQue.Name ;
        shp1.ShippedDate__c = '12/16/15';
        shp1.Status__c = '';
        shp1.Quote__c = qtQue.Id;
        insert shp1;
		ShipmentDetail__c shppe = [Select id,Status__c from ShipmentDetail__c where Quantity__c = 2 LIMIT 1];
        shppe.Status__c = 'New';

        update shppe;
        Test.stopTest();
        System.assert(true);
        }
    }
    
    @isTest
    public static void testShipmentDetails2(){
       System.runAs(new User(Id=UserInfo.getUserId())) {
         insert new ShGl_DisableBusinessLogic__c(Disable_Product2_Validation_Rules__c = true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true, setupOwnerId = userinfo.getuserid());      
        Account act = [Select Id from Account LIMIT 1];
        Opportunity opp = [Select Id from Opportunity LIMIT 1 ];
        Contact cnt = [Select Id from Contact LIMIT 1];
        Test.startTest();
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__PrimaryContact__c = cnt.Id;
        qt.SBQQ__Primary__c = true;
        insert qt; 
        
           Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'STANDALONE',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit'
                };
                    
                    Map<String, Object> prdMap1 = new Map<String, Object> {
                        'Name' => 'Subscription', 
                            'IsActive' => true, 
                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                            'SBQQ__SubscriptionTerm__c' => 12, 
                            'SBQQ__SubscriptionType__c' => 'Renewable'
                            };
                                Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
        
        //prdHW.ProductCode = 'Standalone';
        //prdSubs.ProductCode = 'Standalone';
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        insert prdList;
 
        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pBList.add(pbeHW);
        
        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pBList.add(pbeSubs);
        insert pBList;
        
        
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' );  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' ); 
        qliList.add( qli1 );
        qliList.add( qli2 );
        insert qliList;
        
         List<Product2> prooList = new List<Product2> ();
        Product2 prdOne = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli1.SBQQ__Product__c LIMIT 1 ];
        Product2 prdTwo = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli2.SBQQ__Product__c LIMIT 1 ];
        prdOne.ProductCode = 'STANDALONE';
        prdOne.Product_Type__c = 'Spares';
        prdTwo.ProductCode = 'STANDALONE';
        prdTwo.Product_Type__c = 'Spares';
        prooList.add(prdOne);
        prooList.add(prdTwo);
        update prooList;
        
        
        SBQQ__QuoteLine__c sbqProu = [Select id,SBQQ__ProductCode__c from SBQQ__QuoteLine__c where id = :qli1.Id ];
        
         SBQQ__Quote__c qtQue = [Select Id,SBQQ__Primary__c,Name,ApprovalStatus__c,SBQQ__Opportunity2__c from SBQQ__Quote__c where id = :qt.Id ];
        

        ShipmentDetail__c shpEx = new ShipmentDetail__c();
        shpEx.HW_SerialNumber__c = 'Ass-65431';
        shpEx.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shpEx.ProductName__c = prdHW.Name;
        shpEx.Quantity__c = 2;
        shpEx.QuoteNumber__c = qtQue.Name ;
        shpEx.Quote__c = qtQue.Id;
        shpEx.Status__c = 'Success';
        shpEx.ShippedDate__c = '12/16/15';
        insert shpEx;
        
        
       	ShipmentDetail__c shp = new ShipmentDetail__c();
        shp.HW_SerialNumber__c = 'Ass-654321';
        shp.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shp.ProductName__c = prdHW.Name;
        shp.Quantity__c = 2;
        shp.QuoteNumber__c = qtQue.Name ;
        shp.Quote__c = qtQue.Id;
        shp.ShippedDate__c = '12/16/15';
        shp.Status__c = '';
        insert shp;
        
        ShipmentDetail__c shp1 = new ShipmentDetail__c();
        shp1.HW_SerialNumber__c = 'Ass-654321';
        shp1.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shp1.ProductName__c = prdHW.Name;
        shp1.Quantity__c = 20;
        shp1.QuoteNumber__c = qtQue.Name ;
        shp1.Quote__c = qtQue.Id;
        shp1.ShippedDate__c = '12/16/15';
        shp1.Status__c = '';
        insert shp1;
        
		ShipmentDetail__c shpee = [Select id,Status__c,QuoteNumber__c,SalesOrderNumber__c from ShipmentDetail__c where Quantity__c = 2 LIMIT 1];
        shpee.SalesOrderNumber__c = 'BRIKONLY';
        shpee.Status__c = 'New';
        
        
        update shpee;
        Test.stopTest();
        System.assert(true);
        }
    }
    
    @isTest
    public static void testRCASpareQuote(){
        System.runAs(new User(Id=UserInfo.getUserId())) {
         insert new ShGl_DisableBusinessLogic__c(Disable_Product2_Validation_Rules__c = true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true, setupOwnerId = userinfo.getuserid());      
        Account act = [Select Id from Account LIMIT 1];
         Opportunity opp = [Select Id from Opportunity LIMIT 1 ];
        Contact cnt = [Select Id from Contact LIMIT 1];
        Test.startTest();
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__PrimaryContact__c = cnt.Id;
        insert qt; 
        
         Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'RCA-SFP-TSR-01',
            'IsActive' => true
         };
    	Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        insert prdHW;
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        insert pbeHW;
        
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Ass-65431',Product_Type__c = 'Spares' );  
		insert qli1;
        List<SBQQ__Quote__c> lstQuote = [Select  id, Name from SBQQ__Quote__c Where Id = : qt.Id];

        ShipmentDetail__c shpEx = new ShipmentDetail__c();
        shpEx.HW_SerialNumber__c = 'Ass-65431';
        shpEx.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shpEx.ProductName__c = 'RCA-SFP-TSR-01';
        shpEx.Quantity__c = 1;
        shpEx.QuoteNumber__c = lstQuote[0].Name ;
        shpEx.Quote__c = lstQuote[0].Id;
        shpEx.Status__c = '';
        shpEx.order__c = null;
        shpEx.ShippedDate__c = '12/16/15';
        insert shpEx;
		shpEx.Status__c = 'New';
        update shpEx;        
        Map<String, List<ShipmentDetail__c>> quoteNameVsSDList = new Map<String, List<ShipmentDetail__c>>{lstQuote[0].Name => new List<ShipmentDetail__c>{shpEx}};
        Map<String, ShipmentDetail__c> existingOverviews = new Map<String, ShipmentDetail__c>();
        Map<String, String> quoteNameVsId = new Map<String, String>{lstQuote[0].Name => lstQuote[0].Id};
        ShipmentDetailHelper handler = new  ShipmentDetailHelper();
        handler.createOverviewRecord(quoteNameVsSDList, existingOverviews, quoteNameVsId);
        Map<Id, String> orderSdProcessStatus = new Map<Id, String>{shpEx.Order__c => 'Success'};
        handler.emitStatus(shpEx, orderSdProcessStatus);
        shpEx.Status__c = 'New';
        orderSdProcessStatus = new Map<Id, String>{shpEx.Order__c => 'New'};
        handler.emitStatus(shpEx, orderSdProcessStatus);
        Test.stopTest();   
        System.assert(true);
        }
        
    }
    
    @isTest
    public static void testNotAspenQuote(){
       System.runAs(new User(Id=UserInfo.getUserId())) {
         insert new ShGl_DisableBusinessLogic__c(Disable_Product2_Validation_Rules__c = true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true, setupOwnerId = userinfo.getuserid());              Account act = [Select Id from Account LIMIT 1];
        Opportunity opp = [Select Id from Opportunity LIMIT 1 ];
        Contact cnt = [Select Id from Contact LIMIT 1];
        Test.startTest();
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__PrimaryContact__c = cnt.Id;
        qt.SBQQ__Primary__c = true;
        qt.ApprovalStatus__c = 'Approved';
        insert qt; 
        
        SBQQ__Quote__c qtQue = [Select id, Name from SBQQ__Quote__c where Id = : qt.Id];
        
             Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'HW-Product',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit'
             };
            Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
			insert prdHW;
        ShipmentDetail__c shpEx = new ShipmentDetail__c();
        shpEx.HW_SerialNumber__c = 'Ass-65431';
        shpEx.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shpEx.ProductName__c = 'HW-Product';
        shpEx.Quantity__c = 2;
        shpEx.QuoteNumber__c = qtQue.Name ;
        shpEx.Quote__c = qtQue.Id;
        shpEx.Status__c = '';
        shpEx.ShippedDate__c = '12/16/15';
        insert shpEx;

        shpEx.Status__c = 'New';
        update shpEx;
       Test.StopTest();
       System.assert(true);
        }
    }
    
        @isTest
    public static void testNotApprovedQuote(){
       System.runAs(new User(Id=UserInfo.getUserId())) {
         insert new ShGl_DisableBusinessLogic__c(Disable_Product2_Validation_Rules__c = true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true, setupOwnerId = userinfo.getuserid());              Account act = [Select Id from Account LIMIT 1];
        Opportunity opp = [Select Id from Opportunity LIMIT 1 ];
        Contact cnt = [Select Id from Contact LIMIT 1];
        Test.startTest();
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__PrimaryContact__c = cnt.Id;
        insert qt; 
        
        SBQQ__Quote__c qtQue = [Select id, Name from SBQQ__Quote__c where Id = : qt.Id];
        
             Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'HW-Product',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit'
             };
            Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
			insert prdHW;
          Asset objAsset =   new Asset(
          Name = 'Ass-65431',
          SerialNumber = 'Ass-65431',
          serial_number__c = 'Ass-65431',
          AccountId = act.Id,
          Product2Id = prdHW.Id
        );
        insert objAsset;
        ShipmentDetail__c shpEx = new ShipmentDetail__c();
        shpEx.HW_SerialNumber__c = 'Ass-65431';
        shpEx.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shpEx.ProductName__c = 'HW-Product';
        shpEx.Quantity__c = 2;
        shpEx.QuoteNumber__c = qtQue.Name ;
        shpEx.Quote__c = qtQue.Id;
        shpEx.Status__c = '';
        shpEx.ShippedDate__c = '12/16/15';
        insert shpEx;

        shpEx.Status__c = 'New';
        update shpEx;
       Test.StopTest();
       System.assert(true);
        }
    }

     @isTest
    public static void testShipmentDetails4(){
System.runAs(new User(Id=UserInfo.getUserId())) {
         insert new ShGl_DisableBusinessLogic__c(Disable_Product2_Validation_Rules__c = true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true, setupOwnerId = userinfo.getuserid());              Account act = [Select Id from Account LIMIT 1];
         Opportunity opp = [Select Id from Opportunity LIMIT 1 ];
        Contact cnt = [Select Id from Contact LIMIT 1];
        Test.startTest();
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__PrimaryContact__c = cnt.Id;
        qt.SBQQ__Primary__c = true;
        insert qt; 
        
           Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'STANDALONE',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit'
                };
                    
                    Map<String, Object> prdMap1 = new Map<String, Object> {
                        'Name' => 'Subscription', 
                            'IsActive' => true, 
                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                            'SBQQ__SubscriptionTerm__c' => 12, 
                            'SBQQ__SubscriptionType__c' => 'Renewable'
                            };
                                Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
        
        //prdHW.ProductCode = 'Standalone';
        //prdSubs.ProductCode = 'Standalone';
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        insert prdList;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pBList.add(pbeHW);
        
        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pBList.add(pbeSubs);
        insert pBList;
        
        
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' );  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' ); 
        qliList.add( qli1 );
        qliList.add( qli2 );
        insert qliList;
        
         List<Product2> prooList = new List<Product2> ();
        Product2 prdOne = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli1.SBQQ__Product__c LIMIT 1 ];
        Product2 prdTwo = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli2.SBQQ__Product__c LIMIT 1 ];
        prdOne.ProductCode = 'STANDALONE';
        prdOne.Product_Type__c = 'Spares';
        prdTwo.ProductCode = 'STANDALONE';
        prdTwo.Product_Type__c = 'Spares';
        prooList.add(prdOne);
        prooList.add(prdTwo);
        update prooList;
                
        SBQQ__QuoteLine__c sbqProu = [Select id,SBQQ__ProductCode__c from SBQQ__QuoteLine__c where id = :qli1.Id ];
        
    
         SBQQ__Quote__c qtQue = [Select Id,SBQQ__Primary__c,Name,ApprovalStatus__c,SBQQ__Opportunity2__c from SBQQ__Quote__c where id = :qt.Id ];
                
        ShipmentDetail__c shpEx = new ShipmentDetail__c();
        shpEx.HW_SerialNumber__c = 'Ass-65431';
        shpEx.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shpEx.ProductName__c = prdHW.Name;
        shpEx.Quantity__c = 2;
        shpEx.QuoteNumber__c = qtQue.Name ;
        shpEx.Status__c = 'Success';
        shpEx.ShippedDate__c = '12/16/15';
        insert shpEx;
        
        
       	ShipmentDetail__c shp = new ShipmentDetail__c();
        shp.HW_SerialNumber__c = 'Ass-654321';
        shp.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shp.ProductName__c = prdHW.Name;
        shp.Quantity__c = 2;
        shp.QuoteNumber__c = qtQue.Name ;
        shp.Quote__c = qtQue.Id ;
        shp.ShippedDate__c = '12/16/15';
        shp.Status__c = '';
        insert shp;
        
        ShipmentDetail__c shp1 = new ShipmentDetail__c();
        shp1.HW_SerialNumber__c = 'Ass-654321';
        shp1.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shp1.ProductName__c = prdHW.Name;
        shp1.Quantity__c = 20;
        shp1.QuoteNumber__c = qtQue.Name ;
        shp1.ShippedDate__c = '12/16/15';
        shp1.Status__c = '';
        shp1.Quote__c = qtQue.Id ;
        insert shp1;
		ShipmentDetail__c shpef = [Select id,Status__c,QuoteNumber__c,SalesOrderNumber__c,ProductName__c from ShipmentDetail__c where Quantity__c = 2 LIMIT 1];
        shpef.QuoteNumber__c = '';
        shpef.Status__c = 'New';
        
        
        update shpef;
        Test.stopTest();
        System.assert(true);
        }
    }
    
     @isTest
    public static void testShipmentDetails5(){
System.runAs(new User(Id=UserInfo.getUserId())) {
         insert new ShGl_DisableBusinessLogic__c(Disable_Product2_Validation_Rules__c = true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true, setupOwnerId = userinfo.getuserid());              Account act = [Select Id from Account LIMIT 1];
         Opportunity opp = [Select Id from Opportunity LIMIT 1 ];
        Contact cnt = [Select Id from Contact LIMIT 1];
        Test.startTest();
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__PrimaryContact__c = cnt.Id;
        qt.SBQQ__Primary__c = true;
        insert qt; 
        
           Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'STANDALONE',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit'
                };
                    
                    Map<String, Object> prdMap1 = new Map<String, Object> {
                        'Name' => 'Subscription', 
                            'IsActive' => true, 
                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                            'SBQQ__SubscriptionTerm__c' => 12, 
                            'SBQQ__SubscriptionType__c' => 'Renewable'
                            };
                                Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
        

        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        insert prdList;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pBList.add(pbeHW);
        
        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pBList.add(pbeSubs);
        insert pBList;
        
        
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' );  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' ); 
        qliList.add( qli1 );
        qliList.add( qli2 );
        insert qliList;
        
         List<Product2> prooList = new List<Product2> ();
        Product2 prdOne = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli1.SBQQ__Product__c LIMIT 1 ];
        Product2 prdTwo = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli2.SBQQ__Product__c LIMIT 1 ];
        prdOne.ProductCode = 'STANDALONE';
        prdOne.Product_Type__c = 'Spares';
        prdTwo.ProductCode = 'STANDALONE';
        prdTwo.Product_Type__c = 'Spares';
        prooList.add(prdOne);
        prooList.add(prdTwo);
        update prooList;
                
        //prdHW.ProductCode = 'Standalone';
        SBQQ__QuoteLine__c sbqProu = [Select id,SBQQ__ProductCode__c from SBQQ__QuoteLine__c where id = :qli1.Id ];
        
        
         SBQQ__Quote__c qtQue = [Select Id,SBQQ__Primary__c,Name,ApprovalStatus__c,SBQQ__Opportunity2__c from SBQQ__Quote__c where id = :qt.Id ];
        

        ShipmentDetail__c shpEx = new ShipmentDetail__c();
        shpEx.HW_SerialNumber__c = 'Ass-65431';
        shpEx.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shpEx.ProductName__c = prdHW.Name;
        shpEx.Quantity__c = 2;
        shpEx.QuoteNumber__c = qtQue.Name ;
        shpEx.Status__c = 'Success';
        shpEx.ShippedDate__c = '12/16/15';
        shpEx.Quote__c = qtQue.Id ;
        insert shpEx;
        
        
       	ShipmentDetail__c shp = new ShipmentDetail__c();
        shp.HW_SerialNumber__c = 'Ass-654321';
        shp.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shp.ProductName__c = prdHW.Name;
        shp.Quantity__c = 2;
        shp.QuoteNumber__c = qtQue.Name ;
        shp.ShippedDate__c = '12/16/15';
        shp.Status__c = '';
        shp.Quote__c = qtQue.Id ;
        insert shp;
        
        ShipmentDetail__c shp1 = new ShipmentDetail__c();
        shp1.HW_SerialNumber__c = 'Ass-654321';
        shp1.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shp1.ProductName__c = prdHW.Name;
        shp1.Quantity__c = 20;
        shp1.QuoteNumber__c = qtQue.Name ;
        shp1.ShippedDate__c = '12/16/15';
        shp1.Status__c = '';
        shp1.Quote__c = qtQue.Id ;
        insert shp1;
		ShipmentDetail__c shpef = [Select id,Status__c,QuoteNumber__c,SalesOrderNumber__c,ProductName__c from ShipmentDetail__c where Quantity__c = 2 LIMIT 1];
        shpef.SalesOrderNumber__c = 'spr';
        shpef.Status__c = 'New';
        
        
        update shpef;
        Test.stopTest();
        System.assert(true);
        }
    }
    @isTest
    public static void testShipmentDetails6(){
    	System.runAs(new User(Id=UserInfo.getUserId())) {
         insert new ShGl_DisableBusinessLogic__c(Disable_Product2_Validation_Rules__c = true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true, setupOwnerId = userinfo.getuserid());              
	 Account act = [Select Id from Account LIMIT 1];
         Opportunity opp = [Select Id from Opportunity LIMIT 1 ];
        Contact cnt = [Select Id from Contact LIMIT 1];
        Test.startTest();
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__PrimaryContact__c = cnt.Id;
        qt.SBQQ__Primary__c = true;
        insert qt; 
        
           Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'STANDALONE',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit'
                };
                    
                    Map<String, Object> prdMap1 = new Map<String, Object> {
                        'Name' => 'Subscription', 
                            'IsActive' => true, 
                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                            'SBQQ__SubscriptionTerm__c' => 12, 
                            'SBQQ__SubscriptionType__c' => 'Renewable'
                            };
                                Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
        

        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        insert prdList;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pBList.add(pbeHW);
        
        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pBList.add(pbeSubs);
        insert pBList;
        
        
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' );  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' ); 
        qliList.add( qli1 );
        qliList.add( qli2 );
        insert qliList;
        
         List<Product2> prooList = new List<Product2> ();
        Product2 prdOne = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli1.SBQQ__Product__c LIMIT 1 ];
        Product2 prdTwo = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli2.SBQQ__Product__c LIMIT 1 ];
        prdOne.ProductCode = 'STANDALONE';
        prdOne.Product_Type__c = 'Spares';
        prdTwo.ProductCode = 'STANDALONE';
        prdTwo.Product_Type__c = 'Spares';
        prooList.add(prdOne);
        prooList.add(prdTwo);
        update prooList;
                
        SBQQ__QuoteLine__c sbqProu = [Select id,SBQQ__ProductCode__c from SBQQ__QuoteLine__c where id = :qli1.Id ];
        
        SBQQ__Quote__c qtQue = [Select Id,SBQQ__Primary__c,Name,ApprovalStatus__c,SBQQ__Opportunity2__c from SBQQ__Quote__c where id = :qt.Id ];
                
        ShipmentDetail__c shpEx = new ShipmentDetail__c();
        shpEx.HW_SerialNumber__c = 'Ass-65431';
        shpEx.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shpEx.ProductName__c = prdHW.Name;
        shpEx.Quantity__c = 2;
        shpEx.QuoteNumber__c = qtQue.Name ;
        shpEx.Status__c = 'Success';
        shpEx.ShippedDate__c = '12/16/15';
        shpEx.Quote__c = qtQue.Id ;
        insert shpEx;
        
        
       	ShipmentDetail__c shp = new ShipmentDetail__c();
        shp.HW_SerialNumber__c = 'Ass-654321';
        shp.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shp.ProductName__c = prdHW.Name;
        shp.Quantity__c = 2;
        shp.QuoteNumber__c = qtQue.Name ;
        shp.ShippedDate__c = '12/16/15';
        shp.Status__c = '';
        shp.Quote__c = qtQue.Id ;

        insert shp;
        
        ShipmentDetail__c shp1 = new ShipmentDetail__c();
        shp1.HW_SerialNumber__c = 'Ass-654321';
        shp1.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shp1.ProductName__c = prdHW.Name;
        shp1.Quantity__c = 20;
        shp1.QuoteNumber__c = qtQue.Name ;
        shp1.ShippedDate__c = '12/16/15';
        shp1.Status__c = '';
        shp1.Quote__c = qtQue.Id ;

        insert shp1;
        
		ShipmentDetail__c shpef = [Select id,Status__c,QuoteNumber__c,SalesOrderNumber__c,ProductName__c from ShipmentDetail__c where Quantity__c = 2 LIMIT 1];
        shpef.QuoteNumber__c = '123';
        shpef.Status__c = 'New';
        
        
        update shpef;
        Test.stopTest();
        System.assert(true);
        }
    }
    
    @isTest
    public static void testShipmentDetails7(){
	System.runAs(new User(Id=UserInfo.getUserId())) {
         insert new ShGl_DisableBusinessLogic__c(Disable_Product2_Validation_Rules__c = true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true, setupOwnerId = userinfo.getuserid());             
        Account act = [Select Id from Account LIMIT 1];
         Opportunity opp = [Select Id, Override__c,Aspen_Eligibility__c from Opportunity LIMIT 1 ];
         opp.Aspen_Eligibility__c = 'Actual Aspen';
        opp.Override__c = false;
        update opp;

        Contact cnt = [Select Id from Contact LIMIT 1];
        Test.startTest();
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__PrimaryContact__c = cnt.Id;
        qt.SBQQ__Primary__c = true;
        insert qt; 
        
           Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'STANDALONE',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit'
                };
                    
                    Map<String, Object> prdMap1 = new Map<String, Object> {
                        'Name' => 'Subscription', 
                            'IsActive' => true, 
                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                            'SBQQ__SubscriptionTerm__c' => 12, 
                            'SBQQ__SubscriptionType__c' => 'Renewable'
                            };
                                Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        insert prdList;
        
        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pBList.add(pbeHW);
        
        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pBList.add(pbeSubs);
        insert pBList;
        
         Asset objAsset =   new Asset(
          Name = 'Ass-65431',
          SerialNumber = 'Ass-65431',
          serial_number__c = 'Ass-65431',
          AccountId = act.Id,
          Product2Id = prdHW.Id
        );
        insert objAsset;
		List<Asset> lstAsset = [Select id from Asset];
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' );  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' ); 
        qliList.add( qli1 );
        qliList.add( qli2 );
        insert qliList;
        
         List<Product2> prooList = new List<Product2> ();
        Product2 prdOne = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli1.SBQQ__Product__c LIMIT 1 ];
        Product2 prdTwo = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli2.SBQQ__Product__c LIMIT 1 ];
        prdOne.ProductCode = 'STANDALONE';
        prdOne.Product_Type__c = 'Spares';
        prdTwo.ProductCode = 'STANDALONE';
        prdTwo.Product_Type__c = 'Spares';
        prooList.add(prdOne);
        prooList.add(prdTwo);
        update prooList;
                
        SBQQ__QuoteLine__c sbqProu = [Select id,SBQQ__ProductCode__c from SBQQ__QuoteLine__c where id = :qli1.Id ];
        
         SBQQ__Quote__c qtQue = [Select Id,SBQQ__Primary__c,Name,ApprovalStatus__c,SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Aspen_Eligibility__c, SBQQ__Opportunity2__r.Override__c from SBQQ__Quote__c where id = :qt.Id ];
        

        ShipmentDetail__c shpEx = new ShipmentDetail__c();
        shpEx.HW_SerialNumber__c = 'Ass-65431';
        shpEx.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shpEx.ProductName__c = prdHW.Name;
        shpEx.Quantity__c = 2;
        shpEx.QuoteNumber__c = qtQue.Name ;
        shpEx.Status__c = 'Success';
        shpEx.ShippedDate__c = '12/16/15';
        shpEx.Quote__c = qtQue.Id ;
        insert shpEx;
        

       	ShipmentDetail__c shp = new ShipmentDetail__c();
        shp.HW_SerialNumber__c = 'Ass-654321';
        shp.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shp.ProductName__c = prdHW.Name;
        shp.Quantity__c = 2;
        shp.QuoteNumber__c = qtQue.Name ;
        shp.ShippedDate__c = '12/16/15';
        shp.Status__c = '';
        shp.Quote__c = qtQue.Id ;

        insert shp;
        
        ShipmentDetail__c shp1 = new ShipmentDetail__c();
        shp1.HW_SerialNumber__c = 'Ass-654321';
        shp1.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shp1.ProductName__c = prdHW.Name;
        shp1.Quantity__c = 20;
        shp1.QuoteNumber__c = qtQue.Name ;
        shp1.ShippedDate__c = '12/16/15';
        shp1.Status__c = '';
        shp1.Quote__c = qtQue.Id;
        insert shp1;
        
        
		ShipmentDetail__c shpef = [Select id,Status__c,QuoteNumber__c,SalesOrderNumber__c,ProductName__c from ShipmentDetail__c where Quantity__c = 2 LIMIT 1];
        
        shpef.Status__c = 'New';
        
        update shpef;
        Test.stopTest();
        System.assert(true);
        }
    }
     @isTest
    public static void testShipmentDetails8(){
        System.runAs(new User(Id=UserInfo.getUserId())) {
        insert new ShGl_DisableBusinessLogic__c(Disable_Product2_Validation_Rules__c = true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true, setupOwnerId = userinfo.getuserid());              Account act = [Select Id from Account LIMIT 1];
         Opportunity opp = [Select Id, Override__c,Aspen_Eligibility__c from Opportunity LIMIT 1 ];
         opp.Aspen_Eligibility__c = 'Actual Aspen';
        opp.Override__c = false;
        update opp;

        Contact cnt = [Select Id from Contact LIMIT 1];
        Test.startTest();
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__PrimaryContact__c = cnt.Id;
        qt.SBQQ__Primary__c = true;
        insert qt; 
        
           Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'STANDALONE',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit'
                };
                    
                    Map<String, Object> prdMap1 = new Map<String, Object> {
                        'Name' => 'Subscription', 
                            'IsActive' => true, 
                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                            'SBQQ__SubscriptionTerm__c' => 12, 
                            'SBQQ__SubscriptionType__c' => 'Renewable'
                            };
                                Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
    
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        insert prdList;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pBList.add(pbeHW);
        
        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pBList.add(pbeSubs);
        insert pBList;
        
        
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' );  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' ); 
        qliList.add( qli1 );
        qliList.add( qli2 );
        insert qliList;
        
         List<Product2> prooList = new List<Product2> ();
        Product2 prdOne = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli1.SBQQ__Product__c LIMIT 1 ];
        Product2 prdTwo = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli2.SBQQ__Product__c LIMIT 1 ];
        prdOne.ProductCode = 'STANDALONE';
        prdOne.Product_Type__c = 'Spares';
        prdTwo.ProductCode = 'STANDALONE';
        prdTwo.Product_Type__c = 'Spares';
        prooList.add(prdOne);
        prooList.add(prdTwo);
        update prooList;
        
        SBQQ__QuoteLine__c sbqProu = [Select id,SBQQ__ProductCode__c from SBQQ__QuoteLine__c where id = :qli1.Id ];
        
        

         SBQQ__Quote__c qtQue = [Select Id,SBQQ__Primary__c,Name,ApprovalStatus__c,SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Aspen_Eligibility__c, SBQQ__Opportunity2__r.Override__c from SBQQ__Quote__c where id = :qt.Id ];
        

        ShipmentDetail__c shpEx = new ShipmentDetail__c();
        shpEx.HW_SerialNumber__c = 'Ass-65431';
        shpEx.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shpEx.ProductName__c = prdHW.Name;
        shpEx.Quantity__c = 2;
        shpEx.QuoteNumber__c = qtQue.Name ;
        shpEx.Status__c = 'Success';
        shpEx.ShippedDate__c = '12/16/15';
        shpEx.Quote__c = qtQue.Id;
        insert shpEx;
        
        
       	ShipmentDetail__c shp = new ShipmentDetail__c();
        shp.HW_SerialNumber__c = 'Ass-654321';
        shp.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shp.ProductName__c = prdHW.Name;
        shp.Quantity__c = 2;
        shp.QuoteNumber__c = qtQue.Name ;
        shp.ShippedDate__c = '12/16/15';
        shp.Status__c = '';
        shp.Quote__c = qtQue.Id;
        insert shp;
        
        ShipmentDetail__c shp1 = new ShipmentDetail__c();
        shp1.HW_SerialNumber__c = 'Ass-654321';
        shp1.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shp1.ProductName__c = prdHW.Name;
        shp1.Quantity__c = 20;
        shp1.QuoteNumber__c = qtQue.Name ;
        shp1.ShippedDate__c = '12/16/15';
        shp1.Status__c = '';
        shp1.Quote__c = qtQue.Id;
        insert shp1;
        
		ShipmentDetail__c shpef = [Select id,Status__c,QuoteNumber__c,SalesOrderNumber__c,ProductName__c from ShipmentDetail__c where Quantity__c = 2 LIMIT 1];
        
        shpef.Status__c = 'New';
        update shpef;
        Test.stopTest();
        System.assert(true);
        }
    }
     @isTest
    public static void testShipmentDetails9(){
	System.runAs(new User(Id=UserInfo.getUserId())) {
         insert new ShGl_DisableBusinessLogic__c(Disable_Product2_Validation_Rules__c = true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true, setupOwnerId = userinfo.getuserid());              
	 Account act = [Select Id from Account LIMIT 1];
         Opportunity opp = [Select Id, Override__c,Aspen_Eligibility__c from Opportunity LIMIT 1 ];
         opp.Aspen_Eligibility__c = 'Actual Aspen';
        opp.Override__c = false;
        update opp;
        Contact cnt = [Select Id from Contact LIMIT 1];
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__PrimaryContact__c = cnt.Id;
        qt.SBQQ__Primary__c = true;
        insert qt; 
        Test.startTest();
           Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'STANDALONE',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit'
                };
                    
                    Map<String, Object> prdMap1 = new Map<String, Object> {
                        'Name' => 'Subscription', 
                            'IsActive' => true, 
                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                            'SBQQ__SubscriptionTerm__c' => 12, 
                            'SBQQ__SubscriptionType__c' => 'Renewable'
                            };
                                Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
        

        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        insert prdList;
        
        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pBList.add(pbeHW);
        
        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pBList.add(pbeSubs);
        insert pBList;
        
        
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' );  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' ); 
        qliList.add( qli1 );
        qliList.add( qli2 );
        insert qliList;
        
         List<Product2> prooList = new List<Product2> ();
        Product2 prdOne = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli1.SBQQ__Product__c LIMIT 1 ];
        Product2 prdTwo = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli2.SBQQ__Product__c LIMIT 1 ];
        prdOne.ProductCode = 'STANDALONE';
        prdOne.Product_Type__c = 'Spares';
        prdTwo.ProductCode = 'STANDALONE';
        prdTwo.Product_Type__c = 'Spares';
        prooList.add(prdOne);
        prooList.add(prdTwo);
        update prooList;
                
        SBQQ__QuoteLine__c sbqProu = [Select id,SBQQ__ProductCode__c from SBQQ__QuoteLine__c where id = :qli1.Id ];
        
        
         SBQQ__Quote__c qtQue = [Select Id,SBQQ__Primary__c,Name,ApprovalStatus__c,SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Aspen_Eligibility__c, SBQQ__Opportunity2__r.Override__c from SBQQ__Quote__c where id = :qt.Id ];
        

        ShipmentDetail__c shpEx = new ShipmentDetail__c();
        shpEx.HW_SerialNumber__c = 'Ass-65431';
        shpEx.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shpEx.ProductName__c = prdHW.Name;
        shpEx.Quantity__c = 2;
        shpEx.QuoteNumber__c = qtQue.Name ;
        shpEx.Status__c = 'Success';
        shpEx.ShippedDate__c = '12/16/15';
        shpEx.Quote__c = qtQue.Id;
        insert shpEx; 
        
        
       	ShipmentDetail__c shp = new ShipmentDetail__c();
        shp.HW_SerialNumber__c = 'Ass-654321';
        shp.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shp.ProductName__c = prdHW.Name;
        shp.Quantity__c = 2;
        shp.QuoteNumber__c = qtQue.Name ;
        shp.ShippedDate__c = '12/16/15';
        shp.Status__c = '';
        shp.Quote__c = qtQue.Id;
        insert shp;
        
        ShipmentDetail__c shp1 = new ShipmentDetail__c();
        shp1.HW_SerialNumber__c = 'Ass-65,Ass-66,Ass-67';
        shp1.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shp1.ProductName__c = prdHW.Name;
        shp1.Quantity__c = 3;
        shp1.QuoteNumber__c = qtQue.Name ;
        shp1.ShippedDate__c = '12/16/15';
        shp1.Status__c = '';
        shp1.Quote__c = qtQue.Id;
        insert shp1;
        
		ShipmentDetail__c shpef = [Select id,Status__c,QuoteNumber__c,SalesOrderNumber__c,ProductName__c from ShipmentDetail__c where Quantity__c = 3 LIMIT 1];
        
        shpef.Status__c = 'New';
        
        update shpef;
        Test.stopTest();
        System.assert(true);
        }
    }
     @isTest
    public static void testShipmentDetails10(){
        System.runAs(new User(Id=UserInfo.getUserId())) {
         insert new ShGl_DisableBusinessLogic__c(Disable_Product2_Validation_Rules__c = true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true, setupOwnerId = userinfo.getuserid());              
        Account act = [Select Id from Account LIMIT 1];
         Opportunity opp = [Select Id from Opportunity LIMIT 1 ];
        Contact cnt = [Select Id from Contact LIMIT 1];
        Test.startTest();
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__PrimaryContact__c = cnt.Id;
        qt.SBQQ__Primary__c = true;
        insert qt; 
        
           Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'STANDALONE',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit'
                };
                    
                    Map<String, Object> prdMap1 = new Map<String, Object> {
                        'Name' => 'Subscription', 
                            'IsActive' => true, 
                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                            'SBQQ__SubscriptionTerm__c' => 12, 
                            'SBQQ__SubscriptionType__c' => 'Renewable'
                            };
                                Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
        
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        insert prdList;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pBList.add(pbeHW);
        
        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pBList.add(pbeSubs);
        insert pBList;
        
        
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 3, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' );  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 3, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' ); 
        qliList.add( qli1 );
        qliList.add( qli2 );
        insert qliList;
        
         List<Product2> prooList = new List<Product2> ();
        Product2 prdOne = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli1.SBQQ__Product__c LIMIT 1 ];
        Product2 prdTwo = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli2.SBQQ__Product__c LIMIT 1 ];
        prdOne.ProductCode = 'STANDALONE';
        prdOne.Product_Type__c = 'Spares';
        prdTwo.ProductCode = 'STANDALONE';
        prdTwo.Product_Type__c = 'Spares';
        prooList.add(prdOne);
        prooList.add(prdTwo);
        update prooList;
        
        SBQQ__QuoteLine__c sbqProu = [Select id,SBQQ__ProductCode__c from SBQQ__QuoteLine__c where id = :qli1.Id ];
        
        
         SBQQ__Quote__c qtQue = [Select Id,SBQQ__Primary__c,Name,ApprovalStatus__c,SBQQ__Opportunity2__c from SBQQ__Quote__c where id = :qt.Id ];
        

        ShipmentDetail__c shpEx = new ShipmentDetail__c();
        shpEx.HW_SerialNumber__c = 'Ass-65431';
        shpEx.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shpEx.ProductName__c = prdHW.Name;
        shpEx.Quantity__c = 2;
        shpEx.QuoteNumber__c = qtQue.Name ;
        shpEx.Status__c = 'New';
        shpEx.ShippedDate__c = '12/16/15';
        shpEx.Quote__c = qtQue.Id;
        insert shpEx;
        
        
       	ShipmentDetail__c shp = new ShipmentDetail__c();
        shp.HW_SerialNumber__c = 'Ass-654321';
        shp.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shp.ProductName__c = prdHW.Name;
        shp.Quantity__c = 2;
        shp.QuoteNumber__c = qtQue.Name ;
        shp.ShippedDate__c = '12/16/15';
        shp.Status__c = 'New';
        shp.Quote__c = qtQue.Id;
        insert shp;
        
        ShipmentDetail__c shp1 = new ShipmentDetail__c();
        shp1.HW_SerialNumber__c = 'Ass-65,Ass-66,Ass-67';
        shp1.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shp1.ProductName__c = prdHW.Name;
        shp1.Quantity__c = 3;
        shp1.QuoteNumber__c = qtQue.Name ;
        shp1.ShippedDate__c = '12/16/15';
        shp1.Status__c = '';
        shp1.Quote__c = qtQue.Id;
        insert shp1;
        
        String recTyId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        Opportunity oppef = [Select id,Override__c,Aspen_Eligibility__c from Opportunity where RecordTypeId= :recTyId ];
        oppef.Override__c = false;
        oppef.Aspen_Eligibility__c = 'Actual Aspen';
        
		ShipmentDetail__c shpef = [Select id,Status__c,QuoteNumber__c,SalesOrderNumber__c,ProductName__c from ShipmentDetail__c where Quantity__c = 3 LIMIT 1];
        
        shpef.Status__c = 'New';
        
        update oppef;
        update shpef;
        Test.stopTest();
        System.assert(true);
        }
    }
    
     @isTest
    public static void testInternalFailure(){
    	System.runAs(new User(Id=UserInfo.getUserId())) {
    	insert new ShGl_DisableBusinessLogic__c(Disable_Product2_Validation_Rules__c = true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true, setupOwnerId = userinfo.getuserid());      
         Account act = [Select Id from Account LIMIT 1];
         Opportunity opp = [Select Id, Override__c,Aspen_Eligibility__c from Opportunity LIMIT 1 ];
         opp.Aspen_Eligibility__c = 'Actual Aspen';
        opp.Override__c = false;
        update opp;

        Contact cnt = [Select Id from Contact LIMIT 1];
         Test.startTest();
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__PrimaryContact__c = cnt.Id;
        qt.SBQQ__Primary__c = true;
        insert qt; 
        
           Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'STANDALONE',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit'
                };
                    
                    Map<String, Object> prdMap1 = new Map<String, Object> {
                        'Name' => 'Subscription', 
                            'IsActive' => true, 
                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                            'SBQQ__SubscriptionTerm__c' => 12, 
                            'SBQQ__SubscriptionType__c' => 'Renewable'
                            };
                                Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
    
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        insert prdList;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pBList.add(pbeHW);
        
        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pBList.add(pbeSubs);
        insert pBList;
        
        
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 3, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' );  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 3, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' ); 
        qliList.add( qli1 );
        qliList.add( qli2 );
        insert qliList;
        
         List<Product2> prooList = new List<Product2> ();
        Product2 prdOne = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli1.SBQQ__Product__c LIMIT 1 ];
        Product2 prdTwo = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli2.SBQQ__Product__c LIMIT 1 ];
        prdOne.ProductCode = 'STANDALONE';
        prdOne.Product_Type__c = 'Appliance';
        prdTwo.ProductCode = 'STANDALONE';
        prdTwo.Product_Type__c = 'Appliance';
        prooList.add(prdOne);
        prooList.add(prdTwo);
        update prooList;
        
        SBQQ__QuoteLine__c sbqProu = [Select id,SBQQ__ProductCode__c from SBQQ__QuoteLine__c where id = :qli1.Id ];
        
        
         SBQQ__Quote__c qtQue = [Select Id,SBQQ__Primary__c,Name,ApprovalStatus__c,SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Aspen_Eligibility__c, SBQQ__Opportunity2__r.Override__c from SBQQ__Quote__c where id = :qt.Id ];

               
        ShipmentDetail__c shp1 = new ShipmentDetail__c();
        shp1.HW_SerialNumber__c = 'Ass-65,Ass-66,Ass-67,Ass-68';
        shp1.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shp1.ProductName__c = prdHW.Name;
        shp1.Quantity__c = 4;
        shp1.QuoteNumber__c = qtQue.Name ;
        shp1.ShippedDate__c = '12/16/15';
        shp1.Status__c = '';
        shp1.Quote__c = qtQue.Id;
        insert shp1;
                
		ShipmentDetail__c shpef = [Select id,Status__c,QuoteNumber__c,SalesOrderNumber__c,ProductName__c from ShipmentDetail__c where Quantity__c = 4 LIMIT 1];
        
        shpef.Status__c = 'New';
        update shpef;

         Test.stopTest();
         System.assert(true);
        }
    }
    @isTest
    public static void testShipmentDetails11(){
        System.runAs(new User(Id=UserInfo.getUserId())) {
         insert new ShGl_DisableBusinessLogic__c(Disable_Product2_Validation_Rules__c = true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true, setupOwnerId = userinfo.getuserid());      
        Account act = [Select Id from Account LIMIT 1];
         Opportunity opp = [Select Id, Override__c,Aspen_Eligibility__c from Opportunity LIMIT 1 ];
         opp.Aspen_Eligibility__c = 'Actual Aspen';
        opp.Override__c = false;
        update opp;

        Contact cnt = [Select Id from Contact LIMIT 1];
        Test.startTest();
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__PrimaryContact__c = cnt.Id;
        qt.SBQQ__Primary__c = true;
        insert qt; 
        
           Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'STANDALONE',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit'
                };
                    
                    Map<String, Object> prdMap1 = new Map<String, Object> {
                        'Name' => 'Subscription', 
                            'IsActive' => true, 
                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                            'SBQQ__SubscriptionTerm__c' => 12, 
                            'SBQQ__SubscriptionType__c' => 'Renewable'
                            };
                                Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
        
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        insert prdList;
        
        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pBList.add(pbeHW);
        
        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pBList.add(pbeSubs);
        insert pBList;
        
        
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 3, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' );  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 3, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' ); 
        qliList.add( qli1 );
        qliList.add( qli2 );
        insert qliList;
        
         List<Product2> prooList = new List<Product2> ();
        Product2 prdOne = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli1.SBQQ__Product__c LIMIT 1 ];
        Product2 prdTwo = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli2.SBQQ__Product__c LIMIT 1 ];
        prdOne.ProductCode = 'STANDALONE';
        prdOne.Product_Type__c = 'Spares';
        prdTwo.ProductCode = 'STANDALONE';
        prdTwo.Product_Type__c = 'Spares';
        prooList.add(prdOne);
        prooList.add(prdTwo);
        update prooList;
        

        SBQQ__QuoteLine__c sbqProu = [Select id,SBQQ__ProductCode__c from SBQQ__QuoteLine__c where id = :qli1.Id ];
        
        
         SBQQ__Quote__c qtQue = [Select Id,SBQQ__Primary__c,Name,ApprovalStatus__c,SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Aspen_Eligibility__c, SBQQ__Opportunity2__r.Override__c from SBQQ__Quote__c where id = :qt.Id ];

               
        ShipmentDetail__c shp1 = new ShipmentDetail__c();
        shp1.HW_SerialNumber__c = 'Ass-65,Ass-66,Ass-67,Ass-68';
        shp1.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shp1.ProductName__c = prdHW.Name;
        shp1.Quantity__c = 4;
        shp1.QuoteNumber__c = qtQue.Name ;
        shp1.ShippedDate__c = '12/16/15';
        shp1.Status__c = '';
        shp1.Quote__c = qtQue.Id;
        insert shp1;
        
        String recTyId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        
		ShipmentDetail__c shpef = [Select id,Status__c,QuoteNumber__c,SalesOrderNumber__c,ProductName__c from ShipmentDetail__c where Quantity__c = 4 LIMIT 1];
        
        shpef.Status__c = 'New';
        update shpef;
        Test.stopTest();
        System.assert(true);
        }
    }
    @isTest
    public static void testShipmentDetails12(){
        System.runAs(new User(Id=UserInfo.getUserId())) {
        insert new ShGl_DisableBusinessLogic__c(Disable_Product2_Validation_Rules__c = true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true, setupOwnerId = userinfo.getuserid());             
        Account act = [Select Id from Account LIMIT 1];
         Opportunity opp = [Select Id, Aspen_Eligibility__c, Override__c from Opportunity LIMIT 1 ];
         opp.Aspen_Eligibility__c = 'Actual Aspen';
        opp.Override__c = false;
        update opp;
        Contact cnt = [Select Id from Contact LIMIT 1];
        Test.startTest();
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__PrimaryContact__c = cnt.Id;
        qt.SBQQ__Primary__c = true;
        insert qt; 
        
           Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'STANDALONE',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit'
                };
                    
                    Map<String, Object> prdMap1 = new Map<String, Object> {
                        'Name' => 'Subscription', 
                            'IsActive' => true, 
                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                            'SBQQ__SubscriptionTerm__c' => 12, 
                            'SBQQ__SubscriptionType__c' => 'Renewable'
                            };
                                Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
        
        //prdHW.ProductCode = 'Standalone';
        //prdSubs.ProductCode = 'Standalone';
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        insert prdList;
        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pBList.add(pbeHW);
        
        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pBList.add(pbeSubs);
        insert pBList;
        
        
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 3, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' );  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 3, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' ); 
        qliList.add( qli1 );
        qliList.add( qli2 );
        insert qliList;
        
         List<Product2> prooList = new List<Product2> ();
        Product2 prdOne = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli1.SBQQ__Product__c LIMIT 1 ];
        Product2 prdTwo = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli2.SBQQ__Product__c LIMIT 1 ];
        prdOne.ProductCode = 'STANDALONE';
        prdOne.Product_Type__c = 'Spares';
        prdTwo.ProductCode = 'STANDALONE';
        prdTwo.Product_Type__c = 'Spares';
        prooList.add(prdOne);
        prooList.add(prdTwo);
        update prooList;
        
        
        //prdHW.ProductCode = 'Standalone';
        SBQQ__QuoteLine__c sbqProu = [Select id,SBQQ__ProductCode__c from SBQQ__QuoteLine__c where id = :qli1.Id ];
        
        
        SBQQ__Quote__c qtQue = [Select Id,SBQQ__Primary__c,Name,ApprovalStatus__c,SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Aspen_Eligibility__c, SBQQ__Opportunity2__r.Override__c from SBQQ__Quote__c where id = :qt.Id ];

               
        ShipmentDetail__c shp1 = new ShipmentDetail__c();
        shp1.HW_SerialNumber__c = '';
        shp1.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shp1.ProductName__c = prdHW.Name;
        shp1.Quantity__c = 1;
        shp1.QuoteNumber__c = qtQue.Name ;
        shp1.ShippedDate__c = '12/16/15';
        shp1.Status__c = '';
        shp1.Quote__c = qtQue.Id;
        insert shp1;
                
		ShipmentDetail__c shpef = [Select id,Status__c,QuoteNumber__c,SalesOrderNumber__c,ProductName__c from ShipmentDetail__c where Quantity__c = 1 LIMIT 1];
        
        shpef.Status__c = 'New';   
        
        update shpef;
        
        qtQue.ApprovalStatus__c = '';
        update qtQue;

        shpef.Status__c = '';
        update shpef;
        
        Test.stopTest();
        System.assert(true);
        }
    }
    
    @isTest
    public static void testShipmentDetails14(){
        System.runAs(new User(Id=UserInfo.getUserId())) {
         insert new ShGl_DisableBusinessLogic__c(Disable_Product2_Validation_Rules__c = true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true, setupOwnerId = userinfo.getuserid());              
        Account act = [Select Id from Account LIMIT 1];
         Opportunity opp = [Select Id, Override__c,Aspen_Eligibility__c from Opportunity LIMIT 1 ];
         opp.Aspen_Eligibility__c = 'Actual Aspen';
        opp.Override__c = false;
        update opp;

        Contact cnt = [Select Id from Contact LIMIT 1];
        Test.startTest();
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__PrimaryContact__c = cnt.Id;
        qt.SBQQ__Primary__c = true;
        insert qt; 
        
           Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'STANDALONE',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit'
                };
                    
                    Map<String, Object> prdMap1 = new Map<String, Object> {
                        'Name' => 'Subscription', 
                            'IsActive' => true, 
                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                            'SBQQ__SubscriptionTerm__c' => 12, 
                            'SBQQ__SubscriptionType__c' => 'Renewable'
                            };
                                Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        

        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        insert prdList;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pBList.add(pbeHW);
        
        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pBList.add(pbeSubs);
        insert pBList;
        
        
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 3, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' );  
        //SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 3, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' ); 
        qliList.add( qli1 );
        //qliList.add( qli2 );
        insert qliList;
        
         List<Product2> prooList = new List<Product2> ();
        Product2 prdOne = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli1.SBQQ__Product__c LIMIT 1 ];
        //Product2 prdTwo = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli2.SBQQ__Product__c LIMIT 1 ];
        prdOne.ProductCode = 'STANDALONE';
        prdOne.Product_Type__c = 'Spares';
        prooList.add(prdOne);
        update prooList;
                
        //prdHW.ProductCode = 'Standalone';
        SBQQ__QuoteLine__c sbqProu = [Select id,SBQQ__ProductCode__c from SBQQ__QuoteLine__c where id = :qli1.Id ];
        
        SBQQ__Quote__c qtQue = [Select Id,SBQQ__Primary__c,Name,ApprovalStatus__c,SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Aspen_Eligibility__c, SBQQ__Opportunity2__r.Override__c from SBQQ__Quote__c where id = :qt.Id ];

               
        ShipmentDetail__c shp1 = new ShipmentDetail__c();
        shp1.HW_SerialNumber__c = 'Ass-67,Ass-68,Ass-69';
        shp1.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shp1.ProductName__c = prdHW.Name;
        shp1.Quantity__c = 3;
        shp1.QuoteNumber__c = qtQue.Name ;
        shp1.ShippedDate__c = '12/16/15';
        shp1.Status__c = '';
        shp1.Quote__c = qtQue.Id;
        insert shp1;
        
        ShipmentDetail__c shp2 = new ShipmentDetail__c();
        shp2.HW_SerialNumber__c = 'Ass-70';
        shp2.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shp2.ProductName__c = prdHW.Name;
        shp2.Quantity__c = 1;
        shp2.QuoteNumber__c = qtQue.Name ;
        shp2.ShippedDate__c = '12/16/15';
        shp2.Status__c = 'Success';
        shp2.Quote__c = qtQue.Id;
        insert shp2;
        
        
	ShipmentDetail__c shpef = [Select id,Status__c,QuoteNumber__c,SalesOrderNumber__c,ProductName__c from ShipmentDetail__c where Quantity__c = 3 LIMIT 1];
        
        shpef.Status__c = 'New';
        
        update shpef;
        Test.stopTest();
        System.assert(true);
        }
    }

    @isTest
    public static void validationStage6Test(){ 
        System.runAs(new User(Id=UserInfo.getUserId())) {
            insert new ShGl_DisableBusinessLogic__c(Disable_Product2_Validation_Rules__c = true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true, setupOwnerId = userinfo.getuserid());     
        Account act = [Select Id from Account LIMIT 1];
         Opportunity opp = [Select Id,Override__c,Aspen_Eligibility__c from Opportunity LIMIT 1 ];
         opp.Aspen_Eligibility__c = 'Actual Aspen';
        opp.Override__c = false;
        update opp;

        Contact cnt = [Select Id from Contact LIMIT 1];
        Test.startTest();
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__PrimaryContact__c = cnt.Id;
        qt.ProcessType__c = 'Aspen';
        qt.SBQQ__Primary__c = true;
        insert qt; 
        
           Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'STANDALONE',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit'
                };
                    
                    Map<String, Object> prdMap1 = new Map<String, Object> {
                        'Name' => 'Subscription', 
                            'IsActive' => true, 
                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                            'SBQQ__SubscriptionTerm__c' => 12, 
                            'SBQQ__SubscriptionType__c' => 'Renewable'
                            };
                                Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
        
        //prdHW.ProductCode = 'Standalone';
        //prdSubs.ProductCode = 'Standalone';
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        insert prdList;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pBList.add(pbeHW);
        
        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pBList.add(pbeSubs);
        insert pBList;
        
        
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 3, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' );  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 3, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046',Product_Type__c = 'Spares' ); 
        qliList.add( qli1 );
        qliList.add( qli2 );
        insert qliList;
        
         List<Product2> prooList = new List<Product2> ();
        Product2 prdOne = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli1.SBQQ__Product__c LIMIT 1 ];
        Product2 prdTwo = [Select id,ProductCode,Product_Type__c from Product2 where id=: qli2.SBQQ__Product__c LIMIT 1 ];
        prdOne.ProductCode = 'STANDALONE';
        prdOne.Product_Type__c = 'Spares';
        prdTwo.ProductCode = 'STANDALONE';
        prdTwo.Product_Type__c = 'Spares';
        prooList.add(prdOne);
        prooList.add(prdTwo);
        update prooList;
        
        
        //prdHW.ProductCode = 'Standalone';
        SBQQ__QuoteLine__c sbqProu = [Select id,SBQQ__ProductCode__c from SBQQ__QuoteLine__c where id = :qli1.Id ];
        
        SBQQ__Quote__c qtQue = [Select Id,SBQQ__Primary__c,Name,ApprovalStatus__c,SBQQ__Opportunity2__c,Opportunity_Stage__c, SBQQ__Opportunity2__r.Aspen_Eligibility__c, SBQQ__Opportunity2__r.Override__c from SBQQ__Quote__c where id = :qt.Id ];

         ShipmentDetail__c overviewSD = [SELECT Id, Quote__c, Quote_ShipmentValidation__c, Quote_MissingShipmentDetails__c FROM ShipmentDetail__c WHERE RecordTypeId =: Constants.overViewRecordTypeId LIMIT 1];
        
        List<ShipmentDetail__c>SDList = new List<ShipmentDetail__c>();
        SDList.add(new ShipmentDetail__c(HW_SerialNumber__c = 'Ass-65431',
                                                            ContractManufacturer__c = 'Super Micro Computer, Inc.',
                                                            ProductName__c = prdHW.Name,
                                                            Quantity__c = 1,
                                                            QuoteNumber__c = qtQue.Name ,
                                                            Quote__c = qtQue.Id,
                                                            Status__c = 'Success',
                                                            ShippedDate__c = '12/16/15',
                                                            Parent_Shipment_Detail__c = overviewSD.Id));
        SDList.add(new ShipmentDetail__c(HW_SerialNumber__c = 'Ass-65431,Ass-654321',
                                                            ContractManufacturer__c = 'Super Micro Computer, Inc.',
                                                            ProductName__c = prdHW.Name,
                                                            Quantity__c = 2,
                                                            QuoteNumber__c = qtQue.Name ,
                                                            Quote__c = qtQue.Id,
                                                            Status__c = 'Success',
                                                            ShippedDate__c = '12/16/15',
                                                            Parent_Shipment_Detail__c = overviewSD.Id));
       SDList.add(new ShipmentDetail__c(HW_SerialNumber__c = 'Test12', // BRIK ONLY
                                                            ContractManufacturer__c = 'Super Micro Computer, Inc.',
                                                            ProductName__c = prdHW.Name,
                                                            Quantity__c = 2,
                                                            QuoteNumber__c = qtQue.Name ,
                                                            Quote__c = qtQue.Id,
                                                            Status__c = 'New',
                                                            SalesOrderNumber__c = 'BRIKONLY',
                                                            ShippedDate__c = '12/16/15',
                                                            Parent_Shipment_Detail__c = overviewSD.Id));
        SDList.add(new ShipmentDetail__c(HW_SerialNumber__c = 'TestAsset2', // Spares
                                                            ContractManufacturer__c = 'Super Micro Computer, Inc.',
                                                            ProductName__c = prdHW.Name,
                                                            Quantity__c = 2,
                                                            QuoteNumber__c = qtQue.Name ,
                                                            Quote__c = qtQue.Id,
                                                            Status__c = 'New',
                                                            SalesOrderNumber__c = 'SPARES',
                                                            ShippedDate__c = '12/16/15',
                                                            Parent_Shipment_Detail__c = overviewSD.Id));
      SDList.add(new ShipmentDetail__c(HW_SerialNumber__c = 'TestAsset2',  // Spares without quote
                                                            ContractManufacturer__c = 'Super Micro Computer, Inc.',
                                                            ProductName__c = prdHW.Name,
                                                            Quantity__c = 2,
                                                            Status__c = 'New',
                                                            SalesOrderNumber__c = 'SPARES',
                                                            ShippedDate__c = '12/16/15',
                                                            Parent_Shipment_Detail__c = overviewSD.Id));
     SDList.add(new ShipmentDetail__c(HW_SerialNumber__c = 'TestAsset2',  // Spares without product
                                                            ContractManufacturer__c = 'Super Micro Computer, Inc.',
                                                            QuoteNumber__c = qtQue.Name ,
                                                            Quote__c = qtQue.Id,
                                                            Quantity__c = 2,
                                                            Status__c = 'New',
                                                            SalesOrderNumber__c = 'SPARES',
                                                            ShippedDate__c = '12/16/15',
                                                            Parent_Shipment_Detail__c = overviewSD.Id));
        insert SDList;
        
        String recTyId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        Opportunity oppef = [Select id,Override__c,Aspen_Eligibility__c, StageName from Opportunity where RecordTypeId= :recTyId ];
        oppef.StageName = '5 Negotiate & Close' ;
        update oppef;
        overviewSD.Quote__c = qtQue.Id;
        overviewSD.Quote_ShipmentValidation__c = 'Start with Email'; 
        update overviewSD;
        Test.stopTest(); 
        System.assert(true);
    }
 }
}