@isTest
public class ShGl_TestFactory_Test {

    //Example Test Class Code
    static testMethod void testMethod_0 () {
        ShGl_TestFactory.getRequiredFieldDefaults(new Account());
    }

    //Example Test Class Code
    static testMethod void testMethod_UserCreation () {

        //START - UserRole creation
        UserRole usrRole = (UserRole) ShGl_TestFactory.createSObject(new UserRole(), null);
        system.debug('usrRole :: '+usrRole);
        insert usrRole;
        
        List<UserRole> usrRoleList = (List<UserRole>) ShGl_TestFactory.createSObjectList(new UserRole(), 5, null);
        system.debug('usrRoleList :: '+usrRoleList);
        insert usrRoleList;
        
        Map<String, Object>  usrRoleMap = new Map<String, Object> {
            'Name' => 'Test UserRole'
        };
        UserRole usrRoleM = (UserRole) ShGl_TestFactory.createSObject(new UserRole(), usrRoleMap);
        system.debug('usrRoleM :: '+usrRoleM);
        insert usrRoleM;
        //END - UserRole creation
        
        //START - User creation
        User usr = (User) ShGl_TestFactory.createSObject(new User(), null);
        system.debug('usr :: '+usr);
        insert usr;
        
        List<User> usrList = (List<User>) ShGl_TestFactory.createSObjectList(new User(), 5, null);
        system.debug('usrList :: '+usrList);
        insert usrList;
        
        Map<String, Object> m = new Map<String, Object> {
            'emailencodingkey' => 'UTF-8',
            'languagelocalekey' => 'en_US',
            'localesidkey' => 'en_US',
            'country' => 'United Kingdom',
            'isActive' => true,
            'timezonesidkey' => 'Europe/London',
            'FirstName' => 'testMethod_UserCreation',
            'LastName' => 'testMethod_UserCreation',
            'Email' => 'test'+ Math.random().format() + string.valueof(Datetime.now()).replace('-','').replace(':','').replace(' ','') +'user1@test.rubrik.com',
            'UserName' => 'test'+ Math.random().format() + string.valueof(Datetime.now()).replace('-','').replace(':','').replace(' ','') +'user1@test.rubrik.com',
            'Alias' => 'testU',
            'ProfileId' => ([Select Id from Profile where Name='System Administrator'].id)
        };
        User usrM = (User) ShGl_TestFactory.createSObject(new User(), m);
        system.debug('usrM :: '+usrM);
        insert usrM;
        //END - User creation

    }

    //Example Test Class Code
    static testMethod void testMethod_AccountCreation () {

        User usr = (User) ShGl_TestFactory.createSObject(new User(), null);
        system.debug('usr :: '+usr);
        insert usr;

        //create single account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        system.debug('act :: '+act);
        insert act;
        
        List<Account> actList = [SELECT Id FROM Account];
        System.assertEquals(1, actList.size());

        //create a list of accounts - size 10
        List<Account> newActList = (List<Account>) ShGl_TestFactory.createSObjectList(new Account(), 10, null);
        for (Account ant : newActList) {
            system.debug('ant :: '+ant);
        }
        insert newActList;
        
        List<Account> actList1 = [SELECT Id FROM Account];
        System.assertEquals(11, actList1.size());
        
        //create single account with dynamic values
        Map<String, Object>  m = new Map<String, Object> {
            'Name' => 'Test Arpit Account',
            'Type' => 'Customer',    
            'BillingStreet' => '444 Saratoga Ave',
            'BillingCity' => 'Santa Clara',
            'BillingState' => 'California',
            'BillingCountry' => 'United States',
            'BillingPostalCode' => '95050'
        };
        Account act2 = (Account) ShGl_TestFactory.createSObject(new Account(), m);
        system.debug('act2 :: '+act2);
        insert act2;
        
        Account act2Q = [SELECT Id, Name, Type FROM Account WHERE Id = :act2.Id];
        System.assertEquals('Test Arpit Account', act2Q.Name);
        System.assertEquals('Customer', act2Q.Type);
        
    }

    //Example Test Class Code
    static testMethod void testMethod_ContactCreation() {

        ShGl_TestFactoryHelper.insertTriggerControls();

        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        List<Account> actList = new List<Account>();
        actList.add(act);
        insert actList;
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
        };
        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        Contact cnt2 = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        List<Contact> cntList = (List<Contact>) ShGl_TestFactory.createSObjectList(new Contact(), 2, cntMap);
        cntList.add(cnt1);
        cntList.add(cnt2);
        insert cntList;

        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => act.Id
        };
        Map<String, Object>  oppMap1 = new Map<String, Object> {
            'AccountId' => act.Id,
            'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId()
        };
        Map<String, Object>  oppMap2 = new Map<String, Object> {
            'AccountId' => act.Id,
            'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId()
        };
            
        Opportunity opp1 = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        Opportunity opp2 = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        Opportunity opp3 = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap1);
        Opportunity opp4 = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap2);
        List<Opportunity> opptyList = (List<Opportunity>) ShGl_TestFactory.createSObjectList(new Opportunity(), 2, oppMap);
        opptyList.add(opp1);
        opptyList.add(opp2);
        opptyList.add(opp3);
        opptyList.add(opp4);
        insert opptyList;
        List<SBQQ__Quote__c> qtList = TestDataFactory.getQuotes(new Set<Id>{opp1.Id, opp2.id}, 1);
 		qtList[0].SBQQ__Type__c = 'Amendment';
        qtList[1].SBQQ__Type__c = 'Amendment';
        insert qtList;
        System.assert(qtList[0].id != null);
    }
   
    
    static testMethod void testMethod_ContractCreation () {

        ShGl_TestFactoryHelper.insertTriggerControls();

        Map<String, Object> accMap = new Map<String, Object> {
            'Name' => 'testMethod_ContractCreation'
        };
        List<Account> actList = (List<Account>) ShGl_TestFactory.createSObjectList(new Account(), 2, accMap);
        insert actList;

        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
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
        Product2 prdHW1 = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        
        prdList.add(prdHW);
        prdList.add(prdHW1);
        prdList.add(prdSubs);
        insert prdList;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pBList.add(pbeHW);

        PricebookEntry pbeHW1 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW1.Product2Id = prdHW1.Id;
        pBList.add(pbeHW1);

        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pBList.add(pbeSubs);
        insert pBList;

        List<Asset> astList = (List<Asset>) ShGl_TestFactory.createSObjectList(new Asset(Product2Id = prdHW.Id), actList.size() * 5, null);
        for(Integer i = 0; i < astList.size(); i++){
            astList.get(i).AccountId = actList.get(MATH.mod(i, actList.size())).Id;
        }
        insert astList;

        List<ServiceContract> scList = (List<ServiceContract>) ShGl_TestFactory.createSObjectList(new ServiceContract(PriceBook2Id = Test.getStandardPricebookId()), astList.size(), null);
        for(Integer i = 0; i < scList.size(); i++){
            scList.get(i).AccountId = actList.get(MATH.mod(i, actList.size())).Id;
        }
        insert scList;

        List<ContractLineItem> cliList = new List<ContractLineItem>();
        Map<String, Object> cliMap = new Map<String, Object> {
            'StartDate' => Date.Today() - 90,
            'EndDate' => Date.Today().addDays(365),
            'Quantity' => 1
        };

        List<ContractLineItem> clis = null;
        clis = (List<ContractLineItem>) ShGl_TestFactory.createSObjectList(new ContractLineItem(PricebookEntryId = pbeHW.Id, UnitPrice = pbeHW.UnitPrice), astList.size(), cliMap);
        for(Integer i = 0; i < clis.size(); i++){
            clis.get(i).AssetId = astList.get(MATH.mod(i, astList.size())).Id;
            clis.get(i).ServiceContractId = scList.get(MATH.mod(i, scList.size())).Id;
        }
        cliList.addAll(clis);

        clis = (List<ContractLineItem>) ShGl_TestFactory.createSObjectList(new ContractLineItem(PricebookEntryId = pbeSubs.Id, UnitPrice = pbeSubs.UnitPrice), astList.size(), cliMap);
        for(Integer i = 0; i < clis.size(); i++){
            clis.get(i).AssetId = astList.get(MATH.mod(i, astList.size())).Id;
            clis.get(i).ServiceContractId = scList.get(MATH.mod(i, scList.size())).Id;
        }
        cliList.addAll(clis);
        
        insert cliList;

    }
    
    //Test Entitlement And Asset Creation
    static testMethod void test_EntitlementCreation () {

        ShGl_TestFactoryHelper.insertTriggerControls();

        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        
        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        prdHW.ProductCode = 'RBK-SVC-test-product';
        insert prdHW;
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        insert pbeHW;

        Asset ast = (Asset) ShGl_TestFactory.createSObject(new Asset(), null);
        ast.AccountId = act.Id;
        ast.Product2Id = prdHW.Id;
        insert ast;
        
        Entitlement ent = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        ent.AccountId = act.Id;
        ent.StartDate = Date.today().addDays(-365);
        ent.EndDate = Date.today().addDays(365);
        insert ent;
        
        List<Asset> astList = (List<Asset>) ShGl_TestFactory.createSObjectList(new Asset(), 2, null);
        List<Entitlement> entList = (List<Entitlement>) ShGl_TestFactory.createSObjectList(new Entitlement(), 2, null);
        
    }

    //Test Lead Creation
    static testMethod void test_LeadCreation () {

        ShGl_TestFactoryHelper.insertTriggerControls();
        ShGl_TestFactoryHelper.WorkflowTriggerBypass();

        Lead ld = TestDataFactory.insertLead();
        insert ld;
        ld = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
        List<Lead> ldList = (List<Lead>) ShGl_TestFactory.createSObjectList(new Lead(), 2, null);
    }

    //Test data Creation
    static testMethod void test_dataCreation(){
        test.startTest();        
        ShGl_TestFactoryHelper.WorkflowTriggerBypass();
        ShGl_TestFactory.testMethod_PartnerPageConfigurationCreation(1);
        User u = [select id,name from user where profile.name ='System Administrator' and userRoleId != null and isactive=true limit 1];
        List<User> lstUserRec = new List<User>();
        Account accRec = new Account();
        system.runas(u){
            accRec = ShGl_TestFactory.testMethod_PartnerAccount('Test Account');
            List<Contact> lstContact = ShGl_TestFactory.testMethod_PartnerContact(1,accRec);
            lstUserRec = ShGl_TestFactory.testMethod_PartnerUser(1,lstContact);
            CountryWithCode__c cc = new CountryWithCode__c(Code__c='US',Name='United States');
            insert cc;
        }
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        ShGl_TestFactory.testMethod_Content(1);
        List<ContentVersion> cv = ShGl_TestFactory.testMethod_Content(1);
        ContentVersion contentVersionSelect = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv[0].Id LIMIT 1];
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        ShGl_TestFactory.testMethod_EntitySubscription(documents[0].ID,UserInfo.getUserId());
        ShGl_TestFactory.testMethod_PartnerOnBoarding(1);
        List<String> lstCCRType= new List<String>();
        lstCCRType.add('Brik_Dollar_Incentive_Claim_Req');
        List<Incentives__c> lstIncentive = ShGl_TestFactory.testMethod_Incentive(1,lstCCRType);
        List<Id> lstIncentiveId = new List<Id>();
        lstIncentiveId.add(lstIncentive[0].Id);
        ShGl_TestFactory.testMethod_Attachment(1,lstIncentiveId);
        ShGl_TestFactory.testMethod_createDealRegistration(1);
        ShGl_TestFactory.testMethod_createUser(1);
        List<String> lstEmail = new List<String>();
        lstEmail.add('test@rubrik.com');
        List<CCR__c> lsrCCR = ShGl_TestFactory.testMethod_createCCR(1,lstEmail);
        ShGl_TestFactory.testMethod_createPRRequest(1);
        //ShGl_TestFactory.testMethod_createPartnerEvent(1);
        ShGl_TestFactory.testMethod_createPricebook(1);
        List<Product2> lstCreateProduct = ShGl_TestFactory.testMethod_createProduct(1);
        Id pricebookId = Test.getStandardPricebookId();
        List<PricebookEntry> lstPEStandard = ShGl_TestFactory.testMethod_createPriceBookEntries(lstCreateProduct,pricebookId);
        List<Pricebook2> customPB = ShGl_TestFactory.testMethod_createPricebook(1);
        List<PricebookEntry> lstPE = ShGl_TestFactory.testMethod_createPriceBookEntries(lstCreateProduct,customPB[0].Id);
        List<Order> lstOrder = ShGl_TestFactory.testMethod_createOrder(1,accRec,customPB[0]);
        ShGl_TestFactory.testMethod_PartnerOnBoardingWithoutInsert(1);
        ShGl_TestFactory.testMethod_createPatchManager(1);
        ShGl_TestFactory.testMethod_createLead(1);
        test.stopTest();
    }
    public static testmethod void deceboRecordTest(){
        test.startTest();
        Account accRec = ShGl_TestFactory.testMethod_PartnerAccount('Test Account');
        List<Contact> lstContact = ShGl_TestFactory.testMethod_PartnerContact(1,accRec);
        List<String> lstTraining = new List<String>();
        lstTraining.add('C64');
        lstTraining.add('C83');
        lstTraining.add('C82');
        lstTraining.add('C66');
        List<DOCEBO1_CO__c> lstTrainignRecord = ShGl_TestFactory.testMethod_createTraining(lstTraining);
        List<DOCEBO2_CO__c> lstDocebo = ShGl_TestFactory.testMethod_createDecebo(1,lstTrainignRecord[0],lstContact[0]);
        lstDocebo[0].Contact__c = lstContact[0].id;
        Test.stopTest();
    }
	public static  testmethod void testCode(){
        CCRreSubmitLogic.testCode();
    }
    public static  testmethod void testCode1(){
        ShGl_TestFactory.testCode();
    }
    public static testmethod void testCode3(){
        ShGl_TestFactory.createUserwithRole();
    }
    public static testmethod void testCode4(){
        ShGl_TestFactory.Product2Defaults prodDef = new ShGl_TestFactory.Product2Defaults();
        prodDef.getDynamicValueMap();
        ShGl_TestFactory.AccountDefaults accDef = new ShGl_TestFactory.AccountDefaults();
        accDef.getDynamicValueMap();
        ShGl_TestFactory.ContactDefaults conDef = new ShGl_TestFactory.ContactDefaults();
        conDef.getDynamicValueMap();
        ShGl_TestFactory.OpportunityDefaults oppDef = new ShGl_TestFactory.OpportunityDefaults();
        oppDef.getDynamicValueMap();
        ShGl_TestFactory.CaseDefaults caseDef = new ShGl_TestFactory.CaseDefaults();
        caseDef.getDynamicValueMap();
        caseDef.getFieldDefaults();
        caseDef.getFieldDefaultsMultipleRecords(1);
        ShGl_TestFactory.UserRoleDefaults userRoleDef = new ShGl_TestFactory.UserRoleDefaults();
        userRoleDef.getDynamicValueMap();
        ShGl_TestFactory.UserDefaults userDef = new ShGl_TestFactory.UserDefaults();
        userDef.getDynamicValueMap();
        ShGl_TestFactory.ServiceContractDefaults servConDef = new ShGl_TestFactory.ServiceContractDefaults();
        servConDef.getDynamicValueMap();
        servConDef.getFieldDefaults();
        ShGl_TestFactory.AssetDefaults assDef = new ShGl_TestFactory.AssetDefaults();
        assDef.getDynamicValueMap();
        ShGl_TestFactory.CCRDefaults ccrDef = new ShGl_TestFactory.CCRDefaults();
        ccrDef.getDynamicValueMap();
        ccrDef.getFieldDefaults();
        ccrDef.getFieldDefaultsMultipleRecords(1);
    }

}