@isTest 
public with sharing class NCCExpiryUpdateServiceTest{
    
    static testMethod void testMethod1() {

        Account acc = new Account(Name='Test Account',Account_SAM__c = userInfo.getUserId());
        Insert acc;
        Contact con = new Contact(LastName = 'Test Contact',AccountId = acc.id,Notify_For_case_creation__c  = true);
        Insert con;
        Case csRec = new Case(AccountId = acc.Id,CEM_TSM__c = userInfo.getUserId(),Priority = 'P1',close_survey_triggered__c = false);
        Insert csRec;

        // setup controller object
        NCCExpiryUpdateService objconfirm = new NCCExpiryUpdateService();
        // Create a new email, envelope object and Attachment
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        objconfirm.handleInboundEmail(email, envelope);
        email.subject = '[NCC EXPIRED] NCC has expired on case';
        email.plainTextBody = 'refStart:'+csRec.Id+':refEnd';
        envelope.fromAddress = 'support@rubrik.com';
        objconfirm.handleInboundEmail(email, envelope);
        
        Messaging.InboundEmailResult result = objconfirm.handleInboundEmail(email, envelope);
        System.assertEquals( result.success  ,true);
    }
}