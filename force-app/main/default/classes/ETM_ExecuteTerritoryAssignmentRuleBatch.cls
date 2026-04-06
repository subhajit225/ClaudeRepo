/********************************************************************
 * @File Name          : ETM_ExecuteTerritoryAssignmentRuleBatch.cls
 * @Description        : 
 * @Author             : Bhushan Patil
 * @Group              : 
 * @Last Modified By   : Bhushan Patil
 * @Last Modified On   : 15/4/2020, 2:04:32 pm
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0       2/3/2020      Bhushan Patil          Initial Version
*********************************************************************/
global class ETM_ExecuteTerritoryAssignmentRuleBatch implements Database.Batchable<sObject>,Database.stateful, Database.AllowsCallouts, Schedulable {
    Set<Id>jobIds = new Set<Id>();
    Set<string> accountIds = new Set<String>();
    String modelName;
    Boolean processAccounts;
    Boolean territoryActivated;
    //ETM-137: UTA History Tracking
    String strArchivedTerrName;
    String strActivatedTerrName;
    
    Static List<ETMStage_Monitoring__c> lstMonitor;
    Static String CLASS_NAME = 'ETM_ExecuteTerritoryAssignmentRuleBatch';
    Static String ERROR_FUNCTIONALITY = 'ETM';
    Static String accountTag = '<urn:sObjects> '+
                        '<urn1:type>Account</urn1:type>  '+
                        '<urn1:Id>{ACCID}</urn1:Id>   '+
                        '</urn:sObjects> ' ;    
    Static String requestTemplate = '<soapenv:Envelope '+
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


    public ETM_ExecuteTerritoryAssignmentRuleBatch(set<id>jobIds,String modelName,String strArchivedTerrName,Boolean processAccounts,Boolean territoryActivated) {
        this.jobIds = jobIds;
        this.modelName = modelName;
        this.processAccounts = processAccounts;
        this.territoryActivated = territoryActivated;
        //ETM-137
        this.strArchivedTerrName = strArchivedTerrName;
    }

    
    
    /**
    * @description 
    * @author Bhushan Patil | 19/3/2020 
    * @param Database.BatchableContext bc 
    * @return Database.QueryLocator 
    **/
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = '';
        if(processAccounts){
            List<Territory2Model> lstmodel = [
                Select 
                    Id,
                    State,
                    Name
                from
                    Territory2Model
                Where 
                    Name =: modelName 
                    AND State = 'Active'
            ];
            if(territoryActivated){
            if(!lstmodel.isEmpty()){
                List<ETMStage_Monitoring__c> lstStageMoniter = new List<ETMStage_Monitoring__c>();
                for(ETMStage_Monitoring__c obj : [ Select 
                                                        Id,
                                                        Stage_History__c,
                                                        Status__c
                                                    From    
                                                        ETMStage_Monitoring__c
                                                    Where 
                                                        Id IN : jobIds]
                ){
                    if(obj.Stage_History__c != null){
                        obj.Stage_History__c += '\n Territory Activated : ' + lstmodel[0].Name ;
                    }else{
                        obj.Stage_History__c =  'Territory Activated : ' + lstmodel[0].Name ;
                    } 
                    lstStageMoniter.add(obj);         
                }//End of for
                Update lstStageMoniter;

                //ETM-137
                strActivatedTerrName = modelName;
                query = 'Select id from account where Adaptive_Territory_Id__c = null and Account.RecordType.DeveloperName=\'Customer_Prospect\' ' ; 
            }
           } 
          else{
          query = 'select id,AccountId,NewValue,OldValue,CreatedBy.name from AccountHistory where CreatedDate> YESTERDAY and Field=\'Adaptive_Territory_Id__c\'  and Account.RecordType.DeveloperName=\'Customer_Prospect\' and (NOT CreatedBy.Username like \'etm@rubrik.com%\') order by createddate desc';
          }
        }else{
            query = 'Select Id,Account__c,JobId__c from Account_Stage__c Where JobId__c IN: jobIds AND Account__c != null AND Status__c =\'Success\' order by JobId__c';
        }
        System.debug('Run rules query'+query);       
        return Database.getQueryLocator(query);
    }//End of start

    /**
    * @description The execute method is processing the account stage records and running the 
    *              Territory assignment rules to assign the account to the correct terriroty 
    *              The SOAP api is limited to process 200 records at a time so we can not increse 
    *              the batch size more the 200.  
    * @author Bhushan Patil | 19/3/2020 
    * @param Database.BatchableContext BC 
    * @param List<Account_Stage__c> scope 
    * @return void 
    **/
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<Custom_Error_Log__c> errLog = new List<Custom_Error_Log__c>();
        Map<String,List<String>> mapMonitor_Accounts = new Map<String,List<String>>();
        List<ETMStage_Monitoring__c> lstStageMoniter = new List<ETMStage_Monitoring__c>();
        String sessionId = UserInfo.getSessionID();    
        List<String> lstAccString = new List<String>();
        try{
            if(processAccounts == false){
                for(sObject sobj : scope){
                    Account_Stage__c accStage = (Account_Stage__c)sobj;
                    lstAccString.add(accountTag.replace('{ACCID}', accStage.Account__c));
                    accountIds.add(accStage.Account__c);
                    if(!mapMonitor_Accounts.ContainsKey(string.valueOf(accStage.JobId__c))){
                        List<String> lststring = new List<String>();
                        lststring.add(accStage.Account__c);
                        mapMonitor_Accounts.put(accStage.JobId__c,lststring);
                    }else{
                        mapMonitor_Accounts.get(accStage.JobId__c).add(accStage.Account__c);
                    }
                }
            }else{
                if(territoryActivated){
                for(sObject sobj : scope){ 
                      Account objAccount = (Account)sobj;
                      lstAccString.add(accountTag.replace('{ACCID}',objAccount.Id));
                  }
               }
             else{  
             for(sObject sobj : scope){ 
                      AccountHistory accHistory = (AccountHistory)sobj;
                      if(accHistory.NewValue==null){
                          lstAccString.add(accountTag.replace('{ACCID}',accHistory.AccountId));
                      }
                   }
            }
          }  
            system.debug('lstAccString---'+lstAccString); 
            requestTemplate = requestTemplate.replace('{ACCLISTS}', String.join(lstAccString, ' ')) ;
            requestTemplate = requestTemplate.replace('{SESSID}', sessionId) ;                    
            HttpRequest request = new HttpRequest();
            request.setEndpoint(System.URL.getSalesforceBaseUrl().toExternalForm()+'/services/Soap/u/41.0/'+UserInfo.getOrganizationId());
            request.setMethod('POST');
            request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
            request.setHeader('SOAPAction', '""');
            request.setTimeout(120000);
            request.setBody(requestTemplate);
            String s = String.valueOf(new Http().send(request).getBodyDocument());        
        }catch(exception e){
            String failedLogs = 'Failed monitering logs : ';
            for(String strKey : mapMonitor_Accounts.keyset()){
                failedLogs += strKey+', ';
            }
            failedLogs.removeEnd(',');
            errLog.add(LogError.logEtmErrorids(CLASS_NAME,e,failedLogs,ERROR_FUNCTIONALITY));
            Insert errLog;
            for(ETMStage_Monitoring__c obj : [ Select 
                                                Id,
                                                Stage_History__c,
                                                Status__c
                                            From    
                                                ETMStage_Monitoring__c
                                            Where 
                                                Id IN : mapMonitor_Accounts.keyset()] 
            ){
                if(!errLog.isEmpty()){
                    if(obj.Stage_History__c != null){                    
                        obj.Stage_History__c +=  '\n (ETM_ExecuteTerritoryAssignmentRuleBatch) Failed Logs : '+ errLog[0].id ;
                    }else{
                        obj.Stage_History__c = '\n (ETM_ExecuteTerritoryAssignmentRuleBatch) Failed Logs : '+ errLog[0].id ;
                    }
                }
                lstStageMoniter.add(obj);
            }    
            Update lstStageMoniter;
        }//End of Catch  
    }//End of execute
    

    /**
    * @description 
    * @author Bhushan Patil | 19/3/2020 
    * @param Database.BatchableContext bc 
    * @return void 
    **/
    global void finish(Database.BatchableContext bc) {
        //Executing the next batch to process the ObjectTerritory2Association records
        if(processAccounts){
            //SAL24-334/SF-37097
            //Database.ExecuteBatch(new ETM_ExecuteTerritoryAssignmentRuleBatch(jobIds,modelName,strArchivedTerrName,false,territoryActivated),200);
            Database.ExecuteBatch(new ETM_ExecuteTerritoryAssignmentRuleBatch(jobIds,modelName,strArchivedTerrName,false,territoryActivated),100);
            //ETM-137
            if(strActivatedTerrName != null || strArchivedTerrName != null){
                Database.ExecuteBatch(new ETM_UpdateUTAHistoryRecordBatch(strActivatedTerrName,strArchivedTerrName),200);
            }
        }else{
            Database.ExecuteBatch(new ETM_ProcessAssociationRecordBatch(accountIds,jobIds),200);
        }
         
    }//End of finish


    /**
    * @description 
    * @author Bhushan Patil | 19/3/2020 
    * @param SchedulableContext SC 
    * @return void 
    **/
    global void execute(SchedulableContext SC) {
        //SAL24-334/SF-37097
        //Database.ExecuteBatch(new ETM_ExecuteTerritoryAssignmentRuleBatch(jobIds,modelName,strArchivedTerrName,true,territoryActivated),200);
        Database.ExecuteBatch(new ETM_ExecuteTerritoryAssignmentRuleBatch(jobIds,modelName,strArchivedTerrName,true,territoryActivated),100);
    }//End of execute
}//End of ETM_ExecuteTerritoryAssignmentRuleBatch