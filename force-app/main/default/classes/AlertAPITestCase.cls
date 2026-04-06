@isTest()
public class AlertAPITestCase {
	public static TestMethod void AlertAPITestCase()
    {
        Case cs1 = new Case();
        cs1.Subject = '[JIRA] (ALERT-71648) - Test JIRA case alert - To check for the error message1';
        cs1.Description = '[JIRA] (ALERT-71648) - Test JIRA case alert - To check for the error message1';
        cs1.Status = 'New';
        cs1.Priority = 'P1';
        cs1.Origin = 'Alert';
        cs1.Type = 'Software';
        cs1.Problem_Type__c = 'Node down';
        cs1.Product_Area__c = 'Fault';
        insert cs1;
    }
}