@isTest
public class HTTPCalloutServiceMultiMock implements HTTPCalloutMock {

    Map<String, GenericMockHttpResponseGenerator> calloutMocks;

    /*
    * Constructor initializing the class variables
    */
    public HTTPCalloutServiceMultiMock() {
        calloutMocks = new Map<String, GenericMockHttpResponseGenerator>();
    }

    /*
    * Constructor initializing the class variables (from user input if available)
    */
    public HTTPCalloutServiceMultiMock(Map<String, GenericMockHttpResponseGenerator> calloutMocks) {
        this.calloutMocks = calloutMocks;
        if(this.calloutMocks == null) {
            calloutMocks = new Map<String, GenericMockHttpResponseGenerator>();
        }
    }

    /*
    * Adding a callout mock class instance to (URL - Mock) map
    */
    public void addCalloutMock(String serviceName, GenericMockHttpResponseGenerator calloutMock) {
        calloutMocks.put(serviceName, calloutMock);
    }

    /*
    * This method is used to generate and send a mock HTTP response for the incoming request
    * It also throws a custom exception in case the mock is not found for the input request URL
    */
    public HTTPResponse respond(HTTPRequest request) {
        String serviceName = '';
        if(request.getEndpoint().contains('node/field-manufacture/')){
            serviceName = 'heartbeatPost';
        }
        else if(request.getEndpoint().contains('teleport')){
            serviceName = 'teleport';
        }
        else if(request.getEndpoint().contains('node/')){
            serviceName = 'heartbeatPatch';
        }

        GenericMockHttpResponseGenerator calloutMock = calloutMocks.get(serviceName);
        if(calloutMock != null) {
            return calloutMock.respond(request);
        }
        return null;
    }
}