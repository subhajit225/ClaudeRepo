@isTest()
public class CaseManagerAutoEmailResponseTestClass {
    public static TestMethod void CaseManagerAutoEmailResponseTestClass(){
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
/*        
        Case cs = New Case();
        cs.Subject = 'Automatic reply:';
        cs.Description = 'Test';
        cs.Type = 'Other';
        cs.Product_Area__c = 'Other';
        cs.Problem_Type__c = 'Other';
        cs.Status = 'New';
        cs.Priority = 'P1';
        cs.ContactId = ct.Id;
        cs.Origin = 'Email';
        cs.Cause__c = 'Test';
        cs.Software_Version__c = 'Polaris 1.0';
        cs.Solution__c = 'Test';
        cs.Additional_Notes__c = 'Test';
        insert cs;
*/        
        Case cs1 = New Case();
        cs1.Subject = 'Ref:_';
        cs1.Description = 'Test';
        cs1.Type = 'Other';
        cs1.Product_Area__c = 'Other';
        cs1.Problem_Type__c = 'Other';
        cs1.Status = 'New';
        cs1.Priority = 'P1';
        cs1.ContactId = ct.Id;
        cs1.Origin = 'Email';
        cs1.Cause__c = 'Test';
        cs1.Software_Version__c = 'Polaris 1.0';
        cs1.Solution__c = 'Test';
        cs1.Additional_Notes__c = 'Test';
        cs1.If_Other__c = 'Other';
        insert cs1;
    }	
}