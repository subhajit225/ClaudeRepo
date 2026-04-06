/** Description: (SAL25-107) SFDC Account Status and Type for churned customers
    Created Date: 13-Nov-2024 
*/
public class AccountUpdateTypeStatusBatch implements Database.Batchable<sObject> {

    List <Custom_Error_Log__c> errLogs = new List <Custom_Error_Log__c> ();
    List<String> errorsList = new List<String>();
    String CLASS_NAME = 'AccountBatch';
    String FUNCTIONALITY = 'Update Account Type and Status to Prospect/Customer';
    @testvisible Id OPP_RECORD_TYPE_RENEWAL = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Renewal_Opportunity').getRecordTypeId();
    Id ACC_RECORD_TYPE_CUSTOMER = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer_Prospect').getRecordTypeId();
    String PROSPECT = 'Prospect';
    String CUSTOMER = 'Customer';
    Date PAST_90_DAYS = System.today().addDays(-90);
    Set<String> custSetOfTypes = new Set<String>{CUSTOMER, ''};
    Set<String> prosSetOfTypes = new Set<String>{PROSPECT, ''};
    Set<String> setOfValidTypes = new Set<String>{CUSTOMER, PROSPECT, ''};
    String queryStr = '';
    
    //batch constructor: initially blank, to handle Customer accounts
    //second iteration will handle Prospect accounts
    public AccountUpdateTypeStatusBatch(String queryStr) {
        this.queryStr = queryStr;
    }

    // batch Start: to get account records
    public Database.QueryLocator start(Database.BatchableContext BC){
        if(String.isNotBlank(queryStr)) {
            return Database.getQueryLocator(queryStr);
        } 
        String query = 'SELECT Id, Type, Status__c, (SELECT Id, EndDate FROM Entitlements WHERE Status = \'Expired\' AND EndDate < :PAST_90_DAYS ORDER BY EndDate DESC LIMIT 1)'+
            ' FROM Account WHERE (Type IN :custSetOfTypes OR Status__c IN :custSetOfTypes)'+
            ' AND Type IN :setOfValidTypes'+
            ' AND RecordTypeId = :ACC_RECORD_TYPE_CUSTOMER'+
            ' AND Id NOT IN (SELECT AccountId FROM Entitlement WHERE (Status = \'Active\' OR (Status = \'Expired\' AND EndDate > :PAST_90_DAYS)) AND Type != \'Evaluation\')';
              return Database.getQueryLocator(query);
    }

    // batch execute: to change account status and type
    public void execute(Database.BatchableContext BC, List<Account> accounts) {
        List<Account> accountsToUpdate = new List<Account>();    
        if(String.isNotBlank(queryStr)){
            updateAccountsToCustomer(accounts, accountsToUpdate);
        } else {
            updateAccountsToProspect(accounts, accountsToUpdate);
        }
        if(!accountsToUpdate.isEmpty()){
            handleSaveResults(accountsToUpdate);
        }        
    }   
    
    // batch finish: start second batch iteration, and send error email 
    public void finish(Database.BatchableContext BC) {
        if(String.isBlank(queryStr)) {
            queryStr = 'SELECT Id, Type, Status__c FROM Account WHERE (Type IN :prosSetOfTypes OR Status__c IN :prosSetOfTypes)'+
                        ' AND RecordTypeId = :ACC_RECORD_TYPE_CUSTOMER'+
                        ' AND Type IN :setOfValidTypes'+
                        ' AND Id IN (SELECT AccountId FROM Entitlement WHERE Type != \'Evaluation\' AND Status = \'Active\')';
            Database.executeBatch(new AccountUpdateTypeStatusBatch(queryStr), 50);
        }

        if(!errLogs.isEmpty()){
            database.insert(errLogs, false);
            sendErrorReport();
        }
    }
    
    /**** Update account type and status to Prospect ****/
    private void updateAccountsToProspect(List<Account> accounts, List<Account> accountsToUpdate) {
        Map<Id, Date> accIdsAndExpEntitlementDateMap = new Map<Id, Date>();
        Set<Id> accountsHavingRenewalOppty = new Set<Id>();
        
        for(Account account : accounts){
            if(!account.Entitlements.isEmpty()) {
                accIdsAndExpEntitlementDateMap.put(account.Id, account.Entitlements[0].EndDate);
            }
        }
        
        if(!accIdsAndExpEntitlementDateMap.isEmpty()){
            List<Opportunity> renewalOpps = [SELECT Id, CloseDate, AccountId
                                             FROM Opportunity 
                                             WHERE AccountId IN :accIdsAndExpEntitlementDateMap.keySet() 
                                             AND Opportunity_Sub_Type__c = 'Renewal'
                                             AND RecordTypeId = :OPP_RECORD_TYPE_RENEWAL
                                             AND IsClosed = false];
            
            
            for(Opportunity opportunity : renewalOpps){
                Date endDate = accIdsAndExpEntitlementDateMap.get(opportunity.AccountId);
                if(opportunity.CloseDate <= endDate.addDays(120)){
                    accountsHavingRenewalOppty.add(opportunity.AccountId);
                }
            }
        }
        
        for(Account account : accounts) {
            if(!accountsHavingRenewalOppty.contains(account.Id)){
                if(custSetOfTypes.contains(account.Type)){
                    account.Type = PROSPECT;
                }
                account.Status__c = PROSPECT;
                accountsToUpdate.add(account);
            }
        }
    }
    
    /**** Update account type and status to Customer ****/
    private void updateAccountsToCustomer(List<Account> accounts, List<Account> accountsToUpdate) {
        for(Account account : accounts) {
            if(prosSetOfTypes.contains(account.Type)){
                account.Type = CUSTOMER;
            }
            account.Status__c = CUSTOMER;
            accountsToUpdate.add(account);
        }
    }

    /**** Update sobject records and create error log, if DML failed. ****/
    public void handleSaveResults(List<sObject> sobjectList) {
        Database.SaveResult[] result = Database.update(sobjectList, false);
        
        for(Integer i = 0; i < result.size(); i++){
            Database.SaveResult sr = result[i];
            sObject record = sobjectList[i];
            
            if(!sr.isSuccess()){
                for(Database.Error err : sr.getErrors()){
                    errLogs.add(LogError.CreateDMLErrorLog(CLASS_NAME, record.Id, err.getMessage(), FUNCTIONALITY));
                    String recordUrl = System.URL.getOrgDomainUrl() + '/' + record.Id;
                    errorsList.add('<b><a href="' + recordUrl + '">' + recordUrl + '</a></b> ::' + JSON.serialize(sr.getErrors()));
                    System.debug(CLASS_NAME+' - The following error has occurred: ' + err.getStatusCode() + ': ' + err.getMessage());
                    System.debug(CLASS_NAME+' - Fields affected by this error: ' + err.getFields());
                }
            }
        }
    }

    /**** Send failed record to sales app email address. ****/
    public void sendErrorReport() {
        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
        emailMessage.setToAddresses(new List<String>{System.Label.SalesApps_Support_Email});
        emailMessage.setSubject(FUNCTIONALITY+' error - ' + Date.today().format());
        
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