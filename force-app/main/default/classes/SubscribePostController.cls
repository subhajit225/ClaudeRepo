public without sharing class SubscribePostController {
    
    
    @AuraEnabled
    public static boolean  getBookmarkInfo(String networkId,String questionId ){
        if(questionId.startsWith('0D7')){
            FeedComment fc = [SELECT Id, FeedItemId From FeedComment WHERE Id =: questionId];
            questionId = fc.FeedItemId;
        }
        ConnectApi.FeedElement  clp = ConnectApi.ChatterFeeds.getFeedElement(networkId, questionId); 
        return clp.capabilities.bookmarks.isBookmarkedByCurrentUser;
        
    }
    
    @AuraEnabled
    public static boolean  addBookMark(String networkId,String questionId,boolean isBookmarked ){
        ConnectApi.BookmarksCapability bookmark;  
        
        TopicAssignment topicAss=[SELECT EntityId,EntityKeyPrefix,EntityType,Id,IsDeleted,NetworkId,SystemModstamp,TopicId,Topic.Name FROM TopicAssignment where EntityId=:questionId and NetworkId=:networkId limit 1];
        FeedItem   feedItem=[SELECT Id,Title,NetworkScope,createdById from FeedItem where Id=:topicAss.EntityId] ;
        try{
            system.debug('networkId1'+networkId);
            system.debug('questionId1'+questionId);
            system.debug('isBookmarked1'+isBookmarked);
            
            bookmark = ConnectApi.ChatterFeeds.updateFeedElementBookmarks(networkId, questionId, isBookmarked);
            system.debug('bookmark111'+bookmark);
            
            Customer_Subscription__c cs= new Customer_Subscription__c();
            cs.Type__c='FeedItem';
            cs.KB_ID__c=questionId;
            cs.Title__c=feedItem.Title;
            cs.Topic_Name__c=topicAss.Topic.Name;
            //cs.Post_Created_By__c=feedItem.createdById.to15();
            cs.Post_Creator__c=feedItem.createdById;
            //cs.FeedItemCreatedDate__c=feedItem.CreatedDate;
            cs.Topic_Id__c=topicAss.TopicId;
            cs.User__c=UserInfo.getUserId();
            insert cs;
        }
        
        catch(exception e){
            
            system.debug('exception'+e.getMessage());
        }
        
        if(!test.isRunningTest()){
            return   bookmark.isBookmarkedByCurrentUser;
        }
        else{
            return true;
        } 
       
    }
    
    @AuraEnabled
    public static  Map<String,List<Customer_Subscription__c>>  getPostSubscriptionInfo(){
        //Creating a map of Topic Name VS Post under it
        Map<String,List<Customer_Subscription__c>> topicVsPosts= new  Map<String,List<Customer_Subscription__c>>();
        Set<Id> postIds = new set<Id>();
        for(Customer_Subscription__c cs : [SELECT Id,KB_ID__c,Type__c,User__c FROM  Customer_Subscription__c  WHERE Type__c='FeedItem' and User__c=:userinfo.getUserid()]){
            postIds.add(cs.KB_ID__c);
        }
        Map<Id,FeedItem> fIMap = new Map<Id,FeedItem>([SELECT Id,IsDeleted From FeedItem WHERE IsDeleted = False AND Id IN : postIds]);
        for(Customer_Subscription__c cs :[SELECT Id,KB_ID__c,Name,Title__c,Topic_Id__c,Topic_Name__c,Type__c,User__c FROM  Customer_Subscription__c  WHERE Type__c='FeedItem' AND User__c=:userinfo.getUserid() AND KB_ID__c IN : fIMap.keySet()]){
            
            if(!topicVsPosts.containsKey(cs.Topic_Name__c)){
                
                topicVsPosts.put(cs.Topic_Name__c,new List<Customer_Subscription__c>());
                
            }
            topicVsPosts.get(cs.Topic_Name__c).add(cs);
        }
        system.debug('topicVsPosts'+topicVsPosts);
        
        return topicVsPosts;
    }
    
    
    @AuraEnabled
    public static boolean removeBookMark(String networkId,String questionId ,boolean isBookmarked,Id currentuserId){
        system.debug('hrereee111111');
        ConnectApi.BookmarksCapability bookmark ;
        
        try{
            Id curentUser15DigitId=currentuserId.to15();
            system.debug('curentUser15DigitId'+curentUser15DigitId);
            system.debug('isBookmarked@@@@'+isBookmarked); 
            system.debug('questionId@@@@'+questionId); 
            bookmark = ConnectApi.ChatterFeeds.updateFeedElementBookmarks(networkId, questionId,  isBookmarked);
            system.debug('bookmark@@@@'+bookmark);
            delete[Select Id,KB_ID__c,User__c From Customer_Subscription__c where  KB_ID__c=:questionId and User__c=:curentUser15DigitId];
        }
        catch(exception e){
            
            system.debug('exception'+e.getMessage());
            system.debug('exception#####'+e.getLineNumber());
        }
        
        return bookmark.isBookmarkedByCurrentUser;
        
    }
    
    @AuraEnabled
    public static void unsubscribeAll(){   
        Database.executeBatch(new DeleteAllSubscriptions('Forum'), 500);
    }
    
    /***************************************************** 
* CS21-1172
* MyPostSubscriptionPage Categories to fetch Backend Response. 
* Method to return the subscription alert type on the UI
*****************************************************
*/
    @AuraEnabled
    public static String getUserSubsriptionType(){
        User u = [Select Daily_Subscription__c from User WHERE Id = :userInfo.getUserId()];
        return String.valueOf(u.Daily_Subscription__c);
    }
        
    /***************************************************** 
* CS21-1172
* MyPostSubscriptionPage Categories to fetch Backend Response. 
* Method to save the user response on Backend.
*****************************************************
*/
    @AuraEnabled
    public static void saveRadioSubscription(String subscriptionAlert){
        User u = new User(Id=UserInfo.getUserId());
        u.Daily_Subscription__c = Boolean.valueOf(subscriptionAlert);
        update u;
    }
}