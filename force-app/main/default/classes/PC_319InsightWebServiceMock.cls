@isTest
global class PC_319InsightWebServiceMock implements WebServiceMock {
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
       PC_319InsightWebService.deployDataBuilderResponse resp = new PC_319InsightWebService.deployDataBuilderResponse();
                  
       resp.companyId = 12;
       resp.contactId = 23;
       resp.dataBuilderId = 34;
       resp.deployStatus = 'DEPLOYED';
       resp.requestId = '3434';
       resp.status = 'success';        
       response.put('response_x', resp); 
   }
}