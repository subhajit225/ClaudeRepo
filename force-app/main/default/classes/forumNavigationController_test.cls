/**
* @description
*   Test Class for forumNavigationController Apex Class.
* @test
* @author Grazitti Team
* @date   2025-08-01
*/

@IsTest
public class forumNavigationController_test {
    
    /**
* @description Test data setup having data required for the class.
*/
    @testSetup
    private static void setup() {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        
        User u = new User(
            ProfileId = profileId,
            LastName = 'TestUser',
            Email = 'csit-testuser@rubrik.com',
            Username = System.now().millisecond() + 'csit-testuser@rubrik.com',
            CompanyName = 'TEST',
            Title = 'Developer',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Employee_Time_Off__c = true
        );
        insert u;
    }
    
    /**
* @description Verifies gettopicDetail returns feed details along with assigned topic.
*/
    @isTest static void getTopicDetailTest() {
        FeedItem FI = new FeedItem(
            Title = 'Test Title',
            Body = 'This is a test body.',
            ParentId = UserInfo.getUserId(),
            Type = 'QuestionPost'
        );
        insert FI;
        
        Topic tpc = new Topic(Name = 'TestTopic', Description = 'Topic Description');
        insert tpc;
        
        TopicAssignment ta = new TopicAssignment(TopicId = tpc.Id, EntityId = FI.Id);
        insert ta;
        
        User testUser = [SELECT Id FROM User WHERE Email = 'csit-testuser@rubrik.com' LIMIT 1];
        
        System.runAs(testUser) {
            forumNavigationController.feedTopicsClass result = forumNavigationController.gettopicDetail(FI.Id);
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertEquals(FI.Id, result.feed.Id, 'Returned feed should match input FeedItem');
            System.assertEquals(tpc.Id, result.topicId, 'TopicId should match the assigned Topic');
        }
    }
    
    /**
* @description Verifies gettopicDetail works when a comment is passed instead of feed and feed has no best comment.
*/
    @isTest static void getTopicDetailWithFeedCommentTest() {
        FeedItem FI = new FeedItem(
            Title = 'Test Title',
            Body = 'This is a test body.',
            ParentId = UserInfo.getUserId(),
            Type = 'QuestionPost'
        );
        insert FI;
        
        FeedComment comment = new FeedComment(
            FeedItemId = FI.Id,
            CommentBody = 'Test Comment'
        );
        insert comment;
        
        User testUser = [SELECT Id FROM User WHERE Email = 'csit-testuser@rubrik.com' LIMIT 1];
        
        System.runAs(testUser) {
            forumNavigationController.feedTopicsClass result = forumNavigationController.gettopicDetail(comment.Id);
            System.assertNotEquals(null, result, 'Result should not be null when passing FeedComment ID');
            System.assertEquals(FI.Id, result.feed.Id, 'FeedItem should be linked correctly from FeedComment');
        }
    }
    
    /**
* @description Verifies saveData updates body formatting and assigns new topic to feed item.
*/
    @isTest static void saveDatatest() {
        FeedItem FI = new FeedItem(
            Title = 'SaveData Title',
            Body = '<h1>Header</h1><br>Some text with style="color:red;"',
            ParentId = UserInfo.getUserId(),
            Type = 'QuestionPost'
        );
        insert FI;
        
        Topic oldTopic = new Topic(Name = 'Old Topic');
        insert oldTopic;
        
        TopicAssignment oldAssignment = new TopicAssignment(TopicId = oldTopic.Id, EntityId = FI.Id);
        insert oldAssignment;
        
        Topic newTopic = new Topic(Name = 'New Topic');
        insert newTopic;
        
        User testUser = [SELECT Id FROM User WHERE Email = 'csit-testuser@rubrik.com' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            forumNavigationController.saveData(newTopic.Id, FI);
            Test.stopTest();
            
            FeedItem updatedFeed = [SELECT Id, Body FROM FeedItem WHERE Id = :FI.Id];
            System.assert(updatedFeed.Body.contains('<p>'), 'Header tags should be replaced with <p>');
            System.assert(!updatedFeed.Body.contains('style='), 'Style attributes should be removed');
            
            List<TopicAssignment> topicAssignments = [SELECT TopicId FROM TopicAssignment WHERE EntityId = :FI.Id];
            System.assertEquals(1, topicAssignments.size(), 'Only one topic assignment should remain');
            System.assertEquals(newTopic.Id, topicAssignments[0].TopicId, 'New topic should be assigned to FeedItem');
        }
    }
}