public class SendSlackAlertsForPOCOrders implements Queueable {

	Set<Id> pocOrderIds;
	public SendSlackAlertsForPOCOrders(Set<Id> pocOrderIds) {
		this.pocOrderIds = pocOrderIds;
	}
	public void execute(QueueableContext context) {
		Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
		OrgWideEmailAddress emailAddress = [Select Id from OrgWideEmailAddress where DisplayName ='Salesforce Support'];
		Id senderEmailId = emailAddress.Id;

		Email_Preferences__mdt mdt = [Select Id, Receipient__c, cc__c, Email_Subject__c from Email_Preferences__mdt where MasterLabel = 'POC Order Slack Alert' LIMIT 1];
		
		String emailTextHtml = '<p>Hi Team, Following POC Order with Cloud On/Cloud Cluster product has been shipped.</p>';
        for(Order ord: [Select Id, POC_Request__r.Product_Codes__c, OrderNumber, Type, POC_Request__r.AWS_Customer_Account_ID__c
        				from Order where Id in :this.pocOrderIds]){
        	String orderURL = URL.getSalesforceBaseUrl().toExternalForm() + '/' + ord.Id;
        	String productCodes = ord.POC_Request__r.Product_Codes__c;
        	if(String.isNotBlank(productCodes)){
        		if(productCodes.containsIgnoreCase('Cloud On') ||
        			productCodes.containsIgnoreCase('Cloud Cluster')){
        			String emailTextHtmlExt = '<p>Order Number: ' + ord.OrderNumber + '</p>';
        			emailTextHtmlExt += '<p>Order Type: ' + ord.Type + '</p>';
        			emailTextHtmlExt += '<p>Order Link: <a href="' + orderURL + '">' + orderURL + '</a></p>';
        			emailTextHtmlExt += '<p>Product Name:</p>';
        			List<String> productCodesSubStr = productCodes.split(';');
        			for(String productCodeStr: productCodesSubStr){
        				List<String> productDetails = productCodeStr.split('#');
        				if(productDetails.size() == 4 && (productDetails[3].containsIgnoreCase('Cloud On') || productDetails[3].containsIgnoreCase('Cloud Cluster'))) {
        					emailTextHtmlExt += '<p>' + productDetails[0] + ' (' + productDetails[2] + ')</p>';
        				}
        			}
        			emailTextHtmlExt += '<p>AWS Account Number:' + (ord.POC_Request__r.AWS_Customer_Account_ID__c != null ? ord.POC_Request__r.AWS_Customer_Account_ID__c : '') + '</p>';
        			String htmlBody = emailTextHtml + emailTextHtmlExt;
        			Messaging.SingleEmailMessage message = generateEmail(htmlBody, senderEmailId, mdt);
        			messages.add(message);
        		}
        	}
        }
        if(messages.size()>0){
        	Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        }
	}

	private Messaging.SingleEmailMessage generateEmail(String htmlBody, Id orgWideEmailAddressId, Email_Preferences__mdt mdt){
		Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
		message.toAddresses = new String[] { mdt.Receipient__c };
		message.setSubject(mdt.Email_Subject__c);
		message.setHtmlBody(htmlBody);
		message.setOrgWideEmailAddressId(orgWideEmailAddressId);
		if(String.isNotBlank(mdt.cc__c)){
			message.setCcAddresses(new String[] { mdt.cc__c });
		}
		return message;
	}
}