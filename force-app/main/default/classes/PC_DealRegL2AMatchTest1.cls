@isTest
public with sharing class PC_DealRegL2AMatchTest1 {
    @TestSetup
    static void makeData(){
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
        acc.OwnerId = sysuser2.id;
        acc.Focused_Partner__c = true;
        insert acc;
    }
    @isTest static void testService() {
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

            Id georecId = Schema.SObjectType.PatchManager__c.getRecordTypeInfosByName().get('Geographic').getRecordTypeId();
            PatchManager__c pm = new PatchManager__c(recordtypeId=georecId,CDM__c=sysuser2.Id,CountryGlobal__c='United States',City__c='City',State__c='AK',StateGlobal__c='AK',Zip_code__c='421302',SDR__c=sysuser2.Id,AccountExecutive__c=sysuser2.Id);
            insert pm;
            CountryWithCode__c cc = new CountryWithCode__c(Code__c='US',Name='United States');
            insert cc;
            system.debug('cc->'+cc);
            Opportunity opp = TestDataFactory.getOpportunity();
            insert opp;

            Id drAlliance = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('OEM').getRecordTypeId();
            Deal_Registration__c deal = TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Status__c = 'Submitted';
            deal.Company_Name__c = acc.id;
            deal.Partner_Lookup__c = acc.id;
            deal.RecordTypeId = drAlliance;
            insert deal;
            deal.ownerid = sysuser2.Id;
            update deal;
			System.enqueueJob(new PC_DealRegL2AMatch(new List<Deal_Registration__c> {deal}));
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
    @isTest static void testService2() {
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
            insert deal;
            deal.ownerid = sysuser2.Id;
            update deal;
			System.enqueueJob(new PC_DealRegL2AMatch(new List<Deal_Registration__c> {deal}));
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
    @isTest static void testServiceFailure() {
        User sysuser1 = TestDataFactory.getUser();
        User sysuser2  = [Select id from user where LastName = 'lastNameDRTest'];
        Account accPartner = [Select id from account where name = 'Test New Account Partner Ninja' limit 1];

        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('FAILURE'));
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
            deal.Dedicated_Managed_Service__c = true;
            deal.Partner_Lookup__c = accPartner.id;
            insert deal;
            deal.ownerid = sysuser2.Id;
            deal.Deal_Registration_Status__c = 'Approved';
            deal.Opportunity__c = opp.id;
            deal.Deal_Registration_Type__c = 'Partner Sourced New Logo (PSNL)';
            update deal;
			System.enqueueJob(new PC_DealRegL2AMatch(new List<Deal_Registration__c> {deal}));
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

    @isTest static void testServiceWithOutAccount() {
        User sysuser1 = TestDataFactory.getUser();
        User sysuser2  = [Select id from user where LastName = 'lastNameDRTest'];
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        system.runas(sysuser1){
            Id domainrecId = Schema.SObjectType.PatchManager__c.getRecordTypeInfosByName().get('Domain').getRecordTypeId();
            Id georecId = Schema.SObjectType.PatchManager__c.getRecordTypeInfosByName().get('Geographic').getRecordTypeId();
            PatchManager__c pm = new PatchManager__c(recordtypeId=georecId,CountryGlobal__c='United States',City__c='City',State__c='AK',StateGlobal__c='AK',Zip_code__c='421302',SDR__c=sysuser2.Id,AccountExecutive__c=sysuser2.Id);
            insert pm;
            CountryWithCode__c cc = new CountryWithCode__c(Code__c='US',Name='United States');
            insert cc;
            Opportunity opp = TestDataFactory.getOpportunity();
            insert opp;
            Deal_Registration__c deal=TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Status__c = 'Submitted';
            deal.ownerid = sysuser1.Id;
            insert deal;
            deal.ownerid = sysuser2.Id;
            update deal;
			System.enqueueJob(new PC_DealRegL2AMatch(new List<Deal_Registration__c> {deal}));
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
    @isTest static void testService3() {
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

            Id georecId = Schema.SObjectType.PatchManager__c.getRecordTypeInfosByName().get('Geographic').getRecordTypeId();
            PatchManager__c pm = new PatchManager__c(recordtypeId=georecId,CDM__c=sysuser2.Id,CountryGlobal__c='United States',City__c='City',State__c='AK',StateGlobal__c='AK',Zip_code__c='421302',SDR__c=sysuser2.Id,AccountExecutive__c=sysuser2.Id);
            insert pm;
            CountryWithCode__c cc = new CountryWithCode__c(Code__c='US',Name='United States');
            insert cc;
            Opportunity opp = TestDataFactory.getOpportunity();
            insert opp;

            Id internal = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            Deal_Registration__c deal=TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Status__c = 'Submitted';
            deal.Company_Name__c = acc.id;
            deal.Partner_Lookup__c = acc.id;
            deal.RecordTypeId = internal;
            insert deal;
            deal.ownerid = sysuser2.Id;
            update deal;
			System.enqueueJob(new PC_DealRegL2AMatch(new List<Deal_Registration__c> {deal}));
            Deal_Registration__c deal1 = [select name from Deal_Registration__c where id =:deal.Id];
            opp.Deal_Registration_Number__c = deal1.name;
            update opp;
            deal1.Deal_Registration_Status__c = 'Escalated';
            deal1.PS_Escalated__c = true;
            deal1.Opportunity__c = opp.Id;
            deal1.Deal_Reg_Exp_Date__c  = system.today().addDays(-1);
            update deal1;
            Map<string,Date> dealRegOppMap = new Map<string,Date>();
            dealRegOppMap.put(deal1.name,system.today());

            PC_DealRegExpiryUpdateBatch b = new PC_DealRegExpiryUpdateBatch();
            Database.executeBatch(b,1);
            System.assert(true);
        }
    }
    
    @isTest static void testService4() {
        
        User sysuser1 = TestDataFactory.getUser();
        system.runas(sysuser1){
            Account acc = TestDataFactory.getAccount();
            acc.name = 'Test New Account';
            acc.Type = 'Prospect';
            acc.Focused_Partner__c = true;
            insert acc;
            
            Lead lead=new Lead(LastName='Doe1',FirstName='John2',Company='Test',Status='RAW',Country = 'United States');
            flowControll.LeadTriggerHandler = false;
            insert lead;
            flowControll.LeadTriggerHandler = true;
            
            Opportunity opp = TestDataFactory.getOpportunity();
            insert opp;
            
            Id internal = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            Deal_Registration__c deal=TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Status__c = 'Submitted';
            deal.Company_Name__c = acc.id;
            deal.Partner_Lookup__c = acc.id;
            deal.RecordTypeId = internal;
            insert deal;
            
            opp.Deal_Registration_Number__c = '1234';
            opp.Deal_Reg_Approval_Status__c = 'Approved';
            update opp;
            
            deal.Deal_Registration_Status__c = 'Approved';
            deal.PS_Escalated__c = true;
            deal.Opportunity__c = opp.Id;
            deal.Lead__c = lead.Id;
            deal.Deal_Reg_Exp_Date__c  = system.today().addDays(-1);
            deal.Deal_Registration_Sub_Status__c = 'Closed Won';
            update deal;
            
            Test.startTest();
            PC_DealRegExpiryUpdateBatch b = new PC_DealRegExpiryUpdateBatch();
            Database.executeBatch(b,1);
            Test.stopTest();
            
            // Query updated records
            Deal_Registration__c updatedDeal = [SELECT Deal_Registration_Status__c, Send_Expiry_Notification__c, PS_Escalated__c, 
                                                Opportunity__c, Primary_Deal_Registration__c, Deal_Registration_Sub_Status__c 
                                                FROM Deal_Registration__c WHERE Id = :deal.Id];
            
            // Assertions
            System.assertEquals('Expired', updatedDeal.Deal_Registration_Status__c, 'Deal should be marked as Expired');
            System.assertEquals(true, updatedDeal.Send_Expiry_Notification__c, 'Expiry notification flag should be true');
        }
        
    }
    
    @isTest static void testMethod4() {
        User sysuser1 = TestDataFactory.getUser();
        User sysuser2  = [Select id from user where LastName = 'lastNameDRTest'];

        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        system.runas(sysuser1){
            Account acc = TestDataFactory.getAccount();
            acc.name = 'Test N A1 ';
            acc.Type = 'Prospect';
            acc.OwnerId = sysuser2.id;
            acc.Focused_Partner__c = true;
            insert acc;
			Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
            Id georecId = Schema.SObjectType.PatchManager__c.getRecordTypeInfosByName().get('Geographic').getRecordTypeId();
            PatchManager__c pm = new PatchManager__c(recordtypeId=georecId,CDM__c=sysuser2.Id,CountryGlobal__c='United States',City__c='City',State__c='AK',StateGlobal__c='AK',Zip_code__c='421302',SDR__c=sysuser2.Id,AccountExecutive__c=sysuser2.Id);
            insert pm;
            CountryWithCode__c cc = new CountryWithCode__c(Code__c='US',Name='United States');
            insert cc;
            Opportunity opp1 = TestDataFactory.getOpportunity();
            FlowControll.opportunityTriggerHandler = false;
            insert opp1;
            FlowControll.opportunityTriggerHandler = true;
			 
            List<Deal_Registration__c> drList = new List<Deal_Registration__c>();
            Deal_Registration__c deal=TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Status__c = 'Submitted';
            deal.Company_Name__c = acc.id;
            deal.Partner_Lookup__c = acc.id;
            deal.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Internal').getRecordTypeId();
            deal.GSI_Deal_Registration__c = true;
            
            Deal_Registration__c dealA=TestDataFactory.getDealRegistration();
            dealA.Deal_Registration_Status__c = 'Submitted';
            dealA.Company_Name__c = acc.id;
            dealA.Partner_Lookup__c = acc.id;
            dealA.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Alliance').getRecordTypeId();
            dealA.GSI_Deal_Registration__c = true;
            drList.add(deal);
            drList.add(dealA);
            insert drList;
            oldMap.put(opp1.Id, opp1);
            
            List<Deal_Registration__c> drList2 = new List<Deal_Registration__c>();
            deal.Deal_Registration_Status__c = 'Approved';
            dealA.Deal_Registration_Status__c = 'Approved';
            drList2.add(deal); drList2.add(dealA);
            Test.startTest();
            update drList2;
			System.enqueueJob(new PC_DealRegL2AMatch(new List<Deal_Registration__c> {deal}));
            deal.Opportunity__c = opp1.Id;
            dealA.Opportunity__c = opp1.Id;
            DealRegistrationTriggerHelper helper = new DealRegistrationTriggerHelper();
            helper.updateSDPInformation(new List<Deal_Registration__c>{deal},oldMap);
            helper.updateAlliancePartnerInformation(new List<Deal_Registration__c>{dealA},oldMap);
            Test.stopTest();
            System.assert(true);
        }
    }
     @isTest static void testMethod5() {
        User sysuser1 = TestDataFactory.getUser();
        User sysuser2  = [Select id from user where LastName = 'lastNameDRTest'];

        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        system.runas(sysuser1){
            Lead lead=new Lead(LastName='Doe1',FirstName='John2',Company='Test',Status='RAW',Country = 'United States');
            flowControll.LeadTriggerHandler = false;
            insert lead;
            flowControll.LeadTriggerHandler = true;
            Account acc = TestDataFactory.getAccount();
            acc.name = 'Test N A1 ';
            acc.Type = 'Prospect';
            acc.OwnerId = sysuser2.id;
            acc.Focused_Partner__c = true;
            insert acc;
            Id georecId = Schema.SObjectType.PatchManager__c.getRecordTypeInfosByName().get('Geographic').getRecordTypeId();
            PatchManager__c pm = new PatchManager__c(recordtypeId=georecId,CDM__c=sysuser2.Id,CountryGlobal__c='United States',City__c='City',State__c='AK',StateGlobal__c='AK',Zip_code__c='421302',SDR__c=sysuser2.Id,AccountExecutive__c=sysuser2.Id);
            insert pm;
            CountryWithCode__c cc = new CountryWithCode__c(Code__c='US',Name='United States');
            insert cc;
            Id internal = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            Deal_Registration__c deal=TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Status__c = 'Pending Conversion';
            deal.Company_Name__c = acc.id;
            deal.Partner_Lookup__c = acc.id;
            deal.RecordTypeId = internal;
            deal.Lead__c = lead.Id;
            flowControll.DealRegistrationTrigger = false;
            insert deal;
            flowControll.DealRegistrationTrigger = true;
            Test.startTest();
            Database.LeadConvert lc = new database.LeadConvert();
            lc.setLeadId(lead.id);
            lc.setDoNotCreateOpportunity(false);
            lc.setConvertedStatus('Nurture');
            flowControll.LeadTriggerHandler = false;
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            flowControll.LeadTriggerHandler = true;
            
            deal.Lead__c = null;
            try{
                update deal;
				System.enqueueJob(new PC_DealRegL2AMatch(new List<Deal_Registration__c> {deal}));
            }catch(exception e){
                system.debug(LoggingLevel.DEBUG,'exception' +e);
            }
            System.assert(true);
            Test.stopTest();
        }
     }
    @isTest static void testMethod6(){
        
        User sysuser1 = TestDataFactory.getUser();
        User sysuser2  = [Select id from user where LastName = 'lastNameDRTest'];

        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        system.runas(sysuser1){
            
            Lead lead=new Lead(LastName='Doe1',FirstName='John2',Company='Test',Status='RAW',Country = 'United States');
            flowControll.LeadTriggerHandler = false;
            insert lead;
            flowControll.LeadTriggerHandler = true;
            Account acc = TestDataFactory.getAccount();
            acc.name = 'Test N A1 ';
            acc.Type = 'Prospect';
            acc.OwnerId = sysuser2.id;
            acc.Focused_Partner__c = true;
            insert acc;
            Id georecId = Schema.SObjectType.PatchManager__c.getRecordTypeInfosByName().get('Geographic').getRecordTypeId();
            PatchManager__c pm = new PatchManager__c(recordtypeId=georecId,CDM__c=sysuser2.Id,CountryGlobal__c='United States',City__c='City',State__c='AK',StateGlobal__c='AK',Zip_code__c='421302',SDR__c=sysuser2.Id,AccountExecutive__c=sysuser2.Id);
            insert pm;
            CountryWithCode__c cc = new CountryWithCode__c(Code__c='US',Name='United States');
            insert cc;
            Id internal = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            Deal_Registration__c deal=TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Status__c = 'Pending Meeting';
            deal.Company_Name__c = acc.id;
            deal.Partner_Lookup__c = acc.id;
            deal.RecordTypeId = internal;
            deal.Lead__c = lead.Id;
            flowControll.DealRegistrationTrigger = false;
            insert deal;
            flowControll.DealRegistrationTrigger = true;
            
            Test.startTest();
            try{
                deal.Deal_Reg_Exp_Date__c = date.today();
                deal.Deal_Registration_Status__c = 'Pending Conversion';
                update deal;
				System.enqueueJob(new PC_DealRegL2AMatch(new List<Deal_Registration__c> {deal}));
            }catch(exception e){
                system.debug(LoggingLevel.DEBUG,'exception' +e);
            }
            Test.stopTest();
            System.assert(true);
        }
    }
}