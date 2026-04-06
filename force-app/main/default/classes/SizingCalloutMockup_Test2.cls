@isTest
global class SizingCalloutMockup_Test2 implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        //System.assertEquals('http://sizing.com/example/test', req.getEndpoint()); //EXCL-6
        System.assertEquals('POST', req.getMethod());
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"data":"0066f000018HXi1,0068Y00001TThfH,0068Y00001TThKi"}');
        res.setStatusCode(500);
        res.setStatus('OK'); 
        return res;
    }
}