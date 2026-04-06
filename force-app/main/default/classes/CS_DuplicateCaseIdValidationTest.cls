/**
* @Author       :   Saakshi Gupta
* @CreatedDate  :   14-02-2020
* @Jira Ticket  :   CS-474 - Allow only one alert key per case
* @Description  :   Test class for CS_DuplicateCaseIdValidationController.cls
*/
@isTest(seeAllData=false)
public class CS_DuplicateCaseIdValidationTest {

    @testSetup 
    public static void dataSetup() {
        insert new TriggerControl__c(Name='Case'); 
        insert new TriggerControl__c(Name='Entitlement'); 
        List<Case> caseList = new List<Case>();
        
        Account acc = new Account(name='testAcc');
        insert acc;
        
        Contact cont = new Contact(lastName='testCont');
        cont.Notify_For_case_creation__c = true;
        cont.Email='jira@rubrik.atlassian.net';
        cont.AccountId=acc.Id;
        insert cont;
        
        Case cs = new case();
        cs.Accountid = acc.id;
        cs.contactid = cont.id;
        cs.Subject ='JIRA12345';
        cs.JIRA_References_URL__c='SPARK-123456, SPARK-78910';
        cs.Jira_Reference_urls__c= 'SPARK-123456, SPARK-78910';
        cs.Origin = 'Alert';
        cs.close_survey_triggered__c = false; 
        cs.Article_Created__c = false;
        cs.Resolution_Details__c  = 'test';
        cs.Next_Step__c = 'Test';
        cs.Current_Status__c  = 'testStatus';
        cs.Priority = 'P1';
        cs.Alert_Key__c = 'Alert case 1 key';
        caseList.add(cs);

        cs = new case();
        cs.Accountid = acc.id;
        cs.contactid = cont.id;
        cs.Subject ='JIRA12346';
        cs.JIRA_References_URL__c='SPARK-123457, SPARK-78911';
        cs.Jira_Reference_urls__c= 'SPARK-123457, SPARK-78911';
        cs.Origin = 'Alert';
        cs.close_survey_triggered__c = false;
        cs.Article_Created__c = false;
        cs.Resolution_Details__c  = 'test';
        cs.Next_Step__c = 'Test';
        cs.Current_Status__c  = 'testStatus';
        cs.Priority = 'P1';
        cs.Alert_Key__c = 'Alert case 2 key';
        caseList.add(cs);
        
        Case cs1 = new case();
        cs1.Subject='Test case dup';
        cs1.JIRA_References_URL__c='ALERT-11112abc';
        cs1.Jira_Reference_urls__c= 'ALERT-11112abc';
        cs1.Description='testing';
        cs1.Origin = 'Portal';
        cs1.Status ='In Progress';
        cs1.Accountid = acc.id;
        cs1.contactid = cont.id;  
        cs1.Resolution__c='Product defect';
        cs1.Priority = 'P1';
        cs1.Alert_Key__c = 'Parent case key';
        caseList.add(cs1);

        insert caseList;
    }

    /**
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   14-02-2020
    */
    @isTest static void testValidateDuplicateCaseId() {
        Case caseRecord = [Select Id, Duplicate_Case_Id__c from Case where Subject like '%JIRA12345%'];

        Case caseRecord2 = [Select Id, Duplicate_Case_Id__c from Case where Subject like '%JIRA12346%'];

        Case duplicateCase = [Select Id from Case where Subject like '%Test case dup%'];

        ApexPages.StandardController sc = new ApexPages.StandardController(caseRecord);
        CS_DuplicateCaseIdValidationController controllerObject = new CS_DuplicateCaseIdValidationController(sc);
        
        PageReference pageRef = Page.CS_DuplicateCaseIdValidation;
        Test.setCurrentPage(pageRef);

        Test.startTest();

        controllerObject.changeToEditMode();

        caseRecord.Duplicate_Case_Id__c = duplicateCase.Id;
        controllerObject.validateDuplicateCaseId();
        
        controllerObject.updateCase();

        controllerObject.Cancel();
        
        ApexPages.StandardController sc2 = new ApexPages.StandardController(caseRecord2);
        CS_DuplicateCaseIdValidationController controllerObject2 = new CS_DuplicateCaseIdValidationController(sc2);
        
        PageReference pageRef2 = Page.CS_DuplicateCaseIdValidation;
        Test.setCurrentPage(pageRef2);
        
        caseRecord2.Duplicate_Case_Id__c = duplicateCase.Id;
        controllerObject2.validateDuplicateCaseId();
        
        caseRecord2.Duplicate_Case_Id__c = null;
        controllerObject2.validateDuplicateCaseId();

        Test.stopTest();
    }
}