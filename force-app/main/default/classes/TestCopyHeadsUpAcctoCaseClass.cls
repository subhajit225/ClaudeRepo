@isTest()
public class TestCopyHeadsUpAcctoCaseClass {
    Static TestMethod void TestCopyHeadsUpAcctoCaseClass()
    {
        Account a = new Account();
         a.Name = 'test34343434';
         a.Heads_Up_to_Support_Team__c = 'Hello';
         insert a;
        
         Contact ct = new Contact();
         ct.Email = 'usmummaneni@gmail.com';
         ct.FirstName = 'hbn';
         ct.LastName = 'hi';
         ct.Account=a;
         insert ct;
        
        Case caseTest = new Case();
        caseTest.Subject = 'testing one more';
        caseTest.ContactId = ct.Id;
        caseTest.Jira_Reference_urls__c = 'test';
        caseTest.Last_Case_Status__c = 'Customer requested close';
        caseTest.Priority ='P2';
        caseTest.Special_Handling_Instructions__c = a.Heads_Up_to_Support_Team__c;
        caseTest.Account=ct.Account;
        caseTest.AccountId = a.Id;
        insert caseTest;
        
        If(caseTest.AccountId != Null)
        {
            caseTest.Special_Handling_Instructions__c = a.Heads_Up_to_Support_Team__c;			 
        }		       
    }
}