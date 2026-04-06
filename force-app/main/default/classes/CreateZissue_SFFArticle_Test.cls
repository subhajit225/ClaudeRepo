@isTest
public class CreateZissue_SFFArticle_Test {
    @isTest static void TestList()
    {
            
            Account a = new Account(Name = 'Test Account');
            insert a;
            
        	zsfjira__ZIssue__c zissue1 = new zsfjira__ZIssue__c();
        	zissue1.zsfjira__IssueKey__c = 'sdr-234';
        	zissue1.zsfjira__IssueId__c = 234567;
        	INSERT zissue1;
        	
        	zsfjira__ZIssue__c zissue2 = new zsfjira__ZIssue__c();
        	zissue2.zsfjira__IssueKey__c = 'bhuj-234';
        	zissue2.zsfjira__IssueId__c = 234564;
        	INSERT zissue2;
                
                
            How_To__kav k = new How_To__kav();
            k.Title = 'APEX TEST';
            k.UrlName = 'APEX-TEST';
            k.Language = 'en_US';
        	k.JIRA_Reference__c = 'Testing sdr-234 bhuj-234';
            insert k;
            k = [SELECT Id, KnowledgeArticleId, JIRA_Reference__c FROM How_To__kav WHERE Id = :k.Id];    
            KbManagement.PublishingService.publishArticle(k.KnowledgeArticleId, true);
            
            Case c = new Case();
            c.Origin = 'Web';
            c.Status = 'Working';
            c.AccountId = a.Id;
        	c.Priority = 'P1 - Critical service impact';
            insert c;
            
            CaseArticle ca = new CaseArticle();
            ca.CaseId = c.Id;
            ca.KnowledgeArticleId = k.KnowledgeArticleId;
            insert ca;            
            
            
            CreateZissue_SFFArticle_CaseScheduler createZissue = new CreateZissue_SFFArticle_CaseScheduler();
            Test.startTest();
            System.enqueueJob(createZissue);
            CreateZissue_Scheduler scs=new CreateZissue_Scheduler();
            String sch = '0 0 23 * * ?'; 
            system.schedule('TestCreateZissue_Scheduler', sch, scs);     
            Test.stopTest();
        
    }
}