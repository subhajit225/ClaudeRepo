/**
 * Author           :   Saakshi Gupta
 * Created Date     :   25-01-2021
 * Description      :   Test class for CaseAuditFormController
 */
@isTest(seeAllData=false)
public class CaseAuditFormControllerTest {

    @testSetup
    public static void dataSetup() {
        insert new TriggerControl__c(Name='Case');
        insert new TriggerControl__c(Name='Entitlement');
        List<Case> caseList = new List<Case>();

        Account acc = new Account(name='testAcc');
        insert acc;

        Case cs = new case();
        cs.Accountid = acc.id;
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

        insert cs;
    }

    @isTest public static void testGetCaseAndCaseAuditRecord() {
        Case caseRecord = [SELECT Id FROM Case];

        CaseAuditFormController.getCaseAndCaseAuditRecord(caseRecord.Id);
    }
}