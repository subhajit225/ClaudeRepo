/*
* Date : 1/31/2019
* Purpose : to populate Terms & Conditions related signed contracts on Partner onboarding form
*/
public without sharing class PC_PactsafeCalloutController {
    @future(callout=true)
    public static void callpactsafe(String onboardingId, String partnertype, String email){
        Map<String,String> jsonMap = new Map<String,String>();
        Custom_Error_Log__c errorLog = new Custom_Error_Log__c();
        String contractGenerationStatus = '';
        if(partnertype != 'Alliance Partner'){
            try{
                String Endpoint = 'https://api.pactsafe.com/v1.1/sites/'+system.label.pactsafe_Site_Id+'/activity?filter=event_type==agreed%20and%20signer_id=='+email+'&sort=created_time%20desc';
                Http http = new Http();
                if(Test.isRunningTest()){
                    Endpoint= 'http://pactsafe.com/example/test';
                }
                HttpRequest req = new HttpRequest();
                req.setEndpoint(Endpoint);
                req.setMethod('GET');
                req.setHeader('Authorization','Bearer '+system.label.pactsafe_access_token);
                HTTPResponse res = http.send(req);
                if(res.getStatusCode() == 200 && res.getStatus() == 'OK'){
                    contractGenerationStatus = 'Successful';
                } else {
                    contractGenerationStatus = 'Error';
                    errorLog.Http_Request__c = 'GET';
                    errorLog.Http_StatusCode__c = String.valueOf(res.getStatusCode());
                    errorLog.Functionality__c = 'Partner Onboarding';
                    errorLog.Http_Response__c = res.getBody();
                    errorLog.Class__c = 'PC_PactsafeCalloutController';
                }
                System.debug('----------------'+res.getBody());
                String resbody = res.getBody();
                JSONParser parser = JSON.createParser(resbody);

                jsonMap.put('Master','');
                if(partnertype == 'Reseller' || partnertype == 'MSP-Reseller'){
                    jsonMap.put('Secondary','');
                }
                if(partnertype == 'MSP-Reseller' || partnertype == 'MSP'){
                    jsonMap.put('Tertiary','');
                }
                String stremail = '';
                String page_query = '';
                String download_url = '';
                List<String> arr = new List<String>();
                List<String> arrtemp = new List<String>();
                while (parser.nextToken() != null) {
                    if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                        String text = parser.getText();
                        if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                            if (text == 'page_query') {
                                page_query = parser.getText();
                                system.debug('@@ page_query '+page_query);
                                if(page_query.contains('&')){
                                    arr = page_query.split('&');
                                    stremail = 'email='+email;
                                    if(arr.size() > 2 && arr[2] == stremail && arr[0].contains('=')){
                                        arrtemp = arr[0].split('=');
                                        system.debug('## arrtemp '+arrtemp);
                                        if(jsonMap != null && jsonMap.containskey(arrtemp[1]) && jsonMap.get(arrtemp[1]) == ''){
                                            system.debug('## in arrtemp[1] '+arrtemp[1]);
                                            jsonMap.put(arrtemp[1],'fill');
                                        }
                                    }
                                }
                            }else if (text == 'download_url') {
                                download_url = parser.getText();
                                system.debug('@@ download_url '+download_url);
                                for(String key : jsonMap.keyset()){
                                    if(jsonMap.get(key) == 'fill'){
                                        jsonMap.put(key,download_url);
                                    }
                                }
                            }
                        }
                    }
                }
            }catch(Exception e){
                system.debug('Exception occured '+e.getMessage()+' at line '+e.getLineNumber());
            }
        }
        system.debug('@@ jsonMap '+jsonMap);
        try{
            Partner_Onboarding_Request__c PO_Request = [SELECT Id,Partner_Onboarding_Status__c,Master_Terms__c,Secondary_Terms__c,Tertiary_Terms__c
                                                        FROM Partner_Onboarding_Request__c
                                                        WHERE id =:onboardingId];
            PO_Request.Partner_Onboarding_Status__c ='Pending';
            if(jsonMap !=null && !jsonMap.isEmpty() && contractGenerationStatus.equals('Successful')){
                for(String key :jsonMap.keyset()){
                    if(key == 'Master'){
                        PO_Request.Master_Terms__c = jsonMap.get(key);
                    }else if(key == 'Secondary'){
                        PO_Request.Secondary_Terms__c = jsonMap.get(key);
                    }else if(key == 'Tertiary'){
                        PO_Request.Tertiary_Terms__c = jsonMap.get(key);
                    }
                }
                PO_Request.Contract_Generation__c = contractGenerationStatus;
            }else if(contractGenerationStatus.equals('Error')){
                PO_Request.Contract_Generation__c = contractGenerationStatus;
                String exceptionOwnerID = Label.POB_Exception_UserId;
                PO_Request.OwnerId = exceptionOwnerID;
                insert errorLog;
            }
            update PO_Request;
        }catch(Exception e){
            system.debug('Exception occured '+e.getMessage()+' at line '+e.getLineNumber());
            Custom_Error_Log__c errorLogRec = new Custom_Error_Log__c();
            errorLogRec.Class__c = 'PC_PactsafeCalloutController';
            errorLogRec.Exception_Message__c = e.getMessage();
            errorLogRec.Functionality__c = 'Partner Onboarding';
            insert errorLogRec;
        }
    }
}