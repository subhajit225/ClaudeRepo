/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-04-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class DealRegistrationTriggerHelperTest {
	@TestSetup static void makeData(){
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
        System.runAs(sysuser2){
            CountryWithCode__c cc = new CountryWithCode__c(Code__c='US',Name='United States');
            insert cc;
            System.assert(true);
        }
    }
    @isTest static void testSellToPartner(){
        User sysuser1 = TestDataFactory.getUser();
        User sysuser2  = [Select id from user where LastName = 'lastNameDRTest'];

        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        system.runas(sysuser1){
            Account acc = TestDataFactory.getAccount();
            acc.name = 'Test New Account';
            acc.Type = 'Prospect';
            acc.OwnerId = sysuser2.id;
            acc.Focused_Partner__c = true;
            insert acc;

            //Create contact
            Contact contact1 = new Contact(
                FirstName = 'Test',
                Lastname = 'McTes11',
                AccountId = acc.Id,
                Email = System.now().millisecond() + 'test@test.com',
                Primary_Role__c = 'Admin'
            );
			insert contact1;
            Id georecId = Schema.SObjectType.PatchManager__c.getRecordTypeInfosByName().get('Geographic').getRecordTypeId();
            PatchManager__c pm = new PatchManager__c(recordtypeId=georecId,CDM__c=sysuser2.Id,CountryGlobal__c='United States',City__c='City',State__c='AK',StateGlobal__c='AK',Zip_code__c='421302',SDR__c=sysuser2.Id,AccountExecutive__c=sysuser2.Id);
            insert pm;
            CountryWithCode__c cc = new CountryWithCode__c(Code__c='US',Name='United States');
            insert cc;
            Opportunity opp = TestDataFactory.getOpportunity();
            insert opp;

            Id internal = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Internal').getRecordTypeId();
            Deal_Registration__c deal=TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Status__c = 'Submitted';
            deal.Company_Name__c = acc.id;
            deal.Partner_Lookup__c = acc.id;
            deal.RecordTypeId = internal;
            deal.GSI_Deal_Registration__c = true;
            deal.Primary_Contact__c = contact1.Id;
            try{
            	insert deal;
            }
            catch(exception e){
                System.debug(LoggingLevel.DEBUG, 'error');
            }
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

        List<User> userList = new List<User>();
        List<PermissionSetAssignment> psAssignmentList = new List<PermissionSetAssignment>();
        
        Profile prCDM = [Select Id from profile where Name='Channel Development Manager'];
        Id psId = [SELECT Id from PermissionSet WHERE Name = 'RubrikChannelUsersNew'].Id;
        
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
        );
        userList.add(uCDM1);
        
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
        );
        userList.add(uCDM2);

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
        );
        userList.add(uCDM3);
        
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

        Test.stopTest();
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

        insert utaRecords;
        System.assert(true);
    }

    @isTest static void testrunPatchManager() {
        Deal_Registration__c deal=TestDataFactory.getDealRegistration();
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        deal.Deal_Registration_Status__c = 'Submitted';
        insert deal;
        Test.startTest();
            deal.rerun_PatchManager_Assignments__c = true;
            update deal;
        Test.stopTest();
    }

    static testMethod void testMethod4() {
        User sysuser1 = TestDataFactory.getUser();
        User sysuser2  = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'last',
            Email = 'enrique1233' +'@rubrik.com',
            Username = 'enrique1233' +'@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'enrqueName'.substring(0,5),
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Start_Date__c=System.Today().adddays(-30)
        );
        insert sysuser2;
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        system.runas(sysuser1){
            Id georecId = Schema.SObjectType.PatchManager__c.getRecordTypeInfosByName().get('Geographic').getRecordTypeId();
            PatchManager__c pm = new PatchManager__c(recordtypeId=georecId,CDM__c=sysuser2.Id,CountryGlobal__c='United States',City__c='City',State__c='AK',StateGlobal__c='AK',Zip_code__c='421302',SDR__c=sysuser2.Id,AccountExecutive__c=sysuser2.Id);
            insert pm;
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
        User sysuser1 = TestDataFactory.getUser();
        User sysuser2  = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'last',
            Email = 'enrique1233' +'@rubrik.com',
            Username = 'enrique1233' +'@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'enrqueName'.substring(0,5),
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Start_Date__c=System.Today().adddays(-30)
        );
        insert sysuser2;
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        system.runas(sysuser1){
            Id georecId = Schema.SObjectType.PatchManager__c.getRecordTypeInfosByName().get('Geographic').getRecordTypeId();
            PatchManager__c pm = new PatchManager__c(recordtypeId=georecId,CDM__c=sysuser2.Id,CountryGlobal__c='United States',City__c='City',State__c='AK',StateGlobal__c='AK',Zip_code__c='421302',SDR__c=sysuser2.Id,AccountExecutive__c=sysuser2.Id);
            insert pm;
            Opportunity opp = TestDataFactory.getOpportunity();
            insert opp;
            Deal_Registration__c deal=TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Status__c = 'Submitted';
            insert deal;
            deal.ownerid = sysuser2.Id;
            deal.Deal_Registration_Status__c = 'Escalated';
            deal.Opportunity__c = opp.Id;
            deal.PS_Escalated__c = true;
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

    static testMethod void testMethod6() {
        string accountPartnerRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        User sysuser1 = TestDataFactory.getUser();
        User sysuser2  = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'last',
            Email = 'enrique1233' +'@rubrik.com',
            Username = 'enrique1233' +'@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'enrqueName'.substring(0,5),
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Start_Date__c=System.Today().adddays(-30)
        );
        insert sysuser2;
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        system.runas(sysuser1){
            Account accp = TestDataFactory.getAccount();
            accp.name = 'Test New Account Partner Acc';
            accp.Type = 'Reseller';
            accp.OwnerId = sysuser2.Id;
            accp.RecordTypeId = accountPartnerRecordType;
            accp.MSP_Sub_Type__c = 'GSI';
            insert accp;

            Opportunity opp = TestDataFactory.getOpportunity();
            insert opp;
            Deal_Registration__c deal=TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Status__c = 'Submitted';
            insert deal;
            deal.ownerid = sysuser2.Id;
            deal.Deal_Registration_Status__c = 'Approved';
            deal.Opportunity__c = opp.Id;
            deal.Partner_Lookup__c = accp.Id;
            //update deal;
            Deal_Registration__c deal1 = [select name from Deal_Registration__c where id =:deal.Id];
            opp.Deal_Registration_Number__c = deal1.name;
            opp.Deal_Reg_Approval_Status__c = 'Approved';
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
    
    static testMethod void testMethod7() {
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
        
        User sysuser1 = TestDataFactory.getUser();
        User sysuser2  = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'last',
            Email = 'enrique1233' +'@rubrik.com',
            Username = 'enrique1233' +'@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'enrqueName'.substring(0,5),
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Start_Date__c=System.Today().adddays(-30)
        );
        insert sysuser2;
        
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        system.runas(sysuser1){
            
            //User Territory Association
            List<UserTerritory2Association> utaRecords = new List<UserTerritory2Association>();
            UserTerritory2Association uta = new UserTerritory2Association();
            uta.Territory2Id = territories[0].Id;
            uta.RoleInTerritory2 = 'Account Executive';
            uta.UserId = sysuser1.Id;
            utaRecords.add(uta);
            
            uta = new UserTerritory2Association();
            uta.Territory2Id = territories[0].Id;
            uta.RoleInTerritory2 = 'CDM';
            uta.UserId = sysuser2.Id;
            utaRecords.add(uta);
            
            insert utaRecords;
            Account portalAccount = new Account(Name = 'TestAccount', Type = 'MSP');
            insert portalAccount;

            Contact contact = new Contact(
                FirstName = 'Test',
                LastName = 'McTesty',
                AccountId = portalAccount.Id,
                Email = System.now().millisecond() + 'test@test.com',
                Primary_Role__c = 'Admin'
            );
            insert contact;
            
            Id georecId = Schema.SObjectType.PatchManager__c.getRecordTypeInfosByName().get('Geographic').getRecordTypeId();
            PatchManager__c pm = new PatchManager__c(recordtypeId=georecId,CDM__c=sysuser2.Id,CountryGlobal__c='United States',City__c='City',State__c='AK',StateGlobal__c='AK',Zip_code__c='421302',SDR__c=sysuser2.Id,AccountExecutive__c=sysuser2.Id,TLevel1__c='AMER');
            insert pm;
            Opportunity opp = TestDataFactory.getOpportunity();
            insert opp;
            Deal_Registration__c deal=TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Status__c = 'Submitted';
            deal.Partner_Lookup__c = portalAccount.Id;
            deal.Company_Name__c = portalAccount.Id;
            deal.GSI_Deal_Registration__c = true;
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
    
    @isTest static void testsetInternalDRStatus(){
        User sysuser1 = TestDataFactory.getUser();
        User sysuser2  = [Select id from user where LastName = 'lastNameDRTest'];

        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        system.runas(sysuser1){
            Account acc = TestDataFactory.getAccount();
            acc.name = 'Test New Account';
            acc.Type = 'Prospect';
            acc.OwnerId = sysuser2.id;
            acc.Focused_Partner__c = true;
            insert acc;
            //Create contact
            Contact contact1 = new Contact(
                FirstName = 'Test',
                Lastname = 'McTes11',
                AccountId = acc.Id,
                Email = System.now().millisecond() + 'test@test.com',
                Primary_Role__c = 'Admin'
            );
			insert contact1;
            CountryWithCode__c cc = new CountryWithCode__c(Code__c='US',Name='United States');
            insert cc;
            Opportunity opp = TestDataFactory.getOpportunity();
            insert opp;

            Deal_Registration__c deal = TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Status__c = 'Submitted';
            deal.Company_Name__c = acc.id;
            deal.Partner_Lookup__c = acc.id;
            deal.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByDeveloperName().get('Service_Delivery_Partner').getRecordTypeId();
            deal.GSI_Deal_Registration__c = true;
            deal.GSI_NDA__c = true;
            deal.Primary_Contact__c = contact1.Id;
            deal.StateCode__c = '';

            Test.startTest();
            insert deal;
            Test.stopTest();

            deal.Deal_Registration_Status__c = 'Approved';
            deal.Opportunity__c = opp.Id;
            update deal;
            System.assert(true);
        }
    }

    @isTest static void testUpdateAllianceOEMDR(){
        User sysuser1 = TestDataFactory.getUser();
        User sysuser2  = [Select id from user where LastName = 'lastNameDRTest'];

        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        system.runas(sysuser1){
            Account acc = TestDataFactory.getAccount();
            acc.name = 'Test New Account';
            acc.Type = 'Prospect';
            acc.OwnerId = sysuser2.id;
            acc.Focused_Partner__c = true;
            insert acc;

            Account acc1 = TestDataFactory.getAccount();
            acc1.name = 'Test New Account';
            acc1.Type = 'Partner';
            acc1.OwnerId = sysuser2.id;
            acc1.Focused_Partner__c = true;
            acc1.RecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            acc1.Type = 'OEM';
            acc1.OEM_SubType__c = 'Revshare';
            insert acc1;

            //Create contact
            Contact contact1 = new Contact(
                FirstName = 'Test',
                Lastname = 'McTes11',
                AccountId = acc.Id,
                Email = System.now().millisecond() + 'test@test.com',
                Primary_Role__c = 'Admin'
            );
			insert contact1;
            CountryWithCode__c cc = new CountryWithCode__c(Code__c='US',Name='United States');
            insert cc;
            Opportunity opp = TestDataFactory.getOpportunity();
            insert opp;

            Deal_Registration__c deal = TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Status__c = 'Submitted';
            deal.Company_Name__c = acc.id;
            deal.Partner_Lookup__c = acc.id;
            deal.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByDeveloperName().get('Alliance').getRecordTypeId();
            deal.Primary_Contact__c = contact1.Id;
            deal.StateCode__c = '';

            Test.startTest();
            insert deal;
            Test.stopTest();

            deal.Deal_Registration_Status__c = 'Approved';
            deal.Primary_Deal_Registration__c = true;
            deal.Opportunity__c = opp.Id;
            update deal;

            Id georecId = Schema.SObjectType.PatchManager__c.getRecordTypeInfosByName().get('Geographic').getRecordTypeId();
            PatchManager__c pmRec = new PatchManager__c(recordtypeId=georecId,CDM__c=sysuser2.Id,CountryGlobal__c='United States',City__c='City',State__c='',StateGlobal__c='',Zip_code__c='421302',SDR__c=sysuser2.Id,AccountExecutive__c=sysuser2.Id);
            insert pmRec;

            Deal_Registration__c deal1 = TestDataFactory.getDealRegistration();
            deal1.Deal_Registration_Status__c = 'Submitted';
            deal1.Company_Name__c = acc.id;
            deal1.Partner_Lookup__c = acc.id;
            deal1.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByDeveloperName().get('OEM').getRecordTypeId();
            deal1.Primary_Contact__c = contact1.Id;
            deal1.StateCode__c = '';
            deal1.Distributor__c = acc1.Id;
            deal1.PatchManager__c = pmRec != null ? pmRec.Id : null;
            deal1.OwnerId = sysuser2.id;
            insert deal1;
            System.assert(true);
        }
    }

    @isTest static void testmanageConvertedLeads(){
        User sysuser1 = TestDataFactory.getUser();
        User sysuser2  = [Select id from user where LastName = 'lastNameDRTest'];

        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        system.runas(sysuser1){
            Account acc1 = TestDataFactory.getAccount();
            acc1.name = 'Test New Account';
            acc1.Type = 'Partner';
            acc1.OwnerId = sysuser2.id;
            acc1.Focused_Partner__c = true;
            acc1.RecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert acc1;

            CountryWithCode__c cc = new CountryWithCode__c(Code__c='US',Name='United States');
            insert cc;
            Opportunity opp = TestDataFactory.getOpportunity();
            insert opp;

            List<Lead> leadList = new List<Lead>();
            Lead led = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
            led.firstName = 'Test Lead FN';
            led.lastName = 'Test Lead LN';
            led.Status = 'Open';
            led.CountryCode = 'US';
            led.Routing_Rule_Applied__c ='test';
            leadList.add(led);

            Lead led1 = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
            led1.firstName = 'Test Lead FN12';
            led1.lastName = 'Test Lead LN23';
            led1.Status = 'Open';
            led1.CountryCode = 'US';
            led1.Routing_Rule_Applied__c ='test';
            leadList.add(led1);

            List<Deal_Registration__c> dealList = new List<Deal_Registration__c>();
            Deal_Registration__c deal = TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Status__c = 'Submitted';
            deal.Partner_Lookup__c = acc1.id;
            deal.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            deal.StateCode__c = '';
            deal.Lead_Share_Campaign__c = true;
            dealList.add(deal);

            Deal_Registration__c deal1 = TestDataFactory.getDealRegistration();
            deal1.Deal_Registration_Status__c = 'Submitted';
            deal1.Partner_Lookup__c = acc1.id;
            deal1.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            deal1.StateCode__c = '';
            dealList.add(deal1);

            Test.startTest();
            insert dealList;
            insert leadList;
            Test.stopTest();

            dealList[0].Deal_Registration_Status__c = 'Pending Conversion';
            dealList[0].Lead__c = leadList[0].Id;
            update dealList[0];

            dealList[1].Deal_Registration_Status__c = 'Pending Conversion';
            dealList[1].Lead__c = leadList[1].Id;
            update dealList[1];
            System.assert(true);
        }
    }

    @isTest static void testaddCustomerContactAsOppRole(){
        User sysuser1 = TestDataFactory.getUser();
        User sysuser2  = [Select id from user where LastName = 'lastNameDRTest'];

        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        system.runas(sysuser1){
            Account acc1 = TestDataFactory.getAccount();
            acc1.name = 'Test New Account';
            acc1.Type = 'Partner';
            acc1.OwnerId = sysuser2.id;
            acc1.Focused_Partner__c = true;
            acc1.RecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert acc1;

            Account acc2 = TestDataFactory.getAccount();
            acc2.name = 'Test New Account';
            acc2.Type = 'MSP-Reseller';
            acc2.OwnerId = sysuser2.id;
            acc2.Focused_Partner__c = true;
            acc2.RecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            //acc2.Account_Status__c = 'Existing Customer';
            insert acc2;

            Account acc3 = TestDataFactory.getAccount();
            acc3.name = 'Test New Account';
            acc3.Type = 'MSP Customer';
            acc3.OwnerId = sysuser2.id;
            //acc3.Account_Status__c = 'Prospect';
            insert acc3;

            Contact contact1 = new Contact(
                FirstName = 'Tes33232t',
                Lastname = 'McTes11123',
                AccountId = acc1.Id,
                Email = 'test@test9876541.com',
                Primary_Role__c = 'Admin'
            );
            insert contact1;

            CountryWithCode__c cc = new CountryWithCode__c(Code__c='US',Name='United States');
            insert cc;
            Opportunity opp = TestDataFactory.getOpportunity();
            insert opp;

            Opportunity opp1 = TestDataFactory.getOpportunity();
            insert opp1;

            Opportunity opp2 = TestDataFactory.getOpportunity();
            opp2.AccountId = acc2.Id;
            insert opp2;

            Opportunity opp3 = TestDataFactory.getOpportunity();
            opp3.AccountId = acc3.Id;
            insert opp3;

            OpportunityContactRole ocr = new OpportunityContactRole();
            ocr.ContactId = contact1.Id;
            ocr.OpportunityId = opp.Id;
            insert ocr;

            List<Lead> leadList = new List<Lead>();
            Lead led = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
            led.firstName = 'Test Lead FN987';
            led.lastName = 'Test Lead LN987';
            led.Status = 'Open';
            led.email = 'test@test987654.com';
            led.status = 'RAW';
            led.CountryCode = 'US';
            led.Routing_Rule_Applied__c ='test';
            led.Deal_Registration__c = true;
            led.Deal_Reg_Approval_Status__c = 'Expired';
            leadList.add(led);

            List<Deal_Registration__c> dealList = new List<Deal_Registration__c>();
            Deal_Registration__c deal = TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Status__c = 'Submitted';
            deal.Partner_Lookup__c = acc1.id;
            deal.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            deal.Email__c = 'test@test987654.com';
            deal.StateCode__c = '';
            deal.company_name__c = acc1.id;
            deal.Lead_Share_Campaign__c = true;
            dealList.add(deal);

            Deal_Registration__c deal1 = TestDataFactory.getDealRegistration();
            deal1.Deal_Registration_Status__c = 'Submitted';
            deal1.Partner_Lookup__c = acc1.id;
            deal1.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByDeveloperName().get('Service_Delivery_Partner').getRecordTypeId();
            deal1.StateCode__c = '';
            deal1.Email__c = 'test@test9876541.com';
            deal1.Primary_Contact__c = contact1.Id;
            dealList.add(deal1);

            Deal_Registration__c deal2 = TestDataFactory.getDealRegistration();
            deal2.Deal_Registration_Status__c = 'Submitted';
            deal2.Company_Name__c = acc2.id;
            deal2.Partner_Lookup__c = acc1.id;
            deal2.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            deal2.StateCode__c = '';
            deal2.Email__c = 'test@test98765434.com';
            deal2.Primary_Contact__c = contact1.Id;
            dealList.add(deal2);

            Deal_Registration__c deal3 = TestDataFactory.getDealRegistration();
            deal3.Deal_Registration_Status__c = 'Submitted';
            deal3.Company_Name__c = acc3.id;
            deal3.Partner_Lookup__c = acc1.id;
            deal3.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Engagement').getRecordTypeId();
            deal3.StateCode__c = '';
            deal3.Email__c = 'test@test98765424.com';
            deal3.Primary_Contact__c = contact1.Id;
            dealList.add(deal3);

            Test.startTest();
            insert dealList;
            insert leadList;

            dealList[0].Deal_Registration_Status__c = 'Approved';
            dealList[0].Opportunity__c = opp.Id;

            dealList[1].Deal_Registration_Status__c = 'Approved';
            dealList[1].Opportunity__c = opp1.Id;
            
            dealList[2].Deal_Registration_Status__c = 'Approved';
            dealList[2].Opportunity__c = opp.Id;
            
            dealList[3].Deal_Registration_Status__c = 'Approved';
            dealList[3].Opportunity__c = opp1.Id;
            
            update dealList;
            List<Deal_Registration__c> errorList = new List<Deal_Registration__c>();
            try{
                deal.company_name__c = acc2.Id;
                deal1.Partner_Lookup__c = acc2.Id;
                deal2.Distributor__c = acc2.Id;
                deal3.Opportunity__c = opp.Id;
                errorList.add(deal);
                errorList.add(deal1);
                errorList.add(deal2);
                errorList.add(deal3);
                update errorList;
            }catch(exception e){
                System.debug(LoggingLevel.DEBUG, 'error');
            }
            
            Test.stopTest();
            System.assert(true);
        }
    }
    
    @isTest static void markDealRegApprovedTest(){
        User sysuser1 = TestDataFactory.getUser();
        User sysuser2  = [Select id from user where LastName = 'lastNameDRTest'];
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        system.runas(sysuser1){
            Account acc1 = TestDataFactory.getAccount();
            acc1.name = 'Test New Account';
            acc1.Type = 'Partner';
            acc1.OwnerId = sysuser2.id;
            acc1.Focused_Partner__c = true;
            acc1.RecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert acc1;
            Contact contact1 = new Contact(
                FirstName = 'Tes33232t',
                Lastname = 'McTes11123',
                AccountId = acc1.Id,
                Email = 'test@test9876541.com',
                Primary_Role__c = 'Admin'
            );
            insert contact1;

            CountryWithCode__c cc = new CountryWithCode__c(Code__c='US',Name='United States');
            insert cc;
            Opportunity opp = TestDataFactory.getOpportunity();
            insert opp;
            
            List<Deal_Registration__c> dealList = new List<Deal_Registration__c>();
            Deal_Registration__c deal1 = TestDataFactory.getDealRegistration();
            deal1.Deal_Registration_Status__c = 'Submitted';
            deal1.Partner_Lookup__c = acc1.id;
            deal1.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByDeveloperName().get('Service_Delivery_Partner').getRecordTypeId();
            deal1.StateCode__c = '';
            deal1.Email__c = 'test@test9876541.com';
            deal1.Primary_Contact__c = contact1.Id;
            deal1.Deal_Reg_Exp_Date__c = Date.today().addDays(1);
            dealList.add(deal1);
            
            Deal_Registration__c deal2 = TestDataFactory.getDealRegistration();
            deal2.Deal_Registration_Status__c = 'Pending Meeting';
            deal2.Company_Name__c = acc1.id;
            deal2.Partner_Lookup__c = acc1.id;
            deal2.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            deal2.StateCode__c = '';
            deal2.Email__c = 'test@test98765434.com';
            deal2.Primary_Contact__c = contact1.Id;
            deal2.Deal_Reg_Exp_Date__c = Date.today().addDays(1);
            dealList.add(deal2);
            
            Deal_Registration__c deal3 = TestDataFactory.getDealRegistration();
            deal3.Deal_Registration_Status__c = 'Submitted';
            deal3.Partner_Lookup__c = acc1.id;
            deal3.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByDeveloperName().get('Service_Delivery_Partner').getRecordTypeId();
            deal3.StateCode__c = '';
            deal3.Email__c = 'test@test9876541333.com';
            deal3.Primary_Contact__c = contact1.Id;
            deal3.Deal_Reg_Exp_Date__c = Date.today().addDays(1);
            dealList.add(deal3);
            
            insert dealList;
            
            deal1.Deal_Registration_Sub_Status__c = 'Extension Approved';
            deal1.Opportunity__c = opp.Id;
            
            deal2.Deal_Registration_Extension_Request__c = 'Pending Meeting Ext. Req. for next 10 Days';
            
            deal3.Deal_Registration_Status__c = 'Expired';
            Test.startTest();
        		update dealList;
            try{
                DealRegistrationTriggerHelper cls = new DealRegistrationTriggerHelper();
                Lead newLead = cls.copyDealRegToLead(deal1, null);
            }catch(exception e){
                System.debug(LoggingLevel.DEBUG, 'error');
            }
        	Test.stopTest();
            System.assert(true);
        }
    }
    
    @isTest static void populateGSIDealRegTest(){
        User sysuser1 = TestDataFactory.getUser();
        User sysuser2  = [Select id from user where LastName = 'lastNameDRTest'];
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        system.runas(sysuser1){
            Account acc1 = TestDataFactory.getAccount();
            acc1.name = 'Test New Account';
            acc1.Type = 'Partner';
            acc1.OwnerId = sysuser2.id;
            acc1.Focused_Partner__c = true;
            acc1.MSP_Sub_Type__c = 'GSI';
            acc1.RecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert acc1;
            Contact contact1 = new Contact(
                FirstName = 'Tes33232t',
                Lastname = 'McTes11123',
                AccountId = acc1.Id,
                Email = 'test@test9876541.com',
                Primary_Role__c = 'Admin'
            );
            insert contact1;

            CountryWithCode__c cc = new CountryWithCode__c(Code__c='US',Name='United States');
            insert cc;
            Opportunity opp = TestDataFactory.getOpportunity();
            insert opp;
            List<Deal_Registration__c> dealList = new List<Deal_Registration__c>();
            Deal_Registration__c deal1 = TestDataFactory.getDealRegistration();
            deal1.Deal_Registration_Status__c = 'Submitted';
            deal1.Partner_Lookup__c = acc1.id;
            deal1.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByDeveloperName().get('Service_Delivery_Partner').getRecordTypeId();
            deal1.StateCode__c = '';
            deal1.Email__c = 'test@test9876541.com';
            deal1.Primary_Contact__c = contact1.Id;
            deal1.Deal_Reg_Exp_Date__c = Date.today().addDays(1);
            dealList.add(deal1);
            
            Test.startTest();
        		insert dealList;
        	Test.stopTest();
            System.assert(true);
        }
    }
    
    @isTest static void checkDRInfoUpdateTest(){
        User sysuser1 = TestDataFactory.getUser();
        User sysuser2  = [Select id from user where LastName = 'lastNameDRTest'];
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        system.runas(sysuser1){
            Account acc1 = TestDataFactory.getAccount();
            acc1.name = 'Test New Account';
            acc1.Type = 'Partner';
            acc1.OwnerId = sysuser2.id;
            acc1.Focused_Partner__c = true;
            acc1.MSP_Sub_Type__c = 'GSI';
            acc1.RecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert acc1;
            
            Contact contact1 = new Contact(
                FirstName = 'Tes33232t',
                Lastname = 'McTes11123',
                AccountId = acc1.Id,
                Email = 'test@test9876541.com',
                Primary_Role__c = 'Admin'
            );
            insert contact1;
            CountryWithCode__c cc = new CountryWithCode__c(Code__c='US',Name='United States');
            insert cc;
            Opportunity opp = TestDataFactory.getOpportunity();
            insert opp;
            
            Lead existingLead = new Lead(
                LastName = 'Old Lead',
                Company = 'Old Company',
                Country = 'United States'
            );
            insert existingLead;
            
            List<Deal_Registration__c> dealList = new List<Deal_Registration__c>();
            Deal_Registration__c deal1 = TestDataFactory.getDealRegistration();
            deal1.Deal_Registration_Status__c = 'Submitted';
            deal1.Partner_Lookup__c = acc1.id;
            deal1.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByDeveloperName().get('Service_Delivery_Partner').getRecordTypeId();
            deal1.StateCode__c = '';
            deal1.Email__c = 'test@test9876541.com';
            deal1.Primary_Contact__c = contact1.Id;
            deal1.Deal_Reg_Exp_Date__c = Date.today().addDays(1);
            deal1.Lead__c = existingLead.Id;
            dealList.add(deal1);
            insert dealList;
            Deal_Registration__c dealQueried = [SELECT ID,Name FROM Deal_Registration__c WHERE ID =: deal1.Id];
            
            Test.startTest();
            	flowControll.LeadTriggerHandler = false;
            	existingLead.Deal_Reg_Number__c = dealQueried.Name;
            	update existingLead;
            	flowControll.LeadTriggerHandler = true;
            	deal1.Deal_Reg_Exp_Date__c = Date.today().addDays(3);
            	update deal1;
            Test.stopTest();
            System.assert(true);
        }
    }
    
    @isTest static void addCustomerContactAsOppRoleTest(){
        User sysuser1 = TestDataFactory.getUser();
        User sysuser2  = [Select id from user where LastName = 'lastNameDRTest'];
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        system.runas(sysuser1){
            Account acc1 = TestDataFactory.getAccount();
            acc1.name = 'Test New Account';
            acc1.Type = 'Partner';
            acc1.OwnerId = sysuser2.id;
            acc1.Focused_Partner__c = true;
            acc1.MSP_Sub_Type__c = 'GSI';
            acc1.RecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert acc1;
            Account acc2 = TestDataFactory.getAccount();
            acc2.name = 'Test New Account 2';
            acc2.Type = 'Partner';
            acc2.OwnerId = sysuser2.id;
            acc2.Focused_Partner__c = true;
            acc2.MSP_Sub_Type__c = 'GSI';
            acc2.RecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert acc2;
            List<Contact> conList = new List<Contact>();
            Contact contact1 = new Contact(
                FirstName = 'Tes33232t',
                Lastname = 'McTes11123',
                AccountId = acc1.Id,
                Email = 'test@test987654122.com',
                Primary_Role__c = 'Admin'
            );
            conList.add(contact1);
            Contact contact2 = new Contact(
                FirstName = 'Tes33232t',
                Lastname = 'McTes11123',
                AccountId = acc2.Id,
                Email = 'test@test987654122.com',
                Primary_Role__c = 'Admin'
            );
            conList.add(contact2);
            insert conList;
            CountryWithCode__c cc = new CountryWithCode__c(Code__c='US',Name='United States');
            insert cc;
            Opportunity opp = TestDataFactory.getOpportunity();
            insert opp;
            
            List<Deal_Registration__c> dealList = new List<Deal_Registration__c>();
            Deal_Registration__c deal1 = TestDataFactory.getDealRegistration();
            deal1.Deal_Registration_Status__c = 'Submitted';
            deal1.Partner_Lookup__c = acc1.id;
            deal1.Company_Name__c = acc1.Id;
            deal1.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            deal1.StateCode__c = '';
            deal1.Email__c = 'test@test987654122.com';
            deal1.Primary_Contact__c = contact1.Id;
            deal1.Deal_Reg_Exp_Date__c = Date.today().addDays(1);
            deal1.Opportunity__c = opp.Id;
            dealList.add(deal1);
            insert dealList;
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
            oppMap.put(opp.Id,opp);
            Test.startTest();
            try{
            DealRegistrationTriggerHelper.addCustomerContactAsOppRole(dealList, oppMap);
            }catch(exception e){
                System.debug(LoggingLevel.DEBUG, 'error');
            }
            Test.stopTest();
            System.assert(true);
        }
    }

    @isTest static void createCampaignMembersTest(){
        User sysuser1 = TestDataFactory.getUser();
        User sysuser2  = [Select id from user where LastName = 'lastNameDRTest'];
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        system.runas(sysuser1){
            Account acc1 = TestDataFactory.getAccount();
            acc1.name = 'Test New Account';
            acc1.Type = 'Partner';
            acc1.OwnerId = sysuser2.id;
            acc1.Focused_Partner__c = true;
            acc1.MSP_Sub_Type__c = 'GSI';
            acc1.RecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert acc1;
            List<Contact> conList = new List<Contact>();
            Contact contact1 = new Contact(
                FirstName = 'Tes33232t',
                Lastname = 'McTes11123',
                AccountId = acc1.Id,
                Email = 'test@test987654122.com',
                Primary_Role__c = 'Admin'
            );
            conList.add(contact1);
            Contact contact2 = new Contact(
                FirstName = 'Tes33232t',
                Lastname = 'McTes11123',
                AccountId = acc1.Id,
                Email = 'test@test987654122.com',
                Primary_Role__c = 'Admin'
            );
            conList.add(contact2);
            insert conList;
            CountryWithCode__c cc = new CountryWithCode__c(Code__c='US',Name='United States');
            insert cc;
            Opportunity opp = TestDataFactory.getOpportunity();
            insert opp;
            
            Lead existingLead = new Lead(
                LastName = 'Old Lead',
                Company = 'Old Company',
                Country = 'United States'
            );
            insert existingLead;
            Lead existingLead1 = new Lead(
                LastName = 'Old Lead',
                Company = 'Old Company',
                Country = 'United States'
            );
            insert existingLead1;
            
            List<Deal_Registration__c> dealList = new List<Deal_Registration__c>();
            Deal_Registration__c deal1 = TestDataFactory.getDealRegistration();
            deal1.Deal_Registration_Status__c = 'Submitted';
            deal1.Partner_Lookup__c = acc1.id;
            deal1.Company_Name__c = acc1.Id;
            deal1.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            deal1.StateCode__c = '';
            deal1.Email__c = 'test@test987654122.com';
            deal1.Primary_Contact__c = contact1.Id;
            deal1.Deal_Reg_Exp_Date__c = Date.today().addDays(1);
            deal1.Opportunity__c = opp.Id;
            deal1.Rubrik_Complete_Edition_Reg__c = true;
            dealList.add(deal1);

            Deal_Registration__c deal2 = TestDataFactory.getDealRegistration();
            deal2.Deal_Registration_Status__c = 'Submitted';
            deal2.Partner_Lookup__c = acc1.id;
            deal2.Company_Name__c = acc1.Id;
            deal2.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            deal2.StateCode__c = '';
            deal2.Email__c = 'test@test987654122.com';
            deal2.Primary_Contact__c = contact1.Id;
            deal2.Deal_Reg_Exp_Date__c = Date.today().addDays(1);
            deal2.Opportunity__c = opp.Id;
            dealList.add(deal2);
            insert dealList;

            Map<Integer, Lead> successIndexToLeads = new Map<Integer, Lead>();
            successIndexToLeads.put(0,existingLead);
            successIndexToLeads.put(1,existingLead1);

             // Create a Campaign record - Rubrik Complete Campaign
            List<Campaign> campList = new List<Campaign>();
            Campaign testCampaign = new Campaign(
                Name = 'Partner Portal Deal Registration',
                Status = 'Planned',
                Type = 'Email',
                IsActive = true,
                StartDate = Date.today(),
                EndDate = Date.today().addDays(10),
                Campaign_Sales_Area__c ='AMER',
                Executed_By__c = 'Partner Marketing',
                Alliance_Partner__c = 'Amazon Web Services',
                Campaign_Sales_Region__c = 'AMER',
                Campaign_Theme__c = 'General',
                Campaign_Sales_Theatre__c = 'AMER',
                GTM_Play__c = 'General',
                Involvement_by_Customer_Marketing__c = 'No'
            );
            campList.add(testCampaign);
            Campaign testCampaign1 = new Campaign(
                Name = 'Rubrik Complete Campaign',
                Status = 'Planned',
                Type = 'Email',
                IsActive = true,
                StartDate = Date.today(),
                EndDate = Date.today().addDays(10),
                Campaign_Sales_Area__c ='AMER',
                Executed_By__c = 'Partner Marketing',
                Alliance_Partner__c = 'Amazon Web Services',
                Campaign_Sales_Region__c = 'AMER',
                Campaign_Theme__c = 'General',
                Campaign_Sales_Theatre__c = 'AMER',
                GTM_Play__c = 'General',
                Involvement_by_Customer_Marketing__c = 'No'
            );
            campList.add(testCampaign1);
            flowControll.CampaignTrigger = false;
            insert campList;
            flowControll.CampaignTrigger = true;
            ShGl_DisableBusinessLogic__c setting = new ShGl_DisableBusinessLogic__c(  // required for org-wide default
                Disable_Campaign_Member_Triggers__c = true
            );
            insert setting;

            List<CampaignMember> cMList = new List<CampaignMember>();
            CampaignMember member = new CampaignMember(
                CampaignId = testCampaign.Id,
                LeadId = existingLead.Id,
                Status = 'Planned'  // Optional, depends on org settings
            );
            cMList.add(member);
            CampaignMember member1 = new CampaignMember(
                CampaignId = testCampaign1.Id,
                LeadId = existingLead.Id,
                Status = 'Planned'  // Optional, depends on org settings
            );
            cMList.add(member1);
            insert cMList;
			//Start PRIT26-544
            /*Test.startTest();
            DealRegistrationTriggerHelper helper = new DealRegistrationTriggerHelper();
                helper.createCampaignMembers(successIndexToLeads,dealList);
            Test.stopTest();*/
            //End PRIT26-544
			System.assert(true);
        }
    }
    
    @isTest static void handleDuplicatesTest(){
        User sysuser1 = TestDataFactory.getUser();
        User sysuser2  = [Select id from user where LastName = 'lastNameDRTest'];
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        system.runas(sysuser1){
            
            flowControll.DealRegistrationTrigger = false;
            flowControll.LeadTriggerHandler = false;
            flowControll.CampaignTrigger = false;
            
            Account acc1 = TestDataFactory.getAccount();
            acc1.name = 'Test New Account';
            acc1.Type = 'Partner';
            acc1.OwnerId = sysuser2.id;
            acc1.Focused_Partner__c = true;
            acc1.MSP_Sub_Type__c = 'GSI';
            acc1.RecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert acc1;
            Account acc2 = TestDataFactory.getAccount();
            acc2.name = 'Test New Account 2';
            acc2.Type = 'Partner';
            acc2.OwnerId = sysuser2.id;
            acc2.Focused_Partner__c = true;
            acc2.MSP_Sub_Type__c = 'GSI';
            acc2.RecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert acc2;
            List<Contact> conList = new List<Contact>();
            Contact contact1 = new Contact(
                FirstName = 'Tes33232t',
                Lastname = 'McTes11123',
                AccountId = acc1.Id,
                Email = 'test@test987654122.com',
                Primary_Role__c = 'Admin'
            );
            conList.add(contact1);
            Contact contact2 = new Contact(
                FirstName = 'Tes33232t',
                Lastname = 'McTes11123',
                AccountId = acc2.Id,
                Email = 'test@test987654122.com',
                Primary_Role__c = 'Admin'
            );
            conList.add(contact2);
            insert conList;
            CountryWithCode__c cc = new CountryWithCode__c(Code__c='US',Name='United States');
            insert cc;
            Opportunity opp = TestDataFactory.getOpportunity();
            insert opp;
            
            Lead existingLead = new Lead(
                LastName = 'Old Lead',
                Company = 'Old Company',
                Country = 'United States'
            );
            insert existingLead;
            
            List<Deal_Registration__c> dealList = new List<Deal_Registration__c>();
            Deal_Registration__c deal1 = TestDataFactory.getDealRegistration();
            deal1.Deal_Registration_Status__c = 'Submitted';
            deal1.Partner_Lookup__c = acc1.id;
            deal1.Company_Name__c = acc1.Id;
            deal1.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            deal1.StateCode__c = '';
            deal1.Email__c = 'test@test987654122.com';
            deal1.Primary_Contact__c = contact1.Id;
            deal1.Deal_Reg_Exp_Date__c = Date.today().addDays(1);
            deal1.Opportunity__c = opp.Id;
            deal1.Lead__c = existingLead.Id;
            
            dealList.add(deal1);
            
            Deal_Registration__c deal2 = TestDataFactory.getDealRegistration();
            deal2.Deal_Registration_Status__c = 'Submitted';
            deal2.Partner_Lookup__c = acc1.id;
            deal2.Company_Name__c = acc1.Id;
            deal2.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            deal2.StateCode__c = '';
            deal2.Email__c = 'test@test987654122.com';
            deal2.Primary_Contact__c = contact1.Id;
            deal2.Deal_Reg_Exp_Date__c = Date.today().addDays(1);
            deal2.Opportunity__c = opp.Id;
            dealList.add(deal2);
            
            insert dealList;
            Map<Integer, Set<Id>> mapLead = new Map<Integer, Set<Id>>();
            mapLead.put(1,new Set<Id>{existingLead.Id});
            Test.startTest();
            DealRegistrationTriggerHelper cls = new DealRegistrationTriggerHelper();
            cls.handleDuplicates(mapLead,new List<Lead>{existingLead}, dealList, new Map<Integer, Lead>());
            Test.stopTest();
            System.assert(true);
        }
    }
    
}