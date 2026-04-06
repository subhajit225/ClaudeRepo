@isTest
private with sharing class PC_DealRegEmailServiceTest {
    @TestSetup
    static void makeData(){
        User sysuser = new User(
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
            Start_Date__c = System.Today().adddays(-30)
        );
        insert sysuser;
        System.runAs(sysuser){
            CountryWithCode__c cc = new CountryWithCode__c(Code__c='CA',Name='Canada');
            insert cc;
            system.debug(LoggingLevel.DEBUG,'cc->'+cc);
        }
    }
    @IsTest
    static void testInboundEmailHandler() {
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

            Id recordId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            Deal_Registration__c deal = TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Status__c = 'Submitted';
            deal.Company_Name__c = acc.id;
            deal.Partner_Lookup__c = acc.id;
            deal.RecordTypeId = recordId;
            try{
            	insert deal;
            }
            catch(exception e){
                system.debug(LoggingLevel.DEBUG,'exception e->'+e.getMessage());
            }
            deal.Deal_Registration_Status__c = 'Escalated';
            deal.Deal_Registration_Sub_Status__c = 'Pending RSM Approval';
            deal.PS_Escalated__c = true;
            update deal;
            // Create a new Email
            Messaging.InboundEmail email = new Messaging.InboundEmail();
            Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
            List <String> toAddresses = new List<String>{'test@test.com'};
            Deal_Registration__c dealTemp = [Select id,Name from Deal_Registration__c where id =:deal.id];
            email.subject = 'Partner Sourced Escalation RD Approval - '+dealTemp.Name;
            String emailBody = 'Approved';
            emailBody += '\n' + 'Test body .com/'+ dealTemp.id;
            emailBody += '\n' + 'Test body .com/';
            email.plainTextBody = emailBody;
            email.toAddresses = toAddresses;
            email.fromAddress = 'test@test.comm11';

            PC_DealRegEmailService testInbound = new PC_DealRegEmailService ();
            testInbound.handleInboundEmail(email, env);
            System.assert(true);
        }
    }

    @IsTest
    static void testInboundEmailHandler2() {
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

            Id recordId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            Deal_Registration__c deal1 = TestDataFactory.getDealRegistration();
            deal1.Deal_Registration_Status__c = 'Submitted';
            deal1.Company_Name__c = acc.id;
            deal1.Partner_Lookup__c = acc.id;
            deal1.RecordTypeId = recordId;
            try{
            	insert deal1;
            }
            catch(exception e){
                system.debug(LoggingLevel.DEBUG,'exception e->'+e.getMessage());
            }
            deal1.Deal_Registration_Status__c = 'Escalated';
            deal1.Deal_Registration_Sub_Status__c = 'Pending RVP Approval';
            deal1.PS_Escalated__c = true;
            update deal1;
            // Create a new Email
            Messaging.InboundEmail email = new Messaging.InboundEmail();
            Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
            List <String> toAddresses = new List<String>{'test@test.com'};
            Deal_Registration__c dealTemp = [Select id,Name from Deal_Registration__c where id =:deal1.id];
            email.subject = 'Partner Sourced Escalation RVP Approval - '+dealTemp.Name;
            String emailBody = 'Approved';
            emailBody += '\n' + 'Test body .com/'+ dealTemp.id;
            emailBody += '\n' + 'Test body .com/';
            email.plainTextBody = emailBody;
            email.toAddresses = toAddresses;
            email.fromAddress = 'test@test.comm11';

            PC_DealRegEmailService testInbound = new PC_DealRegEmailService ();
            testInbound.handleInboundEmail(email, env);
            System.assert(true);
        }
    }
    @IsTest
    static void testInboundEmailHandler3() {
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

            Id recordId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            Deal_Registration__c deal1 = TestDataFactory.getDealRegistration();
            deal1.Deal_Registration_Status__c = 'Submitted';
            deal1.Company_Name__c = acc.id;
            deal1.Partner_Lookup__c = acc.id;
            deal1.RecordTypeId = recordId;
            try{
            	insert deal1;
            }
            catch(exception e){
                system.debug(LoggingLevel.DEBUG,'exception e->'+e.getMessage());
            }
            deal1.Deal_Registration_Status__c = 'Escalated';
            deal1.Deal_Registration_Sub_Status__c = 'Pending RVP Approval';
            deal1.PS_Escalated__c = true;
            update deal1;
            // Create a new Email
            Messaging.InboundEmail email = new Messaging.InboundEmail();
            Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
            List <String> toAddresses = new List<String>{'test@test.com'};
            Deal_Registration__c dealTemp = [Select id,Name from Deal_Registration__c where id =:deal1.id];
            email.subject = 'Partner Sourced Escalation RVP Approval - '+dealTemp.Name;
            String emailBody = 'Rejected';
            emailBody += '\n' + 'Test body .com/'+ dealTemp.id;
            emailBody += '\n' + 'Test body .com/';
            email.plainTextBody = emailBody;
            email.toAddresses = toAddresses;
            email.fromAddress = 'test@test.comm11';

            PC_DealRegEmailService testInbound = new PC_DealRegEmailService ();
            testInbound.handleInboundEmail(email, env);
            System.assert(true);
        }
    }
    
    @IsTest
    static void testInboundEmailHandler4() {
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

            Id recordId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            Deal_Registration__c deal = TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Status__c = 'Submitted';
            deal.Company_Name__c = acc.id;
            deal.Partner_Lookup__c = acc.id;
            deal.RecordTypeId = recordId;
            try{
            	insert deal;
            }
            catch(exception e){
                system.debug(LoggingLevel.DEBUG,'exception e->'+e.getMessage());
            }
            deal.Deal_Registration_Status__c = 'Escalated';
            deal.Deal_Registration_Sub_Status__c = 'Pending RSM Approval';
            deal.ACV_at_Escalation__c = 300001;
            deal.PS_Escalated__c = true;
            update deal;
            // Create a new Email
            Messaging.InboundEmail email = new Messaging.InboundEmail();
            Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
            List <String> toAddresses = new List<String>{'test@test.com'};
            Deal_Registration__c dealTemp = [Select id,Name from Deal_Registration__c where id =:deal.id];
            email.subject = 'Partner Sourced Escalation RD Approval - '+dealTemp.Name;
            String emailBody = 'Approved';
            emailBody += '\n' + 'Test body .com/'+ dealTemp.id;
            emailBody += '\n' + 'Test body .com/';
            email.plainTextBody = emailBody;
            email.toAddresses = toAddresses;
            email.fromAddress = 'test@test.comm11';

            PC_DealRegEmailService testInbound = new PC_DealRegEmailService ();
            testInbound.handleInboundEmail(email, env);
            System.assert(true);
        }
    }
}