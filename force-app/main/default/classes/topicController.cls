public without sharing class topicController{

    @AuraEnabled
    public static List<wrapperList> getfeeds(String topicId){
        List<wrapperList> listWrapper = new List<wrapperList>();
        set<Id> userIds = new Set<Id>();
        List<FeedItem> feedList = [SELECT Id,Title,createdById,CreatedDate, CommentCount, LikeCount FROM FeedItem WHERE ID IN (SELECT EntityId FROM TopicAssignment where topicId =:topicId) and commentcount = 0 and title!=null order by createddate limit 10];
        for(feeditem each :feedList){
            userIds.add(each.createdById);    
        }
        map<id,user> Usermap = new map<id,user>([SELECT id,CommunityNickname FROM user WHERE ID IN : userIds]);
         for(feeditem each :feedList){
             wrapperList eachWrapper = new wrapperList();
             eachWrapper.item = each;
             eachWrapper.userName = Usermap.get(each.createdById).CommunityNickname;
             listWrapper.add(eachWrapper);
         }
        
         return listWrapper;
    }
    public class wrapperList{
        @AuraEnabled public feedItem item;
        @AuraEnabled public string userName;
    }

}