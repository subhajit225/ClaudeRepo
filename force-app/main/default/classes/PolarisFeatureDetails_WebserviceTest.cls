@istest
public class PolarisFeatureDetails_WebserviceTest { 
    @testSetup static void createTestData() {
        
        List<TriggerControl__c> controller = new List<TriggerControl__c>();
        controller.add(new TriggerControl__c(Name = 'Opportunity', DisableTrigger__c = true));
        //controller.add( new TriggerControl__c(Name = 'Entitlement',DisableTrigger__c = true));
        controller.add( new TriggerControl__c(Name = 'Order',DisableTrigger__c = true));
        controller.add( new TriggerControl__c(Name = 'PortalUserCreation',DisableTrigger__c = true));
        controller.add( new TriggerControl__c(Name = 'ServiceContract',DisableTrigger__c = true));
        controller.add( new TriggerControl__c(Name = 'User',DisableTrigger__c = true));
        
        insert controller; 
        
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance(); 
        disableFuncCS.Disable_Order_Old_Trigger__c = true;
        insert disableFuncCS;
        
        insert new ShGl_DisableBusinessLogic__c(
            Disable_SBQQ_Quote_Triggers__c = true,
            Disable_SBQQ_QuoteLine_Triggers__c = true,
            Disable_Opportunity_Triggers__c = true,
            Disable_Order_Email_Alerts__c = false,
            Disable_Order_Triggers__c = true,
            Disable_Opportunity_Validation_Rules__c = true,
            Disable_SBQQ_Quote_Validation_Rules__c = True,
            Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
            Disable_ServiceContract_Trigger__c = true,
            Disable_Order_Validation_Rules__c = True
        );
        
        StateNameCode__c custset = new StateNameCode__c();
        custset.Name = 'California';
        custset.Code__c = 'US-CA';
        insert custset;
        
        Date closeDt = System.Today()+30;
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        List<Account> acctList = new List<Account>();
        Account acct = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert acct;
        acctList.add(acct);
        
        Account acct1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        //acct1.name = 'Test';
        //acctList.add(acct1);
        insert acct1;
        Map<String, Object> entMap = new Map<String, Object> {
            'Accountid' => acct.Id
                };
                    TriggerControl__c trgCnt = new TriggerControl__c(Name = 'Entitlement', DisableTrigger__c = false);
        insert trgCnt;
        
        Test.startTest();
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => acct.Id,
                'Email'  =>'leademail@hidden.com'
                };
                    Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap); 
        
        insert cnt1;
        
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => acct.Id,
                'Initial_Contacts_Name__c' => cnt1.Id,
                'Primary_Competitor__c' => 'Other',
                'Other_Primary_Competitor__c' => 'Other',
                'StageName' => '1 Discovery',
                'Other_Competitor_Field__c' => 'Other',
                'ForecastCategoryName' => 'Best Case'
                };
                    Opportunity oppty = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        //oppty.Deal_Type__c = 'Software Only';
        insert oppty;
        
        
        list<Product2> prodlist = new list<Product2>();
        Map<String, Object>  prodMap = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'POLARIS',
                'Category__c' => 'NFR',
                'Product_Type__c' => 'Appliance',
                'PDM_Feature_Enabled__c' => true
                };
                    Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);  
        pd.Asset_Priority__c = 1;
        pd.Create_Asset__c = true;
        pd.License_Type__c = 'Subscription';
        prodlist.add(pd);
        
        Map<String, Object>  prodMap2 = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'POLARIS',
                'Product_Type__c' => 'GPS',
                'Category__c' => 'Support',
                'License_Type__c' => 'Subscription',
                 'PDM_Feature_Enabled__c' => true

                };
                    Product2 pd2 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap2);
        pd2.Asset_Priority__c = 0;          
        prodlist.add(pd2);
        
        Map<String, Object>  prodMap3 = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'POLARIS',
                'Product_Type__c' => 'RADAR'
                };
                    Product2 pd3 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap3);  
        //prodlist.add(pd3);
        pd3.Asset_Priority__c = 1;
        
        insert prodlist;
        
        /*         List<Product_Feature__c> testFeatures = new List<Product_Feature__c>();

// Active Feature for Product A (within date range)
testFeatures.add(new Product_Feature__c(
Product_Name__c = prodlist[0].Id,
Product_Code__c = prodlist[0].name,
//Feature__c = 'NAS Cloud Direct',
Feature_start_date__c = Date.today().addDays(-10),
Feature_EOL__c = Date.today().addDays(10)
));
insert testFeatures;*/
        
        Map<String, Object> asstMap = new Map<String, Object> {
            'AccountId' => acct.id,
                'Product2Id' => prodlist[0].id
                };
                    
                    Asset ast = (Asset) ShGl_TestFactory.createSObject(new Asset(), asstMap);
        insert ast;
        
        
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
        insert qt1;
        
        oppty.Pricebook2Id = pricebookId;
        oppty.StageName = '4 Business Justification';
        oppty.Partner_Level_Of_Involvement__c = '1.Rubrik initiated, Partner was fulfillment only';
        oppty.SBQQ__PrimaryQuote__c = qt1.Id;
        update oppty;
        
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
        od.Type = 'POC';
        od.Order_Sub_Type__c ='Try N Buy';
        od.Est_Ship_Date__c = system.today();
        od.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId();
        od.Pricebook2Id = pricebookId;
        
        insert od;
        
        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prodlist[0].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry;
        
        PricebookEntry pbEntry1 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prodlist[1].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry1;
        
        od.Pricebook2Id = pricebookId;
        update od;
        
        List<orderItem> OIList = new List<orderItem>();
        OIList.add(new OrderItem(OrderId=od.Id, Quantity=10, PricebookEntryId=pbEntry.Id, UnitPrice = 10, Product2Id = prodlist[0].Id, SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009'));
        OIList.add(new OrderItem(OrderId=od.Id, Quantity=10, PricebookEntryId=pbEntry1.Id, UnitPrice = 10, Product2Id = prodlist[1].Id, SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009'));
        insert OIList;
        serviceContract scNew = new ServiceContract();
        scNew.Name = 'Test Contract';
        scNew.SBQQSC__Opportunity__c = oppty.Id;
        scNew.AccountId = acct1.Id;
        scNew.StartDate = System.today();
        scNew.PriceBook2Id = Test.getStandardPricebookId();
        scNew.Term = 36;
        insert scNew;
        List<Entitlement> entitlements = new List<Entitlement> {
            // new Entitlement(Name = 'ENT-1', Type = 'Phone Support', AccountId = acct.Id, StartDate = Date.valueof(System.now().addDays(-2)), EndDate = Date.valueof(System.now().addYears(2)), AssetId = assets.get(0).Id, Product__c = products.get(1).Id,Order_Service_Item__c = ordItem.id),
            // new Entitlement(Name = 'ENT-2', Type = 'Phone Support', AccountId = acct.Id, StartDate = Date.valueof(System.now().addDays(-2)), EndDate = Date.valueof(System.now().addYears(2)), AssetId = assets.get(1).Id, Product__c = products.get(1).Id,Order_Service_Item__c = ordItem.id),
            new Entitlement(ServiceContractId = scNew.Id, Name = 'ENT-3', Type = 'Phone Support', AccountId = acct1.Id, StartDate = Date.valueof(System.now().addDays(-2)), EndDate = Date.valueof(System.now().addYears(2)), Product__c = prodlist[0].Id,Order_Service_Item__c = OIList[0].id),
                new Entitlement(ServiceContractId = scNew.Id,Name = 'ENT-4', Type = 'Phone Support', AccountId = acct1.Id, StartDate = Date.valueof(System.now().addDays(-2)), EndDate = Date.valueof(System.now().addYears(2)), Product__c = prodlist[1].Id, Order_Service_Item__c = OIList[1].id)
                };
                    
                    insert entitlements;
        
        Test.stopTest();
    }
    
    static testMethod void  testfeatureDetailAPI(){
        String uniqueUserName = 'AdminUser12' + DateTime.now().getTime() + '@rubrik.com';
        Profile p = [SELECT Id FROM Profile WHERE Name = 'API Integration User'];
        User u = new User(
            Alias = 'adminU',
            Email = 'AdminUser@rubrik.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUserName
        );
        
        System.runAs(u) {
            
            Order ord = [select Id, AccountId,Account.Name,Account.Region__c ,Ship_to_Email__c ,Order_Status__c , Polaris_GPS_Region__c, Polaris_Fulfillment_Status__c,(select id from orderItems)  from Order LIMIT 1];               
            system.debug(LoggingLevel.DEBUG,'CP ord'+ord.orderItems);
            Test.startTest();
            List<product2> productList = [Select Id,name,PDM_Feature_Enabled__c from product2 where PDM_Feature_Enabled__c = true];
            List<Product_Feature__c> testFeatures = new List<Product_Feature__c>();
            
            // Active Feature for Product A (within date range)
            testFeatures.add(new Product_Feature__c(
                Product_Name__c = productList[0].Id,
                Product_Code__c = productList[0].name,
                Feature__c = 'NAS Cloud Direct',
                Feature_start_date__c = Date.today().addDays(-10),
                Feature_EOL__c = Date.today().addDays(10)
            ));
            testFeatures.add(new Product_Feature__c(
                Product_Name__c = productList[1].Id,
                Product_Code__c = productList[1].name,
                Feature__c = 'DSPM CUSTOMER HOSTED UCL',
                Feature_start_date__c = Date.today().addDays(-10),
                Feature_EOL__c = Date.today().addDays(10)
            ));

            insert testFeatures;
            
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            
            req.requestURI = '/services/apexrest/polaris/getFeatureDetails'; 
            req.httpMethod = 'GET';
            req.addHeader('Content-Type', 'application/json');
            req.addHeader('accountid',ord.AccountId); 
            req.addHeader('featuretype', 'Try N Buy'); 
            req.addHeader('fieldset', 'Description'); 
            RestContext.request = req;
            RestContext.response = res;
            PolarisFeatureDetails_Webservice.fetchFeatureDetails();
            system.assert(res != null);
            
            //error case
            req = new RestRequest();
            req.requestURI = '/services/apexrest/polaris/getFeatureDetails'; 
            req.httpMethod = 'GET';
            req.addHeader('Content-Type', 'application/json');
            req.addHeader('accountid',ord.AccountId); 
            req.addHeader('fieldset', 'wrongField');
            req.addHeader('featuretype', 'POC'); 
            RestContext.request = req;
            RestContext.response = res;
            PolarisFeatureDetails_Webservice.fetchFeatureDetails(); 
            
            // Required field missing 
            req = new RestRequest();
            req.requestURI = '/services/apexrest/polaris/getFeatureDetails'; 
            req.httpMethod = 'GET';
            req.addHeader('Content-Type', 'application/json');
            req.addHeader('fieldset', 'wrongField');
            req.addHeader('featuretype', 'POC'); 
            RestContext.request = req;
            RestContext.response = res;
            PolarisFeatureDetails_Webservice.fetchFeatureDetails(); 
            
            Test.stopTest();
        }
        
    }
    
    
    static testMethod void  testfeatureDetailAPI2(){
        system.runAs(new User(Id = UserInfo.getUserId())){
            Entitlement ett = [Select Id,AccountId from entitlement LIMIT 1];
            Test.startTest();
            
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            
            req.requestURI = '/services/apexrest/polaris/getFeatureDetails'; 
            req.httpMethod = 'GET';
            req.addHeader('Content-Type', 'application/json');
            req.addHeader('accountid',ett.AccountId); 
            req.addHeader('featuretype', 'Try N Buy'); 
            req.addHeader('fieldset', 'Description'); 
            RestContext.request = req;
            RestContext.response = res;
            PolarisFeatureDetails_Webservice.fetchFeatureDetails();
            system.assert(res != null);
        }
    }
    
    static testMethod void  testfeatureDetailAPIRSC(){
        system.runAs(new User(Id = UserInfo.getUserId())){
            Entitlement ett = [Select Id,AccountId from entitlement LIMIT 1];
            Test.startTest();
            RSCInstance__c rsci = new RSCInstance__c();
            rsci.AccountId__c = ett.AccountId;
            rsci.RSCUrl__c = 'test.com';
            rsci.RSCAccountType__c = 'Revenue';
            rsci.RSCAccountRelationship__c = 'Primary';
            rsci.Status__c = 'Active';
            insert rsci;
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            
            req.requestURI = '/services/apexrest/polaris/getFeatureDetails'; 
            req.httpMethod = 'GET';
            req.addHeader('Content-Type', 'application/json');
            req.addHeader('rscinstanceid',rsci.Id); 
            req.addHeader('featuretype', 'Try N Buy'); 
            req.addHeader('fieldset', 'Description'); 
            RestContext.request = req;
            RestContext.response = res;
            PolarisFeatureDetails_Webservice.fetchFeatureDetails();
            system.assert(res != null);
            
            res = new RestResponse();
            req.requestURI = '/services/apexrest/polaris/getFeatureDetails'; 
            req.httpMethod = 'GET';
            req.addHeader('Content-Type', 'application/json');
            req.addHeader('rscinstanceid',rsci.Id); 
            req.addHeader('featuretype', 'Revenue'); 
            req.addHeader('fieldset', 'Description'); 
            RestContext.request = req;
            RestContext.response = res;
            PolarisFeatureDetails_Webservice.fetchFeatureDetails();
            
            res = new RestResponse();
            req.requestURI = '/services/apexrest/polaris/getFeatureDetails'; 
            req.httpMethod = 'GET';
            req.addHeader('Content-Type', 'application/json');
            req.addHeader('rscinstanceid',ett.AccountId); 
            req.addHeader('featuretype', 'Try N Buy'); 
            req.addHeader('fieldset', 'Description'); 
            RestContext.request = req;
            RestContext.response = res;
            PolarisFeatureDetails_Webservice.fetchFeatureDetails();
        }
    }
    
}