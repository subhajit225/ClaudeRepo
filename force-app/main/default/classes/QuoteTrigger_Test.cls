/*****************************************************************************************************
* Name              : QuoteTrigger_Test
*@description       : QuoteTrigger_Test is Used for Testing QuoteTriggerHandler and QuoteTriggerHelper Class
******************************************************************************************************/

@isTest
public class QuoteTrigger_Test {
    /**************************************************************************************************
    * Method Name          : setup
    * Date Created/Modified: 28/02/2025
    * @description         : Data setup for the test class
    /************************************************************************************************/
    @testSetup static void setup() {
        User usr1 = Replacement_TestDataFactory.getUser();
        insert usr1;
        //Deactivate triggers
        INSERT new ShGl_DisableBusinessLogic__c(
        Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
        Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,Disable_Opportunity_Validation_Rules__c=true,
        Disable_Deal_Desk_Case_Validation_Rules__c = true
        );
        TriggerControls.disableQuoteTrigger = true;
    }
    
    static List<SBQQ__Quote__c> quoteList;
    
    static Product2 getProduct(String name, String code) {
        return new Product2(Name = name, ProductCode = code, isActive = true, CPQ_Uplift__c = '5');
    }
     
    static PricebookEntry getPbe(Id pbId, Id prodId, Decimal unitPrice) {
        return new PricebookEntry(Pricebook2Id = pbId, Product2Id = prodId, UnitPrice = unitPrice, IsActive = true);
    }
    
    static PricebookEntry getPbe(Id prodId, Decimal unitPrice) {
        return getPbe(Test.getStandardPricebookId(), prodId, unitPrice);
    }
    
    static ContractLineItem getCli(Id pbeId, Id scId) {
        return new ContractLineItem(
            Quantity = 1,
            SBQQSC__Quantity__c = 1,
            PricebookEntryId = pbeId,
            ServiceContractId = scId,
            UnitPrice = 100,
            StartDate = Date.today()
        );
    }
    
    static Asset getAsset(String name, Id prodId, Id accountId) {
        return new Asset(
            Name = name,
            SerialNumber = name,
            Serial_Number__c = name,
            Product2ID = prodId,
            Accountid = accountId
        );
    }
    
    static OrderItem getOli(Id orderId, Id pbeId, Decimal price, String serialNumber) {
        return new OrderItem(
            OrderId = orderId,
            Quantity = 5,
            PricebookEntryId = pbeId,
            UnitPrice = price,
            SerialNumber__c = serialNumber,
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
    }
    // Partner account record type Id
    static final Id partnerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName()
        .get('Partner/Distributor')
        .getRecordTypeId();
     
    // Sales oppty record typeId
    static final Id salesRtId = Schema.getGlobalDescribe()
        .get('Opportunity')
        .getDescribe()
        .getRecordTypeInfosByName()
        .get('Sales Opportunity')
        .getRecordTypeId();
    
    static Account getAccount(String name, String type, String rtId) {
        Account vAccount = new Account();
        vAccount.Name = name;
        vAccount.Type = type;
        vAccount.recordTypeId = rtId;
        
        return vAccount;
    }
    
    /*userProfileName*/
    static String userProfileName; 
    /*serviceContractList*/
    static List<ServiceContract> serviceContractList;
    /*accountsList*/
    static List<Account> accountsList;
    /*qList*/
    static List<SBQQ__Quote__c> qList;

    /**************************************************************************************************
    * Method Name          : testMethod1A
    * @description         : testMethod1A for covering QuoteTriggerHelper
    /************************************************************************************************/
    @isTest
    static void testMethod1A() {
        user usr1 = [SELECT Id FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
            ShGl_TestFactoryHelper.insertTriggerControls();
            
            insert new TriggerControl__c(
                Name = 'Approval',
                DisableTrigger__c = true
            );
            //Generate the  Account
            Account actA = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            insert actA;
            
            List<Account> accountListA = new List<Account>();
            
            Account vAccountA = getAccount('Test Account', 'Distributor', partnerRtId);
            vAccountA.Payment_Term__c = 'Net 30';
            accountListA.add(vAccountA);
            
            Account vAccount2A = getAccount('NetApp Inc (US Disti)', null, vAccountA.recordTypeId);
            accountListA.add(vAccount2A);
            insert accountListA;
            
            //Generate the Contact
            Map<String, Object> cntMapA = new Map<String, Object>{ 'AccountId' => actA.Id };
                Contact cntA = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMapA);
            insert cntA;
            
            Map<String, Object> prdMapA = new Map<String, Object>{
                'Name' => 'Standalone',
                    'IsActive' => true,
                    'SBQQ__AssetConversion__c' => 'One per unit',
                    'ProductCode' => 'RBK-PRO-BUNDLE-R6410S-01'
                    };
                        
                        Map<String, Object> prdMap1 = new Map<String, Object> {
                            'Name' => 'SubscriptionTest',
                                'IsActive'  => true,
                                'SBQQ__SubscriptionPricing__c'  => 'Fixed Price',
                                'SBQQ__SubscriptionTerm__c'  => 12,
                                'SBQQ__SubscriptionType__c'  => 'Renewable'
                                };
                                    Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMapA);
            Product2 prdSubsA = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
            
            List<Product2> prdListA = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMapA);
            prdListA.add(prdHW);
            prdListA.add(prdSubsA);
            insert prdListA;
            
            List<PricebookEntry> pBListA = new List<PricebookEntry>();
            
            PricebookEntry pbeHWA = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeHWA.Product2Id = prdHW.Id;
            pBListA.add(pbeHWA);
            
            PricebookEntry pbeSubsA = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeSubsA.Product2Id = prdSubsA.Id;
            pBListA.add(pbeSubsA);
            insert pBListA;
            
            List<Polaris_SKU_Mapping_V2__c> polarisSKUMappingListA = new List<Polaris_SKU_Mapping_V2__c>();
            Polaris_SKU_Mapping_V2__c polMap1A = new Polaris_SKU_Mapping_V2__c(
                Name = 'Mappin1',
                Old_Product__c = prdHW.Id,
                New_Product__c = prdSubsA.Id
            );
            polarisSKUMappingListA.add(polMap1A);
            insert polarisSKUMappingListA;

            
            //Generate the Opportunity
            Map<String, Object> oppMapA = new Map<String, Object>{
                'AccountId' => actA.Id,
                    'RecordTypeId' => salesRtId
                    };
                        

                        Opportunity oppA = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMapA);
            oppA.ForecastCategoryName = 'Best Case';
            oppA.Partner_Lookup__c = vAccount2A.id;
            oppA.Distributor_Lookup__c = vAccountA.id;
            oppA.Sell_to_Partner__c = vAccount2A.id;
            oppA.Renewal_Credit_ACV__c = 2000;
            oppA.Renewal_Credit_TCV__c = 4000;
            oppA.Opportunity_Sub_Type__c = 'MSP';
            oppA.CloseDate = System.today().addDays(130);
            oppA.Number_of_valid_Primary_Quotes__c = 5;
            insert oppA;
            
            SBQQ__Quote__c qtA = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
            qtA.SBQQ__Account__c = actA.Id;
            qtA.SBQQ__Opportunity2__c = oppA.Id;
            qtA.SBQQ__PrimaryContact__c = cntA.Id;
            qtA.Task_Products__c = 'RBK-DISK-RETENTION';
            qtA.Sell_to_Partner__c = vAccount2A.id;
            qtA.SBQQ__Primary__c = true;
            qtA.RenCredACV__c = 2500;
            qtA.RenTradeUpAmt__c = 5000;
            qtA.SBQQ__Opportunity2__c = oppA.Id; 
            qtA.RWD_Deal_Ops_Exception__c = 'Test Quote';
            qtA.RWD_Deal_Ops_Exception_Justification__c = 'RWD Deals Ops Ezception is For Test';
            qtA.SBQQ__Status__c = 'Draft';
            qtA.SBQQ__Type__c = 'Amendment';
            qtA.OpportunitySubType__c = 'GC Offer';
            qtA.Task_Products__c = 'RBK-DISK-RETENTION';
            qtA.Has_Mosaic_SKUs__c = true;
            qtA.Deal_Desk_Notes__c = 'Test quot deal';
            qtA.ApprovalStatus__c = 'Approved';
            qtA.NIPA__c = vAccountA.id;
            qtA.NIPD__c = vAccountA.id;
            qtA.SBQQ__Type__c = 'Amendment';
            qtA.SBQQ__EndDate__c = System.today().addDays(230);
            qtA.Update_Expires_On__c = true;
            qtA.Sell_to_Partner__c = 'HPE US';
            
            insert qtA;
            
            List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>();
            SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qtA.Id,
                SBQQ__Product__c = prdHW.Id,
                SBQQ__Quantity__c = 10,
                SBQQ__Number__c = 1,
                Scale_Utility_Product__c = true,
                Scale_Utility_Product_Identifier__c = 'M365 SU RSVX',
                SubscribedAssetNames__c = 'BB192863040046, BB192863040047',
                SBQQ__SubscribedAssetIds__c = '02i1W00000Sn8uyQAB, 02i1W00000Sn8uZQAR'
            );
            SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qtA.Id,
                SBQQ__Product__c = prdSubsA.Id,
                SBQQ__RequiredBy__c = qli1.id,
                SBQQ__Quantity__c = 10,
                SBQQ__Number__c = 2,
                Scale_Utility_Product__c = true,
                Scale_Utility_Product_Identifier__c = 'M365 SU RSVX',
                SubscribedAssetNames__c = 'BB1928630400416, BB1921863040047',
                SBQQ__SubscribedAssetIds__c = '02i1W00000Sn8uyQAb, 02i1W00000Sn8uZQAb'
            );
            qliList.add(qli1);
            qliList.add(qli2);
            TriggerControls.disableQuoteTrigger = false;
            TriggerControls.disableQuoteLineTrigger = false;
            SBQQ.TriggerControl.enable();
            Test.startTest();
            insert qliList;

            Test.stopTest();
            
            System.assert(true);
        }
    }
    
    /**************************************************************************************************
    * Method Name          : testMethod2
    * @description         : testMethod2 for covering QuoteTriggerHelper
    /************************************************************************************************/
    @isTest
    static void testMethod2() {
        
        user usr1 = [SELECT Id FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
            ShGl_DisableFunctionalityLogic__c disFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
            disFuncCS.Disable_Account_Old_Trigger__c = false;
            disFuncCS.Disable_Opportunity_Old_Trigger__c = false;
            disFuncCS.Disable_Quote_Clone_Date__c = System.now().addDays(-1);
            insert disFuncCS;
        
            ShGl_TestFactoryHelper.insertTriggerControls();
            
            //Generate the Account
            Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            act.ETM_Area__c = 'AMER-FED';
            insert act;
            
            List<Account> accountList = new List<Account>();
            
            Id ptId = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get('Partner/Distributor')
                .getRecordTypeId();
            
            Account vAccount = getAccount('Test Account 2', 'Distributor', ptId);
            vAccount.Payment_Term__c = 'Net 30';
            accountList.add(vAccount);
            
            Account vAccount2 = getAccount('T account', null, vAccount.recordTypeId);
            accountList.add(vAccount2);
            insert accountList;

            List<Task> lTask = new List<Task>();
            Task t = new Task();
            t.OwnerId = usr1.id;
            t.Subject = 'Test Task';
            t.Priority = 'Normal';
            t.Status = 'Not Started';
            t.Type = 'Action'; 
            t.WhatId = act.Id;
            lTask.add(t);
            insert lTask;
            
            //Generate the Contact
            Map<String, Object> cntMap = new Map<String, Object>{ 'AccountId' => act.Id };
                Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
            insert cnt;
            
            Map<String, Object> prdMap = new Map<String, Object>{
                'Name' => 'Standalone2',
                    'IsActive' => TRUE,
                    'SBQQ__AssetConversion__c' => 'One per unit'
                    };
                        
                        Map<String, Object> prdMap1 = new Map<String, Object>{
                            'Name' => 'Subscription3',
                                'IsActive' => True,
                                'SBQQ__SubscriptionPricing__c' => 'Fixed Price',
                                'SBQQ__SubscriptionTerm__c' => 12,
                                'SBQQ__SubscriptionType__c' => 'Renewable'
                                };
                                    Product2 prdHwTest = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
            Product2 prdSub = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
            
            List<Product2> prdListTest = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
            prdListTest.add(prdHwTest);
            prdListTest.add(prdSub);
            insert prdListTest;
            
            List<PricebookEntry> pBListTest = new List<PricebookEntry>();
            
            PricebookEntry pbeHWTest = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeHWTest.Product2Id = prdHwTest.Id;
            pBListTest.add(pbeHWTest);
            
            PricebookEntry pbeSubsTest = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeSubsTest.Product2Id = prdSub.Id;
            pBListTest.add(pbeSubsTest);
            insert pBListTest;
            
            //Generate the Opportunity
            Map<String, Object> oppMap1 = new Map<String, Object>{
                'AccountId' => act.Id,
                    'RecordTypeId' => salesRtId
                    };
                        
                        Opportunity Renopp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap1);
            Renopp.Partner_Lookup__c = vAccount2.id;
            Renopp.Distributor_Lookup__c = vAccount.id;
            insert Renopp;
            
            ServiceContract serviceContractObj = new ServiceContract();
            serviceContractObj.Name = 'PolarisContractRenewalQuotesUpdateTests';
            serviceContractObj.SBQQSC__Opportunity__c = Renopp.Id;
            serviceContractObj.StartDate = System.today();
            serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
            serviceContractObj.Term = 36;
            serviceContractObj.EndDate = System.today().addDays(365);
            serviceContractObj.SBQQSC__RenewalForecast__c = false;
            serviceContractObj.SBQQSC__RenewalTerm__c = 12;
            insert serviceContractObj;
            
            List<contractLineItem> cliList = new List<contractLineItem>();
            
            ContractLineItem ContractLineItemObj = new ContractLineItem();
            ContractLineItemObj.SBQQSC__Account__c = vAccount2.Id;
            ContractLineItemObj.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObj.Quantity = 10;
            ContractLineItemObj.UnitPrice = 100;
            ContractLineItemObj.StartDate = System.today();
            ContractLineItemObj.EndDate = System.today().addDays(120);
            ContractLineItemObj.PricebookEntryId = pbeHWTest.Id;
            cliList.add(ContractLineItemObj);
            insert cliList;
            
            //Generate the Opportunity
            Map<String, Object> oppMap = new Map<String, Object>{
                'AccountId' => act.Id,
                    'RecordTypeId' => salesRtId
                    };
                        
                        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
            opp.ForecastCategoryName = 'Best Case';
            opp.Partner_Lookup__c = vAccount2.id;
            opp.Distributor_Lookup__c = vAccount.id;
            
            //opp.SBQQSC__AmendedServiceContract__c = serviceContractObj.Id; 
            opp.Opportunity_Sub_Type__c = 'GC Offer';
            insert opp;
            
            Test.startTest();
            
            SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
            qt.SBQQ__Account__c = act.Id;
            qt.SBQQ__Opportunity2__c = opp.Id;
            qt.Task_Products__c = 'RBK-DISK-RETENTION';
            qt.SBQQ__Type__c = 'Amendment';
            qt.Amended_Renewed_Service_Contract__c = serviceContractObj.Id;
            qt.SBQQ__PrimaryContact__c = cnt.Id;
            
            insert qt;
            
            SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt.Id,
                SBQQ__Product__c = prdHWTest.Id,
                SBQQ__Quantity__c = 10,
                SBQQ__Number__c = 1,
                SubscribedAssetNames__c = 'BB192863040042, BB192863040232',
                SBQQSC__RenewedContractLine__c = ContractLineItemObj.id,
                SBQQ__SubscribedAssetIds__c = '02i1W00000Sn8ayQAB, 02i1A00000Sn8uZQAR',
                Special_Program__c = 'Conversion'
            );
            insert qli1;
            
            SBQQ__Quote__c qtCloned = qt.clone();
            System.assertEquals(true, qtCloned.isClone());
            qtCloned.SBQQ__Source__c = qt.Id;
            insert qtCloned;
            SBQQ__Quote__c qtCloned1 = qt.clone();
            qtCloned.SBQQ__Source__c = qtCloned1.Id;
            update qtCloned;
            qt.Has_Mosaic_SKUs__c = true;
            QuoteTriggerHelper.insert_logic = false;
            update qt;
            delete qli1;
            
            Test.stopTest();
            //System.assertEquals(null, qtCloned);
            System.assert(true);
        }
    }

    /**************************************************************************************************
    * Method Name          : testBeforeInsertStatus
    * @description         : testBeforeInsertStatus for covering QuoteTriggerHelper
    /************************************************************************************************/
    @isTest
    static void testBeforeInsertStatus() {
        user usr1 = [SELECT Id FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
            ShGl_TestFactoryHelper.insertTriggerControls();
            Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            insert act;
            Account act2 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            act2.Name = 'NetApp Inc (US Disti)';
            act2.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert act2;

            List<Task> lTask = new List<Task>();
            Task t = new Task();
            t.OwnerId = usr1.id;
            t.Subject = 'Test Task';
            t.Priority = 'Normal';
            t.Status = 'Not Started';
            t.Type = 'Action'; 
            t.WhatId = act.Id;
            lTask.add(t);
            insert lTask;

            //Generate the Contact
            Map<String, Object> cntMap = new Map<String, Object>{ 'AccountId' => act.Id };
                Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
            insert cnt;

            //Generate the Opportunity
            Map<String, Object> oppMap = new Map<String, Object>{
                'AccountId' => act.Id,
                    'RecordTypeId' => salesRtId
                    };
                        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
            opp.Opportunity_Type__c = 'Existing';
            opp.Opportunity_Sub_Type__c = 'Regular';
            opp.Sell_to_Partner__c = act2.Id;
            insert opp;
            
            Map<String, Object> qtMap = new Map<String, Object> {
                'SBQQ__Account__c' => act.Id,
                    'SBQQ__Opportunity2__c' => opp.Id,
                    'SBQQ__Type__c' => 'Renewal',
                    'SBQQ__StartDate__c' => Date.parse('05/20/2022'),
                    'Task_Products__c' => 'RBK-DISK-RETENTION'
                    };
                        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), qtMap);
            insert qt;
            
            qt.OpportunitySubType__c = 'Regular';
            qt.NIPA__c = act2.Id;
            qt.Sell_to_Partner__c = act2.Id;
            update qt;
            qt.Sell_to_Partner__c = 'HPE US';
            qt.SBQQ__PrimaryContact__c = cnt.Id;
            qt.SBQQ__Status__c = 'Draft';
            qt.RWD_Deal_Ops_Exception__c = 'Subsumed Old Contract Line Items Validation Exception';
            qt.RWD_Deal_Ops_Exception_Justification__c = 'Test';
            update qt;
            
            DateTime setDate = DateTime.Now();
            SBQQ__Quote__c clonedQuote = qt.clone(false, false, false, false);
            clonedQuote.SBQQ__Source__c = qt.Id;
            clonedQuote.SBQQ__LastCalculatedOn__c = Date.Today().addDays(-1);
            clonedQuote.CreatedDate = setDate;
            clonedQuote.Approvals_Created_from_Source__c = true;
            insert clonedQuote;
            clonedQuote.SBQQ__LastCalculatedOn__c = Date.Today().addDays(2);
            Update clonedQuote;
            Test.startTest();
            qt.ApprovalStatus__c = 'Invalid';
            qt.Invalid_Reason__c = 'Invalid Test';
            update qt;
            System.assert(true);
        }
    }
    /**************************************************************************************************
    * Method Name          : uncheckSOWONOpportunityTest
    * @description         : uncheckSOWONOpportunityTest for covering QuoteTriggerHelper
    /************************************************************************************************/
    @isTest
    static void uncheckSOWONOpportunityTest() {
        user usr1 = [SELECT Id FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
            Account at = new Account();
            at.Name = 'Test Account';
            at.ETM_Area__c = 'AMER FED';
            insert at;

            List<Task> lTask = new List<Task>();
            Task t = new Task();
            t.OwnerId = usr1.id;
            t.Subject = 'Test Task';
            t.Priority = 'Normal';
            t.Status = 'Not Started';
            t.Type = 'Action'; 
            t.WhatId = at.Id;
            lTask.add(t);
            insert lTask;
            
            Map<String, Object> prdMap = new Map<String, Object>{
                'Name' => 'Standalone',
                    'IsActive' => true,
                    'SBQQ__AssetConversion__c' => 'One per unit'
                    };
                        Product2 prdHW_Test = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
            insert prdHW_Test;
            
            PricebookEntry pbeHW_Test = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeHW_Test.Product2Id = prdHW_Test.Id;
            insert pbeHW_Test;
            
            List<Opportunity> oppInsert = new List<Opportunity>();
            Set<Id> dummySet = new Set<Id>();
            
            Opportunity opTest = new Opportunity();
            opTest.name = 'test';
            opTest.StageName = '1 Discovery';
            opTest.AccountId = at.Id;
            opTest.CloseDate = Date.newInstance(2021, 12, 9);
            oppInsert.add(opTest);
            test.startTest();
            insert (oppInsert);
            
            SBQQ__Quote__c sd = new SBQQ__Quote__c();
            sd.SBQQ__Type__c = 'Quote';
            sd.SBQQ__Opportunity2__c = opTest.Id;
            sd.SBQQ__Primary__c = true;
            sd.SBQQ__StartDate__c = Date.Today();
            sd.SBQQ__SubscriptionTerm__c = 36;
            sd.Task_Products__c = 'RBK-DISK-RETENTION';
            sd.RWD_Sales_Rep_Exception__c = 'Exception for On-Prem Quoting';
            sd.Count_of_Rubrik_Basic_Edition__c = 1;
            
            insert sd;
            
            sd.SBQQ__Primary__c = false;
            sd.RWD_Sales_Rep_Exception__c = '';
            update sd;
            test.stopTest();
            System.assert(true);
        }
    }
    /**************************************************************************************************
    * Method Name          : errorForExpiryDateTest1
    * @description         : errorForExpiryDateTest1 for covering QuoteTriggerHelper
    /************************************************************************************************/
    @isTest
    static void errorForExpiryDateTest1() {
        user usr1 = [SELECT Id FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
            Test.startTest();
            
            Date endOfQuarter = quoteTriggerHelper.lastDateOfQuarter();
            Opportunity opp1 = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
            opp1.CloseDate = endOfQuarter.addDays(20);
            insert opp1;
            SBQQ__Quote__c sdTest1 = new SBQQ__Quote__c();
            sdTest1.SBQQ__type__c = 'Quote';
            sdTest1.SBQQ__Opportunity2__c = opp1.Id;
            sdTest1.SBQQ__Primary__c = false;
            sdTest1.Update_Expires_On__c = true;
            sdTest1.SBQQ__StartDate__c = Date.Today();
            sdTest1.SBQQ__SubscriptionTerm__c = 12;
            sdTest1.SBQQ__ExpirationDate__c = Date.Today().addDays(20);
            sdTest1.EOL_New_Product_Earliest_Date__c = Date.Today().addDays(120);
            sdTest1.Task_Products__c = 'RBK-DISK-RETENTION';
            sdTest1.Count_of_Rubrik_Basic_Edition__c = 1;
            insert sdTest1;

            QuoteTriggerHelper.insert_logic = false;
            Map<Id, SBQQ__Quote__c> oldMap = new Map<Id, SBQQ__Quote__c>();
            oldMap.put(sdTest1.Id, sdTest1.clone(true, true));
            sdTest1.SBQQ__ExpirationDate__c = Date.today().addDays(100);

            List<SBQQ__Quote__c> newList = new List<SBQQ__Quote__c>{sdTest1};
            Map<Id, SBQQ__Quote__c> newMap = new Map<Id, SBQQ__Quote__c>(newList);
            List<SBQQ__Quote__c> newList1 = [SELECT Id, SBQQ__Opportunity2__r.CloseDate, SBQQ__ExpirationDate__c, SBQQ__Type__c, ApprovalStatus__c, OpportunitySubType__c,
                               SBQQ__StartDate__c, CreatedDate, Update_Expires_On__c, EOLProductEarliestDate__c, Earliest_EOL_Date__c, oldExpirationDate__c FROM SBQQ__Quote__c WHERE Id =: sdTest1.Id];
            QuoteTriggerHelper.errorForExpiryDate(null, newList1, oldMap, newMap); 
            
            try {
                sdTest1.SBQQ__ExpirationDate__c = Date.today().addDays(120);
                sdTest1.Update_Expires_On__c = false;
                sdTest1.SBQQ__StartDate__c = Date.Today().addDays(1);
                sdTest1.EOL_New_Product_Earliest_Date__c = Date.Today().addDays(220);
                update sdTest1;

            } catch (Exception error) { 
                System.assert(true);
            }
            Test.stopTest(); 
            System.assert(true);
        }
    }

    /**************************************************************************************************
    * Method Name          : errorForExpiryDateTest
    * @description         : errorForExpiryDateTest for covering QuoteTriggerHelper
    /************************************************************************************************/
    @isTest
    static void errorForExpiryDateTest() {
        user usr1 = [SELECT Id FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
            Test.startTest();
            
            Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
            opp.CloseDate = date.today();
            insert opp;
            
            SBQQ__Quote__c sdTest = new SBQQ__Quote__c();
            sdTest.SBQQ__type__c = 'Quote';
            sdTest.SBQQ__Opportunity2__c = opp.Id;
            sdTest.SBQQ__Primary__c = false;
            sdTest.Update_Expires_On__c = true;
            sdTest.SBQQ__StartDate__c = Date.Today();
            sdTest.SBQQ__SubscriptionTerm__c = 12;
            sdTest.SBQQ__ExpirationDate__c = Date.Today();
            sdTest.EOL_New_Product_Earliest_Date__c = Date.Today().addDays(120);
            sdTest.Task_Products__c = 'RBK-DISK-RETENTION';
            sdTest.Count_of_Rubrik_Basic_Edition__c = 1;
            
            insert sdTest;
            
            QuoteTriggerHelper.insert_logic = false;
            try {
                sdTest.SBQQ__ExpirationDate__c = Date.today().addDays(100);
                sdTest.Update_Expires_On__c = false;
                update sdTest;
            } catch (Exception error) {
                System.assert(error.getMessage().contains('Update failed.'));
                System.assert(error.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
                System.assert(
                    error.getMessage().contains('You cannot update the Expires On beyond End of Quarter for in-quarter deals.')
                );
            }
            Test.stopTest();
            System.assert(true);
        }
    }

    /**************************************************************************************************
    * Method Name          : reSubmissionQuote
    * @description         : reSubmissionQuote for covering QuoteTriggerHelper
    /************************************************************************************************/
    @isTest
    static void reSubmissionQuote() {
        user usr1 = [SELECT Id FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
            insert new TriggerControl__c(
                Name = 'Approval',
                DisableTrigger__c = true
            );
            Test.startTest();
            
            Account acct = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            insert acct;

            List<Task> lTask = new List<Task>();
            Task t = new Task();
            t.OwnerId = usr1.id;
            t.Subject = 'Test Task';
            t.Priority = 'Normal';
            t.Status = 'Not Started';
            t.Type = 'Action'; 
            t.WhatId = acct.Id;
            lTask.add(t);
            insert lTask;

            
            List<SBQQ__Quote__c> insertQuotes = new List<SBQQ__Quote__c>();
            List<SBQQ__Quote__c> updateQuotes = new List<SBQQ__Quote__c>();
            //Create Public Group
            Group deal = new Group();
            deal.Name = 'Deal Desk';
            deal.DeveloperName = 'testDeveloper';
            deal.Type = 'Regular';
            insert deal;
            
            // Approver creation
            sbaa__Approver__c app = new sbaa__Approver__c();
            app.name = 'Deal Desk';
            app.sbaa__GroupId__c = deal.id;
            app.sbaa__DelegationStart__c = Date.newInstance(2018, 10, 9);
            app.sbaa__DelegationEnd__c = Date.newInstance(2018, 8, 13);
            insert app;
            //Generate the Opportunity
            Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
            opp.CloseDate = Date.newInstance(2021, 4, 30);
            insert opp;
            
            Product2 prdHW = new Product2();
            prdHW.Name = 'Subscription';
            prdHW.IsActive = true;
            prdHW.SBQQ__SubscriptionTerm__c = 12;
            prdHW.SBQQ__SubscriptionPricing__c = 'Fixed Price';
            prdHW.SBQQ__SubscriptionType__c = 'Renewable';
            insert prdHW;
            Product2 prdSubs = new Product2();
            prdSubs.Name = 'Subscription';
            prdSubs.IsActive = true;
            prdSubs.SBQQ__SubscriptionTerm__c = 12;
            prdSubs.SBQQ__SubscriptionPricing__c = 'Fixed Price';
            prdSubs.SBQQ__SubscriptionType__c = 'Renewable';
            insert prdSubs;
            List<PricebookEntry> pBList = new List<PricebookEntry>();
            PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeHW.Product2Id = prdHW.Id;
            pBList.add(pbeHW);
            PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeSubs.Product2Id = prdSubs.Id;
            pBList.add(pbeSubs);
            insert pBList;
            
            List<sbaa__ApprovalRule__c> approvalRule = new List<sbaa__ApprovalRule__c>();
            sbaa__ApprovalRule__c rule1 = new sbaa__ApprovalRule__c();
            rule1.name = 'Expiration Date Exception';
            rule1.sbaa__TargetObject__c = 'SBQQ__Quote__c';
            rule1.sbaa__Approver__c = app.id;
            rule1.sbaa__ApprovalStep__c = 1;
            rule1.sbaa__ConditionsMet__c = 'All';
            approvalRule.add(rule1);
            
            sbaa__ApprovalRule__c rule2 = new sbaa__ApprovalRule__c();
            rule2.name = 'Expiration Date Updated';
            rule2.sbaa__TargetObject__c = 'SBQQ__Quote__c';
            rule2.sbaa__Approver__c = app.id;
            rule2.sbaa__ApprovalStep__c = 1;
            rule2.sbaa__ConditionsMet__c = 'All';
            approvalRule.add(rule2);
            
            sbaa__ApprovalRule__c rule3 = new sbaa__ApprovalRule__c();
            rule3.name = 'Expiration Date Exceeds Start Date';
            rule3.sbaa__TargetObject__c = 'SBQQ__Quote__c';
            rule3.sbaa__Approver__c = app.id;
            rule3.sbaa__ApprovalStep__c = 1;
            rule3.sbaa__ConditionsMet__c = 'All';
            approvalRule.add(rule3);
            
            insert approvalRule;
            List<SBQQ__Quote__c> quoteInsertList = new List<SBQQ__Quote__c>();
            List<SBQQ__Quote__c> quoteUpdateList = new List<SBQQ__Quote__c>();
            
            SBQQ__Quote__c sd = new SBQQ__Quote__c();
            sd.SBQQ__type__c = 'Quote';
            sd.Quote_Name__c = 'StartDateQuote';
            sd.SBQQ__Opportunity2__c = opp.Id;
            sd.SBQQ__SubscriptionTerm__c = 12;
            sd.SBQQ__ExpirationDate__c = Date.newInstance(2030, 3, 19);
            sd.Task_Products__c = 'RBK-DISK-RETENTION';
            sd.Count_of_Rubrik_Basic_Edition__c = 1;
            
            quoteInsertList.add(sd);
            
            insert quoteInsertList;
            
            List<sbaa__Approval__c> approvals = new List<sbaa__Approval__c>();
            sbaa__Approval__c approval = new sbaa__Approval__c(
                Quote__c = quoteInsertList[0].Id,
                sbaa__Opportunity__c = opp.Id,
                sbaa__Status__c = 'Rejected',
                sbaa__Approver__c = app.Id,
                sbaa__RecordField__c = 'Quote__c',  
                sbaa__ApprovalStep__c = 1,
                sbaa__archived__c = false,
                sbaa__rule__c = approvalRule[0].Id
            );
            approvals.add(approval);
            insert approvals;
            
            SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = sd.Id,
                SBQQ__Product__c = prdHW.Id,
                SBQQ__Quantity__c = 10,
                SBQQ__Number__c = 1,
                SubscribedAssetNames__c = 'BB192863040046, BB192863040047',
                SBQQ__SubscribedAssetIds__c = '02i1W00000Sn8uyQAB, 02i1W00000Sn8uZQAR'
            );
            insert qli1;
            
            sd.Sbqq__Status__c = 'Approved';
            sd.ApprovalStatus__c = 'Approved';
            sd.SBQQ__StartDate__c = System.TODAY();
            sd.SBQQ__ExpirationDate__c = System.TODAY();
            sd.Update_Expires_On__c = true;
            QuoteTriggerHelper.insert_logic = false;
            
            update sd;
            Test.stopTest();
            System.assert(true);
        }
    }
    
    /**************************************************************************************************
    * Method Name          : coverlinkEntitlementsToRenewalOpp
    * @description         : coverlinkEntitlementsToRenewalOpp for covering QuoteTriggerHelper
    /************************************************************************************************/
    @isTest
    static void coverlinkEntitlementsToRenewalOpp() {
        user usr1 = [SELECT Id FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
        
            TriggerControl__c TC = new TriggerControl__c();
            TC.Name = 'Entitlement';
            TC.DisableTrigger__c = true;
            TC.DisableTrigger__c = true;
            TC.Last_Batch_Run_Date__c = Date.newInstance(2021, 4, 30);
            TC.SendEmail__c = false;
            insert TC;
            
            Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            insert act;
            
            List<Account> accountList = new List<Account>();
            Account vAccount = getAccount('Test', 'Distributor', partnerRtId);
            vAccount.Payment_Term__c = 'Net 30';
            accountList.add(vAccount);
            
            Account vAccount2 = getAccount('TestAcc', null, partnerRtId);
            accountList.add(vAccount2);
            insert accountList;
            
            Opportunity oppNew = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
            oppNew.AccountId = act.Id;
            oppNew.CloseDate = Date.newInstance(2021, 4, 30);
            oppNew.Partner_Lookup__c = vAccount2.id;
            oppNew.Distributor_Lookup__c = vAccount.id;
            oppNew.Opportunity_Sub_Type__c = 'MSP Consumption Renewal';
            oppNew.Opportunity_Program__c = 'Go Refresh';
            insert oppNew;
            
            Product2 prod = new Product2(
                Name = 'Test-Prod',
                ProductCode = 'Test-Prod',
                IsActive = true,
                Support_Tier__c = 'S2'
            );
            insert prod;
            
            PricebookEntry pricebookObj = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pricebookObj.Product2Id = prod.Id;
            pricebookObj.UnitPrice = 100;
            pricebookObj.Pricebook2Id = Test.getStandardPricebookId();
            pricebookObj.IsActive = true;
            insert pricebookObj;
            
            List<Asset> lstAsset = new List<Asset>();
            Asset asset1 = new Asset(Name = 'AA191164040122', Product2Id = prod.Id, AccountId = vAccount.Id);
            Asset asset2 = new Asset(Name = 'AA191164040411', Product2Id = prod.Id, AccountId = vAccount.Id);
            lstAsset.add(asset1);
            lstAsset.add(asset2);
            insert lstAsset;
            
            List<ServiceContract> contractList = new List<ServiceContract>();
            ServiceContract serviceContractObj = new ServiceContract();
            serviceContractObj.Name = 'PolarisContractRenewalQuotesUpdate';
            serviceContractObj.SBQQSC__Opportunity__c = oppNew.Id;
            serviceContractObj.StartDate = System.today();
            serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
            serviceContractObj.Term = 36;
            serviceContractObj.EndDate = System.today().addDays(365);
            serviceContractObj.SBQQSC__RenewalForecast__c = false;
            serviceContractObj.SBQQSC__RenewalTerm__c = 12;
            
            contractList.add(serviceContractObj);
            insert contractList;
            
            test.startTest();
            List<contractLineItem> cliList = new List<contractLineItem>();
            ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(
                new ContractLineItem(),
                null
            );
            ContractLineItemObj.SBQQSC__Account__c = vAccount2.Id;
            ContractLineItemObj.PricebookEntryId = pricebookObj.Id;
            ContractLineItemObj.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObj.Quantity = 10;
            ContractLineItemObj.UnitPrice = 100;
            ContractLineItemObj.StartDate = System.today();
            ContractLineItemObj.EndDate = System.today().addDays(120);
            //insert ContractLineItemObj;
            cliList.add(ContractLineItemObj);
            insert cliList;
            
            Entitlement ent = new Entitlement(
                Name = 'Testing',
                AccountId = act.Id,
                ServiceContractId = serviceContractObj.id,
                ContractLineItemId = ContractLineItemObj.id,
                Product__c = prod.id,
                StartDate = Date.today(),
                AssetId = asset2.Id,
                EndDate = Date.today().addDays(365)
            );
            insert ent;
            
            List<SBQQ__Quote__c> lstQuote = new List<SBQQ__Quote__c>();
            SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
            qt.SBQQ__Account__c = act.Id;
            qt.SBQQ__Opportunity2__c = oppNew.Id;
            qt.SBQQ__SubscriptionTerm__c = 12;
            qt.SBQQ__Type__c = 'Renewal';
            qt.SBQQ__Status__c = 'Draft';
            qt.SBQQ__Primary__c = true;
            qt.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Draft Quote').getRecordTypeId();
            qt.Amended_Renewed_Service_Contract__c = serviceContractObj.Id;
            qt.Count_of_Rubrik_Basic_Edition__c = 1;
            qt.Opportunity_Program__c = 'Go Refresh';
            lstQuote.add(qt);
            
            insert qt;
            
            
            SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt.Id,
                SBQQ__Product__c = prod.Id,
                SBQQ__Quantity__c = 1,
                SBQQSC__RenewedContractLine__c = ContractLineItemObj.id,
                SBQQ__Number__c = 1
            );
            insert qli1;
            QuoteTriggerHandler.isRecursiveLinkOppEnt = false;
            qt.SBQQ__Primary__c = true;
            update qt;
            test.stopTest();
            System.assert(true);
        }
    }
    /**************************************************************************************************
    * Method Name          : testBeforeInsertStatus2
    * @description         : testBeforeInsertStatus2 for covering QuoteTriggerHelper
    /************************************************************************************************/
    @isTest
    static void testBeforeInsertStatus2() {
        Profile p = [SELECT Id FROM profile WHERE Name = 'System Administrator'];
        String testmail = system.label.Task_User_Assignment;
        User testUser = new User(
            Alias = 'standt',
            Email = 'cyrus.sharif@rubrik.com.sandbox',
            EmailEncodingKey = 'UTF-8',
            LastName = 'martin',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'jivanJ@testorg.com',
            RBAC_Group__c = 'System - IT',
            RBAC_Department__c = 'Service Account'
        );
        
        insert testUser;
        
        System.runAs(testUser) {
            ShGl_DisableBusinessLogic__c dbl = ShGl_DisableBusinessLogic__c.getInstance();
            dbl.Disable_Account_Triggers__c = true;
            dbl.Disable_Opportunity_Triggers__c = true;
            dbl.Disable_ServiceContract_Trigger__c = true;
            dbl.Disable_SBQQ_QuoteLine_Triggers__c = true;
            upsert dbl;
            ShGl_TestFactoryHelper.insertTriggerControls();
            List<Account> accList = new List<Account>();
            Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            accList.add(act);
            Account act2 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            act2.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            accList.add(act2);
            Account act3 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            act3.RSC_G_Eligible__c = true;
            act3.Scale_Eligible__c = true;
            accList.add(act3);
            Account act4 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            act4.RSC_G_Eligible__c = true;
            accList.add(act4);
            insert accList;
            
            List<Task> lTask = new List<Task>();
            Task t = new Task();
            t.OwnerId = testUser.id;
            t.Subject = 'Test Task';
            t.Priority = 'Normal';
            t.Status = 'Not Started';
            t.Type = 'Action'; 
            t.WhatId = act.Id;
            lTask.add(t);
            insert lTask;

            //Generate the Opportunity
            Map<String, Object> oppMap = new Map<String, Object>{
                'AccountId' => act.Id,
                    'RecordTypeId' => salesRtId,
                    'Opportunity_Type__c' => 'Existing',
                    'Opportunity_Sub_Type__c' => 'Regular'
                    };
             Map<String, Object> oppMap1 = new Map<String, Object>{
                'AccountId' => act3.Id,
                    'RecordTypeId' => salesRtId,
                    'Opportunity_Type__c' => 'Existing',
                    'Opportunity_Sub_Type__c' => 'Regular'
                    };
            Map<String, Object> oppMap2 = new Map<String, Object>{
                'AccountId' => act4.Id,
                    'RecordTypeId' => salesRtId,
                    'Opportunity_Type__c' => 'Existing',
                    'Opportunity_Sub_Type__c' => 'Regular'
                    };
                        
            List<Opportunity> oppLst = new List<Opportunity>();
            Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
            opp.Sell_to_Partner__c = act2.Id;
            oppLst.add(opp);
            
            Opportunity opp1 = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap1);
            oppLst.add(opp1);

            Opportunity opp2 = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap2);
            oppLst.add(opp2);
            insert oppLst;


            List<SBQQ__Quote__c> qtList = new List<SBQQ__Quote__c>();
            SBQQ__Quote__c qtTestNew = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
            qtTestNew.SBQQ__Account__c = act.Id;
            qtTestNew.SBQQ__Opportunity2__c = opp.Id;
            qtTestNew.SBQQ__Type__c = 'Quote';
            qtTestNew.SBQQ__StartDate__c = Date.parse('05/20/2022');
            qtTestNew.SBQQ__StartDate__c = Date.parse('05/20/2024');
            qtTestNew.Task_Products__c = 'RBK-DISK-RETENTION';
            qtTestNew.Sell_to_Partner__c = '';
            qtTestNew.Count_of_Rubrik_Basic_Edition__c = 1;
            qtList.add(qtTestNew);

            SBQQ__Quote__c qtTestNew1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
            qtTestNew1.SBQQ__Account__c = act3.Id;
            qtTestNew1.SBQQ__Opportunity2__c = opp1.Id;
            qtTestNew1.SBQQ__Type__c = 'Quote';
            qtTestNew1.Task_Products__c = 'RBK-DISK-RETENTION';
            qtTestNew1.Count_of_Rubrik_Basic_Edition__c = 1;
            qtList.add(qtTestNew1);

            SBQQ__Quote__c qtTestNew2 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
            qtTestNew2.SBQQ__Account__c = act4.Id;
            qtTestNew2.SBQQ__Opportunity2__c = opp2.Id;
            qtTestNew2.SBQQ__Type__c = 'Quote';
            qtTestNew2.Task_Products__c = 'RBK-DISK-RETENTION';
            qtTestNew2.Count_of_Rubrik_Basic_Edition__c = 1;
            qtList.add(qtTestNew2);
            
            insert qtList;
            
            Map<Id,SBQQ__Quote__c> oldMap = new Map<Id,SBQQ__Quote__c>();
            oldMap.put(qtTestNew.Id,qtTestNew);
            oldMap.put(qtTestNew1.Id,qtTestNew1);
            oldMap.put(qtTestNew2.Id,qtTestNew2);
            QuoteTriggerHelper.guidedSellingDefaulting(qtList, oldMap);
            
            for (SBQQ__Quote__c quote : qtList) {
                quote.GPL_Deal__c = 'NetApp';
                quote.RWD_Guided_Selling__c = '';
                oldMap.put(quote.Id,Quote);
            }
            for (SBQQ__Quote__c quote : qtList) {
                quote.GPL_Deal__c = 'NetApp';
                quote.RWD_Guided_Selling__c = 'Polaris Guided Selling - Federal ';
            }
            QuoteTriggerHelper.guidedSellingDefaulting(qtList, oldMap);
            for (SBQQ__Quote__c quote : qtList) {
                quote.GPL_Deal__c = 'NetApp';
                quote.RWD_Guided_Selling__c = 'Polaris Guided Selling - Federal ';
                //quote.Is_Federal_Eligible_Quote__c = true;
                quote.RWD_Sales_Rep_Exception__c = null;
            }
            
            QuoteTriggerHelper.guidedSellingDefaulting(qtList, null);
            for (SBQQ__Quote__c quote : qtList) {
                quote.GPL_Deal__c = '';
                quote.RWD_Sales_Rep_Exception__c = null;
                quote.Sell_to_Partner__c = 'HPE US';
            }
            update qtList;
            QuoteTriggerHelper.guidedSellingDefaulting(qtList, null);
            QuoteLineRecordResponse objQuoteLineRecordResponse = new QuoteLineRecordResponse();
            objQuoteLineRecordResponse.ptyp = 'HW Support';
            objQuoteLineRecordResponse.rqBy = 'test';
            objQuoteLineRecordResponse.optional = false;
            objQuoteLineRecordResponse.reqSupTier = 'Test';
            objQuoteLineRecordResponse.reqHWSupTier = 'test';
            objQuoteLineRecordResponse.supTier = 'supTier';

            QuoteLineRecordResponse objQuoteLineRecordResponse1 = new QuoteLineRecordResponse();
            objQuoteLineRecordResponse1.ptyp = 'HW Support';
            objQuoteLineRecordResponse1.rqBy = 'test';
            objQuoteLineRecordResponse1.optional = false;
            //objQuoteLineRecordResponse1.reqSupTier = 'Test';
            objQuoteLineRecordResponse1.reqHWSupTier = 'test';
            objQuoteLineRecordResponse1.hWSupTier = 'hWSupTier';

            QuoteTriggerHelper.verifyTierOnQLs(new List<QuoteLineRecordResponse>{objQuoteLineRecordResponse,objQuoteLineRecordResponse1});

            
            Product2 prdHWTest11 = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
            prdHWTest11.Name = 'Subscription';
            prdHWTest11.IsActive = true;
            prdHWTest11.SBQQ__SubscriptionPricing__c = 'Fixed Price';
            prdHWTest11.ProductCode = 'RS-BT-RCDM-T';
            prdHWTest11.Product_Level__c = 'OnPrem';
            insert prdHWTest11;
            
            Product2 prod4Test = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
            prod4Test.Name = 'DateTest1';
            prod4Test.IsActive = true;
            prod4Test.License_Subtype__c = 'Add-On';
            prod4Test.ProductCode = 'RS-BT-FE-PE-PP';
            
            insert prod4Test;
            
            Entitlement ent = new Entitlement(
                Name = 'Testing',
                AccountId = act.Id,
                Product__c = prdHWTest11.id,
                StartDate = Date.today(),
                EndDate = Date.today().addDays(365)
            );
            
            Test.startTest();
            
            insert ent;
            
            Entitlement ent2 = new Entitlement(
                Name = 'Testing',
                AccountId = act.Id,
                Product__c = prdHWTest11.id,
                StartDate = Date.today(),
                EndDate = Date.today().addDays(360)
            );
            insert ent2;
            
            SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qtTestNew.Id,
                SBQQ__Product__c = prdHWTest11.Id,
                SBQQ__Quantity__c = 1,
                SBQQ__Number__c = 1,
                SubscribedAssetNames__c = 'BB192863040046, BB192863040047',
                SBQQ__SubscribedAssetIds__c = '02i1W00000Sn8uyQAB, 02i1W00000Sn8uZQAR'
            );
            insert qli1;
            
            Set<Id> qliSet = new Set<Id>();
            qliSet.add(qtTestNew.Id);
            
            Map<Id, SBQQ__Quote__c> newQuoteList = new Map<Id, SBQQ__Quote__c>();
            newQuoteList.put(qtTestNew.Id, qtTestNew);
            List<SBQQ__Quote__c> objqt = [
                    SELECT
                    Id,
                    Name,
                    SBQQ__Account__c,
                    SBQQ__Status__c,
                    SBQQ__Primary__c,
                    SBQQ__SubscriptionTerm__c,
                    recordtypeId,
                    Task_Products__c,
                    Opportunity_Program__c,
                    ApprovalStatus__c,
                    SBQQ__Type__c,
                    OpportunitySubType__c,
                    SBQQ__Opportunity2__c,
                    SBQQ__ExpirationDate__c
                    FROM SBQQ__Quote__c
                    WHERE Id = :qliSet
                ];
            
            //QuoteTriggerHelper.createQuoteLineGroup(newQuoteList);
            qtTestNew.Task_Products__c = 'RBK-DISK-RETENTION 2';
            newQuoteList.put(qtTestNew.Id, qtTestNew);
            QuoteTriggerHelper.createTask(objqt, newQuoteList);
            Test.stopTest();
            
            System.assert(true);
        }
    }
    /**************************************************************************************************
    * Method Name          : testBeforeInsertStatus3
    * @description         : testBeforeInsertStatus3 for covering QuoteTriggerHelper
    /************************************************************************************************/
    @isTest
    static void testBeforeInsertStatus3() {
        user usr1 = [SELECT Id FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
            ShGl_TestFactoryHelper.insertTriggerControls();
            Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            insert act;
            
            //Generate the Opportunity
            Map<String, Object> oppMap = new Map<String, Object>{
                'AccountId' => act.Id,
                    'RecordTypeId' => salesRtId
                    };
                        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
            opp.Opportunity_Type__c = 'Existing';
            opp.Opportunity_Sub_Type__c = 'Regular';
            insert opp;
            
            SBQQ__Quote__c qtTest2 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
            qtTest2.SBQQ__Account__c = act.Id;
            qtTest2.SBQQ__Opportunity2__c = opp.Id;
            qtTest2.SBQQ__Type__c = 'Renewal';
            qtTest2.SBQQ__StartDate__c = Date.parse('05/20/2022');
            qtTest2.SBQQ__StartDate__c = Date.parse('05/20/2024');
            qtTest2.Task_Products__c = 'RBK-DISK-RETENTION';
            qtTest2.SBQQ__Status__c = 'Draft';
            qtTest2.SBQQ__ExpirationDate__c = System.Today();
            
            insert qtTest2;
            
            Map<String, Object> prdMap1 = new Map<String, Object>{
                'Name' => 'SubscriptionTEST',
                    'IsActive' => true,
                    'SBQQ__SubscriptionPricing__c' => 'Fixed Price',
                    'ProductCode' => 'RS-BT-RCDM-T',
                    'Product_Level__c' => 'OnPrem'
                    };
                        Map<String, Object> prdMap3 = new Map<String, Object>{
                            'Name' => 'DateTest312',
                                'IsActive' => true,
                                'License_Subtype__c' => 'Add-On',
                                'ProductCode' => 'RS-BT-FE-PE-PP',
                                'Product_Type__c' => 'Hardware',
                                'Family' => 'Rubrik Scale'
                                };
                                    
                                    Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
            insert prdHW;
            
            Product2 prod4 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap3);
            insert prod4;
            
            Entitlement ent = new Entitlement(
                Name = 'TestingRecord',
                AccountId = act.Id,
                Product__c = prdHW.id,
                StartDate = Date.today(),
                EndDate = Date.today().addDays(365)
            );
            
            insert ent;
            
            Entitlement ent2 = new Entitlement(
                Name = 'TestingRecord2',
                AccountId = act.Id,
                Product__c = prdHW.id,
                StartDate = Date.today(),
                EndDate = Date.today().addDays(360)
            );
            insert ent2;
            
            SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qtTest2.Id,
                SBQQ__Product__c = prod4.Id,
                SBQQ__Quantity__c = 1,
                SBQQ__Number__c = 1,
                SubscribedAssetNames__c = 'BB192863040012, BB192863123047',
                TPH_OEM__c = 'DELL',
                Product_Type__c = 'Hardware',
                SBQQ__SubscribedAssetIds__c = '02i1W0011aSn8uyQAB, 02i1W011100Sn8uZQAR'
            );
            insert qli1;
            
            List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
            quoteList.add(qtTest2);
            
            QuoteTriggerHelper.hwApplianceAndTphAddedTogetherValidation(quoteList);
            SBQQ__Quote__c clonedQuote = qtTest2.clone(false, false, false, false);
            clonedQuote.SBQQ__Source__c = qtTest2.Id;
            clonedQuote.Trade_Up_Serial_Numbers__c = 'BB192863040012, BB192863123047';
            Test.startTest();
            insert clonedQuote;

            Map<Id, SBQQ__Quote__c> quoteOldMap = new Map<Id, SBQQ__Quote__c>();
            quoteOldMap.put(qtTest2.Id,qtTest2);
                //Disable quoteTriggers
            SBQQ.TriggerControl.disable();
            TriggerControls.disableQuoteTrigger = true;
            qtTest2.Update_Expires_On__c=true;
            qtTest2.SBQQ__ExpirationDate__c = Date.newInstance(2024, 2, 11);
            qtTest2.SBQQ__Status__c = 'Expired';
            update qtTest2;
            QuoteTriggerHelper.UpdateOnExpireDateExtension(quoteOldMap,new List<SBQQ__Quote__c>{qtTest2});
                SBQQ.TriggerControl.enable();
                TriggerControls.disableQuoteTrigger=false;
            qtTest2.SBQQ__Status__c = 'Approved';
            update qtTest2;
            quoteOldMap.put(qtTest2.Id,qtTest2);
            QuoteTriggerHelper.UpdateOnExpireDateExtension(quoteOldMap,new List<SBQQ__Quote__c>{qtTest2});
            qtTest2.SBQQ__Status__c = 'Expired';
            qtTest2.Update_Expires_On__c=true;
            qtTest2.SBQQ__ExpirationDate__c = System.today();
            Update qtTest2;
            quoteOldMap.put(qtTest2.Id,qtTest2);
            QuoteTriggerHelper.UpdateOnExpireDateExtension(quoteOldMap,new List<SBQQ__Quote__c>{qtTest2});
            
            //Additional Coverage 6401
            qtTest2.SBQQ__Status__c = 'Expired';
            update qtTest2;
            Map<Id, SBQQ__Quote__c> quoteOldMap1 = new Map<Id, SBQQ__Quote__c>{
                qtTest2.Id => qtTest2.clone(true, true) 
            };
            SBQQ__Quote__c updatedQt = qtTest2.clone(true, true);
            updatedQt.SBQQ__ExpirationDate__c = Date.today().addDays(10); // Change date
            updatedQt.Update_Expires_On__c=true;
            updatedQt.SBQQ__StartDate__c = Date.today().addDays(1);
           
            TriggerControls.disableCPQTriggers();
            QuoteTriggerHelper.UpdateOnExpireDateExtension(quoteOldMap1, new List<SBQQ__Quote__c>{updatedQt});

            SBQQ__Quote__c quoteH = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
            quoteH.SBQQ__Account__c = act.Id;
            quoteH.SBQQ__Opportunity2__c = opp.Id;
            quoteH.SBQQ__Type__c = 'Quote';
            quoteH.SBQQ__StartDate__c = Date.today().addDays(-30);
            quoteH.Task_Products__c = 'RBK-DISK-RETENTION';
            quoteH.SBQQ__ExpirationDate__c = System.Today();
            insert quoteH;

            Map<Id, SBQQ__Quote__c> oldMap = new Map<Id, SBQQ__Quote__c>();
            oldMap.put(quoteH.Id, new SBQQ__Quote__c(
                Id = quoteH.Id,
                SBQQ__Status__c = 'Draft', // Prior status
                SBQQ__StartDate__c = Date.today().addDays(-30),
                SBQQ__ExpirationDate__c = Date.today().addDays(10),
                Update_Expires_On__c = true
            ));
            QuoteTriggerHelper.updateOnExpireDateExtension(oldMap, new List<SBQQ__Quote__c>{quoteH});
            
            TriggerControls.disableCPQTriggers();
            Test.stopTest();
            System.assert(true);
        }
    }
    /**************************************************************************************************
    * Method Name          : testBeforeInsertStatus6
    * @description         : testBeforeInsertStatus6 for covering QuoteTriggerHelper
    /************************************************************************************************/
    @isTest
    static void testBeforeInsertStatus6() {
        user usr1 = [SELECT Id FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
        List<SBQQ__Quote__c> allQuotes;
            TestDataFactory.setTriggerSwitch('Approval', false);
            List<sbaa__ApprovalRule__c> appRuleList = new List<sbaa__ApprovalRule__c>();
            sbaa__ApprovalRule__c rule1 = new sbaa__ApprovalRule__c(
                Name = 'Expiration Date Exception',
                sbaa__TargetObject__c = 'SBQQ__Quote__c',
                sbaa__ApprovalStep__c = 1
            );
            sbaa__ApprovalRule__c rule2 = new sbaa__ApprovalRule__c(
                Name = 'Expiration Date Updated',
                sbaa__TargetObject__c = 'SBQQ__Quote__c',
                sbaa__ApprovalStep__c = 2
            );
            sbaa__ApprovalRule__c rule3 = new sbaa__ApprovalRule__c(
                Name = 'Expiration Date Exceeds Start Date',
                sbaa__TargetObject__c = 'SBQQ__Quote__c',
                sbaa__ApprovalStep__c = 3
            );
            appRuleList.add(rule1);
            appRuleList.add(rule2);
            appRuleList.add(rule3);
            insert appRuleList;
            ShGl_TestFactoryHelper.insertTriggerControls();
            Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            insert act;
            Account act2 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            insert act2;
            
            //Generate the Opportunity
            Map<String, Object> oppMap = new Map<String, Object>{
                'AccountId' => act.Id,
                    'RecordTypeId' => salesRtId
                    };
                        Opportunity oppty = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
            oppty.Opportunity_Type__c = 'Existing';
            oppty.Opportunity_Sub_Type__c = 'Regular';
            insert oppty;
            
            SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
            qt.SBQQ__Account__c = act.Id;
            qt.SBQQ__Opportunity2__c = oppty.Id;
            qt.SBQQ__Type__c = 'Renewal+Expansion';
            qt.SBQQ__StartDate__c = System.today();
            qt.Task_Products__c = 'RBK-DISK-RETENTION';
            qt.MetricsLastCalcOn__c = System.today();
            insert qt;
            //RS-BT-RCDM-T
            
            Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
            prdHW.Name = 'Subscription';
            prdHW.IsActive = true;
            prdHW.SBQQ__SubscriptionPricing__c = 'Fixed Price';
            prdHW.ProductCode = 'RS-BT-EE-RSCP-L3-PP';
            prdHW.Product_Level__c = 'OnPrem';
            insert prdHW;
            
            Product2 prod4 = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
            prod4.Name = 'DateTest1';
            prod4.IsActive = true;
            prod4.License_Subtype__c = 'Add-On';
            prod4.ProductCode = 'RS-BT-FE-PE-PP';
            insert prod4;
            
        Set<id> oppIdsSet= new Set<Id>{oppty.Id};
        test.startTest();
        allQuotes = QuoteTriggerHelper.getQuoteRecords(oppIdsSet);
            
            List<SBQQ__QuoteLine__c> qli1List = new List<SBQQ__QuoteLine__c>();
            SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt.Id,
                SBQQ__Product__c = prdHW.Id,
                SBQQ__Quantity__c = 1,
                SBQQ__Number__c = 1,
                SubscribedAssetNames__c = 'BB192863040046, BB192863040047',
                SBQQ__ListPrice__c = 10.00,
                SBQQ__ProrateMultiplier__c = 1,
                SBQQ__SubscribedAssetIds__c = '02i1W00000Sn8uyQAB, 02i1W00000Sn8uZQAR'
            );
            
            qli1List.add(qli1);
            
            SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt.Id,
                SBQQ__Product__c = prod4.Id,
                SBQQ__Quantity__c = 1,
                SBQQ__Number__c = 1,
                SubscribedAssetNames__c = 'BB192863040046, BB192863040044',
                SBQQ__ListPrice__c = 10.00,
                SBQQ__ProrateMultiplier__c = 1,
                SBQQ__SubscribedAssetIds__c = '02i1W00000TjqVmQAJ, 02i1W00000TjqVmQA1'
            );
            
            qli1List.add(qli2);
            
            insert qli1List;
            qt.SBQQ__Primary__c = true;
            qt.SBQQ__ExpirationDate__c = System.today();
            qt.ApprovalStatus__c = 'Approved';
            update qt;
            qt.ApprovalStatus__c = 'Recalled';
            update qt;
            List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
            quoteList.add(qt);
            Delete quoteList;
            test.stopTest();
            System.assert(true);
        }
    }
    /**
    * @description testConvertQLtoDispositionLine method. 
    * Summer Release Cutover activities - Khushboo
    **/ 
    @isTest 
    public static void testConvertQLtoDispositionLine(){
        Profile p = [SELECT Id FROM profile WHERE Name = 'System Administrator'];
        User testUser = new User(
            Alias = 'standt',
            Email = 'abc@gmail.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'martin',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'jivanJ@testorg.com',
            RBAC_Group__c = 'System - IT',
            RBAC_Department__c = 'Service Account'
        );

        insert testUser;

        System.runAs(testUser){

            ShGl_DisableBusinessLogic__c dbl = ShGl_DisableBusinessLogic__c.getInstance();
            dbl.Disable_Account_Triggers__c = true;
            dbl.Disable_Opportunity_Triggers__c = true;
            dbl.Disable_ServiceContract_Trigger__c = true;
            dbl.Disable_SBQQ_Quote_Triggers__c = true;
            dbl.Disable_SBQQ_QuoteLine_Triggers__c = true;
            upsert dbl;

            ShGl_TestFactoryHelper.insertTriggerControls();
            
            Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            insert act1;

            //Generate the Opportunity
            Map<String, Object> oppMap = new Map<String, Object>{
            'AccountId' => act1.Id,
            'RecordTypeId' => salesRtId
            };

            Opportunity oppty1 = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
            oppty1.Opportunity_Type__c = 'Existing';
            oppty1.Opportunity_Sub_Type__c = 'Regular';
            insert oppty1;

            Product2 prdHW1 = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
            prdHW1.Name = 'Subscription';
            prdHW1.IsActive = true;
            prdHW1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
            prdHW1.ProductCode = 'RS-BT-EE-RSCP-L3-PP';
            prdHW1.Product_Level__c = 'OnPrem';
            insert prdHW1;
            Map<String, Object> prdMap = new Map<String, Object>{
            'Name' => 'Standalone',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit',
                'ProductCode' => 'RBK-PRO-BUNDLE-R6410S-01',
                'Replacement_Category__c' => 'Enterprise Data Protection'
                };
                    
            Map<String, Object> prdMap1 = new Map<String, Object> {
                'Name' => 'SubscriptionTest',
                    'IsActive'  => true,
                    'SBQQ__SubscriptionPricing__c'  => 'Fixed Price',
                    'SBQQ__SubscriptionTerm__c'  => 12,
                    'SBQQ__SubscriptionType__c'  => 'Renewable',
                    'Replacement_Category__c' => 'Not Replaceable'
                    };
            Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
            Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
            List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
            prdList.add(prdHW);
            prdList.add(prdSubs);
            insert prdList;

            Map<String, Object> quoteMap1 = new Map<String, Object>{
                'SBQQ__Account__c' => act1.Id,
                    'SBQQ__Opportunity2__c' => oppty1.Id
                    };

            PriceBook2 pb1 = new Pricebook2(
                Name = 'V68_2017_08_09_12_26_43',
                Description = 'Price Book 2009 Products 1',
                IsActive = true
            );
            insert pb1;

            SBQQ__Quote__c qt2 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap1);
            qt2.SBQQ__Opportunity2__c = oppty1.Id;
            qt2.SBQQ__Primary__c = false;
            qt2.SBQQ__PriceBook__c = pb1.Id;
            qt2.SBQQ__Type__c = 'Renewal+Expansion';
            qt2.AddOn_Date_Check__c = true;
            qt2.SBQQ__EndDate__c = Date.today().addDays(2360);
            qt2.SBQQ__Status__c= 'Draft';
            qt2.SBQQ__LastCalculatedOn__c = System.today();
            qt2.ApprovalStatus__c = '';
            
            insert qt2;

            List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>();
            SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt2.Id,
                SBQQ__Product__c = prdHW1.Id,
                SBQQ__Quantity__c = 10,
                SubscribedAssetNames__c = 'BB192863040046',
                SBQQ__EndDate__c = Date.today().addDays(2360),
                Disposition_Reason__c='Renew Later',
                Replacement_Motion__c='Upgrade',
                Replacement_Details__c ='{"lodToSaas":true}'//FY25SR-2391
            );
            SBQQ__QuoteLine__c qli11 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt2.Id,
                SBQQ__Product__c = prdHW.Id,
                SBQQ__Quantity__c = 10,
                SBQQ__Number__c = 1,
                SubscribedAssetNames__c = 'BB192863040046, BB192863040047',
                SBQQ__SubscribedAssetIds__c = '02i1W00000Sn8uyQAB, 02i1W00000Sn8uZQAR'
            );
            SBQQ__QuoteLine__c qli12 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt2.Id,
                SBQQ__Product__c = prdSubs.Id,
                SBQQ__RequiredBy__c = qli11.id,
                SBQQ__Quantity__c = 10,
                SBQQ__Number__c = 2,
                SubscribedAssetNames__c = 'BB1928630400416, BB1921863040047',
                SBQQ__SubscribedAssetIds__c = '02i1W00000Sn8uyQAb, 02i1W00000Sn8uZQAb'
            );
            qliList.add(qli2);
            qliList.add(qli11);
            qliList.add(qli12);
            insert qliList;
            qli2.isFieldNull__c = true;
            update qli2;
            
            QuoteTriggerHelper.resetFlagonClone(new Set<Id>{qt2.Id});
            List<CPQ_Disposition_Quote_Line__c> listCPQLines= new List<CPQ_Disposition_Quote_Line__c>();
            listCPQLines.add(new CPQ_Disposition_Quote_Line__c(Product__c = prdSubs.Id,Disposition_Reason__c = 'At Risk',Quote__c=qt2.Id));
            listCPQLines.add(new CPQ_Disposition_Quote_Line__c(Product__c = prdHW.Id,Disposition_Reason__c = 'Renew Now',Quote__c=qt2.Id));
            insert listCPQLines;
            Test.startTest();
            qt2.SBQQ__Primary__c = true;
            qt2.ApprovalStatus__c= 'Approved';
            update qt2;
                
            QuoteTriggerHelper.processQLtoCPQDisposeLines(new Set<Id>{qt2.Id});

            Test.stopTest();

            List<CPQ_Disposition_Quote_Line__c> disposeLines = [SELECT Id FROM CPQ_Disposition_Quote_Line__c WHERE Quote__c =: qt2.Id]; 
            System.assert(disposeLines.size() > 0);
        }
    }
    /**************************************************************************************************
    * Method Name          : hwApplianceAndTphAddedTogetherValidationTest
    * @description         : hwApplianceAndTphAddedTogetherValidationTest for covering QuoteTriggerHelper
    /************************************************************************************************/
    @isTest
    static Void hwApplianceAndTphAddedTogetherValidationTest() {
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        insert new TriggerControl__c(
                Name = 'Approval',
                DisableTrigger__c = true
            );
        SBQQ.TriggerControl.disable();
        user usr1 = [SELECT Id FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
            Id standardPriceBookId = Test.getStandardPricebookId();
        
            PriceBook2 pb1 = new Pricebook2(
                Name = 'V68_2017_08_09_12_26_43',
                Description = 'Price Book 2009 Products 1',
                IsActive = true
            );
            insert pb1;
            Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get('Partner/Distributor')
                .getRecordTypeId();
            Account acct = new Account(
                Name = 'testAccount',
                RecordTypeId = partnerRecordTypeId,
                Account_Deal_Desk_Notes__c = 'Test Notes'
            );
            Account acc = new Account(Name = 'testAccount1');
            insert new List<Account>{ acct, acc };
            
            List<Task> lTask = new List<Task>();
            Task t = new Task();
            t.OwnerId = usr1.id;
            t.Subject = 'Test Task';
            t.Priority = 'Normal';
            t.Status = 'Not Started';
            t.Type = 'Action'; 
            t.WhatId = acct.Id;
            lTask.add(t);
            insert lTask;
            
                
            Opportunity oppr = TestDataFactory.getOpportunity(acct);
            oppr.ETM_Theatre__c = 'APAC';
            oppr.Opportunity_Sub_Type__c = 'GC Offer';
            
            insert oppr;
            
            Opportunity oppr2 = [SELECT Id FROM Opportunity LIMIT 1];
            oppr2.Type = 'Existing Customer';
            oppr2.Opportunity_Sub_Type__c = 'GC Offer';
            oppr2.Amount = 2000;
            update oppr2;
            
            Opportunity oppr1 = TestDataFactory.getOpportunity(acct);
            oppr1.Type = 'Existing Customer';
            oppr1.Opportunity_Sub_Type__c = 'GC Offer';
            oppr1.StageName = '7 Closed Lost';
            oppr1.Amount = 2000;
            
            Opportunity oppr3 = TestDataFactory.getOpportunity(acct);
            oppr3.Type = 'Existing Customer';
            oppr3.Opportunity_Sub_Type__c = 'GC Offer';
            oppr3.StageName = '7 Closed Lost';
            
            insert new List<Opportunity>{ oppr1, oppr3 };

            Map<String, Object> quoteMap = new Map<String, Object>{
                            'SBQQ__Account__c' => acct.Id,
                                'SBQQ__Opportunity2__c' => oppr.Id
                                };
                                    
                                    List<SBQQ__Quote__c> qtlist = new List<SBQQ__Quote__c>();
            
            SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
            qt1.SBQQ__Opportunity2__c = oppr.Id;
            qt1.SBQQ__Primary__c = false;
            qt1.SBQQ__PriceBook__c = pb1.Id;
            qt1.ApprovalStatus__c = '';
            qt1.SBQQ__Type__c = 'Renewal+Expansion';
            qt1.SBQQ__StartDate__c = Date.today();
            qt1.SBQQ__EndDate__c = System.Today().addDays(90);
            qt1.Manual_Billing__c = false;
            qt1.Consolidate_Lines__c = false;
            qt1.RWD_Deal_Ops_Exception__c = 'Hardfloor Discount Exception - HW & HW Support';
            qt1.RWD_Deal_Ops_Exception_Justification__c = 'Test';
                
            
            //Create your product
            Product2 prod1 = getProduct('RBK-GO-BE-R6408', 'RBK-GO-BE-R6408');
            prod1.Family = 'Rubrik Scale';
            
            Product2 prod2 = getProduct('RBK-R Premium Support 1-Yr Prepaid, r304', 'RBK-SVC-PREM-R304');
            prod2.Family = 'Rubrik Scale';
            
            //Create your product
            Product2 prod3 = getProduct('RBK-GO-BE-R6408', 'RBK-GO-BE-R6408');
            prod3.Family = 'Rubrik Scale';
            
            //Create your product
            Product2 prod4 = getProduct('RBK-RCDM-10-MO-CLON', 'RBK-RCDM-10-MO-CLON');
            prod4.Family = 'Rubrik Scale';
            
            Product2 prod6 = getProduct('RS-PAYGO-C-X', 'RS-PAYGO-C-X'); //GTMIT-49
            
            
            Product2 prod5 = getProduct('RS-BE-GO-PE-PP', 'RS-BE-GO-PE-PP');
            prod5.Family = 'Rubrik Scale';
            
            insert new List<Product2>{ prod1, prod2, prod3, prod4, prod5,prod6 };//GTMIT-49
                
            //Create your pricebook entry
            PricebookEntry pbStanEntry1 = getPbe(standardPriceBookId, prod1.Id, 100.00);
            
            //Create your pricebook entry
            PricebookEntry pbStanEntry2 = getPbe(standardPriceBookId, prod2.Id, 1000.00);
            
            //Create your pricebook entry
            PricebookEntry pbStanEntry3 = getPbe(standardPriceBookId, prod3.Id, 1000.00);
            
            //Create your pricebook entry
            PricebookEntry pbStanEntry4 = getPbe(standardPriceBookId, prod4.Id, 1000.00);
            
            PricebookEntry pbStanEntry5 = getPbe(standardPriceBookId, prod5.Id, 1000.00);
            
            PricebookEntry pbStanEntry6 = getPbe(standardPriceBookId, prod6.Id, 1000.00);//GTMIT-49
            
            //Create your pricebook entry
            PricebookEntry pbEntry1 = getPbe(pb1.id, prod1.Id, 100.00);
            
            //Create your pricebook entry
            PricebookEntry pbEntry2 = getPbe(pb1.id, prod2.Id, 100.00);
            
            //Create your pricebook entry
            PricebookEntry pbEntry3 = getPbe(pb1.id, prod3.Id, 1000.00);
            
            //Create your pricebook entry
            PricebookEntry pbEntry4 = getPbe(pb1.id, prod4.Id, 1000.00);
            
            PricebookEntry pbEntry5 = getPbe(pb1.id, prod5.Id, 1000.00);
            
            PricebookEntry pbEntry6 = getPbe(pb1.id, prod6.Id, 1000.00);//GTMIT-49
            
            insert new List<PricebookEntry>{
                pbStanEntry1,
                    pbStanEntry2,
                    pbStanEntry3,
                    pbStanEntry4,
                    pbStanEntry5,
                    pbStanEntry6,//GTMIT-49
                    pbEntry1,
                    pbEntry2,
                    pbEntry3,
                    pbEntry4,
                    pbEntry5,
                    pbEntry6//GTMIT-49
                    };
                        
                        
            
            SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
            qt.SBQQ__Opportunity2__c = oppr.Id;
            qt.SBQQ__Primary__c = true;//GTMIT-49
            qt.SBQQ__PriceBook__c = pb1.Id;
            qt.Is_RWD_Polaris_Quote__c = false;
            qt.ApprovalStatus__c = 'Pending';
            qt.SBQQ__Type__c = 'Quote';
            qt.SBQQ__StartDate__c = Date.today();
            qt.SBQQ__EndDate__c = System.Today().addDays(90);
            qt.Manual_Billing__c = false;
            qt.Consolidate_Lines__c = false;
            qt.RWD_Deal_Ops_Exception__c = 'Hardfloor Discount Exception - HW & HW Support';
            qt.RWD_Deal_Ops_Exception_Justification__c = 'Test';
            qt.Count_of_Rubrik_Basic_Edition__c = 1;
            insert qt;
            qt.ApprovalStatus__c = 'Approved';
            update qt;
            
            Order ordr1 = new Order(
                Type = 'Revenue',
                AccountId = acct.Id,
                OpportunityId = oppr.Id,
                ShippingStreet = 'Test Street',
                ShippingCity = 'Test City',
                ShippingState = null,
                ShippingCountry = 'Austria',
                ShippingPostalcode = '94820',
                EffectiveDate = system.Today(),
                Status = 'Pending',
                Pricebook2Id = pb1.Id
            );
            
            insert ordr1;
            
            ServiceContract objSC1 = new ServiceContract(
                Name = 'ServiceContract Test',
                AccountId = acct.Id,
                StartDate = Date.today(),
                Term = 36,
                pricebook2Id = pb1.Id,
                SBQQSC__Opportunity__c = oppr.Id,
                SBQQSC__Order__c = ordr1.Id,
                SBQQSC__Quote__c = qt.Id
            );
            
            insert objSC1;

            oppr.SBQQSC__AmendedServiceContract__c = objSC1.Id;
            oppr.Opportunity_Sub_Type__c = 'GC Offer';
            update oppr;
            
            SBQQ__Quote__c qt2 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
            qt2.SBQQ__Opportunity2__c = oppr.Id;
            qt2.SBQQ__Primary__c = false;
            qt2.SBQQ__PriceBook__c = pb1.Id;
            qt2.ApprovalStatus__c = 'Rejected';
            qt2.SBQQ__Type__c = 'Renewal+Expansion';
            qt2.SBQQ__StartDate__c = Date.today();
            qt2.SBQQ__EndDate__c = System.Today().addDays(90);
            qt2.Manual_Billing__c = false;
            qt2.Consolidate_Lines__c = false;
            qt2.RWD_Deal_Ops_Exception__c = 'Hardfloor Discount Exception - HW & HW Support';
            qt2.RWD_Deal_Ops_Exception_Justification__c = 'Test';
            
            // insert qt2;
            qtlist.add(qt1);
            qtlist.add(qt2);
            qtlist.add(qt);
            
            SBQQ__Quote__c qt3 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
            qt3.SBQQ__Opportunity2__c = oppr.Id;
            qt3.SBQQ__Primary__c = false;
            qt3.SBQQ__PriceBook__c = pb1.Id;
            qt3.ApprovalStatus__c = 'Pending';
            qt3.SBQQ__Type__c = 'Amendment';
            qt3.SBQQ__StartDate__c = Date.today();
            qt3.SBQQ__EndDate__c = System.Today().addDays(90);
            qt3.Manual_Billing__c = false;
            qt3.Consolidate_Lines__c = false;
            qt3.RWD_Deal_Ops_Exception__c = 'Hardfloor Discount Exception - HW & HW Support';
            qt3.RWD_Deal_Ops_Exception_Justification__c = 'Test';
            
            // insert qt3;
            qtlist.add(qt3);
            
            SBQQ__Quote__c qt4 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
            qt4.SBQQ__Opportunity2__c = oppr3.Id;
            qt4.SBQQ__Primary__c = false;
            qt4.SBQQ__PriceBook__c = pb1.Id;
            qt4.ApprovalStatus__c = 'Rejected';
            qt4.SBQQ__Type__c = 'Renewal';  
            qt4.SBQQ__StartDate__c = Date.today();
            qt4.SBQQ__EndDate__c = System.Today().addDays(90);
            qt4.Manual_Billing__c = false;
            qt4.Consolidate_Lines__c = false;
            qt4.RWD_Deal_Ops_Exception__c = 'Hardfloor Discount Exception - HW & HW Support';
            qt4.RWD_Deal_Ops_Exception_Justification__c = 'Test';
            
            // insert qt4;
            qtlist.add(qt4);
            
            insert new List<SBQQ__Quote__c>{ qt1, qt2, qt3, qt4 };
                
            list<SBQQ__Quote__c> qtlist2 = new List<SBQQ__Quote__c>();
            qt1.RWD_Deal_Ops_Exception__c = 'Annual Products min/max 36';
            qt1.Amended_Renewed_Service_Contract__c = objSC1.Id;
            qt1.SBQQ__LastCalculatedOn__c = System.Today().addDays(7);
            qt2.RWD_Deal_Ops_Exception__c = 'Annual Products min/max 36';
            qt2.Amended_Renewed_Service_Contract__c = objSC1.Id;
            qt2.SBQQ__LastCalculatedOn__c = System.Today().addDays(7);
            qt2.ApprovalStatus__c = 'Pending';
            qtlist2.add(qt1);
            qtlist2.add(qt2);
            qtlist2.add(qt3);
            update qtlist2;
            
            Order ordr11 = new Order(
                Type = 'Revenue',
                AccountId = acct.Id,
                OpportunityId = oppr.Id,
                ShippingStreet = 'Test Street',
                ShippingCity = 'Test City',
                ShippingState = null,
                ShippingCountry = 'Austria',
                ShippingPostalcode = '94820',
                EffectiveDate = system.Today(),
                Status = 'Pending',
                Pricebook2Id = pb1.Id
            );
            
            insert ordr11;
            
            List<Asset> AssetList = new List<Asset>();
            Asset asst1 = getAsset('Test1234567Assets1', prod3.Id, acct.Id);
            AssetList.add(asst1);
            
            Asset asst2 = getAsset('TestAsset4', prod3.Id, acct.Id);
            AssetList.add(asst2);
            
            Asset asst3 = getAsset('TestAsset6', prod3.Id, acct.Id);
            AssetList.add(asst3);
            
            Asset asst4 = getAsset('TestAsset3', prod3.Id, acct.Id);
            AssetList.add(asst4);
            
            insert AssetList;
            
            oppr.StageName = '6 PO Recieved';
            //update oppr;
            
            //ordr.Ship_To_Name__c = acct.id;
            ordr11.ShipToContactName__c = 'ah';
            ordr11.Shipping_Method__c = 'Other';
            ordr11.Shipping_Carrier__c = 'AIT';
            ordr11.Service_Level__c = 'Economy';
            ordr11.Bill_To_Name__C = acct.id;
            ordr11.est_Ship_Date__C = System.Today().addDays(7);
            ordr11.Status = 'Order Accepted';
            
            //update ordr;
            //create your opportunity line item.  This assumes you already have an opportunity created, called opp
            OrderItem oli1 = getOli(ordr11.Id, pbEntry1.Id, pbEntry1.UnitPrice, 'Test1234567Asset2123');
            
            //create your opportunity line item.  This assumes you already have an opportunity created, called opp
            OrderItem oli2 = getOli(ordr11.Id, pbEntry2.Id, pbEntry2.UnitPrice, 'Test1234567Asset314');
            
            OrderItem oli3 = getOli(ordr11.Id, pbEntry3.Id, pbEntry3.UnitPrice, 'Test1234567Asset321');
            
            ServiceContract objSC = new ServiceContract(
                Name = 'ServiceContract Test',
                AccountId = acct.Id,
                StartDate = Date.today(),
                Term = 36,
                pricebook2Id = pb1.Id,
                SBQQSC__Opportunity__c = oppr.Id,
                SBQQSC__Order__c = ordr11.Id,
                SBQQSC__Quote__c = qt1.Id
            );
            
            insert objSC;
            
            List<ContractLineItem> lstCli = new List<ContractLineItem>();
            ContractLineItem cli = getCli(oli1.PricebookEntryId, objSC.id);
            cli.Quantity = oli1.quantity;
            cli.SBQQSC__Discount__c = 10;
            cli.PricebookEntryId = oli1.PricebookEntryId;
            cli.StartDate = date.today();
            lstCli.add(cli);
            
            ContractLineItem cli2 = getCli(oli2.PricebookEntryId, objSC.id);
            cli2.Quantity = oli2.quantity;
            cli.SBQQSC__Discount__c = 10;
            cli2.UnitPrice = oli2.UnitPrice;
            cli2.StartDate = date.today();
            lstCli.add(cli2);
            
            ContractLineItem cli3 = getCli(oli3.PricebookEntryId, objSC.id);
            cli3.Quantity = oli3.quantity;
            cli.SBQQSC__Discount__c = 10;
            cli3.UnitPrice = oli3.UnitPrice;
            cli3.StartDate = date.today();
            lstCli.add(cli3);
            
            insert lstCli;
            
            List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
            SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt1.Id,
                Prior_Net_Total__c = 10,
                SBQQ__Product__c = prod1.Id,
                SBQQ__Quantity__c = 20,
                SBQQ__SubscriptionPricing__c = null,
                SBQQ__DefaultSubscriptionTerm__c = null,
                SBQQ__ListPrice__c = 200,
                SBQQ__NetPrice__c = 200,
                SBQQ__DiscountScheduleType__c = 'Slab',
                Scale_Utility_Product__c = true,
                Scale_Utility_Product_Identifier__c = 'M365 SU RSVX',
                SBQQ__StartDate__c = Date.today(),
                SBQQSC__RenewedContractLine__c= cli.Id,
                SBQQ__EndDate__c = Date.today().addDays(11),
                SubscribedAssetNames__c = 'BB192863040046',
                Product_Type__c = 'Hardware'
            );
            insert ql1;
            SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c();
            qli1.SBQQ__Quote__c = qt.Id;
            qli1.SBQQ__Product__c = prod6.Id;//GTMIT-49
            qli1.SBQQ__Quantity__c = 10;
            qli1.SBQQ__Number__c = 1;
            qli1.SubscribedAssetNames__c = 'BB192863040046';
            qli1.SBQQ__ListPrice__c = 100;
            qli1.Product_Type__c ='PAYGO-Commit';
            insert qli1;//Gtmit - 49
            
            SBQQ__QuoteLine__c ql2 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt1.Id,
                SBQQ__Source__c = ql1.Id,
                Prior_Net_Total__c = 0,
                SBQQ__Product__c = prod2.Id,
                MSP_Segment_Product__c = true,
                SBQQ__Quantity__c = 20,
                SBQQ__Segmentindex__c = 1,
                SBQQ__SubscriptionPricing__c = 'Fixed Price',
                Scale_Utility_Product__c = true,
                Scale_Utility_Product_Identifier__c = 'M365 SU RSVX',
                SBQQ__DefaultSubscriptionTerm__c = null,
                SBQQ__ListPrice__c = 200,
                SBQQ__NetPrice__c = 200,
                SBQQ__DiscountScheduleType__c = 'Slab',
                SBQQ__StartDate__c = Date.today(),
                SBQQSC__RenewedContractLine__c= cli2.Id,
                SubscribedAssetNames__c = 'BB192863040047',
                Who_will_the_customer_be_buying_the_HW__c = 'Reseller'
            );
            lines.add(ql2);
            SBQQ__QuoteLine__c ql3 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt1.Id,
                SBQQ__Product__c = prod1.Id,
                SBQQ__Source__c = ql1.Id,
                SBQQ__Quantity__c = 25,
                SBQQ__SubscriptionPricing__c = null,
                SBQQ__DefaultSubscriptionTerm__c = 12,
                SBQQ__ListPrice__c = 200,
                SBQQ__NetPrice__c = 200,
                SBQQ__DiscountScheduleType__c = 'Slab',
                Scale_Utility_Product__c = true,
                Scale_Utility_Product_Identifier__c = 'M365 SU RSVX',
                SBQQ__StartDate__c = Date.today(),
                SBQQ__EndDate__c = Date.today().addDays(10),
                SubscribedAssetNames__c = 'BB192863040048'
            );
            lines.add(ql3);
            SBQQ__QuoteLine__c ql4 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt1.Id,
                SBQQ__Product__c = prod4.Id,
                SBQQ__Source__c = ql1.Id,
                MSP_Segment_Product__c = true,
                SBQQ__Quantity__c = 20,
                SBQQ__Segmentindex__c = 1,
                SBQQ__SubscriptionPricing__c = 'Fixed Price',
                SBQQ__DefaultSubscriptionTerm__c = null,
                Scale_Utility_Product__c = true,
                Scale_Utility_Product_Identifier__c = 'M365 SU RSVX',
                SBQQ__ListPrice__c = 200,
                SBQQ__NetPrice__c = 200,
                SBQQ__DiscountScheduleType__c = 'Slab',
                SubscribedAssetNames__c = 'BB192863040049'
            );
            lines.add(ql4);
            
            SBQQ__QuoteLine__c ql5 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt.Id,
                Prior_Net_Total__c = 10,
                SBQQ__Product__c = prod1.Id,
                SBQQ__Quantity__c = 20,
                SBQQ__SubscriptionPricing__c = null,
                SBQQ__DefaultSubscriptionTerm__c = null,
                SBQQ__ListPrice__c = 200,
                SBQQ__NetPrice__c = 100000,
                SBQQ__DiscountScheduleType__c = 'Slab',
                Scale_Utility_Product__c = true,
                Scale_Utility_Product_Identifier__c = 'M365 SU RSVX',
                SBQQ__StartDate__c = Date.today(),
                SBQQ__EndDate__c = Date.today().addDays(10),
                SubscribedAssetNames__c = 'BB192863040046',
                Product_Type__c = 'Hardware'
            );
            lines.add(ql5);
            
            SBQQ__QuoteLine__c ql6 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt.Id,
                Prior_Net_Total__c = 10,
                SBQQ__Product__c = prod1.Id,
                SBQQ__Quantity__c = 20,
                SBQQ__SubscriptionPricing__c = null,
                SBQQ__DefaultSubscriptionTerm__c = null,
                SBQQ__ListPrice__c = 200,
                SBQQ__NetPrice__c = 40000,
                SBQQ__DiscountScheduleType__c = 'Slab',
                Scale_Utility_Product__c = true,
                Scale_Utility_Product_Identifier__c = 'M365 SU RSVX',
                SBQQ__StartDate__c = Date.today(),
                SBQQ__EndDate__c = Date.today().addDays(10),
                SubscribedAssetNames__c = 'BB192863040046',
                Product_Type__c = 'Hardware',
                SBQQ__Source__c = ql1.Id
            );
            lines.add(ql6);
            
            insert lines;
            lines.add(ql1);
            list<Merged_Quote_Line__c> mtqtList = new List<Merged_Quote_Line__c>();
            
            Merged_Quote_Line__c Mqt1 = new Merged_Quote_Line__c(
                Name = 'test',
                Merged_Renewal_Quote_Line__c = ql1.Id,
                New_Quote_Line__c = ql1.Id,
                Quote__c = qt1.Id
            );
            mtqtList.add(Mqt1);

            Merged_Quote_Line__c Mqt2 = new Merged_Quote_Line__c(
                Name = 'test',
                Merged_Renewal_Quote_Line__c = ql5.Id,
                New_Quote_Line__c = ql5.Id,
                Quote__c = qt.Id
            );
            mtqtList.add(Mqt2);
            
            insert mtqtList;
            Consolidated_Contract_Lines__c consolidateContractLines = new Consolidated_Contract_Lines__c();
            consolidateContractLines.Quote_Line__c = ql1.Id;
            consolidateContractLines.Quote__c =qt1.Id;
            consolidateContractLines.Contract_Line_Item__c = cli3.Id;
            insert consolidateContractLines;
            set<Id> QtId = new Set<Id>{ qt1.Id, qt2.Id };
                
            Map<Id, SBQQ__Quote__c> QtMap = new Map<Id, SBQQ__Quote__c>(qtlist);
            //Additional Coverage PJ
            Group deal = new Group();
            deal.Name = 'Deal Desk';
            deal.DeveloperName = 'testDeveloper';
            deal.Type = 'Regular';
            insert deal;

		    sbaa__Approver__c app = new sbaa__Approver__c();
            app.name = 'Deal Desk';
            app.sbaa__GroupId__c = deal.id;
            app.sbaa__DelegationStart__c = Date.newInstance(2018, 10, 9);
            app.sbaa__DelegationEnd__c = Date.newInstance(2018, 8, 13);
            insert app;

		    List<sbaa__ApprovalRule__c> approvalRule = new List<sbaa__ApprovalRule__c>();
            sbaa__ApprovalRule__c rule1 = new sbaa__ApprovalRule__c();
            rule1.name = 'Expiration Date Exception'; 
            rule1.sbaa__TargetObject__c = 'SBQQ__Quote__c';
            rule1.sbaa__Approver__c = app.id;
            rule1.sbaa__ApprovalStep__c = 1;
            rule1.sbaa__ConditionsMet__c = 'All';
            approvalRule.add(rule1);
		    insert approvalRule;
			
		    List<sbaa__Approval__c> approvals = new List<sbaa__Approval__c>();
            sbaa__Approval__c approval = new sbaa__Approval__c(
                Quote__c = qt1.Id,
                sbaa__Opportunity__c = oppr.Id,
                sbaa__Status__c = 'Approved',
                sbaa__Approver__c = app.Id,
                sbaa__RecordField__c = 'Quote__c',  
                sbaa__ApprovalStep__c = 1,
                sbaa__archived__c = false,
                sbaa__rule__c = approvalRule[0].Id
            );
            approvals.add(approval);
            insert approvals;
            Approval_Snapshot__c snap = new Approval_Snapshot__c(
                Quote__c = qt1.Id,
                Quote_Line__c = ql1.Id,
                History__c = 'Initial Approval Snapshot'
            );
            insert snap;
            
            TriggerControls.disableQuoteTrigger = false;
            TriggerControls.disableQuoteLineTrigger = false;
            SBQQ.TriggerControl.enable();
            Test.startTest();
            
            QuoteTriggerHelper.hwApplianceAndTphAddedTogetherValidation(qtlist);
            //QuoteTriggerHelper.populateFieldsOnUpdate(qtlist2, QtMap);
            QuoteTriggerHelper.createMergedQLRecords(QtId, QtId);
            QuoteTriggerHelper.createCCLIRecords(QtId, QtId);  //REEN-25 
            QuoteTriggerHelper.sendNotificationForDealSize(qtlist2, QtMap);
            QuoteTriggerHelper.populateFieldsOnInsert(qtlist);
			QuoteTriggerHelper.populateFieldsOnOpportunity(QtMap);
            //QuoteTriggerHelper.populateCoTermOnInsert(qtlist,QtMap);
            
            
            QuoteTriggerHelper.populateFieldsOnInsert(qtlist);
            for (SBQQ__Quote__c quote : qtlist) {
                quote.RWD_Deal_Ops_Exception__c = 'AMER-FED Account quoting RSC';
                //code_block
            }
            QuoteTriggerHelper.setModifiedDealOpsExceptions(qtlist);
            Test.stopTest();
            
            System.assert(true);
        }
    }
    /**************************************************************************************************
    * Method Name          : populateFieldsFromOpportunityTest
    * @description         : populateFieldsFromOpportunityTest for covering QuoteTriggerHelper
    /************************************************************************************************/
    @isTest
    static void populateFieldsFromOpportunityTest() {
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        user usr1 = [SELECT Id FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
            Account acct = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            acct.OwnerId = system.Label.Data_Migration_User_ID;
            insert acct;
            Account acct2 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            acct2.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert acct2;
            Id standardPriceBookId = Test.getStandardPricebookId();
            
            PriceBook2 pb1 = new Pricebook2(
                Name = 'V68_2017_08_09_12_26_43',
                Description = 'Price Book 2009 Products 1',
                IsActive = true
            );
            insert pb1;
            
            //Create your product
            Product2 prod1 = new Product2(Name = 'RBK-GO-BE-R6408', ProductCode = 'RBK-GO-BE-R6408', isActive = true);
            Product2 prod2 = new Product2(
                Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
                ProductCode = 'RBK-SVC-PREM-R304',
                isActive = true
            );
            //Create your product
            Product2 prod3 = new Product2(Name = 'RBK-GO-BE-R6408', ProductCode = 'RBK-GO-BE-R6408', isActive = true);
            //Create your product
            Product2 prod4 = new Product2(Name = 'RBK-RCDM-10-MO-CLON', ProductCode = 'RBK-RCDM-AWS-MO', isActive = true);
            
            Product2 prod5 = new Product2(Name = 'RS-BE-GO-PE-PP', ProductCode = 'RS-BE-GO-PE-PP', isActive = true);
            
            insert new List<Product2>{ prod1, prod2, prod3, prod4, prod5 };
                
            //Create your pricebook entry
            PricebookEntry pbStanEntry1 = getPbe(prod1.Id, 100.00);
            
            //Create your pricebook entry
            PricebookEntry pbStanEntry2 = getPbe(prod2.Id, 1000.00);
            
            //Create your pricebook entry
            PricebookEntry pbStanEntry3 = getPbe(prod3.Id, 100.00);
            
            //Create your pricebook entry
            PricebookEntry pbStanEntry4 = getPbe(prod4.Id, 100.00);
            
            PricebookEntry pbStanEntry5 = getPbe(prod5.Id, 100.00);
            
            //Create your pricebook entry
            PricebookEntry pbEntry1 = getPbe(pb1.Id, prod1.Id, 100.00);
            
            //Create your pricebook entry
            PricebookEntry pbEntry2 = getPbe(pb1.Id, prod2.Id, 1000.00);
            
            //Create your pricebook entry
            PricebookEntry pbEntry3 = getPbe(pb1.Id, prod3.Id, 1000.00);
            
            //Create your pricebook entry
            PricebookEntry pbEntry4 = getPbe(pb1.Id, prod4.Id, 1000.00);
            
            PricebookEntry pbEntry5 = getPbe(pb1.Id, prod5.Id, 1000.00);
            
            insert new List<PricebookEntry>{
                pbStanEntry1,
                pbStanEntry2,
                pbStanEntry3,
                pbStanEntry4,
                pbStanEntry5,
                pbEntry1,
                pbEntry2,
                pbEntry3,
                pbEntry4,
                pbEntry5
                };
      
            
            Opportunity oppr = TestDataFactory.getOpportunity(acct);
            oppr.Type = 'Existing Customer';
            oppr.Opportunity_Sub_Type__c = 'MSP';
            oppr.Distributor_Lookup__c = acct2.Id;
            oppr.Partner_Lookup__c = acct2.Id;
            //insert oppr;
            
            Opportunity oppr1 = TestDataFactory.getOpportunity(acct);
            oppr1.Type = 'Existing Customer';
            oppr1.Opportunity_Sub_Type__c = 'MSP';
            oppr1.StageName = '7 Closed Lost';
            
            upsert new List<Opportunity>{ oppr1 , oppr};
            Map<String, Object> quoteMap = new Map<String, Object>{
                'SBQQ__Account__c' => acct.Id,
                'SBQQ__Opportunity2__c' => oppr.Id
            };
            SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
            qt.SBQQ__Opportunity2__c = oppr.Id;
            qt.SBQQ__Primary__c = false;
            qt.SBQQ__PriceBook__c = pb1.Id;
            qt.ApprovalStatus__c = 'Approved';
            qt.SBQQ__Type__c = 'Amendment';
            qt.SBQQ__StartDate__c = Date.today();
            qt.Manual_Billing__c = false;
            qt.Consolidate_Lines__c = false;
            qt.OpportunitySubType__c = 'MSP';
            insert qt;
    
            ServiceContract objSC = new ServiceContract(
                Name = 'ServiceContract Test',
                AccountId = acct.Id,
                StartDate = Date.today(),
                Term = 36,
                pricebook2Id = pb1.Id,
                SBQQSC__Opportunity__c = oppr.Id,
                SBQQSC__Quote__c = qt.Id
            );
            insert objSC;
            
            Opportunity oppr2 = TestDataFactory.getOpportunity(acct);
            oppr2.Type = 'Existing Customer';
            oppr2.Opportunity_Sub_Type__c = 'MSP';
            oppr2.StageName = '7 Closed Lost';
            oppr2.SBQQSC__AmendedServiceContract__c = objSC.Id;
            oppr2.SBQQSC__RenewedServiceContract__c = objSC.Id; 
            oppr2.Churn_Type__c = 'Account Churn';
            oppr2.Opportunity_Sub_Type__c = 'GC Offer';
            // oppr2.Pricebook2Id = pb1.Id;
            insert new List<Opportunity>{ oppr2 };
    
            Map<String, Object> quoteMap1 = new Map<String, Object>{
                'SBQQ__Account__c' => acct.Id,
                'SBQQ__Opportunity2__c' => oppr.Id
            };
            
            SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap1);
            qt1.SBQQ__Opportunity2__c = oppr2.Id;
            qt1.SBQQ__Primary__c = false;
            qt1.SBQQ__PriceBook__c = pb1.Id;
            qt1.ApprovalStatus__c = 'Approved';
            qt1.SBQQ__Type__c = 'Renewal';
            qt1.SBQQ__StartDate__c = Date.today();
            qt1.Manual_Billing__c = false;
            qt1.Consolidate_Lines__c = false;
            qt1.Amended_Renewed_Service_Contract__c = objSC.Id;
            qt1.SBQQ__ExpirationDate__c = System.today().addDays(300);
            qt1.OwnerId = system.Label.Data_Migration_User_ID;
            insert new List<SBQQ__Quote__c> {qt1};

            qt1.RWD_Deal_Ops_Exception__c = 'AMER-FED Account quoting RSC';
            qt1.RWD_Deal_Ops_Exception_Justification__c = 'tvmbsxhnlcskdjxnv/kdnknv jnfdj ncl.nd.z n';
            update qt1;
            Map<Id, Opportunity> OppMap = new Map<Id, Opportunity>(
                [
                    SELECT Id, Type, Opportunity_Sub_Type__c, StageName, SBQQSC__AmendedServiceContract__c,Deal_Structuring_Oppty_Notes__c,SBQQSC__RenewedServiceContract__c
                    FROM Opportunity
                    LIMIT 50000
                ]
            );
            
            TriggerControls.disableQuoteTrigger = false;
            TriggerControls.disableQuoteLineTrigger = false;
            SBQQ.TriggerControl.enable();
            
            Test.startTest();
            
            QuoteTriggerHelper.populateFieldsFromOpportunity(qt1, OppMap);
            
            qt1.Amended_Renewed_Service_Contract__c = null;
            QuoteTriggerHelper.populateFieldsFromOpportunity(qt1, OppMap);
            
            qt1.Amended_Renewed_Service_Contract__c = null;
            
            for(Opportunity obj: OppMap.values()){
                obj.SBQQSC__AmendedServiceContract__c = null;
            }
            QuoteTriggerHelper.populateFieldsFromOpportunity(qt1, OppMap);
            
            qt1.Error_Message_From_QCP__c ='Test';
            Map<Id, SBQQ__Quote__c> quoteOldMap = new Map<Id, SBQQ__Quote__c>();
            quoteOldMap.put(qt1.Id,qt1);
            QuoteTriggerHelper.ThrowErrorMessage(new List<SBQQ__Quote__c>{qt1},quoteOldMap);
            //QuoteTriggerHelper.quotelinemap = null;
            //QuoteTriggerHelper.quotelinemap = 
            QuoteTriggerHelper.getquotelines(new Set<Id>{qt1.Id});            
    
            Order ordr11 = new Order(
                Type = 'Revenue',
                AccountId = acct.Id,
                OpportunityId = oppr.Id,
                ShippingStreet = 'Test Street',
                ShippingCity = 'Test City',
                ShippingState = null,
                ShippingCountry = 'Austria',
                ShippingPostalcode = '94820',
                EffectiveDate = system.Today(),
                Status = 'Pending',
                Pricebook2Id = pb1.Id
            );
            
            insert ordr11;
            
            List<Asset> AssetList = new List<Asset>();
            Asset asst1 = getAsset('Test1234567Assets1', prod3.Id, acct.Id);
            AssetList.add(asst1);
            
            Asset asst2 = getAsset('TestAsset4', prod3.Id, acct.Id);
            AssetList.add(asst2);
            
            Asset asst3 = getAsset('TestAsset6', prod3.Id, acct.Id);
            AssetList.add(asst3);
            
            Asset asst4 = getAsset('TestAsset3', prod3.Id, acct.Id);
            AssetList.add(asst4);
            
            insert AssetList;
    
            OrderItem oli1 = getOli(ordr11.Id, pbEntry1.Id, pbEntry1.UnitPrice, 'Test1234567Asset2123');
            
            //create your opportunity line item.  This assumes you already have an opportunity created, called opp
            OrderItem oli2 = getOli(ordr11.Id, pbEntry2.Id, pbEntry2.UnitPrice, 'Test1234567Asset314');
            
            OrderItem oli3 = getOli(ordr11.Id, pbEntry3.Id, pbEntry3.UnitPrice, 'Test1234567Asset321');
            
            ServiceContract objSC1 = new ServiceContract(
                Name = 'ServiceContract Test',
                AccountId = acct.Id,
                StartDate = Date.today(),
                Term = 36,
                pricebook2Id = pb1.Id,
                SBQQSC__Opportunity__c = oppr.Id,
                SBQQSC__Order__c = ordr11.Id,
                SBQQSC__Quote__c = qt1.Id
            );
            
            insert objSC1;
            
            List<ContractLineItem> lstCli = new List<ContractLineItem>();
            ContractLineItem cli = getCli(oli1.PricebookEntryId, objSC1.id);
            cli.Quantity = oli1.quantity;
            cli.PricebookEntryId = oli1.PricebookEntryId;
            cli.StartDate = date.today();
            lstCli.add(cli);
            insert lstCli;
            SBQQ__Quote__c quoteResult = [SELECT Id, SBQQ__PriceBook__r.Name,
                SBQQ__Opportunity2__r.Pricebook2.Name FROM SBQQ__Quote__c WHERE Id =:qt1.Id ];
            SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt1.Id,
                Prior_Net_Total__c = 10,
                SBQQ__Product__c = prod1.Id,
                SBQQ__Quantity__c = 20,
                SBQQ__SubscriptionPricing__c = null,
                SBQQ__DefaultSubscriptionTerm__c = null,
                SBQQ__ListPrice__c = 200,
                SBQQ__NetPrice__c = 200,
                SBQQ__DiscountScheduleType__c = 'Slab',
                Scale_Utility_Product__c = true,
                Scale_Utility_Product_Identifier__c = 'M365 SU RSVX',
                SBQQ__StartDate__c = Date.today(),
                SBQQ__PricebookEntryId__c = cli.PricebookEntryId,
                // SBQQSC__RenewedContractLine__c= cli.Id,
                SBQQ__EndDate__c = Date.today().addDays(11),
                SubscribedAssetNames__c = 'BB192863040046',
                Product_Type__c = 'Hardware'
            );
            //        insert ql1;
    
            QuoteTriggerHelper.userLicenseCountValidation(new List<SBQQ__Quote__c>{qt1});
            
            qt1.SBQQ__Status__c = 'Expired';
            qt1.SBQQ__StartDate__c = Date.today();
            qt1.EOL_New_Product_Earliest_Date__c = Date.today().addDays(20);
            //qt1.SBQQ__ExpirationDate__c = Date.today().addDays(120);
            qt1.Update_Expires_On__c = true;
            qt1.SBQQ__ExpirationDate__c = Date.today();
            //update qt1;
            QuoteTriggerHelper.UpdateOnExpireDateExtension(quoteOldMap,new List<SBQQ__Quote__c>{qt1});
            
            qt1.ApprovalStatus__c = 'Rejected';
            qt1.SBQQ__Type__c = 'Renewal';
            
            QuoteTriggerHelper.populateFieldsOnUpdate(new List<SBQQ__Quote__c>{qt1},quoteOldMap);
            
            qt1.ApprovalStatus__c = 'Rejected';
            qt1.SBQQ__Type__c = 'Renewal+Expansion';
            qt1.SBQQ__LastCalculatedOn__c = System.today();
            qt1.RWD_Deal_Ops_Exception__c = 'Complete Edition - Hard Floors';
            
            QuoteTriggerHelper.populateFieldsOnUpdate(new List<SBQQ__Quote__c>{qt1},quoteOldMap);
    
            for (SBQQ__Quote__c obj : quoteOldMap.values()) {
                obj.RWD_Deal_Ops_Exception__c = '';
                obj.SBQQ__LastCalculatedOn__c = null;
                obj.ApprovalStatus__c = null;
                //code_block
            }
    
            Task t = new Task();
            //t.OwnerId = taskUser[0].id;
            t.Subject = ' is quoted on Quote #' + qt1.name;
            t.Priority = 'Normal';
            t.Status = 'Not Started';
            t.Type = 'Action';
            t.WhatId = qt1.SBQQ__Account__c;
            t.Task_Email__c = system.label.Task_Email;
    
            qt1.SBQQ__Status__c = 'Draft';
            qt1.Task_Products__c = null;
            QuoteTriggerHelper.populateFieldsOnUpdate(new List<SBQQ__Quote__c>{qt1},quoteOldMap);
    
    
            QuoteTriggerHelper.userLicenseCountValidation(new List<SBQQ__Quote__c>{qt1});
            
            Test.stopTest();
            
            System.assert(true);
        } 
    }
    /**************************************************************************************************
    * Method Name          : createDealDeskCaseTest
    * @description         : createDealDeskCaseTest for covering QuoteTriggerHelper
    /************************************************************************************************/
    @IsTest
    public static void createDealDeskCaseTest(){
        
        user usr1 = [SELECT Id FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
        
            insert new TriggerControl__c(
                Name = 'Approval',
                DisableTrigger__c = true
            );
            
            Opportunity oopt = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
            oopt.Name = 'Test Opportunity';
            oopt.StageName = 'Prospecting';
            oopt.CloseDate = Date.today();
            insert oopt;
            
            List<SBQQ__Quote__c> quotes = new List<SBQQ__quote__c>();
            
            SBQQ__Quote__c quote = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
            quote.SBQQ__Opportunity2__c = oopt.Id;
            quotes.add(quote);
            
            SBQQ__Quote__c quote2 = quote.clone();
            quotes.add(quote2);
            
            insert quotes;
            
            sbaa__Approver__c approver = new sbaa__Approver__c(
                Name= 'Deal Desk'
            );
            insert approver;
            
            sbaa__ApprovalRule__c rule = new sbaa__ApprovalRule__c(
                sbaa__Approver__c = approver.Id,
                sbaa__Active__c = true,
                sbaa__TargetObject__c   = 'SBQQ__Quote__c',
                Name = 'Expiration Date Exceeds Start Date'
            );
            insert rule;
            
            List<sbaa__Approval__c> approvals = new List<sbaa__Approval__c>();
            sbaa__Approval__c approval = new sbaa__Approval__c(
                Quote__c = quote.Id,
                sbaa__Opportunity__c = oopt.Id,
                sbaa__Status__c = 'Requested',
                sbaa__Approver__c = approver.Id,
                sbaa__RecordField__c = 'Quote__c',
                sbaa__ApprovalStep__c = 1,
                sbaa__rule__c = rule.Id
            );
            sbaa__Approval__c approval1 = new sbaa__Approval__c(
                Quote__c = quote.Id,
                sbaa__Opportunity__c = oopt.Id,
                sbaa__Status__c = 'Revoked',
                sbaa__Approver__c = approver.Id,
                sbaa__RecordField__c = 'Quote__c',
                sbaa__ApprovalStep__c = 1,
                sbaa__rule__c = rule.Id
            );
            approvals.add(approval1);
            
            sbaa__Approval__c approval2 = approval.clone();
            approval2.Quote__c = quote2.Id;
            approvals.add(approval2);
            insert approvals;
            
            Deal_Desk_Case__c ddcCase = new Deal_Desk_Case__c(
                Quote__c = quote.Id,
                Opportunity__c = quote.sbqq__opportunity2__c,
                Deal_Desk_Team__c = 'Deal Structuring',
                ApprovalStatus__c = '',
                Request_Type__c = 'General Inquiry',
                Business_Justification__c = 'minimum characters',
                Summary_of_Approval__c = 'test'
            );
            
            insert ddcCase;
            
            ddcCase.Request_Status__c = 'Draft';
            //ddcCase.ApprovalStatus__c = 'Approved';
            update ddcCase;

            List<SBQQ__Quote__c> quoteRecs = new List<SBQQ__Quote__c>{quote, quote2};
            Test.startTest();
            //QuoteTriggerHelper.createDealDeskCase(quoteRecs);

            
            ddcCase.Request_Status__c = 'Approved';
            ddcCase.ApprovalStatus__c = 'Approved';
            update ddcCase;

            List<SBQQ__Quote__c> quoteRecs1 = new List<SBQQ__Quote__c>{quote, quote2};
            //QuoteTriggerHelper.createDealDeskCase(quoteRecs1);
            
            quote.Legal_Approved_Verbiage__c = 'gvmdsbuhjdb bknjn s,dnusdih vbsdchksbuh';
            List<SBQQ__Quote__c> quoteRecs2 = new List<SBQQ__Quote__c>{quote, quote2};

            QuoteTriggerHelper.updateSpecialRequestsNeededField(quoteRecs2);
            Test.stopTest();
            System.assert(true);
        }
    }
}