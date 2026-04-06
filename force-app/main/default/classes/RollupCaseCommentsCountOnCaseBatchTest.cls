@isTest(SeeAllData = false)
public class RollupCaseCommentsCountOnCaseBatchTest {
    
        
    @testSetup
    static void testSetUp() {
		insert new TriggerControl__c(Name='Case');
        
        Account account = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        account.Name = 'Test Account';
        insert account;
        
        List<Case> cases = new List<Case>();
        
        for (integer i=0 ; i< 10; i++) {
            Case newCase = (Case) ShGl_TestFactory.createSObject(new Case(), null);
            newCase.Subject = 'Test Case' + i;
            newCase.AccountId = account.Id;
            newCase.Priority = 'P4';
            cases.add(newCase);
        }
        
        insert cases;
        
        List<CaseComment> caseComments = new List<CaseComment>();
        
        for (integer i=0 ; i< 20; i++) {
            CaseComment newComment = new CaseComment();
            newComment.IsPublished = math.mod(i, 2) == 0 ? true : false;
            newComment.parentId = cases[0].Id;
            newComment.CommentBody = 'Test ' + i;
            caseComments.add(newComment);
        }
        
        insert caseComments;
    }
    
    @istest
    static void testRollupCaseCommentsCount() {
        test.startTest();
        String query = 'SELECT Id, CaseCommentsPublic__c, CaseCommentsPrivate__c, LastPublicCommentCreatedDate__c, LastPrivateCommentCreatedDate__c FROM Case';
        RollupCaseCommentsCountOnCaseBatch caseCommentSummary = new RollupCaseCommentsCountOnCaseBatch(query);
        Database.executeBatch(caseCommentSummary, 10);
        test.stopTest();
        
        List<Case> cases = [SELECT Id, CaseCommentsPublic__c,
                            CaseCommentsPrivate__c, LastPublicCommentCreatedDate__c, 
                            LastPrivateCommentCreatedDate__c FROM Case 
                            WHERE Subject = 'Test Case0' LIMIT 1];
        System.assertEquals(10, cases[0].CaseCommentsPublic__c);
        System.assertEquals(10, cases[0].CaseCommentsPrivate__c);
        
        List<CaseComment> caseComments = [SELECT Id, CreatedDate 
                                          FROM CaseComment 
                                          WHERE IsPublished = true
                                          ORDER BY CreatedDate 
                                          DESC LIMIT 1];
        
        system.assertEquals(cases[0].LastPublicCommentCreatedDate__c, caseComments[0].CreatedDate);
        
        caseComments = [SELECT Id, CreatedDate 
                        FROM CaseComment 
                        WHERE IsPublished = false
                        ORDER BY CreatedDate 
                        DESC LIMIT 1];
        
        system.assertEquals(cases[0].LastPrivateCommentCreatedDate__c, caseComments[0].CreatedDate);
        
    }

}