public class AccountTeamMemberTriggerHandler {
    //To update account cem/tsm field on account on insertion of account team member of cem/tsm role
    public static void CEMRoleAccountTeamMembers(List<accountTeamMember> atmList,List<accountTeamMember> oldAtmList,Boolean isUpdate){
        set<ID> accountIdSet = new set<ID>();
        Map<Id,List<AccountTeamMember>> accountToAccountTeamMembers = new Map<Id,List<AccountTeamMember>>();
        List<Account> accList = new List <Account>();
        for(AccountTeamMember eachATM : atmList){
            if(eachATM != null){
                accountIdSet.add(eachATM.AccountId);
            }
        }
        if(isUpdate){
            if(!atmList.equals(oldAtmList)){
                for(AccountTeamMember eachAccTeamMember : atmList){
                    if(eachAccTeamMember != null &&  eachAccTeamMember.TeamMemberRole == 'Customer Experience Manager'){
                        if(accountToAccountTeamMembers.containsKey(eachAccTeamMember.AccountId)) {
                            List<AccountTeamMember> ATMListOfAccount = accountToAccountTeamMembers.get(eachAccTeamMember.AccountId);
                            ATMListOfAccount.add(eachAccTeamMember);
                            accountToAccountTeamMembers.put(eachAccTeamMember.AccountId, ATMListOfAccount);
                        } else {
                            accountToAccountTeamMembers.put(eachAccTeamMember.AccountId, new List<AccountTeamMember>{eachAccTeamMember});
                        }
                    }
                }
            }
        }
        if(!isUpdate){
            for(AccountTeamMember eachAccTeamMember : atmList){
                if(eachAccTeamMember != null && eachAccTeamMember.TeamMemberRole == 'Customer Experience Manager'){
                    if(accountToAccountTeamMembers.containsKey(eachAccTeamMember.AccountId)) {
                        List<AccountTeamMember> ATMListOfAccount = accountToAccountTeamMembers.get(eachAccTeamMember.AccountId);
                        ATMListOfAccount.add(eachAccTeamMember);
                        accountToAccountTeamMembers.put(eachAccTeamMember.AccountId, ATMListOfAccount);
                    } else {
                        accountToAccountTeamMembers.put(eachAccTeamMember.AccountId, new List<AccountTeamMember>{eachAccTeamMember});
                    }
                }
            }
        }
        for(account eachAcc : [select id,Name,Account_SAM__c from Account Where id IN: accountIdSet]){
            if(accountToAccountTeamMembers.size()>0){
                Id ATMUserId = accountToAccountTeamMembers.get(eachAcc.Id)[0].UserId;
                if(eachAcc.Account_SAM__c == null){
                    eachAcc.Account_SAM__c = ATMUserId;
                    accList.add(eachAcc);
                }
                else{
                    if(eachAcc.Account_SAM__c != ATMUserId){
                        eachAcc.Account_SAM__c = ATMUserId;
                        accList.add(eachAcc);
                    }
                }
            }
            /*else if(accountToAccountTeamMembers.size() <=0 && isUpdate == true){
                eachAcc.Account_SAM__c = null;
                accList.add(eachAcc);
            }*/
        }
        UPDATE accList;
    }
    // To update cem/tsm field on account after deletion of an account team member of cem role
    public static void CEMRoleAccountTeamMembersAfterDelete(List<accountTeamMember> oldTeamMembers){
        set<ID> accountIdSetAfterDeletion = new set<ID>();
        Map<Id,List<AccountTeamMember>> accountToAccountTeamMembersAfterDeletion = new Map<Id,List<AccountTeamMember>>();
        List<Account> accListAfterDeletion = new List <Account>();
        for(AccountTeamMember eachAccTeamMember1 : oldTeamMembers){
            if(eachAccTeamMember1 != null && eachAccTeamMember1.TeamMemberRole == 'Customer Experience Manager'){
                if(accountToAccountTeamMembersAfterDeletion.containsKey(eachAccTeamMember1.AccountId)) {
                    List<AccountTeamMember> ATMList1 = accountToAccountTeamMembersAfterDeletion.get(eachAccTeamMember1.AccountId);
                    ATMList1.add(eachAccTeamMember1);
                    accountToAccountTeamMembersAfterDeletion.put(eachAccTeamMember1.AccountId, ATMList1);
                } else {
                    accountToAccountTeamMembersAfterDeletion.put(eachAccTeamMember1.AccountId, new List<AccountTeamMember>{eachAccTeamMember1});
                }
            }
        }
        for(account eachAcc1 : [select id,Name,Account_SAM__c from Account Where ID IN: accountToAccountTeamMembersAfterDeletion.keyset()]){
            if(eachAcc1 != null){
                if(accountToAccountTeamMembersAfterDeletion.size() > 0){
                    eachAcc1.Account_SAM__c = null;
                    accListAfterDeletion.add(eachAcc1);
                }
            }
        }
        UPDATE accListAfterDeletion;
    }
}