public with sharing class PartnerAccAccrdtionCalcBatch implements Database.Batchable<sObject>{
    String query;
    List<Accreditions_scoring_setting__mdt> accrSettings;
    public PartnerAccAccrdtionCalcBatch(){
        accrSettings = [SELECT MasterLabel, Contact_Certification_Achieved_field__c, Contact_Accreditation_Expiry_Field__c, Account_Rollup_field__c FROM Accreditions_scoring_setting__mdt];
        query = 'SELECT Id FROM Account WHERE RecordType.Name = \'Partner/Distributor\'';
    }
    public Database.QueryLocator start(Database.BatchableContext context){
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext context, List<Account> accList){
        String  contactFields = '';
        for(Accreditions_scoring_setting__mdt setting : accrSettings){
            contactFields = contactFields + ',' + setting.Contact_Certification_Achieved_field__c+','+setting.Contact_Accreditation_Expiry_Field__c;
        }
        String contactQuery = 'SELECT AccountId'+contactFields+' FROM Contact WHERE AccountId IN :accList';
        List<Contact> contactResults = (List<Contact>)Database.query(contactQuery);
        Map<Id, Map<String, Integer>> accountIdToCertiToCount = new Map<Id, Map<String, Integer>>();
        for(Account acc: accList) {
            accountIdToCertiToCount.put(acc.Id, new Map<String, Integer>());
        }
        for(Contact result : contactResults) {
            Id accountId = result.AccountId;
            for(Accreditions_scoring_setting__mdt setting : accrSettings){
                Date contactAccredAchieved = Date.valueOf(result.get(setting.Contact_Certification_Achieved_field__c));
                Date contactAccredExpired = Date.valueOf(result.get(setting.Contact_Accreditation_Expiry_Field__c));
                if(contactAccredAchieved != null && contactAccredAchieved <= Date.TODAY()){
                    if(accountIdToCertiToCount.get(accountId).containsKey(setting.Account_Rollup_field__c)){
                        Integer updatedcount = accountIdToCertiToCount.get(accountId).get(setting.Account_Rollup_field__c)+1;
                        accountIdToCertiToCount.get(accountId).put(setting.Account_Rollup_field__c, updatedcount);
                    }else{
                        accountIdToCertiToCount.get(accountId).put(setting.Account_Rollup_field__c, 1);
                    }
                }
                if(contactAccredExpired != null && contactAccredExpired < Date.TODAY() && accountIdToCertiToCount.get(accountId).containsKey(setting.Account_Rollup_field__c)){
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
                    }else {
                        updateAccount.put(setting.Account_Rollup_field__c, 0);
                    }
                }
                updateAccounts.add(updateAccount);
            }
            update updateAccounts;
        }
    }
    public void finish(Database.BatchableContext context){
        try{
            PC_DealRegExpiryUpdateBatch bt = new PC_DealRegExpiryUpdateBatch();
            Database.executeBatch(bt,1);
        }catch(Exception e){
            system.debug('@@ Exception occured PC_DealRegExpiryUpdateBatch '+e.getMessage());
        }
        try{
            PC_MDFSubmitClaimReminderBatch claimReminder = new PC_MDFSubmitClaimReminderBatch();
            Database.executeBatch(claimReminder,100);
        }catch(Exception e){
            system.debug('@@ Exception occured PC_MDFSubmitClaimReminderBatch '+e.getMessage());
        }
        try{
            PC_ContractExpiryBatch contractexpbatch = new PC_ContractExpiryBatch();
            Database.executeBatch(contractexpbatch,100);
        }catch(Exception e){
            system.debug('@@ Exception occured PC_ContractExpiryBatch '+e.getMessage());
        }
        try{
            PC_ReCalculate_FileSharingBatch filesharebatch = new PC_ReCalculate_FileSharingBatch();
            Database.executeBatch(filesharebatch);
        }catch(Exception e){
            system.debug('@@ Exception occured PC_ReCalculate_FileSharingBatch '+e.getMessage());
        }
        
        try{
            PC_RequestExpiredUpdateBatch requestExpiredBatch = new PC_RequestExpiredUpdateBatch();
            Database.executeBatch(requestExpiredBatch, 5);
        }catch(Exception e){
            system.debug('@@ Exception occured PC_RequestExpiredUpdateBatch'+ e.getMessage());
        } 
        
        /*try{
            MIPSyncBatch mipBatch = new MIPSyncBatch();
            Database.executeBatch(mipBatch, 1);
        }catch(Exception e){
            system.debug('@@ Exception occured MIPSyncBatch'+ e.getMessage());
        } */
    }
}