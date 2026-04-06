public class SendSlackAlertsForMosaicOrders implements Queueable {

    Set<Id> pocOrderIds;
    String strSlackAlert = 'MOSAIC Order Slack Alert';
    
    public SendSlackAlertsForMosaicOrders(Set<Id> pocOrderIds) {
        this.pocOrderIds = pocOrderIds;
    }
    
    public void execute(QueueableContext context) {
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
        OrgWideEmailAddress emailAddress = [Select Id From OrgWideEmailAddress Where DisplayName = 'Salesforce Support'];
        Id senderEmailId = emailAddress.Id;

        Email_Preferences__mdt mdt = [Select Id
                                           , Receipient__c
                                           , cc__c
                                           , Email_Subject__c
                                      From Email_Preferences__mdt 
                                      Where MasterLabel = :strSlackAlert
                                      LIMIT 1
                                     ];

        for(
                Order objOrder :
                    [Select Id
                          , OrderNumber
                          , Mosaic_SKUs__c
                          , OpportunityId
                          , Opportunity.Mosaic_Customer_Environment__c
                          , Account.Name
                          , Account.Owner.Name
                          , Ship_to_Email__c
                     From Order
                     Where Id in :this.pocOrderIds
                     And Mosaic_SKUs__c != NULL
                    ]
        ){
            String orderURL = URL.getSalesforceBaseUrl().toExternalForm() + '/' + objOrder.Id;
            
            String emailTextHtmlExt = '';
            
            emailTextHtmlExt = '<p>Hello Fulfillment Team, </p> <p/> <p>Below Order requires MOSAIC fulfillment.</p>';
            emailTextHtmlExt += '<p>Account Name: ' + objOrder.Account.Name + '</p>';
            emailTextHtmlExt += '<p>Contact Email: ' + objOrder.Ship_to_Email__c + '</p>';
            emailTextHtmlExt += '<p>Account Owner: ' + objOrder.Account.Owner.Name + '</p>';
            emailTextHtmlExt += '<p>Order Number: ' + objOrder.OrderNumber + '</p>';
            emailTextHtmlExt += '<p>Order Product Details: </p>';
            
            Integer count = 1;
            for(String productCodeStr: objOrder.Mosaic_SKUs__c.split(',')){
                emailTextHtmlExt += '<p>' + count + '. ' + productCodeStr + '</p>';
                count++;
            }
            
            emailTextHtmlExt += '<p>Mosaic Customer Environment: ' + objOrder.Opportunity.Mosaic_Customer_Environment__c + '</p>';
            emailTextHtmlExt += '<p>Order Link: <a href="' + orderURL + '">' + orderURL + '</a></p>';
                          
            if (String.isNotBlank(emailTextHtmlExt)) {
                Messaging.SingleEmailMessage message = generateEmail(emailTextHtmlExt, senderEmailId, mdt);
                message.Subject += ' ' + objOrder.OrderNumber;
                messages.add(message);
            }
            
        }

        if(!messages.isEmpty()) {
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