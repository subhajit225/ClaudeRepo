@isTest
public class forumMerticsLikeCountController_Test {
    public static testMethod void feedItemWithFeedLikes(){
        Account acc = new account();
        Contact con = new contact();
        acc.Name = 'Test Account';
        insert acc;
        con.lastName = 'Test con';
        con.accountId = acc.Id;
        insert con;
        Case cs = new Case(Priority = 'P1',AccountId = acc.Id,Subject = 'Test');
        insert cs;
        Id pfId = [select id,Name from profile where name = 'Rubrik Customer Community Super Login User'].Id;
        Test.startTest();
        User u = new User(
            ProfileId = pfId,
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'puser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ContactId = con.Id);
        insert u;
        
        system.runAs(u){
            Network n = [select id,Name from network limit 1];
            system.debug('n--->'+n);
            feedItem fe = new feedItem(ParentId = cs.Id,Body = 'TestBody');
            insert fe;
            feedlike fl = new feedlike(FeedItemId = fe.Id);
            insert fl;
            Topic t = new Topic(Name = 'TestTopic',networkId = n.Id);
            insert t;
            Topic t1 = [select id,Name from Topic where Id =: t.Id limit 1];
            List<TopicAssignment> taList = new List<TopicAssignment>();
            TopicAssignment newTopicAssignment = new TopicAssignment(TopicId=t1.Id,entityId = fe.Id,networkId = n.Id);
            //taList.add(newTopicAssignment);
            //TopicAssignment newTopicAssignment1 = new TopicAssignment(TopicId=t.Id,entityId = fe.Id,networkId = n.Id);
            //taList.add(newTopicAssignment1);
            insert newTopicAssignment;
        }
        forumMerticsLikeCountController fm = new forumMerticsLikeCountController();
        fm.getFeedItemForumLikes();
        Test.stopTest();
    }
    
    public static testMethod void feedItemWithoutFeedLikes(){
        Account acc = new account();
        Contact con = new contact();
        acc.Name = 'Test Account';
        insert acc;
        con.lastName = 'Test con';
        con.accountId = acc.Id;
        insert con;
        Case cs = new Case(Priority = 'P1',AccountId = acc.Id,Subject = 'Test');
        insert cs;
        Id pfId = [select id,Name from profile where name = 'Rubrik Customer Community Super Login User'].Id;
        Test.startTest();
        User u = new User(
            ProfileId = pfId,
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'puser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ContactId = con.Id);
        insert u;
        
        system.runAs(u){
            Network n = [select id,Name from network limit 1];
            system.debug('n--->'+n);
            feedItem fe = new feedItem(ParentId = cs.Id,Body = 'TestBody');
            insert fe;
            Topic t = new Topic(Name = 'TestTopic',networkId = n.Id);
            insert t;
            Topic t1 = [select id,Name from Topic where Id =: t.Id limit 1];
            List<TopicAssignment> taList = new List<TopicAssignment>();
            TopicAssignment newTopicAssignment = new TopicAssignment(TopicId=t1.Id,entityId = fe.Id,networkId = n.Id);
            //taList.add(newTopicAssignment);
            //TopicAssignment newTopicAssignment1 = new TopicAssignment(TopicId=t.Id,entityId = fe.Id,networkId = n.Id);
            //taList.add(newTopicAssignment1);
            insert newTopicAssignment;
        }
        forumMerticsLikeCountController fm = new forumMerticsLikeCountController();
        fm.getFeedItemForumLikes();
        Test.stopTest();
        
        fm.getprev();
        fm.getnxt();
        fm.getPageNumber();
        fm.getTotalPageNumber();
        fm.getPageSize();
        fm.getTotalsize();
        fm.Previous();
        fm.Next();
    }
}