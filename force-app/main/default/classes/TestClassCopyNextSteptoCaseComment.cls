@isTest()
public class TestClassCopyNextSteptoCaseComment {
	Public static TestMethod Void TestClassCopyNextSteptoCaseComment()
    {   
     	Account a = new Account();
        a.Name = 'test34343434';
        insert a;
        
		Contact ct = new Contact();
        ct.Email = 'usmummaneni@gmail.com';
        ct.FirstName = 'hbn';
        ct.LastName = 'hi';
        ct.Account=a;
        insert ct;
        
       	Case caseTest = new Case();
        Case caseTest1 = new Case();
        
        caseTest.Subject = 'testing one more';
     	caseTest.Description = 'Helo';
        caseTest.ContactId = ct.Id;
        caseTest.Priority ='P2';
        caseTest.AccountId = a.Id;
        caseTest.Status = 'New';
        caseTest.Next_Step__c = 'Next Step';
        caseTest.Current_Status__c = 'Current Status';
        insert caseTest;   
        
        caseTest.Id = caseTest.Id;
        caseTest.Next_Step__c = 'Next Step1';
        caseTest.Current_Status__c = 'Current Status1';
        update caseTest; 
        
        caseTest.Id = caseTest.Id;
        caseTest.Next_Step__c = 'Next Step2';
        caseTest.Current_Status__c = 'Current Status2';
        update caseTest;
    }    
}