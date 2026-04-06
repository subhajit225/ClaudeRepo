/**
 * @Author      : Vijay Kumar K R
 * @CreatedDate : Aug 10, 2023 
 * @TstClass    : HbxProxcyControllerTest
 * @Description :
 * -------------------------- @History -------------------------------------
 * Story Number       Modified By              Date           Description
 * 
 * -------------------------------------------------------------------------
 */
@RestResource(urlMapping='/hbxproxynew/*')
global class HbxProxcyController {

    // Okta
    public final static String POST = 'POST';
	public final static String GET = 'GET';
    // Okta base URL
    public static String OKTA_BASE_URL = String.valueOf(OktaCalloutSelector.getOktaAttributes().get('Okta_Base_URL__c'));
    // Okta Access token
    public static String ACCESS_TOKEN ='SSWS '+String.valueOf(OktaCalloutSelector.getOktaAttributes().get('Access_Token__c'));

    // hbx
    private static String hbxurl = system.label.hbxprodurl;
    private static String hbxapitoken = system.label.hbxprodapikey;
    
    /**
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
        * @description Auth CIAM Cred recied from rk_cli
        * ───────────────────────────────────────────────────────────────────────────────────────────────────
        * Method    processPostRequest
        * @param    NA
        * @return   String
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    @HttpPost
    global static void processPostRequest() {
        
        List<Custom_Error_Log__c> errorLogList = new List<Custom_Error_Log__c>();
        try {

            Map<String, Object> rkcli_req = (Map<String, Object>)JSON.deserializeUntyped(RestContext.request.requestBody.toString());
            Map<String, Object> hbx_data = (Map<String, Object>)rkcli_req.get('hbx_data');
            Map<String, Object> body = (Map<String, Object>)hbx_data.get('body');
            
            String reqBody = RestContext.request.requestBody.toString();
            rkcli_req rk_cli_req = (rkcli_req)System.JSON.deserialize(reqBody, rkcli_req.class);
            
            hbx_data hbxData = rk_cli_req.hbx_data;
            
            String okta_un = rk_cli_req.okta_creds.username;
            String okta_pw = rk_cli_req.okta_creds.password;

            HTTPResponse oktaAuthRes = isValidCiamAuth(okta_un, okta_pw);
            if(isValidCallout(oktaAuthRes)){
                    HTTPResponse oktaUserRes = getSupportPortalUserName(okta_un);
                    if(isValidCallout(oktaUserRes)){
                            OktaCalloutSelector.UserData oktaResp = (OktaCalloutSelector.UserData)System.JSON.deserialize(oktaUserRes.getBody(), OktaCalloutSelector.UserData.class);
                            String supportPortalUn = oktaResp.profile.sfdcCustomerPortalUsername;
                            if(String.isNotBlank(supportPortalUn)){
                                User objUser = [SELECT Id, Name, ContactId, Contact.AccountId 
                                                FROM User 
                                                WHERE Username =: supportPortalUn 
                                                AND isActive = true Limit 1];
                                body.put('user_id', objUser.Id);
                                passThroughReq(objUser.Id, objUser.ContactId, objUser.Contact.AccountId, hbxData, 'POST', JSON.serialize(body), errorLogList);
                            }
                            // If No Customer User exists in Okta
                            else{
                                RestResponse oresp =  RestContext.response;
                                oresp.addHeader('Content-Type', 'application/json');
                                oresp.statusCode = 404;                                 
                                oresp.responseBody = Blob.valueof('Customer Portal User Not found');
                                return;
                            }
                    }else{
                        returnErrorRes(oktaUserRes);
                    }
            }else{
                returnErrorRes(oktaAuthRes);
            }

            captureUserDetails(okta_un);
        }
        // catch statement for exceptions.
        catch (Exception e) {
            System.debug('Exception: '+e.getMessage());
            Custom_Error_Log__c exceptionErrorLog = new Custom_Error_Log__c();
            exceptionErrorLog.Class__c = 'HbxProxcyController';
            exceptionErrorLog.Exception_Message__c = e.getmessage();
            exceptionErrorLog.ErrorTrace__c = e.getStackTraceString();
            errorLogList.add(exceptionErrorLog);
        } 
        // Finally block
        finally{
            System.debug('errorLogList: '+errorLogList);
            if(!errorLogList.isEmpty()){
                INSERT errorLogList;
            }
        }
    } 

    /**
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
        * @description Auth CIAM Cred recied from rk_cli
        * ───────────────────────────────────────────────────────────────────────────────────────────────────
        * Method    passThroughReq
        * @param    String endUserId, String endUserContactId, String endUserAccountId, hbx_data hbxData, String method, String bodyText, List<Custom_Error_Log__c> errorLogList
        * @return   String
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    private static void passThroughReq(String endUserId,
                                        String endUserContactId,
                                        String endUserAccountId,
                                        hbx_data hbxData, String method, String bodyText, List<Custom_Error_Log__c> errorLogList) {
        
        String endpoint = hbxurl + hbxData.endpoint;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader('Authorization', 'Bearer '+hbxapitoken);
        req.setHeader('Content-Type', 'application/json; charset=UTF-8');
        req.setHeader('AccountId', endUserAccountId);
        req.setHeader('ContactId', endUserContactId);
        req.setHeader('UserId', endUserId);
        if(string.isNotblank(system.label.hbxproxyTimeout)){
            req.setTimeout(integer.valueof(system.label.hbxproxyTimeout));
        }
        req.setBody(bodyText); 

        Http http = new Http();
        HttpResponse hbxresp = new HttpResponse();
        hbxresp = http.send(req);	
        RestResponse oresp =  RestContext.response;
        oresp.addHeader('Content-Type', 'application/json');
        if (hbxresp == null) {
            oresp.statusCode = 400;
            oresp.responseBody = blob.valueOf('{"message": "Unknown Error"}');     
        } else {
            if(hbxresp.getstatusCode() != 200){
                errorLogList.add(createErrorLog(req, hbxresp, endpoint));
            }
            oresp.statusCode = hbxresp.getStatusCode();                                 
            oresp.responseBody = blob.valueOf(hbxresp.getBody());
        }
        return; 
    }

    /**
        * ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
        * @description Create Custom Error Log record
        * ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
        * Method    createErrorLog
        * @param    HttpRequest req, HttpResponse hbxresp, String endpoint 
        * @return   Custom_Error_Log__c
        * ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public static Custom_Error_Log__c createErrorLog(HttpRequest req, HttpResponse hbxresp, String endpoint){
        Custom_Error_Log__c errorLog = new Custom_Error_Log__c();
        errorLog.Class__c = 'HbxProxcyController';
        errorLog.Http_Request__c = req.getBody();
        errorLog.Http_Response__c = hbxresp.getBody();
        errorLog.Http_StatusCode__c = String.ValueOf(hbxresp.getstatusCode());
        errorLog.Server_Endpoint__c = endpoint;
        return errorLog;
    }

    /**
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
        * @description Auth CIAM Cred recied from rk_cli
        * ───────────────────────────────────────────────────────────────────────────────────────────────────
        * Method    getSupportPortalUserName
        * @param    String email
        * @return   HTTPResponse
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    private static HTTPResponse getSupportPortalUserName(String email){
        String encoded = EncodingUtil.urlEncode(email, 'UTF-8');
        HttpRequest req = new HttpRequest();
        String endpoint = OKTA_BASE_URL+'/api/v1/users/'+encoded;
        req.setMethod('GET');
        req.setEndpoint(endpoint);
        req.setCompressed(false);
        req.setTimeout(20000);
        req.setHeader('Accept','application/json');
		req.setHeader('Content-Type', 'application/json');
		req.setHeader('Connection', 'keep-alive');
		req.setHeader('Authorization', ACCESS_TOKEN);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        // OktaCalloutSelector.UserData oktaResp = (OktaCalloutSelector.UserData)System.JSON.deserialize(res.getBody(), OktaCalloutSelector.UserData.class);
        return res;
    }

    /**
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
        * @description Capture User details coming from rkcli to SFDC
        * ───────────────────────────────────────────────────────────────────────────────────────────────────
        * Method    captureUserDetails
        * @param    String username
        * @return   void
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    @future
    private static void captureUserDetails(String username){
        User objUser = [SELECT Id FROM User WHERE UserName =: username AND isActive = true Limit 1];
        try {
            Rkcli_User_Log__c rbcli1 = [SELECT Id FROM Rkcli_User_Log__c 
                                            WHERE User__c =: objUser.Id];
            rbcli1.Last_Login_Time__c = System.now();
            UPDATE rbcli1;
        } catch (Exception e) {
            Rkcli_User_Log__c rbcli2 = new Rkcli_User_Log__c(User__c = objUser.Id, Last_Login_Time__c = System.now());      
            INSERT rbcli2;
        }
    }

    /**
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
        * @description Auth CIAM Cred recied from rk_cli
        * ───────────────────────────────────────────────────────────────────────────────────────────────────
        * Method    isValidCiamAuth
        * @param    String username, String password
        * @return   HTTPResponse
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    private static HTTPResponse isValidCiamAuth(String username, String password){

        // payload
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('username', username);
        payload.put('password', password);

        // http req callout
        HttpRequest req = new HttpRequest();
        String endpoint = OKTA_BASE_URL+'/api/v1/authn';
        req.setMethod('POST');
        req.setEndpoint(endpoint);
        req.setCompressed(false);
        req.setTimeout(20000);
        req.setHeader('Accept','application/json');
		req.setHeader('Content-Type', 'application/json');
		req.setHeader('Connection', 'keep-alive');
		req.setHeader('Authorization', ACCESS_TOKEN);
        req.setBody(JSON.serialize(payload));
        // http res
        Http http = new Http();
        HTTPResponse res = http.send(req);
        // Kill okta session token
        Map<String, Object> okta_res = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        okta_res.put('sessionToken', null);
        return res;

    }

    /**
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
        * @description check res status code and status
        * ───────────────────────────────────────────────────────────────────────────────────────────────────
        * Method    isValidCallout
        * @param    HTTPResponse res
        * @return   Boolean
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    private static Boolean isValidCallout(HTTPResponse res){
        return (res.getStatusCode() == 200
                && res.getStatus().equalsIgnoreCase('OK'));
    }

    /**
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
        * @description return Error info
        * ───────────────────────────────────────────────────────────────────────────────────────────────────
        * Method    returnErrorRes
        * @param    HTTPResponse res
        * @return   RestResponse
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    private static void returnErrorRes(HTTPResponse res){
        RestResponse oresp =  RestContext.response;
        oresp.addHeader('Content-Type', 'application/json');
        oresp.statusCode = res.getStatusCode();                                 
        oresp.responseBody = blob.valueOf(res.getBody());
        return;
    }
    
    /**
        * ───────────────────────────────────────────────────────────────────────────────────────────────────
        * Wrapper    rkcli_req
        * @param     okta_creds okta_creds
        * @param     hbx_data hbx_data
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public class rkcli_req {
        public okta_creds okta_creds;
        public hbx_data hbx_data;
    }
    
    /**
        * ───────────────────────────────────────────────────────────────────────────────────────────────────
        * Wrapper    hbx_data
        * @param     String endpoint
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public class hbx_data {
        public String endpoint {get;set;}
    }
    
    /**
        * ───────────────────────────────────────────────────────────────────────────────────────────────────
        * Wrapper    okta_creds
        * @param     String password
        * @param     String username
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public class okta_creds {
        public String password {get;set;}
        public String username {get;set;}
	}
}