@isTest
public class topicController_Test {
    public static testMethod void topicController_Test(){
        
        Topic tpc = new Topic();
        tpc.Name = 'Topic Test';
        insert tpc;
        
        FeedItem FD = new FeedItem();
        FD.ParentId = userinfo.getuserid();
        FD.Body = 'Test';
        FD.Title = 'Test';
        Insert FD;
        
        TopicAssignment TA = new TopicAssignment();
        TA.TopicId = tpc.Id;
        TA.EntityId = FD.Id;
        insert TA;
        
        topicController.getfeeds(tpc.Id);
        
    }
}