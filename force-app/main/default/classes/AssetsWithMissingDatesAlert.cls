global class AssetsWithMissingDatesAlert implements Schedulable {
	global void execute(SchedulableContext sc) {
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