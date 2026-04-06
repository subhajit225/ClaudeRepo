public with sharing class PartnerAccredRollUpCorrection 
                            implements Database.Batchable<SObject>, System.Schedulable {
    
    String query;List<Accreditions_scoring_setting__mdt> accrSettings;
    public PartnerAccredRollUpCorrection(){
        accrSettings = [SELECT MasterLabel, Contact_Certification_Achieved_field__c, Contact_Accreditation_Expiry_Field__c, Account_Rollup_field__c
                                                            FROM Accreditions_scoring_setting__mdt];
        query = 'SELECT Id, AccountId FROM Contact WHERE CreatedDate>2021-01-09T00:00:00Z AND Account.RecordType.Name != \'Partner/Distributor\' AND AccountId!=null';
    }
    public Database.QueryLocator start(Database.BatchableContext context){
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext context, List<Contact> conList){
        Map<Id, Map<String, Integer>> accountIdToCertiToCount = new Map<Id, Map<String, Integer>>();
        for(Contact con : conList) {
            accountIdToCertiToCount.put(con.AccountId, new Map<String, Integer>());
        }
        Set<Id> accountIds = accountIdToCertiToCount.keySet();
        String  contactFields = '';
        for(Accreditions_scoring_setting__mdt setting : accrSettings){
            contactFields = contactFields + ',' + setting.Contact_Certification_Achieved_field__c+','+setting.Contact_Accreditation_Expiry_Field__c;
        }
        String contactQuery = 'SELECT AccountId'+contactFields+' FROM Contact WHERE AccountId IN :accountIds';
        List<Contact> contactResults = (List<Contact>)Database.query(contactQuery);
        for(Contact result : contactResults) {
            Id accountId = result.AccountId;   
            for(Accreditions_scoring_setting__mdt setting : accrSettings){
                Date contactAccredAchieved = Date.valueOf(result.get(setting.Contact_Certification_Achieved_field__c));
                Date contactAccredExpired = Date.valueOf(result.get(setting.Contact_Accreditation_Expiry_Field__c));
                if(contactAccredAchieved != null && contactAccredAchieved <= Date.TODAY()){
                    if(accountIdToCertiToCount.get(accountId).containsKey(setting.Account_Rollup_field__c)){
                        Integer updatedcount = accountIdToCertiToCount.get(accountId).get(setting.Account_Rollup_field__c)+1;
                        accountIdToCertiToCount.get(accountId).put(setting.Account_Rollup_field__c, updatedcount);
                    }
                    else 
                        accountIdToCertiToCount.get(accountId).put(setting.Account_Rollup_field__c, 1);    
                }
                if(contactAccredExpired != null && contactAccredExpired < Date.TODAY()){
                    Integer updatedcount = accountIdToCertiToCount.get(accountId).get(setting.Account_Rollup_field__c)-1;
                    accountIdToCertiToCount.get(accountId).put(setting.Account_Rollup_field__c, updatedcount);        
                }
            }
        }
        if(!accountIdToCertiToCount.isEmpty()){
            List<Account> updateAccounts = new List<Account>();
            for(Id accountId: accountIdToCertiToCount.keySet()) {
                Account updateAccount = new Account(Id = accountId);
                for(Accreditions_scoring_setting__mdt setting : accrSettings){
                    if(accountIdToCertiToCount.get(accountId).containsKey(setting.Account_Rollup_field__c)){
                        updateAccount.put(setting.Account_Rollup_field__c, accountIdToCertiToCount.get(accountId).get(setting.Account_Rollup_field__c));
                    }
                    else {
                        updateAccount.put(setting.Account_Rollup_field__c, 0);
                    }
                }
                updateAccounts.add(updateAccount);
            }
            update updateAccounts;
        }
    }
    public void finish(Database.BatchableContext context) {

    }
    public void execute(System.SchedulableContext context){
        Database.executeBatch(this, 200);
    }
}