@isTest
public class CaseSubHistoryControllerTest {
    static testMethod void CaseSubHistoryTest(){
        
        CaseSubHistoryController cshc = new CaseSubHistoryController();
        cshc.getLastEmail();
        cshc.getAnyComment();
        cshc.getcaseDetail();
        cshc.getDescription();
        cshc.getE2CPHistory();
        cshc.getLastComment();
        cshc.getResolutionDetails();
        cshc.getResolutionText();
        
        Account testacc = new Account(name='Test Company Name');
        Contact testCon = new Contact(FirstName='First Name',LastName='Last name',title='TITLE',Phone='123456489',Email='test@test.com');
        insert testacc;
        insert testCon;
        Case ca = new Case(Subject='Test sub history contoller case',ContactId = testCon.id,    AccountId = testacc.id,Resolution_Details__c='<br>test case<div>', Priority ='P2');
        insert ca;
        CaseComment cm = new CaseComment(CommentBody='Test sub history contoller case comment',ParentId = ca.id);
        insert cm;
        cshc.cseID = ca.id;
        cshc.isPrivate = false;
        cshc.getLastEmail();
        cshc.getAnyComment();
        cshc.getcaseDetail();
        cshc.getDescription();
        cshc.getE2CPHistory();
        cshc.getLastComment();
        cshc.getResolutionDetails();
        cshc.getResolutionText();
        
        
    }
}