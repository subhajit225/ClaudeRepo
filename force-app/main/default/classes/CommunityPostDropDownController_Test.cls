@isTest
public class CommunityPostDropDownController_Test {
    @testSetup static void testData() {
        Topic t = new Topic(NetworkId = '0DB1W00000001vMWAQ', Name = 'test', Description = 'test');
        insert t;

        FeedItem feedItmobj= new FeedItem();
        feedItmobj.Title='Test Post';
        feedItmobj.Body='Testing';
        feedItmobj.NetworkScope=System.Label.networkScope;
        feedItmobj.ParentId=UserInfo.getUserId();
        
        insert feedItmobj;

        TopicAssignment ta = new TopicAssignment(NetworkId = '0DB1W00000001vMWAQ', TopicId = t.Id, EntityId = feedItmobj.Id);
        insert ta;
        
        Customer_Subscription__c cs= new Customer_Subscription__c();
        cs.Type__c='FeedItem';
        cs.KB_ID__c=feedItmobj.Id;
        cs.Title__c='Test';
        cs.Topic_Name__c='TestName1';
        cs.Topic_Id__c=t.Id;
        cs.User__c=UserInfo.getUserId();
        insert cs;
    }
    public static testMethod void testCommunityPostDropDown(){
        FeedItem fi = [SELECT Id from FeedItem LIMIT 1];
        CommunityPostDropDownController.feedItemOwnerId(fi.Id);
        FeedComment fc = CustomNotficationTestUtils.createFeedComment(fi.Id);
        CommunityPostDropDownController.feedItemOwnerId(fc.Id);
        CommunityPostDropDownController.flagPost(fi.Id);
        CommunityPostDropDownController.unflagPost(fi.Id);
        CommunityPostDropDownController.deletePost(fi.Id);
    }
}