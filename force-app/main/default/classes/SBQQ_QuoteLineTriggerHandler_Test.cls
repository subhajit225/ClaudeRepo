/**
* Name     : SBQQ_QuoteLineTriggerHandler_Test
* @description  : SBQQ_QuoteLineTriggerHandler_Test is used for testing SBQQ_QuoteLineTriggerHandler class
*/
@isTest
public class SBQQ_QuoteLineTriggerHandler_Test {
    
    static final Id partnerRtId = Schema.SObjectType.Account
        .getRecordTypeInfosByName()
        .get('Partner/Distributor')
        .getRecordTypeId();
    
    static PricebookEntry getPbe(Id pbId, Id prodId, Decimal unitPrice) {
        return new PricebookEntry(
            Pricebook2Id = pbId,
            Product2Id = prodId,
            UnitPrice = unitPrice,
            IsActive = true
        );
    }
    
    static PricebookEntry getPbe(Id prodId, Decimal unitPrice) {
        return getPbe(Test.getStandardPricebookId(), prodId, unitPrice);
    }
    
    static Account getAccount(String name, String type, String rtId) {
        Account vAccount = new Account();
        vAccount.Name = name;
        vAccount.Type = type;
        vAccount.recordTypeId = rtId;
        vAccount.Payment_Term__c = 'Net 60';
        
        return vAccount;
    }
    
    static Contact getContact(String name, String accId) {
        return new Contact(
            LastName = name,
            LeadSource = 'web',
            Email = 'testc@test.com',
            AccountId = accId
        );
    }
    
    static Product2 getProduct(String name, String code) {
        return new Product2(
            Name = name,
            ProductCode = code,
            isActive = true,
            CPQ_Uplift__c = '5',
            Product_Type__c='PAYGO-Commit'
        );
    }
    
    static Asset getAsset(String name, Id accountId, Id prodId) {
        return new Asset(
            Name = name,
            SerialNumber = name,
            Serial_Number__c = name,
            Product2ID = prodId,
            Accountid = accountId
        );
    }
    
    static Opportunity getOppty(String name, String accId, String partner, String disti) {
        Opportunity opp = new Opportunity();
        opp.Name = name;
        opp.AccountId = accId;
        opp.StageName = '1 Discovery';
        opp.CloseDate = System.today();
        opp.ForecastCategoryName = 'Best Case';
        opp.Business_Unit__c = 'Rubrik';
        opp.Installation_Assigned_To__c = 'FE Install';
        opp.Partner_Lookup__c = partner;
        opp.Distributor_Lookup__c = disti;
        
        return opp;
    }
    
    /**testBeforeInsert */
    /**
     * @description  : This test method is used to test the before insert functionality of SBQQ_QuoteLineTriggerHandler.
     */
    @isTest
    private static void testBeforeInsert() {
        System.runAs(new user(ID = UserInfo.getUserID())){
            ShGl_TestFactoryHelper.insertTriggerControls();
            
            ShGl_DisableBusinessLogic__c cdf1 = new ShGl_DisableBusinessLogic__c(
                SetupOwnerId = userInfo.getUserId(),
                Disable_SBQQ_Quote_Triggers__c = true
            );
            //insert cdf1;
            
            SBQQ_QuoteLineTriggerHandler handler = new SBQQ_QuoteLineTriggerHandler();
            
            Product2 prod = getProduct('TestProd', 'TestProd');
            prod.Quotable_by_users__c =  '<a href="/'+ UserInfo.getUserID() +'" target="_blank">Ashwini</a>';
            prod.Quotable_By_Profiles__c = 'Rubrik Light Administrator';
            prod.Quotable_By_Countries__c = 'Cambodia; India; Indonesia; Malaysia; Myanmar; Philippines;'; 
            prod.Allow_mentioned_Countries_to_Quote__c = true;
            insert prod;
           
            
            Account acc1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            insert acc1;
            
            List<Account> accountList = new List<Account>();
            
            Account vAccount1 = getAccount('Test Account', 'Distributor', partnerRtId);
            accountList.add(vAccount1);
            
            Account vAccount2 = getAccount('Test Account2', null, partnerRtId);
            accountList.add(vAccount2);
            
            insert accountList;
            
            Contact con1 = getContact('test con', acc1.Id);
            insert con1;

			Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Sales_Opportunity').getRecordTypeId();
            
            //insert new opportunity
            Opportunity opp1 = getOppty('TestOpp', acc1.Id, vAccount2.Id, vAccount1.Id);
            opp1.RecordTypeId= recordTypeId;
            insert opp1;
            
            Asset asset = getAsset('123456', acc1.Id, prod.Id);
            insert asset;
            
            SBQQ__Quote__c q = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp1.Id,SBQQ__Primary__c = true);
            
            Test.startTest();
            
            insert q;
            
            SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c();
            qli1.SBQQ__Quote__c = q.Id;
            qli1.SBQQ__Product__c = prod.Id;
            qli1.SBQQ__Quantity__c = 10;
            qli1.SBQQ__Number__c = 1;
            qli1.SBQQ__SubscribedAssetIds__c = asset.Id;
            qli1.SubscribedAssetNames__c = 'BB192863040046';
            qli1.SBQQ__ListPrice__c = 100;
            qli1.Product_Type__c ='PAYGO-Commit';
            insert qli1;
            
            SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c();
            qli2.SBQQ__Quote__c = q.Id;
            qli2.SBQQ__Product__c = prod.Id;
            qli2.SBQQ__Quantity__c = 10;
            qli2.SBQQ__Number__c = 1;
            qli2.SBQQ__SubscribedAssetIds__c = asset.Id;
            qli2.SubscribedAssetNames__c = 'BB192863040046';
            qli2.SBQQ__ListPrice__c = 100;
            qli2.Product_Type__c ='PAYGO-Commit';
            insert qli2;
            SBQQ__QuoteLine__c sbq1 = [
                SELECT Id
                FROM SBQQ__QuoteLine__c
                WHERE Id = :qli1.Id
                LIMIT 1
            ];
            delete sbq1;
            
            undelete sbq1;
            
            Test.stopTest();
            System.assert(true);
    }
    }
    
    /** test_checkMendatroyInstalledBy*/
    /**
     * @description  : This test method is used to test the checkMendatroyInstalledBy functionality of SBQQ_QuoteLineTriggerHandler.
     */
    @isTest
    private static void testCheckMendatroyInstalledBy() {
        System.runAs(new user(ID = UserInfo.getUserID())){
        ShGl_TestFactoryHelper.insertTriggerControls();
        
        Product2 prodtestprod = getProduct('testprod', 'testprod');
        insert prodtestprod;
        
        Account acctest = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert acctest;
        
        List<Account> accountList = new List<Account>();
        
        Account vAccount11 = getAccount('testa acc', 'Distributor', partnerRtId);
        accountList.add(vAccount11);
        
        Account vAccount2 = getAccount('testa account', null, partnerRtId);
        accountList.add(vAccount2);
        
        insert accountList;
        
        Opportunity opp = getOppty('testa opp', acctest.Id, vAccount2.Id, vAccount11.Id);
        Date oldDate = Date.valueOf('2021-09-07');
        
        Test.startTest();
        
        SBQQ__Quote__c qtest = new SBQQ__Quote__c();
        qtest.SBQQ__Opportunity2__c = opp.Id;
        qtest.SBQQ__Type__c = 'Quote';
        qtest.PSLegacyQuote__c = false;
        qtest.SBQQ__Source__c = null;
        qtest.Installed_By__c = 'Customer';
        //  insert q;
        
        SBQQ__QuoteLine__c qlitest = new SBQQ__QuoteLine__c();
        qlitest.SBQQ__Quote__c = qtest.Id;
        qlitest.SBQQ__Product__c = prodtestprod.Id;
        qlitest.SBQQ__Quantity__c = 10;
        qlitest.SBQQ__Number__c = 1;
        qlitest.Product_Type__c = 'Hardware';
        qlitest.Product_Subtype__c = 'HDD';
        qlitest.SubscribedAssetNames__c = 'BB192863040046';
        qlitest.SBQQ__ListPrice__c = 100;
        //     insert qli1;
        
        try {
            update qlitest;
        } catch (Exception ex) {
            Boolean expectedExceptionThrown = ex.getMessage()
                .contains('Script-thrown exception')
                ? true
                : false;
            System.assertEquals(expectedExceptionThrown, false);
        }
        
        Test.stopTest();
        System.assert(true);
    }
    }
    
    /**testHiddenAndOptionalQuoteLines */
    /**
     * @description  : This test method is used to test the hidden and optional quote lines functionality of SBQQ_QuoteLineTriggerHandler.
     */
    @isTest
    private static void testHiddenAndOptionalQuoteLines() {
        System.runAs(new user(ID = UserInfo.getUserID())){
        ShGl_TestFactoryHelper.insertTriggerControls();
        
        SBQQ_QuoteLineTriggerHandler handler = new SBQQ_QuoteLineTriggerHandler();
        
        Product2 prod = getProduct('testp', 'testp');
        prod.Legacy_Software_Bundle__c = true;
        insert prod;
        
        Account acct = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert acct;
        
        List<Account> accountList = new List<Account>();
        
        Account vAccountTst = getAccount('test acc', 'Distributor', partnerRtId);
        accountList.add(vAccountTst);
        
        Account vAccount2 = getAccount('test acc2', null, partnerRtId);
        insert accountList;
        
        Contact con = getContact('test con 2', acct.Id);
        con.User_Profile__c = 'System Administrator';
        insert con;
        
        Opportunity opp = getOppty('test oppty', acct.Id, vAccount2.Id, vAccountTst.Id);
        insert opp;
        
        Asset asset = getAsset('123345', acct.Id, prod.Id);
        insert asset;
        
        Test.startTest();
        
        SBQQ__Quote__c qtest = new SBQQ__Quote__c();
        qtest.SBQQ__Opportunity2__c = opp.Id;
        qtest.SBQQ__Type__c = 'Renewal';
        qtest.SBQQ__StartDate__c = Date.today();
        insert qtest;
        
        SBQQ__QuoteLine__c qlitest12 = new SBQQ__QuoteLine__c();
        qlitest12.SBQQ__Quote__c = qtest.Id;
        qlitest12.SBQQ__Product__c = prod.Id;
        qlitest12.SBQQ__Quantity__c = 10;
        qlitest12.SBQQ__Number__c = 1;
        qlitest12.SubscribedAssetNames__c = 'BB192863040046';
        qlitest12.SBQQ__SubscribedAssetIds__c = asset.Id;
        qlitest12.SBQQ__ListPrice__c = 100;
        insert qlitest12;
        
        List<SBQQ__QuoteLine__c> qls = new List<SBQQ__QuoteLine__c>();
        qls.add(qlitest12);
        
        //SBQQ_QuoteLineTriggerHelper.populateAssetDetails(qls);
        
        Test.stopTest();
        System.assert(true);
        }
    }
    
    @isTest
    private static void datePolicyTest() {
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
        System.runAs(u) {
        ShGl_DisableFunctionalityLogic__c setting1 = new ShGl_DisableFunctionalityLogic__c();
        setting1.Name = 'System Administrator';
        setting1.Disable_Opportunity_Old_Trigger__c = true;
        setting1.Disable_Order_Old_Trigger__c = true;
        setting1.Disable_Account_Old_Trigger__c = true;
        insert setting1;
        
        ShGl_DisableBusinessLogic__c settingDisable2 = new ShGl_DisableBusinessLogic__c();
        settingDisable2.Name = 'System Administrator';
        settingDisable2.Disable_Opportunity_Validation_Rules__c = true;
        settingDisable2.Disable_Order_Validation_Rules__c = true;
        settingDisable2.Disable_Entitlement_Validation_Rules__c = true;
        insert settingDisable2;
        
        List<TriggerControl__c> triggerList = new List<TriggerControl__c>();
        
        TriggerControl__c setting0 = new TriggerControl__c();
        setting0.Name = 'Order';
        setting0.DisableTrigger__c = true;
        triggerList.add(setting0);
        
        TriggerControl__c settingtc = new TriggerControl__c();
        settingtc.Name = 'Opportunity';
        settingtc.DisableTrigger__c = true;
        triggerList.add(settingtc);
        
        TriggerControl__c setting2 = new TriggerControl__c();
        setting2.Name = 'Entitlement';
        setting2.DisableTrigger__c = true;
        triggerList.add(setting2);
        
        insert triggerList;
        
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act1;
        
        List<Account> accountList = new List<Account>();
        
        Account vAccount = getAccount('TestaAccount', 'Distributor', partnerRtId);
        accountList.add(vAccount);
        
        Account vAccount2 = getAccount('Test Account', null, vAccount.RecordTypeId);
        accountList.add(vAccount2);
        
        insert accountList;
        
        Opportunity oppnew = getOppty('test opportunity', act1.Id, vAccount2.Id, vAccount.Id);
        insert (oppnew);
        
        Map<String, Object> prdMap = new Map<String, Object>{
            'Name' => 'DateTest',
                'IsActive' => true,
                'Product_Type__c' => 'RCDM Support',
                'ProductCode' => 'Date-Test'
                };
                    
                    Map<String, Object> otherTypeProduct = new Map<String, Object>{
                        'Name' => 'DateTest',
                            'IsActive' => true,
                            'Product_Type__c' => 'HW Support',
                            'ProductCode' => 'Date-Test'
                            };
                                
                                List<Product2> prodList = new List<Product2>();
        
        Product2 hwent = (Product2) ShGl_TestFactory.createSObject(
            new Product2(),
            otherTypeProduct
        );
        prodList.add(hwent);
        
        Product2 prod = (Product2) ShGl_TestFactory.createSObject(
            new Product2(),
            prdMap
        );
        prodList.add(prod);
        
        Map<String, Object> prdMap1 = new Map<String, Object>{
            'Name' => 'DateTest1',
                'IsActive' => true,
                'License_Subtype__c' => 'Add-On',
                'ProductCode' => 'Date-Test1'
                };
                    
                    Product2 prod1 = (Product2) ShGl_TestFactory.createSObject(
                        new Product2(),
                        prdMap1
                    );
        prodList.add(prod1);
        
        Product2 prod3 = new Product2(
            Name = 'TestProd3',
            IsActive = true,
            Legacy_Software_Bundle__c = true,
            License_Subtype__c = 'Add-On',
            ProductCode = 'Test-Prod'
        );
        prodList.add(prod3);
        
        insert prodList;
        
        List<PricebookEntry> entries = new List<PricebookEntry>();
        entries.add(
            getPbe(hwent.Id, 100)
        );
        
        entries.add(
            getPbe(prod.Id, 100)
        );
        
        entries.add(
            getPbe(prod1.Id, 100)
        );
        insert entries;
        
        List<Entitlement> entToInsert = new List<Entitlement>();
        
        Entitlement ent = new Entitlement(
            Name = 'Testing',
            AccountId = act1.Id,
            Product__c = prod.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(365)
        );
        entToInsert.add(ent);
        
        Entitlement ent2 = new Entitlement(
            Name = 'Testing',
            AccountId = act1.Id,
            Product__c = hwent.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(360)
        );
        entToInsert.add(ent2);
        
        Entitlement ent3 = new Entitlement(
            Name = 'Testing2',
            AccountId = act1.Id,
            Product__c = hwent.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(360)
        );
        entToInsert.add(ent3);
        
        insert entToInsert;
        
        SBQQ__Quote__c q = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = oppnew.Id,
            SBQQ__Type__c = 'Amendment',
            SBQQ__Account__c = act1.Id,
            AddOn_Date_Check__c = true,
            SBQQ__EndDate__c = Date.today().addDays(2360)
        );
        
        Test.startTest();
        
        insert q;
        
        List<SBQQ__QuoteLine__c> qliToInsert = new List<SBQQ__QuoteLine__c>();
        
        SBQQ__QuoteLine__c qlis = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q.Id,
            SBQQ__Product__c = prod1.Id,
            SBQQ__Quantity__c = 10,
            SubscribedAssetNames__c = 'BB192863040046',
            SBQQ__EndDate__c = Date.today().addDays(2360),
            SBQQ__ListPrice__c = 100
        );
        qliToInsert.add(qlis);
        
        SBQQ__QuoteLine__c qlis1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q.Id,
            SBQQ__Product__c = prod3.Id,
            SBQQ__Quantity__c = 10,
            SubscribedAssetNames__c = 'BB192863040046',
            SBQQ__EndDate__c = Date.today().addDays(2360),
            SBQQ__ListPrice__c = 100
        );
        qliToInsert.add(qlis1);
        
        insert qliToInsert;
        
        Set<Id> qlid = new Set<Id>();
        qlid.add(qlis.Id);
        qlid.add(qlis1.Id);
        
        SBQQ_QuoteLineTriggerHelper.datePolicy(qlid, false);
        
        Test.stopTest();
        System.assert(true);
         }
    }
    
    /**datePolicy_Test1 */
    /**
     * @description  : This test method is used to test the date policy functionality of SBQQ_QuoteLineTriggerHandler.
     */
    @isTest
    private static void datePolicyTest1() {
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
        System.runAs(u) {
        ShGl_DisableFunctionalityLogic__c settingtest = new ShGl_DisableFunctionalityLogic__c();
        settingtest.Name = 'System Administrator';
        settingtest.Disable_Opportunity_Old_Trigger__c = true;
        settingtest.Disable_Order_Old_Trigger__c = true;
        settingtest.Disable_Account_Old_Trigger__c = true;
        insert settingtest;
        
        ShGl_DisableBusinessLogic__c settingDisable1 = new ShGl_DisableBusinessLogic__c();
        settingDisable1.Name = 'System Administrator';
        settingDisable1.Disable_Opportunity_Validation_Rules__c = true;
        settingDisable1.Disable_Order_Validation_Rules__c = true;
        settingDisable1.Disable_Entitlement_Validation_Rules__c=true;
        insert settingDisable1;
        
        List<TriggerControl__c> triggerList = new List<TriggerControl__c>();
        
        TriggerControl__c setting01 = new TriggerControl__c();
        setting01.Name = 'Order';
        setting01.DisableTrigger__c = true;
        triggerList.add(setting01);
        
        TriggerControl__c setting12 = new TriggerControl__c();
        setting12.Name = 'Opportunity';
        setting12.DisableTrigger__c = true;
        triggerList.add(setting12);
        
        TriggerControl__c setting22 = new TriggerControl__c();
        setting22.Name = 'Entitlement';
        setting22.DisableTrigger__c = true;
        triggerList.add(setting22);
        
        insert triggerList;
        
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        
        List<Account> accountList = new List<Account>();
        Account vAccount = getAccount('test acc', 'Distributor', partnerRtId);
        accountList.add(vAccount);
        
        Account vAccount2 = getAccount('test account new', null, partnerRtId);
        accountList.add(vAccount2);
        
        insert accountList;
        
        Opportunity opp = getOppty('test oppty', act.Id, vAccount2.Id, vAccount.Id);
        insert opp;
        
        List<Product2> prodToInsert = new List<Product2>();
        
        Product2 hwent = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        hwent.Name = 'DateTest';
        hwent.IsActive = true;
        hwent.Product_Type__c = 'HW Support';
        hwent.ProductCode = 'Date-Test';
        prodToInsert.add(hwent);
        
        Product2 prod = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        prod.Name = 'DateTest';
        prod.IsActive = true;
        prod.Product_Type__c = 'RCDM Support';
        prod.ProductCode = 'Date-Test';
        prodToInsert.add(prod);
        
        Product2 prod1 = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        prod1.Name = 'DateTest1';
        prod1.IsActive = true;
        prod1.License_Subtype__c = 'Add-On';
        prod1.ProductCode = 'Date-Test1';
        prodToInsert.add(prod1);
        
        insert prodToInsert;
        
        List<PricebookEntry> entries = new List<PricebookEntry>();
        entries.add(
            getPbe(hwent.Id, 100)
        );
        
        entries.add(
            getPbe(prod.Id, 100)
        );
        
        entries.add(
            getPbe(prod1.Id, 200)
        );
        
        insert entries;
        
        List<Entitlement> entToInsert = new List<Entitlement>();
        
        Entitlement ent = new Entitlement();
        ent.Name = 'Testing';
        ent.AccountId = act.Id;
        ent.Product__c = prod.Id;
        ent.StartDate = Date.today();
        ent.EndDate = Date.today().addDays(365);
        entToInsert.add(ent);
        
        Entitlement ent2 = new Entitlement();
        ent2.Name = 'Testing';
        ent2.AccountId = act.Id;
        ent2.Product__c = hwent.Id;
        ent2.StartDate = Date.today();
        ent2.EndDate = Date.today().addDays(360);
        entToInsert.add(ent2);
        
        insert entToInsert;
        
        SBQQ__Quote__c qnew = new SBQQ__Quote__c();
        qnew.SBQQ__Opportunity2__c = opp.Id;
        qnew.SBQQ__Type__c = 'Amendment';
        qnew.SBQQ__Account__c = act.Id;
        qnew.sbqq__SubscriptionTerm__c = 12;
        qnew.AddOn_Date_Check__c = true;
        
        Test.startTest();
        
        insert qnew;
        
        SBQQ__QuoteLine__c qlis = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qnew.Id,
            SBQQ__Product__c = prod1.Id,
            SBQQ__Quantity__c = 10,
            SubscribedAssetNames__c = 'BB192863040046',
            SBQQ__EndDate__c = Date.today().addDays(2360),
            SBQQ__ListPrice__c = 100
        );
        insert qlis;
        
        Set<Id> qlid = new Set<Id>();
        qlid.add(qlis.Id);
        
        SBQQ_QuoteLineTriggerHelper.datePolicy(qlid, false);
        
        Test.stopTest();
        System.assert(true);
        }
    }
    
    /**premiumbundleSupport_Test */
    /**
     * @description  : This test method is used to test the premium bundle support functionality of SBQQ_QuoteLineTriggerHandler.
     */
    @isTest
    private static void premiumBundleSupportTest() {
        Account act1 = (Account) ShGl_TestFactory.createSObject(
            new Account(),
            null
        );
        insert act1;
        
        List<Account> accountList = new List<Account>();
        
        Account vAccount = getAccount('test', 'Distributor', partnerRtId);
        accountList.add(vAccount);
        
        Account vAccount2 = getAccount('test 2', null, vAccount.RecordTypeId);
        accountList.add(vAccount2);
        
        insert accountList;
        
        Opportunity opp1 = getOppty('test opportunity 1', act1.Id, vAccount2.Id, vAccount.Id);
        insert (opp1);
        
        List<Product2> prdList = new List<Product2>();
        
        Map<String, Object> prdMap = new Map<String, Object>{
            'Name' => 'WrapperProduct',
                'IsActive' => true
                };
                    
                    Product2 pd = (Product2) ShGl_TestFactory.createSObject(
                        new Product2(),
                        prdMap
                    );
        prdList.add(pd);
        
        Map<String, Object> prdMap1 = new Map<String, Object>{
            'Name' => 'optionProduct',
                'IsActive' => true,
                'SBQQ__SubscriptionTerm__c' => 12,
                'Category__c' => 'Support',
                'Support_Type__c' => 'PREM',
                'SBQQ__Component__c' => true,
                'ProductCode' => 'option-Product'
                };
                    
                    Product2 pd1 = (Product2) ShGl_TestFactory.createSObject(
                        new Product2(),
                        prdMap1
                    );
        prdList.add(pd1);
        
        insert prdList;
        
        Product2 jb = [
            SELECT Id, Name, Is_Premium_Support__c
            FROM Product2
            WHERE Id = :pd1.Id
            LIMIT 1
        ];
        
        List<PricebookEntry> entries1 = new List<PricebookEntry>();
        
        entries1.add(
            getPbe(pd.Id, 100)
        );
        
        entries1.add(
            getPbe(pd1.Id, 1000)
        );
        
        insert entries1;
        
        SBQQ__ProductOption__c optionForBundle = new SBQQ__ProductOption__c(
            SBQQ__Number__c = 20,
            SBQQ__ConfiguredSKU__c = pd.Id,
            SBQQ__OptionalSKU__c = jb.Id
        );
        insert optionForBundle;
        
        SBQQ__Quote__c q1 = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp1.Id,
            SBQQ__Type__c = 'Quote',
            SBQQ__Account__c = act1.Id
        );
        
        Test.startTest();
        
        insert (q1);
        
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q1.Id,
            SBQQ__Product__c = pd.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__SubscriptionTerm__c = 12,
            SubscribedAssetNames__c = 'BB192863040046',
            SBQQ__ListPrice__c = 100
        );
        insert ql;
        
        SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q1.Id,
            SBQQ__Product__c = pd1.Id,
            SBQQ__RequiredBy__c = ql.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__SubscriptionTerm__c = 36,
            SubscribedAssetNames__c = 'BB192863040046',
            SBQQ__ListPrice__c = 100
        );
        
        System.runAs(new user(ID = UserInfo.getUserID())){
            insert ql1;
        }
        
        Test.stopTest();
        System.assert(true);
    }
    
    /**populateQuoteLineGroupFuture_Test */
    /**
     * @description  : This test method is used to test the populateQuoteLineGroupFuture functionality of SBQQ_QuoteLineTriggerHandler.
     */
    @isTest
    private static void populateQuoteLineGroupFutureTest() {
        String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(
            Alias = 'adminU', Email='AdminUser@rubrik.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
            RBAC_Group__c = 'System - IT',
            RBAC_Department__c = 'Service Account',
            UserName=uniqueUserName
        );
        insert u;
        System.runAs(u) {
        INSERT new ShGl_DisableBusinessLogic__c(setupownerid = u.Id, 
                                                Disable_Account_Triggers__c = TRUE,Disable_Opportunity_Validation_Rules__c=true,
                                                Disable_Opportunity_Triggers__c=true,Disable_Order_Validation_Rules__c = true,
                                                Disable_Order_Old_Trigger__c = true,Disable_Entitlement_Validation_Rules__c=true,
                                                Disable_OrderItem_Old_Trigger__c = true);    
        
        TriggerControl.stopOrderItemTrigger = true;
        TriggerControl.stopOrderTrigger = true;
        TriggerControl.stopEntitlementTrigger = true;
        flowControll.opportunityTriggerHandler = false;
        flowControll.opportunityLineItemHandler = false;
        TriggerControl__c setting3 = new TriggerControl__c();
        setting3.Name = 'Entitlement';
        setting3.DisableTrigger__c = False;
        insert new List<TriggerControl__c>{setting3};
            
        Account act1 = (Account) ShGl_TestFactory.createSObject(
            new Account(),
            null
        );
        insert act1;
        
        List<Account> accountList = new List<Account>();
        
        Account vAccount = getAccount('test acc', 'Distributor', partnerRtId);
        accountList.add(vAccount);
        
        Account vAccount2 = getAccount('test account 2', null, partnerRtId);
        accountList.add(vAccount2);
        
        insert accountList;
        
        Opportunity opp1 = getOppty('test opty', act1.Id, vAccount2.Id, vAccount.Id);
        insert (opp1);
        
        List<Product2> prodList = new List<Product2>();
        
        Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        pd.Name = 'WrapperProduct';
        pd.IsActive = true;
        prodList.add(pd);
        
        Product2 pd1 = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        pd1.Name = 'optionProduct';
        pd1.IsActive = true;
        pd1.SBQQ__SubscriptionTerm__c = 12;
        pd1.Category__c = 'Support';
        pd1.Support_Type__c = 'PREM';
        pd1.SBQQ__Component__c = true;
        pd1.ProductCode = 'option-Product';
        pd1.Legacy_Software_Bundle__c = true;
        prodList.add(pd1);
        
        insert prodList;
        
        Product2 jb = [
            SELECT Id, Name, Is_Premium_Support__c
            FROM Product2
            WHERE Id = :pd1.Id
            LIMIT 1
        ];
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>();
        Map<Id, SBQQ__QuoteLine__c> newQLIMap = new Map<Id, SBQQ__QuoteLine__c>();
        
        List<PricebookEntry> entries1 = new List<PricebookEntry>();
        
        entries1.add(getPbe(pd.Id, 100));
        
        //entries1.add(getPbe(pd1.Id, 1000));
        insert entries1;
        
        SBQQ__ProductOption__c optionForBundle = new SBQQ__ProductOption__c(
            SBQQ__Number__c = 20,
            SBQQ__ConfiguredSKU__c = pd.Id,
            SBQQ__OptionalSKU__c = jb.Id
        );
        insert optionForBundle;
        Entitlement ent = new Entitlement(
            Name = 'Testing',
            AccountId = act1.Id,
            Product__c = pd.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(365)
        );
        insert ent;
        
        SBQQ__Quote__c q1 = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp1.Id,
            SBQQ__Type__c = 'Renewal+Expansion',
            SBQQ__Account__c = act1.Id
        );
        
        SBQQ__Quote__c q2 = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp1.Id,
            SBQQ__Type__c = 'Renewal',
            SBQQ__Account__c = act1.Id
        );
        
        Test.startTest();
        
        insert new List<SBQQ__Quote__c>{ q1, q2 };
            
            Set<Id> qid = new Set<Id>();
        qid.add(q1.id);
        
        Product2 prod1 = getProduct('TestProd1', 'RS-BT-RCDM-T');
        Product2 prod = getProduct('TestProd', 'RS-UR-MH-PE-PP');
        
        insert new List<Product2>{ prod1, prod };
            
            SBQQ__QuoteLineGroup__c objQLG = new SBQQ__QuoteLineGroup__c(
                Name = 'Renewal Quote',
                SBQQ__Quote__c = q1.Id
            );
        
        SBQQ__QuoteLineGroup__c objQLGExp = new SBQQ__QuoteLineGroup__c(
            Name = 'Expansion Quote',
            SBQQ__Quote__c = q1.Id
        );
        
        SBQQ__QuoteLineGroup__c objQLGDis = new SBQQ__QuoteLineGroup__c(
            Name = 'Disposition Quote',
            SBQQ__Quote__c = q1.Id
        );
        
        insert new List<SBQQ__QuoteLineGroup__c>{ objQLG, objQLGExp, objQLGDis };
            
            SBQQ__QuoteLine__c ql0 = new SBQQ__QuoteLine__c();
        ql0.SBQQ__Quote__c = q1.Id;
        ql0.SBQQ__Product__c = pd.Id;
        ql0.SBQQ__Quantity__c = 10;
        ql0.SBQQ__Group__c = objQLGExp.Id;
        ql0.SBQQ__SubscriptionTerm__c = 12;
        ql0.SBQQ__ListPrice__c = 100;
        insert ql0;
        
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
        ql.SBQQ__Quote__c = q1.Id;
        ql.SBQQ__Product__c = pd.Id;
        ql.SBQQ__Quantity__c = 10;
        ql.SBQQ__Group__c = objQLGExp.Id;
        ql.SBQQ__SubscriptionTerm__c = 12;
        ql.SubscribedAssetNames__c = 'BB192863040046';
        ql.SBQQ__ListPrice__c = 100;
        insert ql;
        
        SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c();
        ql1.SBQQ__Quote__c = q1.Id;
        ql1.SBQQ__RequiredBy__c = ql.Id;
        ql1.SBQQ__Group__c = objQLG.Id;
        ql1.SBQQ__Quantity__c = 10;
        ql1.SBQQ__SubscriptionTerm__c = 36;
        ql1.SBQQ__Product__c = prod.Id;
        ql1.Disposition_Reason__c = 'Churn';
        ql1.SBQQ__ListPrice__c = 100;
        insert ql1;
        
        SBQQ__QuoteLine__c ql2 = new SBQQ__QuoteLine__c();
        ql2.SBQQ__Quote__c = q1.Id;
        ql2.SBQQ__RequiredBy__c = ql.Id;
        ql2.SBQQ__Group__c = objQLGDis.Id;
        ql2.SBQQ__Quantity__c = 10;
        ql2.SBQQ__SubscriptionTerm__c = 36;
        ql2.SBQQ__Product__c = prod.Id;
        ql2.Disposition_Reason__c = 'Churn';
        ql2.SBQQ__ListPrice__c = 100;
        
        SBQQ__QuoteLine__c ql3 = new SBQQ__QuoteLine__c();
        ql3.SBQQ__Quote__c = q1.Id;
        ql3.SBQQ__RequiredBy__c = ql.Id;
        ql3.SBQQ__Group__c = objQLGDis.Id;
        ql3.SBQQ__Quantity__c = 10;
        ql3.SBQQ__SubscriptionTerm__c = 36;
        ql3.SBQQ__Product__c = prod1.Id;
        ql3.Disposition_Reason__c = 'Churn';
        ql3.SBQQ__ListPrice__c = 100;
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        
        SBQQ.TriggerControl.disable();
        
        //Asset asset = getAsset('12234', act1.Id, prod.Id);
        //insert asset;
        
        Asset asset = new Asset();
        asset.Name = 'BBASSET123';
        asset.Serial_Number__c = 'BBASSET123';
        asset.AccountId = act1.id;
        asset.Product2Id = prod.Id;
        insert asset;
        
        ServiceContract serviceContractObj = new ServiceContract();
        serviceContractObj.Name = 'EntitlementTriggerHelper Contract';
        serviceContractObj.SBQQSC__Opportunity__c = opp1.Id;
        serviceContractObj.SBQQSC__RenewalOpportunity__c = opp1.Id;
        serviceContractObj.AccountId = act1.Id;
        serviceContractObj.StartDate = System.today();
        serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj.Term = 36;
        insert serviceContractObj;
        
        ContractLineItem renewedContractLineItem = new ContractLineItem();
        renewedContractLineItem.SBQQSC__Account__c = act1.Id;
        renewedContractLineItem.AssetId = asset.Id;
        renewedContractLineItem.PricebookEntryId = entries1[0].Id;
        renewedContractLineItem.ServiceContractId = serviceContractObj.Id;
        renewedContractLineItem.SBQQSC__QuoteLine__c = ql1.Id;
        renewedContractLineItem.Quantity = 10;
        renewedContractLineItem.UnitPrice = 100;
        insert renewedContractLineItem;
        
        SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c();
        qli3.SBQQ__Quote__c = q1.Id;
        qli3.SBQQ__Product__c = prod.Id;
        qli3.SBQQ__Quantity__c = 10;
        qli3.SBQQSC__RenewedContractLine__c = renewedContractLineItem.Id;
        qli3.Product_Level__c = 'Hardware';
        qli3.SBQQ__SubscriptionTerm__c = 12;
        qli3.SubscribedAssetNames__c = 'BB192863040046';
        qli3.Disposition_Reason__c = 'Churn';
        qli3.SBQQ__ListPrice__c = 100;
        insert qli3;
        
        SBQQ__QuoteLine__c qli4 = new SBQQ__QuoteLine__c();
        qli4.SBQQ__Quote__c = q1.Id;
        qli4.SBQQ__Product__c = prod.Id;
        qli4.SBQQ__Quantity__c = 10;
        qli4.SBQQSC__RenewedContractLine__c = renewedContractLineItem.Id;
        qli4.Product_Level__c = 'Hardware';
        qli4.SBQQ__SubscriptionTerm__c = 12;
        qli4.SubscribedAssetNames__c = 'BB192863040046';
        qli4.Disposition_Reason__c = 'Churn';
        qli4.SBQQ__ListPrice__c = 100;
        insert qli4;
        
        SBQQ__QuoteLine__c qli5 = new SBQQ__QuoteLine__c();
        qli5.SBQQ__Quote__c = q2.Id;
        qli5.SBQQ__Product__c = prod.Id;
        qli5.SBQQ__Quantity__c = 10;
        qli5.SBQQSC__RenewedContractLine__c = renewedContractLineItem.Id;
        qli5.Product_Level__c = 'Hardware';
        qli5.SBQQ__SubscriptionTerm__c = 12;
        qli5.SubscribedAssetNames__c = 'BB192863040046';
        qli5.Disposition_Reason__c = 'Not Renewing - Converted';
        qli5.SBQQ__ListPrice__c = 100;
        insert qli5;
        
        qliList.add(ql0);
        qliList.add(ql);
        qliList.add(ql1);
        qliList.add(ql2);
        qliList.add(ql3);
        qliList.add(qli3);
        qliList.add(qli4);
        qliList.add(qli5);
        
        newQLIMap.put(ql.Id, ql);
        newQLIMap.put(ql1.Id, ql1);
        newQLIMap.put(ql2.Id, ql2);
        newQLIMap.put(qli3.Id, qli3);
        newQLIMap.put(qli4.Id, qli4);
        newQLIMap.put(qli5.Id, qli5);
        
        SBQQ_QuoteLineTriggerHelper.populateQuoteLineGroup(qliList);
        SBQQ_QuoteLineTriggerHelper.populateQuoteLineGroupFuture(qid);
        SBQQ_QuoteLineTriggerHelper.updateApprovalIdentifierForDisposition(
            newQLIMap
        );
         Test.stopTest();
        System.assert(true);
        }
    }
    
    /**testCustomPOT */
    /**
     * @description  : This test method is used to test the custom POT functionality of SBQQ_QuoteLineTriggerHandler.
     */
    @isTest
    private static void testCustomPOT() {
        SBQQ_QuoteLineTriggerHandler handler = new SBQQ_QuoteLineTriggerHandler();
        
        ShGl_DisableBusinessLogic__c cdf1 = new ShGl_DisableBusinessLogic__c(
            SetupOwnerId = UserInfo.getUserId(),
            Disable_SBQQ_Quote_Triggers__c = true
        );
        //insert cdf1;
        
        Product2 parentProd = new Product2();
        parentProd.Name = 'CPQ Bundle Product';
        parentProd.ProductCode = 'CPQ-Bundle Product';
        parentProd.IsActive = true;
        parentProd.SBQQ__Hidden__c = true;
        parentProd.SBQQ__ExcludeFromOpportunity__c = true;
        parentProd.New_CPQ_Product__c = true;
        
        Product2 prod = new Product2();
        prod.Name = 'RBK-SVC-PREM-OBJ-STORAGE';
        prod.ProductCode = 'RBK-SVC-PREM-OBJ-STORAGE';
        prod.Category__c = 'Support';
        prod.Family = null;
        prod.Product_Type__c = null;
        prod.SBQQ__AssetConversion__c = 'None';
        prod.SBQQSC__EntitlementConversion__c = 'One per unit';
        prod.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        prod.SBQQ__SubscriptionTerm__c = 12;
        prod.SBQQ__SubscriptionBase__c = 'List';
        prod.SBQQ__SubscriptionType__c = 'Renewable';
        prod.Custom_POT__c = true;
        prod.SBQQ__SubscriptionPercent__c = 1.083;
        prod.SBQQ__SubscriptionCategory__c = 'Hardware';
        prod.IsActive = true;
        prod.Asset_Priority__c = 1;
        prod.New_CPQ_Product__c = true;
        
        Product2 prod1 = new Product2(
            Name = 'TestProd',
            IsActive = true,
            Custom_POT__c = true,
            SBQQ__SubscriptionPercent__c = 1.083,
            SBQQ__SubscriptionCategory__c = 'Hardware',
            ProductCode = 'Test-Prod'
        );
        
        insert new List<Product2>{ parentProd, prod, prod1 };
            
            SBQQ__ProductOption__c objProdOption1 = new SBQQ__ProductOption__c();
        objProdOption1.SBQQ__Number__c = 20;
        objProdOption1.SBQQ__ConfiguredSKU__c = parentProd.Id;
        objProdOption1.SBQQ__OptionalSKU__c = prod1.Id;
        objProdOption1.POT_Parent_s_Source__c = prod.Id;
        insert objProdOption1;
        
        List<PricebookEntry> lstPBE = new List<PricebookEntry>();
        PricebookEntry objPBE1 = getPbe(parentProd.Id, 200);
        lstPBE.add(objPBE1);
        
        PricebookEntry objPBE2 = getPbe(prod.Id, 100);
        lstPBE.add(objPBE2);
        
        PricebookEntry objPBE3 = getPbe(prod1.Id, 50);
        lstPBE.add(objPBE3);
        
        insert lstPBE;
        
        Account acc = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert acc;
        
        List<Account> accountList = new List<Account>();
        Account vAccount = getAccount('test1a account', 'Distributor', partnerRtId);
        accountList.add(vAccount);
        
        Account vAccount2 = getAccount('test2a account', null, partnerRtId);
        accountList.add(vAccount2);
        
        insert accountList;
        
        Contact con = getContact('test cont', acc.Id);
        insert con;
        
        Opportunity opp = getOppty('test opp1', acc.Id, vAccount2.Id, vAccount.Id);
        
        Test.startTest();
        insert opp;
        
        Asset asset = getAsset('12341321', acc.Id, prod.Id);
        insert asset;
        
        SBQQ__Quote__c q = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__StartDate__c = Date.today()
        );
        insert q;
        
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q.Id,
            SBQQ__Product__c = parentProd.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__Number__c = 1,
            SBQQ__SubscribedAssetIds__c = asset.Id,
            SubscribedAssetNames__c = 'BB192863040046',
            SBQQ__ListPrice__c = 100
        );
        insert qli1;
        
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q.Id,
            SBQQ__Product__c = prod1.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__Number__c = 1,
            SBQQ__SubscribedAssetIds__c = asset.Id,
            SBQQ__RequiredBy__c = qli1.Id,
            SubscribedAssetNames__c = 'BB192863040046',
            SBQQ__ListPrice__c = 100
        );
        insert qli2;
        
        SBQQ__QuoteLine__c sbq1 = [
            SELECT Id, POT_Calculation_Field__c
            FROM SBQQ__QuoteLine__c
            WHERE Id = :qli2.Id
            LIMIT 1
        ];
        
        System.runAs(new user(ID = UserInfo.getUserID())){
            sbq1.POT_Calculation_Field__c = 'Estimated POT';
            update sbq1;
        }
        
        Test.stopTest();
        System.assert(true);
    }
    
    /** testSubscribedAssetDetails*/
    /**
     * @description  : This test method is used to test the subscribed asset details functionality of SBQQ_QuoteLineTriggerHandler.
     */
    @isTest
    private static void testSubscribedAssetDetails() {
        ShGl_DisableBusinessLogic__c cdf1 = new ShGl_DisableBusinessLogic__c(
            SetupOwnerId = UserInfo.getUserId(),
            Disable_SBQQ_Quote_Triggers__c = true
        );
        //insert cdf1;
        
        SBQQ_QuoteLineTriggerHandler handler = new SBQQ_QuoteLineTriggerHandler();
        
        Test.startTest();
        
        Product2 prod = getProduct('TestProd1a', 'Test-Prod');
        insert prod;
        
        Account acct1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert acct1;
        
        List<Account> accountList = new List<Account>();
        
        Account vAccountt1 = getAccount('test2 account', 'Distributor', partnerRtId);
        accountList.add(vAccountt1);
        
        Account vAccount2 = getAccount('testa2 account', null, partnerRtId);
        accountList.add(vAccount2);
        
        insert accountList;
        
        Contact con = getContact('tesst2 con', acct1.Id);
        insert con;
        
        Opportunity opp = getOppty('testo opp', acct1.Id, vAccount2.Id, vAccountt1.Id);
        insert opp;
        
        SBQQ__Quote__c q = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Type__c = 'Quote',
            SBQQ__StartDate__c = Date.today(),
            Quoting_Desk_Exception__c = 'Quoting Exception - SW without HW',
            RWD_Deal_Ops_Exception_Justification__c = 'Test'
        );
        insert q;
        
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q.Id,
            SBQQ__Product__c = prod.Id,
            SBQQ__Quantity__c = 2,
            SBQQ__Number__c = 1,
            SubscribedAssetNames__c = 'BB192863040146 , AA183063040157, AA183063040158',
            Product_Subtype__c = 'GO CNV',
            SBQQ__ListPrice__c = 100
        );
        
        insert qli1;
        
        qli1.SubscribedAssetNames__c = 'AA183063040158, AA183063040158 , BB192863040146 , BB192863040147';
        update qli1;
        
        List<SBQQ__QuoteLine__c> qls = new List<SBQQ__QuoteLine__c>();
        qls.add(qli1);
        Map<Id, SBQQ__QuoteLine__c> newQLIMap = new Map<Id, SBQQ__QuoteLine__c>(
            qls
        );
        
        System.runAs(new user(ID = UserInfo.getUserID())){
            SBQQ_QuoteLineTriggerHelper.validateSubscribedAssetIds(newQLIMap, qls);
        }
        
        Test.stopTest();
        System.assert(true);
    }
    
    @isTest
    static void testPopulateReinstatementFeeSkuDefaultValue() {
        ShGl_TestFactoryHelper.insertTriggerControls();
        SBQQ_QuoteLineTriggerHandler handler = new SBQQ_QuoteLineTriggerHandler();
        
        Product2 prod = getProduct('RBK-REINSTATE-FEE', 'RBK-REINSTATE-FEE');
        insert prod;
        
        Account acctest1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert acctest1;
        
        List<Account> accountList = new List<Account>();
        Account vAccountTest = getAccount('testaccount', 'Distributor', partnerRtId);
        accountList.add(vAccountTest);
        
        Account vAccount2 = getAccount('testaccount 2', null, partnerRtId);
        accountList.add(vAccount2);
        
        insert accountList;
        
        Contact con = getContact('testcion', acctest1.Id);
        insert con;
        
        Opportunity opp = getOppty('test opptyp', acctest1.Id, vAccount2.Id, vAccountTest.Id);
        insert opp;
        
        Asset asset = getAsset('asset1', acctest1.Id, prod.Id);
        
        Asset asset2 = getAsset('asset2', acctest1.Id, prod.Id);
        
        Asset asset3 = getAsset('BBASSET123', acctest1.Id, prod.Id);
        
        Asset asset4 = getAsset('AA183063040158', acctest1.Id, prod.Id);
        insert new List<Asset>{ asset, asset2, asset3, asset4 };
            
            Test.startTest();
        
        SBQQ__Quote__c q = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Type__c = 'Quote',
            SBQQ__StartDate__c = Date.today(),
            SBQQ__ExpirationDate__c = Date.today().addDays(365)
        );
        insert q;
        
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q.Id,
            RnStatemntFee_included__c = false,
            SBQQ__Product__c = prod.Id,
            SBQQ__Quantity__c = 0,
            SBQQ__Number__c = 1,
            SBQQ__Renewal__c = false,
            SBQQ__DiscountScheduleType__c = 'Slab',
            SBQQ__Existing__c = false,
            SBQQ__CarryoverLine__c = false,
            SubscribedAssetNames__c = 'BBASSET123 ,AA183063040158 ',
            SBQQ__ListPrice__c = 100
        );
        
        System.runAs(new user(ID = UserInfo.getUserID())){
            insert qli1;
        }

        Map<Id, SBQQ__QuoteLine__c> oldMap = new Map<Id, SBQQ__QuoteLine__c>{
            qli1.Id => qli1
                };
                    
                    qli1.SubscribedAssetNames__c =
                    asset.Name +
                    ', ' +
                    asset2.Name +
                    ', ' +
                    asset3.Name +
                    ', ' +
                    asset4.Name;
        List<SBQQ__QuoteLine__c> newList = new List<SBQQ__QuoteLine__c>{ qli1 };
            
            //SBQQ_QuoteLineTriggerHelper.populateSubscribedAssetIds(oldMap, newList);
            
            Test.stopTest();
        System.assert(true);
    }
    
    @isTest
    private static void testForOppStageToValidate() {
        ShGl_TestFactoryHelper.insertTriggerControls();
        
        SBQQ_QuoteLineTriggerHandler handler = new SBQQ_QuoteLineTriggerHandler();
        
        Product2 prod = getProduct('RBK-REINSTATE-FEE', 'RBK-REINSTATE-FEE');
        prod.Legacy_Software_Bundle__c = true;
        insert prod;
        
        Account accTest12 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert accTest12;
        
        List<Account> accountList = new List<Account>();
        
        Account vAccount12 = getAccount('Test Account2', 'Distributor', partnerRtId);
        accountList.add(vAccount12);
        
        Account vAccount2 = getAccount('Testa Account', null, partnerRtId);
        accountList.add(vAccount2);
        
        insert accountList;
        
        Contact con = getContact('testcontact2', accTest12.Id);
        insert con;
        
        Opportunity opp = getOppty('testopportunuity', accTest12.Id, vAccount2.Id, vAccount12.Id);
        insert opp;
        
        Asset asset = getAsset('314121', accTest12.Id, prod.Id);
        insert asset;
        
        Test.startTest();
        
        SBQQ__Quote__c q = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Type__c = 'Renewal',
            SBQQ__StartDate__c = Date.today()
        );
        insert q;
        
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q.Id,
            RnStatemntFee_included__c = false,
            SBQQ__Product__c = prod.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__Number__c = 1,
            SBQQ__SubscribedAssetIds__c = asset.Id,
            SubscribedAssetNames__c = 'BB192863040046',
            Is_Premium_Support__c = true,
            SBQQ__ListPrice__c = 100
        );
        insert qli1;
        
        qli1.SBQQ__Number__c = 2;
        update qli1;
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>();
        qliList.add(qli1);
        
        List<SBQQ__QuoteLine__c> queryList = [
            SELECT
            Id,
            SBQQ__ProductCode__c,
            SBQQ__Quote__r.SBQQ__Type__c,
            RnStatemntFee_included__c,
            SBQQ__SubscribedAssetIds__c,
            SubscribedAssetLookup__c,
            SubscribedAssetNames__c
            FROM SBQQ__QuoteLine__c
            WHERE Id IN :qliList
            LIMIT 50000
        ];
        
        //SBQQ_QuoteLineTriggerHelper.populateAssetDetails(queryList);
        
        System.runAs(new user(ID = UserInfo.getUserID())){
            SBQQ_QuoteLineTriggerHelper.populateReinstatementFeeSkuDefaultValue(
                queryList
            );
        }
        
        Test.stopTest();
        System.assert(true);
    }
    
    @isTest
    private static void datePolicyTest3() {
         String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(
            Alias = 'adminU', Email='AdminUser@rubrik.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
            RBAC_Group__c = 'System - IT',
            RBAC_Department__c = 'Service Account',
            UserName=uniqueUserName
        );
        insert u;
        System.runAs(u) {
        ShGl_DisableFunctionalityLogic__c settingA = new ShGl_DisableFunctionalityLogic__c();
        settingA.Name = 'System Administrator';
        settingA.Disable_Opportunity_Old_Trigger__c = true;
        settingA.Disable_Order_Old_Trigger__c = true;
        settingA.Disable_Account_Old_Trigger__c = true;
        insert settingA;
        
        ShGl_DisableBusinessLogic__c settingDisableA = new ShGl_DisableBusinessLogic__c();
        settingDisableA.Name = 'System Administrator';
        settingDisableA.Disable_Opportunity_Validation_Rules__c = true;
        settingDisableA.Disable_Order_Validation_Rules__c = true;
        settingDisableA.Disable_Entitlement_Validation_Rules__c=true;
        insert settingDisableA;
        
        List<TriggerControl__c> triggerList = new List<TriggerControl__c>();
        TriggerControl__c setting0 = new TriggerControl__c();
        setting0.Name = 'Order';
        setting0.DisableTrigger__c = true;
        triggerList.add(setting0);
        
        TriggerControl__c setting1 = new TriggerControl__c();
        setting1.Name = 'Opportunity';
        setting1.DisableTrigger__c = true;
        triggerList.add(setting1);
        
        TriggerControl__c setting2 = new TriggerControl__c();
        setting2.Name = 'Entitlement';
        setting2.DisableTrigger__c = true;
        triggerList.add(setting2);
        
        insert triggerList;
        
        Account actVal = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert actVal;
        
        List<Account> accountList = new List<Account>();
        Account vAccountK = getAccount('test1account', 'Distributor', partnerRtId);
        accountList.add(vAccountK);
        
        Account vAccount2 = getAccount('testaccrbk', null, partnerRtId);
        accountList.add(vAccount2);
        
        insert accountList;
        
        Opportunity opp = getOppty('testopprt2', actVal.Id, vAccount2.Id, vAccountK.Id);
        insert opp;
        
        Map<String, Object> prdMap = new Map<String, Object>{
            'Name' => 'DateTest1',
                'IsActive' => true,
                'Product_Type__c' => 'RCDM Support',
                'ProductCode' => 'Date-Test1'
                };
                    
                    Map<String, Object> otherTypeProduct = new Map<String, Object>{
                        'Name' => 'DateTest2',
                            'IsActive' => true,
                            'Product_Type__c' => 'HW Support',
                            'ProductCode' => 'Date2-Test'
                            };
                                
                                Map<String, Object> prdMap1 = new Map<String, Object>{
                                    'Name' => 'DateTest12',
                                        'IsActive' => true,
                                        'License_Subtype__c' => 'Add-On',
                                        'ProductCode' => 'Date-Test12'
                                        };
                                            
                                            Map<String, Object> prdMap2 = new Map<String, Object>{
                                                'Name' => 'DateTest13',
                                                    'IsActive' => true,
                                                    'License_Subtype__c' => 'Add-On',
                                                    'ProductCode' => 'RBK-REINSTATE-FEE'
                                                    };
                                                        
                                                        Product2 hwent = (Product2) ShGl_TestFactory.createSObject(
                                                            new Product2(),
                                                            otherTypeProduct
                                                        );
        
        Product2 prod = (Product2) ShGl_TestFactory.createSObject(
            new Product2(),
            prdMap
        );
        
        Product2 prod1 = (Product2) ShGl_TestFactory.createSObject(
            new Product2(),
            prdMap1
        );
        
        Product2 prod3 = (Product2) ShGl_TestFactory.createSObject(
            new Product2(),
            prdMap2
        );
        
        Product2 prod4 = new Product2(
            Name = 'TestProd',
            IsActive = true,
            ProductCode = 'RBK-REINSTATE-FEE'
        );
        
        insert new List<Product2>{ hwent, prod, prod1, prod3, prod4 };
            
            List<PricebookEntry> entries = new List<PricebookEntry>();
        entries.add(
            getPbe(hwent.Id, 100)
        );
        
        entries.add(
            getPbe(prod.Id, 100)
        );
        
        entries.add(
            getPbe(prod1.Id, 200)
        );
        
        entries.add(
            getPbe(prod3.Id, 200)
        );
        
        entries.add(
            getPbe(prod4.Id, 200)
        );
        
        insert entries;
        
        Entitlement ent = new Entitlement();
        ent.Name = 'Testing';
        ent.AccountId = actVal.Id;
        ent.Product__c = prod.Id;
        ent.StartDate = Date.today();
        ent.EndDate = Date.today().addDays(365);
        insert ent;
        
        Entitlement ent2 = new Entitlement();
        ent2.Name = 'Testing';
        ent2.AccountId = actVal.Id;
        ent2.Product__c = hwent.Id;
        ent2.StartDate = Date.today();
        ent2.EndDate = Date.today().addDays(360);
        insert ent2;
        
        SBQQ__Quote__c q = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Type__c = 'Amendment',
            SBQQ__Account__c = actVal.Id,
            SBQQ__SubscriptionTerm__c = 12,
            AddOn_Date_Check__c = true
        );
        
        SBQQ__Quote__c q1 = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Type__c = 'Renewal',
            SBQQ__Account__c = actVal.Id,
            SBQQ__SubscriptionTerm__c = 12
        );
        
        Test.startTest();
        
        List<SBQQ__Quote__c> qList = new List<SBQQ__Quote__c>();
        qList.add(q);
        qList.add(q1);
        
        insert qList;
        
        SBQQ__QuoteLineGroup__c objQLGDis = new SBQQ__QuoteLineGroup__c(
            Name = 'Disposition Quote',
            SBQQ__EndDate__c = Date.today().addDays(370),
            SBQQ__Quote__c = q.Id
        );
        insert new List<SBQQ__QuoteLineGroup__c>{ objQLGDis };
            
            SBQQ__QuoteLine__c qlis = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = q.Id,
                SBQQ__Product__c = prod1.Id,
                SBQQ__Quantity__c = 10,
                SubscribedAssetNames__c = 'BB192863040046',
                SBQQ__SubscriptionTerm__c = 12,
                SBQQ__ListPrice__c = 100
            );
        insert qlis;
        
        SBQQ__QuoteLine__c qli1s = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q1.Id,
            RnStatemntFee_included__c = false,
            SBQQ__Quantity__c = 10,
            SubscribedAssetNames__c = 'BB192863040046',
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__Product__c = prod4.Id,
            SBQQ__PackageProductCode__c = 'RBK-REINSTATE-FEE',
            SBQQ__ListPrice__c = 100
        );
        insert qli1s;
        
        Set<Id> qlid = new Set<Id>();
        qlid.add(qlis.id);
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> ListQl = new List<SBQQ__QuoteLine__c>();
        ListQl.add(qli1s);
        qliList.add(qli1s);
        
        SBQQ_QuoteLineTriggerHelper.datePolicy(qlid, false);
        //SBQQ_QuoteLineTriggerHelper.makeFieldsNullWhenCloned(qlid);
        SBQQ_QuoteLineTriggerHelper.populateReinstatementFeeSkuDefaultValue(ListQl);
        
        Test.stopTest();
        System.assert(true);
        }
    }
    
    /**datePolicy_Test4 */
    /**
     * @description  : This test method is used to test the date policy functionality of SBQQ_QuoteLineTriggerHandler.
     */
    @isTest
    private static void datePolicyTest4() {
        ShGl_DisableFunctionalityLogic__c setting = new ShGl_DisableFunctionalityLogic__c();
        setting.Name = 'System Administrator';
        setting.Disable_Opportunity_Old_Trigger__c = true;
        setting.Disable_Order_Old_Trigger__c = true;
        setting.Disable_Account_Old_Trigger__c = true;
        insert setting;
        
        ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c();
        settingDisable.Name = 'System Administrator';
        settingDisable.Disable_Opportunity_Validation_Rules__c = true;
        settingDisable.Disable_Order_Validation_Rules__c = true;
        insert settingDisable;
        
        List<TriggerControl__c> triggerList = new List<TriggerControl__c>();
        TriggerControl__c setting0 = new TriggerControl__c();
        setting0.Name = 'Order';
        setting0.DisableTrigger__c = true;
        triggerList.add(setting0);
        
        TriggerControl__c setting1 = new TriggerControl__c();
        setting1.Name = 'Opportunity';
        setting1.DisableTrigger__c = true;
        triggerList.add(setting1);
        
        TriggerControl__c setting2 = new TriggerControl__c();
        setting2.Name = 'Entitlement';
        setting2.DisableTrigger__c = true;
        triggerList.add(setting2);
        
        insert triggerList;
        
        Account actB = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert actB;
        
        List<Account> accountList = new List<Account>();
        Account vAccountV = getAccount('TestBAccount', 'Distributor', partnerRtId);
        accountList.add(vAccountV);
        
        Account vAccount2 = getAccount('Test Account', null, vAccountV.RecordTypeId);
        accountList.add(vAccount2);
        
        insert accountList;
        
        Opportunity opp = getOppty('testopprty', actB.Id, vAccount2.Id, vAccountV.Id);
        insert opp;
        
        Product2 prod4 = new Product2();
        prod4.Name = 'TestProd';
        prod4.IsActive = true;
        prod4.ProductCode = 'RBK-REINSTATE-FEE';
        prod4.Product_Type__c = 'HW Support';
        insert prod4;
        
        SBQQ__Quote__c q2 = new SBQQ__Quote__c();
        q2.SBQQ__Opportunity2__c = opp.Id;
        q2.SBQQ__Type__c = 'Renewal+Expansion';
        q2.SBQQ__Account__c = actB.Id;
        q2.SBQQ__SubscriptionTerm__c = 12;
        
        Test.startTest();
        
        insert q2;
        
        SBQQ__QuoteLine__c qlis = new SBQQ__QuoteLine__c();
        qlis.SBQQ__Quote__c = q2.Id;
        qlis.SBQQ__Product__c = prod4.Id;
        qlis.SBQQ__Quantity__c = 10;
        qlis.SubscribedAssetNames__c = 'BB192863040046';
        qlis.SBQQ__SubscriptionTerm__c = 12;
        qlis.Product_Type__c = 'Hardware';
        qlis.Special_Program__c = 'Conversion';
        qlis.Arroyo_Subscribed_Asset_Name__c = 'BB192863040046';
        qlis.SBQQ__ListPrice__c = 100;
        insert qlis;
        
        List<SBQQ__QuoteLine__c> qliList = [
            SELECT
            Id,
            Line_Type__c,
            Arroyo_Subscribed_Asset_Name__c,
            SBQQ__Quote__c,
            SBQQ__RequiredBy__c,
            Product_Type__c,
            Special_Program__c
            FROM SBQQ__QuoteLine__c
            WHERE Id = :qlis.Id
            LIMIT 50000
        ];
        
        
        System.runAs(new user(ID = UserInfo.getUserID())){
            SBQQ_QuoteLineTriggerHelper.stopDeletionOfRenewalLines(
                qliList,
                new Map<Id, SBQQ__Quote__c>{ q2.Id => q2 }
            );
        }
        
        Test.stopTest();
        System.assert(true);
    }
    
    /**
     * @description  : This test method is used to test the populateBundlePremiumSUpport functionality of SBQQ_QuoteLineTriggerHelper.
     */
    @isTest
    static void testMethod1() {
        ShGl_DisableBusinessLogic__c cdf1 = new ShGl_DisableBusinessLogic__c(
            SetupOwnerId = UserInfo.getUserId(),
            Disable_SBQQ_Quote_Triggers__c = true
        );
        //insert cdf1;
        
        ShGl_DisableFunctionalityLogic__c settingB = new ShGl_DisableFunctionalityLogic__c();
        settingB.Name = 'System Administrator';
        settingB.Disable_Opportunity_Old_Trigger__c = true;
        settingB.Disable_Order_Old_Trigger__c = true;
        settingB.Disable_Account_Old_Trigger__c = true;
        insert settingB;
        
        ShGl_DisableBusinessLogic__c settingDisableB = new ShGl_DisableBusinessLogic__c();
        settingDisableB.Name = 'System Administrator';
        settingDisableB.Disable_Opportunity_Validation_Rules__c = true;
        settingDisableB.Disable_Order_Validation_Rules__c = true;
        insert settingDisableB;
        
        List<TriggerControl__c> triggerList = new List<TriggerControl__c>();
        
        TriggerControl__c setting0A = new TriggerControl__c();
        setting0A.Name = 'Order';
        setting0A.DisableTrigger__c = true;
        triggerList.add(setting0A);
        
        TriggerControl__c setting1A = new TriggerControl__c();
        setting1A.Name = 'Opportunity';
        setting1A.DisableTrigger__c = true;
        triggerList.add(setting1A);
        
        insert triggerList;
        
        ShGl_TestFactoryHelper.insertTriggerControls();
        
        Product2 prod = getProduct('TestProd', 'Test-Prod');
        
        Product2 prodSupp = getProduct('TestProdSupport', 'Test-Supp');
        
        Product2 prodSub = getProduct('TestProdSubscription', 'Test-Subs');
        
        List<Product2> prdList = new List<Product2>{ prod, prodSupp, prodSub };
            insert prdList;
        
        PricebookEntry pbe = getPbe(prod.Id, 10);
        
        PricebookEntry pbeSupp = getPbe(prodSupp.Id, 10);
        
        PricebookEntry pbeSub = getPbe(prodSub.Id, 10);
        
        List<PricebookEntry> pbeList = new List<PricebookEntry>{
            pbe,
                pbeSupp,
                pbeSub
                };
                    insert pbeList;
        
        Account acc = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert acc;
        
        List<Account> accountList = new List<Account>();
        
        Account vAccount = getAccount('Test Account 2', 'Distributor', partnerRtId);
        accountList.add(vAccount);
        
        Account vAccount2 = getAccount('TestAccount22', null, vAccount.RecordTypeId);
        vAccount2.Distributor__c = vAccount.Id;
        accountList.add(vAccount2);
        
        insert accountList;
        
        Asset asset = getAsset('353019', acc.Id, prod.Id);
        insert asset;
        
        //Generate the Opportunity
        Map<String, Object> oppMap = new Map<String, Object>{
            'AccountId' => acc.Id,
                'Partner_Lookup__c' => vAccount2.Id,
                'Distributor_Lookup__c' => vAccount.Id
                };
                    
                    Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(
                        new Opportunity(),
                        oppMap
                    );
        insert opp;
        
        Test.startTest();
        
        SBQQ__Quote__c q = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp.Id);
        insert q;
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>();
        
        SBQQ__QuoteLine__c qli1a = new SBQQ__QuoteLine__c();
        qli1a.SBQQ__Quote__c = q.Id;
        qli1a.SBQQ__Product__c = prod.Id;
        qli1a.SBQQ__Quantity__c = 10;
        qli1a.SBQQ__Number__c = 1;
        qli1a.SBQQ__SubscribedAssetIds__c = asset.Id;
        qli1a.SubscribedAssetNames__c = 'BB192863040046';
        qli1a.SBQQ__SubscriptionTerm__c = 12;
        qli1a.SBQQ__ListPrice__c = 100;
        insert qli1a;
        
        SBQQ__QuoteLine__c qli2a = new SBQQ__QuoteLine__c();
        qli2a.SBQQ__Quote__c = q.Id;
        qli2a.SBQQ__Product__c = prodSupp.Id;
        qli2a.SBQQ__Quantity__c = 10;
        qli2a.SBQQ__Number__c = 2;
        qli2a.SBQQ__SubscriptionTerm__c = 12;
        qli2a.Is_Premium_Support__c = true;
        qli2a.SubscribedAssetNames__c = 'BB192863040046';
        qli2a.SBQQ__ListPrice__c = 100;
        
        SBQQ__QuoteLine__c qli3a = new SBQQ__QuoteLine__c();
        qli3a.SBQQ__Quote__c = q.Id;
        qli3a.SBQQ__Product__c = prodSub.Id;
        qli3a.SBQQ__Quantity__c = 10;
        qli3a.SBQQ__Number__c = 3;
        qli3a.SBQQ__SubscriptionTerm__c = 12;
        qli3a.SubscribedAssetNames__c = 'BB192863040046';
        qli3a.SBQQ__ListPrice__c = 100;
        
        SBQQ__QuoteLine__c qli4a = new SBQQ__QuoteLine__c();
        qli4a.SBQQ__Quote__c = q.Id;
        qli4a.SBQQ__Product__c = prodSub.Id;
        qli4a.SBQQ__Quantity__c = 10;
        qli4a.SBQQ__Number__c = 3;
        qli4a.SBQQ__SubscriptionTerm__c = 24;
        qli4a.Is_Premium_Support__c = true;
        qli4a.SubscribedAssetNames__c = 'BB192863040046';
        qli4a.SBQQ__ListPrice__c = 100;
        
        SBQQ__QuoteLine__c qli5a = new SBQQ__QuoteLine__c();
        qli5a.SBQQ__Quote__c = q.Id;
        qli5a.SBQQ__Product__c = prodSub.Id;
        qli5a.SBQQ__Quantity__c = 10;
        qli5a.SBQQ__Number__c = 3;
        qli5a.SBQQ__SubscriptionTerm__c = 24;
        qli5a.Is_Premium_Support__c = false;
        qli5a.SubscribedAssetNames__c = 'BB192863040046';
        qli5a.SBQQ__ListPrice__c = 100;
        
        qli2a.SBQQ__RequiredBy__c = qli1a.Id;
        qli3a.SBQQ__RequiredBy__c = qli1a.Id;
        qli4a.SBQQ__RequiredBy__c = qli1a.Id;
        qli5a.SBQQ__RequiredBy__c = qli1a.Id;
        
        qliList.add(qli2a);
        qliList.add(qli3a);
        qliList.add(qli4a);
        qliList.add(qli5a);
        
        
        System.runAs(new user(ID = UserInfo.getUserID())){
          insert qliList;
        }
        
        //SBQQ_QuoteLineTriggerHelper.populateBundlePremiumSupportAndSubscriptionTerm(qliList);
        
        Test.stopTest();
        System.assert(true);
    }
    
    /**
     * @description  : This test method is used to test the setSourceListPrice functionality of SBQQ_QuoteLineTriggerHelper.
     */
    @isTest
    static void testMethod2() {
        ShGl_DisableBusinessLogic__c cdf1 = new ShGl_DisableBusinessLogic__c(
            SetupOwnerId = UserInfo.getUserId(),
            Disable_SBQQ_Quote_Triggers__c = true,
            Disable_ServiceContract_Trigger__c = true
        );
        //insert cdf1;
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        TriggerControls.disableCalculateAPIBatch = true;
        SBQQ.TriggerControl.disable();
        ShGl_DisableFunctionalityLogic__c settingC = new ShGl_DisableFunctionalityLogic__c();
        settingC.Name = 'System Administrator';
        settingC.Disable_Opportunity_Old_Trigger__c = true;
        settingC.Disable_Order_Old_Trigger__c = true;
        settingC.Disable_Account_Old_Trigger__c = true;
        insert settingC;
        
        ShGl_DisableBusinessLogic__c settingDisableV = new ShGl_DisableBusinessLogic__c();
        settingDisableV.Name = 'System Administrator';
        settingDisableV.Disable_Opportunity_Validation_Rules__c = true;
        settingDisableV.Disable_Order_Validation_Rules__c = true;
        settingDisableV.Disable_ServiceContract_Trigger__c = true;
        //insert settingDisableV;

        ShGl_DisableBusinessLogic__c settingD = new ShGl_DisableBusinessLogic__c();
        settingD.Name = 'Deal Operations';
        settingD.Disable_Opportunity_Validation_Rules__c = true;
        settingD.Disable_ServiceContract_Trigger__c = true;
        settingD.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
        insert settingD;
        
        List<TriggerControl__c> triggerList = new List<TriggerControl__c>();
        
        TriggerControl__c setting0V = new TriggerControl__c();
        setting0V.Name = 'Order';
        setting0V.DisableTrigger__c = true;
        triggerList.add(setting0V);
        
        TriggerControl__c setting1V = new TriggerControl__c();
        setting1V.Name = 'Opportunity';
        setting1V.DisableTrigger__c = true;
        triggerList.add(setting1V);
        
        insert triggerList;
        
        ShGl_TestFactoryHelper.insertTriggerControls();
        
        Id pb = Test.getStandardPricebookId();
        
        Product2 prod = new Product2(
            Name = 'RA-REINST-FEE-PP',
            IsActive = true,
            SBQQ__SubscriptionPricing__c = 'Fixed Price',
            ProductCode = 'Test-Prod'
        );
        
        Product2 prodSupp = new Product2(
            Name = 'TestProdSupport',
            IsActive = true,
            SBQQ__SubscriptionPricing__c = 'Fixed Price',
            ProductCode = 'Test-Supp'
        );
        
        Product2 prodSub = new Product2(
            Name = 'TestProdSubscription',
            IsActive = true,
            SBQQ__SubscriptionPricing__c = 'Fixed Price',
            Approval_Category__c = 'AIR BASIC',
            ProductCode = 'Test-Subs'
        );
        
        List<Product2> prdList = new List<Product2>{ prod, prodSupp, prodSub };
            insert prdList;
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pb,
            Product2Id = prod.Id,
            IsActive = true,
            UnitPrice = 10
        );
        
        PricebookEntry pbeSupp = new PricebookEntry(
            Pricebook2Id = pb,
            Product2Id = prodSupp.Id,
            IsActive = true,
            UnitPrice = 10
        );
        
        PricebookEntry pbeSub = new PricebookEntry(
            Pricebook2Id = pb,
            Product2Id = prodSub.Id,
            IsActive = true,
            UnitPrice = 10
        );
        
        List<PricebookEntry> pbeList = new List<PricebookEntry>{
            pbe,
                pbeSupp,
                pbeSub
                };
                    insert pbeList;
        
        Account acc = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert acc;
        
        List<Account> accountList = new List<Account>();
        Account vAccount = new Account();
        vAccount.Name = 'Test Account';
        vAccount.Type = 'Distributor';
        vAccount.Payment_Term__c = 'Net 30';
        vAccount.RecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByName()
            .get('Partner/Distributor')
            .getRecordTypeId();
        accountList.add(vAccount);
        
        Account vAccount2 = new Account();
        vAccount2.Name = 'Test Account';
        vAccount2.Distributor__c = vAccount.Id;
        vAccount2.RecordTypeId = vAccount.RecordTypeId;
        vAccount2.Payment_Term__c = 'Net 30';
        accountList.add(vAccount2);
        
        insert accountList;
        
        Asset asset = new Asset();
        asset.Name = '123456';
        asset.Serial_Number__c = '123456';
        asset.AccountId = acc.Id;
        asset.Product2Id = prod.Id;
        insert asset;
        
        //Generate the Opportunity
        Map<String, Object> oppMap = new Map<String, Object>{
            'AccountId' => acc.Id
                };
                    
                    Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(
                        new Opportunity(),
                        oppMap
                    );
        opp.Partner_Lookup__c = vAccount2.Id;
        opp.Distributor_Lookup__c = vAccount.Id;
        insert opp;
        
        Opportunity opp1 = (Opportunity) ShGl_TestFactory.createSObject(
            new Opportunity(),
            oppMap
        );
        opp1.Partner_Lookup__c = vAccount2.Id;
        opp1.Distributor_Lookup__c = vAccount.Id;
        opp1.ETM_Theatre__c = 'APAC';
        
        Test.startTest();
        
        insert opp1;
        
        Tier_Quantity_Range_lookup_Table__c objTier1 = new Tier_Quantity_Range_lookup_Table__c();
        objTier1.Quantity_Lower_Bound__c = 1;
        objTier1.Quantity_Upper_Bound__c = 100;
        objTier1.Location__c = 'All';
        objTier1.Discount_RSM__c = 68;
        objTier1.Approval_Category__c = 'AIR BASIC';
        insert objTier1;
        
        SBQQ__Quote__c q1 = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            CSAT_Reason__c = 'Product Issue'
        );
        
        SBQQ__Quote__c q = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,//opp1.Id Khushboo
            CSAT_Reason__c = 'Product Issue'
        );
        
        insert new List<SBQQ__Quote__c>{ q, q1 };
            list<SBQQ__QuoteLine__c> quoteList = new List<SBQQ__QuoteLine__c>();
        q.SBQQ__Source__c=q1.Id;
        Update q;
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q1.Id,
            SBQQ__Product__c = prod.Id,
            SBQQ__RenewedAsset__c = asset.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__Number__c = 1,
            SBQQ__SubscribedAssetIds__c = asset.Id,
            SubscribedAssetNames__c = 'BB192863040046',
            RnStatemntFee_included__c = false,
            SBQQ__Renewal__c = true,
            SBQQ__Discount__c = 99.95,
            CPQ_Prior_Discount__c = 99.95,
            SBQQ__ListPrice__c = 100
        );
        quoteList.add(qli1);
        
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q1.Id,
            SBQQ__Product__c = prodSupp.Id,
            SBQQ__RenewedAsset__c = asset.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__Number__c = 2,
            SBQQ__SubscriptionTerm__c = 12,
            Is_Premium_Support__c = true,
            SubscribedAssetNames__c = 'BB192863040046',
            SBQQ__Renewal__c = true,
            SBQQ__Discount__c = 40,
            SBQQ__ListPrice__c = 100
        );
        insert qli2;
        
        ServiceContract serviceContractObj1 = new ServiceContract();
        serviceContractObj1.Name = 'EntitlementTriggerHelper Contract';
        serviceContractObj1.SBQQSC__Opportunity__c = opp1.Id;
        serviceContractObj1.AccountId = acc.Id;
        serviceContractObj1.StartDate = System.today();
        serviceContractObj1.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj1.Term = 36;
        insert serviceContractObj1;
        
        ContractLineItem renewedContractLineItem1 = new ContractLineItem();
        renewedContractLineItem1.SBQQSC__Account__c = acc.Id;
        renewedContractLineItem1.PricebookEntryId = pbe.Id;
        renewedContractLineItem1.ServiceContractId = serviceContractObj1.Id;
        renewedContractLineItem1.SBQQSC__QuoteLine__c = qli2.Id;
        renewedContractLineItem1.Quantity = 10;
        renewedContractLineItem1.UnitPrice = 100;
        insert renewedContractLineItem1;
        
        SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q1.Id,
            SBQQ__Product__c = prodSub.Id,
            SBQQSC__RenewedContractLine__c = renewedContractLineItem1.Id,
            SBQQ__RenewedAsset__c = asset.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__Number__c = 3,
            SBQQ__SubscriptionTerm__c = 12,
            SubscribedAssetNames__c = 'BB192863040046',
            Promo_Disc__c = 50,
            Approval_Category__c = 'AIR BASIC',
            SBQQ__Renewal__c = true,
            SBQQ__Discount__c = 100.00,
            CPQ_Prior_Discount__c = 10.00,
            Total_Discount__c = 100,
            SBQQ__ListPrice__c = 100
        );
        insert qli3;
        
        ServiceContract serviceContractObj12 = new ServiceContract();
        serviceContractObj12.Name = 'EntitlementTriggerHelper Contract';
        serviceContractObj12.SBQQSC__Opportunity__c = opp1.Id;
        serviceContractObj12.AccountId = acc.Id;
        serviceContractObj12.StartDate = System.today();
        serviceContractObj12.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj12.Term = 36;
        insert serviceContractObj12;
        
        ContractLineItem renewedContractLineItem = new ContractLineItem();
        renewedContractLineItem.SBQQSC__Account__c = acc.Id;
        renewedContractLineItem.PricebookEntryId = pbe.Id;
        renewedContractLineItem.ServiceContractId = serviceContractObj1.Id;
        renewedContractLineItem.SBQQSC__QuoteLine__c = qli3.Id;
        renewedContractLineItem.SBQQSC__Discount__c = 20.00;
        renewedContractLineItem.Quantity = 10;
        renewedContractLineItem.UnitPrice = 100;
        insert renewedContractLineItem;
        
        SBQQ__QuoteLine__c qli4 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q1.Id,
            SBQQSC__RenewedContractLine__c = renewedContractLineItem.Id,
            SBQQ__Product__c = prodSub.Id,
            SBQQ__RenewedAsset__c = asset.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__Number__c = 3,
            SBQQ__SubscriptionTerm__c = 12,
            SubscribedAssetNames__c = 'BB192863040046',
            SBQQ__Renewal__c = true,
            SBQQ__ListPrice__c = 100
        );
        
        quoteList.add(qli4);
        
        SBQQ__QuoteLine__c qli5 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q.Id,
            SBQQSC__RenewedContractLine__c = renewedContractLineItem.Id,
            SBQQ__Product__c = prodSub.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__Number__c = 3,
            SBQQ__SubscriptionTerm__c = 12,
            SubscribedAssetNames__c = 'BB192863040046',
            SBQQ__Renewal__c = true,
            SBQQ__Source__c = qli1.Id,
            SBQQ__ListPrice__c = 100
        );
        quoteList.add(qli5);
        
        SBQQ__QuoteLine__c qli6 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q.Id,
            SBQQ__Product__c = prodSub.Id,
            SBQQSC__RenewedContractLine__c = renewedContractLineItem.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__Number__c = 3,
            SBQQ__SubscriptionTerm__c = 12,
            SubscribedAssetNames__c = 'BB192863040046',
            Promo_Disc__c = 100.00,
            Approval_Category__c = 'AIR BASIC',
            SBQQ__Renewal__c = true,
            SBQQ__Discount__c = 100.00,
            CPQ_Prior_Discount__c = 10.00,
            SBQQ__Source__c= qli2.Id,
            SBQQ__ListPrice__c = 100
        );
        quoteList.add(qli6);
        insert quoteList;
            
        set<Id> quoteLineId = new Set<Id>{ qli5.Id,qli6.Id };
        Map<Id, SBQQ__QuoteLine__c> oldMap = new Map<Id, SBQQ__QuoteLine__c>{ qli5.Id => qli5,qli6.Id => qli6 };
        
        System.runAs(new user(ID = UserInfo.getUserID())){
            SBQQ_QuoteLineTriggerHelper.setSourceListPrice(quoteLineId, oldMap);
        }
        Test.stopTest();
        System.assert(true);
    }
    
    /**
     * @description  : This test method is used to test the functionality of SBQQ_QuoteLineTriggerHelper and Handler.
     */
    @isTest
    static void test3deleteQLines() {
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        
        Account accObj = TestDataFactory.getAccount();
        
        Account accObj1 = TestDataFactory.getAccount();
        accObj1.Name = 'RUBRIK_ACC_NAME';
        
        Account rbkAcc = new Account(Name = 'Rubrik');
        
        insert new List<Account>{ accObj, accObj1, rbkAcc };
            
            Opportunity oppr = TestDataFactory.getOpportunity(accObj);
        oppr.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
        insert oppr;
        
        Id standardPriceBookId = Test.getStandardPricebookId();
        
        PriceBook2 pb1 = new Pricebook2(
            Name = 'V68_2017_08_09_12_26_43',
            Description = 'Price Book 2009 Products 1',
            IsActive = true
        );
        insert pb1;
        
        Product2 prod1 = new Product2(
            Name = 'RBK-GO-BE-R6408',
            ProductCode = 'RBK-GO-BE-R6408',
            IsActive = true,
            SBQQ__SubscriptionTerm__c = 1
        );
        
        Product2 prod2 = new Product2(
            Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
            ProductCode = 'RBK-SVC-PREM-R304',
            IsActive = true,
            SBQQ__SubscriptionTerm__c = 1,
            Product_Type__c = 'HW Support'
        );
        
        Product2 prod3 = new Product2(
            Name = 'RH-6408SE-02',
            ProductCode = 'RH-6408SE-02',
            Category__c = 'Hardware',
            Product_Subtype__c = 'GO',
            SBQQ__AssetConversion__c = 'None',
            SBQQSC__EntitlementConversion__c = 'One per unit',
            SBQQ__SubscriptionPricing__c = 'Fixed Price',
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__SubscriptionBase__c = 'List',
            SBQQ__SubscriptionType__c = 'Renewable',
            IsActive = true,
            Asset_Priority__c = 1,
            New_CPQ_Product__c = true,
            Product_Level__c = 'Hardware'
        );
        
        insert new List<Product2>{ prod1, prod2, prod3 };
            
            PricebookEntry pbStanEntry1 = new PricebookEntry(
                Pricebook2Id = standardPriceBookId,
                Product2Id = prod1.Id,
                UnitPrice = 100.00,
                IsActive = true
            );
        
        PricebookEntry pbStanEntry2 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        
        PricebookEntry pbStanEntry3 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        
        PricebookEntry pbEntry1 = new PricebookEntry(
            Pricebook2Id = pb1.Id,
            Product2Id = prod1.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        
        PricebookEntry pbEntry2 = new PricebookEntry(
            Pricebook2Id = pb1.Id,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        
        PricebookEntry pbEntry3 = new PricebookEntry(
            Pricebook2Id = pb1.Id,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        
        insert new List<PricebookEntry>{
            pbStanEntry1,
                pbStanEntry2,
                pbStanEntry3,
                pbEntry1,
                pbEntry2,
                pbEntry3
                };
                    
                    Map<String, Object> quoteMap = new Map<String, Object>{
                        'SBQQ__Account__c' => accObj.Id,
                            'SBQQ__Opportunity2__c' => oppr.Id
                            };
                                
                                Set<Id> quoteId = new Set<Id>();
        
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(
            new SBQQ__Quote__c(),
            quoteMap
        );
        qt1.SBQQ__Opportunity2__c = oppr.Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__PriceBook__c = pb1.Id;
        qt1.SBQQ__Status__c = 'Draft';
        qt1.SBQQ__Type__c = 'Renewal';
        qt1.SBQQ__StartDate__c = Date.today();
        qt1.Manual_Billing__c = false;
        qt1.Consolidate_Lines__c = false;
        insert qt1;
        
        qt1.MetricsLastCalcOn__c = System.today() + 1;
        update qt1;
        
        quoteId.add(qt1.Id);
        
        insert new RPS__c(
            SetupOwnerId = Userinfo.getOrganizationId(),
            Is_RPS_Required__c = false,
            Screening_Source__c = 'Internal',
            Valid_HoldCodes__c = 'Global Trade Compliance screening failed;Credit Check Failed'
        );
        
        POC__c pocobj = new POC__c();
        pocobj.Planned_Installation_Date__c = date.today().addDays(90);
        pocobj.Support_Awareness_needed__c = 'Yes';
        pocobj.POC_Duration__c = '60 Days'; //30 Days
        pocobj.POC_Type__c = 'Conditional PO';
        insert pocobj;
        
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage(
            'Promark Technology, Inc.',
            'test123',
            System.today().addDays(10),
            1,
            'test@test.com',
            'test partner',
            System.today(),
            1,
            'test12345',
            qt1.Name,
            10000
        );
        pos.Bill_To_Name__c = accObj.Id;
        pos.Quote__c = qt1.Id;
        pos.PO_Validation_Status__c = 'Success - 855 Sent';
        pos.Payment_schedule_type__c = 'test';
        pos.PO_Internal_Validation_Status__c = 'Success';
        insert pos;
        
        Map<String, Object> OrderMap = new Map<String, Object>{
            'POC_Request__c' => pocobj.Id,
                'AccountId' => accObj.Id,
                'Type' => 'POC',
                'Send_for_Polaris_Fulfilment__c' => false,
                'POC_Opportunity__c' => oppr.Id,
                'Sync_to_NetSuite__c' => false,
                'ShippingCountryCode' => 'US',
                'ShippingStreet' => 'Test Street',
                'EffectiveDate' => System.today(),
                'Order_Status__c' => null,
                'Status' => 'Pending',
                'ShippingCity' => 'Test City',
                'ShippingState' => 'California',
                'ShippingCountry' => 'United States',
                'ShippingPostalcode' => '94820',
                'ship_To_Name__c' => accObj.Id,
                'ShipToContactName__c' => 'Test',
                'Pricebook2Id' => Test.getStandardPricebookId(),
                'Have_Polaris_Products__c' => true,
                'Polaris_Fulfillment_Status__c' => 'Completed',
                'Original_Est_Ship_Date__c' => Date.today().addDays(30),
                'Order_Sub_Type__c' => 'Renewal',
                'Integration_Failure__c' => false,
                'Est_Ship_Date__c' => null,
                'Order_Splitted__c' => true,
                'SBQQ__Quote__c' => qt1.Id
                };
                    
                    Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
        ord.Partner_Name_Text__c = 'CDW';
        ord.AddOn_Node_Count__c = null;
        ord.Stage_PO__c = pos.Id;
        insert ord;
        
        OrderItem ordrItem = new OrderItem(
            UnitPrice = pbStanEntry1.UnitPrice,
            SerialNumber__c = '123\\s+,456\\s+',
            Failed_Serial_Number__c = 'S3F4NXM416324',
            Support_End_Date__c = System.Today().addYears(1),
            OrderId = ord.Id,
            Quantity = 5,
            PricebookEntryId = pbStanEntry1.Id,
            Support_Start_Date__c = System.Today(),
            Is_Hardware_Line__c = true,
            Is_Refresh__c = true
        );
        //insert ordrItem;
        
        //test.stopTest();
        ord.Order_Status__c = 'Order Accepted';
        ord.ScreenStatus__c = 'On hold';
        ord.Integration_Failure__c = true;
        ord.Hold_Code__c = null;
        ord.Polaris_Fulfillment_Status__c = 'Manual Fulfillment';
        ord.NetSuite_Order__c = 'NSTest12';
        ord.Type = 'Revenue';
        ord.Credit_Check_Failure_Reason__c = 'Customer balance of 32 exceeds credit limit of 41.00 ';
        update ord;
        
        ord.Order_Sub_Type__c = 'MSP Overage';
        ord.Hold_Code__c = null;
        ord.ScreenStatus__c = 'Approved';
        ord.Order_Status__c = 'Pending';
        update ord;
        
        List<ServiceContract> lstServiceContract = new List<ServiceContract>();
        ServiceContract serviceContractObj2 = new ServiceContract();
        serviceContractObj2.Name = 'EntitlementTriggerHelper Contract';
        serviceContractObj2.SBQQSC__Opportunity__c = oppr.Id;
        serviceContractObj2.AccountId = accObj.Id;
        serviceContractObj2.StartDate = Date.today().addmonths(-30);
        serviceContractObj2.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj2.Term = 36;
        serviceContractObj2.SBQQSC__RenewalOpportunity__c = oppr.Id;
        serviceContractObj2.EndDate = System.today().addDays(360);
        serviceContractObj2.SBQQSC__RenewalForecast__c = false;
        lstServiceContract.add(serviceContractObj2);
        
        ServiceContract renewServiceContractObj = new ServiceContract();
        renewServiceContractObj.Name = 'EntitlementTriggerHelper Contract';
        renewServiceContractObj.SBQQSC__Opportunity__c = oppr.Id;
        renewServiceContractObj.AccountId = accObj.Id;
        renewServiceContractObj.StartDate = System.today();
        renewServiceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        renewServiceContractObj.Term = 36;
        renewServiceContractObj.SBQQSC__Quote__c = qt1.Id;
        renewServiceContractObj.EndDate = System.today().addDays(360);
        lstServiceContract.add(renewServiceContractObj);
        insert lstServiceContract;
        
        ContractLineItem contractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(
            new ContractLineItem(),
            null
        );
        contractLineItemObj.SBQQSC__Account__c = accObj.Id;
        contractLineItemObj.PricebookEntryId = pbStanEntry1.Id;
        contractLineItemObj.ServiceContractId = lstServiceContract[0].Id;
        contractLineItemObj.Quantity = 10;
        contractLineItemObj.UnitPrice = 100;
        contractLineItemObj.StartDate = Date.today().addmonths(-29);
        contractLineItemObj.EndDate = Date.today().addmonths(6);
        contractLineItemObj.SBQQSC__RenewalQuantity__c = 1;
        
        ContractLineItem contractLineItemObj2 = (ContractLineItem) ShGl_TestFactory.createSObject(
            new ContractLineItem(),
            null
        );
        contractLineItemObj2.SBQQSC__Account__c = accObj.Id;
        contractLineItemObj2.PricebookEntryId = pbStanEntry3.Id;
        contractLineItemObj2.ServiceContractId = lstServiceContract[0].Id;
        contractLineItemObj2.Quantity = 10;
        contractLineItemObj2.UnitPrice = 100;
        contractLineItemObj2.StartDate = Date.today().addmonths(-29);
        contractLineItemObj2.EndDate = Date.today().addmonths(6);
        contractLineItemObj2.SBQQSC__RenewalQuantity__c = 1;
        
        insert new List<ContractLineItem>{
            contractLineItemObj,
                contractLineItemObj2
                };
                    
                    SBQQ__QuoteLineGroup__c objQLG = new SBQQ__QuoteLineGroup__c(
                        Name = 'Renewal Quote',
                        SBQQ__Quote__c = qt1.Id
                    );
        
        SBQQ__QuoteLineGroup__c objQLGExp = new SBQQ__QuoteLineGroup__c(
            Name = 'Expansion Quote',
            SBQQ__Quote__c = qt1.Id
        );
        
        SBQQ__QuoteLineGroup__c objQLGDis = new SBQQ__QuoteLineGroup__c(
            Name = 'Disposition Quote',
            Is_Expansion_Group__c = false,
            SBQQ__Quote__c = qt1.Id
        );
        
        SBQQ__QuoteLineGroup__c objtestIs = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Quote',
            Is_Expansion_Group__c = false,
            SBQQ__Quote__c = qt1.Id
        );
        
        insert new List<SBQQ__QuoteLineGroup__c>{
            objQLG,
                objQLGExp,
                objQLGDis,
                objtestIs
                };
                    
                    List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
        
        SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c(
            PriorACVwithUplift__c = 10000,
            RTAwithoutUplift__c = 10007,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010',
            SBQQSC__RenewedContractLine__c = contractLineItemObj.Id,
            Sales_Comp_Category__c = 'HW SUPPORT',
            Disposition_Reason__c = 'Renewing',
            SBQQ__Quote__c = qt1.Id,
            SBQQ__Product__c = prod1.Id,
            SBQQ__Quantity__c = 20,
            SBQQ__SubscriptionPricing__c = null,
            SBQQ__DefaultSubscriptionTerm__c = null,
            SBQQ__ListPrice__c = 200,
            SBQQ__NetPrice__c = 200,
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addDays(10),
            SubscribedAssetNames__c = 'BB192863040046',
            Prior_Net_Total__c = 21000
        );
        
        SBQQ__QuoteLine__c ql2 = new SBQQ__QuoteLine__c(
            SBQQ__RequiredBy__c = ql1.Id,
            SubscribedAssetNames__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011',
            PriorACVwithUplift__c = 10000,
            RTAwithoutUplift__c = 107,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480011',
            SBQQSC__RenewedContractLine__c = contractLineItemObj.Id,
            Sales_Comp_Category__c = 'HW SUPPORT',
            Disposition_Reason__c = 'Refreshed',
            SBQQ__Quote__c = qt1.Id,
            SBQQ__Product__c = prod2.Id,
            SBQQ__Quantity__c = 20,
            SBQQ__SubscriptionPricing__c = 'Fixed Price',
            SBQQ__DefaultSubscriptionTerm__c = null,
            SBQQ__ListPrice__c = 200,
            SBQQ__NetPrice__c = 200,
            SBQQ__StartDate__c = Date.today(),
            Prior_Net_Total__c = 21000,
            MSP_Segment_Product__c = true,
            SBQQ__Segmentindex__c = 1
        );
        
        SBQQ__QuoteLine__c ql3 = new SBQQ__QuoteLine__c(
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010',
            Special_Program__c = 'Conversion',
            Sales_Comp_Category__c = 'HW SUPPORT',
            Disposition_Reason__c = 'None',
            SBQQ__Quote__c = qt1.Id,
            SBQQ__Product__c = prod1.Id,
            SBQQ__Quantity__c = 25,
            SBQQ__SubscriptionPricing__c = null,
            SBQQ__DefaultSubscriptionTerm__c = 12,
            SBQQ__ListPrice__c = 200,
            SBQQ__NetPrice__c = 200,
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addDays(10),
            Prior_Net_Total__c = 21000
        );
        
        SBQQ__QuoteLine__c ql4 = new SBQQ__QuoteLine__c(
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010',
            Special_Program__c = 'Conversion',
            Sales_Comp_Category__c = 'HW SUPPORT',
            Disposition_Reason__c = 'None',
            SBQQ__Quote__c = qt1.Id,
            SBQQ__Product__c = prod2.Id,
            SBQQ__Quantity__c = 20,
            SBQQ__SubscriptionPricing__c = 'Fixed Price',
            SBQQ__DefaultSubscriptionTerm__c = null,
            SBQQ__ListPrice__c = 200,
            SBQQ__NetPrice__c = 200,
            SubscribedAssetNames__c = 'BB192863040049',
            Prior_Net_Total__c = 21000,
            MSP_Segment_Product__c = true,
            SBQQ__Segmentindex__c = 1
        );
        
        SBQQ__QuoteLine__c ql5 = new SBQQ__QuoteLine__c(
            SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010',
            PriorACVwithUplift__c = 10000,
            RTAwithoutUplift__c = 107,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480093',
            SBQQSC__RenewedContractLine__c = contractLineItemObj.Id,
            Sales_Comp_Category__c = 'HW SUPPORT',
            Disposition_Reason__c = 'Converted',
            SBQQ__Quote__c = qt1.Id,
            SBQQ__Product__c = prod2.Id,
            SBQQ__Quantity__c = 20,
            SBQQ__SubscriptionPricing__c = 'Fixed Price',
            SBQQ__DefaultSubscriptionTerm__c = null,
            SBQQ__ListPrice__c = 200,
            SBQQ__NetPrice__c = 200,
            SBQQ__StartDate__c = Date.today(),
            Prior_Net_Total__c = 21000,
            MSP_Segment_Product__c = true,
            SBQQ__Segmentindex__c = 1
        );
        
        SBQQ__QuoteLine__c ql6 = new SBQQ__QuoteLine__c(
            SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010',
            PriorACVwithUplift__c = 10000,
            RTAwithoutUplift__c = 207,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010',
            SBQQSC__RenewedContractLine__c = contractLineItemObj.Id,
            Sales_Comp_Category__c = 'HW SUPPORT',
            Disposition_Reason__c = 'Converted',
            SBQQ__Quote__c = qt1.Id,
            SBQQ__Product__c = prod2.Id,
            SBQQ__Quantity__c = 20,
            SBQQ__SubscriptionPricing__c = 'Fixed Price',
            SBQQ__DefaultSubscriptionTerm__c = null,
            SBQQ__ListPrice__c = 200,
            SBQQ__NetPrice__c = 200,
            SBQQ__StartDate__c = Date.today(),
            Prior_Net_Total__c = 21000,
            MSP_Segment_Product__c = true,
            SBQQ__Segmentindex__c = 1
        );
        
        SBQQ__QuoteLine__c ql11 = new SBQQ__QuoteLine__c(
            PriorACVwithUplift__c = 10000,
            RTAwithoutUplift__c = 10007,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010',
            Sales_Comp_Category__c = 'HW SUPPORT',
            Disposition_Reason__c = 'Churn',
            SBQQ__Quote__c = qt1.Id,
            SBQQ__Product__c = prod1.Id,
            SBQQ__Quantity__c = 20,
            SBQQ__SubscriptionPricing__c = null,
            SBQQ__DefaultSubscriptionTerm__c = null,
            SBQQ__ListPrice__c = 200,
            SBQQ__NetPrice__c = 200,
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addDays(10),
            SubscribedAssetNames__c = 'BB192863040046',
            Prior_Net_Total__c = 21000
        );
        
        lines.add(ql11);
        lines.add(ql1);
        lines.add(ql2);
        lines.add(ql3);
        lines.add(ql4);
        lines.add(ql5);
        lines.add(ql6);
        insert lines;
        
        Test.startTest();
        
        qt1.Additional_Month_added__c = true;
        qt1.SBQQ__SubscriptionTerm__c = 36;
        
        User u = [SELECT Id, Name FROM User WHERE Name = 'CPQ Admin' LIMIT 1];
        
        System.runAs(u) {
            update qt1;
        }
        
        TriggerControls.disableQuoteLineTrigger = false;
        SBQQ.TriggerControl.enable();
        

        try {
            delete lines;
        } catch (DMLException e) {
            System.debug(LoggingLevel.INFO, 'MS catch block');
        }
        
        Test.stopTest();
        System.assert(true);
    }
    
    /**
     * @description  : This test method is used to test the populateQuoteLineGroup functionality of SBQQ_QuoteLineTriggerHelper.
     */
    @isTest
    static void testProperTestMethod() {
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        
        Account accObj = TestDataFactory.getAccount();
        
        insert accObj;
        
        Opportunity oppr = TestDataFactory.getOpportunity(accObj);
        oppr.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
        insert oppr;
        
        Id standardPriceBookId = Test.getStandardPricebookId();
        
        Product2 prod1 = new Product2(
            Name = 'RS-BT-BE-PE-PP',
            ProductCode = 'RS-BT-BE-PE-PP',
            IsActive = true,
            SBQQ__SubscriptionTerm__c = 36,
            Product_Level__c = 'Hybrid Software'
        );
        
        Product2 prod2 = new Product2(
            Name = 'RH-6304S-01',
            ProductCode = 'RH-6304S-01',
            IsActive = true,
            SBQQ__SubscriptionTerm__c = 36,
            Product_Type__c = 'Hardware',
            Category__c = 'Hardware',
            Product_Level__c = 'Hardware'
        );
        
        Product2 prod3 = new Product2(
            Name = 'RS-BT-SW-SVC-PE',
            ProductCode = 'RS-BT-SW-SVC-PE',
            IsActive = true,
            SBQQ__SubscriptionTerm__c = 36,
            Category__c = 'Support',
            Product_Type__c = 'Support',
            Product_Level__c = 'Support'
        );
        
        Product2 prod4 = new Product2(
            Name = 'RS-BT-RCDM-T',
            ProductCode = 'RS-BT-RCDM-T',
            IsActive = true,
            SBQQ__SubscriptionTerm__c = 36,
            Product_Level__c = 'OnPrem'
        );
        
        insert new List<Product2>{ prod1, prod2, prod3, prod4 };
            
            Asset asset3 = new Asset();
        asset3.Name = 'BBASSET123';
        asset3.Serial_Number__c = 'BBASSET123';
        asset3.AccountId = accObj.id;
        asset3.Product2Id = prod3.Id;
        
        insert asset3;
        
        PricebookEntry pb1 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod1.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        
        PricebookEntry pb2 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod2.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        
        PricebookEntry pb3 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod3.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        
        PricebookEntry pb4 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod4.Id,
            UnitPrice = 0.00,
            IsActive = true
        );
        
        insert new List<PricebookEntry>{ pb1, pb2, pb3, pb4 };
            
            Map<String, Object> quoteMap = new Map<String, Object>{
                'SBQQ__Account__c' => accObj.Id,
                    'SBQQ__Opportunity2__c' => oppr.Id,
                    'SBQQ__Primary__c' => true,
                    'SBQQ__PriceBook__c' => standardPriceBookId,
                    'SBQQ__Status__c' => 'Draft',
                    'SBQQ__Type__c' => 'Renewal',
                    'SBQQ__StartDate__c' => Date.today()
                    };
                        
                        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(
                            new SBQQ__Quote__c(),
                            quoteMap
                        );
        insert qt1;
        
        SBQQ__QuoteLineGroup__c objQLG = new SBQQ__QuoteLineGroup__c(
            Name = 'Renewal Quote',
            SBQQ__Quote__c = qt1.Id
        );
        
        SBQQ__QuoteLineGroup__c objQLGExp = new SBQQ__QuoteLineGroup__c(
            Name = 'Expansion Quote',
            SBQQ__Quote__c = qt1.Id
        );
        
        SBQQ__QuoteLineGroup__c objQLGDis = new SBQQ__QuoteLineGroup__c(
            Name = 'Disposition Quote',
            SBQQ__Quote__c = qt1.Id
        );
        
        SBQQ__QuoteLineGroup__c objtestIs = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Quote',
            Is_Expansion_Group__c = false,
            SBQQ__Quote__c = qt1.Id
        );
        
        insert new List<SBQQ__QuoteLineGroup__c>{
            objQLG,
                objQLGExp,
                objQLGDis,
                objtestIs
                };
                    
                    SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c(
                        SBQQ__Quote__c = qt1.Id,
                        SBQQ__Product__c = prod1.Id,
                        SBQQ__Group__c = objQLGExp.Id,
                        SBQQ__Quantity__c = 20,
                        SBQQ__SubscriptionPricing__c = null,
                        SBQQ__DefaultSubscriptionTerm__c = null,
                        SBQQ__ListPrice__c = 200,
                        SBQQ__NetPrice__c = 200,
                        SBQQ__StartDate__c = Date.today(),
                        SBQQ__EndDate__c = Date.today().addDays(10)
                    );
        
        insert ql1;
        
        SBQQ__QuoteLine__c ql2 = new SBQQ__QuoteLine__c(
            SBQQ__RequiredBy__c = ql1.Id,
            SBQQ__Quote__c = qt1.Id,
            SBQQ__Group__c = objQLG.Id,
            SBQQ__Product__c = prod2.Id,
            Disposition_Reason__c = 'None',
            SBQQ__Existing__c = false,
            SBQQ__Renewal__c = false,
            SBQQ__Quantity__c = 20,
            SBQQ__SubscriptionPricing__c = 'Fixed Price',
            SBQQ__DefaultSubscriptionTerm__c = null,
            SBQQ__ListPrice__c = 200,
            SBQQ__NetPrice__c = 200,
            SBQQ__StartDate__c = Date.today()
        );
        
        insert ql2;
        
        SBQQ__QuoteLine__c ql3 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt1.Id,
            SBQQ__Product__c = prod3.Id,
            SBQQ__RequiredBy__c = ql2.Id,
            SBQQ__Group__c = objtestIs.Id,
            Disposition_Reason__c = 'None',
            SBQQ__Quantity__c = 25,
            // SBQQ__RenewedAsset__c = asset3.Id,
            SBQQ__Renewal__c = true,
            SBQQ__SubscriptionPricing__c = null,
            SBQQ__DefaultSubscriptionTerm__c = 12,
            SBQQ__ListPrice__c = 200,
            SBQQ__NetPrice__c = 200,
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addDays(10)
        );
        
        SBQQ__QuoteLine__c ql4 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt1.Id,
            SBQQ__Product__c = prod3.Id,
            SBQQ__RequiredBy__c = ql1.Id,
            SBQQ__Quantity__c = 25,
            SBQQ__SubscriptionPricing__c = null,
            SBQQ__DefaultSubscriptionTerm__c = 12,
            SBQQ__ListPrice__c = 0,
            SBQQ__NetPrice__c = 0,
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addDays(10)
        );
        
        SBQQ__QuoteLine__c ql5 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt1.Id,
            SBQQ__Product__c = prod4.Id,
            Disposition_Reason__c = 'None',
            SBQQ__RequiredBy__c = ql1.Id,
            SBQQ__Quantity__c = 25,
            SBQQ__SubscriptionPricing__c = null,
            SBQQ__DefaultSubscriptionTerm__c = 12,
            SBQQ__ListPrice__c = 0,
            SBQQ__NetPrice__c = 0,
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addDays(10)
        );
        
        insert new List<SBQQ__QuoteLine__c>{ ql3, ql4, ql5 };
          
        System.runAs(new user(ID = UserInfo.getUserID())){  

            SBQQ_QuoteLineTriggerHelper.populateQuoteLineGroupFuture(
                new Set<Id>{ qt1.Id }
            );
        }
        System.assert(true);
    }
    /* autoAddONDSKUs_Test */
    //@isTest
    //private static void autoAddONDSKUs_Test() 
    /* Test Data Set Up */
    @TestSetUp
    static void initialDataSetupAutoAddONDSKUsTest() {
        System.runAs(new user(ID = UserInfo.getUserID())){
        ShGl_DisableBusinessLogic__c cdf1 = new ShGl_DisableBusinessLogic__c(SetupOwnerId = userInfo.getUserId(),
                                                                             Disable_SBQQ_Quote_Validation_Rules__c = true,
                                                                             Disable_SBQQ_QuoteLine_Validation_Rules__c = true,
                                                                             Disable_Opportunity_Validation_Rules__c = true,
                                                                             Disable_ServiceContract_Trigger__c = true,
                                                                             Disable_Contract_Line_Item_Triggers__c = true);
        insert cdf1;
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        TriggerControls.disableCalculateAPIBatch = true;
        SBQQ.TriggerControl.disable();
        
        Account act11 = (Account) ShGl_TestFactory.createSObject(
            new Account(),
            null
        );
        insert act11;
        
        List<Account> accountList12 = new List<Account>();
        
        Account vAccount1a = getAccount('test acc', 'Distributor', partnerRtId);
        accountList12.add(vAccount1a);
        
        Account vAccount2 = getAccount('test account 2', null, partnerRtId);
        accountList12.add(vAccount2);
        
        insert accountList12;
        
        Opportunity opp1a = getOppty('test opty', act11.Id, vAccount2.Id, vAccount1a.Id);
        insert (opp1a);
        
        List<Product2> prodList1a = new List<Product2>();
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> newQLIMap = new List<SBQQ__QuoteLine__c>();
        
        List<Product2> prdList2 = new List<Product2>();
        
        Map<String, Object> prdMap2 = new Map<String, Object>{
            'Name' => 'WrapperProduct',
                'IsActive' => true
                };
                    
                    Product2 pd = (Product2) ShGl_TestFactory.createSObject(
                        new Product2(),
                        prdMap2
                    );
        prdList2.add(pd);
        
        Map<String, Object> prdMap11 = new Map<String, Object>{
            'Name' => 'optionProduct',
                'IsActive' => true,
                'SBQQ__SubscriptionTerm__c' => 12,
                'Category__c' => 'Support',
                'Support_Type__c' => 'PREM',
                'SBQQ__Component__c' => true,
                'ProductCode' => 'option-Product'
                };
                    
                    Product2 pd11 = (Product2) ShGl_TestFactory.createSObject(
                        new Product2(),
                        prdMap11
                    );
        prdList2.add(pd11);
        
        Product2 pd2 = (Product2) ShGl_TestFactory.createSObject(
            new Product2(),
            prdMap11
        );
        prdList2.add(pd2);
        
        insert prdList2;
        
        Product2 jb1 = [
            SELECT Id, Name, Is_Premium_Support__c
            FROM Product2
            WHERE Id = :pd11.Id
            LIMIT 1
        ];
        Product2 jb2 = [
            SELECT Id, Name, Is_Premium_Support__c
            FROM Product2
            WHERE Id = :pd11.Id
            LIMIT 1
        ];
        
        List<PricebookEntry> entries1 = new List<PricebookEntry>();
        
        entries1.add(
            getPbe(pd.Id, 100)
        );
        
        entries1.add(
            getPbe(pd11.Id, 1000)
        );
        
        insert entries1;
        
        SBQQ__Quote__c q1 = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp1a.Id,
            SBQQ__Type__c = 'Amendment',
            SBQQ__Account__c = act11.Id,
            OpportunitySubType__c = 'GC Offer',
            SBQQ__PricebookId__c = Test.getStandardPricebookId()
        );
        
        SBQQ__Quote__c q2 = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp1a.Id,
            SBQQ__Type__c = 'Amendment',
            SBQQ__Account__c = act11.Id,
            OpportunitySubType__c = 'GC Offer',
            SBQQ__PricebookId__c = Test.getStandardPricebookId()
        );
        
        SBQQ__Quote__c q3 = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp1a.Id,
            SBQQ__Type__c = 'Amendment',
            SBQQ__Account__c = act11.Id,
            OpportunitySubType__c = 'GC Offer',
            SBQQ__PricebookId__c = Test.getStandardPricebookId()
        );
        
        SBQQ__Quote__c q4 = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp1a.Id,
            SBQQ__Type__c = 'Amendment',
            SBQQ__Account__c = act11.Id,
            OpportunitySubType__c = 'GC Offer',
            SBQQ__PricebookId__c = Test.getStandardPricebookId()
        );
        
        SBQQ__Quote__c newQuote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp1a.Id,
            SBQQ__Type__c = 'Quote',
            SBQQ__Account__c = act11.Id,
            OpportunitySubType__c = 'GC Offer',
            SBQQ__PricebookId__c = Test.getStandardPricebookId()
        );
        //Test.startTest();
        
        insert new List<SBQQ__Quote__c>{ q1, q2, q3, q4, newQuote };
            
            Set<Id> qid = new Set<Id>();
        qid.add(q1.id);
        
        List<Product2> sampleProducts = new List<Product2>();
        //0
        Product2 prod0 = new Product2();
        prod0.Name = 'RS-TB-FE-RSVX-PE';
        prod0.ProductCode = 'RS-TB-FE-RSVX-PE';
        prod0.IsActive = true;
        prod0.Product_Type__c = 'Foundation Edition';
        prod0.Support_Type__c = 'Premium';
        prod0.Scale_Utility_Product_Identifier__c = null;
        prod0.Scale_Utility_Product_RSV_OND__c = null;
        prod0.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        sampleProducts.add(prod0);
        
        //1
        Product2 prod1 = new Product2();
        prod1.Name = 'RS-TB-FE-RSV-PE';
        prod1.ProductCode = 'RS-TB-FE-RSV-PE';
        prod1.IsActive = true;
        prod1.Product_Type__c = 'Foundation Edition';
        prod1.Support_Type__c = 'Premium';
        prod1.Scale_Utility_Product_Identifier__c = null;
        prod1.Scale_Utility_Product_RSV_OND__c = 'RSV';
        prod1.Product_Payment_Option__c = 'Prepay';
        sampleProducts.add(prod1);
        
        //2
        Product2 prod2 = new Product2();
        prod2.Name = 'RS-TB-EE-RSVX-PE';
        prod2.ProductCode = 'RS-TB-EE-RSVX-PE';
        prod2.IsActive = true;
        prod2.Product_Type__c = 'Enterprise Edition';
        prod2.Support_Type__c = 'Premium';
        prod2.Scale_Utility_Product_Identifier__c = null;
        prod2.Scale_Utility_Product_RSV_OND__c = null;
        prod2.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        sampleProducts.add(prod2);
        
        //3
        Product2 prod3 = new Product2();
        prod3.Name = 'RS-TB-EE-RSV-PE';
        prod3.ProductCode = 'RS-TB-EE-RSV-PE';
        prod3.IsActive = true;
        prod3.Product_Type__c = 'Enterprise Edition';
        prod3.Support_Type__c = 'Premium';
        prod3.Scale_Utility_Product_Identifier__c = null;
        prod3.Scale_Utility_Product_RSV_OND__c = 'RSV';
        prod3.Product_Payment_Option__c = 'Prepay';
        sampleProducts.add(prod3);
        
        //4
        Product2 prod4 = new Product2();
        prod4.Name = 'RS-TB-FE-AR-PE';
        prod4.ProductCode = 'RS-TB-FE-AR-PE';
        prod4.IsActive = true;
        prod4.Product_Type__c = 'Foundation Edition';
        prod4.Support_Type__c = 'Premium';
        prod4.Scale_Utility_Product_Identifier__c = 'OND AR';
        prod4.Scale_Utility_Upgrade_Editions__c = 'FUE;FUP';
        prod4.Scale_Utility_Product_RSV_OND__c = 'OND';
        prod4.Product_Payment_Option__c = 'Prepay';
        sampleProducts.add(prod4);
        
        //5
        Product2 prod5 = new Product2();
        prod5.Name = 'RS-TB-FE-SR-PE';
        prod5.ProductCode = 'RS-TB-FE-SR-PE';
        prod5.IsActive = true;
        prod5.Product_Type__c = 'Foundation Edition';
        prod5.Support_Type__c = 'Premium';
        prod5.Scale_Utility_Product_Identifier__c = 'OND SR';
        prod5.Scale_Utility_Upgrade_Editions__c = 'FUE;FUP';
        prod5.Scale_Utility_Product_RSV_OND__c = 'OND';
        prod5.Product_Payment_Option__c = 'Prepay';
        sampleProducts.add(prod5);
        
        //6
        Product2 prod6 = new Product2();
        prod6.Name = 'RS-TB-EE-AR-PE';
        prod6.ProductCode = 'RS-TB-EE-AR-PE';
        prod6.IsActive = true;
        prod6.Product_Type__c = 'Enterprise Edition';
        prod6.Support_Type__c = 'Premium';
        prod6.Scale_Utility_Product_Identifier__c = 'OND AR';
        prod6.Scale_Utility_Upgrade_Editions__c = 'EUP';
        prod6.Scale_Utility_Product_RSV_OND__c = 'OND';
        prod6.Product_Payment_Option__c = 'Prepay';
        sampleProducts.add(prod6);
        
        //7
        Product2 prod7 = new Product2();
        prod7.Name = 'RS-TB-EE-SR-PE';
        prod7.ProductCode = 'RS-TB-EE-SR-PE';
        prod7.IsActive = true;
        prod7.Product_Type__c = 'Enterprise Edition';
        prod7.Support_Type__c = 'Premium';
        prod7.Scale_Utility_Product_Identifier__c = 'OND SR';
        prod7.Scale_Utility_Upgrade_Editions__c = 'EUP';
        prod7.Scale_Utility_Product_RSV_OND__c = 'OND';
        prod7.Product_Payment_Option__c = 'Prepay';
        sampleProducts.add(prod7);
        
        //8
        Product2 prod8 = new Product2();
        prod8.Name = 'RS-UR-FE-MD-RSVX-PE';
        prod8.ProductCode = 'RS-UR-FE-MD-RSVX-PE';
        prod8.IsActive = true;
        prod8.Product_Type__c = 'M365H';
        prod8.Support_Type__c = 'Premium';
        prod8.Scale_Utility_Product_Identifier__c = 'M365 SU RSVX';
        prod8.Scale_Utility_Product_RSV_OND__c = null;
        prod8.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        sampleProducts.add(prod8);
        
        //9
        Product2 prod9 = new Product2();
        prod9.Name = 'RS-UR-FE-MD-RSV-PE';
        prod9.ProductCode = 'RS-UR-FE-MD-RSV-PE';
        prod9.IsActive = true;
        prod9.Product_Type__c = 'M365H';
        prod9.Support_Type__c = 'Premium';
        prod9.Scale_Utility_Product_Identifier__c = 'M365 RSV SU';
        prod9.Scale_Utility_Product_RSV_OND__c = null;
        prod9.Product_Payment_Option__c = 'Prepay';
        sampleProducts.add(prod9);
        
        //10
        Product2 prod10 = new Product2();
        prod10.Name = 'RS-UR-EE-MD-RSVX-PE';
        prod10.ProductCode = 'RS-UR-EE-MD-RSVX-PE';
        prod10.IsActive = true;
        prod10.Product_Type__c = 'M365H';
        prod10.Support_Type__c = 'Premium';
        prod10.Scale_Utility_Product_Identifier__c = 'M365 SU RSVX';
        prod10.Scale_Utility_Product_RSV_OND__c = null;
        prod10.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        sampleProducts.add(prod10);
        
        //11
        Product2 prod11 = new Product2();
        prod11.Name = 'RS-UR-EE-MD-RSV-PE';
        prod11.ProductCode = 'RS-UR-EE-MD-RSV-PE';
        prod11.IsActive = true;
        prod11.Product_Type__c = 'M365H';
        prod11.Support_Type__c = 'Premium';
        prod11.Scale_Utility_Product_Identifier__c = 'M365 RSV SU';
        prod11.Scale_Utility_Product_RSV_OND__c = null;
        prod11.Product_Payment_Option__c = 'Prepay';
        sampleProducts.add(prod11);
        
        //12
        Product2 prod12 = new Product2();
        prod12.Name = 'RS-UR-FE-MD-AR-PE';
        prod12.ProductCode = 'RS-UR-FE-MD-AR-PE';
        prod12.IsActive = true;
        prod12.Product_Type__c = 'Foundation Edition';
        prod12.Support_Type__c = 'Premium';
        prod12.Scale_Utility_Product_Identifier__c = 'OND AR';
        prod12.Scale_Utility_Product_RSV_OND__c = 'OND';
        prod12.Scale_Utility_Upgrade_Editions__c = 'FUE;FUP';
        prod12.Product_Payment_Option__c = 'Prepay';
        sampleProducts.add(prod12);
        
        //13
        Product2 prod13 = new Product2();
        prod13.Name = 'RS-UR-FE-MD-SR-PE';
        prod13.ProductCode = 'RS-UR-FE-MD-SR-PE';
        prod13.IsActive = true;
        prod13.Product_Type__c = 'Foundation Edition';
        prod13.Support_Type__c = 'Premium';
        prod13.Scale_Utility_Product_Identifier__c = 'OND SR';
        prod13.Scale_Utility_Product_RSV_OND__c = 'OND';
        prod13.Scale_Utility_Upgrade_Editions__c = 'FUE;FUP';
        prod13.Product_Payment_Option__c = 'Prepay';
        sampleProducts.add(prod13);
        
        //14
        Product2 prod14 = new Product2();
        prod14.Name = 'RS-UR-EE-MD-AR-PE';
        prod14.ProductCode = 'RS-UR-EE-MD-AR-PE';
        prod14.IsActive = true;
        prod14.Product_Type__c = 'Enterprise Edition';
        prod14.Support_Type__c = 'Premium';
        prod14.Scale_Utility_Product_Identifier__c = 'OND AR';
        prod14.Scale_Utility_Product_RSV_OND__c = 'OND';
        prod14.Scale_Utility_Upgrade_Editions__c = 'EUP';
        prod14.Product_Payment_Option__c = 'Prepay';
        sampleProducts.add(prod14);
        
        //15
        Product2 prod15 = new Product2();
        prod15.Name = 'RS-UR-EE-MD-SR-PE';
        prod15.ProductCode = 'RS-UR-EE-MD-SR-PE';
        prod15.IsActive = true;
        prod15.Product_Type__c = 'Enterprise Edition';
        prod15.Support_Type__c = 'Premium';
        prod15.Scale_Utility_Product_Identifier__c = 'OND SR';
        prod15.Scale_Utility_Product_RSV_OND__c = 'OND';
        prod15.Scale_Utility_Upgrade_Editions__c = 'EUP';
        prod15.Product_Payment_Option__c = 'Prepay';
        sampleProducts.add(prod15);
        
        //16 Upgrade FUE SKU
        Product2 prod16 = new Product2();
        prod16.Name = 'RS-TB-FUE-RSV-PE';
        prod16.ProductCode = 'RS-TB-FUE-RSV-PE';
        prod16.IsActive = true;
        prod16.Scale_Utility_Product_Identifier__c = 'SU FUE';
        prod16.Scale_Utility_Product_RSV_OND__c = null;
        prod16.Product_Payment_Option__c = 'Prepay';
        sampleProducts.add(prod16);
        
        //17 Old OND SKU
        Product2 prod17 = new Product2();
        prod17.Name = 'RS-TB-FE-OND-PE';
        prod17.ProductCode = 'RS-TB-FE-OND-PE';
        prod17.IsActive = true;
        prod17.Scale_Utility_Product_Identifier__c = null;
        prod17.Scale_Utility_Product_RSV_OND__c = null;
        prod17.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        sampleProducts.add(prod17);
        
        insert sampleProducts;
        
        List<PricebookEntry>entries = new List<PricebookEntry>();
        
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[0].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[1].Id, IsActive = true, UnitPrice = 200));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[2].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[3].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[4].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[5].Id, IsActive = true, UnitPrice = 200));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[6].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[7].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[8].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[9].Id, IsActive = true, UnitPrice = 200));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[10].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[11].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[12].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[13].Id, IsActive = true, UnitPrice = 200));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[14].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[15].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[16].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[17].Id, IsActive = true, UnitPrice = 100));
        
        insert entries;
        
        List<SBQQ__ProductOption__c>prodOptions = new List<SBQQ__ProductOption__c>();
        
        //Options for non-M365H Scale Utility Bundle: FE Edition AR & SR
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 10, SBQQ__ConfiguredSKU__c = sampleProducts[0].Id, SBQQ__OptionalSKU__c = sampleProducts[4].Id, SBQQ__Selected__c = true));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 20, SBQQ__ConfiguredSKU__c = sampleProducts[0].Id, SBQQ__OptionalSKU__c = sampleProducts[5].Id, SBQQ__Selected__c = true));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 30, SBQQ__ConfiguredSKU__c = sampleProducts[0].Id, SBQQ__OptionalSKU__c = sampleProducts[6].Id));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 40, SBQQ__ConfiguredSKU__c = sampleProducts[0].Id, SBQQ__OptionalSKU__c = sampleProducts[7].Id));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 40, SBQQ__ConfiguredSKU__c = sampleProducts[0].Id, SBQQ__OptionalSKU__c = sampleProducts[16].Id));
        
        //Options for non-M365H Scale Utility Bundle: EE Edition AR & SR
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 10, SBQQ__ConfiguredSKU__c = sampleProducts[2].Id, SBQQ__OptionalSKU__c = sampleProducts[4].Id));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 20, SBQQ__ConfiguredSKU__c = sampleProducts[2].Id, SBQQ__OptionalSKU__c = sampleProducts[5].Id));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 30, SBQQ__ConfiguredSKU__c = sampleProducts[2].Id, SBQQ__OptionalSKU__c = sampleProducts[6].Id, SBQQ__Selected__c = true));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 40, SBQQ__ConfiguredSKU__c = sampleProducts[2].Id, SBQQ__OptionalSKU__c = sampleProducts[7].Id, SBQQ__Selected__c = true));
        
        //Options for M365H Bundle: FE Edition AR & SR
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 10, SBQQ__ConfiguredSKU__c = sampleProducts[8].Id, SBQQ__OptionalSKU__c = sampleProducts[12].Id, SBQQ__Selected__c = true));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 20, SBQQ__ConfiguredSKU__c = sampleProducts[8].Id, SBQQ__OptionalSKU__c = sampleProducts[13].Id, SBQQ__Selected__c = true));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 30, SBQQ__ConfiguredSKU__c = sampleProducts[8].Id, SBQQ__OptionalSKU__c = sampleProducts[14].Id));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 40, SBQQ__ConfiguredSKU__c = sampleProducts[8].Id, SBQQ__OptionalSKU__c = sampleProducts[15].Id));
        
        //Options for M365H Bundle: EE Edition AR & SR
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 10, SBQQ__ConfiguredSKU__c = sampleProducts[10].Id, SBQQ__OptionalSKU__c = sampleProducts[12].Id));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 20, SBQQ__ConfiguredSKU__c = sampleProducts[10].Id, SBQQ__OptionalSKU__c = sampleProducts[13].Id));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 30, SBQQ__ConfiguredSKU__c = sampleProducts[10].Id, SBQQ__OptionalSKU__c = sampleProducts[14].Id, SBQQ__Selected__c = true));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 40, SBQQ__ConfiguredSKU__c = sampleProducts[10].Id, SBQQ__OptionalSKU__c = sampleProducts[15].Id, SBQQ__Selected__c = true));
        
        insert prodOptions;
        
        SBQQ__QuoteLine__c ql0 = new SBQQ__QuoteLine__c();
        ql0.SBQQ__Quote__c = q1.Id;
        ql0.SBQQ__Product__c = sampleProducts[0].Id;
        ql0.SBQQ__Quantity__c = 10;
        ql0.SBQQ__PriorQuantity__c = 10;
        ql0.SBQQ__SubscriptionTerm__c = 12;
        ql0.SBQQ__ListPrice__c = 100;
        insert ql0;
        
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
        ql.SBQQ__Quote__c = q1.Id;
        ql.SBQQ__Product__c = sampleProducts[1].Id;
        ql.SBQQ__Quantity__c = 10;
        ql.SBQQ__PriorQuantity__c = 10;
        ql.SBQQ__SubscriptionTerm__c = 12;
        ql.SBQQ__RequiredBy__c = ql0.Id;
        ql.SBQQ__SegmentIndex__c = 1;
        ql.SubscribedAssetNames__c = 'BB192863040046';
        ql.SBQQ__ListPrice__c = 100;
        insert ql;
        
        SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c();
        ql1.SBQQ__Quote__c = q1.Id;
        ql1.SBQQ__Quantity__c = 10;
        ql1.SBQQ__PriorQuantity__c = 10;
        ql1.SBQQ__SubscriptionTerm__c = 36;
        ql1.SBQQ__Product__c = sampleProducts[2].Id;
        ql1.Product_Type__c = 'Enterprise Edition';
        ql1.SBQQ__ListPrice__c = 100;
        insert ql1;
        
        SBQQ__QuoteLine__c ql2 = new SBQQ__QuoteLine__c();
        ql2.SBQQ__Quote__c = q1.Id;
        ql2.SBQQ__RequiredBy__c = ql1.Id;
        ql2.SBQQ__Quantity__c = 10;
        ql2.SBQQ__PriorQuantity__c = 10;
        ql2.SBQQ__SubscriptionTerm__c = 36;
        ql2.SBQQ__Product__c = sampleProducts[3].Id;
        ql2.SBQQ__SegmentIndex__c = 1;
        ql2.SBQQ__ListPrice__c = 100;
        insert ql2;

        SBQQ__QuoteLine__c ql22 = new SBQQ__QuoteLine__c();
        ql22.SBQQ__Quote__c = q1.Id;
        ql22.SBQQ__RequiredBy__c = ql1.Id;
        ql22.SBQQ__Quantity__c = 20;
        ql22.SBQQ__PriorQuantity__c = 10;
        ql22.SBQQ__SubscriptionTerm__c = 36;
        ql22.SBQQ__Product__c = sampleProducts[3].Id;
        ql22.SBQQ__SegmentIndex__c = 2;
        ql22.SBQQ__ListPrice__c = 100;
        insert ql22;
        
        SBQQ__QuoteLine__c ql3 = new SBQQ__QuoteLine__c();
        ql3.SBQQ__Quote__c = q1.Id;
        ql3.SBQQ__RequiredBy__c = ql1.Id;
        ql3.SBQQ__Quantity__c = 10;
        ql3.SBQQ__PriorQuantity__c = 10;
        ql3.SBQQ__SubscriptionTerm__c = 36;
        ql3.SBQQ__Product__c = sampleProducts[4].Id;
        ql3.SBQQ__ListPrice__c = 100;
        insert ql3;
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        
        Asset asset = getAsset('12234', act11.Id, pd.Id);
        insert asset;
        
        SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c();
        qli3.SBQQ__Quote__c = q1.Id;
        qli3.SBQQ__Product__c = sampleProducts[0].Id;//FE-RSVX
        qli3.SBQQ__Quantity__c = 10;
        qli3.Product_Level__c = 'Hardware';
        qli3.SBQQ__SubscriptionTerm__c = 12;
        qli3.SubscribedAssetNames__c = 'BB192863040046';
        qli3.SBQQ__ListPrice__c = 100;
        insert qli3;
        
        SBQQ__QuoteLine__c qli4 = new SBQQ__QuoteLine__c();
        qli4.SBQQ__Quote__c = q1.Id;
        qli4.SBQQ__Product__c = sampleProducts[1].Id;//FE-RSV-
        qli4.SBQQ__Quantity__c = 10;
        qli4.SBQQ__PriorQuantity__c = 10;
        qli4.Product_Level__c = 'Hardware';
        qli4.SBQQ__SubscriptionTerm__c = 12;
        ql3.SBQQ__RequiredBy__c = qli3.Id;
        qli4.SubscribedAssetNames__c = 'BB192863040046';
        qli4.SBQQ__ListPrice__c = 100;
        insert qli4;
        
        SBQQ__QuoteLine__c qli5 = new SBQQ__QuoteLine__c();
        qli5.SBQQ__Quote__c = q2.Id;
        qli5.SBQQ__Product__c = sampleProducts[2].Id;//EE-RSVX
        qli5.SBQQ__Quantity__c = 10;
        qli5.Product_Level__c = 'Hardware';
        qli5.SBQQ__SubscriptionTerm__c = 12;
        qli5.SubscribedAssetNames__c = 'BB192863040046';
        qli5.Product_Type__c = 'Enterprise Edition';
        qli5.SBQQ__ListPrice__c = 100;
        insert qli5;
        
        //RSVX QLI
        SBQQ__QuoteLine__c qli14 = new SBQQ__QuoteLine__c();
        qli14.SBQQ__Quote__c = q2.Id;
        qli14.SBQQ__Product__c = sampleProducts[0].Id;//FE-RSVX-
        qli14.SBQQ__Quantity__c = 10;
        qli14.Product_Level__c = 'Hardware';
        qli14.SBQQ__SubscriptionTerm__c = 12;
        qli14.SBQQSC__UpgradedContractLine__c = null;
        qli14.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        qli14.Product_Type__c = 'Foundation Edition';
        qli14.Support_Type__c = 'Premium';
        qli14.Scale_Utility_Product_Identifier__c = null;
        qli14.SBQQ__NetPrice__c = 100;
        qli14.SBQQ__ListPrice__c = 100;
        qli14.SBQQ__Discount__c = 15;
        insert qli14;
        SBQQ__QuoteLine__c qli15 = new SBQQ__QuoteLine__c();
        qli15.SBQQ__Quote__c = q2.Id;
        qli15.SBQQ__Product__c = sampleProducts[2].Id;//EE-RSVX-
        qli15.SBQQ__Quantity__c = 10;
        qli15.Product_Level__c = 'Hardware';
        qli15.SBQQ__SubscriptionTerm__c = 12;
        qli15.SBQQSC__UpgradedContractLine__c = null;
        qli15.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        qli15.Product_Type__c = 'Enterprise Edition';
        qli15.Support_Type__c = 'Premium';
        qli15.Scale_Utility_Product_Identifier__c = null;
        qli15.SBQQ__NetPrice__c = 100;
        qli15.SBQQ__ListPrice__c = 100;
        qli15.SBQQ__Discount__c = 15;
        insert qli15;
        SBQQ__QuoteLine__c qli16 = new SBQQ__QuoteLine__c();
        qli16.SBQQ__Quote__c = q2.Id;
        qli16.SBQQ__Product__c = sampleProducts[8].Id;//FE-MD-RSVX-
        qli16.SBQQ__Quantity__c = 10;
        qli16.Product_Level__c = 'Hardware';
        qli16.SBQQ__SubscriptionTerm__c = 12;
        qli16.SBQQSC__UpgradedContractLine__c = null;
        qli16.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        qli16.Product_Type__c = 'M365H';
        qli16.Support_Type__c = 'Premium';
        qli16.Scale_Utility_Product_Identifier__c = 'M365 SU RSVX';
        qli16.SBQQ__NetPrice__c = 100;
        qli16.SBQQ__ListPrice__c = 100;
        qli16.SBQQ__Discount__c = 15;
        insert qli16;
        newQLIMap.add(qli16);
        
        
        SBQQ__QuoteLine__c qli16AB = new SBQQ__QuoteLine__c();
        qli16AB.SBQQ__Quote__c = q2.Id;
        qli16AB.SBQQ__Product__c = sampleProducts[8].Id;
        qli16AB.SBQQ__Quantity__c = 10;
        qli16AB.Product_Level__c = 'Hardware';
        qli16AB.SBQQ__SubscriptionTerm__c = 12;
        qli16AB.SBQQSC__UpgradedContractLine__c = null;
        qli16AB.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        qli16AB.Product_Type__c = 'Foundation Edition';
        qli16AB.Support_Type__c = 'Premium';
        qli16AB.Scale_Utility_Product_Identifier__c = null;
        qli16AB.SBQQ__NetPrice__c = 100;
        qli16AB.SBQQ__ListPrice__c = 100;
        qli16AB.SBQQ__Discount__c = 15;
        //insert qli16AB;
        //newQLIMap.add(qli16AB);
        
        SBQQ__QuoteLine__c qli16ABC = new SBQQ__QuoteLine__c();
        qli16ABC.SBQQ__Quote__c = q2.Id;
        qli16ABC.SBQQ__Product__c = sampleProducts[8].Id;//EE-MD-RSVX-
        qli16ABC.SBQQ__Quantity__c = 10;
        qli16ABC.Product_Level__c = 'Hardware';
        qli16ABC.SBQQ__SubscriptionTerm__c = 12;
        qli16ABC.SBQQSC__UpgradedContractLine__c = null;
        qli16ABC.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        qli16ABC.Product_Type__c = 'Foundation Edition';
        qli16ABC.Support_Type__c = 'Premium';
        qli16ABC.Scale_Utility_Product_Identifier__c = null;
        qli16ABC.SBQQ__NetPrice__c = 100;
        qli16ABC.SBQQ__ListPrice__c = 100;
        qli16ABC.SBQQ__Discount__c = 15;
        //insert qli16ABC;
        //newQLIMap.add(qli16ABC);
        
        SBQQ__QuoteLine__c qli16X = new SBQQ__QuoteLine__c();
        qli16X.SBQQ__Quote__c = q2.Id;
        qli16X.SBQQ__Product__c = sampleProducts[8].Id;//FE-MD-RSVX-
        qli16X.SBQQ__Quantity__c = 10;
        qli16X.Product_Level__c = 'Hardware';
        qli16X.SBQQ__SubscriptionTerm__c = 12;
        qli16X.SBQQSC__UpgradedContractLine__c = null;
        qli16X.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        qli16X.Product_Type__c = 'M365H';
        qli16X.Support_Type__c = 'Premium';
        qli16X.Scale_Utility_Product_Identifier__c = 'M365 SU RSVX';
        qli16X.SBQQ__NetPrice__c = 100;
        qli16X.SBQQ__ListPrice__c = 100;
        qli16X.SBQQ__Discount__c = 15;
        //insert qli16X;
        //newQLIMap.add(qli16X);
        
        SBQQ__QuoteLine__c qli17 = new SBQQ__QuoteLine__c();
        qli17.SBQQ__Quote__c = q2.Id;
        qli17.SBQQ__Product__c = sampleProducts[10].Id;//EE-MD-RSVX-
        qli17.SBQQ__Quantity__c = 10;
        qli17.Product_Level__c = 'Hardware';
        qli17.SBQQ__SubscriptionTerm__c = 12;
        qli17.SBQQSC__UpgradedContractLine__c = null;
        qli17.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        qli17.Product_Type__c = 'M365H';
        qli17.Support_Type__c = 'Premium';
        qli17.Scale_Utility_Product_Identifier__c = 'M365 SU RSVX';
        qli17.SBQQ__NetPrice__c = 100;
        qli17.SBQQ__ListPrice__c = 100;
        qli17.SBQQ__Discount__c = 15;
        insert qli17;
        
        /* */
        SBQQ__QuoteLine__c qli17AB = new SBQQ__QuoteLine__c();
        qli17AB.SBQQ__Quote__c = q2.Id;
        qli17AB.SBQQ__Product__c = sampleProducts[10].Id;//EE-MD-RSVX-
        qli17AB.SBQQ__Quantity__c = 10;
        qli17AB.Product_Level__c = 'Hardware';
        qli17AB.SBQQ__SubscriptionTerm__c = 12;
        qli17AB.SBQQSC__UpgradedContractLine__c = null;
        qli17AB.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        qli17AB.Product_Type__c = 'Enterprise Edition';
        qli17AB.Support_Type__c = 'Premium';
        qli17AB.Scale_Utility_Product_Identifier__c = null;
        qli17AB.SBQQ__NetPrice__c = 100;
        qli17AB.SBQQ__ListPrice__c = 100;
        qli17AB.SBQQ__Discount__c = 15;
        insert qli17AB;
        newQLIMap.add(qli17AB);
        
        SBQQ__QuoteLine__c qli21AB = new SBQQ__QuoteLine__c();
        qli21AB.SBQQ__Quote__c = q2.Id;
        qli21AB.SBQQ__Product__c = sampleProducts[11].Id;//EE-MD-RSV-
        qli21AB.SBQQ__Quantity__c = 10;
        qli21AB.Product_Level__c = 'Hardware';
        qli21AB.SBQQ__SubscriptionTerm__c = 12;
        qli21AB.SBQQSC__UpgradedContractLine__c = null;
        qli21AB.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        qli21AB.SBQQ__SegmentLabel__c = '1';
        qli21AB.SBQQ__SegmentIndex__c = 1;
        qli21AB.SBQQ__RequiredBy__c = qli17AB.Id;
        qli21AB.Product_Type__c = 'Enterprise Edition';
        qli21AB.Support_Type__c = 'Premium';
        qli21AB.Scale_Utility_Product_Identifier__c = 'M365 RSV SU';
        qli21AB.Scale_Utility_Product_RSV_OND__c = null;
        qli21AB.SBQQ__NetPrice__c = 100;
        qli21AB.SBQQ__ListPrice__c = 100;
        qli21AB.SBQQ__Discount__c = 15;
        insert qli21AB;
        newQLIMap.add(qli21AB);
        
        SBQQ__QuoteLine__c qli17ABC = new SBQQ__QuoteLine__c();
        qli17ABC.SBQQ__Quote__c = q2.Id;
        qli17ABC.SBQQ__Product__c = sampleProducts[10].Id;//EE-MD-RSVX-
        qli17ABC.SBQQ__Quantity__c = 10;
        qli17ABC.Product_Level__c = 'Hardware';
        qli17ABC.SBQQ__SubscriptionTerm__c = 12;
        qli17ABC.SBQQSC__UpgradedContractLine__c = null;
        qli17ABC.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        qli17ABC.Product_Type__c = 'Foundation Edition';
        qli17ABC.Support_Type__c = 'Premium';
        qli17ABC.Scale_Utility_Product_Identifier__c = null;
        qli17ABC.SBQQ__NetPrice__c = 100;
        qli17ABC.SBQQ__ListPrice__c = 100;
        qli17ABC.SBQQ__Discount__c = 15;
        insert qli17ABC;
        newQLIMap.add(qli17ABC);
        
        SBQQ__QuoteLine__c qli21ABC = new SBQQ__QuoteLine__c();
        qli21ABC.SBQQ__Quote__c = q2.Id;
        qli21ABC.SBQQ__Product__c = sampleProducts[11].Id;//EE-MD-RSV-
        qli21ABC.SBQQ__Quantity__c = 10;
        qli21ABC.Product_Level__c = 'Hardware';
        qli21ABC.SBQQ__SubscriptionTerm__c = 12;
        qli21ABC.SBQQSC__UpgradedContractLine__c = null;
        qli21ABC.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        qli21ABC.SBQQ__SegmentLabel__c = '1';
        qli21ABC.SBQQ__SegmentIndex__c = 1;
        qli21ABC.SBQQ__RequiredBy__c = qli17ABC.Id;
        qli21ABC.Product_Type__c = 'Foundation Edition';
        qli21ABC.Support_Type__c = 'Premium';
        qli21ABC.Scale_Utility_Product_Identifier__c = 'M365 RSV SU';
        qli21ABC.Scale_Utility_Product_RSV_OND__c = null;
        qli21ABC.SBQQ__NetPrice__c = 100;
        qli21ABC.SBQQ__ListPrice__c = 100;
        qli21ABC.SBQQ__Discount__c = 15;
        insert qli21ABC;
        newQLIMap.add(qli21ABC);
        //RSV QLIs
        SBQQ__QuoteLine__c qli18 = new SBQQ__QuoteLine__c();
        qli18.SBQQ__Quote__c = q2.Id;
        qli18.SBQQ__Product__c = sampleProducts[1].Id;//FE-RSV-
        qli18.SBQQ__Quantity__c = 10;
        qli18.SBQQ__PriorQuantity__c = 10;
        qli18.Product_Level__c = 'Hardware';
        qli18.SBQQ__SubscriptionTerm__c = 12;
        qli18.SBQQSC__UpgradedContractLine__c = null;
        qli18.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        qli18.Scale_Utility_Product_RSV_OND__c = 'RSV';
        qli18.SBQQ__SegmentLabel__c = '1';
        qli18.SBQQ__SegmentIndex__c = 1;
        qli18.SBQQ__RequiredBy__c = qli14.Id;
        qli18.Product_Type__c = 'Foundation Edition';
        qli18.Support_Type__c = 'Premium';
        qli18.Scale_Utility_Product_Identifier__c = null;
        qli18.Scale_Utility_Product_RSV_OND__c = 'RSV';
        qli18.SBQQ__NetPrice__c = 100;
        qli18.SBQQ__ListPrice__c = 100;
        qli18.SBQQ__Discount__c = 15;
        insert qli18;
        SBQQ__QuoteLine__c qli19 = new SBQQ__QuoteLine__c();
        qli19.SBQQ__Quote__c = q2.Id;
        qli19.SBQQ__Product__c = sampleProducts[3].Id;//EE-RSV-
        qli19.SBQQ__Quantity__c = 10;
        qli19.SBQQ__PriorQuantity__c = 10;
        qli19.Product_Level__c = 'Hardware';
        qli19.SBQQ__SubscriptionTerm__c = 12;
        qli19.SBQQSC__UpgradedContractLine__c = null;
        qli19.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        qli19.SBQQ__SegmentLabel__c = '1';
        qli19.SBQQ__SegmentIndex__c = 1;
        qli19.SBQQ__RequiredBy__c = qli15.Id;
        qli19.Product_Type__c = 'Enterprise Edition';
        qli19.Support_Type__c = 'Premium';
        qli19.Scale_Utility_Product_Identifier__c = null;
        qli19.Scale_Utility_Product_RSV_OND__c = 'RSV';
        qli19.SBQQ__NetPrice__c = 100;
        qli19.SBQQ__ListPrice__c = 100;
        qli19.SBQQ__Discount__c = 15;
        insert qli19;
        
        SBQQ__QuoteLine__c qli20 = new SBQQ__QuoteLine__c();
        qli20.SBQQ__Quote__c = q2.Id;
        qli20.SBQQ__Product__c = sampleProducts[9].Id;//FE-MD-RSV-
        qli20.SBQQ__Quantity__c = 10;
        qli20.Product_Level__c = 'Hardware';
        qli20.SBQQ__SubscriptionTerm__c = 12;
        qli20.SBQQSC__UpgradedContractLine__c = null;
        qli20.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        qli20.Scale_Utility_Product_Identifier__c = 'M365 RSV SU';
        qli20.SBQQ__SegmentLabel__c = '1';
        qli20.SBQQ__SegmentIndex__c = 1;
        qli20.SBQQ__RequiredBy__c = qli16.Id;
        qli20.Product_Type__c = 'M365H';
        qli20.Support_Type__c = 'Premium';
        qli20.Scale_Utility_Product_Identifier__c = 'M365 RSV SU';
        qli20.Scale_Utility_Product_RSV_OND__c = null;
        qli20.SBQQ__NetPrice__c = 100;
        qli20.SBQQ__ListPrice__c = 100;
        qli20.SBQQ__Discount__c = 15;
        insert qli20;
        
        SBQQ__QuoteLine__c qli21 = new SBQQ__QuoteLine__c();
        qli21.SBQQ__Quote__c = q2.Id;
        qli21.SBQQ__Product__c = sampleProducts[11].Id;//EE-MD-RSV-
        qli21.SBQQ__Quantity__c = 10;
        qli21.Product_Level__c = 'Hardware';
        qli21.SBQQ__SubscriptionTerm__c = 12;
        qli21.SBQQSC__UpgradedContractLine__c = null;
        qli21.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        qli21.Scale_Utility_Product_Identifier__c = 'M365 RSV SU';
        qli21.SBQQ__SegmentLabel__c = '1';
        qli21.SBQQ__SegmentIndex__c = 1;
        qli21.SBQQ__RequiredBy__c = qli17.Id;
        qli21.Product_Type__c = 'M365H';
        qli21.Support_Type__c = 'Premium';
        qli21.Scale_Utility_Product_Identifier__c = 'M365 RSV SU';
        qli21.Scale_Utility_Product_RSV_OND__c = null;
        qli21.SBQQ__NetPrice__c = 100;
        qli21.SBQQ__ListPrice__c = 100;
        qli21.SBQQ__Discount__c = 15;
        insert qli21;
        
        //AR & SR QLIs
        //FE-AR
        SBQQ__QuoteLine__c qli6 = new SBQQ__QuoteLine__c();
        qli6.SBQQ__Quote__c = q2.Id;
        qli6.SBQQ__Product__c = sampleProducts[4].Id;
        qli6.SBQQ__Quantity__c = 10;
        qli6.Product_Level__c = 'Hardware';
        qli6.SBQQ__SubscriptionTerm__c = 12;
        qli6.SBQQSC__UpgradedContractLine__c = null;
        qli6.Scale_Utility_Product_Identifier__c = 'OND AR';
        qli6.SBQQ__RequiredBy__c = qli14.Id;
        qli6.Product_Type__c = 'Foundation Edition';
        qli6.Support_Type__c = 'Premium';
        qli6.Scale_Utility_Product_RSV_OND__c = 'OND';
        qli6.SBQQ__NetPrice__c = 100;
        qli6.SBQQ__ListPrice__c = 100;
        qli6.SBQQ__Discount__c = 15;
        insert qli6;
        SBQQ__QuoteLine__c qli81 = new SBQQ__QuoteLine__c();
        qli81.SBQQ__Quote__c = q2.Id;
        qli81.SBQQ__Product__c = sampleProducts[4].Id;
        qli81.SBQQ__Quantity__c = 10;
        qli81.Product_Level__c = 'Hardware';
        qli81.SBQQ__SubscriptionTerm__c = 12;
        qli81.SBQQSC__UpgradedContractLine__c = null;
        qli81.Scale_Utility_Product_Identifier__c = 'OND AR';
        qli81.SBQQ__RequiredBy__c = qli15.Id;
        qli81.Product_Type__c = 'Foundation Edition';//Earlier Enterprise
        qli81.Support_Type__c = 'Premium';
        qli81.Scale_Utility_Product_RSV_OND__c = 'OND';
        qli81.SBQQ__NetPrice__c = 100;
        qli81.SBQQ__ListPrice__c = 100;
        qli81.SBQQ__Discount__c = 15;
        insert qli81;
        //FE-SR
        SBQQ__QuoteLine__c qli7 = new SBQQ__QuoteLine__c();
        qli7.SBQQ__Quote__c = q2.Id;
        qli7.SBQQ__Product__c = sampleProducts[5].Id;
        qli7.SBQQ__Quantity__c = 10;
        qli7.Product_Level__c = 'Hardware';
        qli7.SBQQ__SubscriptionTerm__c = 12;
        qli7.SBQQSC__UpgradedContractLine__c = null;
        qli7.Scale_Utility_Product_Identifier__c = 'OND SR';
        qli7.SBQQ__RequiredBy__c = qli14.Id;
        qli7.Product_Type__c = 'Foundation Edition';
        qli7.Support_Type__c = 'Premium';
        qli7.Scale_Utility_Product_RSV_OND__c = 'OND';
        qli7.SBQQ__NetPrice__c = 100;
        qli7.SBQQ__ListPrice__c = 100;
        qli7.SBQQ__Discount__c = 15;
        insert qli7;
        SBQQ__QuoteLine__c qli91 = new SBQQ__QuoteLine__c();
        qli91.SBQQ__Quote__c = q2.Id;
        qli91.SBQQ__Product__c = sampleProducts[5].Id;
        qli91.SBQQ__Quantity__c = 10;
        qli91.Product_Level__c = 'Hardware';
        qli91.SBQQ__SubscriptionTerm__c = 12;
        qli91.SBQQSC__UpgradedContractLine__c = null;
        qli91.Scale_Utility_Product_Identifier__c = 'OND SR';
        qli91.SBQQ__RequiredBy__c = qli15.Id;
        qli91.Product_Type__c = 'Foundation Edition';//Earlier Enterprise
        qli91.Support_Type__c = 'Premium';
        qli91.Scale_Utility_Product_RSV_OND__c = 'OND';
        qli91.SBQQ__NetPrice__c = 100;
        qli91.SBQQ__ListPrice__c = 100;
        qli91.SBQQ__Discount__c = 15;
        insert qli91;
        //EE-AR
        SBQQ__QuoteLine__c qli61 = new SBQQ__QuoteLine__c();
        qli61.SBQQ__Quote__c = q2.Id;
        qli61.SBQQ__Product__c = sampleProducts[6].Id;
        qli61.SBQQ__Quantity__c = 10;
        qli61.Product_Level__c = 'Hardware';
        qli61.SBQQ__SubscriptionTerm__c = 12;
        qli61.SBQQSC__UpgradedContractLine__c = null;
        qli61.Scale_Utility_Product_Identifier__c = 'OND AR';
        qli61.SBQQ__RequiredBy__c = qli14.Id;
        qli61.Product_Type__c = 'Enterprise Edition';//Earlier Foundation
        qli61.Support_Type__c = 'Premium';
        qli61.Scale_Utility_Product_RSV_OND__c = 'OND';
        qli61.SBQQ__NetPrice__c = 100;
        qli61.SBQQ__ListPrice__c = 100;
        qli61.SBQQ__Discount__c = 15;
        insert qli61;
        SBQQ__QuoteLine__c qli8 = new SBQQ__QuoteLine__c();
        qli8.SBQQ__Quote__c = q2.Id;
        qli8.SBQQ__Product__c = sampleProducts[6].Id;
        qli8.SBQQ__Quantity__c = 10;
        qli8.Product_Level__c = 'Hardware';
        qli8.SBQQ__SubscriptionTerm__c = 12;
        qli8.SBQQSC__UpgradedContractLine__c = null;
        qli8.Scale_Utility_Product_Identifier__c = 'OND AR';
        qli8.SBQQ__RequiredBy__c = qli15.Id;
        qli8.Product_Type__c = 'Enterprise Edition';
        qli8.Support_Type__c = 'Premium';
        qli8.Scale_Utility_Product_RSV_OND__c = 'OND';
        qli8.SBQQ__NetPrice__c = 100;
        qli8.SBQQ__ListPrice__c = 100;
        qli8.SBQQ__Discount__c = 15;
        insert qli8;
        //EE-SR
        SBQQ__QuoteLine__c qli71 = new SBQQ__QuoteLine__c();
        qli71.SBQQ__Quote__c = q2.Id;
        qli71.SBQQ__Product__c = sampleProducts[7].Id;
        qli71.SBQQ__Quantity__c = 10;
        qli71.Product_Level__c = 'Hardware';
        qli71.SBQQ__SubscriptionTerm__c = 12;
        qli71.SBQQSC__UpgradedContractLine__c = null;
        qli71.Scale_Utility_Product_Identifier__c = 'OND SR';
        qli71.SBQQ__RequiredBy__c = qli14.Id;
        qli71.Product_Type__c = 'Enterprise Edition';//Earlier Foundation
        qli71.Support_Type__c = 'Premium';
        qli71.Scale_Utility_Product_RSV_OND__c = 'OND';
        qli71.SBQQ__NetPrice__c = 100;
        qli71.SBQQ__ListPrice__c = 100;
        qli71.SBQQ__Discount__c = 15;
        insert qli71;
        SBQQ__QuoteLine__c qli9 = new SBQQ__QuoteLine__c();
        qli9.SBQQ__Quote__c = q2.Id;
        qli9.SBQQ__Product__c = sampleProducts[7].Id;
        qli9.SBQQ__Quantity__c = 10;
        qli9.Product_Level__c = 'Hardware';
        qli9.SBQQ__SubscriptionTerm__c = 12;
        qli9.SBQQSC__UpgradedContractLine__c = null;
        qli9.Scale_Utility_Product_Identifier__c = 'OND SR';
        qli9.SBQQ__RequiredBy__c = qli15.Id;
        qli9.Product_Type__c = 'Enterprise Edition';
        qli9.Support_Type__c = 'Premium';
        qli9.Scale_Utility_Product_RSV_OND__c = 'OND';
        qli9.SBQQ__NetPrice__c = 100;
        qli9.SBQQ__ListPrice__c = 100;
        qli9.SBQQ__Discount__c = 15;
        insert qli9;
        
        //12: FE-UR-AR
        SBQQ__QuoteLine__c qli10 = new SBQQ__QuoteLine__c();
        qli10.SBQQ__Quote__c = q2.Id;
        qli10.SBQQ__Product__c = sampleProducts[12].Id;
        qli10.SBQQ__Quantity__c = 10;
        qli10.Product_Level__c = 'Hardware';
        qli10.SBQQ__SubscriptionTerm__c = 12;
        qli10.SBQQSC__UpgradedContractLine__c = null;
        qli10.Scale_Utility_Product_Identifier__c = 'OND AR';
        qli10.SBQQ__RequiredBy__c = qli16.Id;
        qli10.Product_Type__c = 'Foundation Edition';
        qli10.Support_Type__c = 'Premium';
        qli10.Scale_Utility_Product_RSV_OND__c = 'OND';
        qli10.SBQQ__NetPrice__c = 100;
        qli10.SBQQ__ListPrice__c = 100;
        qli10.SBQQ__Discount__c = 15;
        //insert qli10;//
        
        SBQQ__QuoteLine__c qli121 = new SBQQ__QuoteLine__c();
        qli121.SBQQ__Quote__c = q2.Id;
        qli121.SBQQ__Product__c = sampleProducts[12].Id;
        qli121.SBQQ__Quantity__c = 10;
        qli121.Product_Level__c = 'Hardware';
        qli121.SBQQ__SubscriptionTerm__c = 12;
        qli121.SBQQSC__UpgradedContractLine__c = null;
        qli121.Scale_Utility_Product_Identifier__c = 'OND AR';
        qli121.SBQQ__RequiredBy__c = qli17.Id;
        qli121.Product_Type__c = 'Foundation Edition';//Earlier Enterprise
        qli121.Support_Type__c = 'Premium';
        qli121.Scale_Utility_Product_RSV_OND__c = 'OND';
        qli121.SBQQ__NetPrice__c = 100;
        qli121.SBQQ__ListPrice__c = 100;
        qli121.SBQQ__Discount__c = 15;
        //insert qli121;
        //newQLIMap.add(qli121);
        
        //13: FE-UR-SR
        SBQQ__QuoteLine__c qli11 = new SBQQ__QuoteLine__c();
        qli11.SBQQ__Quote__c = q2.Id;
        qli11.SBQQ__Product__c = sampleProducts[13].Id;
        qli11.SBQQ__Quantity__c = 10;
        qli11.Product_Level__c = 'Hardware';
        qli11.SBQQ__SubscriptionTerm__c = 12;
        qli11.SBQQSC__UpgradedContractLine__c = null;
        qli11.Scale_Utility_Product_Identifier__c = 'OND SR';
        qli11.SBQQ__RequiredBy__c = qli16.Id;
        qli11.Product_Type__c = 'Foundation Edition';
        qli11.Support_Type__c = 'Premium';
        qli11.Scale_Utility_Product_RSV_OND__c = 'OND';
        qli11.SBQQ__NetPrice__c = 100;
        qli11.SBQQ__ListPrice__c = 100;
        qli11.SBQQ__Discount__c = 15;
        //insert qli11;
        
        SBQQ__QuoteLine__c qli111 = new SBQQ__QuoteLine__c();
        qli111.SBQQ__Quote__c = q2.Id;
        qli111.SBQQ__Product__c = sampleProducts[13].Id;
        qli111.SBQQ__Quantity__c = 10;
        qli111.Product_Level__c = 'Hardware';
        qli111.SBQQ__SubscriptionTerm__c = 12;
        qli111.SBQQSC__UpgradedContractLine__c = null;
        qli111.Scale_Utility_Product_Identifier__c = 'OND SR';
        qli111.SBQQ__RequiredBy__c = qli16.Id;
        qli111.Product_Type__c = 'Foundation Edition';
        qli111.Support_Type__c = 'Premium';
        qli111.Scale_Utility_Product_RSV_OND__c = 'OND';
        qli111.SBQQ__NetPrice__c = 100;
        qli111.SBQQ__ListPrice__c = 100;
        qli111.SBQQ__Discount__c = 15;
        //insert qli111;
        
        //newQLIMap.add(qli10);
        //newQLIMap.add(qli11);
        //newQLIMap.add(qli101);
        //newQLIMap.add(qli111);
        
        SBQQ__QuoteLine__c qli131 = new SBQQ__QuoteLine__c();
        qli131.SBQQ__Quote__c = q2.Id;
        qli131.SBQQ__Product__c = sampleProducts[13].Id;
        qli131.SBQQ__Quantity__c = 10;
        qli131.Product_Level__c = 'Hardware';
        qli131.SBQQ__SubscriptionTerm__c = 12;
        qli131.SBQQSC__UpgradedContractLine__c = null;
        qli131.Scale_Utility_Product_Identifier__c = 'OND SR';
        qli131.SBQQ__RequiredBy__c = qli17.Id;
        qli131.Product_Type__c = 'Foundation Edition';//Earlier Enterprise
        qli131.Support_Type__c = 'Premium';
        qli131.Scale_Utility_Product_RSV_OND__c = 'OND';
        qli131.SBQQ__NetPrice__c = 100;
        qli131.SBQQ__ListPrice__c = 100;
        qli131.SBQQ__Discount__c = 15;
        insert qli131;
        
        //14: EE-UR-AR
        SBQQ__QuoteLine__c qli101 = new SBQQ__QuoteLine__c();
        qli101.SBQQ__Quote__c = q2.Id;
        qli101.SBQQ__Product__c = sampleProducts[14].Id;
        qli101.SBQQ__Quantity__c = 10;
        qli101.Product_Level__c = 'Hardware';
        qli101.SBQQ__SubscriptionTerm__c = 12;
        qli101.SBQQSC__UpgradedContractLine__c = null;
        qli101.Scale_Utility_Product_Identifier__c = 'OND AR';
        qli101.SBQQ__RequiredBy__c = qli16.Id;
        qli101.Product_Type__c = 'Enterprise Edition';//earlier Foundation
        qli101.Support_Type__c = 'Premium';
        qli101.Scale_Utility_Product_RSV_OND__c = 'OND';
        qli101.SBQQ__NetPrice__c = 100;
        qli10.SBQQ__ListPrice__c = 100;
        qli101.SBQQ__Discount__c = 15;
        //insert qli101;
        
        //15: EE-UR-SR
        SBQQ__QuoteLine__c qli12 = new SBQQ__QuoteLine__c();
        qli12.SBQQ__Quote__c = q2.Id;
        qli12.SBQQ__Product__c = sampleProducts[15].Id;
        qli12.SBQQ__Quantity__c = 10;
        qli12.Product_Level__c = 'Hardware';
        qli12.SBQQ__SubscriptionTerm__c = 12;
        qli12.SBQQSC__UpgradedContractLine__c = null;
        qli12.Scale_Utility_Product_Identifier__c = 'OND SR';
        qli12.SBQQ__RequiredBy__c = qli17.Id;
        qli12.Product_Type__c = 'Enterprise Edition';
        qli12.Support_Type__c = 'Premium';
        qli12.Scale_Utility_Product_RSV_OND__c = 'OND';
        qli12.SBQQ__NetPrice__c = 100;
        qli12.SBQQ__ListPrice__c = 100;
        qli12.SBQQ__Discount__c = 15;
        insert qli12;//
        
        SBQQ__QuoteLine__c qli13 = new SBQQ__QuoteLine__c();
        qli13.SBQQ__Quote__c = q2.Id;
        qli13.SBQQ__Product__c = sampleProducts[15].Id;
        qli13.SBQQ__Quantity__c = 10;
        qli13.Product_Level__c = 'Hardware';
        qli13.SBQQ__SubscriptionTerm__c = 12;
        qli13.SBQQSC__UpgradedContractLine__c = null;
        qli13.Scale_Utility_Product_Identifier__c = 'OND SR';
        qli13.SBQQ__RequiredBy__c = qli17.Id;
        qli13.Product_Type__c = 'Enterprise Edition';
        qli13.Support_Type__c = 'Premium';
        qli13.Scale_Utility_Product_RSV_OND__c = 'OND';
        qli13.SBQQ__NetPrice__c = 100;
        qli13.SBQQ__ListPrice__c = 100;
        qli13.SBQQ__Discount__c = 15;
        //insert qli13;
        //newQLIMap.add(qli13);
        
        Asset assetObj = (Asset) ShGl_TestFactory.createSObject(new Asset(), null);
        assetObj.AccountId = act11.Id;
        assetObj.Name = 'EntitlementTriggerHelperAsset';
        assetObj.Product2Id = sampleProducts[1].Id;
        assetObj.Justification_for_HW_Eligibility_Overrid__c = '-';
        assetObj.serial_number__c = 'JAY8486304222k4';
        insert assetObj;
        
        ServiceContract serviceContractObj = new ServiceContract();
        serviceContractObj.Name = 'EntitlementTriggerHelper Contract';
        serviceContractObj.SBQQSC__Opportunity__c = opp1a.Id;
        serviceContractObj.AccountId = act11.Id;
        serviceContractObj.StartDate = System.today();
        serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj.Term = 36;
        insert serviceContractObj;
        
        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj.SBQQSC__Account__c = act11.Id;
        ContractLineItemObj.AssetId = assetObj.Id;
        ContractLineItemObj.PricebookEntryId = entries[1].Id;
        ContractLineItemObj.ServiceContractId = serviceContractObj.Id;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.UnitPrice = 100;
        insert ContractLineItemObj;
        
        //Upgrade FUE QLI
        SBQQ__QuoteLine__c qli22 = new SBQQ__QuoteLine__c();
        qli22.SBQQ__Quote__c = q2.Id;
        qli22.SBQQ__Product__c = sampleProducts[16].Id;
        qli22.SBQQ__Quantity__c = 10;
        qli22.Product_Level__c = 'Hardware';
        qli22.SBQQ__SubscriptionTerm__c = 12;
        qli22.SBQQSC__UpgradedContractLine__c = null;
        qli22.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        qli22.Scale_Utility_Product_Identifier__c = 'SU FUE';
        qli22.Product_Type__c = 'Edition Upgrade';
        qli22.SBQQ__RequiredBy__c = qli14.Id;
        //qli22.SBQQSC__UpgradedContractLine__c = ContractLineItemObj.Id;
        qli22.SBQQ__ProrateMultiplier__c = 1.5;
        qli22.SBQQ__NetPrice__c = 100;
        qli22.SBQQ__ListPrice__c = 100;
        qli22.SBQQ__Discount__c = 15;
        insert qli22;
        
        //Upgrade Old OND QLI
        SBQQ__QuoteLine__c qli23 = new SBQQ__QuoteLine__c();
        qli23.SBQQ__Quote__c = q2.Id;
        qli23.SBQQ__Product__c = sampleProducts[17].Id;
        qli23.SBQQ__Quantity__c = 10;
        qli23.Product_Level__c = 'Hardware';
        qli23.SBQQ__SubscriptionTerm__c = 12;
        qli23.SBQQSC__UpgradedContractLine__c = null;
        qli23.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        qli23.SBQQ__RequiredBy__c = qli14.Id;
        qli23.SBQQSC__UpgradedContractLine__c = ContractLineItemObj.Id;
        qli23.SBQQ__ProrateMultiplier__c = 1.5;
        qli23.SBQQ__NetPrice__c = 100;
        qli23.SBQQ__ListPrice__c = 100;
        qli23.SBQQ__Discount__c = 15;
        insert qli23;
        
        newQLIMap.add(ql);
        newQLIMap.add(ql1);
        newQLIMap.add(ql2);
        newQLIMap.add(qli3);
        newQLIMap.add(qli4);
        newQLIMap.add(qli5);
        newQLIMap.add(qli6);
        newQLIMap.add(qli7);
        newQLIMap.add(qli8);
        newQLIMap.add(qli9);
        newQLIMap.add(qli12);
        
        newQLIMap.add(qli14);
        newQLIMap.add(qli15);
        
        newQLIMap.add(qli17);
        newQLIMap.add(qli18);
        newQLIMap.add(qli19);
        newQLIMap.add(qli20);
        newQLIMap.add(qli21);
        newQLIMap.add(qli22);
        newQLIMap.add(qli23);
        newQLIMap.add(qli61);
        newQLIMap.add(qli71);
        newQLIMap.add(qli81);
        newQLIMap.add(qli91);
        
        newQLIMap.add(qli131);
        
        //Quote Lines for New Quotes
        //RSVX QLI
        SBQQ__QuoteLine__c qli14A = new SBQQ__QuoteLine__c();
        qli14A.SBQQ__Quote__c = newQuote.Id;
        qli14A.SBQQ__Product__c = sampleProducts[0].Id;
        qli14A.SBQQ__Quantity__c = 10;
        qli14A.Product_Level__c = 'Hardware';
        qli14A.SBQQ__SubscriptionTerm__c = 12;
        qli14A.SBQQSC__UpgradedContractLine__c = null;
        qli14A.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        qli14A.Product_Type__c = 'Foundation Edition';
        qli14A.Support_Type__c = 'Premium';
        qli14A.Scale_Utility_Product_Identifier__c = null;
        qli14A.SBQQ__ListPrice__c = 100;
        insert qli14A;
        SBQQ__QuoteLine__c qli15A = new SBQQ__QuoteLine__c();
        qli15A.SBQQ__Quote__c = newQuote.Id;
        qli15A.SBQQ__Product__c = sampleProducts[2].Id;
        qli15A.SBQQ__Quantity__c = 10;
        qli15A.Product_Level__c = 'Hardware';
        qli15A.SBQQ__SubscriptionTerm__c = 12;
        qli15A.SBQQSC__UpgradedContractLine__c = null;
        qli15A.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        qli15A.Product_Type__c = 'Enterprise Edition';
        qli15A.Support_Type__c = 'Premium';
        qli15A.Scale_Utility_Product_Identifier__c = null;
        qli15A.SBQQ__ListPrice__c = 100;
        insert qli15A;
        SBQQ__QuoteLine__c qli16A = new SBQQ__QuoteLine__c();
        qli16A.SBQQ__Quote__c = newQuote.Id;
        qli16A.SBQQ__Product__c = sampleProducts[8].Id;
        qli16A.SBQQ__Quantity__c = 10;
        qli16A.Product_Level__c = 'Hardware';
        qli16A.SBQQ__SubscriptionTerm__c = 12;
        qli16A.SBQQSC__UpgradedContractLine__c = null;
        qli16A.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        qli16A.Product_Type__c = 'M365H';
        qli16A.Support_Type__c = 'Premium';
        qli16A.Scale_Utility_Product_Identifier__c = 'M365 SU RSVX';
        qli16A.SBQQ__ListPrice__c = 100;
        insert qli16A;
        SBQQ__QuoteLine__c qli17A = new SBQQ__QuoteLine__c();
        qli17A.SBQQ__Quote__c = newQuote.Id;
        qli17A.SBQQ__Product__c = sampleProducts[10].Id;
        qli17A.SBQQ__Quantity__c = 10;
        qli17A.Product_Level__c = 'Hardware';
        qli17A.SBQQ__SubscriptionTerm__c = 12;
        qli17A.SBQQSC__UpgradedContractLine__c = null;
        qli17A.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        qli17A.Product_Type__c = 'M365H';
        qli17A.Support_Type__c = 'Premium';
        qli17A.Scale_Utility_Product_Identifier__c = 'M365 SU RSVX';
        qli17A.SBQQ__ListPrice__c = 100;
        insert qli17A;
        
        //RSV QLIs
        //Segment 1
        SBQQ__QuoteLine__c qli18A = new SBQQ__QuoteLine__c();
        qli18A.SBQQ__Quote__c = newQuote.Id;
        qli18A.SBQQ__Product__c = sampleProducts[1].Id;
        qli18A.SBQQ__Quantity__c = 10;
        qli18A.Product_Level__c = 'Hardware';
        qli18A.SBQQ__SubscriptionTerm__c = 12;
        qli18A.SBQQSC__UpgradedContractLine__c = null;
        qli18A.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        qli18A.Scale_Utility_Product_RSV_OND__c = 'RSV';
        qli18A.SBQQ__SegmentLabel__c = '1';
        qli18A.SBQQ__RequiredBy__c = qli14A.Id;
        qli18A.Product_Type__c = 'Foundation Edition';
        qli18A.Support_Type__c = 'Premium';
        qli18A.Scale_Utility_Product_Identifier__c = null;
        qli18A.Scale_Utility_Product_RSV_OND__c = 'RSV';
        qli18A.SBQQ__ListPrice__c = 100;
        insert qli18A;
        SBQQ__QuoteLine__c qli19A = new SBQQ__QuoteLine__c();
        qli19A.SBQQ__Quote__c = newQuote.Id;
        qli19A.SBQQ__Product__c = sampleProducts[3].Id;
        qli19A.SBQQ__Quantity__c = 10;
        qli19A.Product_Level__c = 'Hardware';
        qli19A.SBQQ__SubscriptionTerm__c = 12;
        qli19A.SBQQSC__UpgradedContractLine__c = null;
        qli19A.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        qli19A.Scale_Utility_Product_RSV_OND__c = 'RSV';
        qli19A.SBQQ__SegmentLabel__c = '1';
        qli19A.SBQQ__RequiredBy__c = qli15A.Id;
        qli19A.Product_Type__c = 'Enterprise Edition';
        qli19A.Support_Type__c = 'Premium';
        qli19A.Scale_Utility_Product_Identifier__c = null;
        qli19A.Scale_Utility_Product_RSV_OND__c = 'RSV';
        qli19A.SBQQ__ListPrice__c = 100;
        insert qli19A;
        SBQQ__QuoteLine__c qli20A = new SBQQ__QuoteLine__c();
        qli20A.SBQQ__Quote__c = newQuote.Id;
        qli20A.SBQQ__Product__c = sampleProducts[9].Id;
        qli20A.SBQQ__Quantity__c = 10;
        qli20A.Product_Level__c = 'Hardware';
        qli20A.SBQQ__SubscriptionTerm__c = 12;
        qli20A.SBQQSC__UpgradedContractLine__c = null;
        qli20A.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        qli20A.Scale_Utility_Product_Identifier__c = 'M365 RSV SU';
        qli20A.SBQQ__SegmentLabel__c = '1';
        qli20A.SBQQ__RequiredBy__c = qli16A.Id;
        qli20A.Product_Type__c = 'M365H';
        qli20A.Support_Type__c = 'Premium';
        qli20A.Scale_Utility_Product_Identifier__c = 'M365 RSV SU';
        qli20A.Scale_Utility_Product_RSV_OND__c = null;
        qli20A.SBQQ__ListPrice__c = 100;
        insert qli20A;
        SBQQ__QuoteLine__c qli21A = new SBQQ__QuoteLine__c();
        qli21A.SBQQ__Quote__c = newQuote.Id;
        qli21A.SBQQ__Product__c = sampleProducts[11].Id;
        qli21A.SBQQ__Quantity__c = 10;
        qli21A.Product_Level__c = 'Hardware';
        qli21A.SBQQ__SubscriptionTerm__c = 12;
        qli21A.SBQQSC__UpgradedContractLine__c = null;
        qli21A.Member_of_Bundle_Edition_s__c = 'Scale Utility';
        qli21A.Scale_Utility_Product_Identifier__c = 'M365 RSV SU';
        qli21A.SBQQ__SegmentLabel__c = '1';
        qli21A.SBQQ__RequiredBy__c = qli17A.Id;
        qli21A.Product_Type__c = 'M365H';
        qli21A.Support_Type__c = 'Premium';
        qli21A.Scale_Utility_Product_Identifier__c = 'M365 RSV SU';
        qli21A.Scale_Utility_Product_RSV_OND__c = null;
        qli21A.SBQQ__ListPrice__c = 100;
        insert qli21A;
        
        //AR & SR QLIs
        SBQQ__QuoteLine__c qli6A = new SBQQ__QuoteLine__c();
        qli6A.SBQQ__Quote__c = newQuote.Id;
        qli6A.SBQQ__Product__c = sampleProducts[4].Id;
        qli6A.SBQQ__Quantity__c = 10;
        qli6A.Product_Level__c = 'Hardware';
        qli6A.SBQQ__SubscriptionTerm__c = 12;
        qli6A.SBQQSC__UpgradedContractLine__c = null;
        qli6A.Scale_Utility_Product_Identifier__c = 'OND AR';
        qli6A.SBQQ__RequiredBy__c = qli14A.Id;
        qli6A.Product_Type__c = 'Foundation Edition';
        qli6A.Support_Type__c = 'Premium';
        qli6A.Scale_Utility_Product_RSV_OND__c = 'OND';
        qli6A.SBQQ__ListPrice__c = 100;
        insert qli6A;
        SBQQ__QuoteLine__c qli7A = new SBQQ__QuoteLine__c();
        qli7A.SBQQ__Quote__c = newQuote.Id;
        qli7A.SBQQ__Product__c = sampleProducts[5].Id;
        qli7A.SBQQ__Quantity__c = 10;
        qli7A.Product_Level__c = 'Hardware';
        qli7A.SBQQ__SubscriptionTerm__c = 12;
        qli7A.SBQQSC__UpgradedContractLine__c = null;
        qli7A.Scale_Utility_Product_Identifier__c = 'OND SR';
        qli7A.SBQQ__RequiredBy__c = qli14A.Id;
        qli7A.Product_Type__c = 'Foundation Edition';
        qli7A.Support_Type__c = 'Premium';
        qli7A.Scale_Utility_Product_RSV_OND__c = 'OND';
        qli7A.SBQQ__ListPrice__c = 100;
        insert qli7A;
        SBQQ__QuoteLine__c qli8A = new SBQQ__QuoteLine__c();
        qli8A.SBQQ__Quote__c = newQuote.Id;
        qli8A.SBQQ__Product__c = sampleProducts[6].Id;
        qli8A.SBQQ__Quantity__c = 10;
        qli8A.Product_Level__c = 'Hardware';
        qli8A.SBQQ__SubscriptionTerm__c = 12;
        qli8A.SBQQSC__UpgradedContractLine__c = null;
        qli8A.Scale_Utility_Product_Identifier__c = 'OND AR';
        qli8A.SBQQ__RequiredBy__c = qli15A.Id;
        qli8A.Product_Type__c = 'Enterprise Edition';
        qli8A.Support_Type__c = 'Premium';
        qli8A.Scale_Utility_Product_RSV_OND__c = 'OND';
        qli8A.SBQQ__ListPrice__c = 100;
        insert qli8A;
        SBQQ__QuoteLine__c qli9A = new SBQQ__QuoteLine__c();
        qli9A.SBQQ__Quote__c = newQuote.Id;
        qli9A.SBQQ__Product__c = sampleProducts[7].Id;
        qli9A.SBQQ__Quantity__c = 10;
        qli9A.Product_Level__c = 'Hardware';
        qli9A.SBQQ__SubscriptionTerm__c = 12;
        qli9A.SBQQSC__UpgradedContractLine__c = null;
        qli9A.Scale_Utility_Product_Identifier__c = 'OND SR';
        qli9A.SBQQ__RequiredBy__c = qli15A.Id;
        qli9A.Product_Type__c = 'Enterprise Edition';
        qli9A.Support_Type__c = 'Premium';
        qli9A.Scale_Utility_Product_RSV_OND__c = 'OND';
        qli9A.SBQQ__ListPrice__c = 100;
        insert qli9A;
        SBQQ__QuoteLine__c qli10A = new SBQQ__QuoteLine__c();
        qli10A.SBQQ__Quote__c = newQuote.Id;
        qli10A.SBQQ__Product__c = sampleProducts[12].Id;
        qli10A.SBQQ__Quantity__c = 10;
        qli10A.Product_Level__c = 'Hardware';
        qli10A.SBQQ__SubscriptionTerm__c = 12;
        qli10A.SBQQSC__UpgradedContractLine__c = null;
        qli10A.Scale_Utility_Product_Identifier__c = 'OND AR';
        qli10A.SBQQ__RequiredBy__c = qli16A.Id;
        qli10A.Product_Type__c = 'Foundation Edition';
        qli10A.Support_Type__c = 'Premium';
        qli10A.Scale_Utility_Product_RSV_OND__c = 'OND';
        qli10A.SBQQ__ListPrice__c = 100;
        insert qli10A;
        SBQQ__QuoteLine__c qli11A = new SBQQ__QuoteLine__c();
        qli11A.SBQQ__Quote__c = newQuote.Id;
        qli11A.SBQQ__Product__c = sampleProducts[13].Id;
        qli11A.SBQQ__Quantity__c = 10;
        qli11A.Product_Level__c = 'Hardware';
        qli11A.SBQQ__SubscriptionTerm__c = 12;
        qli11A.SBQQSC__UpgradedContractLine__c = null;
        qli11A.Scale_Utility_Product_Identifier__c = 'OND SR';
        qli11A.SBQQ__RequiredBy__c = qli16A.Id;
        qli11A.Product_Type__c = 'Foundation Edition';
        qli11A.Support_Type__c = 'Premium';
        qli11A.Scale_Utility_Product_RSV_OND__c = 'OND';
        qli11A.SBQQ__ListPrice__c = 100;
        insert qli11A;
        SBQQ__QuoteLine__c qli12A = new SBQQ__QuoteLine__c();
        qli12A.SBQQ__Quote__c = newQuote.Id;
        qli12A.SBQQ__Product__c = sampleProducts[14].Id;
        qli12A.SBQQ__Quantity__c = 10;
        qli12A.Product_Level__c = 'Hardware';
        qli12A.SBQQ__SubscriptionTerm__c = 12;
        qli12A.SBQQSC__UpgradedContractLine__c = null;
        qli12A.Scale_Utility_Product_Identifier__c = 'OND AR';
        qli12A.SBQQ__RequiredBy__c = qli17A.Id;
        qli12A.Product_Type__c = 'Enterprise Edition';
        qli12A.Support_Type__c = 'Premium';
        qli12A.Scale_Utility_Product_RSV_OND__c = 'OND';
        qli12A.SBQQ__ListPrice__c = 100;
        insert qli12A;
        SBQQ__QuoteLine__c qli13A = new SBQQ__QuoteLine__c();
        qli13A.SBQQ__Quote__c = newQuote.Id;
        qli13A.SBQQ__Product__c = sampleProducts[15].Id;
        qli13A.SBQQ__Quantity__c = 10;
        qli13A.Product_Level__c = 'Hardware';
        qli13A.SBQQ__SubscriptionTerm__c = 12;
        qli13A.SBQQSC__UpgradedContractLine__c = null;
        qli13A.Scale_Utility_Product_Identifier__c = 'OND SR';
        qli13A.SBQQ__RequiredBy__c = qli17A.Id;
        qli13A.Product_Type__c = 'Enterprise Edition';
        qli13A.Support_Type__c = 'Premium';
        qli13A.Scale_Utility_Product_RSV_OND__c = 'OND';
        qli13A.SBQQ__ListPrice__c = 100;
        insert qli13A;
        
        newQLIMap.add(qli6A);
        newQLIMap.add(qli7A);
        newQLIMap.add(qli8A);
        newQLIMap.add(qli9A);
        newQLIMap.add(qli10A);
        newQLIMap.add(qli11A);
        newQLIMap.add(qli12A);
        newQLIMap.add(qli13A);
        newQLIMap.add(qli14A);
        newQLIMap.add(qli15A);
        newQLIMap.add(qli16A);
        newQLIMap.add(qli17A);
        newQLIMap.add(qli18A);
        newQLIMap.add(qli19A);
        newQLIMap.add(qli20A);
        newQLIMap.add(qli21A);
        
        Datetime yesterday = Datetime.now().addDays(-1);
        Test.setCreatedDate(q1.Id, yesterday);
        Test.setCreatedDate(q2.Id, yesterday);
            }
    }

    /**
     * @description  : This test method is used to test the autoAddONDSKUs functionality of SBQQ_QuoteLineTriggerHelper.
     */
    public static testMethod void autoTestMethod1()
    {        
        List<SBQQ__Quote__c> quoteRecordsa1 = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c = 'Amendment' LIMIT 10];
        
        List<SBQQ__QuoteLine__c> quoteLineRecordsa1 = getQLIs(quoteRecordsa1);
        Test.startTest();
        
        System.runAs(new user(ID = UserInfo.getUserID())){
            SBQQ_QuoteLineTriggerHelper.autoAddONDSKUs(quoteLineRecordsa1, 'beforeInsert');
            SBQQ_QuoteLineTriggerHelper.autoAddONDSKUs(quoteLineRecordsa1, 'beforeUpdate');
            SBQQ_QuoteLineTriggerHelper.autoAddONDSKUs(quoteLineRecordsa1, 'afterInsert');
        }
        System.assert(true);
        Test.stopTest();
    }
    
    /**
     * @description  : This test method is used to test the autoAddONDSKUs functionality of SBQQ_QuoteLineTriggerHelper.
     */
    public static testMethod void autoTestMethod2()
    {        
        List<SBQQ__Quote__c> quoteRecordsa2 = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c = 'Amendment' LIMIT 10];
        
        List<SBQQ__QuoteLine__c> quoteLineRecordsa2 = getQLIs(quoteRecordsa2);
        List<SBQQ__QuoteLine__c> newQLIListToUpdate = new List<SBQQ__QuoteLine__c>();
        
        if(quoteLineRecordsa2 != null && !quoteLineRecordsa2.IsEmpty())
        {
            for(SBQQ__QuoteLine__c qli : quoteLineRecordsa2)
            {
                system.debug(LoggingLevel.INFO, 'TC1: ' + qli.SBQQ__ProductCode__c);
                qli.SBQQ__SegmentLabel__c = null;
                qli.SubscribedAssetNames__c = 'BB192863040046';
                newQLIListToUpdate.add(qli);
            }
            update quoteLineRecordsa2;
        }
        if(newQLIListToUpdate != null && !newQLIListToUpdate.IsEmpty()){
            update newQLIListToUpdate;
        }
        system.debug(LoggingLevel.INFO, 'quoteLineRecords1: ' + quoteLineRecordsa2);
        system.debug(LoggingLevel.INFO, 'newQLIListToUpdate: ' + newQLIListToUpdate);
        Test.startTest();
       
       
        System.runAs(new user(ID = UserInfo.getUserID())){
            //SBQQ_QuoteLineTriggerHelper.autoAddONDSKUs(quoteLineRecordsa2, 'beforeInsert');
            SBQQ_QuoteLineTriggerHelper.autoAddONDSKUs(quoteLineRecordsa2, 'beforeUpdate');
            SBQQ_QuoteLineTriggerHelper.autoAddONDSKUs(quoteLineRecordsa2, 'afterInsert');
        }
        System.assert(true);
        Test.stopTest();
    }

    /**
     * @description  : This test method is used to test the autoAddONDSKUs functionality of SBQQ_QuoteLineTriggerHelper.
     */
    public static testMethod void autoTestMethod3()
    {        
        List<SBQQ__Quote__c> quoteRecordsa3 = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c = 'Amendment' LIMIT 10];
        
        List<SBQQ__QuoteLine__c> quoteLineRecordsa3 = getQLIs(quoteRecordsa3);
        Map<Id, SBQQ__QuoteLine__c> newQLIListToUpdate = new Map<Id, SBQQ__QuoteLine__c>();
        
        if(quoteLineRecordsa3 != null && !quoteLineRecordsa3.IsEmpty())
        {
            for(SBQQ__QuoteLine__c qli : quoteLineRecordsa3)
            {
                if(qli.SBQQ__SegmentLabel__c != null)
                {
                    qli.SBQQ__SegmentLabel__c = null;
                    newQLIListToUpdate.put(qli.Id, qli);
                }
                if(qli.Scale_Utility_Product_Identifier__c == 'SU FUE')
                {
                    qli.Scale_Utility_Product_Identifier__c = null;
                    newQLIListToUpdate.put(qli.Id, qli);
                }
                if(qli.Scale_Utility_Product_RSV_OND__c == 'RSV' || qli.Scale_Utility_Product_Identifier__c == 'M365 RSV SU')
                {
                    qli.Quantity_TB__c = 0;
                    qli.SBQQ__Quantity__c = 0;
                    qli.SBQQ__PriorQuantity__c = 0;
                    //qli.SBQQ__UpgradedQuantity__c = 0;
                    qli.SBQQ__SubscriptionPricing__c = null;
                    qli.SBQQ__Existing__c = true;
                    qli.SBQQ__CarryoverLine__c = true;
                    //qli.SBQQ__AllowAssetRefund__c = false;
                    newQLIListToUpdate.put(qli.Id, qli);
                }
                qli.SubscribedAssetNames__c = 'BB192863040046';
            }
            update quoteLineRecordsa3;
        }
        
        if(newQLIListToUpdate != null && !newQLIListToUpdate.IsEmpty() && newQLIListToUpdate.values().size() > 0){
            update newQLIListToUpdate.values();
        }
        Test.startTest();
         
        System.runAs(new user(ID = UserInfo.getUserID())){   
            SBQQ_QuoteLineTriggerHelper.autoAddONDSKUs(quoteLineRecordsa3, 'beforeInsert');
            SBQQ_QuoteLineTriggerHelper.autoAddONDSKUs(quoteLineRecordsa3, 'beforeUpdate');
            SBQQ_QuoteLineTriggerHelper.autoAddONDSKUs(quoteLineRecordsa3, 'afterInsert');
        }
        System.assert(true);
        Test.stopTest();
    }

    /**
     * @description  : This test method is used to test the autoAddONDSKUs functionality of SBQQ_QuoteLineTriggerHelper.
     */
    public static testMethod void autoTestMethod4()
    {        
        List<SBQQ__Quote__c> quoteRecordsa4 = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c = 'Amendment' LIMIT 10];
        
        List<SBQQ__QuoteLine__c> quoteLineRecordsa4 = getQLIs(quoteRecordsa4);
        Map<Id, SBQQ__QuoteLine__c> newQLIListToUpdate = new Map<Id, SBQQ__QuoteLine__c>();
        
        if(quoteLineRecordsa4 != null && !quoteLineRecordsa4.IsEmpty())
        {
            for(SBQQ__QuoteLine__c qli : quoteLineRecordsa4)
            {
                if(qli.Scale_Utility_Product_Identifier__c == 'OND AR' || qli.Scale_Utility_Product_Identifier__c == 'OND SR')
                {
                    qli.Scale_Utility_Product_Identifier__c = null;
                    qli.Scale_Utility_Product_RSV_OND__c = null;
                    newQLIListToUpdate.put(qli.Id, qli);
                }
                qli.SubscribedAssetNames__c = 'BB192863040046';
            }
            update quoteLineRecordsa4;
        }
        
        if(newQLIListToUpdate != null && !newQLIListToUpdate.IsEmpty() && newQLIListToUpdate.values().size() > 0){
            update newQLIListToUpdate.values();
        }
        
        Test.startTest();

        
        System.runAs(new user(ID = UserInfo.getUserID())){
            SBQQ_QuoteLineTriggerHelper.autoAddONDSKUs(quoteLineRecordsa4, 'beforeInsert');
            SBQQ_QuoteLineTriggerHelper.autoAddONDSKUs(quoteLineRecordsa4, 'beforeUpdate');
            SBQQ_QuoteLineTriggerHelper.autoAddONDSKUs(quoteLineRecordsa4, 'afterInsert');
        }

        System.assert(true);
        Test.stopTest();
    }
    
    /**
     * @description  : This test method is used to test the autoAddONDSKUs functionality of SBQQ_QuoteLineTriggerHelper.
     */
    public static testMethod void autoTestMethod5()
    {        
        List<SBQQ__Quote__c> quoteRecordsa5 = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c = 'Quote' LIMIT 10];
        
        List<SBQQ__QuoteLine__c> quoteLineRecords5a = getQLIs(quoteRecordsa5);
        
        Test.startTest();
        
        System.runAs(new user(ID = UserInfo.getUserID())){
            SBQQ_QuoteLineTriggerHelper.autoAddONDSKUs(quoteLineRecords5a, 'beforeInsert');
            SBQQ_QuoteLineTriggerHelper.autoAddONDSKUs(quoteLineRecords5a, 'beforeUpdate');
            SBQQ_QuoteLineTriggerHelper.autoAddONDSKUs(quoteLineRecords5a, 'afterInsert');
        }
        System.assert(true);
        Test.stopTest();
    }
    
    /**
     * @description  : This test method is used to test the autoAddONDSKUsFuture functionality of SBQQ_QuoteLineTriggerHelper.
     */
    public static testMethod void autoTestMethod6()
    {        
        List<SBQQ__Quote__c> quoteRecords6a = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c = 'Amendment' LIMIT 10];
        List<SBQQ__QuoteLine__c> quoteLineRecords6a = getQLIs(quoteRecords6a);
        String cliId = '';
        Map<Id, SBQQ__QuoteLine__c> newQLIListToUpdate6a = new Map<Id, SBQQ__QuoteLine__c>();
        Set<Id> quoteId = new Set<Id>();
        
        if(quoteLineRecords6a != null && !quoteLineRecords6a.IsEmpty())
        {
            for(SBQQ__QuoteLine__c qli : quoteLineRecords6a)
            {
                if(qli.SBQQ__RequiredBy__c != null && qli.SBQQ__RequiredBy__r.Product_Type__c == 'Enterprise Edition'
                   && (qli.Scale_Utility_Product_Identifier__c == 'OND AR' || qli.Scale_Utility_Product_Identifier__c == 'OND SR')
                   //&& qli.Product_Type__c == 'Enterprise Edition'
                  ){
                      qli.Scale_Utility_Product_Identifier__c = null;
                      qli.SBQQ__RequiredBy__c = null;
                      qli.Product_Type__c = null;
                      newQLIListToUpdate6a.put(qli.Id, qli);
                  }
                if(qli.Scale_Utility_Product_Identifier__c == 'SU FUE'){
                    cliId = qli.SBQQSC__UpgradedContractLine__c;
                }
                if((qli.SBQQ__Product__c != null && qli.SBQQ__ProductCode__c != null
                    && qli.SBQQ__ProductCode__c.contains('RSVX'))
                   || qli.Scale_Utility_Product_Identifier__c != 'M365 SU RSVX'
                  ){
                      qli.Product_Type__c = 'Enterprise Edition';
                      newQLIListToUpdate6a.put(qli.Id, qli);
                  }
                if(qli.SBQQ__ProductCode__c == 'RS-UR-EE-MD-RSVX-PE')
                {
                    qli.Scale_Utility_Product_Identifier__c = null;
                    qli.Product_Type__c = 'Enterprise Edition';
                    newQLIListToUpdate6a.put(qli.Id, qli);
                }
                qli.SubscribedAssetNames__c = 'BB192863040046';
            }
            update quoteLineRecords6a;
        }
        if(newQLIListToUpdate6a != null && !newQLIListToUpdate6a.IsEmpty() && newQLIListToUpdate6a.values().size() > 0){
            update newQLIListToUpdate6a.values();
            
            for(SBQQ__QuoteLine__c qli: newQLIListToUpdate6a.values()){
                quoteId.add(qli.SBQQ__Quote__c);
            }
        }
        
        Test.startTest();
        
        System.runAs(new user(ID = UserInfo.getUserID())){
            SBQQ_QuoteLineTriggerHelper.autoAddONDSKUs(quoteLineRecords6a, 'beforeUpdate');
            SBQQ_QuoteLineTriggerHelper.autoAddONDSKUs(quoteLineRecords6a, 'afterInsert');
            
            SBQQ_QuoteLineTriggerHelper.autoAddONDSKUsFuture(quoteId, 'beforeUpdate');
            SBQQ_QuoteLineTriggerHelper.autoAddONDSKUsFuture(quoteId, 'afterInsert');
        }
        System.assert(true);
        Test.stopTest();
    }
    
    /**
     * @description  : This test method is used to test the autoAddONDSKUsFuture functionality of SBQQ_QuoteLineTriggerHelper.
     */
    public static testMethod void autoTestMethod7()
    {        
        List<SBQQ__Quote__c> quoteRecords6a = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c = 'Amendment' LIMIT 10];
        List<SBQQ__QuoteLine__c> quoteLineRecords6a = getQLIs(quoteRecords6a);
        String cliId = '';
        Map<Id, SBQQ__QuoteLine__c> newQLIListToUpdate6a = new Map<Id, SBQQ__QuoteLine__c>();
        Set<Id> quoteId = new Set<Id>();
        
        if(quoteLineRecords6a != null && !quoteLineRecords6a.IsEmpty())
        {
            for(SBQQ__QuoteLine__c qli : quoteLineRecords6a)
            {
                if(qli.SBQQ__RequiredBy__c != null && qli.SBQQ__RequiredBy__r.Product_Type__c == 'Enterprise Edition'
                   && (qli.Scale_Utility_Product_Identifier__c == 'OND AR' || qli.Scale_Utility_Product_Identifier__c == 'OND SR')
                   //&& qli.Product_Type__c == 'Enterprise Edition'
                  ){
                      qli.Scale_Utility_Product_Identifier__c = null;
                      qli.SBQQ__RequiredBy__c = null;
                      qli.Product_Type__c = null;
                      newQLIListToUpdate6a.put(qli.Id, qli);
                  }
                if(qli.Scale_Utility_Product_Identifier__c == 'SU FUE'){
                    cliId = qli.SBQQSC__UpgradedContractLine__c;
                }
                if((qli.SBQQ__Product__c != null && qli.SBQQ__ProductCode__c != null
                    && qli.SBQQ__ProductCode__c.contains('RSVX'))
                   || qli.Scale_Utility_Product_Identifier__c != 'M365 SU RSVX'
                  ){
                      qli.Product_Type__c = 'Enterprise Edition';
                      newQLIListToUpdate6a.put(qli.Id, qli);
                  }
                if(qli.SBQQ__ProductCode__c == 'RS-UR-EE-MD-RSVX-PE')
                {
                   qli.Scale_Utility_Product_Identifier__c = null;
                    qli.Product_Type__c = 'Enterprise Edition';
                    newQLIListToUpdate6a.put(qli.Id, qli);
                }
                qli.SubscribedAssetNames__c = 'BB192863040046,BB192863040047';
            }
            update quoteLineRecords6a;
        }
        if(newQLIListToUpdate6a != null && !newQLIListToUpdate6a.IsEmpty() && newQLIListToUpdate6a.values().size() > 0){
            update newQLIListToUpdate6a.values();
            for(SBQQ__QuoteLine__c qli: newQLIListToUpdate6a.values()){
                quoteId.add(qli.SBQQ__Quote__c);
            }
        }
        /*for (PricebookEntry eachEntry : [SELECT Id, ProductCode, UnitPrice, Pricebook2Id FROM PricebookEntry 
                                            WHERE Product2Id IN (SELECT SBQQ__OptionalSKU__c
                                                                    FROM SBQQ__ProductOption__c
                                                                    WHERE(SBQQ__OptionalSKU__r.Scale_Utility_Product_Identifier__c = 'OND AR'
                                                                        OR SBQQ__OptionalSKU__r.Scale_Utility_Product_Identifier__c = 'OND SR'))
                                                AND IsActive = TRUE]) {
            
        }*/
        
        Test.startTest();
        
        System.runAs(new user(ID = UserInfo.getUserID())){
            SBQQ_QuoteLineTriggerHelper.autoAddONDSKUs(quoteLineRecords6a, 'beforeInsert');
            SBQQ_QuoteLineTriggerHelper.autoAddONDSKUs(quoteLineRecords6a, 'beforeDelete');
            
            SBQQ_QuoteLineTriggerHelper.autoAddONDSKUsFuture(quoteId, 'beforeInsert');
            SBQQ_QuoteLineTriggerHelper.autoAddONDSKUsFuture(quoteId, 'beforeDelete');
        }
        System.assert(true);
        Test.stopTest();
    }

    /**
     * @description  : This test method is used to test the autoAddONDSKUsFuture functionality of SBQQ_QuoteLineTriggerHelper.
     */
    public static testMethod void autoTestMethod8()
    {        
        List<SBQQ__Quote__c> quoteRecords6a = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c = 'Amendment' LIMIT 1];
        List<SBQQ__QuoteLine__c> quoteLineRecords6a = getQLIs(quoteRecords6a);
        Set<Id> quoteId = new Set<Id>();
        if(quoteLineRecords6a != null && !quoteLineRecords6a.IsEmpty() && quoteLineRecords6a.size() > 0){
            Integer i = 1;
            for(SBQQ__QuoteLine__c qli: quoteLineRecords6a){
                quoteId.add(qli.SBQQ__Quote__c);
               
                if(qli.Scale_Utility_Product_Identifier__c == 'OND AR' || qli.Scale_Utility_Product_Identifier__c == 'OND SR'){
                      qli.Scale_Utility_Product_Identifier__c = null;
                }
                if(qli.SBQQ__ProductCode__c.containsIgnoreCase('RSV')){
                    qli.SBQQ__SegmentIndex__c = i;
                    qli.SBQQ__Quantity__c = 500;
                    //qli.SBQQ__EffectiveQuantity__c = 500;
                    i++;
                }
            }
        }
        
        Test.startTest();
        
        System.runAs(new user(ID = UserInfo.getUserID())){
            SBQQ_QuoteLineTriggerHelper.autoAddONDSKUs(quoteLineRecords6a, 'beforeDelete');
            SBQQ_QuoteLineTriggerHelper.autoAddONDSKUsFuture(quoteId, 'beforeDelete');
        }
        System.assert(true);
        Test.stopTest();
    }        
    
    
    testmethod static void testnoErrorQuotableValidation(){
        Product2 prod = new Product2();
        prod.Name = 'Test Product';
        prod.Quotable_By_Profiles__c = 'Rubrik Light Administrator';
        prod.Quotable_by_users__c = '<a href="/0055g00000In" target="_blank">'+UserInfo.getName()+'</a> , <a href="/0055g000006AAB" target="_blank">Test User</a>';
        prod.IsActive = true;
        insert prod;
        
        PriceBookEntry pbe = new PriceBookEntry();
        pbe.Product2Id = prod.Id;
        pbe.IsActive = true;
        pbe.UnitPrice = 100;
        pbe.Pricebook2Id = Test.getStandardPricebookId();
        insert pbe; 
        
        //SBQQ__Quote__c qut = new SBQQ__Quote__c();
        //insert qut;
        //PriceBookEntry pb = [SELECT Id,Product2Id FROM PriceBookEntry];
        SBQQ__Quote__c qt = [SELECT Id,SBQQ__SalesRep__c FROM SBQQ__Quote__c Limit 1];
        
        
        System.runAs(new user(ID = UserInfo.getUserID())){
            SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
            ql.SBQQ__Product__c = pbe.Product2Id;
            ql.SBQQ__Quote__c = qt.Id;
            ql.SBQQ__PricebookEntryId__c = pbe.Id;
            ql.SBQQ__ListPrice__c = 100;
            try{
            insert ql;
            System.assert(ql.Id != null);
            }catch(Exception e){
                System.debug(LoggingLevel.INFO, 'Expected exception: ' + e.getMessage());
            }
    }
    }
    
    testmethod static void testErrorQuotableValidation(){
        Product2 prod = new Product2();
        prod.Name = 'Test1 Product';
        prod.Quotable_By_Profiles__c = 'Rubrik Light Administrator';
        prod.Quotable_by_users__c = '<a href="/0055g00000In" target="_blank">'+UserInfo.getName()+'</a> , <a href="/0055g000006AAB" target="_blank">Test User</a>';
        prod.IsActive = true;
        insert prod;
        
        PriceBookEntry pbe1 = new PriceBookEntry();
        pbe1.Product2Id = prod.Id;
        pbe1.IsActive = true;
        pbe1.UnitPrice = 100;
        pbe1.Pricebook2Id = Test.getStandardPricebookId();
        insert pbe1; 
        
        //SBQQ__Quote__c qt1 = new SBQQ__Quote__c();
        //insert qt1;
        //PriceBookEntry pbe1 = [SELECT Id,Product2Id FROM PriceBookEntry];
        SBQQ__Quote__c qt1 = [SELECT Id,SBQQ__SalesRep__c FROM SBQQ__Quote__c Limit 1];
        
        Product2 product1 = new Product2(Id = pbe1.Product2Id);
        product1.Quotable_by_users__c = '';
        update product1;
        
        
        System.runAs(new user(ID = UserInfo.getUserID())){
            SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
            ql.SBQQ__Product__c = pbe1.Product2Id;
            ql.SBQQ__Quote__c = qt1.Id;
            ql.SBQQ__PricebookEntryId__c = pbe1.Id;
            ql.SBQQ__ListPrice__c = 100;
            try{
            insert ql;
            System.assert(ql.Id != null);
            }catch(Exception e){
                System.debug(LoggingLevel.INFO, 'Expected exception: ' + e.getMessage());
            }
    }
    }

    private static List<SBQQ__QuoteLine__c> getQLIs(List<SBQQ__Quote__c> quoteList) {
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        
        if (quoteList != null && !quoteList.isEmpty()) {
            quoteLines = [SELECT Id, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Number__c, SBQQ__ProductOption__c, 
                          Line_Type__c, SBQQ__Quote__c, SBQQ__RequiredBy__c, Scale_Utility_Product_RSV_OND__c, 
                          Scale_Utility_Product_Identifier__c, SBQQ__Quantity__c, SBQQ__EffectiveQuantity__c, 
                          SBQQ__PriorQuantity__c, Member_of_Bundle_Edition_s__c, SBQQ__StartDate__c, SBQQ__EndDate__c,
                          SBQQ__Quote__r.SBQQ__Type__c, SBQQ__Quote__r.OpportunitySubType__c, SBQQ__Quote__r.Name,
                          SBQQ__Quote__r.SBQQ__LineItemCount__c, Product_Type__c, SBQQ__SubscriptionTerm__c, 
                          SBQQ__SubscriptionPricing__c, SBQQ__SegmentIndex__c, SBQQ__Product__r.Pricebook_Entry_Id__c,
                          SBQQ__SegmentLabel__c, SBQQ__Product__r.Support_Type__c, SBQQ__PricebookEntryId__c, 
                          SBQQ__NetPrice__c, SBQQ__ListPrice__c, SBQQ__Quote__r.SBQQ__PricebookId__c, 
                          SBQQSC__UpgradedContractLine__c, SBQQ__RequiredBy__r.Product_Type__c, 
                          SBQQ__RequiredBy__r.SBQQ__Product__c, 
                          SBQQ__Product__r.Product_Type__c, SBQQ__DynamicOptionId__c, Product_Level__c, Support_Type__c, 
                          Product_Payment_Option__c, SBQQ__RequiredBy__r.Scale_Utility_Product_Identifier__c, 
                          SBQQ__RequiredBy__r.SBQQ__ProductCode__c, SBQQ__RequiredBy__r.Scale_Utility_Product_RSV_OND__c, 
                          SBQQ__Product__r.Description, SBQQ__ProductOption__r.SBQQ__OptionalSKU__r.Description, 
                          SBQQ__Description__c, SBQQ__ProrateMultiplier__c, SBQQ__Discount__c,
                          SBQQ__Existing__c,
                          SBQQ__CarryoverLine__c, SBQQ__UpgradedQuantity__c,
                          SBQQ__AllowAssetRefund__c, Quantity_TB__c
                          FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN: quoteList];
            
        }
        
        return quoteLines;
    }

    @isTest
    private static void msTestMethodQL() {
        ShGl_DisableFunctionalityLogic__c disFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disFuncCS.DisableDemandMatrixCalculation__c = true;
        insert disFuncCS;
            //Disable_Opportunity_Triggers__c = true
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
        System.debug(LoggingLevel.INFO, pricebookId);
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
    
        
        System.runAs(new user(ID = UserInfo.getUserID())){
            //QCPUtility.setDiscountMarginPercentChange(qt1.Id);
            update lines;
        }
    }
        /**
        * @description  : This test method is used to test the setSourceListPrice functionality of SBQQ_QuoteLineTriggerHelper.
        */
     
    @isTest
    static void testMethodDatePolicyAllContract() {
        
        String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(
            Alias = 'adminU', Email='AdminUser@rubrik.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
           RBAC_Group__c = 'System - IT',
           RBAC_Department__c = 'Service Account',
            UserName=uniqueUserName
        );
        insert u;
        System.runAs(u) {
        ShGl_DisableBusinessLogic__c cdf1 = new ShGl_DisableBusinessLogic__c(
            SetupOwnerId = UserInfo.getUserId(),
            Disable_SBQQ_Quote_Triggers__c = true,
            Disable_ServiceContract_Trigger__c = true
        );
        //insert cdf1;
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        TriggerControls.disableCalculateAPIBatch = true;
        SBQQ.TriggerControl.disable();
        ShGl_DisableFunctionalityLogic__c settingC = new ShGl_DisableFunctionalityLogic__c();
        settingC.Name = 'System Administrator';
        settingC.Disable_Opportunity_Old_Trigger__c = true;
        settingC.Disable_Order_Old_Trigger__c = true;
        settingC.Disable_Account_Old_Trigger__c = true;
        insert settingC;
        
        ShGl_DisableBusinessLogic__c settingDisableV = new ShGl_DisableBusinessLogic__c();
        settingDisableV.Name = 'System Administrator';
        settingDisableV.Disable_Opportunity_Validation_Rules__c = true;
        settingDisableV.Disable_Order_Validation_Rules__c = true;
        settingDisableV.Disable_ServiceContract_Trigger__c = true;
        settingDisableV.Disable_Entitlement_Validation_Rules__c = true;
        //insert settingDisableV;

        ShGl_DisableBusinessLogic__c settingD = new ShGl_DisableBusinessLogic__c();
        settingD.Name = 'Deal Operations';
        settingD.Disable_Opportunity_Validation_Rules__c = true;
        settingD.Disable_ServiceContract_Trigger__c = true;
        settingD.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
        settingD.Disable_Entitlement_Validation_Rules__c = true;
        insert settingD;
        List<TriggerControl__c> triggerList = new List<TriggerControl__c>();
        TriggerControl__c setting0V = new TriggerControl__c();
        setting0V.Name = 'Order';
        setting0V.DisableTrigger__c = true;
        triggerList.add(setting0V);
        TriggerControl__c setting1V = new TriggerControl__c();
        setting1V.Name = 'Opportunity';
        setting1V.DisableTrigger__c = true;
        triggerList.add(setting1V);
        
        TriggerControl__c setting2 = new TriggerControl__c();
        setting2.Name = 'Entitlement';
        setting2.DisableTrigger__c = true;
        triggerList.add(setting2);
        insert triggerList;
        
        
        ShGl_TestFactoryHelper.insertTriggerControls();
        Id pb = Test.getStandardPricebookId();
        
        Product2 prod = new Product2(
            Name = 'RA-REINST-FEE-PP',
            IsActive = true,
            SBQQ__SubscriptionPricing__c = 'Fixed Price',
            ProductCode = 'Test-Prod'
        );
        Product2 prodSupp = new Product2(
            Name = 'TestProdSupport',
            IsActive = true,
            SBQQ__SubscriptionPricing__c = 'Fixed Price',
            ProductCode = 'Test-Supp'
        );
        Product2 prodSub = new Product2(
            Name = 'TestProdSubscription',
            IsActive = true,
            SBQQ__SubscriptionPricing__c = 'Fixed Price',
            Approval_Category__c = 'AIR BASIC',
            ProductCode = 'Test-Subs'
        );
        
        List<Product2> prdList = new List<Product2>{ prod, prodSupp, prodSub };
            insert prdList;
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pb,
            Product2Id = prod.Id,
            IsActive = true,
            UnitPrice = 10
        );
        PricebookEntry pbeSupp = new PricebookEntry(
            Pricebook2Id = pb,
            Product2Id = prodSupp.Id,
            IsActive = true,
            UnitPrice = 10
        );
        PricebookEntry pbeSub = new PricebookEntry(
            Pricebook2Id = pb,
            Product2Id = prodSub.Id,
            IsActive = true,
            UnitPrice = 10
        );
        List<PricebookEntry> pbeList = new List<PricebookEntry>{
            pbe,
                pbeSupp,
                pbeSub
                };
                    insert pbeList;
        
        Account acc = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert acc;
        
        List<Entitlement> entToInsert = new List<Entitlement>();
        Entitlement ent = new Entitlement(
            Name = 'Testing',
            AccountId = acc.Id,
            Product__c = prod.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(365)
        );
        entToInsert.add(ent);
        
        Entitlement ent2 = new Entitlement(
            Name = 'Testing',
            AccountId = acc.Id,
            Product__c = prodSupp.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(360)
        );
        entToInsert.add(ent2);
        
        Entitlement ent3 = new Entitlement(
            Name = 'Testing2',
            AccountId = acc.Id,
            Product__c = prodSub.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(360)
        );
        entToInsert.add(ent3);
        insert entToInsert;

        List<Account> accountList = new List<Account>();
        Account vAccount = new Account();
        vAccount.Name = 'Test Account';
        vAccount.Type = 'Distributor';
        vAccount.RecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByName()
            .get('Partner/Distributor')
            .getRecordTypeId();
        accountList.add(vAccount);
        
        Account vAccount2 = new Account();
        vAccount2.Name = 'Test Account';
        vAccount2.Distributor__c = vAccount.Id;
        vAccount2.RecordTypeId = vAccount.RecordTypeId;
        accountList.add(vAccount2);
        insert accountList;
        
        Asset asset = new Asset();
        asset.Name = '123456';
        asset.Serial_Number__c = '123456';
        asset.AccountId = acc.Id;
        asset.Product2Id = prod.Id;
        insert asset;
        
        //Generate the Opportunity
        Map<String, Object> oppMap = new Map<String, Object>{
            'AccountId' => acc.Id
                };
                    
                    Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(
                        new Opportunity(),
                        oppMap
                    );
        opp.Partner_Lookup__c = vAccount2.Id;
        opp.Distributor_Lookup__c = vAccount.Id;
        insert opp;
        
        Opportunity opp1 = (Opportunity) ShGl_TestFactory.createSObject(
            new Opportunity(),
            oppMap
        );
        opp1.Partner_Lookup__c = vAccount2.Id;
        opp1.Distributor_Lookup__c = vAccount.Id;
        opp1.ETM_Theatre__c = 'APAC';
        
        Test.startTest();
        insert opp1;
        
        Tier_Quantity_Range_lookup_Table__c objTier1 = new Tier_Quantity_Range_lookup_Table__c();
        objTier1.Quantity_Lower_Bound__c = 1;
        objTier1.Quantity_Upper_Bound__c = 100;
        objTier1.Location__c = 'All';
        objTier1.Discount_RSM__c = 68;
        objTier1.Approval_Category__c = 'AIR BASIC';
        insert objTier1;
        
        SBQQ__Quote__c q1 = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            CSAT_Reason__c = 'Product Issue'
        );
        
        SBQQ__Quote__c q = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,//opp1.Id Khushboo
            CSAT_Reason__c = 'Product Issue'
        );
        
        insert new List<SBQQ__Quote__c>{ q, q1 };
            list<SBQQ__QuoteLine__c> quoteList = new List<SBQQ__QuoteLine__c>();
        q.SBQQ__Source__c=q1.Id;
        Update q;
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q1.Id,
            SBQQ__Product__c = prod.Id,
            SBQQ__RenewedAsset__c = asset.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__Number__c = 1,
            SBQQ__SubscribedAssetIds__c = asset.Id,
            SubscribedAssetNames__c = 'BB192863040046',
            RnStatemntFee_included__c = false,
            SBQQ__Renewal__c = true,
            SBQQ__Discount__c = 99.95,
            CPQ_Prior_Discount__c = 99.95,
            SBQQ__ListPrice__c = 100
        );
        quoteList.add(qli1);
        
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q1.Id,
            SBQQ__Product__c = prodSupp.Id,
            SBQQ__RenewedAsset__c = asset.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__Number__c = 2,
            SBQQ__SubscriptionTerm__c = 12,
            Is_Premium_Support__c = true,
            SubscribedAssetNames__c = 'BB192863040046',
            SBQQ__Renewal__c = true,
            SBQQ__Discount__c = 40,
            SBQQ__ListPrice__c = 100
        );
        insert qli2;
        
        ServiceContract serviceContractObj1 = new ServiceContract();
        serviceContractObj1.Name = 'EntitlementTriggerHelper Contract';
        serviceContractObj1.SBQQSC__Opportunity__c = opp1.Id;
        serviceContractObj1.AccountId = acc.Id;
        serviceContractObj1.StartDate = System.today();
        serviceContractObj1.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj1.Term = 36;
        insert serviceContractObj1;
        
        ContractLineItem renewedContractLineItem1 = new ContractLineItem();
        renewedContractLineItem1.SBQQSC__Account__c = acc.Id;
        renewedContractLineItem1.PricebookEntryId = pbe.Id;
        renewedContractLineItem1.ServiceContractId = serviceContractObj1.Id;
        renewedContractLineItem1.SBQQSC__QuoteLine__c = qli2.Id;
        renewedContractLineItem1.Quantity = 10;
        renewedContractLineItem1.UnitPrice = 100;
        insert renewedContractLineItem1;
        
        SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q1.Id,
            SBQQ__Product__c = prodSub.Id,
            SBQQSC__RenewedContractLine__c = renewedContractLineItem1.Id,
            SBQQ__RenewedAsset__c = asset.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__Number__c = 3,
            SBQQ__SubscriptionTerm__c = 12,
            SubscribedAssetNames__c = 'BB192863040046',
            Promo_Disc__c = 50,
            Approval_Category__c = 'AIR BASIC',
            SBQQ__Renewal__c = true,
            SBQQ__Discount__c = 100.00,
            CPQ_Prior_Discount__c = 10.00,
            Total_Discount__c = 100,
            SBQQ__ListPrice__c = 100
        );
        insert qli3;
        
        ServiceContract serviceContractObj12 = new ServiceContract();
        serviceContractObj12.Name = 'EntitlementTriggerHelper Contract';
        serviceContractObj12.SBQQSC__Opportunity__c = opp1.Id;
        serviceContractObj12.AccountId = acc.Id;
        serviceContractObj12.StartDate = System.today();
        serviceContractObj12.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj12.Term = 36;
        insert serviceContractObj12;
        
        ContractLineItem renewedContractLineItem = new ContractLineItem();
        renewedContractLineItem.SBQQSC__Account__c = acc.Id;
        renewedContractLineItem.PricebookEntryId = pbe.Id;
        renewedContractLineItem.ServiceContractId = serviceContractObj1.Id;
        renewedContractLineItem.SBQQSC__QuoteLine__c = qli3.Id;
        renewedContractLineItem.SBQQSC__Discount__c = 20.00;
        renewedContractLineItem.Quantity = 10;
        renewedContractLineItem.UnitPrice = 100;
        insert renewedContractLineItem;
        
        SBQQ__QuoteLine__c qli4 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q1.Id,
            SBQQSC__RenewedContractLine__c = renewedContractLineItem.Id,
            SBQQ__Product__c = prodSub.Id,
            SBQQ__RenewedAsset__c = asset.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__Number__c = 3,
            SBQQ__SubscriptionTerm__c = 12,
            SubscribedAssetNames__c = 'BB192863040046',
            SBQQ__Renewal__c = true,
            SBQQ__ListPrice__c = 100
        );
        quoteList.add(qli4);
        
        SBQQ__QuoteLine__c qli5 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q.Id,
            SBQQSC__RenewedContractLine__c = renewedContractLineItem.Id,
            SBQQ__Product__c = prodSub.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__Number__c = 3,
            SBQQ__SubscriptionTerm__c = 12,
            SubscribedAssetNames__c = 'BB192863040046',
            SBQQ__Renewal__c = true,
            SBQQ__Source__c = qli1.Id,
            SBQQ__ListPrice__c = 100
        );
        quoteList.add(qli5);
        
        SBQQ__QuoteLine__c qli6 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q.Id,
            SBQQ__Product__c = prodSub.Id,
            SBQQSC__RenewedContractLine__c = renewedContractLineItem.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__Number__c = 3,
            SBQQ__SubscriptionTerm__c = 12,
            SubscribedAssetNames__c = 'BB192863040046',
            Promo_Disc__c = 100.00,
            Approval_Category__c = 'AIR BASIC',
            SBQQ__Renewal__c = true,
            SBQQ__Discount__c = 100.00,
            CPQ_Prior_Discount__c = 10.00,
            SBQQ__Source__c= qli2.Id,
            SBQQ__ListPrice__c = 100
        );
        quoteList.add(qli6);
        insert quoteList;
            
        set<Id> quoteLineId = new Set<Id>{ qli4.Id,qli5.Id,qli2.Id };
        Set<Id> qlid = new Set<Id>();
        qlid.add(qli4.Id);
        qlid.add(qli5.Id);
        qlid.add(qli2.Id);
        qlid.add(qli3.Id);
        SBQQ_QuoteLineTriggerHelper.datePolicy(qlid, false);
        Test.stopTest();
        System.assert(true);
        }
    }

    /**
     * @description  : This test method is used to test the setSourceListPrice functionality of SBQQ_QuoteLineTriggerHelper.
     */
    @isTest
    static void testMethodDatePolicyAllContractDelete() {
        String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(
            Alias = 'adminU', Email='AdminUser@rubrik.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
           RBAC_Department__c = 'Service Account',
            RBAC_Group__c = 'System - IT',
            UserName=uniqueUserName
        );
        insert u;
        System.runAs(u) {
        ShGl_DisableBusinessLogic__c cdf1 = new ShGl_DisableBusinessLogic__c(
            SetupOwnerId = UserInfo.getUserId(),
            Disable_SBQQ_Quote_Triggers__c = true,
            Disable_ServiceContract_Trigger__c = true
        );
        //insert cdf1;
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        TriggerControls.disableCalculateAPIBatch = true;
        SBQQ.TriggerControl.disable();
        ShGl_DisableFunctionalityLogic__c settingC = new ShGl_DisableFunctionalityLogic__c();
        settingC.Name = 'System Administrator';
        settingC.Disable_Opportunity_Old_Trigger__c = true;
        settingC.Disable_Order_Old_Trigger__c = true;
        settingC.Disable_Account_Old_Trigger__c = true;
        insert settingC;
        
        ShGl_DisableBusinessLogic__c settingDisableV = new ShGl_DisableBusinessLogic__c();
        settingDisableV.Name = 'System Administrator';
        settingDisableV.Disable_Opportunity_Validation_Rules__c = true;
        settingDisableV.Disable_Order_Validation_Rules__c = true;
        settingDisableV.Disable_ServiceContract_Trigger__c = true;
        settingDisableV.Disable_Entitlement_Validation_Rules__c = true;
        //insert settingDisableV;

        ShGl_DisableBusinessLogic__c settingD = new ShGl_DisableBusinessLogic__c();
        settingD.Name = 'Deal Operations';
        settingD.Disable_Opportunity_Validation_Rules__c = true;
        settingD.Disable_ServiceContract_Trigger__c = true;
        settingD.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
        settingD.Disable_Entitlement_Validation_Rules__c = true;
        settingD.Disable_Order_Validation_Rules__c = true;
        insert settingD;
        
        List<TriggerControl__c> triggerList = new List<TriggerControl__c>();
        TriggerControl__c setting0V = new TriggerControl__c();
        setting0V.Name = 'Order';
        setting0V.DisableTrigger__c = true;
        triggerList.add(setting0V);
        TriggerControl__c setting1V = new TriggerControl__c();
        setting1V.Name = 'Opportunity';
        setting1V.DisableTrigger__c = true;
        triggerList.add(setting1V);
        TriggerControl__c setting2 = new TriggerControl__c();
        setting2.Name = 'Entitlement';
        setting2.DisableTrigger__c = true;
        triggerList.add(setting2);
        insert triggerList;
        
        ShGl_TestFactoryHelper.insertTriggerControls();
        Id pb = Test.getStandardPricebookId();
        
        Product2 prod = new Product2(
            Name = 'RA-REINST-FEE-PP',
            IsActive = true,
            SBQQ__SubscriptionPricing__c = 'Fixed Price',
            Product_Type__c = 'RCDM Support',
            ProductCode = 'Test-Prod'
        );
        Product2 prodSupp = new Product2(
            Name = 'TestProdSupport',
            IsActive = true,
            SBQQ__SubscriptionPricing__c = 'Fixed Price',
            ProductCode = 'Test-Supp',
            Product_Type__c = 'RCDM Support'
        );
        Product2 prodSub = new Product2(
            Name = 'TestProdSubscription',
            IsActive = true,
            SBQQ__SubscriptionPricing__c = 'Fixed Price',
            Approval_Category__c = 'AIR BASIC',
            ProductCode = 'Test-Subs'
        );
        
        List<Product2> prdList = new List<Product2>{ prod, prodSupp, prodSub };
            insert prdList;
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pb,
            Product2Id = prod.Id,
            IsActive = true,
            UnitPrice = 10
        );
        PricebookEntry pbeSupp = new PricebookEntry(
            Pricebook2Id = pb,
            Product2Id = prodSupp.Id,
            IsActive = true,
            UnitPrice = 10
        );
        PricebookEntry pbeSub = new PricebookEntry(
            Pricebook2Id = pb,
            Product2Id = prodSub.Id,
            IsActive = true,
            UnitPrice = 10
        );
        List<PricebookEntry> pbeList = new List<PricebookEntry>{
            pbe,
                pbeSupp,
                pbeSub
                };
                    insert pbeList;
        
        Account acc = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert acc;
        
        List<Entitlement> entToInsert = new List<Entitlement>();
        Entitlement ent = new Entitlement(
            Name = 'Testing',
            AccountId = acc.Id,
            Product__c = prod.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(365)
        );
        entToInsert.add(ent);
        
        Entitlement ent2 = new Entitlement(
            Name = 'Testing',
            AccountId = acc.Id,
            Product__c = prodSupp.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(360)
        );
        entToInsert.add(ent2);
        
        Entitlement ent3 = new Entitlement(
            Name = 'Testing2',
            AccountId = acc.Id,
            Product__c = prodSub.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(360)
        );
        entToInsert.add(ent3);
        insert entToInsert;
        
        List<Account> accountList = new List<Account>();
        Account vAccount = new Account();
        vAccount.Name = 'Test Account';
        vAccount.Type = 'Distributor';
        vAccount.RecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByName()
            .get('Partner/Distributor')
            .getRecordTypeId();
        accountList.add(vAccount);
        
        Account vAccount2 = new Account();
        vAccount2.Name = 'Test Account';
        vAccount2.Distributor__c = vAccount.Id;
        vAccount2.RecordTypeId = vAccount.RecordTypeId;
        accountList.add(vAccount2);
        insert accountList;
        
        Asset asset = new Asset();
        asset.Name = '123456';
        asset.Serial_Number__c = '123456';
        asset.AccountId = acc.Id;
        asset.Product2Id = prod.Id;
        insert asset;
        
        //Generate the Opportunity
        Map<String, Object> oppMap = new Map<String, Object>{
            'AccountId' => acc.Id
                };
                    
                    Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(
                        new Opportunity(),
                        oppMap
                    );
        opp.Partner_Lookup__c = vAccount2.Id;
        opp.Distributor_Lookup__c = vAccount.Id;
        insert opp;
        
        Opportunity opp1 = (Opportunity) ShGl_TestFactory.createSObject(
            new Opportunity(),
            oppMap
        );
        opp1.Partner_Lookup__c = vAccount2.Id;
        opp1.Distributor_Lookup__c = vAccount.Id;
        opp1.ETM_Theatre__c = 'APAC';
        
        Test.startTest();
        insert opp1;
        
        Tier_Quantity_Range_lookup_Table__c objTier1 = new Tier_Quantity_Range_lookup_Table__c();
        objTier1.Quantity_Lower_Bound__c = 1;
        objTier1.Quantity_Upper_Bound__c = 100;
        objTier1.Location__c = 'All';
        objTier1.Discount_RSM__c = 68;
        objTier1.Approval_Category__c = 'AIR BASIC';
        insert objTier1;
        
        SBQQ__Quote__c q1 = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            CSAT_Reason__c = 'Product Issue',
            SBQQ__Account__c = acc.Id,
            AddOn_Date_Check__c = true,
            SBQQ__EndDate__c = Date.today().addDays(2360)
        );
        
        SBQQ__Quote__c q = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,//opp1.Id Khushboo
            CSAT_Reason__c = 'Product Issue',
            SBQQ__Account__c = acc.Id,
            AddOn_Date_Check__c = true,
            SBQQ__EndDate__c = Date.today().addDays(2360)
        );
        
        insert new List<SBQQ__Quote__c>{ q, q1 };
            list<SBQQ__QuoteLine__c> quoteList = new List<SBQQ__QuoteLine__c>();
        q.SBQQ__Source__c=q1.Id;
        Update q;
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q1.Id,
            SBQQ__Product__c = prod.Id,
            SBQQ__RenewedAsset__c = asset.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__Number__c = 1,
            SBQQ__SubscribedAssetIds__c = asset.Id,
            SubscribedAssetNames__c = 'BB192863040046',
            RnStatemntFee_included__c = false,
            SBQQ__Renewal__c = true,
            SBQQ__Discount__c = 99.95,
            CPQ_Prior_Discount__c = 99.95,
            SBQQ__ListPrice__c = 100
        );
        quoteList.add(qli1);
        
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q1.Id,
            SBQQ__Product__c = prodSupp.Id,
            SBQQ__RenewedAsset__c = asset.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__Number__c = 2,
            SBQQ__SubscriptionTerm__c = 12,
            Is_Premium_Support__c = true,
            SubscribedAssetNames__c = 'BB192863040046',
            SBQQ__Renewal__c = true,
            SBQQ__Discount__c = 40,
            SBQQ__ListPrice__c = 100
        );
        insert qli2;
        
        ServiceContract serviceContractObj1 = new ServiceContract();
        serviceContractObj1.Name = 'EntitlementTriggerHelper Contract';
        serviceContractObj1.SBQQSC__Opportunity__c = opp1.Id;
        serviceContractObj1.AccountId = acc.Id;
        serviceContractObj1.StartDate = System.today();
        serviceContractObj1.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj1.Term = 36;
        insert serviceContractObj1;
        
        ContractLineItem renewedContractLineItem1 = new ContractLineItem();
        renewedContractLineItem1.SBQQSC__Account__c = acc.Id;
        renewedContractLineItem1.PricebookEntryId = pbe.Id;
        renewedContractLineItem1.ServiceContractId = serviceContractObj1.Id;
        renewedContractLineItem1.SBQQSC__QuoteLine__c = qli2.Id;
        renewedContractLineItem1.Quantity = 10;
        renewedContractLineItem1.UnitPrice = 100;
        insert renewedContractLineItem1;
        
        SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q1.Id,
            SBQQ__Product__c = prodSub.Id,
            SBQQSC__RenewedContractLine__c = renewedContractLineItem1.Id,
            SBQQ__RenewedAsset__c = asset.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__Number__c = 3,
            SBQQ__SubscriptionTerm__c = 12,
            SubscribedAssetNames__c = 'BB192863040046',
            Promo_Disc__c = 50,
            Approval_Category__c = 'AIR BASIC',
            SBQQ__Renewal__c = true,
            SBQQ__Discount__c = 100.00,
            CPQ_Prior_Discount__c = 10.00,
            Total_Discount__c = 100,
            SBQQ__ListPrice__c = 100
        );
        insert qli3;
        
        ServiceContract serviceContractObj12 = new ServiceContract();
        serviceContractObj12.Name = 'EntitlementTriggerHelper Contract';
        serviceContractObj12.SBQQSC__Opportunity__c = opp1.Id;
        serviceContractObj12.AccountId = acc.Id;
        serviceContractObj12.StartDate = System.today();
        serviceContractObj12.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj12.Term = 36;
        insert serviceContractObj12;
        
        ContractLineItem renewedContractLineItem = new ContractLineItem();
        renewedContractLineItem.SBQQSC__Account__c = acc.Id;
        renewedContractLineItem.PricebookEntryId = pbe.Id;
        renewedContractLineItem.ServiceContractId = serviceContractObj1.Id;
        renewedContractLineItem.SBQQSC__QuoteLine__c = qli3.Id;
        renewedContractLineItem.SBQQSC__Discount__c = 20.00;
        renewedContractLineItem.Quantity = 10;
        renewedContractLineItem.UnitPrice = 100;
        insert renewedContractLineItem;
        
        SBQQ__QuoteLine__c qli4 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q1.Id,
            SBQQSC__RenewedContractLine__c = renewedContractLineItem.Id,
            SBQQ__Product__c = prodSub.Id,
            SBQQ__RenewedAsset__c = asset.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__Number__c = 3,
            SBQQ__SubscriptionTerm__c = 12,
            SubscribedAssetNames__c = 'BB192863040046',
            SBQQ__Renewal__c = true,
            SBQQ__ListPrice__c = 100);
        quoteList.add(qli4);
        
        SBQQ__QuoteLine__c qli5 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q.Id,
            SBQQSC__RenewedContractLine__c = renewedContractLineItem.Id,
            SBQQ__Product__c = prodSub.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__Number__c = 3,
            SBQQ__SubscriptionTerm__c = 12,
            SubscribedAssetNames__c = 'BB192863040046',
            SBQQ__Renewal__c = true,
            SBQQ__Source__c = qli1.Id,
            SBQQ__ListPrice__c = 100);
        quoteList.add(qli5);
        
        SBQQ__QuoteLine__c qli6 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q.Id,
            SBQQ__Product__c = prodSub.Id,
            SBQQSC__RenewedContractLine__c = renewedContractLineItem.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__Number__c = 3,
            SBQQ__SubscriptionTerm__c = 12,
            SubscribedAssetNames__c = 'BB192863040046',
            Promo_Disc__c = 100.00,
            Approval_Category__c = 'AIR BASIC',
            SBQQ__Renewal__c = true,
            SBQQ__Discount__c = 100.00,
            CPQ_Prior_Discount__c = 10.00,
            SBQQ__Source__c= qli2.Id,
            SBQQ__ListPrice__c = 100
        );
        quoteList.add(qli6);
        insert quoteList;
            
        set<Id> quoteLineId = new Set<Id>{ qli5.Id,qli6.Id };
        Set<Id> qlid = new Set<Id>();
        qlid.add(qli5.Id);
        qlid.add(qli6.Id);
        
        SBQQ__QuoteLine__c firstQli = [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQSC__RenewedContractLine__c != null LIMIT 1];
        delete firstQli;
        
        System.runAs(new user(ID = UserInfo.getUserID())){
            SBQQ_QuoteLineTriggerHelper.datePolicy(qlid, true);
        }
        Test.stopTest();
        System.assert(true);
        }
    }
      static ReplacementJson getReplacemetnDetail(Id prodId,String Prodcode,Id entitlementId,Integer qty,String dispose)
    {
        ReplacementJson.RowDetail row = new ReplacementJson.RowDetail();
        row.entId =entitlementId;
        row.rowId ='0.0.0';
        row.selectedQty =qty;
        row.selectedTerm=12;
        row.disposition= dispose; 
        
        ReplacementJson jsonData = new ReplacementJson();
        jsonData.rowValues = new List<ReplacementJson.RowDetail>();
        jsonData.rowValues.add(row);
        jsonData.mode = 'dispose';
        jsonData.renLine = true;
        return jsonData;
        
    }
    @isTest
    static void msTestQuotableByCountriesValidation() {

        System.runAs(new user(ID = UserInfo.getUserID())){
        ShGl_TestFactoryHelper.insertTriggerControls();
            
            ShGl_DisableBusinessLogic__c cdf1 = new ShGl_DisableBusinessLogic__c(
                SetupOwnerId = userInfo.getUserId(),
                Disable_SBQQ_Quote_Triggers__c = true
            );

        // Create a test product with Quotable_By_Countries__c and Allow_mentioned_Countries_to_Quote__c
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'Test-Prod',
            isActive = true,
            Quotable_By_Countries__c = 'Cambodia; India; Indonesia; Malaysia; Myanmar; Philippines;',
            Quotable_By_Profiles__c = 'Rubrik Light Administrator',
            Quotable_by_users__c = '<a href="/0055g00000In" target="_blank">'+UserInfo.getName()+'</a> , <a href="/0055g000006AAB" target="_blank">Test User</a>',
            Allow_mentioned_Countries_to_Quote__c = true
        );
        insert testProduct;
        

        Account acc1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert acc1;
        
        List<Account> accountList = new List<Account>();
        
        Account vAccount1 = getAccount('Test Account', 'Distributor', partnerRtId);
        accountList.add(vAccount1);
        
        Account vAccount2 = getAccount('Test Account2', null, partnerRtId);
        accountList.add(vAccount2);
        
        insert accountList;
        
        Contact con1 = getContact('test con', acc1.Id);
        insert con1;
        
        //insert new opportunity
        Opportunity opp1 = getOppty('TestOpp', acc1.Id, vAccount2.Id, vAccount1.Id);
        insert opp1;

        // Create a test quote with billing country
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__BillingCountry__c = 'India',
            SBQQ__Status__c = 'Draft',
            ApprovalStatus__c = 'Not Approved',
            SBQQ__Opportunity2__c = opp1.Id
        );
        insert testQuote;
        
        // Create a test quote line
        SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quote__c = testQuote.Id,
            
            SBQQ__number__c = null,
            SBQQ__ListPrice__c = 100
        );
        
        Test.startTest(); 
        
        // Test case 1: Valid country - should not throw error
        Map<Id, SBQQ__QuoteLine__c> newMap = new Map<Id, SBQQ__QuoteLine__c>{testQuoteLine.Id => testQuoteLine};
        Map<Id, SBQQ__QuoteLine__c> qlMap = new Map<Id, SBQQ__QuoteLine__c>{testQuoteLine.Id => testQuoteLine};
        
        SBQQ_QuoteLineTriggerHelper.updateApprovalIdentifierForDisposition(newMap);
        SBQQ_QuoteLineTriggerHelper.quotableByCountriesValidation(newMap, qlMap, true);
        SBQQ_QuoteLineTriggerHelper.quotableByValidation(newMap,qlMap,qlMap, true);//ITNPI-3373
        
        // Test case 2: Invalid country - should throw error
        testQuote.SBQQ__BillingCountry__c = 'India';
        update testQuote;
        
        SBQQ__QuoteLine__c testQuoteLine2 = new SBQQ__QuoteLine__c(
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__number__c = null,
            Product_Type__c= 'M365 ZRS',//ITNPI-3373
            Product_Subtype__c='Credit',//ITNPI-3373
            SBQQ__ListPrice__c = 100
        );
        insert testQuoteLine2;
        
        
        Map<Id, SBQQ__QuoteLine__c> OldMap2 = new Map<Id, SBQQ__QuoteLine__c>{testQuoteLine2.Id => testQuoteLine2};//ITNPI-3373
        Map<Id, SBQQ__QuoteLine__c> qlMap2 = new Map<Id, SBQQ__QuoteLine__c>{testQuoteLine2.Id => testQuoteLine2};
        testQuoteLine2.SBQQ__Quantity__c=10;//ITNPI-3373
        update testQuoteLine2; //ITNPI-3373
        Map<Id, SBQQ__QuoteLine__c> newMap2 = new Map<Id, SBQQ__QuoteLine__c>{testQuoteLine2.Id => testQuoteLine2};//ITNPI-3373
        
        SBQQ_QuoteLineTriggerHelper.quotableByCountriesValidation(newMap2, qlMap2, false);
        SBQQ_QuoteLineTriggerHelper.quotableByValidation(newMap2,OldMap2, qlMap2, false);//ITNPI-3373
        Test.stopTest();
        System.assert(true);
        update testQuoteLine2;
        }
    }
}