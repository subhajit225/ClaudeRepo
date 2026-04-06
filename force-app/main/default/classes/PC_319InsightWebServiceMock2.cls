@isTest
global class PC_319InsightWebServiceMock2 implements WebServiceMock {
global void doInvoke(
           Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName,
           String responseNS,
           String responseName,
           String responseType) {
           
       PC_319InsightWebService.DataBuilderWebServicePort cons = new PC_319InsightWebService.DataBuilderWebServicePort();
       PC_319InsightWebService.requestDataBuilderResponse resp = new PC_319InsightWebService.requestDataBuilderResponse();
                  
       resp.fileStatus='In Process';
       resp.status ='success';
       resp.totalRiskScore = 2;
       response.put('response_x', resp); 
   }
}