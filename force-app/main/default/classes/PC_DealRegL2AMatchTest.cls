@isTest
global class PC_DealRegL2AMatchTest implements HttpCalloutMock {
    String result;
    global PC_DealRegL2AMatchTest(String result){
        this.result = result;
    }
    global HTTPResponse respond(HTTPRequest req) {
        Id accId = [SELECT Id FROM Account LIMIT 1].Id;
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        if('SUCCESS' == result){
            res.setBody('{"requestId": "20210218074051676_SFDC", "requester": "abc@rubrik.com.rbkqa", "sourceId": "a7411000000Ie3YAAS", "results": {"accountId": "'+accId+'", "matchCriteria": "Company,Street,City,PostalCode", "matchConfidence": "3", "matchStatus": "Matched"}, "status": {"statusCode": "200", "statusDescription": "Success"}}');
            res.setStatusCode(200);
        }
        else {
            res.setStatusCode(404);  
            res.setBody('{"status": {"statusCode": "404", "statusDescription": "Service not found"}}');
        }
        return res;
    }
}