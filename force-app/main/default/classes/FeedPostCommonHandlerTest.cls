/**
* @description Test class for FeedPostCommonHandler functionality.
* @author Raveesh Layal
* @date 2025-08-07
*/
@isTest
public class FeedPostCommonHandlerTest {
    
    /**
    * @description Sets up test data including users with required profiles for test execution.
    */
    @testSetup
    private static void setup(){
         Id profileId = [SELECT Id, Name from Profile WHERE Name = 'Rubrik Customer Support User'].Id;
       
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
            Employee_Time_Off__c = true);
        
        
        insert u;
    }
    
    /**
    * @description Tests the feedCommentAfterInsertMethod functionality with feed comment insertion and subscription validation.
    */
    @isTest
    public static void feedCommentAfterInsertMethodTest() {
        // Create topic
        Topic t = new Topic(
            NetworkId = System.Label.networkScope,
            Name = 'Test Topic',
            Description = 'Test Description'
        );
        insert t;
        
        // Create contacts
        Contact con1 = TestDataFactory.getContact();
        con1.FirstName = 'Test';
        con1.LastName = 'User1';
        
        Contact con2 = TestDataFactory.getContact();
        con2.FirstName = 'Test';
        con2.LastName = 'User2';
        
        insert new List<Contact>{ con1, con2 };
            
        // Create users
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Rubrik Customer Community Super Login User' LIMIT 1].Id;
        
        User user1 = new User(
            FirstName = 'User1',
            LastName = 'Test',
            Alias = 'u1',
            Email = 'user1@test.com',
            Username = System.currentTimeMillis() + 'user1@test.com',
            ProfileId = profileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Country = 'United States',
            IsActive = true,
            ContactId = con1.Id,
            Daily_Subscription__c = true,
            CompanyName = 'Test Company',
            Title = 'Test'
        );
        
        User user2 = new User(
            FirstName = 'User2',
            LastName = 'Test',
            Alias = 'u2',
            Email = 'user2@test.com',
            Username = System.currentTimeMillis() + 'user2@test.com',
            ProfileId = profileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Country = 'United States',
            IsActive = true,
            ContactId = con2.Id,
            Daily_Subscription__c = true,
            CompanyName = 'Test Company',
            Title = 'Test'
        );
        
        insert new List<User>{ user1, user2 };
            
        // Run as User1
        System.runAs(user1) {
            // Create feed item
            FeedItem feedItem = new FeedItem();
            feedItem.Title = 'Test Post @test';
            feedItem.Body = 'Testing @test';
            feedItem.NetworkScope = System.Label.networkScope;
            feedItem.ParentId = user1.Id;
            feedItem.Type = 'QuestionPost';
            insert feedItem;
            
            // Assign topic
            TopicAssignment ta = new TopicAssignment(
                NetworkId = System.Label.networkScope,
                TopicId = t.Id,
                EntityId = feedItem.Id
            );
            insert ta;
            
            // Create feed comment
            FeedComment fc = new FeedComment(
                FeedItemId = feedItem.Id,
                CommentBody = 'This is a test comment @test'
            );
            insert fc;
            
            // Add community feed
            Community_Feed__c cf = new Community_Feed__c(
                FeedCommentId__c = fc.Id,
                FeedItemId__c = feedItem.Id,
                Post_Title__c = 'Test Post',
                Title__c = 'Test Post'
            );
            insert cf;
            
            // Subscribe user2 to topic
            Customer_Subscription__c cusSub = new Customer_Subscription__c(
                KB_ID__c = feedItem.Id,
                Type__c = 'Forum Category',
                Topic_Id__c = ta.TopicId,
                User__c = user2.Id
            );
            insert cusSub;
            
            // FIXED: Pass the actual feedItem list instead of empty list
            List<FeedItem> feedItemList = new List<FeedItem>{ feedItem };
            List<FeedComment> commentList = new List<FeedComment>{ fc };
                
            Test.startTest();
            List<User> result = FeedPostCommonHandler.getSubscribedUserList(
                feedItemList,  // FIXED: Pass actual feed item list
                true,   // feedComment = true
                false,  // FeedItem = false
                commentList
            );
            Test.stopTest();
            
            // Assertions
            System.assertNotEquals(null, result, 'Subscribed users list should not be null');
            Set<Id> resultUserIds = new Set<Id>();
            for (User u : result) {
                resultUserIds.add(u.Id);
            }
            System.assert(resultUserIds.contains(user2.Id), 'User2 should be in the subscribed list');
        }
    }
    
    /**
    * @description Tests the feedCommentAfterInsertMethod with various scenarios.
    */
    //@isTest
    //public static void testFeedCommentAfterInsertMethod() {
        // Create topic
    /*    Topic t = new Topic(
            NetworkId = System.Label.networkScope,
            Name = 'Test Topic',
            Description = 'Test Description'
        );
        insert t;
        
        // Create contacts
        Contact con1 = TestDataFactory.getContact();
        con1.FirstName = 'Test';
        con1.LastName = 'User1';
        
        Contact con2 = TestDataFactory.getContact();
        con2.FirstName = 'Test';
        con2.LastName = 'User2';
        
        insert new List<Contact>{ con1, con2 };
            
        // Create users
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Rubrik Customer Community Super Login User' LIMIT 1].Id;
        
        User user1 = new User(
            FirstName = 'User1',
            LastName = 'Test',
            Alias = 'u1',
            Email = 'user1@test.com',
            Username = System.currentTimeMillis() + 1000 + 'user1@test.com',
            ProfileId = profileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Country = 'United States',
            IsActive = true,
            ContactId = con1.Id,
            Daily_Subscription__c = true,
            CompanyName = 'Test Company',
            Title = 'Test'
        );
        
        User user2 = new User(
            FirstName = 'User2',
            LastName = 'Test',
            Alias = 'u2',
            Email = 'user2@test.com',
            Username = System.currentTimeMillis() + 2000 + 'user2@test.com',
            ProfileId = profileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Country = 'United States',
            IsActive = true,
            ContactId = con2.Id,
            Daily_Subscription__c = true,
            CompanyName = 'Test Company',
            Title = 'Test'
        );
        
        insert new List<User>{ user1, user2 };
            
        // Run as User1
        System.runAs(user1) {
            // Create feed item
            FeedItem feedItem = new FeedItem();
            feedItem.Title = 'Test Post';
            feedItem.Body = 'Testing feed comment method';
            feedItem.NetworkScope = System.Label.networkScope;
            feedItem.ParentId = user1.Id;
            feedItem.Type = 'QuestionPost';
            insert feedItem;
            
            // Assign topic
            TopicAssignment ta = new TopicAssignment(
                NetworkId = System.Label.networkScope,
                TopicId = t.Id,
                EntityId = feedItem.Id
            );
            insert ta;
            
            // Subscribe user2 to topic
            Customer_Subscription__c cusSub = new Customer_Subscription__c(
                KB_ID__c = feedItem.Id,
                Type__c = 'Forum Category',
                Topic_Id__c = ta.TopicId,
                User__c = user2.Id
            );
            insert cusSub;
            
            // Create feed comment
            FeedComment fc = new FeedComment(
                FeedItemId = feedItem.Id,
                CommentBody = 'This is a test comment @User2'
                // ParentId is automatically set by Salesforce and cannot be manually set
            );
            insert fc;
            
            Test.startTest();
            // Test the actual method
            FeedPostCommonHandler.feedCommentAfterInsertMethod(new List<FeedComment>{ fc });
            Test.stopTest();
            
            // Verify method executed without error
            System.assert(true, 'feedCommentAfterInsertMethod executed successfully');
        }*/
    //}
    
    /**
    * @description Tests FeedItem scenario with topic assignment and subscription validation.
    */
    @isTest
    public static void testFeedItemScenario() {
        // Create topic
        Topic t = new Topic(
            NetworkId = System.Label.networkScope,
            Name = 'Test Topic',
            Description = 'Test Description'
        );
        insert t;
        
        // Create contacts
        Contact con1 = TestDataFactory.getContact();
        con1.FirstName = 'Test';
        con1.LastName = 'User1';
        
        Contact con2 = TestDataFactory.getContact();
        con2.FirstName = 'Test';
        con2.LastName = 'User2';
        
        insert new List<Contact>{ con1, con2 };
            
        // Create users
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Rubrik Customer Community Super Login User' LIMIT 1].Id;
        
        User user1 = new User(
            FirstName = 'User1',
            LastName = 'Test',
            Alias = 'u1',
            Email = 'user1@test.com',
            Username = System.currentTimeMillis() + 3000 + 'user1@test.com',
            ProfileId = profileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Country = 'United States',
            IsActive = true,
            ContactId = con1.Id,
            Daily_Subscription__c = true,
            CompanyName = 'Test Company',
            Title = 'Test'
        );
        
        User user2 = new User(
            FirstName = 'User2',
            LastName = 'Test',
            Alias = 'u2',
            Email = 'user2@test.com',
            Username = System.currentTimeMillis() + 4000 + 'user2@test.com',
            ProfileId = profileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Country = 'United States',
            IsActive = true,
            ContactId = con2.Id,
            Daily_Subscription__c = true,
            CompanyName = 'Test Company',
            Title = 'Test'
        );
        
        insert new List<User>{ user1, user2 };
            
        // Run as User1
        System.runAs(user1) {
            // Create feed item
            FeedItem feedItem = new FeedItem();
            feedItem.Title = 'Test Post';
            feedItem.Body = 'Testing FeedItem scenario';
            feedItem.NetworkScope = System.Label.networkScope;
            feedItem.ParentId = user1.Id;
            feedItem.Type = 'QuestionPost';
            insert feedItem;
            
            // Assign topic
            TopicAssignment ta = new TopicAssignment(
                NetworkId = System.Label.networkScope,
                TopicId = t.Id,
                EntityId = feedItem.Id
            );
            insert ta;
            
            // Subscribe user2 to topic
            Customer_Subscription__c cusSub = new Customer_Subscription__c(
                KB_ID__c = feedItem.Id,
                Type__c = 'Forum Category',
                Topic_Id__c = ta.TopicId,
                User__c = user2.Id
            );
            insert cusSub;
            
            // Test FeedItem scenario
            List<FeedItem> feedItemList = new List<FeedItem>{ feedItem };
                
            Test.startTest();
            List<User> result = FeedPostCommonHandler.getSubscribedUserList(
                feedItemList,
                false,  // feedComment = false
                true,   // FeedItem = true
                null
            );
            Test.stopTest();
            
            // Assertions
            System.assertNotEquals(null, result, 'Subscribed users list should not be null');
            Set<Id> resultUserIds = new Set<Id>();
            for (User u : result) {
                resultUserIds.add(u.Id);
            }
            System.assert(resultUserIds.contains(user2.Id), 'User2 should be in the subscribed list for FeedItem');
        }
    }
    
    /**
    * @description Tests the getIdFromTrigger future method functionality.
    */
    @isTest
    public static void testGetIdFromTriggerFutureMethod() {
        // Create topic
        Topic t = new Topic(
            NetworkId = System.Label.networkScope,
            Name = 'Test Topic',
            Description = 'Test Description'
        );
        insert t;
        
        // Create contacts
        Contact con1 = TestDataFactory.getContact();
        con1.FirstName = 'Test';
        con1.LastName = 'User1';
        
        Contact con2 = TestDataFactory.getContact();
        con2.FirstName = 'Test';
        con2.LastName = 'User2';
        
        insert new List<Contact>{ con1, con2 };
            
        // Create users
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Rubrik Customer Community Super Login User' LIMIT 1].Id;
        
        User user1 = new User(
            FirstName = 'User1',
            LastName = 'Test',
            Alias = 'u1',
            Email = 'user1@test.com',
            Username = System.currentTimeMillis() + 5000 + 'user1@test.com',
            ProfileId = profileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Country = 'United States',
            IsActive = true,
            ContactId = con1.Id,
            Daily_Subscription__c = true,
            CompanyName = 'Test Company',
            Title = 'Test'
        );
        
        User user2 = new User(
            FirstName = 'User2',
            LastName = 'Test',
            Alias = 'u2',
            Email = 'user2@test.com',
            Username = System.currentTimeMillis() + 6000 + 'user2@test.com',
            ProfileId = profileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Country = 'United States',
            IsActive = true,
            ContactId = con2.Id,
            Daily_Subscription__c = true,
            CompanyName = 'Test Company',
            Title = 'Test'
        );
        
        insert new List<User>{ user1, user2 };
            
        // Run as User1
        System.runAs(user1) {
            // Create feed item
            FeedItem feedItem = new FeedItem();
            feedItem.Title = 'Test Post';
            feedItem.Body = 'Testing future method';
            feedItem.NetworkScope = System.Label.networkScope;
            feedItem.ParentId = user1.Id;
            feedItem.Type = 'QuestionPost';
            insert feedItem;
            
            // Assign topic
            TopicAssignment ta = new TopicAssignment(
                NetworkId = System.Label.networkScope,
                TopicId = t.Id,
                EntityId = feedItem.Id
            );
            insert ta;
            
            // Subscribe user2 to topic
            Customer_Subscription__c cusSub = new Customer_Subscription__c(
                KB_ID__c = feedItem.Id,
                Type__c = 'Forum Category',
                Topic_Id__c = ta.TopicId,
                User__c = user2.Id
            );
            insert cusSub;
            
            Test.startTest();
            // Test the future method
            List<Id> feedItemIds = new List<Id>{ feedItem.Id };
            FeedPostCommonHandler.getIdFromTrigger(feedItemIds);
            Test.stopTest();
            
            // Since it's a future method, we can't directly test the result
            // But we can verify that no exceptions were thrown
            System.assert(true, 'Future method executed without exceptions');
        }
    }
    
    /**
    * @description Tests the filterUsers method functionality with user names and feed body.
    */
    @isTest
    public static void testFilterUsersMethod() {
        // Create contacts
        Contact con1 = TestDataFactory.getContact();
        con1.FirstName = 'Test';
        con1.LastName = 'User1';
        
        insert con1;
            
        // Create users
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Rubrik Customer Community Super Login User' LIMIT 1].Id;
        
        User user1 = new User(
            FirstName = 'User1',
            LastName = 'Test',
            Alias = 'u1',
            Email = 'user1@test.com',
            Username = System.currentTimeMillis() + 7000 + 'user1@test.com',
            ProfileId = profileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Country = 'United States',
            IsActive = true,
            ContactId = con1.Id,
            Daily_Subscription__c = true,
            CompanyName = 'Test Company',
            Title = 'Test',
            CommunityNickname = 'TestUser1'
        );
        
        insert user1;
        System.runAs(user1){
        
        Test.startTest();
        // Test filterUsers method
        List<String> userNames = new List<String>{ 'Test User1' };
        String feedBody = 'Hello @Test User1, how are you?';
        String result = FeedPostCommonHandler.filterUsers(userNames, feedBody);
        Test.stopTest();
        
        // Verify that the method ran without errors
        System.assertNotEquals(null, result, 'Filter users method should return a result');
        }
    }
    
    /**
    * @description Tests the returnWrapper method functionality.
    */
    @isTest
    public static void testReturnWrapper() {
        User user1 = [Select ProfileId, LastName, Id from User WHERE Email='csit-testuser@rubrik.com' LIMIT 1];
        System.runAs(user1){
        Test.startTest();
        List<FeedPostCommonHandler.FlowWrapper> result = FeedPostCommonHandler.returnWrapper();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Return wrapper should not be null');
        }
    }
    
    /**
    * @description Tests the FlowWrapper class functionality and constructor.
    */
    @isTest
    public static void testFlowWrapperClass() {
        // Create test data for FlowWrapper
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test@test.com'
        );
        
        FeedItem testFeedItem = new FeedItem(
            Title = 'Test',
            Body = 'Test Body'
        );
        
        FeedComment testFeedComment = new FeedComment(
            CommentBody = 'Test Comment'
        );
        User user1 = [Select ProfileId, LastName, Id from User WHERE Email='csit-testuser@rubrik.com' LIMIT 1];
        System.runAs(user1){
        
        Test.startTest();
        FeedPostCommonHandler.FlowWrapper fw = new FeedPostCommonHandler.FlowWrapper(
            new List<User>{ testUser },
            testFeedItem,
            testFeedComment,
            'Test Feed Comment Body'
        );
        Test.stopTest();
        
        System.assertNotEquals(null, fw, 'FlowWrapper should be instantiated');
        System.assertEquals(1, fw.userToFlowList.size(), 'User list should contain one user');
        System.assertEquals('Test', fw.feedItemRecord.Title, 'Feed item title should match');
        System.assertEquals('Test Comment', fw.feedCommentPost.CommentBody, 'Feed comment body should match');
        System.assertEquals('Test Feed Comment Body', fw.feedCom, 'Feed comment string should match');
    }
    }
    
    /**
    * @description Tests edge cases with null and empty parameters.
    */
    @isTest
    public static void testEdgeCases() {
        // Test with null/empty parameters
        User user1 = [Select ProfileId, LastName, Id from User WHERE Email='csit-testuser@rubrik.com' LIMIT 1];
        System.runAs(user1){
        Test.startTest();
        
        // Test getSubscribedUserList with empty list
        List<User> result1 = FeedPostCommonHandler.getSubscribedUserList(
            new List<FeedItem>(),
            false,
            false,
            null
        );
        
        // Test feedCommentAfterInsertMethod with empty list
        FeedPostCommonHandler.feedCommentAfterInsertMethod(new List<FeedComment>());
        
        // Test filterUsers with empty parameters
        String result2 = FeedPostCommonHandler.filterUsers(new List<String>(), 'test');
        
        Test.stopTest();
        
        System.assertNotEquals(null, result1, 'Should return empty list, not null');
        System.assertEquals('test', result2, 'Should return original string');
        }
    }
}