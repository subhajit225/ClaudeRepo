global class RMAOrderEmailService implements Messaging.InboundEmailHandler 
{
 global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email,Messaging.InboundEnvelope env)
 {
  // Create an InboundEmailResult object for returning the result of the Apex Email Service
  Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
  try 
  {
   string emailBody = email.plainTextBody;
   system.debug('email.plainTextBody--'+email.plainTextBody);
   String matchingCaseId = emailBody.substringAfter('refStart:').substringBefore('refEnd');
   system.debug(matchingCaseId);
   if(String.isNotBlank(matchingCaseId)) {
       Case parentCase= [SELECT Id, CaseNumber FROM Case WHERE Id = :matchingCaseId or CaseNumber=:matchingCaseId];
           system.debug('parentCaseId--'+parentCase.Id);
           if(parentCase != null) {
         // if EnhancedEmail Perm is not enabled, continue logging the email as a task

        // if EnhancedEmail Perm is enabled, create an EmailMessage object
        EmailMessage emailMessage = new EmailMessage();
        emailMessage.status = '3'; // email was sent
        emailMessage.parentId = parentCase.Id;
        emailMessage.relatedToId = parentCase.Id; // related to record e.g. an opportunity
        system.debug('email.fromAddress=='+email.fromAddress);
        emailMessage.fromAddress = email.fromAddress; // from address
        emailMessage.fromName = email.fromName; // from name
        emailMessage.subject = email.Subject; // email subject
        emailMessage.HTMlBody = email.htmlBody; // email body
        emailMessage.ToAddress = 'rmarequester@rubrik.com';
        emailMessage.CcAddress = email.fromAddress;
        // Contact, Lead or User Ids of recipients
        //String[] toIds = new String[]{'003B000000AxcEjIAJ'}; 
        //emailMessage.toIds = toIds;
        // additional recipients who don’t have a corresponding contact, lead or user id in the Salesforce org (optional)
        //emailMessage.toAddress = 'emailnotinsalesforce@toexample.com, anotherone@toexample.com';
        insert emailMessage; // insert
        
        // Add Email Message Relation for id of the sender
        EmailMessageRelation emr = new EmailMessageRelation();
        emr.emailMessageId = emailMessage.id;
        emr.relationId = '005B0000003qHvOIAU'; // user id of the sender
        emr.relationType = 'FromAddress';
        //insert emr;
        }
   }  
  }
  catch (Exception e) 
  {
     System.debug('Exception : ' + e);
  }
  result.success = true;
  return result;
 }
}