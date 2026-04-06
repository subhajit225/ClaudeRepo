public without sharing class PC_PactsafeCalloutAgremmentController {
 @future(callout=true)
    public static void callpactsafe(string accId,string accName,string partnertype, string email,string contId){
     Map<string,string> jsonMap = new Map<string,string>();
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
                System.debug('----------------'+res.getBody());
                string resbody = res.getBody();
                JSONParser parser = JSON.createParser(resbody);
                
                jsonMap.put('Master-Reseller','');
                
                string stremail = '';
                string page_query = '';
                string download_url = '';
                List<string> arr = new List<string>();
                List<string> arrtemp = new List<string>();
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
                                for(string key : jsonMap.keyset()){
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
        system.debug('@@ jsonMap '+jsonMap);
        try{
            List<Contract> contractList = new List<Contract>();
            
            for(string key :jsonMap.keyset()){
                if(key == 'Master-Reseller'){
                    Contract mct = new Contract();
                    mct.Terms_Download_Url__c = jsonMap.get(key);
                    mct.ClickThroughContract_Name__c = 'Master';
                    mct.Agreement_Type__c = 'Master Agreement';
                    mct.AccountId = accId;
                    mct.CustomerSignedDate = system.today();
                    mct.CustomerSignedTitle = accName;
                    mct.CustomerSignedId = contId;
                    mct.ContractTerm = 1000;
                    mct.Click_Through__c = true;
                    mct.StartDate = system.today();
                    mct.CompanySignedDate = system.today();
                    mct.CompanySignedId = UserInfo.getuserId();
                    mct.Contract_Status__c = 'Active';
                    contractList.add(mct);
                
                    Contract sct = new Contract();
                    sct.Terms_Download_Url__c = jsonMap.get(key);
                    sct.ClickThroughContract_Name__c = 'Secondary';
                    sct.Agreement_Type__c = 'Reseller';
                    sct.AccountId = accId;
                    sct.CustomerSignedDate = system.today();
                    sct.CustomerSignedTitle = accName;
                    sct.CustomerSignedId = contId;
                    sct.ContractTerm = 1000;
                    sct.Click_Through__c = true;
                    sct.StartDate = system.today();
                    sct.CompanySignedDate = system.today();
                    sct.CompanySignedId = UserInfo.getuserId();
                    sct.Contract_Status__c = 'Active';
                    contractList.add(sct);
                }
            }
            
            if(!contractList.isEmpty()){
                insert contractList;
            }
            if(!jsonMap.isEmpty() && jsonMap.containsKey('Master-Reseller') && !contractList.isEmpty()){
                string termsurl ='<br/>'+jsonMap.get('Master-Reseller');
                PC_pactsafeContractEmailController.sendEmail(termsurl,contId,contractList[0].Id);
            }
			
        }catch(Exception e){
            system.debug('Exception occured '+e.getMessage()+' at line '+e.getLineNumber());
        }
    }
}