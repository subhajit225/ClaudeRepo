global  class UpdateEmailMessageBatch implements Database.Batchable<SObject>,Database.Stateful,Database.AllowsCallouts
{
    String dynamicquery;
    public UpdateEmailMessageBatch(String dynamicquery){
        this.dynamicquery=dynamicquery;
    }
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        String query ='select id, E2CAdv__Long_Comments_Id__r.CreatedDate,E2CAdv__Comment_Source__c,E2CAdv__Long_Comments_Id__c,E2CAdv__Entity_Id__c,E2CAdv__Long_Comments_Id__r.CreatedByID,E2CAdv__Long_Comments_Id__r.CreatedBy.Email,E2CAdv__Long_Comments_Id__r.E2CAdv__To_Address__c,E2CAdv__Long_Comments_Id__r.E2CAdv__Cc_Address__c,   E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c,E2CAdv__Long_Comments_Id__r.E2CAdv__Bcc_Address__c,  E2CAdv__Long_Comments_Id__r.E2CAdv__From_Name__c,E2CAdv__Long_Comments_Id__r.E2CAdv__Long_Subject__c, E2CAdv__Long_Comments_Id__r.E2CAdv__File_Ids__c,E2CAdv__Long_Comments_Id__r.E2CAdv__Comment_Status__c, E2CAdv__Long_Comments_Id__r.E2CAdv__Is_Incoming__c,E2CAdv__Long_Comments_Id__r.E2CAdv__Watchers__c, E2CAdv__Long_Comments_Id__r.E2CAdv__Published__c,E2CAdv__Long_Comments_Id__r.E2CAdv__Comment_Body__c from E2CAdv__CommentSourceControllers__c ';
        query=query+dynamicquery;
        if(query!=null && String.isNotBlank(query)){
            return Database.getQueryLocator(query);
        }else{
            return null;
        }
    }

    global void execute(Database.BatchableContext BC,List<E2CAdv__CommentSourceControllers__c> data)
    {

        List<EmailMessage> emailForOutgoingList = new List<EmailMessage>();
        E2CAdv__E2CAConfiguration__c setting = E2CAdv__E2CAConfiguration__c.getInstance('E2C Advance Configuration');
        List<String> emailTocscIdList = new List<String>();
        List<String> cscIdList = new List<String>();
        for(E2CAdv__CommentSourceControllers__c  csc:data){
            cscIdList.add(csc.Id);
        }
        for(EmailMessage em: [Select id, Source_Controller_Id__c from EmailMessage where Source_Controller_Id__c IN: cscIdList]){
            emailTocscIdList.add(em.Source_Controller_Id__c);
        }
        if(data!=null && !data.isEmpty()){
            for(E2CAdv__CommentSourceControllers__c  csc:data){
                if(!emailTocscIdList.contains(csc.Id)){
                    EmailMessage emailMessage = new EmailMessage();
                    emailMessage.status = '3'; // email was sent
                    emailMessage.ParentId = csc.E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c;
                    String userEmail=csc.E2CAdv__Long_Comments_Id__r.CreatedBy.Email;
                    System.debug('userEmail'+userEmail);
                    // User GetEmail=[select Id,Email from user where Id=:userEmail limit 1];
                    emailMessage.fromAddress = userEmail;
                    emailMessage.fromName = csc.E2CAdv__Long_Comments_Id__r.E2CAdv__From_Name__c;
                    emailMessage.toAddress = csc.E2CAdv__Long_Comments_Id__r.E2CAdv__To_Address__c;
                    String watchers = String.isNotBlank(csc.E2CAdv__Long_Comments_Id__r.E2CAdv__Watchers__c)?csc.E2CAdv__Long_Comments_Id__r.E2CAdv__Watchers__c:'';
                    String ccAddresses = String.isNotBlank(csc.E2CAdv__Long_Comments_Id__r.E2CAdv__Cc_Address__c)?csc.E2CAdv__Long_Comments_Id__r.E2CAdv__Cc_Address__c:'';
                    if (String.isNotBlank(watchers)) {
                        ccAddresses += ';' + watchers;
                    }
                    emailMessage.ccAddress = ccAddresses;
                    emailMessage.bccAddress = csc.E2CAdv__Long_Comments_Id__r.E2CAdv__Bcc_Address__c;
                    emailMessage.CreatedById = csc.E2CAdv__Long_Comments_Id__r.CreatedById;
                    emailMessage.CreatedDate = csc.E2CAdv__Long_Comments_Id__r.CreatedDate;
                    emailMessage.MessageDate = csc.E2CAdv__Long_Comments_Id__r.CreatedDate;
                    String commentTemplateId = '';
                    if(csc.E2CAdv__Long_Comments_Id__r.E2CAdv__Published__c){
                        commentTemplateId = setting.E2CAdv__CaseCommentTemplateId__c;
                    }
                    else{
                        commentTemplateId = setting.E2CAdv__PrivateCaseCommentTemplateId__c;
                    }
                    Messaging.SingleEmailMessage message1 =  Messaging.renderStoredEmailTemplate(commentTemplateId,userInfo.getUserId() , csc.E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c);
                    String emailSubject = (String)message1.getSubject();
                    emailMessage.Subject = emailSubject;

                    emailMessage.Incoming = csc.E2CAdv__Long_Comments_Id__r.E2CAdv__Is_Incoming__c;
                    emailMessage.Source_Controller_Id__c = csc.id;
                    emailForOutgoingList.add(emailMessage);
                }
            }

            if(emailForOutgoingList.size()>0){
                E2CAdv.ManagementClass.isEmailMsgRecursion = true;
                E2CAdv.ManagementClass.stopOutgoingMailSave = false;
                try{
                    insert emailForOutgoingList;
                }
                catch(Exception e){
                    System.debug('<b>Cause :</b> ' + e.getCause() + '<br/><br/> <b>Line Number:</b> ' + e.getLineNumber() + '<br/> <b>Error Message:</b> ' + e.getMessage() + '<br/> <b>Stack trace:</b>' + e.getStackTraceString() + '<br/> <b>Exception Type:</b> ' + e.getTypeName());
                }
            }
        }
    }

    global void finish(Database.BatchableContext BC){

    }
}