public with sharing class L2AService {

	//MKT23-634 Deployment
    public Map<String,Object> getPayload(List<Lead> leadRecords){
        Map<String,Object> payload = new Map<String,Object>();
        List<Map<String, String>> accFields = new List<Map<String, String>>();
        for(Lead leadRecord : leadRecords){
            accFields.add(getAccFields(leadRecord.Company,
                    leadRecord.street,
                    leadRecord.city,
                    leadRecord.stateCode,
                    leadRecord.PostalCode,
                    leadRecord.CountryCode,
                    leadRecord.country,
                    leadRecord.phone,
                    leadRecord.Id,
                    leadRecord.email
                ));
        }
        Map<String,Object> payloadContainer = new Map<String,Object>();
        payloadContainer.put('requester',UserInfo.getUserName());
        payloadContainer.put('l2aAccount',accFields);
        payloadContainer.put('requestId',Datetime.now().format('YYYYMMddHHmmssSS')+'_SFDC');
        
        payload.put('accountSearch',payloadContainer);                        
        return payload;
    }
    public Map<String, String> getAccFields(String companyName,
                                         String street,
                                         String city,
                                         String stateCode,
                                         String postalCode,
                                         String isoCountrycode,
                                         String country,
                                         String phone,
                                         String sourceId,
                                         String emailAddress){
        Map<String,String> accFields = new Map<String,String>();
        accFields.put('companyName',companyName);
        accFields.put('street',street);
        accFields.put('city',city);
        accFields.put('stateCode',stateCode);
        accFields.put('postalCode',postalCode);
        accFields.put('isoCountrycode',isoCountrycode);
        accFields.put('country',country);
        accFields.put('phone',phone);
        accFields.put('sourceId',sourceId);
        accFields.put('emailAddress',emailAddress);
        return accFields;
    }
//MKT23-634 Deployment
    public ResponseWrapper callService(Map<String,Object> payload){
        ResponseWrapper response = new ResponseWrapper();
		System.debug('serialized payload:'+JSON.serialize(payload));
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        HTTPResponse res = new HTTPResponse();
        req.setMethod('POST'); 
        req.setbody(JSON.serialize(payload));
        req.setTimeout(120000); 
        req.setEndpoint('callout:Deal_Reg_L2A_Match/l2a/account/BulkSearch');
        if(Test.isRunningTest()){
            
        res.setHeader('Content-Type', 'application/json');
       
            res.setBody('{"status":{"statusDescription":"Success","statusCode":"200"},"l2aAccount":[{"matchStatus":"Matched","matchConfidence":"3","matchCriteria":"Company,ISO Country Code","accountId":"0016f00002fA9EtAAK","sourceId":"00Q4000001JbaZWEAZ"}],"requester":"ankush.dubey@rubrik.com.rbkuat","requestId":"20220930030413243_SFDC"}');
            res.setStatusCode(200);
        } else { 
            
            res = http.send(req); 
           
               }

        if(200 == res.getStatusCode() || 201 == res.getStatusCode()){
            Map<String, Object> mapResponse = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            system.debug('mapResponse###'+JSON.serialize(mapResponse));
            for(String key : mapResponse.keyset()){
                if('status' == key){
                    Map<String, Object> statusMap = (Map<String, Object>)mapResponse.get(key);
                    response.statusCode = String.valueOf(statusMap.get('statusCode'));
                    response.statusDescription = String.valueOf(statusMap.get('statusDescription'));
                }
                if('l2aAccount' == key){
                    response.l2aAccount = (List<Object>)mapResponse.get(Key);
                }
            }
        }
        return response;
    }

    public class ResponseWrapper{
        public List<Object> l2aAccount{get;set;}
        Map<String, Object> status{get;set;}
        String statusCode{get;set;}
        String statusDescription{get;set;}
    }
    public class L2AResultWrapper{
        public String sourceId{get;set;}
        public String accountId{get;set;}
        public String matchCriteria{get;set;}
        public String matchConfidence{get;set;}
        public String matchStatus{get;set;}
    }
}