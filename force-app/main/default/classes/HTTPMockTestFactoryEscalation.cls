@isTest
public class HTTPMockTestFactoryEscalation implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        
        // Mock response with Escalation field to trigger line 316
        String responseBody = '{' +
            '"idea": {' +
                '"id": "7572648307445937159",' +
                '"name": "Test Escalation Idea",' +
                '"reference_num": "ESCALATION-001",' +
                '"workflow_status": {' +
                    '"id": "7213493030948925638",' +
                    '"name": "Under Review",' +
                    '"position": 3' +
                '},' +
                '"created_by_user": {' +
                    '"id": "7303668217194773340",' +
                    '"name": "Test User",' +
                    '"email": "test@rubrik.com"' +
                '},' +
                '"custom_fields": [' +
                    '{' +
                        '"id": "7574477366186385830",' +
                        '"key": "escalation",' +
                        '"name": "Escalation",' +
                        '"updatedAt": "2025-11-19T16:40:40Z",' +
                        '"value": "High Priority",' +
                        '"type": "string"' +
                    '}' +
                '],' +
                '"feature_links": []' +
            '}' +
        '}';
        
        res.setBody(responseBody);
        return res;
    }
}