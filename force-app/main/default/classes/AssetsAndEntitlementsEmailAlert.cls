global class AssetsAndEntitlementsEmailAlert implements Schedulable {
  global void execute(SchedulableContext sc) {
  
    /* List<EmailTemplate> emailtemp = [SELECT Id FROM EmailTemplate where DeveloperName IN ('Entitlements_With_Missing_Assets_Alert','Duplicate_Entitlements','Assets_with_missing_dates')];
     Email_Preferences__mdt mdt = [Select Id, Receipient__c, cc__c, Email_Subject__c from Email_Preferences__mdt where MasterLabel = 'Entitlements With Missing Assets' LIMIT 1]; 
      */
      try{
      EntitlementsWithMissingAssetsEmailAlert();
      }
      catch(exception e){
              System.debug(e.getMessage());
          }
      try{    
      DuplicateEntitlementsEmailAlert();
      }
     catch(exception e){
              System.debug(e.getMessage());
          }
     try{ 
      AssetsWithMissingDatesAlert();
      }
      catch(exception e){
              System.debug(e.getMessage());
          }     
    }
  
  global void EntitlementsWithMissingAssetsEmailAlert(){
   EntitlementsWithMissingAssetsController controllerObj = new EntitlementsWithMissingAssetsController();

    if(controllerObj.pages != null && controllerObj.pages > 0) {
      EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Entitlements_With_Missing_Assets_Alert'];
      Email_Preferences__mdt mdt = [Select Id, Receipient__c, cc__c, Email_Subject__c from Email_Preferences__mdt where MasterLabel = 'Entitlements With Missing Assets' LIMIT 1];
      User u = [Select Id from User where IsActive = true and Email = :mdt.Receipient__c LIMIT 1];
      Messaging.SingleEmailMessage email = 
            Messaging.renderStoredEmailTemplate(et.Id, u.Id, null);
            List<String> ccAddresses = new List<String>();
            if(mdt.cc__c != null){
              for(String address: mdt.cc__c.split(',')){
                ccAddresses.add(address.trim());
              }
          }
            email.setCcAddresses(ccAddresses);
      email.setSaveAsActivity(false);
      try{
              Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
          }catch(exception e){
              //apexpages.addmessage(new apexpages.message(apexpages.severity.error,e.getMessage()));
              System.debug(e.getMessage());
          }
    }
  
  }
  global void DuplicateEntitlementsEmailAlert(){
     DuplicateEntitlementsController controllerObj = new DuplicateEntitlementsController();

    if(controllerObj.duplicateMap != null && controllerObj.duplicateMap.size() > 0) {
      EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Duplicate_Entitlements'];
      Email_Preferences__mdt mdt = [Select Id, Receipient__c, cc__c, Email_Subject__c from Email_Preferences__mdt where MasterLabel = 'DuplicateEntitlement' LIMIT 1];
      User u = [Select Id from User where IsActive = true and Email = :mdt.Receipient__c LIMIT 1];
      Messaging.SingleEmailMessage email = 
            Messaging.renderStoredEmailTemplate(et.Id, u.Id, null);
            List<String> ccAddresses = new List<String>();
            if(mdt.cc__c != null){
              for(String address: mdt.cc__c.split(',')){
                ccAddresses.add(address.trim());
              }
          }
            email.setCcAddresses(ccAddresses);
      email.setSaveAsActivity(false);
      try{
              Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
          }catch(exception e){
              //apexpages.addmessage(new apexpages.message(apexpages.severity.error,e.getMessage()));
              System.debug(e.getMessage());
          }
    }
  }
  global void AssetsWithMissingDatesAlert(){
    AssetsWithMissingDatesController controllerObj = new AssetsWithMissingDatesController();

    if(controllerObj.pages != null && controllerObj.pages > 0) {
      EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Assets_with_missing_dates'];
      Email_Preferences__mdt mdt = [Select Id, Receipient__c, cc__c, Email_Subject__c from Email_Preferences__mdt where MasterLabel = 'Assets without dates' LIMIT 1];
      User u = [Select Id from User where IsActive = true and Email = :mdt.Receipient__c LIMIT 1];
      Messaging.SingleEmailMessage email = 
            Messaging.renderStoredEmailTemplate(et.Id, u.Id, null);
            List<String> ccAddresses = new List<String>();
            if(mdt.cc__c != null){
              for(String address: mdt.cc__c.split(',')){
                ccAddresses.add(address.trim());
              }
          }
            email.setCcAddresses(ccAddresses);
      email.setSaveAsActivity(false);
      try{
              Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
          }catch(exception e){
             //apexpages.addmessage(new apexpages.message(apexpages.severity.error,e.getMessage()));
             System.debug(e.getMessage());
          }
    }
  }
  
}