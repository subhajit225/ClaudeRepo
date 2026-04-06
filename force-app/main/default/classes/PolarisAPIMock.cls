global class PolarisAPIMock implements HttpCalloutMock {
    /*global HTTPResponse respond(HTTPRequest req) {
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"access_token":"test"}');
        res.setStatusCode(200);
        return res;
    }
     global HTTPResponse respond1(HTTPRequest req) {
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"access_token":"test"}');
        res.setStatusCode(400);
        return res;
    }*/
    global Integer statusCode;
    global String responseBody;
    
   global PolarisAPIMock(Integer statusCode, String responseBody) {
        this.statusCode = statusCode;
        this.responseBody = responseBody;
    }
    
   global  HTTPResponse respond(HTTPRequest req) {
        HTTPResponse res = new HTTPResponse();
        res.setStatusCode(statusCode);
        res.setBody(responseBody);
        return res;
    }

}