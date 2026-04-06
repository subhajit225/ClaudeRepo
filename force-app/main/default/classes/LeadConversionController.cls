public without sharing class LeadConversionController {
    public static final string INCOMPLETE_ACCDETAILS = 'Incomplete Address information in Lead. Account Match not found' ;    
    public static final string OPP_ERROR = 'Please enter Opportunity Name or check DO NOT CREATE OPPORTUNITY' ;
    public static final string CLASS_NAME = 'LeadConversionController';
    public static final string ACC_ERROR = 'Please select account' ;
    public static boolean islastOppSourced = false;
    @TestVisible
    private static String continuationLabel;
    @TestVisible 
    private static StateResponse continuationState = new StateResponse();    
    @AuraEnabled(continuation=true)
    public static Object startRequest(String leadId) 
    {
        
        Lead ldSource = [SELECT Id, Name, FirstName, isFederalIntel__c, Website, LastName, CountryCode, 
                         OwnerId, Company, CompanyDunsNumber__c, Phone, city, country, Street, State,
                         Statecode, PostalCode, Owner.Name FROM Lead 
                         WHERE Id =: leadId];
        system.debug('Search Start'+System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS')); 
        if(ldSource.isFederalIntel__c)
        {
            String whereClause = ' isFederalIntel__c ='+ldSource.isFederalIntel__c ;
            searchInternalAccount(ldSource, whereClause);
            return null;
        }
        else
        {
            try{
                map<string,Object> CMAccFields = new Map<string,object>();
                CMAccFields.put('accountName', ldSource.Company);
                CMAccFields.put('addressLine1', ldSource.street != null ? ldSource.street : '');
                CMAccFields.put('city', ldSource.city != null ? ldSource.city : '');
                CMAccFields.put('state', ldSource.state != null ? ldSource.state : '');
                CMAccFields.put('stateCode', ldSource.stateCode != null ? ldSource.stateCode : '');
                CMAccFields.put('postalCode', ldSource.postalCode != null ? ldSource.postalCode : '');
                CMAccFields.put('country', ldSource.Country != null ? ldSource.Country : '');
                CMAccFields.put('isoCountrycode', ldSource.CountryCode != null ? ldSource.CountryCode : '');
                CMAccFields.put('phone', ldSource.Phone != null ? ldSource.Phone : '');
                CMAccFields.put('website', ldSource.Website != null ? ldSource.Website : '');
                CMAccFields.put('isFederalintel', ldSource.isFederalIntel__c);
                CMAccFields.put('sourceName', 'SFDC');
                
                map<string,Object> payloadContainer = new Map<string,object>();
                payloadContainer.put('requestId', Datetime.now().format('YYYYMMddHHmmssSS')+'_SFDC');
                payloadContainer.put('requester', UserInfo.getUserName());
                payloadContainer.put('CMAccount', CMAccFields);
                
                map<string,Object> payload = new Map<string,object>();
                payload.put('accountSearch', payloadContainer);
                
                Continuation con = new Continuation(40);
                con.continuationMethod = 'processResponse';
                // Create callout request
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');  
                req.setEndpoint('callout:Company_Master/account/search');
                req.setbody(JSON.serialize(payload)) ;
                continuationLabel = con.addHttpRequest(req);
                StateResponse sr = new StateResponse();
                sr.log = new Custom_Error_Log__c(Class__c = 'LeadConversionController',
                                                Http_Request__c = req.getbody(),
                                                Server_Endpoint__c = req.getEndpoint(),
                                                Type__c = 'Outbound Integration',
                                                Functionality__c = 'CompanyMaster',
                                                Request_Time__c = System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS'));
                sr.ldSource = ldSource;
                con.state = sr;
                continuationState = sr;
                return con;
            }Catch(exception e){
                system.debug('@@ Exception '+e.getMessage()+ 'at line '+e.getLineNumber());
                throw new AuraHandledException(e.getMessage());
            } 
        }     

        
    }    
    @AuraEnabled
    public static InitResponse processResponse(List<String> labels, Object state) 
    {
        InitResponse ir = new InitResponse();
        StateResponse sr = (StateResponse)state;
        ir.ldSource = sr.ldSource;
        Custom_Error_Log__c IntegrationLog = sr.log;
        Map<string,account>accId_account = new Map<string,account>();
        
        try
        {
            List<Id> AccountIds = new List<Id>();
            accId_account.clear(); 
            HttpResponse response = Continuation.getResponse(labels[0]);
		    IntegrationLog.Response_Time__c = System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS');
            IntegrationLog.Http_Response__c = response.getBody().abbreviate(131071);
            IntegrationLog.Http_StatusCode__c = string.valueof(response.getStatusCode());
            if(response.getStatusCode() == 200)
            {
                CMAccountSearch searchRes = (CMAccountSearch)JSON.deserialize(response.getBody(),CMAccountSearch.class);
                if(searchRes.status.statusCode == '200' || searchRes.status.statusCode == '201')
                {
                    system.debug('CM search process result'+searchRes.Results);
                    ir.searchType = 'External-CM';
                    if(searchRes.Results.CMAccount.accountName != null && searchRes.Results.CMAccount.isoCountrycode != null && ((Schema.sObjectType.Account.isCreateable()== false && searchRes.Results.CMAccount.newAccount.equalsIgnoreCase('N')) ||Schema.sObjectType.Account.isCreateable())) // to check if there is empty exact match record as accName and country are mandatory fields
                    {
                        ir.exactAccMatch.add(searchRes.Results.CMAccount);
                        system.debug('res accountId'+searchRes.Results.CMAccount.sourceID);
                        if(searchRes.Results.CMAccount.sourceID != '' && searchRes.Results.CMAccount.sourceID != null && searchRes.Results.CMAccount.sourceID != 'None')
                            AccountIds.add(searchRes.Results.CMAccount.sourceID);
                        else
                            searchRes.Results.CMAccount.accountOwner = '';                              
                    }
                    
                    ir.potentialAccMatch.addall(searchRes.Results.potentialAccounts);
                    if(ir.potentialAccMatch.size() == 0 && ir.exactAccMatch.size() == 0 && Schema.sObjectType.Account.isCreateable() == false ){
                        ir.isError = true;
                        ir.errMsg = 'Please contact Sales Data Ops ( salesdataops@rubrik.com ) for Account creation';
                    }
                    for(CMAccountSearch.CMAccount PM : searchRes.Results.potentialAccounts){
                        if(PM.sourceID != null && PM.sourceID != '' && PM.sourceID!='None')
                            AccountIds.add(PM.sourceID);
                        else
                            PM.accountOwner = '';
                    }
                                        
                    for(account acc: [select id,owner.name,recordtype.name,Account_Status__c from account where id IN: AccountIds ]){
                        accId_account.put(acc.id,acc);
                    }
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
                    
                    for(CMAccountSearch.CMAccount PM : searchRes.Results.potentialAccounts)
                    {
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
                else if(searchRes.status.statusCode == '204')
                {
                    IntegrationLog.Result__c = 'Success';
                    if(Schema.sObjectType.Account.isCreateable()){
                        ir.isError = true;
                        ir.errMsg = INCOMPLETE_ACCDETAILS;
                    }      
                    else{
                        ir.isError = true;
                        ir.errMsg = INCOMPLETE_ACCDETAILS;
                    }     
                }
                else if(searchRes.status.statusCode.startswith('5'))     // Server application errors make internal search
                {
                    IntegrationLog.Result__c = 'Application Failure';
                    InternalAccountResponse ar = searchInternalAccount(sr.ldSource, '');
                    if(ar.isError){
                        ir.isError = true;
                        ir.errMsg = ar.errMsg;
                    } else {
                        ir.exactAccMatch = ar.exactAccMatch;
                    }
                }
                else {
                    IntegrationLog.Result__c = searchRes.status.statusCode.startswith('2') ?'Success':'Application Failure';
                    ir.isError = true;
                    ir.errMsg = SearchRes.Status.statusDescription;
                }
            }
            else if(response.getStatusCode().format().startswith('5'))      // Server errors make internal search
            {
                IntegrationLog.Result__c = 'Server Failure'; 
                InternalAccountResponse ar = searchInternalAccount(sr.ldSource, '');
                if(ar.isError){
                    ir.isError = true;
                    ir.errMsg = ar.errMsg;
                } else {
                    ir.exactAccMatch = ar.exactAccMatch;
                }
            }
            else      // 3xx and 4xx series
            {
                IntegrationLog.Result__c = response.getStatusCode().format().startswith('2')?'Success':'Server Failure'; 
                ir.isError = true;
                ir.errMsg = response.getStatusCode()+'-'+response.getStatus();
            }
        }
        Catch(exception e){
            IntegrationLog.Result__c = 'Salesforce Exception';
            IntegrationLog.Id = null;
            IntegrationLog.ErrorTrace__c = String.format('{0}\n{1}\n\n\n\n',new List<String>{'Exception type :'+e.getTypeName(),'Trace : '+e.getStackTraceString()}).abbreviate(131071); 
            IntegrationLog.Exception_Message__c = e.getmessage();
            ir.isError = true;
            ir.errMsg = e.getMessage()+e.getstacktracestring();
        }
        if(SetupCompanyMaster__c.getOrgDefaults().Log_API_Calls__c)
            Insert IntegrationLog ;
        return ir; 
    }    
    
    //Desc : 
    //Exact match - create new account if doesnt exist in SF and set it for using in lead conversion
    //Potential Match - set selected account for using in lead conversion
    @AuraEnabled
    public static PreConversionResponse createORsetAccount(String exactAccMatchPayload, String potentialAccMatchPayload, String selectedrowIndex, String searchType, Id leadId, Boolean sendEmailToOwner, Boolean dontCreateOpp, String oppName, Decimal oppAmount, String selectedLeadStatus, String accountOwnerId) 
    {
        System.debug('oppName..!'+oppName);
        System.debug('dontCreateOpp..!'+dontCreateOpp);
        System.debug('accountOwnerId..!'+accountOwnerId);
        list<CMAccountSearch.CMAccount> exactAccMatch = (list<CMAccountSearch.CMAccount>)JSON.deserialize(exactAccMatchPayload, list<CMAccountSearch.CMAccount>.class);
        list<CMAccountSearch.CMAccount> potentialAccMatch = (list<CMAccountSearch.CMAccount>)JSON.deserialize(potentialAccMatchPayload, list<CMAccountSearch.CMAccount>.class);
        PreConversionResponse pr = new PreConversionResponse();
        //try
        //{
        Lead ldSource = [SELECT Id, FirstName, isFederalIntel__c, Website, LastName, CountryCode, 
            OwnerId, Company, CompanyDunsNumber__c, Phone, city, country, Street, State,
            Statecode, PostalCode, Opportunity_Amount__c FROM Lead 
            WHERE Id =: leadId];
        
        if(String.isBlank(accountOwnerId)){
            throw new AuraHandledException('Account Owner is mandatory.');
        }
        ldSource.OwnerId = accountOwnerId;
        ldSource.Opportunity_Amount__c = oppAmount;
        
        
        System.debug('ldSource..!'+ldSource);

        if(dontCreateOpp == null)
            dontCreateOpp = false;
        if(sendEmailToOwner == null)
            sendEmailToOwner = false;

        if((string.isBlank(oppName) || string.isEmpty(oppName)) && dontCreateOpp == false){                
            throw new AuraHandledException(OPP_ERROR);
        }        
        if(!Test.isRunningTest() && !dontCreateOpp && ldSource.Opportunity_Amount__c == null){                
            throw new AuraHandledException('Please enter the Opportunity amount');
        }
        if(string.isNotBlank(selectedrowIndex) && string.isNotEmpty(selectedrowIndex))
        { 
            if(selectedrowIndex.endsWith('pm'))
            {
                if(string.isNotBlank(potentialAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].accountOwner) && potentialAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].accountOwner != 'None'){
                    pr.selectedAccountId = potentialAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].sourceID;
                    LeadConversionResponse lcr = convertLead(ldSource, sendEmailToOwner, pr.selectedAccountId, dontCreateOpp, oppName, selectedLeadStatus);
                    System.debug('lcr..!'+lcr);
                    if(lcr.isError != true){                            
                        pr.convertedAccountId = lcr.accountId;
                        return pr;
                    } else {
                        throw new AuraHandledException(lcr.errMsg);
                    }
                }
                else{
                    throw new AuraHandledException('AccountId is invalid');
                }
            }
            else if(selectedrowIndex.endsWith('em'))
            {
                if(exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].newAccount.equalsIgnoreCase('y'))
                {                        
                    Account acc = new account(CMID__c = exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].CMID , 
                                            Name = exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].accountName , 
                                            Billingcountrycode = exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].isoCountrycode,
                                            BillingCity = exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].city , 
                                            BillingStateCode = exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].stateCode,
                                            BillingpostalCode = exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].postalCode, 
                                            BillingStreet = exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].addressLine1+exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].addressLine2 , 
                                            D_U_N_S__c = exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].dunsNumber );
                    acc.OwnerId = ldSource.OwnerId;
                    acc.isFederalIntel__c = ldSource.isFederalIntel__c;                        
                    Savepoint stopAccountCreation = Database.setSavepoint();
                    Database.SaveResult accSaveRes = Database.insert(acc,false);          
                    if (accSaveRes.isSuccess()) 
                    {
                        pr.selectedAccountId = acc.id ;
                        if(searchType == 'SF Internal')
                        {
                            LeadConversionResponse lcr = convertLead(ldSource, sendEmailToOwner, pr.selectedAccountId, dontCreateOpp, oppName, selectedLeadStatus);
                            System.debug('lcr..!'+lcr);
                            if(lcr.isError != true){
                                pr.convertedAccountId = lcr.accountId;
                                return pr;
                            }
                            else
                            {
                                Database.rollback(stopAccountCreation);
                                throw new AuraHandledException(lcr.errMsg);
                            }
                        } 
                        else if(searchType == 'External-CM')
                        {
                            system.debug('CP lead convert start');
                            LeadConversionResponse lcr = convertLead(ldSource, sendEmailToOwner, pr.selectedAccountId, dontCreateOpp, oppName, selectedLeadStatus);
                            if(lcr.isError == true){
                                Database.rollback(stopAccountCreation);
                                throw new AuraHandledException(lcr.errMsg);
                            } else {
                                pr.convertedAccountId = lcr.accountId;
                                return pr;
                            }
                        }
                    }
                    else {                   
                        for(Database.Error err : accSaveRes.getErrors()) {    
                            throw new AuraHandledException(err.getMessage());
                        }
                    }
                }
                else
                {
                    if(string.isNotBlank(exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].accountOwner) && exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].accountOwner != 'None'){
                        pr.selectedAccountId = exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].sourceID;
                        LeadConversionResponse lcr = convertLead(ldSource, sendEmailToOwner, pr.selectedAccountId, dontCreateOpp, oppName, selectedLeadStatus);
                        if(lcr.isError != true){                                
                            pr.convertedAccountId = lcr.accountId;
                        }
                    }                
                    else{
                        throw new AuraHandledException('AccountId is invalid');
                    }     
                }
            }
            else{                    
                throw new AuraHandledException('Select one account');
            }
        }
        else{
            throw new AuraHandledException(ACC_ERROR);
        }      
        //}
        //catch(exception e){
        //    throw new AuraHandledException(e.getMessage());
        //} 
        return pr;
    }
    public class PreConversionResponse
    {
        @AuraEnabled public Boolean isError;
        @AuraEnabled public String errMsg;
        @AuraEnabled public Id convertedAccountId;
        @AuraEnabled public Id selectedAccountId;
        public PreConversionResponse()
        {}
        public PreConversionResponse(Boolean isError, String errMsg)
        {
            this.isError = isError;
            this.errMsg = errMsg;
        }
    }
    
    //Description : call company master once the account is successfully inserted in SF
    @AuraEnabled    
    public static PostConversionResponse postAccountConvertLead(String exactAccMatchPayload, String selectedrowIndex, String searchType, String leadConvertErrMsg, Id convertedAccountId, Id selectedAccountId)
    {
        list<CMAccountSearch.CMAccount> exactAccMatch = (list<CMAccountSearch.CMAccount>)JSON.deserialize(exactAccMatchPayload, list<CMAccountSearch.CMAccount>.class);
        
        PostConversionResponse pr = new PostConversionResponse();
        Custom_Error_Log__c IntegrationLog = new Custom_Error_Log__c(Class__c = CLASS_NAME, Functionality__c ='CompanyMaster');
        try
        {            
            if(!string.isBlank(leadConvertErrMsg)){
                return new PostConversionResponse(true, leadConvertErrMsg);
            }
            
            // CP check if extra em,y checks are needed
            if(searchType =='External-CM' && selectedrowIndex.endsWith('em') && exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].newAccount.equalsIgnoreCase('Y'))
            {
                map<string,Object> CMAccFields = new Map<string,object>();
                CMAccFields.put('CMID',(exactAccMatch[integer.valueof(selectedrowIndex.substringBefore('-'))].CMID));
                CMAccFields.put('sourceID', selectedAccountId);
                CMAccFields.put('sourceName','SFDC');
                CMAccFields.put('requester',UserInfo.getUserName());
                CMAccFields.put('requestId',Datetime.now().format('YYYYMMddHHmmssSS')+'_SFDC');
                
                map<string,Object> payload = new Map<string,object>();
                payload.put('createAccount',CMAccFields);
                
                HttpRequest req = new HttpRequest();
                req.setMethod('POST'); 
                req.setEndpoint('callout:Company_Master/account/create'); 
                req.setbody(JSON.serialize(payload));
                req.setTimeout(120000); 
                
                Http http = new Http();
                IntegrationLog.Request_Time__c = System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS');
                HTTPResponse res = http.send(req);
                IntegrationLog.Response_Time__c = System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS');
                IntegrationLog.Http_Request__c = req.getbody();
                IntegrationLog.Server_Endpoint__c = req.getEndpoint();
                IntegrationLog.Type__c = 'Outbound Integration';
                IntegrationLog.Http_Response__c = res.getbody();
                IntegrationLog.Http_StatusCode__c = string.valueof(res.getStatusCode());

                if(res.getStatusCode() == 200)
                {
                    Map<String, Object> accPostRes = (Map<String, Object>) JSON.deserializeUntyped(res.getbody());
                    system.debug('accPostRes'+accPostRes);
                    if((string)((Map<string,object>)accPostRes.get('status')).get('statusCode')== '200' || (string)((Map<string,object>)accPostRes.get('status')).get('statusCode')== '201' || ((string)(((Map<string,object>)accPostRes.get('status')).get('statusCode'))).startswith('5'))
                    {
                       // leadConvStatus = convertLead();
                        if(convertedAccountId != null)
                        {               
                            Account leadAcc = new Account(Id = selectedAccountId);
                            if(!String.isBlank(string.valueof(accPostRes.get('CMAccount'))))
                            {
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
                            else
                            {    
                                // If there are no enrichment attribs returned
                                IntegrationLog.Result__c = 'Application Failure';
                                IntegrationLog.Exception_Message__c ='There are no enrichment attributes returned';
                            }
                            IntegrationLog.Result__c = ((string)(((Map<string,object>)accPostRes.get('status')).get('statusCode'))).startswith('5') == true ? 'Application Failure':'Success';
                            if(SetupCompanyMaster__c.getOrgDefaults().Log_API_Calls__c)
                                Insert IntegrationLog ; 
                            
                            pr.convertedAccountId = convertedAccountId;
                            return pr;
                        }
                    }
                    else 
                    {
                        IntegrationLog.Result__c = 'Success';
                        throw new AuraHandledException(accPostRes.get('statusCode')+'-'+accPostRes.get('statusDescription'));
                    }
                }
                else if(res.getStatusCode().format().startswith('5'))			// Server errors 
                {
                    //leadConvStatus = convertLead();
                    IntegrationLog.Result__c = 'Server Failure' ;
                    if(SetupCompanyMaster__c.getOrgDefaults().Log_API_Calls__c)
                        Insert IntegrationLog ; 
                    if(convertedAccountId != null){
                        pr.convertedAccountId = convertedAccountId;
                        return pr;
                    }                    
                }
                else
                {
                    IntegrationLog.Result__c = 'Server Failure' ;                    
                    throw new AuraHandledException(res.getStatusCode()+'-'+res.getStatus());
                } 
            }
        }
        catch(exception e)
        {
            IntegrationLog.Result__c = 'Salesforce Exception';
            IntegrationLog.ErrorTrace__c= String.format('{0}\n{1}\n\n\n\n',new List<String>{'Exception type :'+e.getTypeName(),'Trace : '+e.getStackTraceString()}); 
            IntegrationLog.Exception_Message__c= e.getmessage();
            system.debug('@@ Exception '+e.getMessage()+ 'at line '+e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
        if(SetupCompanyMaster__c.getOrgDefaults().Log_API_Calls__c)
            Upsert IntegrationLog;
        return pr;
    }
    public class PostConversionResponse
    {
        @AuraEnabled public Boolean isError;
        @AuraEnabled public String errMsg;
        @AuraEnabled public Id convertedAccountId;
        public PostConversionResponse()
        {}
        public PostConversionResponse(Boolean isError, String errMsg)
        {
            this.isError = isError;
            this.errMsg = errMsg;
        }
    }


    /*
     *  Private methods
     */
    //Desc :  CUstom lead conversion
    private static LeadConversionResponse convertLead(Lead ldSource, Boolean sendEmailToOwner, String accId, Boolean dontCreateOpp, String oppName, String selectedLeadStatus)
    {
        try{
            Lead ld = new Lead();
            ld = getOppSourcedEvents(ldSource);
            if(islastOppSourced){
                update ld;
            }else{
            update ldSource;
            }
        } catch (Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
        
        System.debug('ldSource.OwnerId..!'+ldSource.OwnerId);
        
        LeadConversionResponse lcResp = new LeadConversionResponse();
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(ldSource.Id);
        lc.setOwnerId(ldSource.OwnerId);
        lc.setSendNotificationEmail(sendEmailToOwner);
        lc.setAccountId(accId);
        lc.setDoNotCreateOpportunity(dontCreateOpp);
        if(dontCreateOpp == false) 
        { 
            lc.setOpportunityName(oppName); 
        }
        lc.setConvertedStatus(selectedLeadStatus);

        Database.LeadConvertResult lcr;
        try{
            lcr = Database.convertLead(lc);
        } catch (Exception ex){
            system.debug('@@ Exception '+ex.getMessage()+ 'at line '+ex.getLineNumber());
            throw new AuraHandledException(ex.getMessage());
        }
        
        Task taskSobj = new Task();
        taskSobj.recordtypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Task').getRecordTypeId();
        taskSobj.WhatId = lcr.getOpportunityId();
        taskSobj.WhoId = lcr.getContactId();
        
        if(taskSobj.Subject != null && taskSobj.Type != null)
            insert taskSobj;
        
        if(lcr.isSuccess()) { 
            lcResp.accountId = (Id)lcr.getAccountId();    
            updateEventRelatedToOpp(ldSource.Id);
            return lcResp;
        } 
        else 
        {
            for(Database.Error err : lcr.getErrors()) {    
                lcResp.errMsg = err.getMessage();             
            }
            lcResp.isError = true;
            return lcResp;
        }   
    }

    //Description : Method used for searching accounts within salesforce 
    //When : federal account , Company master server is down
    private static InternalAccountResponse searchInternalAccount(Lead ldSource, String whereClause)
    {
        InternalAccountResponse ir = new InternalAccountResponse();
        try{
            
            List<account> sfdcaccList = new List<Account>();
            String query ='select id,Name,D_U_N_S__c,owner.name,Billingcountry,recordtype.name,billingstate,account_status__c,BillingStateCode,billingcity,billingpostalcode,BillingStreet,billingcountrycode,Phone,website from account where';  
            system.debug('In Search whereClause '+whereClause);
            ir.searchType = 'SF Internal';
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
            ir.exactAccMatch = new List<CMAccountSearch.CMAccount>();
            if(sfdcaccList.size()>0){
                for(account acc : sfdcaccList){
                    ir.exactAccMatch.add(new CMAccountSearch.CMAccount(acc.id,acc.name,acc.owner.name,
                                                                    acc.billingstreet,acc.billingcity,acc.billingstate,acc.billingstatecode,
                                                                    acc.billingpostalCode,acc.billingcountry,acc.D_U_N_S__c ,acc.billingcountrycode,acc.recordtype.name,acc.account_status__c));
                }
            }
            else
            {
                if(ldSource.Street == null && ldSource.isFederalIntel__c == false && (ldSource.City == null || ldSource.StateCode == null || ldSource.PostalCode == null)){
                    ir.isError = true;
                    ir.errMsg = 'No Matches Found, insufficient information found on lead to create new account';
                }
                if(Schema.sObjectType.Account.isCreateable()){
                CMAccountSearch.CMAccount createSFAcc = new CMAccountSearch.CMAccount(null,ldSource.company,null,
                                                                                     ldSource.street != null ? ldSource.street:'',
                                                                                     ldSource.city != null ? ldSource.city:'',
                                                                                     ldSource.state != null ? ldSource.state:'',
                                                                                     ldSource.statecode != null ? ldSource.statecode:'',
                                                                                     ldSource.postalCode != null ? ldSource.postalCode:'',
                                                                                     ldSource.country != null ? ldSource.country:'',
                                                                                     ldSource.CompanyDunsNumber__c != null ? ldSource.CompanyDunsNumber__c:'' ,
                                                                                     ldSource.countrycode != null ? ldSource.countrycode:'','','');            
                createSFAcc.newAccount = 'Y';
                ir.exactAccMatch.add(createSFAcc);
               } 
            }
        }Catch(exception e){
            system.debug('@@ Exception '+e.getMessage()+ 'at line '+e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        } 
        return ir;
    }
    @AuraEnabled
    public static List<Object> getRecordsByName(String objectName, String searchFor) {
        String queryString = 'SELECT Id, Name FROM ';
        queryString += String.escapeSingleQuotes(objectName) + ' WHERE Name Like \'%' + String.escapeSingleQuotes(searchFor) + '%\'';
        return Database.query(queryString);
    }
    public static Lead getOppSourcedEvents(Lead leadToBeUpdated) {
        List<Event> eve = [SELECT Id, CreatedById, WhoID, Type, Post_Meeting_Status__c,Completed_Date__c,StartDateTime, NBM_Complete__c, Completed_By__c, Created_Through_Quick_Action__c, RelatedtoObject__c FROM Event WHERE Type = 'Inside Sales Led Meeting' AND Post_Meeting_Status__c != 'Meeting Cancelled' AND Completed_Date__c = LAST_90_DAYS AND WhoId =: leadToBeUpdated.Id ORDER BY CreatedDate DESC LIMIT 1];
                List<Event> updateEvent = new List<Event>();
        if(!eve.isEmpty()){
            leadToBeUpdated.Meeting_Id__c = eve[0].Id;
            leadToBeUpdated.MeetingDate__c = eve[0].StartDateTime;
            leadToBeUpdated.EventType__c = eve[0].Type;
            if(eve[0].NBM_Complete__c == 'Yes'){
             	leadToBeUpdated.NBM_Complete__c = true;   
            }else{
                leadToBeUpdated.NBM_Complete__c = false;
            }
            leadToBeUpdated.SDR_Led__c = true;
            leadToBeUpdated.SDR_Led_Checked_Date__c = System.now();
            leadToBeUpdated.Meeting_Completed_By__c = eve[0].Completed_By__c;
            leadToBeUpdated.Meeting_Completed_Date__c = eve[0].Completed_Date__c;
            leadToBeUpdated.Post_Meeting_Status__c = eve[0].Post_Meeting_Status__c;
            leadToBeUpdated.Created_Through_Quick_Action__c = eve[0].Created_Through_Quick_Action__c;
            leadToBeUpdated.OriginalLeadOwner__c = eve[0].CreatedById;
            islastOppSourced = true;
        } else {
            leadToBeUpdated.Meeting_Id__c = null;
            leadToBeUpdated.MeetingDate__c = null;
            leadToBeUpdated.EventType__c = null;
            leadToBeUpdated.NBM_Complete__c = false;   
            leadToBeUpdated.SDR_Led__c = false;
            leadToBeUpdated.SDR_Led_Checked_Date__c = null;
            leadToBeUpdated.Meeting_Completed_By__c = null;
            leadToBeUpdated.Meeting_Completed_Date__c = null;
            leadToBeUpdated.Post_Meeting_Status__c = null;
            leadToBeUpdated.Created_Through_Quick_Action__c = true;
            leadToBeUpdated.OriginalLeadOwner__c = null;
            islastOppSourced = true;
        }
        return leadToBeUpdated;
    }
    public static void updateEventRelatedToOpp(String leadId){
        System.debug('Post Lead Conversion updateEventRelatedToOpp method called');
        List<Lead> convertedLead = [SELECT Id, ConvertedOpportunityId,Meeting_Id__c  FROM Lead WHERE ConversionStatus__c = 'Converted to Opportunity' AND Id =: leadId LIMIT 1];
        List<Event> updateEvent = new List<Event>();
        if(!convertedLead.isEmpty() && convertedLead[0].ConvertedOpportunityId != null && convertedLead[0].Meeting_Id__c != null){
            Event eve = new Event();
            eve.Id = convertedLead[0].Meeting_Id__c;
            eve.WhatId = convertedLead[0].ConvertedOpportunityId;
            updateEvent.add(eve);
        }
        if(!updateEvent.isEmpty()){
            update updateEvent;
        }
    }
    public class InitResponse
    {
		@AuraEnabled public String searchType;
        @AuraEnabled public Boolean isError;
        @AuraEnabled public String errMsg;
        @AuraEnabled public List<CMAccountSearch.CMAccount> exactAccMatch;
        @AuraEnabled public list<CMAccountSearch.CMAccount> potentialAccMatch;
        @AuraEnabled public Lead ldSource;
        public InitResponse()
        {
            exactAccMatch = new List<CMAccountSearch.CMAccount>();
            potentialAccMatch = new List<CMAccountSearch.CMAccount>();
            ldSource = new Lead();
        }
    }
    public class StateResponse
    {
        Custom_Error_Log__c log;
        Lead ldSource;
        public StateResponse(){
            log = new Custom_Error_Log__c();
            ldSource = new Lead();
        }
    }
    public class LeadConversionResponse
    {
        Boolean isError;
        String errMsg;
        Id accountId;
    }
    public class InternalAccountResponse
    {
        @AuraEnabled public String searchType;
        @AuraEnabled public Boolean isError;
        @AuraEnabled public String errMsg;
        @AuraEnabled public List<CMAccountSearch.CMAccount> exactAccMatch;
    }

}