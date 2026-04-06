@isTest
public class Test_UpdateAccountCaseCemTsm {
    public static testMethod void AccountCemTsmUpdateMeth(){
        
       	List<Account> accList = new List<Account>();
        Account acc = new Account(Name = 'Test Account');
        Account acc1 = new Account(Name = 'Test Account1');
        accList.add(acc);
        accList.add(acc1);
        Insert accList;
        Contact cont = TestDataFactory.getContact(acc);
        insert cont;
        
        List<AccountTeamMember> atmList = new List<AccountTeamMember>();
        //AccountTeamMember with CEM Role
        AccountTeamMember atmRecord = new AccountTeamMember();
        atmRecord.UserId = Userinfo.getUserId();
        atmRecord.AccountId = accList[0].Id;
        atmRecord.TeamMemberRole = 'Customer Experience Manager';
        atmList.add(atmRecord);
        
        AccountTeamMember atmRecord1 = new AccountTeamMember();
        atmRecord1.UserId = Userinfo.getUserId();
        atmRecord1.AccountId = accList[0].Id;
        atmRecord1.TeamMemberRole = 'Customer Experience Manager';
        atmList.add(atmRecord1);
        Insert atmList;
        List<Case> csList = new List<Case>();
        case cs = TestDataFactory.getCase(acc, cont);
        csList.add(cs);
        case cs1 = TestDataFactory.getCase(acc, cont);
		csList.add(cs1); 
        insert csList;
        UpdateAccountCaseCemTsm.AccountCemTsmUpdate(accList);
        //Assertion
        Account accRec = [Select id,Account_SAM__c from account where id =: accList[0].id];
        System.assertEquals(UserInfo.getUserId(),accRec.Account_SAM__c);
        case caseRec = [Select id,CEM_TSM__c from Case where id =: csList[0].id];
        System.assertEquals(accRec.Account_SAM__c,caseRec.CEM_TSM__c);
    }
}