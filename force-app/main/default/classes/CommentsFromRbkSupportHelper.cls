public  without sharing  class CommentsFromRbkSupportHelper {
    
    public static void afterInsert(List<FeedComment>feedCommentList,Map<id,FeedComment>feedCommentMap){
        Map<Id,List<FeedComment>> feedItemIdVsListofComments = new   Map<Id,List<FeedComment>> ();
        Map<Id,Customer_Subscription__c> userIdAndCustomerSubscription = new   Map<Id,Customer_Subscription__c> (); 
        Set<Id>feedItemId= new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        Set<Id>threadParentId= new Set<Id>();
        Set<Id>recordOwnerId= new Set<Id>();
        List<Community_Feed__c> communityFeedRecords1= new List<Community_Feed__c>();
        List<Community_Feed__c> communityFeedRecords2= new List<Community_Feed__c>();
        
        for(FeedComment fc :feedCommentList){
            
            feedItemId.add(fc.FeedItemId);
            userIds.add(fc.CreatedById);
            if(fc.ThreadParentId!=null)
                threadParentId.add(fc.ThreadParentId);    
        }
        
        for(Customer_Subscription__c cs : [SELECT Id, KB_ID__c, User__c FROM Customer_Subscription__c WHERE KB_ID__c IN : feedItemId AND User__c IN : userIds]){
            userIdAndCustomerSubscription.put(cs.User__c,cs);
        }
        
        Map<id,Community_Feed__c> mapofFeedCommetIdVsCommunityFeed= new Map<id,Community_Feed__c>();
        for(Community_Feed__c cf1 :[SELECT Id, CreatedById, CreatedBy.Email, Title__c, FeedCommentId__c,
                                    FeedItemId__c, InsertedById__c, ParentId__c, CreatedBy.IsActive
                                    FROM Community_Feed__c 
                                    WHERE FeedCommentId__c IN :ThreadParentId]){  
            mapofFeedCommetIdVsCommunityFeed.put(cf1.FeedCommentId__c, cf1);
        }
        system.debug('mapofFeedCommetIdVsCommunityFeed@@'+mapofFeedCommetIdVsCommunityFeed);
        
        Map<Id,FeedItem> idVsFeedItemMap = new Map<Id,FeedItem>([Select Id,Title from FeedItem where Id IN:feedItemId]);
        
        for(FeedComment fc :feedCommentList){
            if(!userIdAndCustomerSubscription.containsKey(fc.CreatedById)){
                SubscribePostController.addBookMark('0DB1W00000001vMWAQ', fc.FeedItemId, true);
            }
            Community_Feed__c cf= new Community_Feed__c();
            cf.FeedItemId__c= fc.FeedItemId;
            cf.FeedCommentId__c=fc.Id;
            cf.Post_Title__c=idVsFeedItemMap.get(fc.FeedItemId).Title;
            cf.InsertedById__c=fc.CreatedById;
            cf.Title__c= fc.CommentBody;
            cf.ParentId__c=fc.ThreadParentId;
            if(mapofFeedCommetIdVsCommunityFeed.containsKey(fc.ThreadParentId)){
                cf.Community_Feed_Parent__c=mapofFeedCommetIdVsCommunityFeed.get(fc.ThreadParentId).Id;
                cf.Parentfeed__c=mapofFeedCommetIdVsCommunityFeed.get(fc.ThreadParentId).Id;
                cf.Parent_Comment_Title__c=mapofFeedCommetIdVsCommunityFeed.get(fc.ThreadParentId).Title__c;
                if(mapofFeedCommetIdVsCommunityFeed.get(fc.ThreadParentId).CreatedBy.IsActive)
                    cf.Comment_Owner_Email__c=mapofFeedCommetIdVsCommunityFeed.get(fc.ThreadParentId).CreatedBy.Email;
                
            }
            
            cf.ParentId__c=fc.ThreadParentId;
            threadParentId.add(fc.ThreadParentId);
            communityFeedRecords1.add(cf); 
        }            
        if(!communityFeedRecords1.isEmpty()){
            
            insert communityFeedRecords1;
            system.debug('communityFeedRecords'+communityFeedRecords1);
        }
        
    } 
    
    public static void beforeDelete(List<FeedComment> oldFeedCommentList){
        List<PermissionSetAssignment> psaList = [SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId =: userInfo.getUserId() AND (PermissionSet.Name = 'Moderate_Community_for_Customer_Community_Login_License_Users' OR PermissionSet.Name = 'Moderate_Community_for_Customer_Community_License_Users')];
        for(FeedComment fc : oldFeedCommentList){
            if((UserInfo.getUserId() == fc.CreatedById && fc.ThreadChildrenCount == 0) || !psaList.isEmpty()){
                
            }
            else{
                fc.addError('Only user with moderator abilities have permission to do this.');
            }
        }
    }
}