/**
* @Author      : Vijay Kumar K R
* @CreatedDate :  
* @TstClass    : HbxProxyTest
* @Description :
* -------------------------- @History -------------------------------------
* Story Number       Modified By              Date           Description
* 
* -------------------------------------------------------------------------
*/
@RestResource(urlMapping='/hbxproxy/*')
global class HbxProxy  {
    public class HBXToken {
        public String hbx_session_api_token, serial_number;
    }
    
    // Sandbox Settings
    // private static String hbxurl =  system.label.hbxsandboxurl;
    // private static String hbxapitoken = system.label.hbxsandboxapikey;
    // Production Settings
    private static String hbxurl;
    private static String hbxapitoken;
    public static string regkey {get; set;}
 
    private static void passThroughReq(String endUserId,
                                       String endUserContactId,
                                       String endUserAccountId,
                                       RestRequest incomingreq, String method) {

        Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        //Set sandbox related attributes
        if(isSandbox) {
            hbxurl = System.Label.hbxsandboxurl;
            hbxapitoken = System.Label.hbxsandboxapikey;
        }
        //Set Production related attributes
        else {
            hbxurl = System.Label.hbxprodurl;
            hbxapitoken = System.Label.hbxprodapikey;
        }
        
        string endpoint = hbxurl + incomingreq.requestURI.removeStart('/hbxproxy/');
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader('Authorization', 'Bearer ' + hbxapitoken);
        req.setHeader('Content-Type', 'application/json; charset=UTF-8');
        req.setHeader('AccountId', endUserAccountId);
        req.setHeader('ContactId', endUserContactId);
        req.setHeader('UserId', endUserId);
        if(string.isNotblank(system.label.hbxproxyTimeout)){
            req.setTimeout(integer.valueof(system.label.hbxproxyTimeout));
         }
        

        if (method == 'POST') {
            req.setBodyAsBlob(incomingreq.requestBody);    
        }

        Http http = new Http();
        HttpResponse hbxresp = new HttpResponse();
        hbxresp = http.send(req);
        RestResponse oresp =  RestContext.response;
        oresp.addHeader('Content-Type', 'application/json');
        if (hbxresp == null) {
            oresp.statusCode = 400;
            oresp.responseBody = blob.valueOf('{"message": "Unknown Error"}');                                               
        } else {
            oresp.statusCode = hbxresp.getStatusCode();                                 
            oresp.responseBody = blob.valueOf(hbxresp.getBody());
        }
        return;
    }

    @HttpPost
    global static void processPostRequest() {
        String ll = userinfo.getUserId();
        Contact endUserContact = [SELECT Id, UserName, Contact.AccountId from User where Id=:ll].Contact;
        String enduserAccountId = endUserContact.AccountId;
        passThroughReq(ll,
                       endUserContact.Id,
                       enduserAccountId, 
                       RestContext.request,
                       'POST');
     }  
}