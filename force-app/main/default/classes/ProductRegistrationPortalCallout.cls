/**
 * @Created By: 
 * @Created Date: 
 * @Test Class: RegisterProductTest
 * @Modified History: CS21-1150 by vijay.kr@rubrik.com, June 17 2022
 * -------------------------- @History --------------------------------------------------------------------------------------------
 * Story Number       Modified By              Date           Description
 * CS21-1623         Vijay Kumar K R        Oct 04, 2023      Add support for new error structure from HBX on support portal
 * --------------------------------------------------------------------------------------------------------------------------------
 */
@RestResource(urlMapping='/registerportal/*')
global class ProductRegistrationPortalCallout{
    
    private static String secretKey = 'secret';
    private static String endpoint = system.label.hearbeatendpoint; // Node id present
    private static String endpointDatosProduct = system.label.hearbeatendpointdatos; // Node id not present
    private static String latestCdmEndpoint = system.label.hearbeatlatestcdmendpoint; // recent CDM release endpoint
    public static string regkey {get; set;}
    private static String reqBody {get; set;}
    
    @TestVisible
    private static final String TEST_ACC_NAME = 'Rubrik-Test';
    private static final String INVALID_TOKEN_ERROR = 'The teleport token is not valid. Please verify the teleport token and submit the registration request again.';

    /**
     * @Method: processRegRequest 
     * @params: string uuid, string nodename, String manufacturingtime, String teleporttoken, Boolean islegacy
     * @return: string
     **/
    @HttpPost
    global static string processRegRequest(string uuid, string nodename, String manufacturingtime, String teleporttoken, Boolean islegacy) {
                
        RestResponse oresp =  RestContext.response;
        if(oresp!=null) oresp.addHeader('Content-Type', 'application/json');
        
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();

        req = prepareCallout(req, uuid, nodename, manufacturingtime, teleporttoken, islegacy);
        
        String respmessage = '{}';
        regkey = '';

        try {
            if (Test.isRunningTest()) {
                res = new HttpResponse();
            } else {   
                res = http.send(req);
            }
            try{
                createRegistrationLog(res, uuid, nodename);
            }catch(Exception e){
                System.debug(e);
            }

            if (res != null && res.getStatusCode() == 200) {
                if(oresp!=null) oresp.statusCode = 200;
                if(oresp!=null) oresp.responseBody = blob.valueOf(respmessage);
                respmessage = res.getBody(); 
                // Removing double quotes on each end of Teleport Token
                if(!islegacy){
                    respmessage = respmessage.replace('\"','');
                }
                
            } else {
                //URL to pass back: 
                if(oresp!=null) oresp.statusCode = 400;
                respmessage = handleCalloutError(res, req, respmessage);
            }
        } 
        catch(System.CalloutException e) {
            System.debug('\n ### callout error: '+ e);
            throw e;
        } catch (system.Dmlexception dmlEx) {
            System.debug('\n ### Exception in reservation : '+ dmlEx);
            throw dmlEx;
        }
        return respmessage;
    }

    /**
     * @Method: prepareCallout by Vijay Kumar K R <vijay.kr@rubrik.com>
     * @params: HttpRequest req, string uuid, string nodename, String manufacturingtime, String teleporttoken, Boolean islegacy
     * @return: HttpRequest
     **/
    private static HttpRequest prepareCallout(HttpRequest req, string uuid, string nodename, String manufacturingtime, String teleporttoken, Boolean islegacy){
        //create the string of callout parameters

        String ll = userinfo.getUserId();
        String lla = [SELECT Id,UserName,Contact.AccountId from User where Id=:ll].Contact.AccountId;
        string finalAcct = lla==null ? [SELECT Id FROM Account WHERE Name =: TEST_ACC_NAME].Id : lla; // ASK do we have same Acc in higher orgs as well?

        // By Vijay: is Sandbox, to get heartbeat attributes based on Sandbox type 
        Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        // base URL mapping
        String endUrl = isSandbox ? System.Label.hbxsandboxurl : System.Label.hbxprodurl;
        // API key
        String heartbeatAPI = isSandbox ? System.Label.hbxsandboxapikey : System.Label.heartbeatAPI; // Node id present
        
        if(string.isBlank(nodename)){
            // Mosaic Registration
            endUrl += endpointDatosProduct + EncodingUtil.urlEncode(uuid, 'UTF-8');
        }else{
            // CS21-1150
            if(islegacy){
                endUrl += endpoint + EncodingUtil.urlEncode(uuid, 'UTF-8');
            }else{
                endUrl += latestCdmEndpoint + EncodingUtil.urlEncode(nodename, 'UTF-8');
            }
        }
        
        req.setEndpoint(endUrl);
        req.setMethod('POST');
        req.setTimeout(120000);
        req.setHeader('Authorization', 'Bearer '+heartbeatAPI);  
        req.setHeader('Content-Type', 'application/json; charset=UTF-8');
        
        reqBody = '';
        reqBody += '{"account_id":"'+EncodingUtil.urlEncode(finalAcct, 'UTF-8');
        //cluster registration for a legacy CDM release that supports the legacy Support 
        if(islegacy){
            // Mosaic Registration
            reqBody += '","id":"'+EncodingUtil.urlEncode(uuid, 'UTF-8');
            // node serial id
            if(string.isNotBlank(nodename)){
                reqBody += '","node_name":"'+EncodingUtil.urlEncode(nodename, 'UTF-8');
            }
        }
        // cluster registration for a more recent CDM release that supports the Teleport infrastructure
        // Rubrik CDM 
        else{
            // Node Id or Serial number
            reqBody += '","id":"'+EncodingUtil.urlEncode(nodename, 'UTF-8');
            // cluster uuid
            if(string.isNotBlank(uuid)){
                reqBody += '","cluster_id":"'+EncodingUtil.urlEncode(uuid, 'UTF-8');
            }else{
                reqBody += '","cluster_id":"'+EncodingUtil.urlEncode(nodename, 'UTF-8');
            }
            // manufacturing date
            if(string.isNotBlank(manufacturingtime)){
                reqBody += '","manual_registration": "true"';
                reqBody += ',"manufactured_date":"'+manufacturingtime;
            }
            // teleport token
            if(string.isNotBlank(teleporttoken)){
                    reqBody += '","teleport_token":"'+EncodingUtil.urlEncode(teleporttoken, 'UTF-8');
            }
        }
        
        reqBody += '"}';
        req.setBody(reqBody);
        system.debug('### req: ' + req+' ##payload: '+reqBody);
        return req;
    }

    /**
     * @Method: handleCalloutError by Vijay Kumar K R <vijay.kr@rubrik.com>
     * @params: HttpResponse res, HttpRequest request, String respmessage
     * @return: string
     **/
    private static string handleCalloutError(HttpResponse res, HttpRequest request, String respmessage){
        try{
            String resResult = 'UserName :'+UserInfo.getUserName();
            resResult += '<br/>UserId :'+UserInfo.getUserid();
            resResult += '<br/>UserEmail :'+UserInfo.getUserEmail();
            resResult += '<br/><br/>Status Code :'+res.getStatusCode();
            resResult += '<br/><br/>ResBody :'+res.getBody();
            resResult += '<br/><br/>reqBody :'+reqBody;

            Heartbeat_Server_Log__c serverLog = new Heartbeat_Server_Log__c();
            serverLog.Exception_Log__c = resResult;
            serverLog.Type__c = 'CDM/Mosaic';
            serverLog.Endpoint__c = request != null ? request.getEndpoint() : '';
            serverLog.Request_Body__c = request != null ? request.getBody() : '';
            serverLog.Response__c = res.getBody();
            serverLog.Error_Message__c = res.getBody();
            Database.insert(serverLog, false);
            
        }catch(Exception e){System.debug('errorLogs');}   
        
        String errorBody = res.getBody();
        System.debug('errorBody: '+errorBody);

        String errorMessage = '';
        if(!test.isRunningTest()) {
            if(res.getStatusCode() == 400){
                respmessage = '400exception+';
                // New HBX Error format
                if(errorBody.containsIgnoreCase('error_code')){
                    respmessage += HeartbeatUtility.getHeartbeatErrorMessage(errorBody, null);
                }else{
                    String invalid_token = 'Unable to register with teleport';
                    if(errorMessage.containsIgnoreCase(invalid_token)){
                        respmessage += INVALID_TOKEN_ERROR;
                    }else{
                        Map<String, String> regMap = (Map<String,String>) JSON.deserialize(errorBody, Map<String,String>.class);
                        errorMessage = (String)regMap.get('message');
                        respmessage += errorMessage;
                    }
                }
            }else if(res.getStatusCode() == 500){
                // New HBX Error format
                if(errorBody.containsIgnoreCase('error_code')){
                    respmessage += HeartbeatUtility.getHeartbeatErrorMessage(errorBody, null);
                }else{
                    respmessage = '500exception+';
                    Map<String, String> regMap = (Map<String,String>) JSON.deserialize(errorBody, Map<String,String>.class);
                    errorMessage = (String)regMap.get('message');
                    respmessage += errorMessage;
                }
            }
        }
        return respmessage;
    }
    /**
     * @Method: createRegistrationLog by Shiva Sharma
     * @params: HttpResponse res, String uuid,  String nodename
     * @return: void
     **/
    public static void createRegistrationLog(HttpResponse res, string uuid, string nodename){
        insert new Cluster_registration__c(
            cluster_UUID__c = uuid,
            Cluster_Tag__c = nodename,
            Registration_Date__c = System.now(),
            Requested_Users__c = Userinfo.getUserId(),
            Request_Status__c = res.getStatus(),
            Request_Status_Message__c = res.getBody()
        );
    }
}