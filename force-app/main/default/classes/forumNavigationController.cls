public without sharing class forumNavigationController{
    
    @AuraEnabled
    public static feedTopicsClass gettopicDetail(String recordId){
        List<topic> topicList = new List<topic>();
        List<FeedItem> feedsList = new List<FeedItem>();
        if(recordId.startsWith('0D7'))
            recordId = [SELECT Id,feedItemId from feedcomment where Id=:recordId ]?.feedItemId;
        feedsList = [SELECT Id, ParentId,(select id,createdbyId from feedcomments) Type, CreatedBy.Name, CreatedById, CreatedDate, LastModifiedDate, Revision, LastEditDate, CommentCount, LikeCount, Title, Body, Visibility,bestcommentId FROM FeedItem where Type = 'QuestionPost' AND ID =: recordId];
        List<TopicAssignment> topicassignmentList = [SELECT EntityId,TopicId,Topic.Name FROM TopicAssignment WHERE EntityId =: recordId LIMIT 1];
        if(System.Label.ReassignProfiles.contains(UserInfo.getProfileId()))
            topicList = [SELECT Id, NetworkId, Name, Description, ManagedTopicType FROM Topic WHERE ManagedTopicType LIKE '%Content%'];
        system.debug('topicList@@@@'+topicList);
        if(!feedsList.isEmpty()){ 
            List<ChatterActivity> userData = new List<ChatterActivity>();
            userData = [SELECT Id, NetworkId, ParentId, PostCount, CommentCount, CommentReceivedCount, LikeReceivedCount, InfluenceRawRank FROM ChatterActivity where ParentId=:feedsList[0].createdById];
            set<Id> commentIds = new set<Id>();
            ChatterActivity each = new chatterActivity();
            if(userData!=null && !userData.isEmpty())
                each = userData[0];
            
            
            if(feedsList[0].bestCommentId!=null){
                if(feedsList[0].createdById == ConnectApi.ChatterFeeds.getComment(System.Label.networkScope,feedsList[0].bestCommentId).user.id){
                    commentIds.add(feedsList[0].bestCommentId);    
                }
            }
            
            
            
            /*if(feedsList.feedcomments!=null && !feedsList.feedcomments.isEmpty()){
for(feedComment each1 : feedsList.feedcomments){
if(each1.createdById == feedsList.createdById){

}
}
}*/
            
            List<FeedItem> bestComment = [SELECT Id,bestcommentid FROM feeditem WHERE bestcommentId IN :commentIds];
            
            if(topicassignmentList != null && !topicassignmentList.isEmpty())
                return new feedTopicsClass(feedsList[0],topicassignmentList[0].TopicId,topicassignmentList[0].Topic.Name,topicList,each,bestComment.size(),false);
            else{
                return new feedTopicsClass(feedsList[0],'','',topicList,each,bestComment.size(),false);
            }
        }
        system.debug('Sending Empty');
        return  new  feedTopicsClass(null,null,null,null,null,null,true);
    }
    
    @AuraEnabled
    public static void saveData(string topicId,FeedItem feed){
        system.debug('@@@@@@'+feed.body);
        feed.Body = feed.Body.replaceAll('<h1>', '<p>').replaceAll('<h2>', '<p>').replaceAll('<h3>', '<p>').replaceAll('<h4>', '<p>').replaceAll('<h5>', '<p>').replaceAll('<h6>', '<p>');
        feed.Body = feed.Body.replaceAll('</h1>', '</p>').replaceAll('</h2>', '</p>').replaceAll('</h3>', '</p>').replaceAll('</h4>', '</p>').replaceAll('</h5>', '</p>').replaceAll('</h6>', '</p>');
        feed.Body = feed.Body.replaceAll('<br>', ' ');
        feed.Body = feed.Body.replaceAll('style=.*;"', '');
        feed.Body = feed.Body.replaceAll('target=.*"', '');
        system.debug('@@@@@@'+feed.body);
        feed.isRichText = true;
        update feed;
        TopicAssignment ts = [SELECT EntityId,TopicId,Topic.Name FROM TopicAssignment WHERE EntityId =: feed.Id LIMIT 1];
        if(ts.TopicId != topicId){
            delete ts;
        }
        insert new TopicAssignment(TopicId = topicId ,EntityId = feed.id );
        
    }
    
    public class topicWrapper{
        
        @AuraEnabled public TopicAssignment tp;
        @AuraEnabled public boolean adminUser;
        
    }
    public class feedTopicsClass{
        @AuraEnabled public FeedItem feed{get;set;}
        @AuraEnabled public ChatterActivity userData{get;set;}
        @AuraEnabled public String topicId{get;set;}
        @AuraEnabled public String topicName{get;set;}
        @AuraEnabled public List<topic> topicList{get;set;}
        @AuraEnabled public Integer bestComment{get;set;}
        @AuraEnabled public Boolean isDeleted;
        public feedTopicsClass(){
            
        }
        public feedTopicsClass(FeedItem feed,String topicId ,String topicName,List<topic> topicList,ChatterActivity userData,Integer bestComment,Boolean isDeleted){
            this.feed = feed;
            this.topicId = topicId;
            this.topicName = topicName;
            this.topicList = topicList;
            this.userData = userData;
            this.bestComment = bestComment;
            this.isDeleted = isDeleted;
        }
    }
}