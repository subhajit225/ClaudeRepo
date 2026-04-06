/********************************************************************************************************
* Name              : CommunityCommentExtension_Test
* Purpose           : CommunityCommentExtension_Test is Used for Testing CommunityCommentExtension Class
*********************************************************************************************************/
@isTest
public class CommunityCommentExtension_Test{

    static testMethod void testSaveComment() {
        Case c = new Case();
        c.Priority='P2';
        c.Origin = 'Email';
        c.Subject = 'Test';
        insert c;  

        Apexpages.StandardController sc = new Apexpages.standardController(c);
        CommunityCommentExtension sset  = new CommunityCommentExtension(sc);
        Test.startTest();
        sset.saveComment();
        Test.stopTest();
    }
    
    static testMethod void testEscalate() {
        Case c = new Case();
        c.Priority='P2';
        c.Origin = 'Email';
        c.Subject = 'Test';
        insert c;  

        Apexpages.StandardController sc = new Apexpages.standardController(c);
        CommunityCommentExtension sset  = new CommunityCommentExtension(sc);
        Test.startTest();
        sset.escalate();
        Test.stopTest();
    }
    
    static testMethod void testReopen() {
        Case c = new Case();
        c.Priority='P2';
        c.Origin = 'Email';
        c.Subject = 'Test';
        insert c;  

        Apexpages.StandardController sc = new Apexpages.standardController(c);
        CommunityCommentExtension sset  = new CommunityCommentExtension(sc);
        Test.startTest();
        sset.reopen();
        Test.stopTest();
    }
    
    static testMethod void testCancel() {
        Case c = new Case();
        c.Priority='P2';
        c.Origin = 'Email';
        c.Subject = 'Test';
        insert c;  

        Apexpages.StandardController sc = new Apexpages.standardController(c);
        CommunityCommentExtension sset  = new CommunityCommentExtension(sc);
        Test.startTest();
        sset.cancel();
        Test.stopTest();
    }
    
    static testMethod void testGetComments() {
        Case c = new Case();
        c.Priority='P2';
        c.Origin = 'Email';
        c.Subject = 'Test';
        insert c;  

        Apexpages.StandardController sc = new Apexpages.standardController(c);
        CommunityCommentExtension sset  = new CommunityCommentExtension(sc);
        Test.startTest();
        sset.getComments();
        Test.stopTest();
    }
}