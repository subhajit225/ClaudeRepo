@isTest
private class PatchManager_Test {
   public static Id DistRecTypeId = Schema.SObjectType.Partner_Onboarding_Request__c.getRecordTypeInfosByName().get('Distributor').getRecordTypeId();
   public static Id SDRecordTypeId = Schema.SObjectType.Partner_Onboarding_Request__c.getRecordTypeInfosByName().get('Service Delivery').getRecordTypeId();
   public static Id ResellerRecordTypeId = Schema.SObjectType.Partner_Onboarding_Request__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();

    public static testmethod void testassignDealRegCountry(){
        map<string,List<PatchManager__c>> patchMap=new map<string,List<PatchManager__c>>();
        List<PatchManager__c> patchList=new List<PatchManager__c>();
        patchList = ShGl_TestFactory.testMethod_createPatchManager(2);
        patchList[0].SMB_Owner__c=userInfo.getUserId();
        patchList[1].SMB_Owner__c=userInfo.getUserId();
        patchList[1].County__c='India';
        patchList[1].CountryGlobal__c = 'India';
        patchList[0].Zip_code__c = '53198';
        update patchList;
        patchMap.put('United States',patchList);
        //List<Deal_Registration__c> lstDR = ShGl_TestFactory.testMethod_createDealRegistration(1);
        List<Deal_Registration__c> lstDR= createDealRegistration(1);
        lstDR[0].Country__c='United States';
        lstDR[0].Segment_Revenue__c=1;
        update lstDR;
        PatchManager__c pmRec = PatchManager.assignDealReg(patchMap,lstDR[0]);
    }
    public static testmethod void testPostalCode(){
        map<string,List<PatchManager__c>> patchMap=new map<string,List<PatchManager__c>>();
        List<PatchManager__c> patchList=new List<PatchManager__c>();
        patchList = ShGl_TestFactory.testMethod_createPatchManager(2);
        patchList[0].SMB_Owner__c=userInfo.getUserId();
        patchList[1].SMB_Owner__c=userInfo.getUserId();
        patchList[1].County__c='India';
        patchList[1].CountryGlobal__c = 'India';
        patchList[0].Zip_code__c = '53198';
        update patchList;
        patchMap.put('53198',patchList);
        //List<Deal_Registration__c> lstDR = ShGl_TestFactory.testMethod_createDealRegistration(1);
        List<Deal_Registration__c> lstDR= createDealRegistration(1);
        lstDR[0].Country__c='United States';
        lstDR[0].Segment_Revenue__c=1;
        update lstDR;
        PatchManager__c pmRec = PatchManager.assignDealReg(patchMap,lstDR[0]);
    }
    
    
    public static testmethod void testassignDealRegCountryState(){
        map<string,List<PatchManager__c>> patchMap=new map<string,List<PatchManager__c>>();
        List<PatchManager__c> patchList=new List<PatchManager__c>();
        patchList = ShGl_TestFactory.testMethod_createPatchManager(2);
        patchList[0].SMB_Owner__c=userInfo.getUserId();
        patchList[1].SMB_Owner__c=userInfo.getUserId();
        patchList[1].County__c='India';
        patchList[1].CountryGlobal__c = 'India';
        patchList[0].Zip_code__c = '53198';
        update patchList;
        patchMap.put('United States/FL',patchList);
        //List<Deal_Registration__c> lstDR = ShGl_TestFactory.testMethod_createDealRegistration(1);
        List<Deal_Registration__c> lstDR= createDealRegistration(1);
        lstDR[0].Country__c='United States';
        lstDR[0].Segment_Revenue__c=1;
        lstDR[0].StateCode__c='FL';
        update lstDR;
        PatchManager__c pmRec = PatchManager.assignDealReg(patchMap,lstDR[0]);
    }
    
    
    public static testmethod void testassignAccount(){
        map<string,List<PatchManager__c>> patchMap=new map<string,List<PatchManager__c>>();
        List<PatchManager__c> patchList=new List<PatchManager__c>();
        Set<Id> accountIds = new Set<Id>();
        patchList = ShGl_TestFactory.testMethod_createPatchManager(2);
        patchList[0].SMB_Owner__c=userInfo.getUserId();
        patchList[0].Zip_code__c = '53198';
        update patchList;
        patchMap.put('United States',patchList);
        Account ac = ShGl_TestFactory.testMethod_PartnerAccount('test account');
        ac.BillingCountry = 'United States';
        update ac;
        PatchManager.assignAccount(patchMap,ac);  
        accountIds.add(ac.Id);
        //PatchManager.findOwnerFromAccount(accountIds);
    }
    public static testmethod void assignContact(){
        map<string,List<PatchManager__c>> patchMap=new map<string,List<PatchManager__c>>();
        List<PatchManager__c> patchList=new List<PatchManager__c>();
        patchList = ShGl_TestFactory.testMethod_createPatchManager(2);
        patchList[0].SMB_Owner__c=userInfo.getUserId();
        patchList[0].Zip_code__c = '53198';
        update patchList;
        patchMap.put('United States',patchList);
        Account ac = ShGl_TestFactory.testMethod_PartnerAccount('test account');
        ac.BillingCountry = 'United States';
        update ac;
        List<Contact> lstCn = ShGl_TestFactory.testMethod_PartnerContact(1,ac);
        lstCn[0].MailingCountry = 'United States';
        update lstCn;
        PatchManager.assignContact(patchMap,lstCn[0]); 
    }
    public static testmethod void assignLead(){
        map<string,List<PatchManager__c>> patchMap=new map<string,List<PatchManager__c>>();
        List<PatchManager__c> patchList=new List<PatchManager__c>();
        //insert Custom Setting
        ShGl_TestFactoryHelper.WorkflowTriggerBypass();  
        patchList = ShGl_TestFactory.testMethod_createPatchManager(2);
        patchList[0].SMB_Owner__c=userInfo.getUserId();
        patchList[0].Zip_code__c = '53198';
        update patchList;
        patchMap.put('United States',patchList);        

        List<Lead> lstLead = ShGl_TestFactory.testMethod_createLead(1);
        PatchManager.assignLead(patchMap,lstLead[0]);
        PatchManager.assignLead(patchMap,lstLead);
    }
    public static testmethod void  assignPartnerAccessRequest(){
        map<string,List<PatchManager__c>> patchMap=new map<string,List<PatchManager__c>>();
        List<PatchManager__c> patchList=new List<PatchManager__c>();
                patchList = ShGl_TestFactory.testMethod_createPatchManager(2);
        patchList[0].SMB_Owner__c=userInfo.getUserId();
        patchList[0].Zip_code__c = '53198';
        update patchList;
        patchMap.put('United States',patchList);
        List<Partner_Registration_Request__c> lstPRR = ShGl_TestFactory.testMethod_createPRRequest(1);
        PatchManager.assignPartnerAccessRequest(patchMap,lstPRR[0]);
    }
    public static testmethod void  testassignPartnerOnboarding(){
        map<string,List<PatchManager__c>> patchMap=new map<string,List<PatchManager__c>>();
        List<PatchManager__c> patchList=new List<PatchManager__c>();
        patchList = ShGl_TestFactory.testMethod_createPatchManager(2);
        patchList[0].SMB_Owner__c=userInfo.getUserId();
        patchList[0].Zip_code__c = '53198';
        update patchList;
        patchMap.put('United States',patchList);
        Account acc1 = TestDataFactory.getAccount();
            acc1.name = 'Test Company';
            acc1.Type = 'OEM';
            acc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            acc1.OEM_Subtype__c = 'Revshare';
        insert acc1;
        List<Partner_Onboarding_Request__c> lstPOR = ShGl_TestFactory.testMethod_PartnerOnBoardingWithoutInsert(1); 
        lstPOR[0].Country__c='United States';
        lstPOR[0].Account__c = acc1.Id;
        insert lstPOR;
        PatchManager.assignPartner(patchMap,lstPOR[0]);
    }
    
    public static testmethod void  testassignPartnerMsp(){
        map<string,List<PatchManager__c>> patchMap=new map<string,List<PatchManager__c>>();
        List<PatchManager__c> patchList=new List<PatchManager__c>();
        patchList = ShGl_TestFactory.testMethod_createPatchManager(2);
        patchList[0].SMB_Owner__c=userInfo.getUserId();
        patchList[0].Zip_code__c = '53198';
        update patchList;
        patchMap.put('United States',patchList);
        Account acc1 = TestDataFactory.getAccount();
            acc1.name = 'Test Company';
            acc1.Type = 'OEM';
            acc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            acc1.OEM_Subtype__c = 'Revshare';
        insert acc1;
        List<Partner_Onboarding_Request__c> lstPOR = ShGl_TestFactory.testMethod_PartnerOnBoardingWithoutInsert(1); 
        lstPOR[0].Country__c='United States';
        lstPOR[0].recordtypeId = DistRecTypeId;
        lstPOR[0].PartnerType__c='Distributor';
        lstPOR[0].Account__c = acc1.Id;
        insert lstPOR;
        PatchManager.assignPartner(patchMap,lstPOR[0]);
    }
    
    
    public static testmethod void testcleanPostalCode(){
        PatchManager.cleanPostalCode('576214-456');
    }
    public static testmethod void  reAssignContactObject(){
                map<string,List<PatchManager__c>> patchMap=new map<string,List<PatchManager__c>>();
        List<PatchManager__c> patchList=new List<PatchManager__c>();
        patchList = ShGl_TestFactory.testMethod_createPatchManager(2);
        patchList[0].SMB_Owner__c=userInfo.getUserId();
        patchList[0].Zip_code__c = '53198';
        update patchList;
        patchMap.put('United States',patchList);
        Account ac = ShGl_TestFactory.testMethod_PartnerAccount('test account');
        ac.BillingCountry = 'United States';
        update ac;
        List<Contact> lstCn = ShGl_TestFactory.testMethod_PartnerContact(1,ac);
        lstCn[0].MailingCountry = 'United States';
        update lstCn;
        PatchManager.reAssignObject(lstCn,'Contact');        
    }
    
    public static testmethod void  reAssignDealObject(){
                map<string,List<PatchManager__c>> patchMap=new map<string,List<PatchManager__c>>();
        List<PatchManager__c> patchList=new List<PatchManager__c>();
        patchList = ShGl_TestFactory.testMethod_createPatchManager(2);
        patchList[0].SMB_Owner__c=userInfo.getUserId();
        patchList[1].SMB_Owner__c=userInfo.getUserId();
        patchList[1].County__c='India';
        patchList[1].CountryGlobal__c = 'India';
        patchList[0].Zip_code__c = '53198';
        update patchList;
        patchMap.put('first',patchList);
        //List<Deal_Registration__c> lstDR = ShGl_TestFactory.testMethod_createDealRegistration(1);
        List<Deal_Registration__c> lstDR= createDealRegistration(1);
        lstDR[0].Country__c='United States';
        lstDR[0].Segment_Revenue__c=1;
        lstDR[0].StateCode__c='FL';
        update lstDR;
       // PatchManager.assignDealReg(patchMap,lstDR[0]);
        PatchManager.reAssignObject(lstDR,'DEAL_REG');
    }
    public static testmethod void  testaddPatchMap(){
                map<string,List<PatchManager__c>> patchMap=new map<string,List<PatchManager__c>>();
        List<PatchManager__c> patchList=new List<PatchManager__c>();
        patchList = ShGl_TestFactory.testMethod_createPatchManager(2);
        patchList[0].SMB_Owner__c=userInfo.getUserId();
        patchList[1].SMB_Owner__c=userInfo.getUserId();
        patchList[1].County__c='India';
        patchList[1].CountryGlobal__c = 'India';
        patchList[0].Zip_code__c = '53198';
        update patchList;
        patchMap.put('United States',patchList);
        PatchManager.addPatchMap('United States',patchList[0],patchMap);
    }
    public static testmethod void testgetPatchMap(){
        //List<Deal_Registration__c> dealList = ShGl_TestFactory.testMethod_createDealRegistration(1);
        List<Deal_Registration__c> dealList= createDealRegistration(1);
        dealList[0].Country__c='United States';
        dealList[0].Segment_Revenue__c=1;
        dealList[0].StateCode__c='FL';
        update dealList;
        PatchManager.getPatchMap(dealList,'Deal_Registration__c');
    }
    public static testmethod void testgetPatchMapAcc(){
        List<Account> accList = new List<Account>();
        Account acc1 = TestDataFactory.getAccount();
            acc1.name = 'Test Company';
            acc1.Type = 'OEM';
            acc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            acc1.OEM_Subtype__c = 'Revshare';
        accList.add(acc1);
        insert accList;
        PatchManager.getPatchMap(accList,'Account');
    }
    public static testmethod void testPartneOnboarding(){
        List<Partner_Onboarding_Request__c> lstPOR = ShGl_TestFactory.testMethod_PartnerOnBoardingWithoutInsert(1); 
        lstPOR[0].Country__c='United States';
        lstPOR[0].PartnerType__c='Distributor';
        PatchManager.getPatchMap(lstPOR,'Partner_Onboarding_Request__c');
    }
    public static testmethod void testPartnerAccess(){
        List<Partner_Registration_Request__c> lstPRR = ShGl_TestFactory.testMethod_createPRRequest(1);
        PatchManager.getPatchMap(lstPRR,'Partner_Registration_Request__c');
    }
    
    public static testmethod void testreAssignObject(){
        //List<Deal_Registration__c> dealList = ShGl_TestFactory.testMethod_createDealRegistration(1);
        List<Deal_Registration__c> dealList= createDealRegistration(1);
        dealList[0].Country__c='United States';
        dealList[0].Segment_Revenue__c=1;
        dealList[0].StateCode__c='FL';
        update dealList;
        PatchManager.reAssignObject(dealList,'Deal_Registration__c');
    }
    public static testmethod void reAssignLeadObject(){
        ShGl_TestFactoryHelper.WorkflowTriggerBypass();
        List<Lead> LeadList = ShGl_TestFactory.testMethod_createLead(1);
        PatchManager.reAssignObject(LeadList,'Lead');
    }   
    public static testmethod void assignLead2(){
        map<string,List<PatchManager__c>> patchMap=new map<string,List<PatchManager__c>>();
        List<PatchManager__c> patchList=new List<PatchManager__c>();
        //insert Custom Setting
        ShGl_TestFactoryHelper.WorkflowTriggerBypass();  
        patchList = ShGl_TestFactory.testMethod_createPatchManager(2);
        patchList[0].SMB_Owner__c=userInfo.getUserId();
        patchList[0].Zip_code__c = '53198';
        update patchList;
        patchMap.put('Industry/United States/US/589526',patchList);
        List<Lead> lstLead = ShGl_TestFactory.testMethod_createLead(1);
        lstLead[0].Industry = 'Industry';
        lstLead[0].Country = 'United States';
        lstLead[0].StateCode = 'US';
        lstLead[0].postalCode = '589526';
        PatchManager.assignLead(patchMap,lstLead[0]);
        PatchManager.assignLead(patchMap,lstLead);
    }
    public static testmethod void assignLead3(){
        map<string,List<PatchManager__c>> patchMap=new map<string,List<PatchManager__c>>();
        List<PatchManager__c> patchList=new List<PatchManager__c>();
        //insert Custom Setting
        ShGl_TestFactoryHelper.WorkflowTriggerBypass();
        patchList = ShGl_TestFactory.testMethod_createPatchManager(2);
        patchList[0].SMB_Owner__c=userInfo.getUserId();
        patchList[0].Zip_code__c = '53198';
        update patchList;
        patchMap.put('United States/US/589526',patchList);
        List<Lead> lstLead = ShGl_TestFactory.testMethod_createLead(1);
        lstLead[0].Country = 'United States';
        lstLead[0].StateCode = 'US';
        lstLead[0].postalCode = '589526';
        PatchManager.assignLead(patchMap,lstLead[0]);
        PatchManager.assignLead(patchMap,lstLead);
       
    }
    public static void createtestdataAllianceDealReg(){
        WorkflowTriggerBypass__c wtb = new WorkflowTriggerBypass__c(Name='cnsFirstAttemptUpdateLeadStatus',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb1 = new WorkflowTriggerBypass__c(Name='CreateSDRLedMeetingTask',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb2 = new WorkflowTriggerBypass__c(Name='leadReassignOnBusinessUnitChange',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb3 = new WorkflowTriggerBypass__c(Name='updateLastOwnershipUpdateDate',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb4 = new WorkflowTriggerBypass__c(Name='updateOpportunitySource',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb5 = new WorkflowTriggerBypass__c(Name='salesOperationInvokePatchManager',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb6 = new WorkflowTriggerBypass__c(Name='salesOperationsAssignAccountSIC',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb7 = new WorkflowTriggerBypass__c(Name='salesOperationsSetEUResident',ByPassTrigger__c=false);
        insert new List<WorkflowTriggerBypass__c>{wtb,wtb1,wtb2,wtb3,wtb4,wtb5,wtb6,wtb7};
        //create an account
        Account testAccount = (Account)ShGl_TestFactory.createSObject(new Account(), null);
        testAccount.Name = 'Test SDR Account';
        Id customerRecordTypeId = Schema.sObjectType.Account.getRecordTypeInfosByName().get('Customer/Prospect').getRecordTypeId();
        testAccount.RecordtypeId = customerRecordTypeId;
        //insert testAccount;

        //create accounts 
        List<Account> testAccounts = (List<Account>)ShGl_TestFactory.createSObjectList(new Account(), 3, null);
        testAccounts.add(testAccount);
        insert testAccounts;
        for(Account acc : testAccounts) {
            acc.OwnerId = UserInfo.getUserId();
        }
        update testAccounts;

        //update account ownership
        //testAccount.OwnerId = UserInfo.getUserId();
        //update testAccount;
        //insert test territory
        UserTerritory2Association territory2obj = [SELECT Id, Territory2Id, UserId FROM UserTerritory2Association WHERE RoleInTerritory2 = 'SDR' AND Territory2.Territory2Model.State = 'Active' LIMIT 1];
        ObjectTerritory2Association testAssociatn = new ObjectTerritory2Association(ObjectId = testAccount.Id,Territory2Id = territory2obj.Territory2Id, AssociationCause = 'Territory2Manual');
        insert testAssociatn;
        //create contacts on the account
        Contact[] testContacts = (Contact[])ShGl_TestFactory.createSObjectList(new Contact(), 2, null);
        testContacts[0].Email = 'test1@testMatch.com';
        testContacts[1].Email = 'test2@testMatch.com';
        testContacts[0].AccountId = testContacts[1].AccountId = testAccount.Id;
        insert testContacts;
        //create a lead
        PatchManager__c ptch = new PatchManager__c();
        ptch.Country__c = 'US';
        insert ptch;
        
        //Generate Lead
        Lead led = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
        led.firstName = 'Test Lead FN';
        led.lastName = 'Te	st Lead LN';
        led.Status = 'Open';
        led.CountryCode = 'US';
        led.email = 'testEmail@test123.com';
        insert led;


        //create Alliance Deal Registrations
        List<Alliance_Deal_Registration__c> dealReg = (List<Alliance_Deal_Registration__c>)ShGl_TestFactory.createSObjectList(new Alliance_Deal_Registration__c(), 2, null);
        dealReg[0].Zip_code__c = dealReg[1].Zip_code__c = '53198';
        dealReg[0].BDM__c = dealReg[1].BDM__c = userInfo.getUserId();
        dealReg[0].SDR__c = dealReg[1].SDR__c = userInfo.getUserId();
        insert dealReg;
    }
     public static testmethod void allianceDealReg(){
        PatchManager_Test.createtestdataAllianceDealReg();
        Alliance_Deal_Registration__c dealReg = [SELECT Id FROM Alliance_Deal_Registration__c LIMIT 1];
        dealReg.Match_Status__c = 'Net New Lead';
        Test.startTest();
            update dealReg;
        Test.stopTest(); 
       
    }
    
    public static List<Deal_Registration__c> createDealRegistration(integer noOfRec){
        User sysuser2  = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'lastNameDRTest',
            Email = 'uniqueName1233' +'@rubrik.com',
            Username = 'uniqueName1233' +'@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'uniqueName'.substring(0,5),
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Start_Date__c=System.Today().adddays(-30)
        );
        insert sysuser2;
        
        Account acc = TestDataFactory.getAccount();
        acc.name = 'Test New Account Partner Ninja';
        acc.Type = 'Reseller';
        acc.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        acc.Focused_Partner__c = true;
        acc.OwnerId = sysuser2.Id;
        insert acc;
        
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        List<Deal_Registration__c> lstdrRec = new List<Deal_Registration__c>();
        CountryWithCode__c setting = new CountryWithCode__c();
        setting.Name = 'United States';
        setting.Code__c = 'US';
        insert setting;
        for(Integer i=0; i<noOfRec; i++){
            Deal_Registration__c dr=new Deal_Registration__c();
            dr.FirstName__c='fn'+noOfRec;
            dr.LastName__c='ln1';
            dr.Deal_Registration_Status__c='Submitted';
            dr.Deal_Reg_Submitted_Date__c=system.today();
            dr.Country__c = 'United States';
            dr.Deal_Registration_Type__c='Partner Sourced New Logo (PSNL)';
            lstdrRec.add(dr);
        }
        insert lstdrRec;
        return lstdrRec;
    }
}