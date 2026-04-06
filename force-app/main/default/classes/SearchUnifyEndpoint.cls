global class SearchUnifyEndpoint {
    
    global static Map<String, Object> SearchResults(String body){
        Customer_Support_Secrets__c secret = Customer_Support_Secrets__c.getInstance();
        String instanceUrl =  'https://rubrik.searchunify.com';
        
        String Uid = secret.SU_UID__c;
       
        String accessToken = secret.SU_Token__c;
        
        String JSONs;
        Boolean searchUnifyDownStatus  = false;
        Map<String, Object> m = new Map<String, Object>();
        Map<String, Object> JsonQuery = (Map<String, Object>)JSON.deserializeUntyped(body);
        String userId = '';
        String ContactId = '';
        String ProfileId = '';
        String AccountId = '';
        String userType = '';
        String emailId = '';
        try{            
            List<User> userList = [SELECT Id,Email,contactId,profileId,userType,AccountId from User WHERE ID=:UserInfo.getUserId()];
            if(!userList.IsEmpty()){
                ContactId = userList[0].contactId;
                ProfileId = userList[0].profileId;
                userId = userList[0].Id;
                AccountId = userList[0].AccountId;
                userType = 'cspliteportal';
                emailId = userList[0].Email;
            }     
            
            String orgId = UserInfo.getOrganizationId();
            if(ContactId != null)
                JsonQuery.put('ContactId',ContactId);
            if(ProfileId != null)
                JsonQuery.put('ProfileID',ProfileId);
            if(userId != null)
                JsonQuery.put('UserId',userId); 
            if(AccountId != null)
                JsonQuery.put('AccountID',AccountId); 
            if(userType != null)
                JsonQuery.put('UserType',userType); 
            JsonQuery.put('accessToken',accessToken);
            JsonQuery.put('uid',Uid);
            String FinalJson = JSON.serialize(JsonQuery);
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            HttpResponse res = new HttpResponse();
            req.setEndpoint(instanceUrl+'/search/searchResultByPost');
            req.setHeader('content-type','application/json');        
            req.setMethod('POST');
            req.setTimeOut(120000);
            req.setBody(FinalJson);
            
            if(!Test.isrunningTest()) {
                try{ 
                    res = http.send(req);
                }catch(Exception ex){
                    System.debug(LoggingLevel.Info,'the exception in the callToSearchUnify is = '+ex);
                }
            } 
            if (Test.isrunningTest() || (res.getStatusCode()==200 && res.getStatus().toLowerCase() == 'ok')) {
                JSONs = res.getBody();
                m = (Map<String, Object>)JSON.deserializeUntyped(JSONs);
                m.put('searchDownStatus', false);
                m.put('searchCallFail', '');
                return m;
                
            } else {
                searchUnifyDownStatus = true;
                m.put('searchDownStatus', searchUnifyDownStatus);
                m.put('searchCallFail', '');
                return m;
            }
            
        } catch(Exception ex){
            m.put('searchCallFail', ex.getMessage());
            return m;
        } 
    }   
    
}