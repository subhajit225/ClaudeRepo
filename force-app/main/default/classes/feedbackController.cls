public without sharing class feedbackController {

    
    @AuraEnabled
    public static FieldsWrapper getFields(){
        FieldsWrapper Fields = new FieldsWrapper();
        return Fields;
    }
    public static String getEmailTemplate(FieldsWrapper Fields)
    {
        EmailTemplate template = [Select id,DeveloperName,HtmlValue from EmailTemplate where developername ='Feedback_Form_template' limit 1];
         String htmlBody = template.HtmlValue;
         htmlBody = htmlBody.replace('[EmailBody]','<b>User Provide the feedback about  :</b>'  + Fields.Type + '<br/><br/><b>User feedback : </b>' + Fields.Description); 
        htmlBody = htmlBody.replace('[Username]', Fields.Username);            
        template.HtmlValue = htmlBody;
        return htmlBody;
    }
    public static String getUsername()
    {
        List<User> oUser = [select Id,Name FROM User Where id =: userInfo.getUserId()];
        return oUser[0].Name;
    }
    @AuraEnabled
    public static void SaveForm(String wrappers)
    {
        FieldsWrapper Fields = (FieldsWrapper)json.deserialize(wrappers, FieldsWrapper.class);
      	List<OrgWideEmailAddress> FromEmailAddress = [Select Id,Address FROM OrgWideEmailAddress WHERE DisplayName = 'No Reply'];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = new String[] {'support-portal-feedback@rubrik.com'};
        mail.setToAddresses(toAddresses);     
		mail.setSubject(Fields.Subject);
		mail.setHtmlBody(feedbackController.getEmailTemplate(Fields));
        mail.setOrgWideEmailAddressId(FromEmailAddress[0].Id);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });		
    }
    
      public class FieldsWrapper
      {
          @AuraEnabled public String Type;
          @AuraEnabled public String Subject;
          @AuraEnabled public String Description;
          @AuraEnabled public String Username;
          
          public FieldsWrapper()
          {
              Type='';
              Subject='';
              Description='';
              Username = feedbackController.getUsername();
          }
    }
    
}