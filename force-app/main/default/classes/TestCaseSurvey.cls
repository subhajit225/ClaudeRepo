@isTest
private class TestCaseSurvey {
   static testMethod void testTrigger() {
      //--INSERT
      Account a = new Account();
      a.Name = 'test34343434';
      insert a;
      Contact ct = new Contact();
      ct.Email = 'usmummaneni@gmail.com';
      ct.FirstName = 'hbn';
      ct.LastName = 'hi';
      ct.Account=a;
      insert ct;
      //ct = [SELECT Id,Email, Account.Id FROM Contact WHERE Email='usmummaneni@gmail.com'];


      Case caseTest = new Case();
      caseTest.Subject = 'testing one more';
      caseTest.ContactId = ct.Id;
      caseTest.Jira_Reference_urls__c = 'test';
      caseTest.Last_Case_Status__c = 'Customer requested close';
      caseTest.Priority ='P2';
      caseTest.Account=ct.Account;
      insert caseTest;
      Case caseTest2 = new Case();
      caseTest2.Subject = 'testing two more';
      caseTest2.Last_Case_Status__c = 'New';

      caseTest2.ContactId = ct.Id;
      caseTest2.Jira_Reference_urls__c = 'test';
      caseTest2.Priority='P2';
      caseTest2.AccountId=ct.Account.Id;
      insert caseTest2;

      CaseTest.Problem_Type__c = 'Other';
      CaseTest.Product_Area__c = 'Other';
      CaseTest.Resolution__c = 'Duplicate/Spam/Junk';
      CaseTest.Status = 'Closed';
      CaseTest.Resolution_Details__c = 'Test1';
      CaseTest.Type = 'Other';
      CaseTest.Other_Type__c = 'SS';
      //update caseTest;

      caseTest2.Problem_Type__c = 'Other';
      caseTest2.Product_Area__c = 'Other';
      caseTest2.Resolution__c = 'Hardware problem';
      caseTest2.Status = 'Closed';
      caseTest2.Resolution_Details__c = 'Test2';
      caseTest2.Type = 'Other';
      caseTest2.Other_Type__c = 'SS';
      caseTest2.If_Other__c = 'Other';
      update caseTest2;
      Contact ct2 = new Contact();
      ct2.Email = 'usmummaneni@gmail.com';
      ct2.FirstName = 'hbn';
      ct2.LastName = 'hi';
      datetime lnow = datetime.now();
      ct2.Last_GetFeedback_Date__c = lnow - 8;
      insert ct2;
      ct2 = [SELECT Id,Email FROM Contact WHERE Email='usmummaneni@gmail.com' limit 1];
      Case caseTest3 = new Case();
      caseTest3.Subject = 'testing two more';
      //caseTest3.ContactId = ct2.Id;
      caseTest3.Jira_Reference_urls__c = 'test';
      caseTest3.Priority='P2';
      caseTest3.Account=ct.Account;
      insert caseTest3;
      CaseTest3.Problem_Type__c = 'Other';
      CaseTest3.Product_Area__c = 'Other';
      CaseTest3.Resolution__c = 'No Problem Found';
      CaseTest3.Status = 'Closed';
      CaseTest3.Resolution_Details__c = 'Test2';
      caseTest3.Last_Case_Status__c = 'New';

      CaseTest3.Type = 'Other';
      CaseTest3.Other_Type__c = 'SS';
      //update caseTest3;


   }
}