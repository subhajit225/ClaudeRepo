public without sharing class CommunityPostDropDownController {
    @AuraEnabled
    public static wrapper feedItemOwnerId(String postId){
        FeedComment fc;
        wrapper wrap;
        if(postId.startsWith('0D7')){
            fc = ([SELECT Id, FeedItemId,IsDeleted From FeedComment WHERE Id =: postId].size()>0)?[SELECT Id, FeedItemId,IsDeleted From FeedComment WHERE Id =: postId]:null;
            if(fc?.IsDeleted == true || fc == null){
                wrap = new wrapper(null,null,null,null,true);
                return wrap;
            }
            postId = fc.FeedItemId;
        }
        if(postId !=null || postId != ''){
            Id ownerId = [SELECT Id, CreatedById FROM FeedItem WHERE Id =: postId].CreatedById;
            List<FeedComment> feedCommList = [SELECT Id FROM FeedComment WHERE FeedItemId =: postId];
            List<PermissionSetAssignment> psaList = [SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId =: userInfo.getUserId() AND (PermissionSet.Name = 'Moderate_Community_for_Customer_Community_Login_License_Users' OR PermissionSet.Name = 'Moderate_Community_for_Customer_Community_License_Users')];
            ConnectApi.ModerationCapability flagged;
            if(!psaList.isEmpty()){
                flagged = ConnectApi.CommunityModeration.getFlagsOnFeedElement(system.label.networkScope, postId);
            }
            wrap = new wrapper(ownerId,feedCommList.isEmpty(),!psaList.isEmpty(),(flagged != null)?flagged.moderationFlags.flaggedByMe:null,false);
            return wrap;
        }
        wrap = new wrapper(null,null,null,null,true);
        return wrap;
    } 
    @AuraEnabled
    public static void deletePost(String postId){
        if(postId.startsWith('0D7')){
            FeedComment fc = [SELECT Id, FeedItemId From FeedComment WHERE Id =: postId];
            postId = fc.FeedItemId;
        }
        List<Customer_Subscription__c> csList = [SELECT Id,KB_ID__c from Customer_Subscription__c WHERE KB_ID__c =: postId];
        if(!csList.isEmpty())
            DELETE csList;
        List<Community_Feed__c> cfList = [SELECT Id,FeedItemId__c FROM Community_Feed__c WHERE FeedItemId__c =: postId];
        if(!cfList.isEmpty())
            DELETE cfList;
        List<FeedComment> fcList = [SELECT Id,FeedItemId FROM FeedComment WHERE FeedItemId =: postId]; 
        if(!fcList.isEmpty())
            DELETE fcList;
        FeedItem fi = [SELECT Id FROM FeedItem WHERE Id =: postId];
        DELETE fi;
    }
    
    @AuraEnabled
    public static void flagPost(String feedItemId){
        if(!test.isRunningTest())
            ConnectApi.ModerationCapability flag = ConnectApi.CommunityModeration.addFlagToFeedElement(system.label.networkScope, feedItemId);
    }
    
    @AuraEnabled
    public static void unflagPost(String feedItemId){
        if(!test.isRunningTest())
            ConnectApi.CommunityModeration.removeFlagFromFeedElement(system.label.networkScope, feedItemId, userInfo.getUserId());
    }
    
    public class wrapper {
        @AuraEnabled public Id ownerId;
        @AuraEnabled public Boolean containComments;
        @AuraEnabled public Boolean isModerator;
        @AuraEnabled public Boolean flagged;
        @AuraEnabled public Boolean isDeleted;
        public wrapper(Id ownerId, Boolean containComments, Boolean isModerator,Boolean flagged,Boolean isDeleted){
            this.ownerId = ownerId;
            this.containComments = containComments;
            this.isModerator = isModerator;
            this.flagged = flagged;
            this.isDeleted = isDeleted;
        }
    }
}