@RestResource(urlMapping='/register/*')
global class ProductRegistrationCallout{

   private static String endpoint =  system.label.hearbeatendpoint; //'https://prod.heartbeat.rubrik.com/cluster/register-edge/';
   //private static String endpoint = 'https://registration.heartbeat.rubrik.com/cluster/register-edge/';

   @HttpPost
   global static void processRegRequest(string accountID, string uuid, string nodename, boolean isDark) {
       
       system.debug('### acctid: '+ accountID + ' uuid: '+uuid+' nodename '+nodename);
         
       RestResponse oresp =  RestContext.response;
       oresp.addHeader('Content-Type', 'application/json');
       
       HttpRequest req = new HttpRequest();
       HttpResponse res = new HttpResponse();
       Http http = new Http();
       String ll = userinfo.getUserId();
       String lla = [SELECT Id,UserName,Contact.AccountId from User where Id=:ll].Contact.AccountId;
       if (lla == null)
       {
           lla = accountID;
       }

       
       //create the string of callout parameters
       endpoint = endpoint + EncodingUtil.urlEncode(uuid, 'UTF-8');
       req.setEndpoint(endpoint);
       req.setMethod('POST');
       Customer_Support_Secrets__c secret = Customer_Support_Secrets__c.getInstance();
       req.setHeader('Authorization', 'Bearer '+secret.HeartBeat_Token__c);
       req.setHeader('Content-Type', 'application/json; charset=UTF-8');
       
       //String reqBody = 'secret='+EncodingUtil.urlEncode(secretKey, 'UTF-8');
       String reqBody = '';
       reqBody += '{"account_id":"'+EncodingUtil.urlEncode(lla, 'UTF-8');
       reqBody += '","id":"'+EncodingUtil.urlEncode(uuid, 'UTF-8');
       reqBody += '","node_name":"'+EncodingUtil.urlEncode(nodename, 'UTF-8');
       //if (isDark != null)   reqBody += '&manual_registration='+isDark;

       reqBody += '"}';
       req.setBody(reqBody);
       system.debug('### reqBody ' + reqBody);
        String respmessage = '{}';
        string regkey = '';

       system.debug(System.LoggingLevel.INFO, '\n ### Request body: ' + req.getBody().replaceAll('\\n',''));
       try {
           if (!Test.isRunningTest()) {
              res = http.send(req);
              
           } else {   
              // res = http.send(req);
               res = new HttpResponse();
               system.debug('### bhanu debug2');             
           }
           system.debug(System.LoggingLevel.INFO, '\n ### Response body: ' + res.getBody()); 
           
           if (res != null && res.getStatusCode() == 200) {
              if(oresp!=null) oresp.statusCode = 200;
               respmessage = res.getBody();
              if(oresp!=null) oresp.responseBody = blob.valueOf(respmessage);
               
           } else {
               string errormessage =  ''; 

               //URL to pass back: System.label.customer_case_url+subject=Registration%20Error&regerror=true&uuid=353254235353+nodename=4543532532523453+regmessage=duplicate%20reg
               oresp.statusCode = 400;
               
               respmessage = res.getBody();
               oresp.responseBody = blob.valueOf(respmessage);

           }
       } catch(System.CalloutException e) {
           System.debug('\n ### callout error: '+ e);
           throw e;
       } catch (system.Dmlexception dmlEx) {
           System.debug('\n ### Exception in reservation : '+ dmlEx);
           throw dmlEx;
       }
        return;

   }

}