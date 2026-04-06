/**
 * @Author      : 
 * @CreatedDate : 13/10/2023
 * @TestClass    : CdmUpgradeProxyControllerTest
 * @Description :
 * -------------------------- @History -------------------------------------
 * Story Number       Modified By              Date           Description
 * 
 * -------------------------------------------------------------------------
 */
@RestResource(urlMapping='/cdm/loginAndListDownloadableReleases/*')
global class CdmUpgradeProxyController {

    // Okta 
    public final static String POST = 'POST';
	public final static String GET = 'GET';
    // Okta base URL
    public static String OKTA_BASE_URL = String.valueOf(OktaCalloutSelector.getOktaAttributes().get('Okta_Base_URL__c'));
    // Okta Access token
    public static String ACCESS_TOKEN ='SSWS '+String.valueOf(OktaCalloutSelector.getOktaAttributes().get('Access_Token__c'));
    
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
        
        RestRequest req = RestContext.request;
        
       
        Boolean showAll = (req.params.get('show_all') == 'true');
        System.debug('Show all versions: ' + showAll);
        
        Boolean fetchLinks = req.params.get('fetch_links') == 'true';
        System.debug('Fetch links: ' + fetchLinks);
        
        String filterVersionName = req.params.get('filter_version');
        System.debug('Version: ' + filterVersionName);
        
        Boolean shouldFilterUpgradeable = false;
        String sourceVersion = null;
        if(req.params.containsKey('filter_upgradable_versions') && req.params.containsKey('source_version')) {
            shouldFilterUpgradeable = (req.params.get('filter_upgradable_versions') == 'true');
            sourceVersion = req.params.get('source_version');
        }
        System.debug('Should filter upgradeable versions: ' + shouldFilterUpgradeable);
        System.debug('Source Version: ' + sourceVersion);
        
        Boolean show814Packages = false;
        if(req.params.containsKey('show_814') && req.params.get('show_814') == 'true') {
            show814Packages = true;
        }
        System.debug('show_814: ' + show814Packages);
        
        List<Custom_Error_Log__c> errorLogList = new List<Custom_Error_Log__c>();
        try {

          
            String reqBody = RestContext.request.requestBody.toString();
            
            String okta_un = (String)RestContext.request.headers.get('username');
            String okta_pw = (String)RestContext.request.headers.get('password');

            HTTPResponse oktaAuthRes = isValidCiamAuth(okta_un, okta_pw);
            if(isValidCallout(oktaAuthRes)){
                    HTTPResponse oktaUserRes = getSupportPortalUserName(okta_un);
                    if(isValidCallout(oktaUserRes)){
                            OktaCalloutSelector.UserData oktaResp = (OktaCalloutSelector.UserData)System.JSON.deserialize(oktaUserRes.getBody(), OktaCalloutSelector.UserData.class);
                            String supportPortalUn = oktaResp.profile.sfdcCustomerPortalUsername;
                            if(String.isNotBlank(supportPortalUn)){
                                List<User> objUser = [SELECT Id, Name, ContactId, Contact.AccountId 
                                                FROM User 
                                                WHERE Username =: supportPortalUn 
                                                AND isActive = true Limit 1];
                               
                                String jsGen='';
                                if(objUser!=NULL && objUser.size()>0){
                                    jsGen= passThroughReq(objUser[0].Contact.AccountId,filterVersionName,sourceVersion,fetchLinks,showAll,shouldFilterUpgradeable,show814Packages);
                                }else{
                                    jsGen='User does not exist in salesforce';
                                }
                                RestResponse oresp =  RestContext.response;
                                oresp.addHeader('Content-Type', 'application/json');
                                oresp.statusCode = 200;                                 
                                oresp.responseBody = Blob.valueof(jsGen);
                                return;
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
            exceptionErrorLog.Class__c = 'CdmUpgradeProxyController';
            exceptionErrorLog.Exception_Message__c = e.getmessage();
            exceptionErrorLog.ErrorTrace__c = e.getStackTraceString();
            errorLogList.add(exceptionErrorLog);
            
            RestResponse oresp =  RestContext.response;
            oresp.addHeader('Content-Type', 'application/json');
            oresp.statusCode = 404;                                 
            oresp.responseBody = Blob.valueof(e.getmessage() + ' '+e.getStackTraceString() );
            return;
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
        * @param    String AccountID,  String filterVersionName,String sourceVersion,Boolean fetchLinks,Boolean showAll,Boolean shouldFilterUpgradeable, Boolean show814Packages
        * @return   String
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    private static String passThroughReq(String AccountID,  String filterVersionName,String sourceVersion,Boolean fetchLinks,Boolean showAll,Boolean shouldFilterUpgradeable, Boolean show814Packages) {
      
        String jsGen= CdmUpgradeController.getCdm(AccountId,filterVersionName,sourceVersion,fetchLinks,showAll,shouldFilterUpgradeable,show814Packages);
        return jsGen;
        
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
        OktaCalloutSelector.UserData oktaResp = (OktaCalloutSelector.UserData)System.JSON.deserialize(res.getBody(), OktaCalloutSelector.UserData.class);
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
    
    public class rkcli_req {
       // public okta_creds okta_creds;
        public hbx_data hbx_data;
    }
    
    public class hbx_data {
        public String endpoint {get;set;}
    }
    
    public class okta_creds {
        public String password {get;set;}
        public String username {get;set;}
	}
}