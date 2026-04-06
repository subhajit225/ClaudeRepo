//Test Class for ShGl_ApexCodeCoveragePageController
@isTest
public class ShGl_ApexCodeCoveragePageController_Test {
	//simple mock responses - not intelligent enough to respond to different input
	public class ApexTestCoverageMock implements HttpCalloutMock{
		public HTTPResponse respond(HTTPRequest req){
			HTTPResponse res = new HTTPResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setBody(
				'{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"ApexCodeCoverageAggregate","records":[' +
				'{"attributes":{"type":"ApexCodeCoverageAggregate","url":"/services/data/v31.0/tooling/sobjects/ApexCodeCoverageAggregate/715190000004HoFAAU"},'+
				'"ApexClassOrTriggerId":"01p19000000Cp4DAAS","ApexClassOrTrigger":{"attributes":{"type":"Name","url":"/services/data/v31.0/tooling/sobjects/ApexClass/01p19000000Cp4DAAS"},'+
				'"Name":"ContactTriggerHandler3"},"NumLinesCovered":12,"NumLinesUncovered":0},' +
				'{"attributes":{"type":"ApexCodeCoverageAggregate","url":"/services/data/v31.0/tooling/sobjects/ApexCodeCoverageAggregate/715190000004HoFAAU"},'+
				'"ApexClassOrTriggerId":"01p19000000Cp4DAAS","ApexClassOrTrigger":{"attributes":{"type":"Name","url":"/services/data/v31.0/tooling/sobjects/ApexClass/01p19000000Cp4DAAS"},'+
				'"Name":"ContactTriggerHandler5"},"NumLinesCovered":12,"NumLinesUncovered":0},' +
				'{"attributes":{"type":"ApexCodeCoverageAggregate","url":"/services/data/v31.0/tooling/sobjects/ApexCodeCoverageAggregate/715190000004HoFAAU"},'+
				'"ApexClassOrTriggerId":"01p19000000Cp4DAAS","ApexClassOrTrigger":{"attributes":{"type":"Name","url":"/services/data/v31.0/tooling/sobjects/ApexClass/01p19000000Cp4DAAS"},'+
				'"Name":"ContactTriggerHandler2"},"NumLinesCovered":12,"NumLinesUncovered":0}' +
				']}'
			);
			res.setStatusCode(200);
			return res;
		}
	}

	public class ApexTestCoverageErrorMock implements HttpCalloutMock{
		public HTTPResponse respond(HTTPRequest req){
			HTTPResponse res = new HTTPResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setBody('[{"message":"unexpected token: <EOF>","errorCode":"MALFORMED_QUERY"}]');
			res.setStatusCode(418);
			res.setStatus('I\'m a teapot'); //seriosuly, this is the RFC-compliant HTTP 418 response
			return res;
		}
	}

	@isTest
	static void successTest(){
		Test.setCurrentPage(Page.ShGl_ApexCodeCoverageExport);
		Test.setMock(HTTPCalloutMock.class, new ApexTestCoverageMock());
		ShGl_ApexCodeCoveragePageController con = new ShGl_ApexCodeCoveragePageController();
		System.assertEquals(3, con.coverages.size());
		System.assertEquals(12, con.coverages[0].NumLinesCovered);
        System.assertEquals(0, con.coverages[0].NumLinesUncovered);
        System.assertEquals(100.00, con.coverages[0].getCodeCoveragePercentage());
        System.assertEquals(36, con.tc.NumLinesCovered);
        System.assertEquals(0, con.tc.NumLinesUncovered);
        System.assertEquals(100.00, con.tc.getCodeCoveragePercentage());
	}

	@isTest
	static void failureTest(){
		Test.setCurrentPage(Page.ShGl_ApexCodeCoverageExport);
		Test.setMock(HTTPCalloutMock.class, new ApexTestCoverageErrorMock());
		ShGl_ApexCodeCoveragePageController con = new ShGl_ApexCodeCoveragePageController();
		System.assertEquals(0, con.coverages.size());
		System.assertEquals(true, ApexPages.hasMessages(ApexPages.Severity.Error), 'No errors processed from response');
	}
}