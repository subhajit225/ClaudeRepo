@isTest
global class CustomerTemperatureControllerMock implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        if(req.getEndpoint().contains('getBlastResults')){
            res.setBody('<?xml version="1.0"?><thermometer_blast_responses> <thermometer_blast_response> <response>Gold Star</response> </thermometer_blast_response> <thermometer_blast_response> <response>Green Light</response> </thermometer_blast_response> <thermometer_blast_response> <response>Yellow Light</response> </thermometer_blast_response> <thermometer_blast_response> <response>Red Light</response> </thermometer_blast_response> </thermometer_blast_responses>');
        }else{
             res.setBody('30%');
        }
        res.setStatusCode(200);
        return res;
    }
}