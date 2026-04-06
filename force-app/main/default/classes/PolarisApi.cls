public class PolarisApi {
     
    public static Map<String,Polaris_Api_Access_Token__mdt> mapOfPolarisAndPocmanApiDetails = Polaris_Api_Access_Token__mdt.getAll();
    
    public static PolarisTokenResponse getAccessToken() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(mapOfPolarisAndPocmanApiDetails.get('PolarisApiDetailNew').Endpoint__c);
        request.setMethod(mapOfPolarisAndPocmanApiDetails.get('PolarisApiDetailNew').Request_Method__c);
        request.setHeader('Content-type', 'application/x-www-form-urlencoded');
        request.setHeader('Accept', 'application/json');
        request.setHeader('Authorization', mapOfPolarisAndPocmanApiDetails.get('PolarisApiDetailNew').Authorization_Header__c);
        request.setBody('grant_type='+(mapOfPolarisAndPocmanApiDetails.get('PolarisApiDetailNew').Grant_Type__c)+'&scope=pacman');
        HttpResponse response = http.send(request);
        System.debug('output '+response);
        // Parse the JSON response
        if(response.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: ' +
                         response.getStatusCode() + ' ' + response.getStatus());
        } else {
            System.debug(response.getBody());
        }
        PolarisTokenResponse resp = PolarisTokenResponse.parse(response.getBody());
        return resp;
    }
    public static LCC_ButtonsController.response_Wrapper restProvisionApiCall(String RSC_ProcessRecordId) {
        LCC_ButtonsController.response_Wrapper retResponse = new LCC_ButtonsController.response_Wrapper();
        try{
            RSC_Process__c rscRec = [select id ,PolarisRequestID__c,Polaris_Suggest_URL__c,RSC_Contact_Email__c, Expiry_Date__c, Customer_Suggest_URL__c,Owner.email,PolarisRegion__c, AccountID__c, AccountID__r.Name from RSC_Process__c  where AccountID__c != null and id=: RSC_ProcessRecordId limit 1 ];
            PolarisTokenResponse tokenresp =  getAccessToken();
            if(tokenresp.access_token!=null || Test.isRunningTest()) {
                String requestBody= '{'
                    +'"polaris_account_url": "'+String.ValueOf(rscRec.Customer_Suggest_URL__c== null? '': rscRec.Customer_Suggest_URL__c)+'",'+
                    +'"suggested_url": "'+String.ValueOf(rscRec.Polaris_Suggest_URL__c == null? '': rscRec.Polaris_Suggest_URL__c)+'",'+
                    +'"polaris_owner_email": "'+String.ValueOf(rscRec.RSC_Contact_Email__c)+'",'+
                    +'"polaris_account_region": "'+String.ValueOf(rscRec.PolarisRegion__c == null? '':rscRec.PolarisRegion__c)+'",'+
                    +'"sfdc_account_id": "'+String.ValueOf(rscRec.AccountID__c)+'",'+
                    +'"rsc_status_id": "'+String.ValueOf(rscRec.Id)+'",'+
                    +'"sfdc_account_name":"'+String.ValueOf(rscRec.AccountID__r.Name)+'",'+
                    +'"term_end_date": "'+String.ValueOf(rscRec.Expiry_Date__c)+'"}';    
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint(mapOfPolarisAndPocmanApiDetails.get('PacmanApiDetail').Endpoint__c);
                request.setMethod(mapOfPolarisAndPocmanApiDetails.get('PacmanApiDetail').Request_Method__c);
                request.setHeader('Grpc-metadata-user', tokenresp.access_token);
                request.setHeader('Content-Type', 'application/json');
                request.setBody(requestBody);
                 system.debug('req==='+request);
                system.debug(requestBody+'req==='+request);
                HttpResponse response = http.send(request);
                System.debug(response);
                System.debug(response.getBody());
                String jsonReq = response.getBody();
                Map<String, Object> m =  (Map<String, Object>) JSON.deserializeUntyped(jsonReq);
                // Parse the JSON response
                if(response.getStatusCode() != 200) {
                    System.debug('The status code returned was not expected:-' +
                                 response.getStatusCode() + ' ' + response.getStatus());
                    retResponse.isSuccess = false;
                    retResponse.errorMessage = String.valueOf(m.get('message'));
                    rscRec.RSC_Status__c = 'Fail';
                    if(response.getStatusCode() == 400){
                        rscRec.Failure_Reason__c = 'Account id must be present.' +String.valueOf(m.get('message'));
                    }else if(response.getStatusCode() == 403){
                        rscRec.Failure_Reason__c = 'User is not Authenticated.';
                    }else {
                        rscRec.Failure_Reason__c = String.valueOf(m.get('message'));
                    }
                    
                } else {
                    System.debug(response.getBody());
                    rscRec.PolarisRequestID__c = String.valueOf(m.get('request_id'));
                    rscRec.Failure_Reason__c = '';
                    rscRec.RSC_Status__c = 'In-Progress';
                    retResponse.isSuccess = true;
                }
                update rscRec;
            }
        }catch(exception ex){
           retResponse.isSuccess = false;
            retResponse.errorMessage = ex.getMessage();
            RSC_Process__c rscRecFailed = new RSC_Process__c();
            rscRecFailed.id= RSC_ProcessRecordId;
            rscRecFailed.RSC_Status__c = 'Fail';
            rscRecFailed.Failure_Reason__c=ex.getMessage();
            update rscRecFailed;
        }
        return retResponse;
    }
}