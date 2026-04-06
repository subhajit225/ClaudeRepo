@isTest
public class CaseTriageFormControllerTest {

    public static case cs;
    
    @testSetup 
    public static void setup() {
        insert new TriggerControl__c(Name='Case'); 
        List<Case> caseList = new List<Case>();
        for(integer j=0 ; j< 10 ;j++){
            caseList.add(new Case(Status = 'New',Priority='P1 - Critical',Subject ='test1234'));
        }
        insert caseList;
        
        
        Account acc = new Account(name='testAcc');
        insert acc;
        
        Contact cont = new Contact(lastName='testCont');
        //cont.Notify_For_case_creation__c = true;
        cont.Email='jira@rubrik.atlassian.net';
        insert cont;
        
        AccountTeamMember acctm = new AccountTeamMember();
        acctm.AccountId = acc.id;
        //acctm.UserId= '005e0000005eAzyAAE';
        //acctm.TeamMemberRole = 'Sales Engineer Manager';
        //insert acctm;
       
        cs = TestDataFactory.getCase(acc, cont);
        cs.Subject ='JIRA12345';
        cs.JIRA_References_URL__c='SPARK-123456, SPARK-78910';
        cs.Jira_Reference_urls__c= 'SPARK-123456, SPARK-78910';
        cs.Origin = 'Alert';
        cs.close_survey_triggered__c = false; 
        cs.Resolution__c = 'No Response';
        cs.Article_Created__c = false;
        cs.Resolution_Details__c  = 'test';
        cs.Next_Step__c = 'Test';
        cs.Current_Status__c  = 'testStatus';
        insert cs;
    }
    
    @isTest static void testCaseTriage(){
        Test.startTest();
          cs = [Select id from Case limit 1];
            ApexPages.StandardController stdCaseController = new ApexPages.StandardController(cs);
            CaseTriageFormController caseFormTriageController = new CaseTriageFormController(stdCaseController);
            PageReference pageRef = Page.CaseTriageForm;
            Test.setCurrentPage(pageRef);
            caseFormTriageController.updateTriageStatus();
            caseFormTriageController.saveForm();
        Test.stopTest();
    }
}