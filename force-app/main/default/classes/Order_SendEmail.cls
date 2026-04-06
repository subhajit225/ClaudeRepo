global class Order_SendEmail{
    @AuraEnabled
    webService static boolean sendemailToFlash(Id orderId){
            system.debug('Input--> OrderId'+orderId);
            List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
            Email_Preferences__mdt emailPref = [select From__c, Receipient__c,cc__c from Email_Preferences__mdt where DeveloperName = 'FlashOrder' limit 1];
            Id emailTemplateId = [select Id from EmailTemplate where DeveloperName ='FlashOrderDetails' limit 1].id;
            Id fromEmailId = [select Id from OrgWideEmailAddress where Address =: emailPref.From__c limit 1].id;
            Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(emailTemplateId, UserInfo.getUserId(), orderId);
            message.OrgWideEmailAddressId = fromEmailId;
            message.setTreatTargetObjectAsRecipient(false);  
            Messaging.renderStoredEmailTemplate(emailTemplateId, UserInfo.getUserId(), orderId);
           // message.toAddresses = new String[] {'chaitra.padashetty@rubrik.com','orders1234@flashglobal.com'};
           message.toAddresses = new String[] { emailPref.Receipient__c};
        // added for PRDOPS22_147
            List<String> ccAddresses = emailPref.cc__c.split(',');
            message.setCcAddresses(ccAddresses);
            message.saveAsActivity = false;
            allmsg.add(message);
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(allmsg,false);
            system.debug('Email Error-->'+results[0].getErrors());
            return results[0].success ;  
        
    }
}