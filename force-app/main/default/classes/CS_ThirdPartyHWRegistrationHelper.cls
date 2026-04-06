/**
* @description  :   Helper class for Register Third Party Hardware feature
* @Author       :   Saakshi Gupta
* @CreatedDate  :   14-09-2021
* @Jira Ticket  :   CS-679 - Enable offline product activation/registration for third party hardware manufacturing on the Support Portal
* @TestClass    :   CS_RegisterThirdPartyHWControllerTest.cls

* -------------------------- @History --------------------------------------------------------------------------------------------
* Story Number       Modified By              Date           Description
*  CS21-1830		 Sushant Arora		   08/16/2023	     Changed the API from register-server to register-node and removed the chasisId, AssestId and other from the payload.
*  CS21-3819		 Shailesh Kumar		   Dec 11,2025	     Code - Remove third party prefix mapping check on SFDC
*/
public without sharing class CS_ThirdPartyHWRegistrationHelper {

    private static String heartbeatEndpoint;
    private static String heartbeatToken;
    private static String teleportEndpoint;

    /**
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   14-09-2021
    * @description  :   This method sets the integration attributes like endpoint and token based on the current Salesforce environment
    */
    public static void setIntegrationAttributes() {
        Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;

        //Set sandbox related attributes
        heartbeatEndpoint = isSandbox ? System.Label.hbxsandboxurl : System.Label.hbxprodurl;
        heartbeatToken = isSandbox ? System.Label.hbxsandboxapikey : System.Label.heartbeatAPI;
        teleportEndpoint = isSandbox ? System.Label.Teleport_Sandbox_Endpoint : System.Label.Teleport_Production_Endpoint;
    }

    /**
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   14-09-2021
    * @description  :   This method makes the first callout to Heartbeat which creates the node in Salesforce
    * @param formFields
    * @param currentUser
    * @param entitlementRecord
    * @return HttpResponse
    */
    public static HttpResponse nodeRegistrationCallout(ThirdPartyHardwareForm formFields, User currentUser, Entitlement entitlementRecord) {//, Node_Prefix_to_Product_Mapping__mdt productMapping removed-CS21-3819
        
        //Generate a wrapper object for request payload and convert to string
        ThirdPartyHardwareNodeRequest nodeRequestObject = new ThirdPartyHardwareNodeRequest(currentUser.Id,System.Label.Default_MAC_Id, formFields.entitlementId, formFields.uuid, formFields.manufacturingTime, formFields.teleportToken, formFields.nodeId);
        String payload = JSON.serialize(nodeRequestObject);

        String endpoint = heartbeatEndpoint + 'node/register-node/' + EncodingUtil.urlEncode(formFields.nodeId, 'UTF-8');
        
        //Create header map which will be used to add the headers to the request payload
        Map<String, String> headerMap = new Map<String, String>();
        headerMap.put('Authorization', 'Bearer ' + heartbeatToken);
        headerMap.put('Content-Type', 'application/json; charset=UTF-8');
        headerMap.put('AccountId', entitlementRecord.AccountId);
        headerMap.put('ContactId', currentUser.ContactId);
        headerMap.put('UserId', currentUser.Id);

        //Create an HTTP request object with the above attributes
        HttpRequest request = createRequest(endpoint, 'POST', 120000, payload, headerMap);

        //Make the webservice callout
        HttpResponse response = new HttpResponse();
        try {
            response = makeCallout(request);
            try{
                ProductRegistrationPortalCallout.createRegistrationLog(response, formFields.uuid, formFields.nodeId);
            }catch(Exception e){
                System.debug(LoggingLevel.DEBUG,e);
            }
        }
        catch(System.CalloutException e) {
            throw e;
        }
        return response;
    }

    /*
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   14-09-2021
    * @Description  :   This method makes the second callout to Heartbeat which updates the manufacturing time on the node created in the
    *                   first callout in Salesforce
    */
    /*public static HttpResponse nodeRegistrationPatchCall(ThirdPartyHardwareForm formFields, String serialNumber) {
        //Generate a wrapper object for request payload and convert to string
        ThirdPartyHardwareNodePatchRequest nodeRequestObject = new ThirdPartyHardwareNodePatchRequest(formFields.manufacturingTime, serialNumber);
        String payload = JSON.serialize(nodeRequestObject);

        //Generate the endpoint url
        String endpoint = heartbeatEndpoint + 'node/' + EncodingUtil.urlEncode(serialNumber, 'UTF-8');

        //Create header map which will be used to add the headers to the request payload
        Map<String, String> headerMap = new Map<String, String>();
        headerMap.put('Authorization', 'Bearer ' + heartbeatToken);
        headerMap.put('Content-Type', 'application/json; charset=UTF-8');

        //Create an HTTP request object with the above attributes
        HttpRequest request = createRequest(endpoint, 'PATCH', 120000, payload, headerMap);

        //Make the webservice callout
        HttpResponse response = new HttpResponse();
        try {
            response = makeCallout(request);
        }
        catch(System.CalloutException e) {
            throw e;
        }
        return response;
    }*/

    /*
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   14-09-2021
    * @Description  :   This method makes the third callout to Teleport which registers the node and generates and returns the entitlement
    *                   token to be used by the customer
    */
    /*public static HttpResponse nodeRegistrationCalloutToTeleport(ThirdPartyHardwareForm formFields, User currentUser) {
        //Generate a wrapper object for request payload and convert to string
        ThirdPartyHardwareTeleportRequest nodeRequestObject = new ThirdPartyHardwareTeleportRequest(formFields.nodeId, formFields.manufacturingTime, formFields.teleportToken);
        String payload = '[' + JSON.serialize(nodeRequestObject) + ']';

        //Generate the endpoint url
        String endpoint = teleportEndpoint + 'api/v1/node/offline_entitlement';

        //Create JWT token for identification at the Teleport side
        String jwtToken = generateJWT(currentUser);

        //Create header map which will be used to add the headers to the request payload
        Map<String, String> headerMap = new Map<String, String>();
        headerMap.put('authorization', jwtToken);
        headerMap.put('Content-Type', 'application/json; charset=UTF-8');

        //Create an HTTP request object with the above attributes
        HttpRequest request = createRequest(endpoint, 'POST', 120000, payload, headerMap);

        //Make the webservice callout
        HttpResponse response = new HttpResponse();
        try {
            response = makeCallout(request);
        }
        catch(System.CalloutException e) {
            throw e;
        }
        return response;
    }*/

    /*
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   14-09-2021
    * @Description  :   This method generates the JWT token with the logged in user's details
    */
    /*public static String generateJWT(User subject){
        JWT jwt = new JWT(System.Label.JWT_Algorigthm);
        jwt.forThirdPartyHWRegistration = true;
        jwt.iss = System.Label.SFDC_Colon_Colon + System.Label.BaseUrlOrg;
        jwt.sub = System.Label.SFDC_Colon_Colon + subject.Username;
        jwt.aud = System.Label.Teleport;
        jwt.validFor = Integer.valueOf(System.Label.Teleport_Token_Validity);
        jwt.cert = System.Label.Teleport_Token_Certificate;

        Map<String, String> claims =new Map<String, String>();
        claims.put('jti', subject.Username);
        jwt.claims = claims;

        String token = '';
        try{
            token = jwt.issue();
        }
        catch(Exception e){
            throw e;
        }
        return token;
    }*/

    /**
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   14-09-2021
    * @description  :   This method creates HTTP request with the parameters passed
    * @param endpoint
    * @param method
    * @param timeout
    * @param requestBody
    * @param headerMap
    * @return HttpRequest
    */
    private static HttpRequest createRequest(String endpoint, String method, Integer timeout, String requestBody, Map<String, String> headerMap){

        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod(method);
        request.setTimeout(timeout);
        request.setBody(requestBody);
        for(String eachKey : headerMap.keySet()){
            request.setHeader(eachKey, headerMap.get(eachKey));
        }
       
        return request;
    }

    /**
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   14-09-2021
    * @description  :   This method makes the webservice callout and creates Integration logs in case of an error or failure
    * @param request
    * @return HttpResponse
    */
    private static HttpResponse makeCallout(HttpRequest request){
        HttpResponse response = new HttpResponse();
        Http http = new Http();
        try {
            response = http.send(request);

            //Record the callout details in case of any error or failure
            if(response.getStatusCode() != 200){
                insertIntegrationLogs(response, request, '');
            }
        }
        catch(System.CalloutException e) {
            insertIntegrationLogs(response, request, e.getMessage());
            throw e;
        }

        return response;
    }

    /**
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   14-09-2021
    * @description  :   This method inserts the Integration logs
    * @param responseObject
    * @param request
    * @param message
    */
    public static void insertIntegrationLogs(HttpResponse responseObject, HttpRequest request, String message) {
        String requestString = request != null ? request.getBody() : '';
        requestString = requestString != '' ? requestString + ' ' + request.toString() : '';

        String resResult = 'UserName :' + UserInfo.getUserName();
        resResult += '<br/>UserId :' + UserInfo.getUserId();
        resResult += '<br/>UserEmail :' + UserInfo.getUserEmail();
        resResult += '<br/><br/>Status Code :' + responseObject.getStatusCode();
        resResult += '<br/><br/>ResBody :' + responseObject.getBody();
        resResult += '<br/><br/>ReqBody :' + requestString;

        Heartbeat_Server_Log__c serverLog = new Heartbeat_Server_Log__c();
        serverLog.Exception_Log__c = resResult;
        serverLog.Type__c = 'Third Party Hardware';
        serverLog.Endpoint__c = request != null ? request.getEndpoint() : '';
        serverLog.Request_Body__c = request != null ? request.getBody() : '';
        serverLog.Response__c = responseObject.getBody();
        serverLog.Error_Message__c = message;
        Database.insert(serverLog, false);
    }

    /**
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   14-09-2021
    * @Jira Ticket  :   CS-679 - Enable offline product activation/registration for third party hardware manufacturing on the Support Portal
    * @description  :   Wrapper class for input data
    */
    public class ThirdPartyHardwareForm{
        /**
        * @description serialNumber
        */
        public String serialNumber {get;set;}
        /**
        * @description uuid
        */
        public String uuid {get;set;}
        /**
        * @description nodeId
        */
        public String nodeId {get;set;}
        /**
        * @description entitlementId
        */
        public String entitlementId {get;set;}
        /**
        * @description manufacturingTime
        */
        public String manufacturingTime {get;set;}
        /**
        * @description teleportToken
        */
        public String teleportToken {get;set;}
    }

    /**
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   14-09-2021
    * @Jira Ticket  :   CS-679 - Enable offline product activation/registration for third party hardware manufacturing on the Support Portal
    * @description  :   Request wrapper class for Post callout to Heartbeat which creates the node in Salesforce
    */
    public class ThirdPartyHardwareNodeRequest{
        /**
        * @description user_id
        */
        public String user_id {get;set;}
        /**
        * @description ipmi_mac_addr
        */
        public String ipmi_mac_addr {get;set;}
        /**
        * @description entitlement_id
        */
        public String entitlement_id {get;set;}
        /**
        * @description system_uuid
        */
        public String system_uuid {get;set;}
        /**
        * @description manufactured_date
        */
        public String manufactured_date {get;set;}
        /**
        * @description teleport_token
        */
        public String teleport_token {get;set;}
        /**
        * @description id
        */
        public String id {get;set;}
        /**
        * @description constructor
        * @param user_id
        * @param ipmi_mac_addr
        * @param entitlement_id
        * @param system_uuid
        * @param manufactured_date
        * @param teleportToken
        * @param node_id
        */
        public ThirdPartyHardwareNodeRequest(String user_id, String ipmi_mac_addr, String entitlement_id, String system_uuid, String manufactured_date, String teleportToken, String node_id){
            this.user_id = user_id;
            this.ipmi_mac_addr = ipmi_mac_addr;
            this.entitlement_id = entitlement_id;
            this.system_uuid = system_uuid;
            this.manufactured_date = manufactured_date;
            this.teleport_token = teleportToken;
            this.id = node_id;
        }
    }

    /*
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   14-09-2021
    * @Jira Ticket  :   CS-679 - Enable offline product activation/registration for third party hardware manufacturing on the Support Portal
    * @Description  :   Request wrapper class for Patch callout to Heartbeat which udpates the manufacturing time on the node created from the first
    *                   callout
    */
    /*public class ThirdPartyHardwareNodePatchRequest{
        public String manufactured_date {get;set;}
        public String serial_number {get;set;}

        public ThirdPartyHardwareNodePatchRequest(String manufactured_date, String serial_number){
            this.manufactured_date = manufactured_date;
            this.serial_number = serial_number;
        }
    }*/

    /**
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   14-09-2021
    * @Jira Ticket  :   CS-679 - Enable offline product activation/registration for third party hardware manufacturing on the Support Portal
    * @description  :   Response wrapper class for Heartbeat responses
    */
    public class ThirdPartyHardwareNodeResponse{
        /**
        * @description authorization_keys
        */
        public String authorization_keys {get;set;}
        /**
        * @description serial_number
        */
        public String serial_number {get;set;}
        /**
        * @description hbx_session_api_token
        */
        public String hbx_session_api_token {get;set;}
        /**
        * @description rksupport_creds
        */
        public String rksupport_creds {get;set;}
        /**
        * @description success
        */
        public String success {get;set;}
        /**
        * @description error
        */
        public String error {get;set;}
        /**
        * @description message
        */
        public String message {get;set;}
    }

    /*
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   14-09-2021
    * @Jira Ticket  :   CS-679 - Enable offline product activation/registration for third party hardware manufacturing on the Support Portal
    * @Description  :   Request wrapper class for Post callout to Teleport which registers the node and generates an entitlement token
    */
    /*public class ThirdPartyHardwareTeleportRequest{
        public String node_id {get;set;}
        public String mfg_date {get;set;}
        public String reg_token {get;set;}

        public ThirdPartyHardwareTeleportRequest(String node_id, String mfg_date, String reg_token){
            this.node_id = node_id;
            this.mfg_date = mfg_date;
            this.reg_token = reg_token;
        }
    }*/

    /*
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   14-09-2021
    * @Jira Ticket  :   CS-679 - Enable offline product activation/registration for third party hardware manufacturing on the Support Portal
    * @Description  :   Response wrapper class for Teleport responses
    */
    /*public class ThirdPartyHardwareTeleportResponse{
        public String entitlement_token {get;set;}
        public String node_id {get;set;}
        public String status {get;set;}
    }*/
}