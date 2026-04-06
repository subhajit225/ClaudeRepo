public with sharing class UpdategrainAttributesControllerLWC {
    public final string ACCPOST_ENDPOINT = '';
   // public final string ACCOUNT = 'account';
    public static final string CLASS_NAME = 'UpdateAccountGrainAttributes';
    public static final string FEDERAL_INFO = 'Federal accounts can be updated directly';
     public static final string NOACCESS = 'Insufficient Privileges to update account';
    public static final string CM_DOWN = 'Company Master Service is depricated';
    public static boolean isFederal;
    public static boolean hasRecAccess;
    public static boolean disableCM;
    public static account updateAcc;
    public static Map<String,String> country_CountryCode=new Map<String,String>();
    public static string BillingStateName;

    @AuraEnabled
    public static List<wrapClass> getAccessDetails(string recId){
       List<wrapClass> wrapClassList = new List<wrapClass>();
       updateAcc = new Account();
       UserRecordAccess access = [SELECT RecordId ,HasEditAccess FROM UserRecordAccess WHERE UserId =:userInfo.getUserId() AND RecordId =:recId limit 1];
       hasRecAccess =  access.HasEditAccess;
       if(!hasRecAccess){
            wrapClassList.add(new wrapClass(NOACCESS,hasRecAccess,false,false,'error',updateAcc)); 
            return wrapClassList;  
        }
        
        if(!String.isBlank(recId)){
            updateAcc = [select id,CMID__c,isFederalIntel__c, BillingState, BillingCountry, Name, BillingCountryCode, BillingStateCode, BillingCity, BillingStreet, BillingPostalCode from account where id =:recId];
            isFederal = updateAcc.isFederalIntel__c;
        } 
        if(updateAcc.isFederalIntel__c){
            wrapClassList.add(new wrapClass(FEDERAL_INFO,hasRecAccess,isFederal,false,'warning',updateAcc));
            return wrapClassList;  
        }
        disableCM = false ;
        if(SetupCompanyMaster__c.getOrgDefaults().Enable_CM__c == false){
            disableCM = true ;
            wrapClassList.add(new wrapClass(CM_DOWN,hasRecAccess,isFederal,disableCM,'warning',updateAcc)); 
            return wrapClassList; 
        } 
        if(wrapClassList.isEmpty()){
            wrapClassList.add(new wrapClass('',hasRecAccess,isFederal,disableCM,'',updateAcc)); 
        }
        return wrapClassList;  
    }


    @AuraEnabled
    public static void saveAccountLWC(Account accrecord){
        Schema.sObjectType objType = Schema.Account.getSObjectType();
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        for (Schema.PicklistEntry country : fieldMap.get('BillingCountryCode').getDescribe().getPickListValues()){
            country_CountryCode.put(country.getValue(),country.getLabel());
        }
        updateAcc = new Account();
        updateAcc = accrecord;
        system.debug('@@ updateAcc '+updateAcc);
        saveAccount();
    }
    public static void saveAccount(){
        Custom_Error_Log__c IntegrationLog ;
        map<string,Object> CMAccFields = new Map<string,object>();
        map<string,Object> payload = new Map<string,object>();
        map<string,Object> payloadContainer = new Map<string,object>();
        HttpRequest req = new HttpRequest();
        HTTPResponse res ;
        
            if(updateAcc.BillingStateCode == null && updateAcc.billingpostalCode == null && updateAcc.billingcity == null){
            if(UserInfo.getUiTheme() == 'Theme3'){   
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error,'Please enter Billing City or Billing State or Billing Postal Code to complete update process')); 
            }else{
                throw new AuraHandledException('Please enter Billing City or Billing State or Billing Postal Code to complete update process');
            }

        }
        try{    
            system.debug('Update account Start'+System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS'));
            IntegrationLog = new Custom_Error_Log__c(Class__c = CLASS_NAME,Functionality__c ='CompanyMaster');
            CMAccFields.put('accountName',updateAcc.name != null ? updateAcc.name:'');
            CMAccFields.put('sourceId',updateAcc.Id);
            CMAccFields.put('addressLine1',updateAcc.BillingStreet!= null ? updateAcc.BillingStreet:'');
            CMAccFields.put('city',updateAcc.billingcity != null ? updateAcc.billingcity:'');
            CMAccFields.put('state',BillingStateName!= null && !BillingStateName.contains('None')? BillingStateName:'');
            //CMAccFields.put('state',BillingStateName!= null && !BillingStateName.contains('None')? updateAcc.BillingCountryCode == 'CA'? (updateAcc.BillingStateCode!= null ?updateAcc.BillingStateCode:''):BillingStateName:'');
            CMAccFields.put('stateCode',updateAcc.BillingStateCode!= null ? updateAcc.BillingStateCode:'');
            CMAccFields.put('postalCode',updateAcc.billingpostalCode!= null ? updateAcc.billingpostalCode:'');
            CMAccFields.put('isoCountrycode',updateAcc.BillingCountryCode!= null ? updateAcc.BillingCountryCode:'');
            CMAccFields.put('country',country_CountryCode.containsKey(updateAcc.BillingCountryCode)?country_CountryCode.get(updateAcc.BillingCountryCode):'');
            CMAccFields.put('sourceName','SFDC');
            payloadContainer.put('requestId',Datetime.now().format('YYYYMMddHHmmssSS')+'_SFDC');
            payloadContainer.put('requester',UserInfo.getUserName());
            payloadContainer.put('CMAccount',CMAccFields);
            payload.put('accountUpdate',payloadContainer);
            req.setMethod('POST'); 
            req.setEndpoint('callout:Company_Master/account/update');
            req.setbody(JSON.serialize(payload)) ;
            req.setTimeout(120000); 
            system.debug('req body'+req.getbody());
            Http http = new Http();
            IntegrationLog.Request_Time__c =System.Now().format('YYYY-MM-dd HH:mm:ss:SS');
            res = http.send(req);
            IntegrationLog.Response_Time__c =System.Now().format('YYYY-MM-dd HH:mm:ss:SS');
            IntegrationLog.Http_Request__c= req.getbody();
            IntegrationLog.Server_Endpoint__c=req.getEndpoint();
            IntegrationLog.Type__c='Outbound Integration';
            IntegrationLog.Http_Response__c=res.getbody();
            IntegrationLog.Http_StatusCode__c= string.valueof(res.getStatusCode());
        }catch(exception e){
            IntegrationLog.Result__c = 'Salesforce Exception';
            IntegrationLog.Exception_Message__c= e.getmessage();
            IntegrationLog.ErrorTrace__c= String.format('{0}\n{1}\n\n\n\n',new List<String>{'Exception type :'+e.getTypeName(),'Trace : '+e.getStackTraceString()}); 
            IntegrationLog.Exception_Message__c= e.getmessage();
            if(UserInfo.getUiTheme() == 'Theme3'){
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error,e.getMessage()));
            }else{
                throw new AuraHandledException(e.getMessage());
            } 
            if(SetupCompanyMaster__c.getOrgDefaults().Log_API_Calls__c)
            Insert IntegrationLog ;
        }
            system.debug('response'+res);

            if(res.getStatusCode() == 200){
                Map<String, Object> accPostRes = (Map<String, Object>) JSON.deserializeUntyped(res.getbody());
                if((string)((Map<string,object>)accPostRes.get('status')).get('statusCode')== '200' || ((string)(((Map<string,object>)accPostRes.get('status')).get('statusCode'))).startswith('5')){  // 5X if the application has some problem running
                try{
                    if((string)((Map<string,object>)accPostRes.get('status')).get('statusCode')== '200'){
                        system.debug('Success Post');
                        if(!String.isBlank(string.valueof(accPostRes.get('CMAccount')))){
                            system.debug('In acc update'+(string)((Map<string,object>)accPostRes.get('CMAccount')).get('isoCountrycode'));
                            updateAcc.CMID__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('CMID');
                            updateAcc.Name = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('accountName');
                            updateAcc.BillingCountryCode = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('isoCountrycode');
                            updateAcc.BillingCountry = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('country');
                            updateAcc.BillingStateCode = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('stateCode');
                            if( ((Map<string,object>)accPostRes.get('CMAccount')).get('state')!='' && ((Map<string,object>)accPostRes.get('CMAccount')).get('isoCountrycode')!=''){
                                if(((Map<string,object>)accPostRes.get('CMAccount')).get('isoCountrycode') == 'CA') {
                                   updateAcc.BillingState = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('stateCode');
                                }
                                else{
                                   updateAcc.BillingState = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('state');
                                   system.debug('Normal state');
                               } 
                            }
                            
                            //updateAcc.BillingState = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('state');
                            updateAcc.BillingCity = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('city');
                            updateAcc.BillingPostalCode = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('postalCode');
                            updateAcc.Billingstreet = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('addressLine1') +' '+(string)((Map<string,object>)accPostRes.get('CMAccount')).get('addressLine2');
                            updateAcc.D_U_N_S__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('dunsNumber');
                            updateAcc.Duns_SIC2_code__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('dunsSIC2Code');
                            updateAcc.Site_Business_Name__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('dunsBusinessName');
                            updateAcc.NumberOfEmployees = ((Map<string,object>)accPostRes.get('CMAccount')).get('guEmployeeCount') ==''?0:Integer.valueof(((Map<string,object>)accPostRes.get('CMAccount')).get('guEmployeeCount'));
                            updateAcc.GU_Annual_Revenue__c = ((Map<string,object>)accPostRes.get('CMAccount')).get('guRevenueUSD')==''?0:(Decimal) ((Map<string,object>)accPostRes.get('CMAccount')).get('guRevenueUSD');
                            updateAcc.Duns_SIC2_code__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('dunsSIC2Code');
                            updateAcc.Website = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('dunsDomainName');
                            updateAcc.Tradestyle__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('dunsTradeStyleName');
                            updateAcc.DU_Duns_Number__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('duDunsNumber');
                            updateAcc.DU_Business_Name__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('duBusinessName');
                            updateAcc.GU_Duns_Number__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('guDunsNumber');
                            updateAcc.GU_Business_Name__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('guBusinessName');
                            updateAcc.AnnualRevenue = ((Map<string,object>)accPostRes.get('CMAccount')).get('siteRevenueUSD')==''?0:(Decimal) ((Map<string,object>)accPostRes.get('CMAccount')).get('siteRevenueUSD');
                            updateAcc.Site_Employees__c = ((Map<string,object>)accPostRes.get('CMAccount')).get('siteEmployeeCount') ==''?0:Integer.valueof(((Map<string,object>)accPostRes.get('CMAccount')).get('siteEmployeeCount')); 
                            updateAcc.Parent_Duns_Number__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('hqDunsNumber');
                            updateAcc.Parent_Business_Name__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('hqBusinessName');
                            updateAcc.Industry = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('industryCategory');
                            if(string.isNotEmpty(updateAcc.industry) && ((Map<string,object>)accPostRes.get('CMAccount')).get('industrySubCategory') != ''){
                             if(CheckFieldValidity.validatedependantPicklist(Account.Industry_Subcategory__c,updateAcc.Industry,(string)((Map<string,object>)accPostRes.get('CMAccount')).get('industrySubCategory')) == true )
                                updateAcc.Industry_Subcategory__c = (string)((Map<string,object>)accPostRes.get('CMAccount')).get('industrySubCategory') ; 
                            }
                            system.debug('Acc updating val'+updateAcc);
                            update updateAcc ;
                        }
                        else{
                            IntegrationLog.Result__c = 'Application Failure';
                            IntegrationLog.Exception_Message__c ='There are no enrichment attributes returned';
                            system.debug('No data in post account API response');
                        }
                        
                    }
                    else{
                      updateSFAccount();
                    }
                    IntegrationLog.Result__c = ((string)(((Map<string,object>)accPostRes.get('status')).get('statusCode'))).startswith('5') == true ? 'Application Failure':'Success';
                   // updateSFAccount();
                }catch(exception e){
                    IntegrationLog.Result__c = 'Salesforce Exception';
                    IntegrationLog.Exception_Message__c= e.getmessage();
                    IntegrationLog.ErrorTrace__c= String.format('{0}\n{1}\n\n\n\n',new List<String>{'Exception type :'+e.getTypeName(),'Trace : '+e.getStackTraceString()}); 
                    IntegrationLog.Exception_Message__c= e.getmessage();
                    if(UserInfo.getUiTheme() == 'Theme3'){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error,e.getMessage()));
                    }else{
                        throw new AuraHandledException(e.getMessage());
                    } 
                    if(SetupCompanyMaster__c.getOrgDefaults().Log_API_Calls__c)
                    Insert IntegrationLog ;
                }
                }
                else{
                    IntegrationLog.Result__c = 'Application Failure' ;
                if(UserInfo.getUiTheme() == 'Theme3'){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,(string)((Map<string,object>)accPostRes.get('status')).get('statusDescription'))); 
                }else{
                    throw new AuraHandledException((string)((Map<string,object>)accPostRes.get('status')).get('statusDescription'));
                }
                }
                
                
            }
            else if (res.getStatusCode().format().startswith('5')){
                IntegrationLog.Result__c = 'Server Failure' ;
                updateSFAccount();
            }
            else{
                IntegrationLog.Result__c = 'Server Failure' ;
            if(UserInfo.getUiTheme() == 'Theme3'){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.warning,res.getStatusCode()+'-'+res.getStatus()));   
            }else{
                throw new AuraHandledException(res.getStatusCode()+'-'+res.getStatus());
            }
        }
        
        
            if(SetupCompanyMaster__c.getOrgDefaults().Log_API_Calls__c)
            Insert IntegrationLog ;
        system.debug('Update account Stop'+System.Now().formatGMT('YYYY-MM-dd HH:mm:ss:SS'));
        }

    
/************************************************************************************
Description : call company master once the account is successfully inserted in SF
************************************************************************************/
    
    public static void updateSFAccount(){
        Database.saveResult result=Database.update(updateAcc,false);
        if(!result.isSuccess()){
            for(Database.Error err : result.getErrors()){
                if(UserInfo.getUiTheme() == 'Theme3'){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error,err.getMessage()));
                System.debug('The following error has occurred.');  
                }else{
                     throw new AuraHandledException(err.getMessage());
                } 
                return; 
            }
        }
        
        
    }
    
    public class wrapClass{
        @AuraEnabled public string errMsg;
        @AuraEnabled public Boolean hasRecAccess;
        @AuraEnabled public Boolean isFederal;
        @AuraEnabled public Boolean disableCM;
        @AuraEnabled public string variant;
        @AuraEnabled public Account accRecord;
        public wrapClass(string errMsg1,Boolean hasRecAccess1,Boolean isFederal1,Boolean disableCM1, string variant1,Account accRecord1){
            errMsg = errMsg1;
            hasRecAccess = hasRecAccess1;
            isFederal = isFederal1;
            disableCM = disableCM1;
            variant = variant1;
            accRecord = accRecord1;
        }
    }
}