@isTest
public class SubscribedTopicControllerTest {
  
   @testSetup   static void testdata() {
        
        Network rubrikSupport=[Select id,Name from Network where Name ='Rubrik Support' limit 1];
        Topic testTopic = new Topic();
        testTopic.Name='TestTopicSubscribedTopicControllerTest';
        testTopic.NetworkId=rubrikSupport.id;
        testTopic.Description='TestData';
        insert  testTopic;
        
        FeedItem testfeed = new FeedItem();
        testfeed.Body = 'testfeed';
        testfeed.Title='TestDataFeed';
        testfeed.Type = 'QuestionPost';
        testfeed.NetworkScope=rubrikSupport.Id;
        testfeed.parentID = UserInfo.getUserId();
        insert testfeed;
        
        TopicAssignment testAss= new TopicAssignment();
        testAss.EntityId=testfeed.Id;
        testAss.NetworkId=rubrikSupport.Id;  
        testAss.TopicId=testTopic.Id;
         
        
        insert testAss; 
        
        EntitySubscription testEntitySub = new EntitySubscription();
        testEntitySub.NetworkId=rubrikSupport.id;
        testEntitySub.SubscriberId= UserInfo.getUserId();
        testEntitySub.ParentId=testTopic.Id;
        insert testEntitySub;
        
       
        
        FeedComment testComm= new FeedComment();
        testComm.CommentBody='TestCommnet';
        testComm.FeedItemId=testfeed.Id;
        
        insert testComm;
        
         //updateUser();
        
    }
    
    /*@future
    public static void updateUser(){
        User u = new User(id=UserInfo.getUserId(),Allow_weekly_notification__c=true);
        Update u;
    }*/
    
    static testMethod void fetchCustomerSusbcriptions() {
        
       
       Test.startTest();
        SubscribedTopicController stc = new SubscribedTopicController();
        stc.currentUserId=UserInfo.getUserId();
        Map<String,List<SubscribedTopicController.wrapperclass>> mapofTopicVsPost =stc.getsubscribedTopicVsSusbscribedPosts();
        system.debug('mapofTopicVsPost'+mapofTopicVsPost);
        System.assertEquals(1,mapofTopicVsPost.size());  
        
        Test.stopTest(); 
    }

}