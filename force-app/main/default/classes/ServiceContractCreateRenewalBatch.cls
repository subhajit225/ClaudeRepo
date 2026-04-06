/**
* @description Batch Job to update the Renewal Quoted field on Service Contracts and create Renewal Opps.
*              JIRA - CPQ22-651
*      
* @CreatedDate 2nd Feb 2022
* @Created By Joyce   Joseph 
* Changes:
   Version Ticket       Changes
   v1     CPQ22-1068   Added logic to insert error details in Batch error log object.
* @Test Class ServiceContractCreateRenewalBatchTest
*/
public with sharing class ServiceContractCreateRenewalBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
    public String query;
    public List<String> errorsnewSCList = new List<String>();
    public List<Batch_Error_Log__c> batchErrLogList = new List<Batch_Error_Log__c>();
 
    public ServiceContractCreateRenewalBatch(){
        string Shipment_Validation='Complete';
        string ProcessType='Aspen';
        String strOppSubType = 'CSAT';
        query = 'Select id,CreatedDate, EndDate, SBQQSC__RenewalQuoted__c,LastModifiedDate,Is_Renewed__c,SBQQSC__Order__r.Overview_Shipment_Detail__r.Quote_ShipmentValidation__c,SBQQSC__Order__r.ProcessType__c,SBQQSC__Order__c,SBQQSC__Order__r.SBQQ__Contracted__c from ServiceContract ';
        //Start - CPQ22-3346 - Added SBQQSC__Quote__r.OpportunitySubType__c != CSAT check in the query. The below commented lines have been kept as backup
        //query +='where CreatedDate = YESTERDAY OR (LastModifiedDate = YESTERDAY  AND SBQQSC__RenewalQuoted__c=false) OR (SBQQSC__Quote__r.Shipment_Validation__c=\''+Shipment_Validation+'\' AND SBQQSC__Order__r.ProcessType__c=\''+ProcessType+'\' AND SBQQSC__RenewalQuoted__c =false AND Is_Renewed__c=false) OR ';
        //query += 'EndDate = NEXT_N_DAYS:121 order by EndDate DESC';
        if(!Test.isRunningTest()){
           query +='where SBQQSC__Order__c != null AND SBQQSC__Order__r.SBQQ__Contracted__c = true AND SBQQSC__Quote__r.OpportunitySubType__c != \''+strOppSubType+'\' AND (CreatedDate = YESTERDAY OR (SBQQSC__Order__r.Overview_Shipment_Detail__r.Quote_ShipmentValidation__c=\''+Shipment_Validation+'\' AND SBQQSC__Order__r.ProcessType__c=\''+ProcessType+'\' AND SBQQSC__RenewalQuoted__c =false AND Is_Renewed__c=false)) '; //REEN-25, removed (LastModifiedDate = YESTERDAY  AND SBQQSC__RenewalQuoted__c=false)
        }
        query += 'order by EndDate DESC'; 
        //End - CPQ22-3346
    } 

    /**
    * @description start method runs at the beginning of a batch Apex job which collects the records or objects to pass to the execute method. 
    * @param  BatchableContext - Database.BatchableContext
    * @return Database.QueryLocator - List of Accounts
    */
    public Database.QueryLocator start(Database.BatchableContext batchableContext){
        return Database.getQueryLocator(query);
    }
    
    /**
    * @description execute method is called for each batch of records that you pass to it
    * @param  BatchableContext - Database.BatchableContext
    * @param  accounts - List of Accounts
    * @return void
    */
    public void execute(Database.BatchableContext batchableContext, List<ServiceContract> serviceContracts){
        List<ServiceContract> newServiceContracts = new List<ServiceContract>();
        Integer intNewSCSize = 0;
        Integer itr = 0; //ARY-1005 
        Map<Id, ServiceContract> mapOfSCstoUpdate = new Map<Id, ServiceContract>();
        for(ServiceContract eachContract: serviceContracts) {
            //create renewel contract for non-Aspen quote
            if(eachContract.SBQQSC__Order__r.ProcessType__c!='Aspen'){
          eachContract.SBQQSC__RenewalQuoted__c = true;
                    eachContract.Is_Renewed__c=true;
                    newServiceContracts.add(eachContract);
            }
            //create renewel contract for Aspen quote
            if(eachContract?.SBQQSC__Order__r?.Overview_Shipment_Detail__r?.Quote_ShipmentValidation__c == 'Complete' && eachContract.SBQQSC__Order__r.ProcessType__c=='Aspen' && eachContract.SBQQSC__RenewalQuoted__c ==false && eachContract.Is_Renewed__c==false ){
                eachContract.SBQQSC__RenewalQuoted__c = true;
                eachContract.Is_Renewed__c=true;
                newServiceContracts.add(eachContract);
            }
        }
               
        intNewSCSize = newServiceContracts.size();
        
        //ARY-1005 starts
        if (!newServiceContracts.isEmpty()) {
            mapOfSCstoUpdate.putAll(newServiceContracts);
        }
        Map<Integer, String> mapOfIds = new Map<Integer, String>();
        
        if (mapOfSCstoUpdate.size()>0) {
            List<Database.SaveResult> saveResults = Database.update(mapOfSCstoUpdate.values(), false);
            String erroSCMsg;
            //log errors
            for (String ids : mapOfSCstoUpdate.keySet()) {
                mapOfIds.put(itr, ids);
                itr++;
            }
            for (Integer i = 0; i < mapOfIds.size(); i++) {
            Database.SaveResult result1 = saveResults[i];
            if(result1.isSuccess()){
            System.debug('Success-'+mapOfIds.get(i));
            }
                Database.SaveResult result = saveResults[i];
                if (!result.isSuccess() || Test.isRunningTest()) {
                    if(i < intNewSCSize) {            
                        errorsnewSCList.add('<b>' + mapOfIds.get(i) + '</b> ::' + JSON.serialize(result.getErrors()));
                        erroSCMsg=System.Label.ScCreatedYesterday;//store error message in custom label
                    } 
                    for(Database.Error errdata : result.getErrors()) {   
      //added by shiva - CPQ22-1068 - start
                        batchErrLogList.add(new Batch_Error_Log__c(Class_Name__c=System.Label.ServiceContractCreateRenewalBatch,Failure_Job_ID__c=batchableContext.getJobId(),Failure_Message__c=string.ValueOf(errdata),Scenario__c=erroSCMsg,Service_Contract_Id__c=mapOfIds.get(i),Failure_Date__c=Date.today()));
                    }
                }
            }
        }
        try{
        if(!batchErrLogList.isEmpty()){
            upsert batchErrLogList; //ARY-1005 - Changed from Insert to Upsert since it was giving cannot specify Id in an insert call: [Id] issue.
        }
        }catch(exception e){
            system.debug('@@@@ Error Details line 114 @@@'+e.getMessage());
        }
        //added by shiva - CPQ22-1068 - End
    }
    
    /**
    * @description finish is to execute post-processing operations
    * @param  batchableContext - Database.BatchableContext
    * @return void
    */
    public void finish(Database.BatchableContext batchableContext){
        //Send email to ID with error log
        Messaging.SingleEmailMessage emailmessage = new Messaging.SingleEmailMessage();
        String strEmails = System.Label.ServiceContractRenewalForecastBatch_Emails;
        //CPQ22-4074 starts - Added strCPQAdmin
        String strCPQAdmin = System.Label.CPQAdminEmailId;
        String[] toAddresses = !String.isBlank(strEmails) ? strEmails.split(',') : new List<String>{strCPQAdmin};
        emailmessage.setToAddresses(toAddresses);
        emailmessage.setSubject('Service Contract Renewal Batch Errors - ' + Date.today().format());

        String Message = 'Below is a list of the Service Contracts that failed to renew <br/><br/>';
        if(!errorsnewSCList.isEmpty()) {
            Message += '<b>SCs created YESTERDAY:</b> <br/>';
            for(String eachError : errorsnewSCList) {
                Message += eachError + '<br/>';
            }
            Message += '<br/>';
        }
        
        Message += '<br/>Thank you';
        emailmessage.setHtmlBody(Message);
        Boolean isSandbox = [select isSandbox from organization WITH SECURITY_ENFORCED limit 1].isSandbox;
        if(!isSandbox){
        if (!test.isRunningTest() && (!errorsnewSCList.isEmpty() )) {
            //Send email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { emailmessage });
        }
        
        /*************Calling Approval Reminder Batch Class********************/
        ApprovalReminderEmailBatch batch = new ApprovalReminderEmailBatch();
        Database.executeBatch(batch,50);
        }
        /*********************************************************************/
    }
    
    /**
    * @description Schedule class execure method
    * @param  SchedulableContext - SchedulableContext
    * @return void
    */
    public void execute(SchedulableContext schedulableContext) {
        ServiceContractCreateRenewalBatch scCreateRenewal = new ServiceContractCreateRenewalBatch();
        if(!Test.isRunningTest()) {Database.executeBatch(scCreateRenewal, 1);}
    }
}