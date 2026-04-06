public without sharing class DataCategoryController {

    
    @AuraEnabled
    public static feedItemClass getQuestionList(String topicId){
        List<feedItems> feedList = new List<feedItems>();
        List<feedItems> pinnedfeeds = new List<feedItems>();
        try{
            Set<Id> feedItemsIds = new Set<Id>();
            for(TopicAssignment tp :[SELECT EntityId FROM TopicAssignment WHERE TopicId =:topicId] ){
                feedItemsIds.add(tp.EntityId);
            }
           
            List<Forum_Info__c> forums = [SELECT Id, Id__c, Type__c, Parent__c, Pinned__c FROM Forum_Info__c WHERE Type__c = 'Item' AND Id__c IN:feedItemsIds];
            Map<Id,Forum_Info__c> forumMap = new Map<Id,Forum_Info__c>();
            for(Forum_Info__c f : forums){
                forumMap.put(f.Id__c,f);
            }
            Set<Id> userIds = new Set<Id>();
            List<FeedItem> feedsList = [SELECT Id, ParentId, Type, CreatedBy.Name, CreatedById, CreatedDate, BestCommentId, LastModifiedDate, Revision, LastEditDate, CommentCount, LikeCount, Title, Body, Visibility,(SELECT Id, FeedItemId, ParentId,CreatedById,CreatedDate FROM FeedComments ORDER BY CreatedDate desc LIMIT 1) FROM FeedItem where Type = 'QuestionPost' AND ID IN: feedItemsIds Order By CreatedDate desc];
            for(FeedItem ft : feedsList){
                userIds.add(ft.CreatedById);
                if(ft.FeedComments.size() > 0){
                    userIds.add(ft.FeedComments[0].CreatedById);
                }
            }
            //added Account and alias - for Gamification
            Map<id,User> userMap = new Map<id,User>([SELECT id,SmallPhotoUrl,Name,CommunityNickName,Account.Name,Alias from User Where ID IN: userIds]);
            for(FeedItem ft : feedsList){
                
                User u = userMap.get(ft.CreatedById);
                User childUser = new User();
                if(ft.FeedComments.size() > 0){
                    childUser = userMap.get(ft.FeedComments[0].CreatedById);
                }
                Boolean isPinned = false;
                if(forumMap.containsKey(ft.Id)){
                    isPinned = forumMap.get(ft.Id).Pinned__c;
                }
                if(isPinned){
                    pinnedfeeds.add(new feedItems(ft, u, childUser, isPinned, isRubrikEmployeed(u), isRubrikEmployeed(childUser)));
                }
                feedList.add(new feedItems(ft, u, childUser, isPinned, isRubrikEmployeed(u), isRubrikEmployeed(childUser)));
            }  
        }catch(exception e){
            system.assert(false,'linenumber==='+e.getLineNumber());
        }
        return new feedItemClass(feedList,pinnedfeeds); 
    }
    
    /*
	* method created for gamification to identify rubrik employees
	*/
    private static boolean isRubrikEmployeed(User eachUser) {
        List<String> moderatorNickNames = label.ForumModerators.split(','); // added for CS21-712 - Veera 
        
        if (eachUser.Account.Name == 'Rubrik' 
            || moderatorNickNames.contains(eachUser.Alias)){
            return true;
        }
        
        return false;
    }
    
    @AuraEnabled
    public static String getQuestionListAPI(String topicId){
        Http h = new Http();
        HttpRequest webReq = new HttpRequest();
        webReq.setMethod('GET');
        webReq.setHeader('Authorization','Bearer '+UserInfo.getSessionId());
        // replace endpoint url
        webReq.setEndpoint('https://rubrikinc--supfullsb.cs15.my.salesforce.com/services/data/v46.0/connect/communities/0DB1W00000001vM/chatter/feeds/topics/'+topicId+'/feed-elements?type=QuestionPost');
        HttpResponse res = h.send(webReq);
        return res.getBody();
    }
    @AuraEnabled
    public static feedItemClass DeletePost(String feedId,String topicId){
        return getQuestionList(topicId); 
    }
    @AuraEnabled
    public static feedItemClass PinPost(String feedId,String topicId){
        List<Forum_Info__c> forums = [SELECT Id, Id__c, Type__c, Parent__c, Pinned__c FROM Forum_Info__c WHERE Type__c = 'Item' AND Id__c =: feedId];
        if(!forums.isEmpty()){
            forums[0].Pinned__c = forums[0].Pinned__c ? false : true;
            update forums;
        }
        
        return getQuestionList(topicId); 
    }
     public class feedItemClass{
          @AuraEnabled public List<feedItems> feed{get;set;}
          @AuraEnabled public List<feedItems> pinnedfeeds{get;set;}
         public feedItemClass(List<feedItems> feed,List<feedItems> pinnedfeeds){
             this.feed = feed;
             this.pinnedfeeds = pinnedfeeds;
         }
     }
    
    public class feedItems{
        @AuraEnabled public feedItem feed{get;set;}
        @AuraEnabled public User userRecord{get;set;}
        @AuraEnabled public String productFamily{get;set;}
        @AuraEnabled public Boolean isPinned{get;set;}
        @AuraEnabled public User childuserRecord{get;set;}
        @AuraEnabled public Boolean isUserRubrikEmployee{get;set;} // added for Gamification
        @AuraEnabled public Boolean isCommentUserRubrikEmployee{get;set;} // added for Gamification
        
        public feedItems(feedItem feeds, User u, User childUser, Boolean isPinned, Boolean isUserRubrikEmployee, Boolean isCommentUserRubrikEmployee){
            this.feed = feeds;
            this.userRecord = u;
            this.childuserRecord = childUser;
            this.isPinned = isPinned;
            this.isUserRubrikEmployee = isUserRubrikEmployee; // added for Gamification
            this.isCommentUserRubrikEmployee = isCommentUserRubrikEmployee; // added for Gamification
        }
        
        public feedItems(feedItem feeds, User u, User childUser, String p, Boolean isUserRubrikEmployee, Boolean isCommentUserRubrikEmployee){
            this.feed = feeds;
            this.userRecord = u;
            this.childuserRecord = childUser;
            this.productFamily = p;
            this.isUserRubrikEmployee = isUserRubrikEmployee; // added for Gamification
            this.isCommentUserRubrikEmployee = isCommentUserRubrikEmployee; // added for Gamification
        }
    }
}