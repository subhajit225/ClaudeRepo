/**
 * @description SAL26-313 - batch apex class to update Shared MSP Customer flag on account based on POS Report end date
 * @created Date: 28-04-2025 
 */ 
public class AccountSharedCustomerUpdateBatch implements Database.Batchable<sObject>{
    
    Date TODAY = System.today();
    List <Custom_Error_Log__c> errLogs = new List <Custom_Error_Log__c> ();
    List<String> errorsList = new List<String>();
    Id ACC_RECORD_TYPE_CUSTOMER = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer_Prospect').getRecordTypeId();
    
    /**
     * @description default constructor
     */ 
    public AccountSharedCustomerUpdateBatch() {
        System.debug(logginglevel.INFO, 'Constructor called');
    }
    
    /**
     * @description batch start method
     * @param BC
     * @return Database.QueryLocator
     */ 
    public Database.QueryLocator start(Database.BatchableContext BC){
        //get accounts with 0 POS records or accounts having POS records with End Date < Today
        String query = 'SELECT Id, Shared_MSP_Customer__c '+
            ' FROM Account '+
            ' WHERE Shared_MSP_Customer__c = True AND RecordTypeId = :ACC_RECORD_TYPE_CUSTOMER AND Id NOT IN (SELECT Account__c FROM POS_Report__c WHERE End_Date__c >= :TODAY)';
              return Database.getQueryLocator(query);
    }
    
    /**
     * @description batch execute method
     * @param BC
     * @param accounts
     */
    public void execute(Database.BatchableContext BC, List<Account> accounts) {
        for(Account account : accounts){
            account.Shared_MSP_Customer__c = false;
        }
        
        if(!accounts.isEmpty()){
            flowControll.accountTrigger = false;
            handleSaveResults(accounts);
            flowControll.accountTrigger = true;
        }   
    }
    
    /**
     * @description batch finish method
     * @param BC
     */ 
    public void finish(Database.BatchableContext BC) {
        if(!errLogs.isEmpty() || Test.isRunningTest()){
            database.insert(errLogs, false);
            sendErrorReport();
        }
    }
    
    /**
     * @description Update sobject records and create error log, if DML failed
     * @param sobjectList
     */ 
    public void handleSaveResults(List<sObject> sobjectList) {
        Database.SaveResult[] result = Database.update(sobjectList, false);
        
        for(Integer i = 0; i < result.size(); i++){
            Database.SaveResult sr = result[i];
            sObject record = sobjectList[i];
            
            if(!sr.isSuccess() || Test.isRunningTest()){
                for(Database.Error err : sr.getErrors()){
                    errLogs.add(LogError.CreateDMLErrorLog('AccountSharedCustomerUpdateBatch', record.Id, err.getMessage(), 'Update Shared MSP Customer Flag on Account.'));
                    String recordUrl = System.URL.getOrgDomainUrl() + '/' + record.Id;
                    errorsList.add('<b><a href="' + recordUrl + '">' + recordUrl + '</a></b> ::' + JSON.serialize(sr.getErrors()));
                    System.debug(logginglevel.ERROR,'AccountSharedCustomerUpdateBatch'+' - The following error has occurred: ' + err.getStatusCode() + ': ' + err.getMessage());
                    System.debug(logginglevel.ERROR,'AccountSharedCustomerUpdateBatch'+' - Fields affected by this error: ' + err.getFields());
                }
            }
        }
    }

    /**
     * @description Send email for DML errors
     */ 
    public void sendErrorReport() {
        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
        emailMessage.setToAddresses(new List<String>{System.Label.SalesApps_Support_Email});
        emailMessage.setSubject('Update Shared MSP Customer Flag on Account '+' error - ' + Date.today().format());
        
        // prepare email body
        String messageBody = 'Below is a list of errors: <br/><br/>';
        if(!errLogs.isEmpty() || Test.isRunningTest()){
            messageBody += '<b>Error Log Records:</b> <br/>';
            for (Custom_Error_Log__c log : errLogs) {
                String logRecordUrl = System.URL.getOrgDomainUrl() + '/' + log.Id;
                messageBody += '<b><a href="' + logRecordUrl + '">' + logRecordUrl + '</a></b><br/>';
            }
            messageBody += '<br/>';
        }

        messageBody += 'Thank you';
        emailMessage.setHtmlBody(messageBody);
        emailMessage.setSaveAsActivity(false);

        if(!Test.isRunningTest() && !errorsList.isEmpty()){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{emailMessage});
        }
    }
}