@isTest
global class GenericMockHttpResponseGenerator implements HttpCalloutMock {
   
    global string conType,jsonRes ;
    global Integer statusCode;
    global GenericMockHttpResponseGenerator(string conType,string jsonRes,Integer statusCode){
    this.conType = conType;
    this.jsonRes = jsonRes;
    this.statusCode = statusCode;
    }
    global HTTPResponse respond(HTTPRequest req) {
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', conType);
        res.setBody(jsonRes);
        
        res.setStatusCode(statusCode);
        return res;
    }
}