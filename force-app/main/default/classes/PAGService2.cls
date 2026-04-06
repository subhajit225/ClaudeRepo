/*
* Class Name :- PAGService
* Author :- Rubrik Dev
* Created Date :- Aug 29th , 2023
* Description : CPQ22-3109 :- Polaris calls this API to create PAG,Opportunity and Entitlements
* TestClass   : PAGServiceTest
// ********************Mofification Log *****************************************************************************
* 
* Modified By          Date             Description (Include Jira Details)
* 
* 
* 
// ********************Modification Log *****************************************************************************
*/
@RestResource(urlMapping='/CreateAndExtendPAGTrials')
global with sharing class PAGService2{
    
    /*
    *********************************************************
    @Method Name    : ExtendTrials
    @author         : Rubrik Dev
    @description    : Capture/Process Polaris PAG Request and send back appropriate response
    @param          : List<ServiceContract> , Map<ID,ServiceContract>
    @return         : void
    ********************************************************
    */
    @HttpPatch
    global static void ExtendTrials(){

        try{
            RestRequest request = RestContext.request;
            //system.debug('request.requestURI'+request.requestURI);
            RestResponse res = RestContext.response;
            PAGRequestWrapper pagReqWrapper = (PAGRequestWrapper)JSON.deserialize(request.requestbody.tostring(),PAGRequestWrapper.class);
            //system.debug('pagReqWrapper.    '+pagReqWrapper);
            //List<PAGResponseWrapper> pagResponseList = new List<PAGResponseWrapper>();
            String responseJSON = JSON.serializePretty(PAGServiceUtility2.createUpdatePAGDetails(pagReqWrapper,request.requestbody.tostring()),true);
            RestContext.response.responseBody = Blob.valueOf(responseJSON);

            //Create PAG Staging Record capturing request and response
            PAGServiceUtility2.createPAGStaging(RestContext.request.requestbody.tostring(),responseJSON);
        }
        catch(Exception ex){
            //Create Response for unhandled exceptions, return 500 as code
            RestContext.response = PAGServiceUtility2.createUnhandledExceptionResponse(RestContext.request,RestContext.response,ex);
        }
    }
    /*
    *********************************************************
    @Method Name    : createTrials
    @author         : Rubrik Dev
    @description    : Capture/Process Polaris PAG Request and send back appropriate response
    @param          : List<ServiceContract> , Map<ID,ServiceContract>
    @return         : void
    ********************************************************
    */
    @HttpPost
    global static void createTrials(){

        try{
            RestRequest request = RestContext.request;
            //system.debug('request.requestURI'+request.requestURI);
            RestResponse res = RestContext.response;
            PAGRequestWrapper pagReqWrapper = (PAGRequestWrapper)JSON.deserialize(request.requestbody.tostring(),PAGRequestWrapper.class);
            //system.debug('pagReqWrapper.    '+pagReqWrapper);
            //List<PAGResponseWrapper> pagResponseList = new List<PAGResponseWrapper>();
            String responseJSON = JSON.serializePretty(PAGServiceUtility2.createUpdatePAGDetails(pagReqWrapper,request.requestbody.tostring()),true);
            RestContext.response.responseBody = Blob.valueOf(responseJSON);

            //Create PAG Staging Record capturing request and response
            PAGServiceUtility2.createPAGStaging(request.requestbody.tostring(),responseJSON);
        }
        catch(Exception ex){
            //Create Response for unhandled exceptions, return 500 as code
            RestContext.response = PAGServiceUtility2.createUnhandledExceptionResponse(RestContext.request,RestContext.response,ex);
        }
    }
}