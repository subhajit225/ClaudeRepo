/**
 * @description EmailHelper to send email notifications
 * @Developer    Rubrik Dev
 * @Test Class   EmailHelper_Test
 */
public class EmailHelper {
    public static String DEFAULT_SENDER = 'salesops@rubrik.com';
    public static String DEFAULT_NAME = 'Sales Ops';

    /**
     * @description set clean and expected line breaks in visualforce templates
     */
    public String NewLine {
        get { return '\r\n'; }
        set;
    }

    /**
     * @description method to send email
     * @param templateId
     * @param userIds
     * @param whatId
     */
    public static void sendEmail(Id templateId, Id[] userIds, Id whatId){
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            //List<Messaging.SingleEmailMessage>﻿ mails = new List<Messaging.SingleEmailMessage>﻿();
            for(Id vUserId: userIds){
                Messaging.SingleEmailMessage email = sendEmail(templateId, vUserId, whatId);
                mails.add(email);
            }
            if(!Test.isRunningTest()) {
                try{
                    Messaging.SendEmailResult[] r = Messaging.sendEmail(mails);
                }Catch(Exception err){
                    system.debug(LoggingLevel.DEBUG, '@@ exception '+err.getMessage());
                }
            }
        
    }
    /**
     * @description method to send email
     * @param templateId
     * @param userId
     * @param whatId
     * @return email
     */
    public static Messaging.SingleEmailMessage sendEmail(Id templateId, Id userId, Id whatId){
        
        Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(templateId, userId, whatId);
        String emailSubject = email.getSubject();
        String emailTextBody = email.getPlainTextBody();
        
        email.setTargetObjectId(userId);
        email.setSubject(emailSubject);
        email.setPlainTextBody(emailTextBody);
        email.saveAsActivity = false;
        return email;
        
        
        
    }
 
/* It is useful code can be use is later when Template is not in place.
    public static Messaging.SingleEmailMessage getSingleEmailMessageObject(Set<String> toUserIds, Set<String> ccUserIds, Set<String> bccUserIds, String subjectText, String htmlTextBody){
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        if(toUserIds!= null){
            toUserIds.remove(null);
            toUserIds.remove('null');
            String[] toUserIds1 = new List<String>(toUserIds);
            email.setToAddresses(toUserIds1);//A list of email addresses or object IDs of the contacts, leads, and users you’re sending the email to. 
        }
        if(ccUserIds!= null){
            ccUserIds.remove(null);
            ccUserIds.remove('null');
            String[] ccUserIds1 = new List<String>(ccUserIds);
            email.setCCAddresses(ccUserIds1);
        } 
        if(bccUserIds!= null){
            bccUserIds.remove(null);
            bccUserIds.remove('null');
            String[] bccUserIds1 = new List<String>(bccUserIds);
            email.setBCCAddresses(bccUserIds1);
        }
        email.setSubject(subjectText);
        email.setHtmlBody(htmlTextBody);
        email.setPlainTextBody(htmlTextBody);
        email.saveAsActivity = false;
        return email;
    }
*/
   /**
     * @description method to prepare email body
     * @param toUserIds
     * @param ccUserIds
     * @param bccUserIds
     * @param fromUserId
     * @param recordIdToMailMerge
     * @param templateId
     * @return email
     */
    public static Messaging.SingleEmailMessage getSingleEmailMessageObj(Set<String> toUserIds, Set<String> ccUserIds, Set<String> bccUserIds, Id fromUserId, Id recordIdToMailMerge, Id templateId){
        //1. Email Alert does not allow Parent Record's user fields to set as recipient.
        //2. Email Template does not allow Parent Record's field to be merged.
        Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(templateId, fromUserId, recordIdToMailMerge);
        String emailSubject = email.getSubject();
        String emailTextBody = email.getHtmlBody();        
        if(toUserIds!= null){
            toUserIds.remove(null);
            toUserIds.remove('null');
            String[] toUserIds1 = new List<String>(toUserIds);
            email.setToAddresses(toUserIds1);//A list of email addresses or object IDs of the contacts, leads, and users you’re sending the email to. 
        }
        if(ccUserIds!= null){
            ccUserIds.remove(null);
            ccUserIds.remove('null');
            String[] ccUserIds1 = new List<String>(ccUserIds);
            email.setCCAddresses(ccUserIds1);
        } 
        if(bccUserIds!= null){
            bccUserIds.remove(null);
            bccUserIds.remove('null');
            String[] bccUserIds1 = new List<String>(bccUserIds);
            email.setBCCAddresses(bccUserIds1);
        }
        email.setSubject(emailSubject);
        email.setPlainTextBody(email.getPlainTextBody());
        email.setHtmlBody(email.getHtmlBody());
        email.saveAsActivity = false;
        return email;
    }
  
    
    /**
     * @description method to send email
     * @param toEmail
     * @param dealRegId
     * @param whtId
     */
    public static void sendCDMAlert(String toEmail, Id dealRegId, Id whtId){
        System.debug(LoggingLevel.DEBUG,'@@sendCDMAlert');
        List<string> toAddress = new List<string>();
        String[] emailList= toEmail.split(',');
        System.debug(LoggingLevel.DEBUG,'@@emailList'+emailList);
        for(String email : emailList){
            System.debug(LoggingLevel.DEBUG,'@@email'+email);
            toAddress.add(email);
        }
      
        OrgWideEmailAddress owa = [select id, DisplayName, Address from OrgWideEmailAddress limit 1];
        EmailTemplate templateId = [Select id from EmailTemplate where name = 'CDM Alert'];
        
        List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        mail.setTemplateID(templateId.Id); 
        mail.setSaveAsActivity(false);
        mail.setToAddresses(toAddress);
        mail.setWhatId(dealRegId);
        mail.setTargetObjectId(whtId);
        //allmsg.add(mail);
        //Messaging.sendEmail(allmsg,false);
        try{
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }Catch(Exception err){
            system.debug(LoggingLevel.DEBUG, '@@ exception '+err.getMessage());
        }
    }
    /**
     * @description method to get template id
     * @param templateName
     * @return Id
     */
    public static ID getEmailTemplateID(String templateName){
        return [Select id from EmailTemplate where name = :templateName].id;
    }
    /**
     * @description method to set email body
     * @param emailIdList
     * @param emailTemplate
     * @param whatIdContact
     * @param whatIdObject
     * @param singleEmailList
     * @return emailMsg
     */
    public static Messaging.SingleEmailMessage setSingleEmailMessage(List<String> emailIdList, ID emailTemplate, ID whatIdContact, ID whatIdObject, List<Messaging.SingleEmailMessage> singleEmailList){
        Messaging.SingleEmailMessage emailMsg = new Messaging.SingleEmailMessage();
        emailMsg.setTemplateID(emailTemplate); 
        emailMsg.setSaveAsActivity(false);
        emailMsg.setToAddresses(emailIdList);//A list of email addresses or object IDs of the contacts, leads, and users you’re sending the email to. 
        emailMsg.setWhatId(whatIdObject);
        emailMsg.setTargetObjectId(whatIdContact);
        if(singleEmailList!= null){
            singleEmailList.add(emailMsg);
        }
        //Messaging.sendEmail(singleEmailList);
        return emailMsg;
    }

    /**
     * @description method to set email body
     * @param recepientUserIdSet
     * @param subjectText
     * @param bodyText
     */
    public static void sendEmailNotification(Set<Id> recepientUserIdSet, String subjectText, String bodyText) {
        Messaging.SingleEmailMessage emailDraft = new Messaging.SingleEmailMessage();
        emailDraft.setSubject(subjectText);
        emailDraft.setHtmlBody(bodyText);
        emailDraft.setPlainTextBody(bodyText);
        sendEmailNotification(recepientUserIdSet, emailDraft);
    }
    /**
     * @description method to send email
     * @param recepientUserIdSet
     * @param emailDraft
     */
    private static void sendEmailNotification(Set <Id> recepientUserIdSet, Messaging.SingleEmailMessage emailDraft) {
        List < Messaging.SingleEmailMessage > emailList = new List < Messaging.SingleEmailMessage > ();
        for (ID recepientId: recepientUserIdSet) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setTargetObjectId(recepientId);
            email.setSubject(emailDraft.getSubject());
            email.setHtmlBody(emailDraft.getHtmlBody());
            email.setPlainTextBody(emailDraft.getPlainTextBody());
            email.saveAsActivity = false;
            emailList.add(email);
        }
        try{
            Messaging.SendEmail(emailList);
        }Catch(Exception err){
            system.debug(LoggingLevel.DEBUG, '@@ exception '+err.getMessage());
        }
    }
    /**
     * @description SAL25-625 method to send email
     * @param toAddresses
     * @param subject
     * @param body
     */
    public static void sendBatchErrorsEmail(List<String> toAddresses, String subject, String body){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);
        mail.setSubject(subject);
        mail.setHtmlBody(body);
        mail.setSaveAsActivity(false);
        try{
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }Catch(Exception err){
            system.debug(LoggingLevel.DEBUG, '@@ exception '+err.getMessage());
        }
    }
    /**
     * @description SAL25-717 method to set email body
     * @param errLogs
     * @return messageBody
     */
        public static string prepareEmailBodyForCustomErrorLog(List<Custom_Error_Log__c> errLogs){
            String messageBody = 'Below is the list of errors: <br/><br/>';
            if(!errLogs.isEmpty()){
                messageBody += '<b>Error Log Records:</b> <br/>';
                for (Custom_Error_Log__c log : errLogs) {
                    String logRecordUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + log.Id;
                    messageBody += '<b><a href="' + logRecordUrl + '">' + logRecordUrl + '</a></b><br/>';
                }
                messageBody += '<br/>';
            }
            
            messageBody += 'Thank you';
            return messageBody;
        }
}