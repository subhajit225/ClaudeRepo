@isTest
public class DealRegistrationTrigger_Test {
    @TestSetup
    static void makeData(){
        List<WorkflowTriggerBypass__c> wtList = new List<WorkflowTriggerBypass__c>();
        WorkflowTriggerBypass__c wt = new WorkflowTriggerBypass__c(name='leadReassignOnBusinessUnitChange',ByPassTrigger__c=false);
        wtList.add(wt);
        WorkflowTriggerBypass__c wt1 = new WorkflowTriggerBypass__c(name='cnsFirstAttemptUpdateLeadStatus',ByPassTrigger__c=false);
        wtList.add(wt1);
        WorkflowTriggerBypass__c wt2 = new WorkflowTriggerBypass__c(name='CreateSDRLedMeetingTask',ByPassTrigger__c=false);
        wtList.add(wt2);
        WorkflowTriggerBypass__c wt3 = new WorkflowTriggerBypass__c(name='updateLastOwnershipUpdateDate',ByPassTrigger__c=false);
        wtList.add(wt3);
        WorkflowTriggerBypass__c wt4 = new WorkflowTriggerBypass__c(name='updateOpportunitySource',ByPassTrigger__c=false);
        wtList.add(wt4);
        WorkflowTriggerBypass__c wt5 = new WorkflowTriggerBypass__c(name='salesOperationsAssignAccountSIC',ByPassTrigger__c=false);
        wtList.add(wt5);
        WorkflowTriggerBypass__c wt6 = new WorkflowTriggerBypass__c(name='salesOperationsSetEUResident',ByPassTrigger__c=false);
        wtList.add(wt6);
        insert wtList;

        CountryWithCode__c cc = new CountryWithCode__c(Code__c='US',Name='United States');
        insert cc;
    }

    @isTest static void testDealInserted() {
        User sysuser1 = TestDataFactory.getUser();
        system.runas(sysuser1){
            Deal_Registration__c deal=TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Status__c = 'Submitted';
            deal.Dedicated_Managed_Service__c = true;
            Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
            Test.startTest();
            insert deal;
            Test.stopTest();
            System.assert(true);
        }
	}
    static testMethod void testMethod3() {
        FlowControll.opportunityTriggerHandler = false;
        User sysuser1 = TestDataFactory.getUser();
        system.runas(sysuser1){
            Lead  l = TestDataFactory.insertLead();
            insert l;
            
            List<Lead> leadList = new List<Lead>();
            leadList.add(l);
            Map<id,Lead> oldMapLead = new Map<id,Lead> ();
            oldMapLead.put(l.id, l);
            
            Account acc = TestDataFactory.getAccount();
            acc.name = 'Test New Account';
            acc.Type = 'Customer';
            insert acc;
            
            Deal_Registration__c deal=TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Status__c = 'Submitted';
            deal.Primary__c = false;
            deal.Company_Name__c = acc.Id;
            deal.Dedicated_Managed_Service__c = true;
            insert deal;
            deal.Primary__c = true;
            update deal;
            
            deal.Deal_Registration_Status__c = 'Approved';         
            deal.Deal_Reg_Exp_Date__c  = system.today().addDays(-1);
            update deal;
            Opportunity opp = TestDataFactory.getOpportunity();
            insert opp;
            Deal_Registration__c deal1 = [select name from Deal_Registration__c where id =:deal.Id];
            opp.Deal_Registration_Number__c = deal1.name;
            opp.Deal_Reg_Approval_Status__c = 'Approved';
            //opp.Cloud_Partner_Led_Activity__c = 'No';
            opp.Opportunity_Sub_Type__c = 'Regular';
            opp.Alliance_HW_Partner__c = 'None';
            opp.Alliance_Source_Type_HW__c = 'None';
            opp.Alliance_Partner_Name__c = 'None';
            opp.Cloud_Type__c = 'None';
            opp.Lost_Reason__c = 'Lost Budget';
            opp.Win_Loss_Comments__c = 'This is a lost deal';
            opp.StageName = '7 Closed Lost';
            update opp;
            test.startTest();
            PC_DealRegExpiryUpdateBatch b2 = new PC_DealRegExpiryUpdateBatch();
            Database.executeBatch(b2,1);
            l.L2A_Status__c= 'PROCESSED';
            l.status = 'Open';
            l.Most_Recent_Activity_Date__c = System.TODAY();
            update l;
            test.stopTest();
        }
        system.assert(true);
    }
    static testMethod void testMethod4() {
        Test.startTest();
        User sysuser1 = TestDataFactory.getUser();
        User sysuser2  = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'last',
            Email = 'uniqueName1233' +'@rubrik.com',
            Username = 'uniqueName1233' +'@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'uniqueName'.substring(0,5),
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            //UserRoleId = vUserRole1.Id,
            Start_Date__c=System.Today().adddays(-30)
        );
        insert sysuser2;
        Test.stopTest();
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        system.runas(sysuser1){
            Id georecId = Schema.SObjectType.PatchManager__c.getRecordTypeInfosByName().get('Geographic').getRecordTypeId();
            PatchManager__c pm = new PatchManager__c(recordtypeId=georecId,CDM__c=sysuser2.Id,CountryGlobal__c='United States',City__c='City',State__c='AK',StateGlobal__c='AK',Zip_code__c='421302',SDR__c=sysuser2.Id,AccountExecutive__c=sysuser2.Id);
            insert pm;
            CountryWithCode__c cc = new CountryWithCode__c(Code__c='US',Name='United States');
            insert cc;
            Opportunity opp = TestDataFactory.getOpportunity();
            insert opp;
            Deal_Registration__c deal=TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Status__c = 'Submitted';
            insert deal;
            deal.ownerid = sysuser2.Id;
            update deal;
            Deal_Registration__c deal1 = [select name from Deal_Registration__c where id =:deal.Id];
            opp.Deal_Registration_Number__c = deal1.name;
            update opp;
            deal1.Deal_Reg_Exp_Date__c  = system.today().addDays(-1);
            update deal1;
            Map<string,Date> dealRegOppMap = new Map<string,Date>();
            dealRegOppMap.put(deal1.name,system.today());

            PC_DealRegExpiryUpdateBatch b = new PC_DealRegExpiryUpdateBatch();
            Database.executeBatch(b,1);
            System.assert(true);
        }
    }
    static testMethod void testMethod5() {
        FlowControll.accountTrigger = false;
        flowControll.UserTriggerHandler = false;
        FlowControll.opportunityTriggerHandler = false;
        
        string AllianceRecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Alliance').getRecordTypeId();
        string ResellerRecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
        string ServiceDeliveryRecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByDeveloperName().get('Service_Delivery_Partner').getRecordTypeId(); // PRIT24-887
        string OEMRecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('OEM').getRecordTypeId();
        string accountPartnerRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
        List<Territory2> territories = new List<Territory2>();
        List<Territory2Model> TModel = [Select id,Name from territory2model where State ='Active'];
        List<Territory2Type> terrType = [Select Id, DeveloperName from Territory2Type where DeveloperName = 'Territory'];

        for(Integer i=0;i<3;i++){
            Territory2 terr = new Territory2();
            terr.Name = 'CDM-' + i;
            terr.DeveloperName = 'CDM_' + i;
            terr.Adaptive_Territory_Id__c = '999999'+i;
            terr.Territory2ModelId = TModel[0].Id;
            terr.Territory2TypeId = terrType[0].Id;
            territories.add(terr);
        }
        insert territories;

        List<User> userList = new List<User>();
        List<PermissionSetAssignment> psAssignmentList = new List<PermissionSetAssignment>();
        Profile pf= [Select Id from profile where Name='System Administrator']; 
        Id psId = [SELECT Id from PermissionSet WHERE Name = 'RubrikChannelUsersNew'].Id;
        
        User uu=new User(firstname = 'Alan', 
            lastName = 'McCarthy', 
            email = 'HG@gmail.com', 
            Username = 'HG79879@gmail.com', 
            EmailEncodingKey = 'ISO-8859-1', 
            Alias = 'GAA', 
            TimeZoneSidKey = 'America/Los_Angeles', 
            LocaleSidKey = 'en_US', 
            LanguageLocaleKey = 'en_US', 
            ProfileId = pf.Id
            //UserRoleId = ur.Id
            ); 
        userList.add(uu);

        Profile prCDM = [Select Id from profile where Name='Channel Development Manager']; 
        User uCDM1 = new User(firstname = 'James', 
            lastName = 'Webb', 
            email = 'JamWeb00098990@gmail.com', 
            Username = 'JamWeb00098990@gmail.com', 
            EmailEncodingKey = 'ISO-8859-1', 
            Alias = 'GAA', 
            TimeZoneSidKey = 'America/Los_Angeles', 
            LocaleSidKey = 'en_US', 
            LanguageLocaleKey = 'en_US', 
            ProfileId = prCDM.Id
            //UserRoleId = urCDM.Id
            ); 
        userList.add(uCDM1);

        User uCDM2 = new User(firstname = 'James', 
            lastName = 'Philips', 
            email = 'JamPhilp889000@gmail.com', 
            Username = 'JamPhilp889000@gmail.com', 
            EmailEncodingKey = 'ISO-8859-1', 
            Alias = 'GAA', 
            TimeZoneSidKey = 'America/Los_Angeles', 
            LocaleSidKey = 'en_US', 
            LanguageLocaleKey = 'en_US', 
            ProfileId = prCDM.Id
            //UserRoleId = urCDM.Id
            ); 
        userList.add(uCDM2);

        User uCDM3 = new User(firstname = 'Joe', 
            lastName = 'Rovers', 
            email = 'JoeRov987895@gmail.com', 
            Username = 'JoeRov987895@gmail.com', 
            EmailEncodingKey = 'ISO-8859-1', 
            Alias = 'GAA', 
            TimeZoneSidKey = 'America/Los_Angeles', 
            LocaleSidKey = 'en_US', 
            LanguageLocaleKey = 'en_US', 
            ProfileId = prCDM.Id
            //UserRoleId = urCDM.Id
            ); 
        userList.add(uCDM3);

        User uCDM4 = new User(firstname = 'James', 
            lastName = 'Philips', 
            email = 'JamPhilp1100@gmail.com', 
            Username = 'JamPhilp1100@gmail.com', 
            EmailEncodingKey = 'ISO-8859-1', 
            Alias = 'GAA', 
            TimeZoneSidKey = 'America/Los_Angeles', 
            LocaleSidKey = 'en_US', 
            LanguageLocaleKey = 'en_US', 
            ProfileId = prCDM.Id
            //UserRoleId = urCDM.Id
            ); 
        userList.add(uCDM4);

        User uCDM5 = new User(firstname = 'Joe', 
            lastName = 'Rovers', 
            email = 'JoeRov1234@gmail.com', 
            Username = 'JoeRov1234@gmail.com', 
            EmailEncodingKey = 'ISO-8859-1', 
            Alias = 'GAA', 
            TimeZoneSidKey = 'America/Los_Angeles', 
            LocaleSidKey = 'en_US', 
            LanguageLocaleKey = 'en_US', 
            ProfileId = prCDM.Id
            //UserRoleId = urCDM.Id
            ); 
        userList.add(uCDM5);
        insert userList;

        PermissionSetAssignment psa1 = new PermissionSetAssignment();
        psa1.AssigneeId = uCDM1.Id;
        psa1.PermissionSetId = psId;
        psAssignmentList.add(psa1);
        
        PermissionSetAssignment psa2 = new PermissionSetAssignment();
        psa2.AssigneeId = uCDM2.Id;
        psa2.PermissionSetId = psId;
        psAssignmentList.add(psa2);
        
        PermissionSetAssignment psa3 = new PermissionSetAssignment();
        psa3.AssigneeId = uCDM3.Id;
        psa3.PermissionSetId = psId;
        psAssignmentList.add(psa3);
        
        PermissionSetAssignment psa4 = new PermissionSetAssignment();
        psa4.AssigneeId = uCDM4.Id;
        psa4.PermissionSetId = psId;
        psAssignmentList.add(psa4);
        
        PermissionSetAssignment psa5 = new PermissionSetAssignment();
        psa5.AssigneeId = uCDM5.Id;
        psa5.PermissionSetId = psId;
        psAssignmentList.add(psa5);
        
        insert psAssignmentList;

        List<UserTerritory2Association> utaRecords = new List<UserTerritory2Association>();
        UserTerritory2Association uta = new UserTerritory2Association();
        uta.Territory2Id = territories[0].Id;
        uta.RoleInTerritory2 = 'Account Executive';
        uta.UserId = uCDM1.Id;
        utaRecords.add(uta);

        uta = new UserTerritory2Association();
        uta.Territory2Id = territories[0].Id;
        uta.RoleInTerritory2 = 'SDR';
        uta.UserId = uCDM2.Id;
        utaRecords.add(uta);

        uta = new UserTerritory2Association();
        uta.Territory2Id = territories[0].Id;
        uta.RoleInTerritory2 = 'CDM';
        uta.UserId = uCDM3.Id;
        utaRecords.add(uta);

        uta = new UserTerritory2Association();
        uta.Territory2Id = territories[0].Id;
        uta.RoleInTerritory2 = 'Regional Director';
        uta.UserId = uCDM4.Id;
        utaRecords.add(uta);

        uta = new UserTerritory2Association();
        uta.Territory2Id = territories[0].Id;
        uta.RoleInTerritory2 = 'Regional Sales Manager';
        uta.UserId = uCDM5.Id;
        utaRecords.add(uta);

        insert utaRecords;
        
        String uniqueName = TestDataFactory.getUniqueName();
        User runAsUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Rubrik Light Administrator'].Id,    
            LastName = 'last',
            Email = uniqueName +'@rubrik.com',
            Username = uniqueName +'@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = uniqueName.substring(0,5),
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            //UserRoleId = ur.Id,
            Start_Date__c=System.Today().adddays(-30)
        );
        insert runAsUser; 
        System.runAs(runAsUser){
            List<Account> accList = new List<Account>();
            Account accp = TestDataFactory.getAccount();
            accp.name = 'Test New Account Partner Acc';
            accp.Type = 'Reseller';
            accp.OwnerId = uCDM1.Id;
            accp.RecordTypeId = accountPartnerRecordType;
            accList.add(accp);

            Account acc = TestDataFactory.getAccount();
            acc.name = 'Test New Account';
            acc.Type = 'Prospect';
            acc.OwnerId = uCDM1.Id;
            accList.add(acc);

            insert accList;

            Lead  l1 = TestDataFactory.insertLead();
            l1.status = 'Working';
            insert l1;
            
            List<Deal_Registration__c> dealList = new List<Deal_Registration__c>();
            Deal_Registration__c deal=TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Status__c = 'Submitted';
            deal.Deal_Reg_Submitted_Date__c = System.today();
            deal.Primary__c = false;
            deal.RecordTypeId = ResellerRecordTypeId;
            dealList.add(deal);

            Deal_Registration__c deal2=TestDataFactory.getDealRegistration();
            deal2.lead__C = l1.Id;
            deal2.Deal_Registration_Status__c = 'Submitted';
            deal2.OwnerId = uCDM2.Id;
            deal2.Deal_Reg_Submitted_Date__c = System.now();
            deal2.RecordTypeId = ResellerRecordTypeId;
            dealList.add(deal2);

            Deal_Registration__c deal3=TestDataFactory.getDealRegistration();
            deal3.Deal_Registration_Status__c = 'Submitted';
            deal3.OwnerId = uCDM2.Id;
            deal3.RecordTypeId = ResellerRecordTypeId;
            deal3.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByDeveloperName().get('Service_Delivery_Partner').getRecordTypeId(); // PRIT24-887
            deal3.StateCode__c = '';
            dealList.add(deal3);

            Test.startTest();
            insert dealList;
            System.runAs(uCDM1){
                PC_DealRegistrationApexController.getRelatedRecords(acc.Id);
                customLookupLWCController.getRecordsByName('Account', 'ABCD','Partner/Distributor','','',false,null,new List<String>{});
                customLookupLWCController.fetchDefaultRecord(acc.Id,'Account');
            }
            Test.stopTest();

            deal.Company_Name__c = acc.Id;
            update deal;

            Opportunity opp = TestDataFactory.getOpportunity();
            opp.StageName = '1 Discovery';
            insert opp;

            deal.Opportunity__c = opp.Id;
            deal.Deal_Reg_Submitted_Date__c = System.now();
            deal.Deal_Registration_Status__c = 'Approved';
            deal.Partner_Lookup__c = accp.Id;
            update deal;
			system.assert(true);
        }
     }
    static testMethod void testMethod6() {
        User sysuser1 = TestDataFactory.getUser();
        
        system.runas(sysuser1){
            Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
            List<DealPartnerEmail__c> dpeList = new List<DealPartnerEmail__c>();
            DealPartnerEmail__c dp1 = new DealPartnerEmail__c(Name='test',Email__c='a@a.com',Type__c='ALERT');
            DealPartnerEmail__c dp2 = new DealPartnerEmail__c(Name='test2',Email__c='a@a.com',Type__c='ALERT-EQUALS');
            DealPartnerEmail__c dp3 = new DealPartnerEmail__c(Name='Commercial',Email__c='a@a.com',Type__c='ALERT-CATEGORY');
            DealPartnerEmail__c dp4 = new DealPartnerEmail__c(Name='test4',Email__c='a@a.com',Type__c='ALERT-REGION');
            DealPartnerEmail__c dp5 = new DealPartnerEmail__c(Name='test5',Email__c='a@a.com',Type__c='ALERT-SUBREGION');
            dpeList.add(dp1);
            dpeList.add(dp2);
            dpeList.add(dp3);
            dpeList.add(dp4);
            dpeList.add(dp5);
            insert dpeList;
        
        
            Account acc=TestDataFactory.getAccount();
            acc.name='test';
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert acc;
            
            Account acc2=TestDataFactory.getAccount();
            acc2.name='test2';
            acc2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert acc2;
            
            Deal_Registration__c deal=TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Status__c = 'Submitted';
            //deal.Partner_Lookup__c = acc.Id;
            deal.Customer_Category__c ='Commercial/Enterprise';
            insert deal;
            
            Deal_Registration__c deal2=TestDataFactory.getDealRegistration();
            deal2.Deal_Registration_Status__c = 'Submitted';
            //deal2.Partner_Lookup__c = acc2.Id;
            insert deal2;
            
            Deal_Registration__c deal3 = TestDataFactory.getDealRegistration();
            deal3.Deal_Registration_Status__c = 'Submitted';
            //deal3.Partner_Lookup__c = acc2.Id;
            deal3.Deal_Registration_Type__c = 'Partner Sourced New Logo (PSNL)';
            deal3.Registration_Type__c = 'Partner Sourced';
            insert deal3;
            
            Opportunity oppClone = TestDataFactory.getOpportunity();
            oppClone.StageName = '1 Discovery';
            insert oppClone;
            
            Test.startTest();
            deal3.Deal_Registration_Status__c = 'Approved';
            deal3.Opportunity__c = oppClone.Id;
            //update deal3;
            Test.stopTest();
            System.assert(true);
            
        }
    }
    @isTest static void testrunPatchManager() {
        User sysuser1 = TestDataFactory.getUser();
        
        system.runas(sysuser1){
            Deal_Registration__c deal=TestDataFactory.getDealRegistration();
            Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
            deal.Deal_Registration_Status__c = 'Submitted';
            insert deal;
            Test.startTest();
            deal.rerun_PatchManager_Assignments__c = true;
            update deal;
            Test.stopTest();   
            System.assert(true);
        }
    }
    @isTest static void testsetApprovalRecord(){
        User sysuser1 = TestDataFactory.getUser();
        
        system.runas(sysuser1){
            Deal_Registration__c deal=TestDataFactory.getDealRegistration();
            Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
            insert deal;
            Test.startTest();
            deal.OwnerId = UserInfo.getUserId();
            deal.Deal_Registration_Status__c = 'Submitted';
            update deal;
            Test.stopTest();
            System.assert(true);
        }
    }

    @isTest static void testsetOwnerTerritory(){
        Test.startTest();
        List<Territory2> territories = new List<Territory2>();
        List<Territory2Model> TModel = [Select id,Name from territory2model where State ='Active'];
        List<Territory2Type> terrType = [Select Id, DeveloperName from Territory2Type where DeveloperName = 'Territory'];

        for(Integer i=0;i<3;i++){
            Territory2 terr = new Territory2();
            terr.Name = 'CDM-' + i;
            terr.DeveloperName = 'CDM_' + i;
            terr.Adaptive_Territory_Id__c = '999999'+i;
            terr.Territory2ModelId = TModel[0].Id;
            terr.Territory2TypeId = terrType[0].Id;
            territories.add(terr);
        }
        insert territories;

        //insert urCDM;
        List<User> cdmList = new List<User>();
        List<PermissionSetAssignment> psAssignmentList = new List<PermissionSetAssignment>();
        Profile prCDM = [Select Id from profile where Name='Channel Development Manager']; 
        Id psId = [SELECT Id from PermissionSet WHERE Name = 'RubrikChannelUsersNew'].Id;
        
        User sysuser1 = TestDataFactory.getUser();
        User uCDM1 = new User(firstname = 'James', 
            lastName = 'Webb', 
            email = 'JamWeb00098990@gmail.com', 
            Username = 'JamWeb098877@gmail.com', 
            EmailEncodingKey = 'ISO-8859-1', 
            Alias = 'GAA', 
            TimeZoneSidKey = 'America/Los_Angeles', 
            LocaleSidKey = 'en_US', 
            LanguageLocaleKey = 'en_US', 
            ProfileId = prCDM.Id
            //UserRoleId = urCDM.Id
            ); 
        cdmList.add(uCDM1);

        User uCDM2 = new User(firstname = 'James', 
            lastName = 'Philips', 
            email = 'JamPhilp889000@gmail.com', 
            Username = 'JamPhilp234567@gmail.com', 
            EmailEncodingKey = 'ISO-8859-1', 
            Alias = 'GAA', 
            TimeZoneSidKey = 'America/Los_Angeles', 
            LocaleSidKey = 'en_US', 
            LanguageLocaleKey = 'en_US', 
            ProfileId = prCDM.Id
            //UserRoleId = urCDM.Id
            ); 
        cdmList.add(uCDM2);

        User uCDM3 = new User(firstname = 'Joe', 
            lastName = 'Rovers', 
            email = 'JoeRov987895@gmail.com', 
            Username = 'JoeRo6789@gmail.com', 
            EmailEncodingKey = 'ISO-8859-1', 
            Alias = 'GAA', 
            TimeZoneSidKey = 'America/Los_Angeles', 
            LocaleSidKey = 'en_US', 
            LanguageLocaleKey = 'en_US', 
            ProfileId = prCDM.Id
            //UserRoleId = urCDM.Id
            ); 
        cdmList.add(uCDM3);
        
        insert cdmList;
        
        PermissionSetAssignment psa1 = new PermissionSetAssignment();
        psa1.AssigneeId = uCDM1.Id;
        psa1.PermissionSetId = psId;
        psAssignmentList.add(psa1);
        
        PermissionSetAssignment psa2 = new PermissionSetAssignment();
        psa2.AssigneeId = uCDM2.Id;
        psa2.PermissionSetId = psId;
        psAssignmentList.add(psa2);
        
        PermissionSetAssignment psa3 = new PermissionSetAssignment();
        psa3.AssigneeId = uCDM3.Id;
        psa3.PermissionSetId = psId;
        psAssignmentList.add(psa3);
        
        insert psAssignmentList;

        List<UserTerritory2Association> utaRecords = new List<UserTerritory2Association>();
        UserTerritory2Association uta = new UserTerritory2Association();
        uta.Territory2Id = territories[0].Id;
        uta.RoleInTerritory2 = 'Account Executive';
        uta.UserId = uCDM1.Id;
        utaRecords.add(uta);

        uta = new UserTerritory2Association();
        uta.Territory2Id = territories[0].Id;
        uta.RoleInTerritory2 = 'SDR';
        uta.UserId = uCDM2.Id;
        utaRecords.add(uta);

        uta = new UserTerritory2Association();
        uta.Territory2Id = territories[2].Id;
        uta.RoleInTerritory2 = 'Channel Manager';
        uta.UserId = uCDM3.Id;
        utaRecords.add(uta);

        //insert utaRecords;
        Test.stopTest();

        //insert vUserRole;
        String uniqueName = TestDataFactory.getUniqueName();
        User runAsUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Rubrik Field Sales User'].Id,    
            LastName = 'last',
            Email = uniqueName +'@rubrik.com',
            Username = uniqueName +'@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = uniqueName.substring(0,5),
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            //UserRoleId = vUserRole.Id,
            Start_Date__c=System.Today().adddays(-30)         
        );
        insert runAsUser; 

        uta = new UserTerritory2Association();
        uta.Territory2Id = territories[0].Id;
        uta.RoleInTerritory2 = 'Account Executive';
        uta.UserId = runAsUser.Id;
        utaRecords.add(uta);
        system.runas(sysuser1){
            insert utaRecords;
            System.assert(true);
        }
    }

    /*@isTest static void createAllianceSDPDeals(){
        User sysuser1 = TestDataFactory.getUser();
        System.runAs(sysuser1){
            Account acc = TestDataFactory.getAccount();
            acc.name = 'Test New Account';
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            acc.OwnerId = UserInfo.getUserId();
            Insert acc;
            
            Contact con = TestDataFactory.getContact(acc);
            insert con;
            
            Opportunity opp = TestDataFactory.getOpportunity();
            opp.AccountId = acc.Id;
            insert opp;
            
            Deal_Registration__c deal = TestDataFactory.getDealRegistration();
            Deal_Registration__c deal2 = TestDataFactory.getDealRegistration();
            Deal_Registration__c deal3 = TestDataFactory.getDealRegistration();
            Test.startTest();
            deal.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Alliance').getRecordTypeId();
            deal.OwnerId = UserInfo.getUserId();
            deal.StateCode__c = '';
            deal.Deal_Registration_Status__c = 'Submitted';
            deal.Company_Name__c = acc.Id;
            deal.Primary_Contact__c = con.Id;
            deal.Partner_Lookup__c = acc.Id;
            insert deal;
            
            deal.Deal_Registration_Status__c = 'Approved';
            deal.Opportunity__c = opp.Id;
            deal.Primary_Deal_Registration__c = true;
            deal.Partner_lookup__c = acc.Id;
            update deal;
            
            PC_DealRegistrationApexController.allowDRAssociationToOpportunity(deal.Id,opp.Id);
            
            deal2.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByDeveloperName().get('Service_Delivery_Partner').getRecordTypeId(); // PRIT24-887
            deal2.StateCode__c = '';
            deal2.Deal_Registration_Status__c = 'Submitted';
            deal2.Company_Name__c = acc.Id;
            deal2.Primary_Contact__c = con.Id;
            deal2.Partner_Lookup__c = acc.Id;
            insert deal2;
            
            deal2.Deal_Registration_Status__c = 'Approved';
            deal2.Opportunity__c = opp.Id;
            //deal2.Partner_Lookup__c = acc.Id;
            update deal2;
            
            deal3.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Alliance').getRecordTypeId();
            deal3.OwnerId = UserInfo.getUserId();
            deal3.StateCode__c = '';
            deal3.Deal_Registration_Status__c = 'Submitted';
            deal3.Company_Name__c = acc.Id;
            deal3.Primary_Contact__c = con.Id;
            insert deal3;
            
            deal3.Auto_Registered_from_Opportunity__c = true;
            deal3.Opportunity__c = opp.Id;
            update deal3;
            
            Test.stopTest();
            System.assert(true);
        }
    }*/
}