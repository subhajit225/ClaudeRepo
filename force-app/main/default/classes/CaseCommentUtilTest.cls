@isTest(seeAllData=false)
public class CaseCommentUtilTest {
    
    @TestSetup
    public static void dataSetup() {
        insert new TriggerControl__c(Name='Case');
        insert new TriggerControl__c(Name='Entitlement');
        
        Account account = new Account(name='testAcc');
        insert account;
        
        Contact contact = new Contact(lastName='testCont');
        contact.Notify_For_case_creation__c = true;
        contact.Email='testcontact@test.com';
        contact.AccountId = account.Id;
        insert Contact;
        
        Case newCase = new case();
        newCase.Accountid = account.id;
        newCase.contactid = contact.id;
        newCase.Subject ='JIRA12345';
        newCase.JIRA_References_URL__c='SPARK-123456, SPARK-78910';
        newCase.Jira_Reference_urls__c= 'SPARK-123456, SPARK-78910';
        newCase.Origin = 'Email';
        newCase.close_survey_triggered__c = false;
        newCase.Article_Created__c = false;
        newCase.Resolution_Details__c  = 'test';
        newCase.Next_Step__c = 'Test';
        newCase.Current_Status__c  = 'testStatus';
        newCase.Priority = 'P1';
        newCase.Alert_Key__c = 'Alert case 1 key';
        insert newCase;
    }
    
    private static testmethod void testCaseCommentTrigger(){
        Case cs = [SELECT Id, CaseCommentsPrivate__c, CaseCommentsPublic__c  FROM Case];
        
        CaseComment cm = new CaseComment(ParentId = cs.id, IsPublished = true, CommentBody = 'test comment');
        insert cm;
        
        cs = [SELECT Id, CaseCommentsPrivate__c, CaseCommentsPublic__c  FROM Case];
        System.assertEquals(cs.CaseCommentsPublic__c, 1);
        
        cm.IsPublished = false;
        update cm;
        
        cs = [SELECT Id, CaseCommentsPrivate__c, CaseCommentsPublic__c, LastPrivateCommentCreatedDate__c FROM Case];
        System.assertEquals(cs.CaseCommentsPublic__c, 0);
        System.assertEquals(cs.CaseCommentsPrivate__c, 1);
        List<CaseComment> caseComments = [SELECT CreatedDate FROM CaseComment LIMIT 1];
        System.assertEquals(cs.LastPrivateCommentCreatedDate__c, caseComments[0].CreatedDate);
        
        delete cm;
        
        cs = [SELECT Id, CaseCommentsPrivate__c, CaseCommentsPublic__c  FROM Case];
        System.assertEquals(cs.CaseCommentsPublic__c, 0);
        System.assertEquals(cs.CaseCommentsPrivate__c, 0);
    }
}