@isTest
public class SandboxRefreshEMaskWorkFlowAlertMock implements HttpCalloutMock {
    // Implement this interface method
    public HTTPResponse respond(HTTPRequest req) {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        string domainUrl = URL.getSalesforceBaseUrl().toExternalForm();
        String emailAlertJSONParser = domainUrl+'/services/data/v51.0/tooling/query/?q=SELECT+id,+EntityDefinitionId,+EntityDefinition.DeveloperName+,+DeveloperName,+CcEmails,+senderType,+TemplateId,+Description+FROM+WorkFlowAlert+WHERE+CcEmails+!=NULL+LIMIT+1';
        // Create a fake response
        HttpResponse res = new HttpResponse();
        if(emailAlertJSONParser.contains(req.getEndpoint())) {
            System.assertEquals(emailAlertJSONParser, req.getEndpoint());
            System.assertEquals('GET', req.getMethod());
            
            res.setHeader('Content-Type', 'application/json');
            String responseBody = '{"size" : 1,  "totalSize" : 1,  "done" : true,  "queryLocator" : null,  "entityTypeName" : "WorkflowAlert",';
            responseBody += '"records" : [ { "attributes" : {   "type" : "WorkflowAlert", "url" : "/services/data/v51.0/tooling/sobjects/WorkflowAlert/01W1W0000004shjUAA"},';
            responseBody += '"Id" : "01W1W0000004shjUAA","EntityDefinitionId" : "Opportunity", "EntityDefinition" : { "attributes" : { "type" : "EntityDefinition", "url" : "/services/data/v51.0/tooling/sobjects/EntityDefinition/Opportunity" },';
            responseBody += '"DeveloperName" : "Opportunity" }, "DeveloperName" : "Opportunity_Holdover_Extension_Approval_Email_Notification", "CcEmails" : "****@example.com", "SenderType" : "CurrentUser", "TemplateId" : "00X1W000001EA8UUAW",';
            responseBody += '"Description" : "Opportunity Holdover Rejection Email Notification"} ]}';
            res.setBody(responseBody);
            
            res.setStatusCode(200);
        }
        else if(!emailAlertJSONParser.contains(req.getEndpoint()) && req.getMethod() == 'GET') {
            // Create a fake response
            res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String responseBody =		'{'+
                '"Metadata" : {'+
                '    "ccEmails" : [ "****@example.com.invalid," ],'+
                '    "description" : "Opportunity Holdover Rejection Email Notification",'+
                '    "protected" : false,'+
                '    "recipients" : [ {'+
                '      "field" : null,'+
                '      "recipient" : "pavan.m@rubrik.com",'+
                '      "type" : "user"'+
                '    }, {'+
                '      "field" : null,'+
                '      "recipient" : "raghavendra.pavan@rubrik.com",'+
                '      "type" : "user"'+
                '    } ],'+
                '    "senderAddress" : null,'+
                '    "senderType" : "CurrentUser",'+
                '    "template" : "Sales_Operations/Opportunity_Holdover_Request_Rejection",'+
                '    "urls" : null'+
                ' }'+
                '}';
            //String responseBody = '{"Metadata" : {"ccEmails" : ["****@example.com"],"description" : "Opportunity Holdover Rejection Email Notification","template" : "Test/Opportunity_Holdover_Extension_Approval_Email_Notification","senderType" : "CurrentUser"}}';
            res.setBody(responseBody);
            
            res.setStatusCode(200);
        }
        else if(!emailAlertJSONParser.contains(req.getEndpoint()) && req.getMethod() == 'PATCH') {
            System.assertEquals(domainUrl+'/services/data/v51.0/tooling/sobjects/WorkflowAlert/01W1W0000004shjUAA', req.getEndpoint());
            System.assertEquals('PATCH', req.getMethod());
            
            // Create a fake response
            res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String responseBody = '{"Metadata" : {"ccEmails" : ["****@example.com"],"description" : "Opportunity Holdover Rejection Email Notification","template" : "Test/Opportunity_Holdover_Extension_Approval_Email_Notification","senderType" : "CurrentUser"}}';
            res.setBody(responseBody);
            
            res.setStatusCode(200);
        }
        return res;
    }
}