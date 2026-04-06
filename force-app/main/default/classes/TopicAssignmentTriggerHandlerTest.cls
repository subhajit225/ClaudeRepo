@isTest
public class TopicAssignmentTriggerHandlerTest {
    public static testMethod void topicassignmentTest(){
        Topic t = new Topic(NetworkId = system.label.networkScope, Name = 'test', Description = 'test');
        insert t;

        FeedItem feedItmobj= new FeedItem();
        feedItmobj.Title='Test Post';
        feedItmobj.Body='Testing';
        feedItmobj.NetworkScope=System.Label.networkScope;
        feedItmobj.ParentId=UserInfo.getUserId();
        feedItmobj.Type = 'QuestionPost';
        
        insert feedItmobj;
      
        TopicAssignment ta = new TopicAssignment(NetworkId = system.label.networkScope, TopicId = t.Id, EntityId = feedItmobj.Id);
        test.startTest();
        insert ta;
        test.stopTest();
    }
}