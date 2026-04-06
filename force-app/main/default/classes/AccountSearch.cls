/*******************************************************************************************************
Description : Controller class for CompanyMaster and salesforce internal account search 
Developer : Chaitra
Date : 7/8/2019

**********************************************************************************************************/
public without sharing class AccountSearch {
    
    /***************************************
    Variable declaration and initialization
    ***************************************/    
        public static final string CLASS_NAME = 'AccountSearch';
        public string BillingStateName{get;set;}
        public Account searchAccount{get;set;}
        public Account accToinsert{get;set;}
        public boolean ShowAccount{get;set;}
        public string selectedRow {get;set;}
        public string searchType {get;set;}
        public Custom_Error_Log__c IntegrationLog ;
        public List<RecordType> AccRectype{get;set;}
        public string RetrieveStatus {get;set;}
        public string RedirectTo {get;set;}
        public String requestLabel;
        //public boolean displayPopUp{get;set;} // account detail view
        public List<CMAccountSearch.CMAccount> potentialMatch {get;set;}
        public List<CMAccountSearch.CMAccount> exactMatch{get;set;}
        public Map<String,String> country_CountryCode=new Map<String,String>();
        //public Map<String,String> state_StateCode=new Map<String,String>();
        public map<string,Object> CMAccFields = new Map<string,object>();
        public map<string,Object> payloadContainer = new Map<string,object>();
        public map<string,Object> payload = new Map<string,object>();
        public static Map<string,account>accId_account = new Map<string,account>();
        public static string query;
        public static string whereClause='';
        public string errAccInsert {get;set;}
        public boolean IsfederalIntel {get;set;}
        
    /*************************************
    Description : constructor 
    **************************************/
        public AccountSearch(ApexPages.StandardController controller) {
            try{
                
                Schema.sObjectType objType = Account.getSObjectType();
                Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
                map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
                for (Schema.PicklistEntry country : fieldMap.get('BillingCountryCode').getDescribe().getPickListValues()){
                    country_CountryCode.put(country.getValue(),country.getLabel());
                }
                errAccInsert = searchType='';
                ShowAccount = true;
                potentialMatch = new List<CMAccountSearch.CMAccount>();
                exactMatch = new List<CMAccountSearch.CMAccount>();
                AccRectype = new List<RecordType>();
                searchAccount = (account)controller.getRecord();
                searchAccount.Billingcountrycode='US';
                // displayPopUp = false;
                AccRectype = [SELECT Name,Description FROM RecordType WHERE SobjectType='Account'];
            }
            Catch(exception e){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,e.getMessage()));
                return ; 
            }
            
        }
        
    /**********************************************
    Description : To Start or stop the CM service 
    ************************************************/   
        
        public PageReference init()
        {
            PageReference returnURL;
            if (SetupCompanyMaster__c.getOrgDefaults().Enable_CM__c == false){
                returnURL = new PageReference('/setup/ui/recordtypeselect.jsp');
                returnURL.getParameters().put('retURL', '/001/o');
                returnURL.getParameters().put('ent', 'Account');
                returnURL.getParameters().put('save_new_url','001/e');
                returnURL.getParameters().put('nooverride','1');
                system.debug('returnURL'+returnURL);
                return returnURL ; 
            }
            else    
                return null;
        }
    /*************************************************************************************************************
    Description : To search account within salesforce incase of federal account and server downtime
    or search non-federal account in company master DB
    ***************************************************************************************************************/
        
        public object createSearchAccount(){
            try{
                system.debug('Search Start'+System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS'));
                IsfederalIntel = searchAccount.isFederalIntel__c ; 
                potentialMatch.clear(); 
                exactMatch.clear(); 
                CMAccountSearch.CMAccount CMAcc ;
                system.debug('BillingState'+BillingStateName+' searchAccount'+searchAccount);
                if(searchAccount.isFederalIntel__c){
                    whereClause = ' isFederalIntel__c ='+searchAccount.isFederalIntel__c ;
                    searchInternalAccount();
                    return null;
                }else{  
                    Continuation con = new Continuation(40);
                    con.continuationMethod='processResponse';
                    HttpRequest req = new HttpRequest();
                    req.setMethod('POST'); 
                    CMAccFields.put('accountName',searchAccount.name != null ? searchAccount.name:'');
                    CMAccFields.put('addressLine1',searchAccount.BillingStreet!= null ? searchAccount.BillingStreet:'');
                    CMAccFields.put('city',searchAccount.billingcity != null ? searchAccount.billingcity:'');
                    CMAccFields.put('state',BillingStateName!= null && !BillingStateName.contains('None')? BillingStateName:'');
                    CMAccFields.put('stateCode',searchAccount.BillingStateCode!= null ? searchAccount.BillingStateCode:'');
                    CMAccFields.put('postalCode',searchAccount.billingpostalCode!= null ? searchAccount.billingpostalCode:'');
                    CMAccFields.put('isoCountrycode',searchAccount.BillingCountryCode!= null ? searchAccount.BillingCountryCode:'');
                    CMAccFields.put('country',country_CountryCode.get(searchAccount.BillingCountryCode));
                    CMAccFields.put('phone',searchAccount.Phone!= null ? searchAccount.Phone:'');
                    CMAccFields.put('website',searchAccount.Website!= null ? searchAccount.Website:'');
                    CMAccFields.put('isFederalintel',searchAccount.isFederalIntel__c);
                    CMAccFields.put('sourceName','SFDC');
                    payloadContainer.put('requester',UserInfo.getUserName());
                    payloadContainer.put('CMAccount',CMAccFields);
                    payloadContainer.put('requestId',Datetime.now().format('YYYYMMddHHmmssSS')+'_SFDC');
                    payload.put('accountSearch',payloadContainer);
                    req.setbody(JSON.serialize(payload)) ;
                    req.setEndpoint('callout:Company_Master/account/search');
                    system.debug('Search account request body-->'+req.getbody());
                    requestLabel = con.addHttpRequest(req);
                    IntegrationLog = new Custom_Error_Log__c(Class__c = CLASS_NAME,Http_Request__c= req.getbody(),Server_Endpoint__c=req.getEndpoint(),Type__c='Outbound Integration',Functionality__c ='CompanyMaster',Request_Time__c =System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS'));
                    system.debug('Search account Request Label'+requestLabel);
                    return con; 
                }
            }
            Catch(exception e){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,e.getMessage()));
                return null; 
            } 
        }  
        
        public Object processResponse() {   
            try{
                List<Id> AccountIds = new List<Id>();
                accId_account.clear(); //clear
                system.debug('Search account requestLabel'+IntegrationLog);
                HttpResponse response = Continuation.getResponse(this.requestLabel);
                IntegrationLog.Response_Time__c = System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS');
                system.debug('Search account statuscode'+response.getStatusCode());
                system.debug('Search account response'+response.getBody());
                IntegrationLog.Http_Response__c = response.getBody();
                IntegrationLog.Http_Response__c = (String.isNotBlank(IntegrationLog.Http_Response__c) && IntegrationLog.Http_Response__c.length() > 131000) ? IntegrationLog.Http_Response__c.left(131000) : IntegrationLog.Http_Response__c;//SAL22-515
                IntegrationLog.Http_StatusCode__c = string.valueof(response.getStatusCode()) ;
                if(response.getStatusCode() == 200){
                    CMAccountSearch searchRes = (CMAccountSearch)JSON.deserialize(response.getBody(),CMAccountSearch.class);
                    system.debug('Search account parse response'+searchRes);                
                    if(searchRes.status.statusCode == '200' || searchRes.status.statusCode == '201'){
                        searchType ='External-CM';
                        if(!(searchRes.Results.CMAccount.accountName == null && searchRes.Results.CMAccount.isoCountrycode == null)) // to check if there is empty exact match record as accName and country are mandatory fields
                        {
                            exactMatch.add(searchRes.Results.CMAccount);
                            if(searchRes.Results.CMAccount.sourceID != '' && searchRes.Results.CMAccount.sourceID != null && searchRes.Results.CMAccount.sourceID != 'None')
                                AccountIds.add(searchRes.Results.CMAccount.sourceID);
                            else
                                searchRes.Results.CMAccount.accountOwner = '';
                            
                        }
                        
                        potentialMatch.addall(searchRes.Results.potentialAccounts);
                        for(CMAccountSearch.CMAccount PM : searchRes.Results.potentialAccounts){
                            if(PM.sourceID != null && PM.sourceID != '' && PM.sourceID!='None')
                                AccountIds.add(PM.sourceID);
                            else
                                PM.accountOwner = '';
                        }
                        
                        system.debug('Exact match'+searchRes.Results.CMAccount);
                        system.debug('Potential Match'+searchRes.Results.potentialAccounts);
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
                            /* PM.accountOwner = accId_account.containsKey(PM.sourceID) ? accId_account.get(PM.sourceID).owner.name:PM.sourceID != null && PM.sourceID != '' && PM.sourceID!='None'?'Not found':'' ;
    PM.recTypeName = accId_account.containsKey(PM.sourceID) ? accId_account.get(PM.sourceID).recordtype.name:PM.sourceID != null && PM.sourceID != '' && PM.sourceID!='None'?'Not found':'' ;*/
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
                    else if(searchRes.status.statusCode.startswith('5')){ // Server application errors make internal search
                        IntegrationLog.Result__c = 'Application Failure';
                        searchInternalAccount();
                    }
                    else {
                        IntegrationLog.Result__c = searchRes.status.statusCode.startswith('2') ?'Success':'Application Failure';
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,searchRes.status.statusDescription)); 
                    }
                }
                else if(response.getStatusCode().format().startswith('5')){ // Server errors make internal search
                    IntegrationLog.Result__c = 'Server Failure'; 
                    searchInternalAccount();
                    
                }
                else{  // 3xx and 4xx series
                    IntegrationLog.Result__c = response.getStatusCode().format().startswith('2')?'Success':'Server Failure'; 
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,response.getStatusCode()+'-'+response.getStatus()));   
                }
            }
            Catch(exception e){
                IntegrationLog.Result__c = 'Salesforce Exception';
                IntegrationLog.ErrorTrace__c= String.format('{0}\n{1}\n\n\n\n',new List<String>{'Exception type :'+e.getTypeName(),'Trace : '+e.getStackTraceString()}); 
                IntegrationLog.Exception_Message__c= e.getmessage();
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,e.getMessage()));
                
            }
            if(SetupCompanyMaster__c.getOrgDefaults().Log_API_Calls__c)
                Insert IntegrationLog ;
            system.debug('Search Stop'+System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS'));
            return null; 
        }
        
    /*****************************************************************************
    Description : to show the detailed view of accountdetails in pop-up
    Method show detail : to open pop up
    Method close : to close pop up
    *****************************************************************************/
        /* public void ShowDetail(){
    system.debug('selectedAccount'+selectedRow);
    displayPopUp = true;
    
    }
    public void close(){
    displayPopUp = false;
    }*/
        
    /**************************************
    Redirect to account record detail page
    *************************************/
        
        public PageReference AccRedirect()
        {
            system.debug('RedirectTo' + RedirectTo);
            PageReference pageRef = new PageReference('/' + RedirectTo);
            pageRef.setRedirect(true);
            return pageRef;
            
        }
    /***************************************************
    Add selected account to temp account for insertion
    **************************************************/
        public void RequestAccCreation(){
            try{
                ShowAccount = false;
                system.debug('selectedRow'+selectedRow+' searchAccount'+searchAccount);
                if(IsfederalIntel){
                    accToinsert =new account(Name =exactMatch[integer.valueof(integer.valueof(selectedrow.substringBefore('-')))].accountName , isFederalIntel__c= true, Billingcountrycode =exactMatch[integer.valueof(integer.valueof(selectedrow.substringBefore('-')))].isoCountrycode ,BillingCity=exactMatch[integer.valueof(integer.valueof(selectedrow.substringBefore('-')))].city , BillingStatecode = exactMatch[integer.valueof(integer.valueof(selectedrow.substringBefore('-')))].stateCode,
                                             BillingpostalCode= exactMatch[integer.valueof(integer.valueof(selectedrow.substringBefore('-')))].postalCode , BillingStreet = exactMatch[integer.valueof(integer.valueof(selectedrow.substringBefore('-')))].addressLine1+exactMatch[integer.valueof(integer.valueof(selectedrow.substringBefore('-')))].addressLine2 , D_U_N_S__c =exactMatch[integer.valueof(integer.valueof(selectedrow.substringBefore('-')))].dunsNumber ,Phone=exactMatch[integer.valueof(integer.valueof(selectedrow.substringBefore('-')))].Phone ,Website=exactMatch[integer.valueof(integer.valueof(selectedrow.substringBefore('-')))].Website);                   
                }
                else{
                    if(selectedrow.endsWith('em')){
                        accToinsert =new account(CMID__c = exactMatch[integer.valueof(integer.valueof(selectedrow.substringBefore('-')))].CMID , Name =exactMatch[integer.valueof(integer.valueof(selectedrow.substringBefore('-')))].accountName , Billingcountrycode =exactMatch[integer.valueof(integer.valueof(selectedrow.substringBefore('-')))].isoCountrycode ,BillingCity=exactMatch[integer.valueof(integer.valueof(selectedrow.substringBefore('-')))].city , BillingStatecode = exactMatch[integer.valueof(integer.valueof(selectedrow.substringBefore('-')))].stateCode,
                                                 BillingpostalCode= exactMatch[integer.valueof(integer.valueof(selectedrow.substringBefore('-')))].postalCode , BillingStreet = exactMatch[integer.valueof(integer.valueof(selectedrow.substringBefore('-')))].addressLine1+exactMatch[integer.valueof(integer.valueof(selectedrow.substringBefore('-')))].addressLine2 , D_U_N_S__c =exactMatch[integer.valueof(integer.valueof(selectedrow.substringBefore('-')))].dunsNumber );
                    }
                    else if(selectedrow.endsWith('pm')){
                        accToinsert =new account(CMID__c = potentialMatch[integer.valueof(integer.valueof(selectedrow.substringBefore('-')))].CMID , Name =potentialMatch[integer.valueof(selectedrow.substringBefore('-'))].accountName , Billingcountrycode =potentialMatch[integer.valueof(integer.valueof(selectedrow.substringBefore('-')))].isoCountrycode ,BillingCity=potentialMatch[integer.valueof(integer.valueof(selectedrow.substringBefore('-')))].city , BillingStatecode = potentialMatch[integer.valueof(integer.valueof(selectedrow.substringBefore('-')))].stateCode,
                                                 BillingpostalCode= potentialMatch[integer.valueof(integer.valueof(selectedrow.substringBefore('-')))].postalCode , BillingStreet = potentialMatch[integer.valueof(integer.valueof(selectedrow.substringBefore('-')))].addressLine1+potentialMatch[integer.valueof(selectedrow.substringBefore('-'))].addressLine2 , D_U_N_S__c =potentialMatch[integer.valueof(integer.valueof(selectedrow.substringBefore('-')))].dunsNumber );
                    }
                }
                if(AccRectype.isEmpty())
                    AccRectype = [SELECT Name,Description FROM RecordType WHERE SobjectType='Account'];
            }
            Catch(exception e){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,e.getMessage()));
                return ; 
            }
        }
        
    /***************************************************
    Convert temp account to salesforce account 
    **************************************************/
        
        public PageReference CreateAccount()
        {
            try{
                system.debug('Create Account Start'+System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS'));
                errAccInsert = '' ;
                system.debug('Account to be inserted'+accToinsert);
                if(accToinsert.id == null){
                    Database.SaveResult accSaveRes = Database.insert(accToinsert,false);
                    if (accSaveRes.isSuccess() == false) {      
                        system.debug('acc insert failed');
                        for(Database.Error err : accSaveRes.getErrors()) {
                            errAccInsert = err.getMessage();
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,err.getMessage()));
                        }
                    }
                    else{
                        system.debug('account Inserted'+accToinsert); 
                        if(IsfederalIntel || searchType =='SF Internal'){     
                            PageReference pageRef = new PageReference('/' + accSaveRes.getId());
                            pageRef.setRedirect(true);
                            return pageRef;
                        }}
                }
            }
            Catch(exception e){
                errAccInsert = e.getMessage();
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,e.getMessage()));
            }
            return null; 
        }
        
        public void Cancel(){
            ShowAccount = true;
        }
        
    /************** ********** *********** ********* ************************
    Description : Method used for searching accounts within salesforce 
    When : federal account , Company master server is don
    
    *** ********** ********** ********** ***********************************/
        public void searchInternalAccount(){
            CMAccountSearch.CMAccount createSFAcc ;
            searchType ='SF Internal';
            query ='select id,Name,D_U_N_S__c,Billingcountry,billingstate,Type,account_status__c,recordtypeId,recordtype.name,BillingStateCode,billingcity,billingpostalcode,BillingStreet,billingcountrycode,Phone,website,owner.name from account where '; 
            List<account> sfdcaccList = new List<Account>();
            system.debug('In Search whereClause '+whereClause);
            try{
                if(String.isNotBlank(whereClause))
                    whereClause+= ' and';
                if(searchAccount.Name != null)  
                    whereClause+= ' Name = \''+String.escapeSingleQuotes(searchAccount.Name)+'\'' ;
                if(searchAccount.Billingcountrycode != null)
                    whereClause+= ' and Billingcountrycode =\''+String.escapeSingleQuotes(searchAccount.Billingcountrycode)+'\'' ;
                if(searchAccount.BillingStateCode != null)
                    whereClause+= ' and BillingStateCode = \''+String.escapeSingleQuotes(searchAccount.BillingStateCode)+'\'';
                if(searchAccount.BillingCity != null)
                    whereClause+= ' and BillingCity = \''+String.escapeSingleQuotes(searchAccount.BillingCity)+'\'' ;
                if(searchAccount.BillingStreet != null)
                    whereClause+= ' and BillingStreet = \''+String.escapeSingleQuotes(searchAccount.BillingStreet)+'\'';
                if(searchAccount.BillingpostalCode != null)
                    whereClause+= ' and BillingpostalCode = \''+String.escapeSingleQuotes(searchAccount.BillingpostalCode)+'\'';
                if(searchAccount.Phone != null)
                    whereClause+= ' and Phone =\''+String.escapeSingleQuotes(searchAccount.Phone)+'\'';
                if(searchAccount.Website!= null) 
                    whereClause+= ' and Website = \''+String.escapeSingleQuotes(searchAccount.Website)+'\'';
                query += whereClause ;
                system.debug('Salesforce query-->'+query);          
                sfdcaccList = database.query(query);
                system.debug('SFDC Matching account'+sfdcaccList);
                if(sfdcaccList.size()>0){
                    for(account acc : sfdcaccList){
                        exactMatch.add(new CMAccountSearch.CMAccount(acc.id,acc.name,acc.owner.name,
                                                                     acc.billingstreet != null ? acc.billingstreet:'',
                                                                     acc.billingcity != null ? acc.billingcity:'',
                                                                     acc.billingstate != null ? acc.billingstate:'',
                                                                     acc.billingstatecode != null ? acc.billingstatecode:'',
                                                                     acc.billingpostalCode != null ? acc.billingpostalCode:'',
                                                                     acc.billingcountry != null ? acc.billingcountry:'',
                                                                     acc.D_U_N_S__c != null ? acc.D_U_N_S__c:'',
                                                                     acc.billingcountrycode != null ? acc.billingcountrycode:'',
                                                                     acc.recordtypeId != null ? acc.recordtype.name : '',acc.account_status__c));
                        system.debug('exactMatch within SF'+exactMatch);
                    }
                }
                else{
                    if(IsfederalIntel == false){
                        if(searchAccount.BillingStreet == null && (searchAccount.BillingCity == null || searchAccount.BillingStateCode == null || searchAccount.BillingPostalCode == null)){
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,'No Matches Found, insufficient information to create new account'));
                            return ;
                        }
                    }
                    createSFAcc = new CMAccountSearch.CMAccount(null,searchAccount.name,null,
                                                                searchAccount.BillingStreet != null ? searchAccount.BillingStreet:'',
                                                                searchAccount.BillingCity != null ? searchAccount.BillingCity:'',
                                                                BillingStateName.contains('None')?'':BillingStateName,
                                                                searchAccount.BillingStateCode != null ? searchAccount.BillingStateCode:'',
                                                                searchAccount.BillingPostalCode != null ? searchAccount.BillingPostalCode:'',
                                                                country_CountryCode.containsKey(searchAccount.BillingCountryCode) ? country_CountryCode.get(searchAccount.BillingCountryCode):'',
                                                                null ,
                                                                searchAccount.billingCountryCode != null ? searchAccount.billingCountryCode:'',null,null);
                    createSFAcc.newAccount ='Y';
                    createSFAcc.phone = searchAccount.Phone;
                    createSFAcc.website =searchAccount.Website;
                    exactMatch.add(createSFAcc);
                    system.debug('New Internal salesforce acc'+exactMatch);
                    
                }
            }
            Catch(exception e){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,e.getMessage()));
                return; 
            }   
        }    
    /************************************************************************************
    Description : call company master once the account is successfully inserted in SF
    ************************************************************************************/
        public PageReference PostAccounttoCM(){
            system.debug('error before calling Postacc API'+errAccInsert);
            HttpRequest req = new HttpRequest();
            HTTPResponse res ;
            try{
                IntegrationLog = new Custom_Error_Log__c(Class__c = CLASS_NAME,Functionality__c ='CompanyMaster');
                if(!string.isBlank(errAccInsert)){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,errAccInsert));   
                    return null ;
                }
                if(IsfederalIntel == false && searchType == 'External-CM'){
                    system.debug('Post acc account'+accToinsert);
                    req.setMethod('POST'); 
                    req.setEndpoint('callout:Company_Master/account/create');
                    CMAccFields.clear();
                    payload.clear();
                    CMAccFields.put('CMID',accToinsert.CMID__c);
                    CMAccFields.put('sourceID',accToinsert.Id);
                    CMAccFields.put('sourceName','SFDC');
                    CMAccFields.put('requester',UserInfo.getUserName());
                    CMAccFields.put('requestId',Datetime.now().format('YYYYMMddHHmmssSS')+'_SFDC');
                    payload.put('createAccount',CMAccFields);
                    req.setbody(JSON.serialize(payload)) ;
                    req.setTimeout(120000); 
                    Http http = new Http();
                    IntegrationLog.Request_Time__c =System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS');
                    res = http.send(req);
                    IntegrationLog.Response_Time__c =System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS');
                    IntegrationLog.Http_Request__c= req.getbody();
                    IntegrationLog.Server_Endpoint__c=req.getEndpoint();
                    IntegrationLog.Type__c='Outbound Integration';
                    IntegrationLog.Http_Response__c=res.getbody();
                    IntegrationLog.Http_Response__c = (String.isNotBlank(IntegrationLog.Http_Response__c) && IntegrationLog.Http_Response__c.length() > 131000) ? IntegrationLog.Http_Response__c.left(131000) : IntegrationLog.Http_Response__c;//SAL22-515
                    IntegrationLog.Http_StatusCode__c= string.valueof(res.getStatusCode());
                    system.debug('Post account response'+res);   
                    if(res.getStatusCode() == 200){
                        Map<String, Object> accPostRes = (Map<String, Object>) JSON.deserializeUntyped(res.getbody());
                        system.debug('POST API parse response'+accPostRes);
                        if((string)((Map<string,object>)accPostRes.get('status')).get('statusCode')== '200' || (string)((Map<string,object>)accPostRes.get('status')).get('statusCode')== '201' || ((string)(((Map<string,object>)accPostRes.get('status')).get('statusCode'))).startswith('5')){
                            if(!String.isBlank(string.valueof(accPostRes.get('CMAccount')))){
                                accToinsert.D_U_N_S__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('dunsNumber');
                                accToinsert.Site_Business_Name__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('dunsBusinessName');
                                accToinsert.NumberOfEmployees = ((Map<string,object>)accPostRes.get('CMAccount')).get('guEmployeeCount') ==''?0:Integer.valueof(((Map<string,object>)accPostRes.get('CMAccount')).get('guEmployeeCount'));
                                accToinsert.GU_Annual_Revenue__c = ((Map<string,object>)accPostRes.get('CMAccount')).get('guRevenueUSD')==''?0:(Decimal) ((Map<string,object>)accPostRes.get('CMAccount')).get('guRevenueUSD');
                                accToinsert.Duns_SIC2_code__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('dunsSIC2Code');
                                accToinsert.Duns_SIC2_description__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('dunsSIC2Description');
                                accToinsert.Website = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('dunsDomainName');
                                accToinsert.Tradestyle__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('dunsTradeStyleName');
                                accToinsert.DU_Duns_Number__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('duDunsNumber');
                                accToinsert.DU_Business_Name__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('duBusinessName');
                                accToinsert.GU_Duns_Number__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('guDunsNumber');
                                accToinsert.GU_Business_Name__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('guBusinessName');
                                accToinsert.AnnualRevenue = ((Map<string,object>)accPostRes.get('CMAccount')).get('siteRevenueUSD')==''?0:(Decimal) ((Map<string,object>)accPostRes.get('CMAccount')).get('siteRevenueUSD');
                                accToinsert.Site_Employees__c = ((Map<string,object>)accPostRes.get('CMAccount')).get('siteEmployeeCount') ==''?0:Integer.valueof(((Map<string,object>)accPostRes.get('CMAccount')).get('siteEmployeeCount'));
                                accToinsert.Parent_Duns_Number__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('hqDunsNumber');
                                accToinsert.Parent_Business_Name__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('hqBusinessName');
                                accToinsert.Industry = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('industryCategory');
                                if(string.isNotEmpty(accToinsert.industry) && ((Map<string,object>)accPostRes.get('CMAccount')).get('industrySubCategory') != ''){
                                 if( CheckFieldValidity.validatedependantPicklist(Account.Industry_Subcategory__c ,accToinsert.Industry,(string)((Map<string,object>)accPostRes.get('CMAccount')).get('industrySubCategory')) == true )
                                    accToinsert.Industry_Subcategory__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('industrySubCategory') ; 
                                }
                                update accToinsert ;
                            }
                            else{
                                
                                // If there are no enrichment attribs returned
                                IntegrationLog.Result__c = res.getStatusCode().format().startswith('2') ?'Success':'Application Failure';
                                IntegrationLog.Exception_Message__c ='There are no enrichment attributes returned';
                                system.debug('There are no enrichment attributes returned');
                            }
                            
                            IntegrationLog.Result__c = ((string)(((Map<string,object>)accPostRes.get('status')).get('statusCode'))).startswith('5') == true ? 'Application Failure':'Success';
                            
                            if(SetupCompanyMaster__c.getOrgDefaults().Log_API_Calls__c)
                                Insert IntegrationLog ; 
                            system.debug('Create Account Stop'+System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS'));
                            PageReference pageRef = new PageReference('/' + accToinsert.Id);
                            pageRef.setRedirect(true);
                            return pageRef;
                            
                        }
                        else{
                            IntegrationLog.Result__c = 'Application Failure' ;
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,((Map<string,object>)accPostRes.get('status')).get('statusCode')+'-'+((Map<string,object>)accPostRes.get('status')).get('statusDescription'))); 
                        }
                    }
                    else if(res.getStatusCode().format().startswith('5')){ // Server errors 
                        IntegrationLog.Result__c = 'Server Failure' ;
                        if(SetupCompanyMaster__c.getOrgDefaults().Log_API_Calls__c)
                            Insert IntegrationLog ;
                        system.debug('Create Account Stop'+System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS'));
                        PageReference pageRef = new PageReference('/' + accToinsert.Id);
                        pageRef.setRedirect(true);
                        return pageRef;
                        
                    }
                    else{     
                        IntegrationLog.Result__c = res.getStatusCode().format().startswith('2')?'Success':'Server Failure' ;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,res.getStatusCode()+'-'+res.getStatus()));   
                        
                    } }
            }
            catch(exception e){
                IntegrationLog.Result__c = 'Salesforce Exception';
                IntegrationLog.ErrorTrace__c= String.format('{0}\n{1}\n\n\n\n',new List<String>{'Exception type :'+e.getTypeName(),'Trace : '+e.getStackTraceString()}); 
                IntegrationLog.Exception_Message__c= e.getmessage();
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,e.getmessage()));   
            }
            if(SetupCompanyMaster__c.getOrgDefaults().Log_API_Calls__c)
                Upsert IntegrationLog ;
            system.debug('Create Account Stop'+System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS'));
            return null;
        }
        
    }