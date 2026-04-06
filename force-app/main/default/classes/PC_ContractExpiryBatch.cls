global class PC_ContractExpiryBatch  implements Database.Batchable<SObject>,Database.RaisesPlatformEvents  {
    public string EXPIRED = 'Expired';
    public string OUTDATED = 'Outdated';
    public string SUPERSEDED = 'Superseded';
    public string MASTER = 'Master Agreement';
    public string ACTIVE = 'Active';
	
    global Database.QueryLocator start(Database.BatchableContext BC) {
        string query = 'SELECT Id,Contract_Status__c,Agreement_Type__c,AccountId FROM Contract WHERE EndDate < TODAY AND Contract_Status__c =: ACTIVE  AND Agreement_Type__c =:MASTER';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Contract> contractList) {
        for(Contract con : contractList){
            con.Contract_Status__c = OUTDATED;
        }
        update contractList;
        //Commented as a part of PRIT25-697. Accounts are getting updated via record triggered flow
        /*
        List<Contract> conList = new List<Contract>();
        List<Contract> allConList = new List<Contract>();
        List<Account> accList = new List<Account>();
        Map<Id,Account> updatedaccMap = new Map<Id,Account>();
        Map<string,boolean> accStatusMap = new Map<string,boolean>();
        Set<Id> accId = new Set<Id>();

        for(Contract con : scope){
            if(con.Agreement_Type__c == 'Reseller' || con.Agreement_Type__c == 'MSP' || con.Agreement_Type__c == 'Distributor'){
                accId.add(con.AccountId);
            }
        }
        
        for(Contract con : scope){
            con.Contract_Status__c = EXPIRED;
            conList.add(con);
        }
        if(!conList.isEmpty()){
            update conList;
        }
        if(!accId.isEmpty()){
        	accList = [select Id,Type,Contract_Status__c from Account where Contract_Status__c !=:EXPIRED AND Id IN:accId];
            allConList = [select Id,Contract_Status__c,Agreement_Type__c,AccountId,Account.Type,Account.Contract_Status__c from Contract where AccountId IN: accId];
        }
        for(Contract con : allConList){
            accStatusMap.put(con.AccountId,false);
        }
        system.debug('@@before accStatusMap '+accStatusMap);
        for(Contract con : allConList){
            if(con.Contract_Status__c != EXPIRED && ((con.Agreement_Type__c == 'Reseller' && (con.Account.Type == 'MSP-Reseller' || con.Account.Type == 'Reseller')) || (con.Agreement_Type__c == 'MSP' && con.Account.Type == 'MSP') || (con.Agreement_Type__c == 'Distributor' && con.Account.Type == 'Distributor'))){
                system.debug('@@ in '+con.Contract_Status__c);
                accStatusMap.put(con.AccountId,true);
            }
        }
        system.debug('@@ allConList '+allConList);
        system.debug('@@ accStatusMap '+accStatusMap);
        for(Contract con : conList){
            for(Account acc : accList){
                if(!accStatusMap.isEmpty() && accStatusMap.containskey(acc.Id) && accStatusMap.get(acc.Id) == false && acc.Id  == con.AccountId && ((con.Agreement_Type__c == 'Reseller' && (acc.Type == 'MSP-Reseller' || acc.Type == 'Reseller')) || (con.Agreement_Type__c == 'MSP' && acc.Type == 'MSP') || (con.Agreement_Type__c == 'Distributor' && acc.Type == 'Distributor'))){
                    acc.Contract_Status__c = EXPIRED;
                    updatedaccMap.put(acc.Id,acc);
                }
            }
        }
        if(!updatedaccMap.isEmpty()){
            update updatedaccMap.values();
        }
	*/
    }
    global void finish(Database.BatchableContext BC) {

    }
}