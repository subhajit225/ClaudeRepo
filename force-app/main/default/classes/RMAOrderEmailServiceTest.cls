@isTest(SeeAllData=true)
public class RMAOrderEmailServiceTest{
    public static testMethod void EmailAttachmentTester(){
        
        Case caseRecord = [select id, CaseNumber from Case where Account.Name Like 'Rubrik%' LIMIT 1];
        
        // setup controller object
        RMAOrderEmailService objconfirm = new RMAOrderEmailService();
        // Create a new email, envelope object and Attachment
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        objconfirm.handleInboundEmail(email, envelope);
        
        email.subject = 'Flash Email';
        email.plainTextBody = 'Hello, this a test email body for Smart Hands Testing  Rubrik Case Reference refStart:'+caseRecord.Id+'refEnd';
        envelope.fromAddress = 'maf@cloudsocius.com';
        //Messaging.InboundEmail.BinaryAttachment[] binaryAttachments = new Messaging.InboundEmail.BinaryAttachment[2];
        Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
        objconfirm.handleInboundEmail(email, envelope);
        
        Messaging.InboundEmailResult result = objconfirm.handleInboundEmail(email, envelope);
        System.assertEquals( result.success  ,true);
        
    }
}