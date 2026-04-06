@isTest(SeeAllData = false)
public class EmailMessageServiceTest {
    
    @testSetup
    static void testSetUp() {
        
        Account account = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        account.Name = 'Assured Data Protection (EMEA)';
        insert account;

        Contact contact = new Contact();
        contact.Email = 'test@example.com';
        contact.FirstName = 'test';
        contact.LastName = 'example';
        insert contact;
        
        List<Case> caseList = new List<Case>();
        
        Case testCase = new Case();
        testCase.Subject = 'Test case to validate jira references';
        testCase.ContactId = contact.Id;
        testCase.Priority = 'P1';
        testCase.AccountId = account.Id;
        caseList.add(testCase);
        
        Id partnerCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Partner Case').getRecordTypeId();
        Case testCase1 = new Case();
        testCase1.Subject = 'Partner Case';
        testCase1.ContactId = contact.Id;
        testCase1.Priority = 'P1';
        testCase1.RecordTypeId = partnerCaseId;
        testCase1.AccountId = account.Id;
        caseList.add(testCase1);
        
        Case testCase2 = new Case();
        testCase2.Subject = 'Partner Closed Case';
        testCase2.ContactId = contact.Id;
        testCase2.Priority = 'P1';
        testCase2.RecordTypeId = partnerCaseId;
        testCase2.AccountId = account.Id;
        caseList.add(testCase2);
        insert caseList;
        
        testCase2.Status = 'Closed - No Action';
        update testCase2;
    }
    
    @istest
    static void testCaptureADPReferenceIdFromSupportEmail() {
        List<Case> cases = [SELECT Id FROM Case LIMIT 1];
        
        if (!cases.isEmpty()) {
            Test.startTest();
            EmailMessage message = new EmailMessage();
            message.FromAddress = Label.ADPSupportEmail;
            message.ToAddress = 'veera.gandi@rubrik.com';
            message.TextBody = 'This is for the test class. {CMI: MCIDTEST123} {CMI: MCID031752}';
            message.ParentId = cases[0].Id;
            insert message;
            Test.stopTest();
            cases = [SELECT Id, ADPReferenceId__c FROM Case LIMIT 1];
            system.assertEquals('{CMI: MCID031752}', cases[0].ADPReferenceId__c);
        }
    }
    
    @istest
    static void testCaptureADPReferenceIdFromSupportEmailNegitive() {
        List<Case> cases = [SELECT Id FROM Case LIMIT 1];
        
        if (!cases.isEmpty()) {
            Test.startTest();
            EmailMessage message = new EmailMessage();
            message.FromAddress = Label.ADPSupportEmail;
            message.ToAddress = 'veera.gandi@rubrik.com';
            message.TextBody = 'This is for the test class.';
            message.ParentId = cases[0].Id;
            insert message;
            Test.stopTest();
            cases = [SELECT Id, ADPReferenceId__c FROM Case LIMIT 1];
            system.assertEquals(null, cases[0].ADPReferenceId__c);
        }
    }

    @istest
    static void testUpdateOpptyPDFAddendumFlag() {
        ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c();
        settingDisable.Disable_Opportunity_Validation_Rules__c = true;
        insert settingDisable;
        Account acc = new Account(Name = 'Test Account');
        insert acc; 
        
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity oppo1 = new opportunity();
        oppo1.StageName = '1 Discovery';
        oppo1.closeDate = System.Today() + 30;
        oppo1.AccountId = acc.Id;
        oppo1.Name = 'Test oppo1';
        oppo1.SOW_Required__c = true;
        oppo1.Click_Thru_Contact_Email__c = 'testclickthru@rubrik.com';
        oppo1.PDF_Addendum_Email_Sent__c = true;
        oppo1.PDF_Addendum_Email_Delivered__c = false;
        oppList.add(oppo1);

        Opportunity oppo2 = new opportunity();
        oppo2.StageName = '1 Discovery';
        oppo2.closeDate = System.Today() + 30;
        oppo2.AccountId = acc.Id;
        oppo2.Name = 'Test oppo2';
        oppo2.SOW_Required__c = true;
        oppo2.Click_Thru_Contact_Email__c = 'testclickthru@rubrik.com';
        oppo2.PDF_Addendum_Email_Sent__c = true;
        oppo2.PDF_Addendum_Email_Delivered__c = false;
        oppList.add(oppo2);
        insert oppList;
        
        List<EmailMessage> emList = new List<EmailMessage>();
        EmailMessage em1 = new EmailMessage();
        em1.FromAddress = 'test12345@rubrik.com';
        em1.ToAddress = 'testclickthru@rubrik.com';
        em1.TextBody = 'This is for the test class.';
        em1.RelatedToId = oppo1.Id;
        emList.add(em1);

        EmailMessage em2 = new EmailMessage();
        em2.FromAddress = 'test12345@rubrik.com';
        em2.ToAddress = 'testclickthru@rubrik.com';
        em2.TextBody = 'This is for the test class.';
        em2.RelatedToId = oppo2.Id;
        emList.add(em2);
        insert emList;

        Test.startTest();
            EmailMessageService.updateOpportunityPDFAddendumFlag(new List<EmailMessage>{em1});
            em2.IsBounced = true;
            update em2;
            EmailMessageService.updateOpportunityPDFAddendumFlag(new List<EmailMessage>{em2});
        Test.stopTest();
        
        Opportunity opptyDel = [select Id, PDF_Addendum_Email_Delivered__c from Opportunity where Id = :oppo1.Id];
        Opportunity opptyBounced = [select Id, PDF_Addendum_Email_Sent__c from Opportunity where Id = :oppo2.Id];
        System.assertEquals(true, opptyDel.PDF_Addendum_Email_Delivered__c, 'Matched');
        System.assertEquals(false, opptyBounced.PDF_Addendum_Email_Sent__c, 'Matched');
    }
    
    @istest
    static void testCapturePartnerNewCase() {
        List<Case> cases = [SELECT Id FROM Case Where Subject = 'Partner Case' LIMIT 1];
        
        if (!cases.isEmpty()) {
            Test.startTest();
            EmailMessage message = new EmailMessage();
            message.FromAddress = Label.ADPSupportEmail;
            message.ToAddress = Label.TAPPartnerEmail;
            message.TextBody = 'This is for the test class. {CMI: MCIDTEST123} {CMI: MCID031752}';
            message.ParentId = cases[0].Id;
            message.Incoming = true;
            insert message;
            Test.stopTest();
            //cases = [SELECT Id, ADPReferenceId__c FROM Case LIMIT 1];
            //system.assertEquals('{CMI: MCID031752}', cases[0].ADPReferenceId__c);
        }
    }
    
    @istest
    static void testCapturePartnerClosedCase() {
        List<Case> cases = [SELECT Id FROM Case Where Subject = 'Partner Closed Case' LIMIT 1];
        
        if (!cases.isEmpty()) {
            Test.startTest();
            cases[0].Date_Time_Closed__c = DateTime.now().addDays(-10);
            update cases;
            
            EmailMessage message = new EmailMessage();
            message.FromAddress = Label.ADPSupportEmail;
            message.ToAddress = Label.TAPPartnerEmail;
            message.TextBody = 'This is for the test class. {CMI: MCIDTEST123} {CMI: MCID031752}';
            message.ParentId = cases[0].Id;
            message.Incoming = true;
            insert message;
            
            Test.stopTest();
            //cases = [SELECT Id, ADPReferenceId__c FROM Case LIMIT 1];
            //system.assertEquals('{CMI: MCID031752}', cases[0].ADPReferenceId__c);
        }
    }
}