@isTest()
public class CreateCaseArticleTestClass {
    public static TestMethod void CreateCaseArticleTestClass() {
       Test.startTest();
         Account acc = New Account();
        acc.Name = 'Acc1';
        acc.Heads_UpTo_Support_Team__c = 'abc';        
        insert acc;
        
        Contact ct = new Contact();
        ct.AccountId = acc.Id;
        ct.FirstName = 'Rajesh';
        ct.LastName = 'Gosetty';
        ct.Email = 'rajesh.gosetty@rubrik.com';
        insert ct;
        
        Case cs = New Case();
        cs.Subject = 'CASE-93282';
        cs.Description = 'Test';
        cs.Type = 'Other';
        cs.Product_Area__c = 'Other';
        cs.Problem_Type__c = 'Other';
        cs.Status = 'New';
        cs.Priority = 'P1';
        cs.ContactId = ct.Id;
        cs.Resolution_Details__c = 'Test';
        cs.Cause__c = 'Test';
        cs.Software_Version__c = 'Polaris 1.0';
        cs.Solution__c = 'Test';
        cs.Additional_Notes__c = 'Test';
        cs.Article_Created__c = False;
        cs.KCS_Article_Candidate__c = 'New Article Created';
        cs.KCS_Article_Status__c = 'Draft';
        cs.If_Other__c = 'Other';
        insert cs;
        
        How_To__kav kcs = new How_To__kav();
        kcs.Status__c = 'Draft';
        kcs.Case__c = cs.Id;
        kcs.Title = cs.Subject;
        kcs.UrlName = 'KCSURL';
        kcs.Solution_Detail__c  = cs.Solution__c;
        kcs.Additional_Note__c  = cs.Additional_Notes__c;
        Insert kcs;
        
        
        cs.Id = cs.Id;
        cs.KCS_Article_Candidate__c = 'New Article Created';
        cs.KCS_Article_Status__c = 'Draft';
        update cs;
		
        kcs.Status__c = 'Published';
        update kcs;
       Test.stopTest();
    }
}