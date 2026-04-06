@isTest
public class Test_AccountTeamMemberTriggerHandler {
    public static testMethod void ToInsertAccountTeamMemberOfCemRole(){
        //To get Logged in User Id
        Id loggedInUserId = UserInfo.getUserId();
        //Create Account
        List<Account> accList = new List<Account>();
        Account acc = new Account(Name = 'Test Account');
        Account acc1 = new Account(Name = 'Test Account1');
        accList.add(acc);
        accList.add(acc1);
        Insert accList;
        //Create AccountTeamMembers
        List<AccountTeamMember> atmList = new List<AccountTeamMember>();
        List<AccountTeamMember> atmList1 = new List<AccountTeamMember>();
        List<AccountTeamMember> atmList2 = new List<AccountTeamMember>();
        //AccountTeamMember with CEM Role
        AccountTeamMember atmRecord = new AccountTeamMember();
        atmRecord.UserId = loggedInUserId;
        atmRecord.AccountId = accList[0].Id;
        atmRecord.TeamMemberRole = 'Customer Experience Manager';
        atmList.add(atmRecord);
        AccountTeamMember atmRecord1 = new AccountTeamMember();
        atmRecord1.UserId = loggedInUserId;
        atmRecord1.AccountId = accList[0].Id;
        atmRecord1.TeamMemberRole = 'Customer Experience Manager';
        atmList.add(atmRecord1);
        Insert atmList;
        AccountTeamMember atmRecord2 = new AccountTeamMember();
        atmRecord2.UserId = loggedInUserId;
        atmRecord2.AccountId = accList[1].Id;
        atmRecord2.TeamMemberRole = 'Customer Experience Manager';
        atmList1.add(atmRecord2);
        AccountTeamMember atmRecord3 = new AccountTeamMember();
        atmRecord3.UserId = loggedInUserId;
        atmRecord3.AccountId = accList[1].Id;
        atmRecord3.TeamMemberRole = 'Customer Experience Manager';
        atmList1.add(atmRecord3);
        Insert atmList1;
        AccountTeamMember atmRecord4 = new AccountTeamMember();
        atmRecord4.UserId = loggedInUserId;
        atmRecord4.AccountId = accList[1].Id;
        atmRecord4.TeamMemberRole = 'Sales Engineer Manager';
        atmList2.add(atmRecord4);
        Insert atmList2;
        AccountTeamMemberTriggerHandler.CEMRoleAccountTeamMembers(atmList,atmList,false);
        //Assertion to check the updated list of account with userId in acountSam field
        Account accRec = [Select id,Account_SAM__c from account where id =: accList[0].id];
        System.assertEquals(atmRecord1.UserId,accRec.Account_SAM__c);
        AccountTeamMemberTriggerHandler.CEMRoleAccountTeamMembers(atmList1,atmList2,true);
        AccountTeamMemberTriggerHandler.CEMRoleAccountTeamMembersAfterDelete(atmList1);
        //Assertion to check the updated list of account with blank value in acountSam field in afterDelete
        Account accRec2 = [Select id,Account_SAM__c from account where id =: accList[1].id];
        System.assertEquals(null,accRec2.Account_SAM__c);
    }
}