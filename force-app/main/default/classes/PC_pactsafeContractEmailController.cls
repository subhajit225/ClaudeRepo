public class PC_pactsafeContractEmailController {
    public static void sendEmail(string termsurl,string contId,string contractId){
        List<Contact> con = new List<Contact>();
        if(!string.isBlank(contId)){
            con = [select Id,firstName,LastName,Email from Contact where Id =: contId];
        }
        if(!con.isEmpty()){
            EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'PC_PactsafeContractEmailTemplate'];
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateId(et.id);
            mail.setwhatId(contractId);
            mail.setSaveAsActivity(false);
            mail.setTargetObjectId(contId);
            mail.setSenderDisplayName('Rubrik Support');
            //mail.setSubject('Acknowledgement on Accepting Rubrik Agreement');
            //String messageBody = '<html><body>Hello '+con[0].firstName+',<br/><br/>Thank you for updating your Rubrik Master Agreement. We appreciate your partnership and look forward to continued joint success.<br/>Please find below links to the agreements.'+termsurl+'<br/><br/>Thank you,<br/>The Rubrik Partner Team.</body></html>';
            //mail.setHtmlBody(messageBody); 
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
}