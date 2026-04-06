/** **************************************************************************
* @File Name          : ETM_ProcessAssociationRecordBatch.cls
* @Description        : 
* @Author             : Bhushan Patil
* @Group              : 
* @Last Modified By   : Bhushan Patil
* @Last Modified On   : 2/4/2020, 10:35:10 pm
* @Modification Log   : 
* Ver       Date            Author                 Modification
* 1.0    2/3/2020        Bhushan Patil            Initial Version
******************************************************************************/
global class ETM_ProcessAssociationRecordBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Schedulable {
    
    List<Custom_Error_Log__c> errLog = new List<Custom_Error_Log__c>();
    Set<String> accountids = new Set<String>();
    public Set<Id> logIds = new Set<Id>(); 
    static String STATUS = 'New';
    static String CLASS_NAME = 'ETM_ProcessAssociationRecordBatch';
    static String ERROR_FUNCTIONALITY = 'ETM';
    static String accountTag = '<urn:sObjects> '+
        '<urn1:type>Account</urn1:type>  '+
        '<urn1:Id>{ACCID}</urn1:Id>   '+
        '</urn:sObjects> ' ;    
    
    static String requestTemplate = '<soapenv:Envelope '+
        'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"'+
        ' xmlns:urn="urn:partner.soap.sforce.com"'+
        ' xmlns:urn1="urn:sobject.partner.soap.sforce.com">'+
        '<soapenv:Header> '+
        '<urn:AssignmentRuleHeader> '+ 
        '<urn:useDefaultRule>true</urn:useDefaultRule> '+
        '<urn:assignmentRuleId></urn:assignmentRuleId> '+
        '</urn:AssignmentRuleHeader>  '+
        '<urn:SessionHeader> '+
        '<urn:sessionId>{SESSID}</urn:sessionId> '+
        '</urn:SessionHeader> '+
        '</soapenv:Header> '+
        '<soapenv:Body> '+
        '<urn:update> '+
        ' {ACCLISTS}'+ 
        '</urn:update> '+
        '</soapenv:Body> '+
        '</soapenv:Envelope>';
    
    
    public ETM_ProcessAssociationRecordBatch(Set<String> ids, Set<Id> logid) {
        accountids = ids;
        logIds = logid;
    }
    
    /**
* @description 
* @author Bhushan Patil | 2/3/2020 
* @param Database.BatchableContext bc 
* @return Database.QueryLocator 
**/
    global Database.QueryLocator start(Database.BatchableContext bc) {
        //String Query = 'Select Id,AdaptiveId__c,JobId__c,JobId__r.Name from Territory_Stage__c where JobId__r.Name =:strModelName AND JobId__r.Status__c =: STATUS ';
        Set<String> setAdaptiveId = New Set<String>();
        List<Territory_Stage__c> ListTStage = [
            Select 
            Id,
            AdaptiveId__c,
            JobId__c,
            JobId__r.Name
            from 
            Territory_Stage__c 
            where 
            JobId__c IN:logIds
            LIMIT 50000];
        for(Territory_Stage__c objTStage : ListTStage){
            setAdaptiveId.add(objTStage.AdaptiveId__c); 
        }  
        String Query = 'Select Id,ObjectId,Territory2Id,Territory2.Adaptive_Territory_Id__c FROM ObjectTerritory2Association Where Territory2.Adaptive_Territory_Id__c In : setAdaptiveId And ObjectId Not in : accountids order by Territory2.Adaptive_Territory_Id__c' ;
        system.debug('territory run rules Query'+Query);
        return Database.getQueryLocator(query);
    }
    
    /**
* @description The execute methods processes the ObjectTerritory2Association records and runs the 
*              territory assignment rule for each account. 
* @author Bhushan Patil | 2/3/2020 
* @param Database.BatchableContext BC 
* @param List<Territory_Stage__c> scope 
* @return void 
**/
    global void execute(Database.BatchableContext BC, List<ObjectTerritory2Association> scope){
        String sessionId = UserInfo.getSessionID();
        string paramvalue = UserInfo.getOrganizationId()+''+UserInfo.getSessionId().substring(15);
        set<String> setIds = new set<String>();
        System.debug('paramvalue ---'+paramvalue);
        
        List<String> lstAccString = new List<String>();
        try{    
            for(ObjectTerritory2Association objT2A : scope){
                lstAccString.add(accountTag.replace('{ACCID}', objT2A.ObjectId));
            }
            system.debug('lstAccString---'+lstAccString); 
            requestTemplate = requestTemplate.replace('{ACCLISTS}', String.join(lstAccString, ' ')) ;
            requestTemplate = requestTemplate.replace('{SESSID}', sessionId) ;                    
            HttpRequest request = new HttpRequest();
            request.setEndpoint(System.URL.getSalesforceBaseUrl().toExternalForm()+'/services/Soap/u/41.0/'+UserInfo.getOrganizationId());
            request.setMethod('POST');
            request.setHeader('Content-Type','text/xml;charset=UTF-8');
            request.setHeader('SOAPAction', '""');
            request.setTimeout(120000);
            request.setBody(requestTemplate);
            String s = String.valueOf(new Http().send(request).getBodyDocument());
            System.debug(s);
            for(ObjectTerritory2Association objT2A : scope){
                setIds.add(objT2A.Territory2.Adaptive_Territory_Id__c);
            }
            // UpdateTerritoryLogs(setIds,' Assignment Rules Executed :  \n ');
        }catch(exception e){
            String strIds = ' Failed monitering logs : ';
            for(ObjectTerritory2Association objT2A : scope){
                if(!setIds.contains(objT2A.Territory2.Adaptive_Territory_Id__c)){
                    setIds.add(objT2A.Territory2.Adaptive_Territory_Id__c);
                    strIds += objT2A.Territory2.Adaptive_Territory_Id__c;
                }
            }
            errLog.add(LogError.logEtmErrorids(CLASS_NAME,e,strIds,ERROR_FUNCTIONALITY));
            Insert errLog;
            UpdateTerritoryLogs(setIds,' (ETM_ProcessAssociationRecordBatch) Failed Logs : ' + errLog[0].id + ' \n ');
        }  
    }//End of execute
    
    /**
* @description The finish method updates the status of monitering log to complted 
so It won't pickups in the new cycle. 
* @author Bhushan Patil | 2/3/2020 
* @param Database.BatchableContext processOpptys 
* @return void 
**/
    global void finish(Database.BatchableContext BC) {
        boolean failedMonitoringlogs = false;
        string htmlBody = '<div> <p>Hi Team,</p><p> Salesforce ETM Job run failed for below records</p> </div>';
        List<ETMStage_Monitoring__c> lstMonitor = [
            Select 
            Id,
            Total_Unprocessed_Account_Records__c,
            Total_Unprocessed_Territory2_Records__c,
            Total_Unprocessed_UTA_Records__c,
            Status__c 
            FROM 
            ETMStage_Monitoring__c 
            WHERE 
            Id IN : logIds];
        for(ETMStage_Monitoring__c objMonitor : lstMonitor){
            if(objMonitor.Status__c == 'New'){
                objMonitor.id = objMonitor.id;
                objMonitor.Status__c = 'Complete';
            }
            else if(objMonitor.Status__c == 'Failed'){
                failedMonitoringlogs = true;  
                htmlBody+= '<div> <b>Montioring rec : </b> <a href="'+URL.getSalesforceBaseUrl().toExternalForm()+'/'+objMonitor.Id+'">'+objMonitor.Id+'</a> ';
                if(objMonitor.Total_Unprocessed_Territory2_Records__c!=null && objMonitor.Total_Unprocessed_Territory2_Records__c!=0)
                    htmlBody+='</ul><li> <b># Failed Territory records : </b>'+objMonitor.Total_Unprocessed_Territory2_Records__c+'</li>';
                if(objMonitor.Total_Unprocessed_Account_Records__c!=null && objMonitor.Total_Unprocessed_Account_Records__c!=0) 
                    htmlBody+='<li> <b># Failed account records: </b>'+objMonitor.Total_Unprocessed_Account_Records__c+'</li>';
                if(objMonitor.Total_Unprocessed_UTA_Records__c!=null && objMonitor.Total_Unprocessed_UTA_Records__c!=0)
                    htmlBody+='<li> <b># Failed UserTerritory records : </b>'+objMonitor.Total_Unprocessed_UTA_Records__c+'</li> </ul>';   
            }
        }
        try{
            system.debug('List monitor---'+lstMonitor);
            if(lstMonitor.size()>0)
                Update lstMonitor;
             List<OrgWideEmailAddress> owea = new List<OrgWideEmailAddress>();
            if(failedMonitoringlogs){
                Email_Preferences__mdt emailPref = [select Id, DeveloperName , Email_Subject__c, Receipient__c, cc__c, From__c from Email_Preferences__mdt where DeveloperName ='ETM_StagingTable'];
                if(emailPref.From__c!=null){
               owea  = [select Id from OrgWideEmailAddress where Address =: emailPref.From__c];
               }
                messaging.singleEmailMessage mail = new messaging.singleEmailMessage();
                mail.ToAddresses = new List<string>{emailPref.Receipient__c} ; 
                    if(emailPref.cc__c!=null)
                    mail.ccAddresses  = new List<string>(emailPref.cc__c.split(';')) ; 
                     if (!owea.isEmpty()) {
                      mail.setOrgWideEmailAddressId(owea[0].Id);
                    }   
                mail.setHtmlBody(htmlBody);
                mail.setSubject('Salesforce staging table process failed etmbatchError');    
                List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
                mails.add(mail);
                Messaging.sendEmail(mails);
            } 
            //Database.executeBatch(new ETMTerritoryOwnerAssociationBatch('AccountUpdate',null,0), 200);
        }catch(exception e){
            errLog.add(LogError.CreateGenericErrorLog(CLASS_NAME,e,ERROR_FUNCTIONALITY));
            Insert errLog;
        } 
        //SAL24-735
        Integer accBatchSize = 50;
        List<Territory_Management_Setup__mdt> fielSalesMdtBatchSize = [select Field_Value__c,Field_Type__c,Operator__c from Territory_Management_Setup__mdt where DeveloperName='ETM_Account_Batch_Size'];
        if(!fielSalesMdtBatchSize.isEmpty() && fielSalesMdtBatchSize[0].Field_Value__c!=null){
            accBatchSize = Integer.valueOf(fielSalesMdtBatchSize[0].Field_Value__c);
        }
        Database.executeBatch(new ETMTerritoryOwnerAssociationBatch('AccountUpdate',null,0), accBatchSize); //SAL24-735
    }//End of finish
    
    public void UpdateTerritoryLogs(set<String> logIds,String strStatus) {
        List<ETMStage_Monitoring__c> lstStageMoniter = new List<ETMStage_Monitoring__c>();
        Set<ETMStage_Monitoring__c> uniqueLogs = new Set<ETMStage_Monitoring__c>();
        List<ETMStage_Monitoring__c> logsToInsert = new List<ETMStage_Monitoring__c>();
        List<Territory_Stage__c> ListTStage = [
            Select 
            Id,
            AdaptiveId__c,
            JobId__c,
            JobId__r.Name,
            JobId__r.Stage_History__c
            from 
            Territory_Stage__c 
            where 
            AdaptiveId__c IN:logIds
            LIMIT 50000];
        for(Territory_Stage__c objstage : ListTStage){
            ETMStage_Monitoring__c obj = new ETMStage_Monitoring__c();
            obj.id = objstage.JobId__c;
            if(objstage.JobId__r.Stage_History__c != null){
                obj.Stage_History__c = '\n'+objstage.JobId__r.Stage_History__c +' '+ strStatus ;
            }else{
                obj.Stage_History__c = strStatus;
            } 
            lstStageMoniter.add(obj);           
        }
        uniqueLogs.AddAll(lstStageMoniter);
        logsToInsert.addAll(uniqueLogs);
        Update logsToInsert;
    }//End of CreateErrLogs
    
    global void execute(SchedulableContext SC) {
        // Database.ExecuteBatch(new ETM_ProcessAssociationRecordBatch(strModelName),200);
    }
}//End of ETM_ProcessAssociationRecordBatch