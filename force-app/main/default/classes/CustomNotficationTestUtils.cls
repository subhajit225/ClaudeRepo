public class CustomNotficationTestUtils {
    
    public static  Id  createFeedItem(){
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
        
        return feedItmobj.Id;
    }
    
     public static  Customer_Subscription__c  createCustomerSubscriptions(Id feedItemId){
        
        Customer_Subscription__c cusSub = new Customer_Subscription__c();
        cusSub.KB_ID__c=feedItemId;
        cusSub.Type__c='FeedItem';
        
        
        insert cusSub;
        
        return cusSub;
    }
     public static  Community_Feed__c  createCommunityFeed(){
        
        Community_Feed__c commFeed = new Community_Feed__c();
        //commFeed.FeedItemId__c=feedItemId;
        commFeed.FeedCommentId__c='FeedItem';
        commFeed.Post_Title__c='Test';
         
        commFeed.Comment_Owner_Email__c='test@gmail.com';
        
        insert commFeed;
        
        return commFeed;
    }
    
    public static  Community_Feed__c  createCommunityFeedParent(Id communityFeedId){
        
        Community_Feed__c commFeed = new Community_Feed__c();
       // commFeed.FeedItemId__c=feedItemId;
        commFeed.FeedCommentId__c='FeedItem';
        commFeed.Post_Title__c='Test';
        commFeed.Comment_Owner_Email__c='test1@gmail.com';
        commFeed.Community_Feed_Parent__c=communityFeedId;
        commFeed.Parentfeed__c=communityFeedId;
        insert commFeed;
        
        return commFeed;
    }
    public static  FeedComment  createFeedComment(Id feedItemId){
        
        FeedComment feedComment= new feedComment();
        feedComment.CommentBody='Direct comment 001 by search';
        feedComment.FeedItemId=feedItemId;
        insert feedComment;
        
        return feedComment;
    }

}