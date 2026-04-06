public class PC_PartnerSpecializationRequestCtrlr {
    
    @AuraEnabled
    public Static response_Wrapper getAccountAndContacts(){   
        response_Wrapper response = new response_Wrapper();  
        try{
            List<User> users = [SELECT Contact.AccountId, email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            List<Account> accList = [SELECT id, Name, billingCountry,BillingStateCode,BillingStreet, BillingCity, BillingPostalCode,BillingState, (select id, name from contacts) FROM Account where id=: users[0].Contact.AccountId LIMIT 1];
            response.accList = accList;
            response.userRecds = users;
        } catch(Exception e) {
            response.isSuccess = false;
            response.errorMessage = e.getMessage();
        }
        return response;
    }
    
    @AuraEnabled
    public Static response_Wrapper createSpecilizationRequest(Partner_Specialization_Request__c spReq){ 
        response_Wrapper response = new response_Wrapper();  
        List<User> users = [SELECT Contact.AccountId, ContactId, Contact.Account.ownerId,Contact.Account.Name, email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        try{
            spReq.CDM__c = users[0].Contact.Account.ownerId;
            insert spReq;
            PC_PartnerSpecializationRequestCtrlr.callpactsafe(spReq.Partner_Company_Name__c,users[0].Contact.Account.Name, users[0].email, users[0].ContactId, spReq.id, spReq.Country__c);
            
        } catch(Exception e) {
            response.isSuccess = false;
            response.errorMessage = e.getMessage();
        }
        return response;
    }
    
    @future(callout=true)
    public static void callpactsafe(string accId, string accName, string email,string contId, string requestId, string country){
        System.debug('------------*****--');
        Map<string,string> jsonMap = new Map<string,string>();
        try{
            String Endpoint = 'https://api.pactsafe.com/v1.1/sites/'+system.label.pactsafe_Site_Id+'/activity?filter=event_type==agreed%20and%20signer_id=='+email+'&sort=created_time%20desc';       
            Http http = new Http();
            if(Test.isRunningTest()){
                Endpoint= 'https://pactsafe.com/example/test';
            }
            HttpRequest req = new HttpRequest();
            req.setEndpoint(Endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization','Bearer '+system.label.pactsafe_access_token);
            HTTPResponse res = http.send(req);
            System.debug('----------------'+res.getBody());
            string resbody = res.getBody();
            JSONParser parser = JSON.createParser(resbody);
            
            jsonMap.put('RUBRIK_PROFESSIONAL_SERVICES_PARTNER','');
            
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
                                Map<string,string> mapKeyValue = new Map<string,string>();
                                for(string keyValue : arr){
                                    mapKeyValue.put(keyValue.split('=')[0],keyValue.split('=')[1]);
                                }
                                    
                                stremail = 'email='+email;
                                if(mapKeyValue != null  && mapKeyValue.containskey('email')){
                                    arrtemp = arr[0].split('=');
                                    if(jsonMap != null && jsonMap.containskey('RUBRIK_PROFESSIONAL_SERVICES_PARTNER') && jsonMap.get('RUBRIK_PROFESSIONAL_SERVICES_PARTNER') == ''){
                                        jsonMap.put('RUBRIK_PROFESSIONAL_SERVICES_PARTNER','fill');
                                    }
                                }
                            }
                            system.debug('@@ jsonMap82 '+jsonMap);
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
            List<Partner_Specialization_Request__c> psRequestList = new List<Partner_Specialization_Request__c>();
            List<ProcessInstanceWorkitem> pOWIList = [SELECT Id, ActorId, OriginalActorId, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =: requestId];
            List<GroupMember> approvers =  new List<GroupMember>();
            if(!pOWIList.isEmpty() && pOWIList[0].ActorId != null && pOWIList[0].ActorId.getSObjectType().getDescribe().getName() == 'Group'){
                approvers = [Select UserOrGroupId From GroupMember where GroupId =: pOWIList[0].ActorId];
            }

            for(string key :jsonMap.keyset()){
                if(key == 'RUBRIK_PROFESSIONAL_SERVICES_PARTNER'){
                    system.debug('@@  jsonMap.get(key)** '+ jsonMap.get(key));
                    Contract mct = new Contract();
                    mct.Terms_Download_Url__c = jsonMap.get(key);
                    mct.ClickThroughContract_Name__c = 'Rubrik Professional Services Partner';
                    mct.Agreement_Type__c = 'RPSP';
                    mct.AccountId = accId;
                    mct.CustomerSignedDate = system.today();
                    mct.CustomerSignedTitle = accName;
                    mct.CustomerSignedId = contId;
                    mct.ContractTerm = 1000;
                    mct.Territory_Country__c = country;
                    mct.Click_Through__c = true;
                    mct.StartDate = system.today();
                    mct.Contract_Status__c = 'Active';
                    mct.CompanySignedDate = system.today();
                    mct.CompanySignedId = UserInfo.getuserId();
                    contractList.add(mct);
                    
                    Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();          
                    req.setComments('Submitting approval request ');        
                    req.setObjectId(requestId);
                    // Submit the approval request for the Opportunity        
                    Approval.ProcessResult result = Approval.process(req); 
                    Partner_Specialization_Request__c spRequest = new Partner_Specialization_Request__c();
                    spRequest.id = requestId;
                    spRequest.Pactsafe_URL__c = jsonMap.get(key);
                    if(!approvers.isEmpty() && approvers[0].UserOrGroupId != null)
                    	spRequest.Ownerid = approvers[0].UserOrGroupId;
                        psRequestList.add(spRequest);
                }
            }
            if(!psRequestList.isEmpty()){
                update psRequestList;
            }
            if(!contractList.isEmpty()){
                insert contractList;
            }
            
        }catch(Exception e){
            system.debug('Exception occured '+e.getMessage()+' at line '+e.getLineNumber());
        }
    }
    
    @InvocableMethod
    public static void setRoleToQueue(List<Id> reqIds){
        setRoleToQueueFuture(reqIds);
    } 
    
    @future
    public static void setRoleToQueueFuture(List<Id> reqIds) {
        Partner_Specialization_Request__c reqRec = [Select id , contact__c from Partner_Specialization_Request__c where id=:reqIds[0] ];
        if(reqRec.contact__c == null) return;
        User usr = [ Select id ,UserRole.Id, ContactId from user where ContactId =:reqRec.contact__c ]; 
        if(usr.UserRole == null) return;
        Group grp = [select Id from Group where DeveloperName='Partner_Specialization_RPSP'];
        Group grp2 = [select Id from Group where relatedid=: usr.UserRole.id And Type='Role' Limit 1];
        GroupMember m = new GroupMember();
        m.UserOrGroupId = grp2.id;
        m.GroupId = grp.Id;
        insert m;
    }
    
    public class response_Wrapper {
        @auraEnabled public List<Contact> contactRecords{get;set;}
        //@auraEnabled public Map<String,List<picklistOptions>> pickListOptns{get;set;}
        @auraEnabled public List<Account> accList{get;set;} 
        @auraEnabled public List<user> userRecds{get;set;}    
        @auraEnabled public boolean isSuccess{get;set;}
        @auraEnabled public string errorMessage  {get;set;}
        
        public response_Wrapper(){
            this.isSuccess = true;
            this.errorMessage = '';
            this.userRecds = new List<user>();
            this.contactRecords = new List<Contact>();
            this.accList = new List<Account>();
            //this.pickListOptns = new Map<String,List<picklistOptions>>();
            
        }
        
    }
}