@isTest
public class CustomNotificationTestUtils_Test {
    public static testMethod void testCustomNotifications(){
        Id feedItemId = CustomNotficationTestUtils.createFeedItem();
        CustomNotficationTestUtils.createCustomerSubscriptions(feedItemId);
        Community_Feed__c communityFeedId = CustomNotficationTestUtils.createCommunityFeed();
        CustomNotficationTestUtils.createCommunityFeedParent(communityFeedId.Id);
        CustomNotficationTestUtils.createFeedComment(feedItemId);
    }
}