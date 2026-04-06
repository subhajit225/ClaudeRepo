/**
* @description Test class for TopicCatelogController functionalities.
* @test
* @author Raveesh Layal
* @date 2025-08-01
*/
@isTest(seeAllData=true)
public class TopicCatelogControllerTest {
    
    /**
* @description Test method covering topic subscription and controller actions.
*/
    @isTest
    static void testFile() {
        
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Rubrik Customer Community Super Login User' LIMIT 1].Id;
        Account acct = new Account(Name = 'Test Account');
        insert acct;
        
        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            AccountId = acct.Id
        );
        insert contact;
        
        User u = new User(
            ProfileId = profileId,
            LastName = 'last',
            Email = 'csit-testuser@rubrik.com',
            Username = System.now().millisecond() + 'csit-testuser@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Employee_Time_Off__c = true,
            ContactId = contact.Id
        );
        insert u;
        // Topic tpc = new Topic(Name = 'TestTopic', Description = 'Topic Description');
        //insert tpc;
        // List<Topic> contentTopics = [SELECT Id FROM Topic WHERE Name = 'TestTopic' LIMIT 1];
        List<Topic> contentTopics = [SELECT Id FROM Topic WHERE ManagedTopicType = 'Content' LIMIT 1];
        NetworkMember membership = [SELECT NetworkID, MemberID FROM NetworkMember WHERE MemberID = :u.Id LIMIT 1];
        EntitySubscription es = new EntitySubscription(
            ParentId = contentTopics[0].Id,
            SubscriberId = UserInfo.getUserId(),
            NetworkID = membership.NetworkID
        );
        insert es;
        
        System.runAs(u){
            FeedItem feedItem = new FeedItem(
                Body = 'This is a test feed item',
                ParentId = UserInfo.getUserId(),
                NetworkScope = membership.NetworkID
            );
            insert feedItem;
            
            TopicAssignment topicAssignment = new TopicAssignment(
                EntityId = feedItem.Id,
                TopicId = contentTopics[0].Id,
                NetworkId = System.Label.networkScope
            );
            insert topicAssignment;
            
            List<Topic> newTopic = [SELECT Id, NetworkId, Name,
                                    (SELECT Id FROM TopicAssignments WHERE EntityType = 'FeedItem')
                                    FROM Topic
                                    WHERE Id IN (
                                        SELECT TopicId
                                        FROM TopicAssignment
                                        WHERE EntityType = 'FeedItem'
                                    )
                                    AND ManagedTopicType LIKE '%Content%'
                                    LIMIT 1];
            
            TopicCatelogController.getTopicsList(newTopic[0].NetworkId);
            TopicCatelogController.getActivityData();
            User currentUser = TopicCatelogController.getCurrentUserRecord();
            System.assertEquals(UserInfo.getUserId(), currentUser.Id);
            
            List<TopicCatelogController.topicClass> listofTopicClass= new List<TopicCatelogController.topicClass>();
            
            TopicCatelogController.topicClass wrapper= new TopicCatelogController.topicClass();
            wrapper.topic = newTopic[0];
            wrapper.comments = 1;
            wrapper.IsSubscribed = true;
            wrapper.imageName = 'Test';
            wrapper.likes = 5;
            wrapper.lastDateFormatted = String.valueOf(Date.today().addDays(-7));
            wrapper.lastDate = Date.today();
            listofTopicClass.add(wrapper);
            
            TopicCatelogController.topicClass wrapper1= new TopicCatelogController.topicClass();
            wrapper1.topic = newTopic[0];
            wrapper1.comments = 2;
            wrapper1.IsSubscribed = false;
            wrapper1.imageName = 'Test1';
            wrapper1.likes = 5;
            wrapper1.lastDate = Date.today();
            listofTopicClass.add(wrapper1);
            
            TopicCatelogController.saveSubscription(listofTopicClass, newTopic[0].NetworkId);
        }
    }
}