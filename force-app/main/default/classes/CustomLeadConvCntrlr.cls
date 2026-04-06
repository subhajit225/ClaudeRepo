/*******************************************************************************************************
Description : Controller class for VF page CustomLeadConversion 
Developer : Chaitra
Date : 7/8/2019
**********************************************************************************************************/

public without sharing class CustomLeadConvCntrlr {
    
    /* VARIABLE INITIALIZATION */
    
    public static final string CLASS_NAME ='CustomLeadConvCntrlr';
    public Lead ldSource {get;set;}
    private Lead leadRecord{get;set;}
    public string searchType {get;set;}
    public string accName {get;set;}
    public string oppName{get;set;}
    public String requestLabel;
    public boolean sendEmailToOwner{get;set;}
    public boolean showAccount{get;set;} // for dialogue box
    public CMAccountSearch SearchRes ;
    public string selectedrowIndex{get;set;} // to store selected account index 01-em or 01-pm
    public string temAccRowIndex{get;set;}
    public string CMErrorMsg {get;set;}
    public string leadConvertErrMsg ;
    public Custom_Error_Log__c IntegrationLog ;
    public map<string,Object> CMAccFields = new Map<string,object>();
    public map<string,Object> payloadContainer = new Map<string,object>();
    public map<string,Object> payload = new Map<string,object>();
    public List<CMAccountSearch.CMAccount> exactAccMatch {get;set;}
    public List<CMAccountSearch.CMAccount> potentialAccMatch {get;set;}
    public static final string OPP_ERROR = 'Please enter Opportunity Name or check DO NOT CREATE OPPORTUNITY' ;
    public static final string ACC_ERROR = 'Please select account' ;
    public static final string LEAD_ERROR = 'Please enter country and company name to proceed with lead conversion' ;
    public static final string INCOMPLETE_ACCDETAILS = 'There is no matching account found, to create new account please enter Company, Country, Street and either City, State or Postal code' ;
    public Boolean dontCreateOpp {get;set;}
    public string selectedLeadStatus{get;set;}
    public Task taskSobj{get;set;}
    public String strStatus {get;set;}
    public static string query;
    public static string whereClause='';
    public Id leadConvStatus;
    public static Map<string,account>accId_account = new Map<string,account>();
    public Map<String,String> country_CountryCode=new Map<String,String>();
    public Map<String,String> state_StateCode=new Map<String,String>();
    public  Id accId {get;set;}
    
    /* Controller */
    public CustomLeadConvCntrlr(ApexPages.StandardController controller) {
        try{
            potentialAccMatch = new List<CMAccountSearch.CMAccount>();
            exactAccMatch = new List<CMAccountSearch.CMAccount>();
            CMErrorMsg = null;
            selectedrowIndex =null ;
            Id leadId = ApexPages.currentPage().getParameters().get('id') ;    
            leadRecord = (Lead)controller.getRecord();
            ldSource = [SELECT Id, FirstName, isFederalIntel__c,Website,LastName,CountryCode,OwnerId,Company,CompanyDunsNumber__c, Phone,city,country,street,state,statecode,PostalCode FROM Lead WHERE Id =: leadId];
            if(ldSource.CountryCode == null || ldSource.Company == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,LEAD_ERROR));
                return ; 
            } 
            OppName = ldSource.Company+'-' ;
            dontCreateOpp = false;
            taskSobj = new task();
            showAccount = false;
        }
        Catch(exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,e.getMessage()));
            return ; 
        }
    }
    
/*********************************************
Desc : To get possible lead conversion status
***********************************************/
    
    public List<Selectoption> getLeadStatus(){
        try{
            List<Selectoption> LeadStat = new List<selectoption>();
            LeadStat.add(new selectOption('', '- None -'));
            for(LeadStatus LS:  [select Id, MasterLabel FROM LeadStatus WHERE IsConverted=true]){
                LeadStat.add(new selectoption(LS.MasterLabel,LS.MasterLabel));
            }
            return LeadStat;
        }
        Catch(exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,e.getMessage()));
            return null; 
        }
    }
    
/*********************************************************************************************
Desc : To get exact and possible account matches with reference to lead from company master
***********************************************************************************************/
    
    public object AccountDetails(){
        try{
            system.debug('Search Start'+System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS'));
            if(ldSource.isFederalIntel__c){
                whereClause = ' isFederalIntel__c ='+ldSource.isFederalIntel__c ;
                searchInternalAccount();
                return null;
            }else{
                Continuation con = new Continuation(40);
                con.continuationMethod='processResponse';
                // Create callout request
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');  
                req.setEndpoint('callout:Company_Master/account/search');
                CMAccFields.put('accountName',ldSource.Company);
                CMAccFields.put('addressLine1',ldSource.street != null ? ldSource.street : '');
                CMAccFields.put('city',ldSource.city != null ? ldSource.city : '');
                CMAccFields.put('state',ldSource.state != null ? ldSource.state : '');
                CMAccFields.put('stateCode',ldSource.stateCode != null ? ldSource.stateCode : '');
                CMAccFields.put('postalCode',ldSource.postalCode != null ? ldSource.postalCode : '');
                CMAccFields.put('country',ldSource.Country != null ? ldSource.Country : '');
                CMAccFields.put('isoCountrycode',ldSource.CountryCode != null ? ldSource.CountryCode : '');
                CMAccFields.put('phone',ldSource.Phone != null ? ldSource.Phone : '');
                CMAccFields.put('website',ldSource.Website != null ? ldSource.Website : '');
                CMAccFields.put('isFederalintel',ldSource.isFederalIntel__c);
                CMAccFields.put('sourceName','SFDC');
                payloadContainer.put('requestId',Datetime.now().format('YYYYMMddHHmmssSS')+'_SFDC');
                payloadContainer.put('requester',UserInfo.getUserName());
                payloadContainer.put('CMAccount',CMAccFields);
                payload.put('accountSearch',payloadContainer);
                req.setbody(JSON.serialize(payload)) ;
                system.debug('CM RequestBody'+req.getbody());
                requestLabel = con.addHttpRequest(req);
                system.debug('CM callout label'+requestLabel);
                IntegrationLog = new Custom_Error_Log__c(Class__c = CLASS_NAME,Http_Request__c= req.getbody(),Server_Endpoint__c=req.getEndpoint(),Type__c='Outbound Integration',Functionality__c ='CompanyMaster',Request_Time__c =System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS'));
                return con;
                
            }     
        }
        Catch(exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,e.getMessage()));
            return null; 
        }  
    }
    
    // Callback method 
    public Object processResponse() {   
        try{
            List<Id> AccountIds = new List<Id>();
            accId_account.clear(); 
            HttpResponse response = Continuation.getResponse(this.requestLabel);
            IntegrationLog.Response_Time__c =System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS');
            system.debug('CM search api statuscode'+response.getStatusCode());
            system.debug('CM search api response -->'+response.getBody());
            IntegrationLog.Http_Response__c = response.getBody().abbreviate(131071);
            IntegrationLog.Http_StatusCode__c = string.valueof(response.getStatusCode()) ;
            if(response.getStatusCode() == 200){
                CMAccountSearch searchRes = (CMAccountSearch)JSON.deserialize(response.getBody(),CMAccountSearch.class);
                system.debug('application res Status code'+searchRes.status.statusCode);
                if(searchRes.status.statusCode == '200' || searchRes.status.statusCode == '201'){
                    system.debug('CM search process result'+searchRes.Results);
                    searchType ='External-CM';
                    if(searchRes.Results.CMAccount.accountName != null && searchRes.Results.CMAccount.isoCountrycode != null && ((Schema.sObjectType.Account.isCreateable()== false && searchRes.Results.CMAccount.newAccount.equalsIgnoreCase('N')) ||Schema.sObjectType.Account.isCreateable())) // to check if there is empty exact match record as accName and country are mandatory fields
                    {
                        exactAccMatch.add(searchRes.Results.CMAccount);
                        system.debug('res accountId'+searchRes.Results.CMAccount.sourceID);
                        if(searchRes.Results.CMAccount.sourceID != '' && searchRes.Results.CMAccount.sourceID != null && searchRes.Results.CMAccount.sourceID != 'None')
                            AccountIds.add(searchRes.Results.CMAccount.sourceID);
                        else
                            searchRes.Results.CMAccount.accountOwner = '';
                        
                        /* default onload exact match as account selection
selectedrowIndex = '0-em';  
selectAccount(); */         
                    }
                    
                    potentialAccMatch.addall(searchRes.Results.potentialAccounts);
                    if(potentialAccMatch.size()==0 && exactAccMatch.size()==0 && Schema.sObjectType.Account.isCreateable()== false ){
                          ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,'There is no matching account found,please reach out to your SDR to convert into a new account')); 
                          CMErrorMsg = 'There is no matching account found,please reach out to your SDR to convert into a new account';
                    }
                    for(CMAccountSearch.CMAccount PM : searchRes.Results.potentialAccounts){
                        if(PM.sourceID != null && PM.sourceID != '' && PM.sourceID!='None')
                            AccountIds.add(PM.sourceID);
                        else
                            PM.accountOwner = '';
                    }
                    
                    system.debug('Exact Match'+exactAccMatch);
                    system.debug('potential AccMatch'+potentialAccMatch);
                    
                    for(account acc: [select id,owner.name,recordtype.name,Account_Status__c from account where id IN: AccountIds ]){
                        accId_account.put(acc.id,acc);
                    }
                    /*searchRes.Results.CMAccount.accountOwner = accId_account.containsKey(searchRes.Results.CMAccount.sourceID) ? accId_account.get(searchRes.Results.CMAccount.sourceID).owner.name:searchRes.Results.CMAccount.sourceID != null && searchRes.Results.CMAccount.sourceID != '' && searchRes.Results.CMAccount.sourceID!='None'?'Not found':'' ;
searchRes.Results.CMAccount.recTypeName = accId_account.containsKey(searchRes.Results.CMAccount.sourceID) ? accId_account.get(searchRes.Results.CMAccount.sourceID).recordtype.name:searchRes.Results.CMAccount.sourceID != null && searchRes.Results.CMAccount.sourceID != '' && searchRes.Results.CMAccount.sourceID!='None'?'Not found':'' ;*/
                    
                    if(accId_account.containsKey(searchRes.Results.CMAccount.sourceID)){
                        searchRes.Results.CMAccount.accountOwner = accId_account.get(searchRes.Results.CMAccount.sourceID).owner.name ;
                        searchRes.Results.CMAccount.recTypeName = accId_account.get(searchRes.Results.CMAccount.sourceID).recordtype.name ;
                        searchRes.Results.CMAccount.accountStatus = accId_account.get(searchRes.Results.CMAccount.sourceID).Account_Status__c ;
                    }
                    else if(searchRes.Results.CMAccount.sourceID != null && searchRes.Results.CMAccount.sourceID != '' && searchRes.Results.CMAccount.sourceID!='None'){
                        searchRes.Results.CMAccount.accountOwner = searchRes.Results.CMAccount.recTypeName = searchRes.Results.CMAccount.accountStatus ='Not found';
                        
                    }
                    else{
                        searchRes.Results.CMAccount.accountOwner = searchRes.Results.CMAccount.recTypeName = searchRes.Results.CMAccount.accountStatus ='';
                        
                    }
                    
                    for(CMAccountSearch.CMAccount PM : searchRes.Results.potentialAccounts){
                        /*PM.accountOwner = accId_account.containsKey(PM.sourceID) ? accId_account.get(PM.sourceID).owner.name:PM.sourceID != null && PM.sourceID != '' && PM.sourceID!='None'?'Not found':'' ;
PM.recTypeName = accId_account.containsKey(PM.sourceID) ? accId_account.get(PM.sourceID).recordtype.name:PM.sourceID != null && PM.sourceID != '' && PM.sourceID!='None'?'Not found':'' ; */
                        if(accId_account.containsKey(PM.sourceID)){
                            PM.accountOwner = accId_account.get(PM.sourceID).owner.name ;
                            PM.recTypeName = accId_account.get(PM.sourceID).recordtype.name ;
                            PM.accountStatus = accId_account.get(PM.sourceID).Account_Status__c ;
                        }
                        else if(PM.sourceID != null && PM.sourceID != '' && PM.sourceID!='None'){
                            PM.accountOwner = PM.recTypeName = PM.accountStatus ='Not found';
                            
                        }
                        else{
                            PM.accountOwner = PM.recTypeName = PM.accountStatus ='';
                            
                        }               
                    }
                    IntegrationLog.Result__c = 'Success';
                }
                else if(searchRes.status.statusCode == '204'){
                  IntegrationLog.Result__c = 'Success';
                   //CMErrorMsg = 'There is no matching account found';
                  // ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,'There is no matching account found'));
                  system.debug('Account is creatable'+Schema.sObjectType.Account.isCreateable()); 
                  if(Schema.sObjectType.Account.isCreateable()){
                  CMErrorMsg = INCOMPLETE_ACCDETAILS;
                  ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,INCOMPLETE_ACCDETAILS)); 
                  }      
                  else{
                      CMErrorMsg = 'There is no matching account found,please reach out to your SDR to convert into a new account';
                      ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,'There is no matching account found,please reach out to your SDR to convert into a new account')); 
                  }     
                }
                else if(searchRes.status.statusCode.startswith('5')){ // Server application errors make internal search
                    IntegrationLog.Result__c = 'Application Failure';
                    searchInternalAccount();
                }
                else {
                    IntegrationLog.Result__c = searchRes.status.statusCode.startswith('2') ?'Success':'Application Failure';
                    CMErrorMsg = SearchRes.Status.statusDescription;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,searchRes.status.statusDescription)); 
                }
            }
            else if(response.getStatusCode().format().startswith('5')){ // Server errors make internal search
                IntegrationLog.Result__c = 'Server Failure'; 
                searchInternalAccount();
                
            }
            else{  // 3xx and 4xx series
                IntegrationLog.Result__c = response.getStatusCode().format().startswith('2')?'Success':'Server Failure'; 
                CMErrorMsg = response.getStatusCode()+'-'+response.getStatus();
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,response.getStatusCode()+'-'+response.getStatus()));   
            }
        }
        Catch(exception e){
            IntegrationLog.Result__c = 'Salesforce Exception';
            IntegrationLog.id = null;
            IntegrationLog.ErrorTrace__c= String.format('{0}\n{1}\n\n\n\n',new List<String>{'Exception type :'+e.getTypeName(),'Trace : '+e.getStackTraceString()}).abbreviate(131071); 
            IntegrationLog.Exception_Message__c= e.getmessage();
            CMErrorMsg = e.getMessage();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,e.getMessage()));
            
        }
        if(SetupCompanyMaster__c.getOrgDefaults().Log_API_Calls__c)
            Insert IntegrationLog ;
        system.debug('Search Stop'+System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS'));
        return null; 
    }
    
/********************************
Desc : To show account pop up
*********************************/
    
    public void searchAccount(){
        showAccount = true;
    }
    
/*******************************************************
Desc : To store the selected account row and name
*********************************************************/
    
    public void selectAccount(){
        try{
            selectedrowIndex = temAccRowIndex;
            showAccount = false;
            if(CMErrorMsg!=null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error,CMErrorMsg));
                return ;
            }
            system.debug('selectedrowIndex'+selectedrowIndex);
            system.debug('exactMatch'+exactAccMatch+'potentialAccMatch'+potentialAccMatch);
            if(string.isNotBlank(selectedrowIndex) && string.isNotEmpty(selectedrowIndex)){
                if(selectedrowIndex.endsWith('pm')){
                    accName = potentialAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].accountName;
                }
                else if(selectedrowIndex.endsWith('em')){
                    accName = exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].accountName;   
                }
                else{
                    system.debug('Error in account selection');
                }
            } 
        }
        Catch(exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,e.getMessage()));
            return ; 
        }
    }
    
/*********************************************************************************************
Desc : To cancel the current account selection
***********************************************************************************************/
    public void closePopUp(){ 
        temAccRowIndex = selectedrowIndex; 
        showAccount = false; 
        if(CMErrorMsg!=null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error,CMErrorMsg));
        }  
    }
    
/*********************************************************************************************
Desc : 
Exact match - create new account if doesnt exist in SF and set it for using in lead conversion
Potential Match - set selected account for using in lead conversion
***********************************************************************************************/
    
    public PageReference createORsetAccount() {
        try{
            system.debug('Create Account Start'+System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS'));
            PageReference pgref; 
            leadConvertErrMsg =''; 
            if((string.isBlank(oppName)|| string.isEmpty(oppName))&& dontCreateOpp == false){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,OPP_ERROR));
                leadConvertErrMsg = OPP_ERROR ;
                return null;
            }     
            if(!Test.isRunningTest() && !dontCreateOpp && leadRecord.Opportunity_Amount__c==null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error,'Please enter the Opportunity amount'));
                leadConvertErrMsg = 'Please enter the Opportunity amount' ;
                return null;
            }
            system.debug('CP createORsetAccount start selectedrow'+selectedrowIndex+'em'+exactAccMatch);
            if(string.isNotBlank(selectedrowIndex) && string.isNotEmpty(selectedrowIndex)){ 
                if(selectedrowIndex.endsWith('pm')){
                    if(string.isNotBlank(potentialAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].accountOwner) && potentialAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].accountOwner != 'None'){
                        accId = potentialAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].sourceID;
                        leadConvStatus = convertLead();
                        if(leadConvStatus != null){
                            return new PageReference('/' +leadConvStatus);
                        }
                    }
                    else{
                        leadConvertErrMsg = 'AccountId is invalid';    
                        //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,'AccountId is invalid'));  
                    }
                }
                else if(selectedrowIndex.endsWith('em')){
                    if(exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].newAccount.equalsIgnoreCase('y')){
                        
                        Account acc = new account(CMID__c = exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].CMID , Name =exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].accountName , Billingcountrycode =exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].isoCountrycode ,BillingCity=exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].city , BillingStateCode = exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].stateCode,
                                                  BillingpostalCode= exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].postalCode , BillingStreet = exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].addressLine1+exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].addressLine2 , D_U_N_S__c =exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].dunsNumber );
                         acc.OwnerId = ldSource.OwnerId;
                        acc.isFederalIntel__c = ldSource.isFederalIntel__c;
                        system.debug('acc insertion'+acc);
                         Savepoint stopAccountCreation = Database.setSavepoint();
                        Database.SaveResult accSaveRes = Database.insert(acc,false);          
                        if (accSaveRes.isSuccess()) {
                            system.debug('Account Inserted');
                            system.debug('CP searchType'+searchType);
                            accId = acc.id ;
                            if(searchType =='SF Internal'){
                            leadConvStatus = convertLead();
                            if(leadConvStatus != null){
                                return new PageReference('/' +leadConvStatus);
                            }
                            else{
                             Database.rollback(stopAccountCreation);
                             
                             }
                           } 
                           else if(searchType =='External-CM'){
                               system.debug('CP lead convert start');
                               leadConvStatus = convertLead();
                               system.debug('CP lead convert end'+leadConvStatus);
                               if(leadConvStatus == null){
                               Database.rollback(stopAccountCreation);                    
                             }
                               
                           }
                        }
                        else {                   
                            for(Database.Error err : accSaveRes.getErrors()) {    
                                leadConvertErrMsg = err.getMessage();                 
                            }
                        }
                    }
                    else{
                        if(string.isNotBlank(exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].accountOwner) && exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].accountOwner != 'None'){
                            accId = exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].sourceID;
                            leadConvStatus = convertLead();
                            if(leadConvStatus != null){
                                return new PageReference('/' +leadConvStatus);
                            }
                        }                
                        else{
                            leadConvertErrMsg = 'AccountId is invalid';
                            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,'AccountId is invalid'));
                        }     
                    }
                }
                else{
                    leadConvertErrMsg = 'Select one account';   
                }
            }
            else{
                leadConvertErrMsg = ACC_ERROR;
            }      
        }
        catch(exception e){
            leadConvertErrMsg = e.getMessage();
        } 
        system.debug('CP createORsetAccount End');
        return null; 
    }
    
/************************************************************************************
Description : call company master once the account is successfully inserted in SF
************************************************************************************/
    
    public pagereference PostAccountConvertLead(){
        system.debug('CP leadConvertErrMsg'+leadConvertErrMsg);
        HttpRequest req = new HttpRequest();
        HTTPResponse res ;
        try{
            IntegrationLog = new Custom_Error_Log__c(Class__c = CLASS_NAME,Functionality__c ='CompanyMaster');
            if(!string.isBlank(leadConvertErrMsg)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,leadConvertErrMsg));   
                return null;
            }
            system.debug('In PostAccount'+searchType+'selectedrowIndex'+selectedrowIndex+'exactAccMatch'+exactAccMatch);
            if(searchType =='External-CM' && selectedrowIndex.endsWith('em') && exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].newAccount.equalsIgnoreCase('Y')){  // CP check if extra em,y checks are needed
                system.debug('Post acc account'+accId);
                req.setMethod('POST'); 
                req.setEndpoint('callout:Company_Master/account/create'); 
                CMAccFields.clear();
                payload.clear();
                CMAccFields.put('CMID',(exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].CMID));
                CMAccFields.put('sourceID',accId);
                CMAccFields.put('sourceName','SFDC');
                CMAccFields.put('requester',UserInfo.getUserName());
                CMAccFields.put('requestId',Datetime.now().format('YYYYMMddHHmmssSS')+'_SFDC');
                payload.put('createAccount',CMAccFields);
                req.setbody(JSON.serialize(payload)) ;
                system.debug('Postacc Request'+req.getbody());
                req.setTimeout(120000); 
                Http http = new Http();
                IntegrationLog.Request_Time__c =System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS');
                res = http.send(req);
                IntegrationLog.Response_Time__c =System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS');
                IntegrationLog.Http_Request__c= req.getbody();
                IntegrationLog.Server_Endpoint__c=req.getEndpoint();
                IntegrationLog.Type__c='Outbound Integration';
                IntegrationLog.Http_Response__c=res.getbody();
                IntegrationLog.Http_StatusCode__c= string.valueof(res.getStatusCode());
                system.debug('Postacc res'+res);
                if(res.getStatusCode() == 200){
                    Map<String, Object> accPostRes = (Map<String, Object>) JSON.deserializeUntyped(res.getbody());
                    system.debug('accPostRes'+accPostRes);
                    if((string)((Map<string,object>)accPostRes.get('status')).get('statusCode')== '200' || (string)((Map<string,object>)accPostRes.get('status')).get('statusCode')== '201' || ((string)(((Map<string,object>)accPostRes.get('status')).get('statusCode'))).startswith('5')){
                       // leadConvStatus = convertLead();
                        if(leadConvStatus != null){               
                            account leadAcc = new account(id=accId);
                            if(!String.isBlank(string.valueof(accPostRes.get('CMAccount')))){
                                leadAcc.D_U_N_S__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('dunsNumber');
                                leadAcc.Site_Business_Name__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('dunsBusinessName');
                                leadAcc.NumberOfEmployees = ((Map<string,object>)accPostRes.get('CMAccount')).get('guEmployeeCount') ==''?0:Integer.valueof(((Map<string,object>)accPostRes.get('CMAccount')).get('guEmployeeCount'));
                                leadAcc.GU_Annual_Revenue__c = ((Map<string,object>)accPostRes.get('CMAccount')).get('guRevenueUSD')==''?0:(Decimal) ((Map<string,object>)accPostRes.get('CMAccount')).get('guRevenueUSD');
                                leadAcc.Duns_SIC2_code__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('dunsSIC2Code');
                                leadAcc.Duns_SIC2_description__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('dunsSIC2Description');
                                leadAcc.Website = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('dunsDomainName');
                                leadAcc.Tradestyle__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('dunsTradeStyleName');
                                leadAcc.DU_Duns_Number__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('duDunsNumber');
                                leadAcc.DU_Business_Name__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('duBusinessName');
                                leadAcc.GU_Duns_Number__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('guDunsNumber');
                                leadAcc.GU_Business_Name__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('guBusinessName');
                                leadAcc.AnnualRevenue = ((Map<string,object>)accPostRes.get('CMAccount')).get('siteRevenueUSD')==''?0:(Decimal) ((Map<string,object>)accPostRes.get('CMAccount')).get('siteRevenueUSD');
                                leadAcc.Site_Employees__c = ((Map<string,object>)accPostRes.get('CMAccount')).get('siteEmployeeCount') ==''?0:Integer.valueof(((Map<string,object>)accPostRes.get('CMAccount')).get('siteEmployeeCount'));
                                leadAcc.Parent_Duns_Number__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('hqDunsNumber');
                                leadAcc.Parent_Business_Name__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('hqBusinessName');
                                leadAcc.Industry = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('industryCategory');
                                if(string.isNotEmpty(leadAcc.industry) && ((Map<string,object>)accPostRes.get('CMAccount')).get('industrySubCategory') != ''){
                             if( CheckFieldValidity.validatedependantPicklist(Account.Industry_Subcategory__c ,leadAcc.Industry,(string)((Map<string,object>)accPostRes.get('CMAccount')).get('industrySubCategory')) == true )
                                leadAcc.Industry_Subcategory__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('industrySubCategory') ; 
                            }
                                update leadAcc ;
                            }
                            else{    
                                // If there are no enrichment attribs returned
                                IntegrationLog.Result__c = 'Application Failure';
                                IntegrationLog.Exception_Message__c ='There are no enrichment attributes returned';
                                system.debug('There are no enrichment attributes returned');
                            }
                            IntegrationLog.Result__c = ((string)(((Map<string,object>)accPostRes.get('status')).get('statusCode'))).startswith('5') == true ? 'Application Failure':'Success';
                            if(SetupCompanyMaster__c.getOrgDefaults().Log_API_Calls__c)
                                Insert IntegrationLog ; 
                            system.debug('Create Account Stop'+System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS'));
                            return new PageReference('/' +leadConvStatus);
                        }
                    }
                    else {
                        IntegrationLog.Result__c = 'Success';
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,accPostRes.get('statusCode')+'-'+accPostRes.get('statusDescription'))); 
                    }
                }
                else if(res.getStatusCode().format().startswith('5')){ // Server errors 
                    //leadConvStatus = convertLead();
                    IntegrationLog.Result__c = 'Server Failure' ;
                    if(SetupCompanyMaster__c.getOrgDefaults().Log_API_Calls__c)
                        Insert IntegrationLog ; 
                    system.debug('Create Account Stop'+System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS'));
                     if(leadConvStatus != null){
                                return new PageReference('/' +leadConvStatus);
                            }                    
                }
                else{
                    IntegrationLog.Result__c = 'Server Failure' ;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,res.getStatusCode()+'-'+res.getStatus()));   
                    
                } }
            system.debug('CP In PostAccount END');
        }
        catch(exception e){
            IntegrationLog.Result__c = 'Salesforce Exception';
            IntegrationLog.ErrorTrace__c= String.format('{0}\n{1}\n\n\n\n',new List<String>{'Exception type :'+e.getTypeName(),'Trace : '+e.getStackTraceString()}); 
            IntegrationLog.Exception_Message__c= e.getmessage();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,e.getmessage()));   
        }
        if(SetupCompanyMaster__c.getOrgDefaults().Log_API_Calls__c)
            Upsert IntegrationLog;
        system.debug('Create Account Stop'+System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS'));
        return null;
    }
    
/************************************
Desc :  CUstom lead conversion
*************************************/
    
    public Id convertLead(){
        update leadRecord;
        system.debug('Lead Conversion begins'+accId);
        Database.LeadConvert lc = new Database.LeadConvert();
        try{
        lc.setLeadId(ldSource.Id);
        lc.setOwnerId(ldSource.OwnerId);
        lc.setSendNotificationEmail(sendEmailToOwner);
        lc.setAccountId(accId); 
        lc.setDoNotCreateOpportunity(dontCreateOpp);
        if(dontCreateOpp == false) { lc.setOpportunityName(oppName); }
        lc.setConvertedStatus(selectedLeadStatus);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        taskSobj.recordtypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Task').getRecordTypeId();
        taskSobj.WhatId = lcr.getOpportunityId() ;
        taskSobj.WhoId = lcr.getContactId();
        /*List<Schema.FieldSetMember> fieldSetMemberList =  Schema.SObjectType.Task.fieldSets.getMap().get('LCTaskInformation').getFields();
        for(Schema.FieldSetMember FSM : fieldSetMemberList)
        { 
           system.debug('CP field -'+FSM.getFieldPath()+'-->'+ taskSobj.get(FSM.getFieldPath()));
           if(FSM.getFieldPath() != 'RecordTypeId' && FSM.getFieldPath() != 'ActivityDate' && taskSobj.get(FSM.getFieldPath()) != null){
            createTask = true;
            break;
           }
           
       }*/
       if(taskSobj.Subject != null && taskSobj.Type != null)
        insert taskSobj ;
        
        system.debug('CP Lead COnversion End'+lcr);
        if(lcr.isSuccess()) { 
            return (Id)lcr.getAccountId();    
        } else {
            for(Database.Error err : lcr.getErrors()) {    
                system.debug('lead conversion failed');       
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,err.getMessage()));
                leadConvertErrMsg = err.getMessage();             
            }
            return null;
        } 
       }
       catch(exception e){
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,e.getmessage())); 
         leadConvertErrMsg = e.getMessage();
         return null;
       }  
        
    }
    
/***** ********** ********** *********** ********* ************************
Description : Method used for searching accounts within salesforce 
When : federal account , Company master server is down

*** ********** ********** ********** ***********************************/
    public void searchInternalAccount(){
        List<account> sfdcaccList = new List<Account>();
        query ='select id,Name,D_U_N_S__c,owner.name,Billingcountry,recordtype.name,billingstate,account_status__c,BillingStateCode,billingcity,billingpostalcode,BillingStreet,billingcountrycode,Phone,website from account where';  
        system.debug('In Search whereClause '+whereClause);
        searchType ='SF Internal';
        if(String.isNotBlank(whereClause))
            whereClause+= ' and';
        if(ldSource.Company != null)  
            whereClause+= ' Name = \''+String.escapeSingleQuotes(ldSource.Company)+'\'' ;
        if(ldSource.CompanyDunsNumber__c != null)
            whereClause+= ' and D_U_N_S__c = \''+String.escapeSingleQuotes(ldSource.CompanyDunsNumber__c)+'\'' ;
        if(ldSource.countrycode != null)
            whereClause+= ' and Billingcountrycode =\''+String.escapeSingleQuotes(ldSource.countrycode)+'\'' ;
        if(ldSource.StateCode != null)
            whereClause+= ' and BillingStateCode = \''+String.escapeSingleQuotes(ldSource.StateCode)+'\'';
        if(ldSource.City != null)
            whereClause+= ' and BillingCity = \''+String.escapeSingleQuotes(ldSource.City)+'\'' ;
        if(ldSource.Street != null)
            whereClause+= ' and BillingStreet = \''+String.escapeSingleQuotes(ldSource.Street)+'\'';
        if(ldSource.postalCode != null)
            whereClause+= ' and BillingpostalCode = \''+String.escapeSingleQuotes(ldSource.postalCode)+'\'';
        if(ldSource.Phone != null)
            whereClause+= ' and Phone =\''+String.escapeSingleQuotes(ldSource.Phone)+'\'';
        if(ldSource.Website!= null) 
            whereClause+= ' and Website = \''+String.escapeSingleQuotes(ldSource.Website)+'\'';
        query += whereClause ;
        system.debug('query-->'+query);
        sfdcaccList = database.query(query);
        system.debug('Salesforce search resluts'+sfdcaccList);
        if(sfdcaccList.size()>0){
            for(account acc : sfdcaccList){
                exactAccMatch.add(new CMAccountSearch.CMAccount(acc.id,acc.name,acc.owner.name,
                                                                acc.billingstreet,acc.billingcity,acc.billingstate,acc.billingstatecode,
                                                                acc.billingpostalCode,acc.billingcountry,acc.D_U_N_S__c ,acc.billingcountrycode,acc.recordtype.name,acc.account_status__c));
            }
        }
        else{
            if(ldSource.Street == null && ldSource.isFederalIntel__c == false && (ldSource.City == null || ldSource.StateCode == null || ldSource.PostalCode == null)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,'No Matches Found, insufficient information found on lead to create new account'));
                return ;
            }
            if(Schema.sObjectType.Account.isCreateable()){
            CMAccountSearch.CMAccount createSFAcc =new CMAccountSearch.CMAccount(null,ldSource.company,null,
                                                                                 ldSource.street != null ? ldSource.street:'',
                                                                                 ldSource.city != null ? ldSource.city:'',
                                                                                 ldSource.state != null ? ldSource.state:'',
                                                                                 ldSource.statecode != null ? ldSource.statecode:'',
                                                                                 ldSource.postalCode != null ? ldSource.postalCode:'',
                                                                                 ldSource.country != null ? ldSource.country:'',
                                                                                 ldSource.CompanyDunsNumber__c != null ? ldSource.CompanyDunsNumber__c:'' ,
                                                                                 ldSource.countrycode != null ? ldSource.countrycode:'','','');            
            createSFAcc.newAccount ='Y';
            exactAccMatch.add(createSFAcc);
           } 
        }
    }
    
/***********************************
Desc : Redirect to lead record
************************************/
    
    public PageReference RedirectBack(){
        String recId1 = ApexPages.currentPage().getParameters().get('id');
        String recId =  String.isBlank(recId1) ? null : String.escapeSingleQuotes(recId1.escapeHtml4()); 
        PageReference pageRef = new PageReference('/' + recId);
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    
    
}