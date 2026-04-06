public class UpdateAccountCaseCemTsm {
    //<Reason>
    //<Additions - 05 November, 2019>
    //To Update CEM/TSM Field on Account Level in accounts if the value in cem/tsm field on account level does not match with account team member user id as per CS-328
    @InvocableMethod
    public static void AccountCemTsmUpdate(List<Account> AccountList){
        List<account> UpdatedAccList = new List<account>();
        set<Id> AccountIdsSet = new set<Id>();
        for(Account eachAccount : AccountList){
            AccountIdsSet.add(eachAccount.Id);
        }
        //Map<Id,AccountTeamMember> accountToAccountTeamMember = new Map<Id,AccountTeamMember>();
        Map<Id,Id> accountToAccountTeamMember = new Map<Id,Id>();
        for(AccountTeamMember eachATM : [select id,UserId,AccountId,Account.Account_SAM__c,TeamMemberRole from AccountTeamMember where AccountId IN: AccountIdsSet])
        {
            if(eachATM != null && eachATM.TeamMemberRole == 'Customer Experience Manager'){
                
                accountToAccountTeamMember.put(eachATM.AccountId, eachATM.UserId);
            }
            
        }
        for(account eachAcc : [Select Id,Account_SAM__c from account where id in: AccountIdsSet]){
            if(accountToAccountTeamMember.size() > 0 && accountToAccountTeamMember.containsKey(eachAcc.Id)){
                Id ATMUserId = accountToAccountTeamMember.get(eachAcc.Id);
                if(eachAcc.Account_SAM__c != ATMUserId){
                    eachAcc.Account_SAM__c = ATMUserId;
                    accountToAccountTeamMember.put(eachAcc.Id,ATMUserId);
                    UpdatedAccList.add(eachAcc);
                }
            }else{
                accountToAccountTeamMember.put(eachAcc.Id,eachAcc.Account_SAM__c);
            }
            
        }
        
        Update UpdatedAccList;
        
        List<Case> caseList = new List<Case>();
        List<Case> updatedCaseList = new List<Case>();
        Map<Id,List<Case>> AccountsToListOfCases = new Map<Id,List<Case>>();
        for(case eachCase : [select id,AccountId,caseNumber,CEM_TSM__c,Status from Case where AccountId IN: AccountIdsSet and Status != 'Closed'])
        {
            if(AccountsToListOfCases.containsKey(eachCase.AccountId)) {
                caseList = AccountsToListOfCases.get(eachCase.AccountId);
                caseList.add(eachCase);
                AccountsToListOfCases.put(eachCase.AccountId, caseList);
            } else {
                AccountsToListOfCases.put(eachCase.AccountId,new List<case> {eachCase});
            }
        }
        for(Id accountId : AccountsToListOfCases.keySet()){
            for(case eachCase1 : AccountsToListOfCases.get(accountId)){
                if(accountToAccountTeamMember.size() > 0 && accountToAccountTeamMember.containsKey(eachCase1.AccountId)){
                    if(eachCase1.CEM_TSM__c != accountToAccountTeamMember.get(eachCase1.AccountId)){
                        eachCase1.CEM_TSM__c = accountToAccountTeamMember.get(eachCase1.AccountId);
                        updatedCaseList.add(eachCase1);
                    }
                }
            }
        }
        Update updatedCaseList;
        //</Reason>
        //</Additions - 05 November, 2019>
        
    }
}