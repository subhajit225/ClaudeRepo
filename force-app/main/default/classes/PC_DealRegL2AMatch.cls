public without sharing class PC_DealRegL2AMatch  implements Queueable,Database.AllowsCallouts{
    
    /***************************************
Variable declaration and initialization
***************************************/    
    public static boolean fromL2A = false;
    public static final string CLASS_NAME = 'AccountSearch';
    public static map<string,Object> CMAccFields = new Map<string,object>();
    public static map<string,Object> payloadContainer = new Map<string,object>();
    public static map<string,Object> payload = new Map<string,object>();
    public List<Deal_Registration__c> newDealReg;
    public static string MATCHED = 'Matched';
    public static string NOT_MATCHED = 'Not Matched';
    public static string SUCCESS = 'Success';
    public static boolean stopApprovalRecursion = false;
    public static String OWNER_INACTIVE = 'Account Owner Inactive';
    
    public static string AllianceRecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Alliance').getRecordTypeId();
    public static string ResellerRecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
    public static string OEMRecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('OEM').getRecordTypeId();
    public static string ServiceDeliveryRecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByDeveloperName().get('Service_Delivery_Partner').getRecordTypeId(); // PRIT24-887
    //public static Id domainrecId = Schema.SObjectType.PatchManager__c.getRecordTypeInfosByName().get('Domain').getRecordTypeId();
    
    public PC_DealRegL2AMatch(List<Deal_Registration__c> newDealReg1){
        newDealReg = new List<Deal_Registration__c>();
        this.newDealReg = newDealReg1;
    }
    
    public void execute(QueueableContext context){
        Deal_Registration__c newRec = newDealReg[0];
        Schema.DescribeSObjectResult objDescribe = Deal_Registration__c.getSObjectType().getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        String commaSepratedFields = String.join(new List<String>(fieldMap.keySet()), ',');
        commaSepratedFields += ',Company_Name__r.OwnerId,Company_Name__r.Owner.IsActive,Partner_Lookup__r.OwnerId,Partner_Lookup__r.Owner.IsActive,Partner_Lookup__r.Focused_Partner__c';
        String query = 'SELECT ' + String.escapeSingleQuotes(commaSepratedFields) + ' FROM Deal_Registration__c WHERE Id = \''+ String.escapeSingleQuotes('' + newRec.Id) +'\'';
        List<Deal_Registration__c> drList = Database.query(query);
        System.debug('#drList:'+drList);
        String exceptionOwnerEmail = Label.Deal_reg_exception_owner_email+'%';
        Account accOnDR = new Account();
        /*try {
            /* PatchManager */
            Map<String, List<PatchManager__c>> patchMap = PatchManager.getPatchMap(drList, PatchManager.DEAL_REG); 
            
            Deal_Registration__c drObj = drList[0];
			
            PatchManager__c pmRec = PatchManager.assignDealReg(patchMap, drObj);
            system.debug('drObj.RecordTypeId->'+drObj.RecordTypeId);
            system.debug('drObj.PatchManager__c->'+drObj.PatchManager__c);
            system.debug('pmRec->'+pmRec);
            if(( (drObj.RecordTypeId == ResellerRecordTypeId || drObj.RecordTypeId == OEMRecordTypeId ) && drObj.PatchManager__c == null && pmRec==null) || Test.isrunningTest()){
                Deal_Registration__c dr = drList[0];
                Map<String, CountryWithCode__c> mapStatusCounrtyCodeCustomSetting = CountryWithCode__c.getAll();
				system.debug('newRec->'+newRec.Country__c);
                system.debug('mapStatusCounrtyCodeCustomSetting->'+mapStatusCounrtyCodeCustomSetting);
                system.debug('mapStatusCounrtyCodeCustomSetting.get(newRec.Country__c->'+mapStatusCounrtyCodeCustomSetting.get(newRec.Country__c));
                Http http = new Http();
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                CMAccFields.put('companyName',newRec.Company__c != null ? newRec.Company__c:'');
                CMAccFields.put('street',newRec.Street__c!= null ? newRec.Street__c:'');
                CMAccFields.put('city',newRec.City__c != null ? newRec.City__c:'');
                CMAccFields.put('stateCode',newRec.StateCode__c!= null ? newRec.StateCode__c:'');
                CMAccFields.put('postalCode',newRec.PostalCode__c!= null ? newRec.PostalCode__c:'');
                CMAccFields.put('isoCountrycode',mapStatusCounrtyCodeCustomSetting.get(newRec.Country__c).code__c!= null ? mapStatusCounrtyCodeCustomSetting.get(newRec.Country__c).code__c:'');
                CMAccFields.put('country',newRec.Country__c!= null ? newRec.Country__c:'');
                CMAccFields.put('phone',newRec.Phone__c!= null ? newRec.Phone__c:'');
                CMAccFields.put('sourceId',newRec.Id);
                CMAccFields.put('emailAddress',newRec.Email__c);
                payloadContainer.put('requester',UserInfo.getUserName());
                payloadContainer.put('l2aAccount',CMAccFields);
                payloadContainer.put('requestId',Datetime.now().format('YYYYMMddHHmmssSS')+'_SFDC');
                payload.put('accountSearch',payloadContainer);
                req.setbody(JSON.serialize(payload)) ;
                req.setTimeout(120000);
                req.setEndpoint('callout:Deal_Reg_L2A_Match/l2a/account/search');
                system.debug('Search account request body-->'+req.getbody());

                HTTPResponse res = http.send(req);
                system.debug('@@ res  '+res.toString());
                System.debug('STATUS:'+res.getStatus());
                System.debug('STATUS_CODE:'+res.getStatusCode());
                System.debug('Content: ' + res.getBody());
                // return con;

                String accId = '';
                String confidencecode = '';
                String matchstatus = '';
                String statusDescription = '';
                Boolean successFlag = false;
                String matchCriteria = '';
                try{
                    Map<String, Object> mapResponse = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                    system.debug('@@ mapResponse '+mapResponse);
                    for(String Key : mapResponse.keyset()){
                        if(key == 'results'){
                            Map<String, Object> resultMap = (Map<String, Object>)mapResponse.get(Key);
                            system.debug('@@ resultMap '+resultMap);
                            accId = string.valueOf(resultMap.get('accountId'));
                            matchCriteria = string.valueOf(resultMap.get('matchCriteria'));
                            confidencecode = string.valueOf(resultMap.get('matchConfidence'));
                            matchstatus = string.valueOf(resultMap.get('matchStatus'));
                        }
                        if(key == 'status'){
                            Map<String, Object> statusMap = (Map<String, Object>)mapResponse.get(Key);
                            system.debug('@@ statusMap '+statusMap);
                            if(string.valueOf(statusMap.get('statusDescription')) == SUCCESS && (string.valueOf(statusMap.get('statusCode')) == '200' || string.valueOf(statusMap.get('statusCode')) == '201')){
                                successFlag = true;
                            }
                            statusDescription = string.valueOf(statusMap.get('statusDescription'));
                        }
                    }

                    if(successFlag == false){
                        dr.L2A_Error_Message__c=statusDescription;
                        if((res.getStatusCode() != 200 || res.getStatusCode() != 201) && string.isBlank(statusDescription)){
                            dr.L2A_Error_Message__c=res.getStatus()+' - '+res.getStatusCode();
                        }
                    }else{
                        Account acc = new Account();
                        if(!string.isBlank(accId)){
                            acc = [select Id,ownerId,Owner.IsActive from Account where Id =:accId];
                        }
                        dr.L2A_Confidence_Code__c=confidencecode;
                        dr.L2A_Match_Status__c=matchstatus;
                        dr.L2A_Matched_Account_Id__c = accId;
                        dr.L2A_Match_Criteria__c = matchCriteria;
                        if(!String.isBlank(confidencecode) && Integer.valueOf(confidencecode) >= 3 && matchstatus == MATCHED && acc != null && acc.Owner.IsActive){
                            dr.OwnerId = acc.OwnerId;
                            system.debug('@@ from L2A owner id '+dr.OwnerId);
                        }else if(!acc.Owner.IsActive){
                            dr.L2A_Error_Message__c = OWNER_INACTIVE;
                        }
                    }
                }Catch(exception e){
                    system.debug('@@ Exception occurred '+e.getMessage()+' at line '+e.getLineNumber()+e.getStackTraceString());
                    //update drList;
                    drList = [SELECT Id, OwnerId FROM Deal_Registration__c WHERE Id = :drList[0].Id];
                    drList[0].L2A_Error_Message__c=e.getMessage()+ ' '+e.getStackTraceString();
                    Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Profile.Name FROM User WHERE Id = :drList[0].OwnerId OR Username LIKE :exceptionOwnerEmail]);
                    if(userMap.get(drList[0].OwnerId).Profile.Name.containsIgnoreCase('Rubrik Partner Community')) {
                        for(Id userId : userMap.keySet()) {
                            if(userId != drList[0].OwnerId) {
                                drList[0].OwnerId = userId;
                                drList[0].Deal_Registration_Status__c = system.label.Deal_Reg_Status;
                                break;
                            }
                        }
                    }
                }
            }
            /* L2A match */
            PC_DealRegL2AMatch.fromL2A = true;
        	System.debug('drList 1'+drList);
            flowControll.DealRegistrationTrigger = false;
            update drList;
            flowControll.DealRegistrationTrigger = true;
            Boolean updateDR = false;
            drList = [SELECT Id, OwnerId FROM Deal_Registration__c WHERE Id = :drList[0].Id];
            Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Profile.Name FROM User WHERE Id = :drList[0].OwnerId OR Username LIKE :exceptionOwnerEmail]);
            if(userMap.get(drList[0].OwnerId).Profile.Name.containsIgnoreCase('Rubrik Partner Community')) {
                for(Id userId : userMap.keySet()) {
                    if(userId != drList[0].OwnerId) {
                        drList[0].OwnerId = userId;
                        drList[0].Deal_Registration_Status__c = system.label.Deal_Reg_Status;
                        updateDR = true;
                        break;
                    }
                }
            }
            if(updateDR){
                System.debug('drList 2'+drList);
                flowControll.DealRegistrationTrigger = false;
                update drList;
                flowControll.DealRegistrationTrigger = true;
            }
        /*} catch(Exception e) {
            system.debug('@@ Exception occurred '+e.getMessage()+' at line '+e.getLineNumber()+e.getStackTraceString());
            //if the owner is still a partner, reset the owner to Sarah
            drList = [SELECT Id, OwnerId FROM Deal_Registration__c WHERE Id = :drList[0].Id];
            drList[0].L2A_Error_Message__c=e.getMessage()+ ' '+e.getStackTraceString();
            Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Profile.Name FROM User WHERE Id = :drList[0].OwnerId OR Username LIKE :exceptionOwnerEmail]);
            if(userMap.get(drList[0].OwnerId).Profile.Name.containsIgnoreCase('Rubrik Partner Community')) {
                for(Id userId : userMap.keySet()) {
                    if(userId != drList[0].OwnerId) {
                        drList[0].OwnerId = userId;
                        drList[0].Deal_Registration_Status__c = system.label.Deal_Reg_Status;
                        break;
                    }
                }
            }
            flowControll.DealRegistrationTrigger = false;
            update drList;
            flowControll.DealRegistrationTrigger = true;
        }*/
    }
}