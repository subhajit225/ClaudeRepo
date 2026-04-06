/**
 * @description API to create PQL, Opportunity.
 * Class Name :- PQLService
 * Author :- Rubrik Dev
 * Created Date :- Dec 26th , 2024
 * TestClass   : PQLServiceTest
 */ 
@RestResource(urlMapping='/CreateOrUpdatePQL')
global class PQLService {

    /** 
     * @description Capture Polaris PQL Request and send back appropriate response
     */
    @HttpPost
    global static void CreatePQL(){
        try{
            RestRequest request = RestContext.request;
            RestResponse res = RestContext.response;
            PAGRequestWrapper pagReqWrapper = (PAGRequestWrapper)JSON.deserialize(request.requestbody.tostring(),PAGRequestWrapper.class);
            String responseJSON = JSON.serializePretty(PAGServiceUtility2.createUpdatePAGDetails(pagReqWrapper,request.requestbody.tostring()),true);
            RestContext.response.responseBody = Blob.valueOf(responseJSON);
            PAGServiceUtility2.createPAGStaging(request.requestbody.tostring(),responseJSON);
        }
        catch(Exception ex){
            RestContext.response = PAGServiceUtility2.createUnhandledExceptionResponse(RestContext.request,RestContext.response,ex);
        }
    }

    /** 
     * @description Capture Polaris PQL Request, update and send back appropriate response
     */
    @HttpPatch
    global static void UpdatePQL(){
        try{
            RestRequest request = RestContext.request;
            RestResponse res = RestContext.response;
            PAGRequestWrapper pagReqWrapper = (PAGRequestWrapper)JSON.deserialize(request.requestbody.tostring(),PAGRequestWrapper.class);
            String responseJSON = JSON.serializePretty(PAGServiceUtility2.createUpdatePAGDetails(pagReqWrapper,request.requestbody.tostring()),true);
            RestContext.response.responseBody = Blob.valueOf(responseJSON);
            PAGServiceUtility2.createPAGStaging(request.requestbody.tostring(),responseJSON);
        }
        catch(Exception ex){
            RestContext.response = PAGServiceUtility2.createUnhandledExceptionResponse(RestContext.request,RestContext.response,ex);
        }
    }

}