public without sharing class AttachingCusSubHelper {
    
    public static void beforeInsert(List<Community_Feed__c> commFeeds){
        List<String> userNames = new List<String>();
        for(Community_Feed__c cm : commFeeds){
            if(cm.Title__c != null && cm.Title__c.contains('@')){
                userNames.addAll(getNames(cm.Title__c));
            }
        }
        
        if(!userNames.isEmpty()){
            List<User> userList = [SELECT id, Name,Contact.Name, CommunityNickName FROM User WHERE Contact.Name LIKE: userNames ];
            Map<String,List<Id>> userNameToIdMap = new Map<String,List<Id>>();
            Map<String,String> userNameToAliasMap= new Map<String,String>();
            for(User usr : userList){
                if(!userNameToIdMap.containsKey(usr.Name)){
                    userNameToIdMap.put(usr.Contact.Name, new List<Id>());
                }
                userNameToIdMap.get(usr.Contact.Name).add(usr.Id);
                userNameToAliasMap.put(usr.Contact.Name,usr.CommunityNickName);
            }
            for(Community_Feed__c cm : commFeeds){
                for(String key : userNameToIdMap.keySet()){
                    if(cm.Title__c.contains('@'+key)){
                        
                        if(userNameToIdMap.get(key).size() > 1){
                            cm.Title__c = cm.Title__c.replaceAll('@'+key+'?','@tagged User').replaceAll('@'+key,'@tagged User');
                        }else{
                            cm.Title__c = cm.Title__c.replaceAll('@'+key+'?',userNameToAliasMap.get(key)).replaceAll('@'+key,userNameToAliasMap.get(key));
                        }
                    }
                }
            }
        }
    }
    
    public static void afterInsert(List<Community_Feed__c> commFeeds,Map<id,Community_Feed__c>commFeedsMap){
        Set<Id>feedItemId= new Set<Id>();
        List<Customer_Subscription__c> customerSubsRecord= new List<Customer_Subscription__c>();
        Map<Id,List<Customer_Subscription__c>> feedItemIdVscustomerSubscriptions = new   Map<Id,List<Customer_Subscription__c>> (); 
        Map<ID,set<ID>> userIDToTopicID=new Map<ID,set<ID>>();
        Set<ID> CommunityFeedUser=new Set<ID>();
        for(Community_Feed__c feed:commFeeds){
            
            // if(NULL==feed.ParentId__c){
            feedItemId.add(feed.FeedItemId__c);
            // }
            
        }
        System.debug('feedItemId@@@@@'+feedItemId);
        for(Customer_Subscription__c cs:[Select id,User__r.Daily_Subscription__c,KB_ID__c,User__c,User__r.Email,Topic_Id__c,Topic_Name__c,Title__c from Customer_Subscription__c where KB_ID__c IN:feedItemId and Type__c='FeedItem']){
            
            if(! feedItemIdVscustomerSubscriptions.containsKey(cs.KB_ID__c)){
                
                feedItemIdVscustomerSubscriptions.put(cs.KB_ID__c, new list<Customer_Subscription__c>());
            }
            
            feedItemIdVscustomerSubscriptions.get(cs.KB_ID__c).add(cs);
            
            CommunityFeedUser.add(cs.User__c);
        } 
        
        for(Customer_Subscription__c cs:[Select id,User__c,Topic_Id__c from Customer_Subscription__c where User__c IN:CommunityFeedUser and Type__c='Forum Category']){
            
            if(userIDToTopicID.containsKey(cs.User__c)){
                set<ID> tempList=userIDToTopicID.get(cs.User__c);
                tempList.add(cs.Topic_Id__c);
                userIDToTopicID.put(cs.User__c,tempList);
            }else{
                userIDToTopicID.put(cs.User__c, new Set<ID>{cs.Topic_Id__c});
            }
            
        }
        
        for(Community_Feed__c feed:commFeeds) {
            
            if(feedItemIdVscustomerSubscriptions.containsKey(feed.FeedItemId__c)){
                
                for(Customer_Subscription__c cs: feedItemIdVscustomerSubscriptions.get(feed.FeedItemId__c)){
                    
                    if(!cs.User__r.Daily_Subscription__c || (userIDToTopicID.containsKey(cs.user__c) && !userIDToTopicID.get(cs.user__c).contains(cs.Topic_Id__c))){
                     
                        cs.Community_Feed__c=feed.Id;
                        cs.Subscribed_User_Email__c=cs.User__r.Email;
                        customerSubsRecord.add(cs);
                    }else if(!userIDToTopicID.containsKey(cs.user__c)){
                       
                        cs.Community_Feed__c=feed.Id;
                        cs.Subscribed_User_Email__c=cs.User__r.Email;
                        customerSubsRecord.add(cs);
                    }
                }
            }
        }
        if(!customerSubsRecord.isEmpty()){
            update customerSubsRecord;
        }
    }
    
    public static List<String> getNames(String feedBody){
        List<String> userNames = new List<String>();
         List<String> splittedBody = feedBody.split(' ');
        for(String str : splittedBody){
            if(str.contains('@')){
                if(str.indexOf('@') != 0){
                    str = str.substring(str.indexOf('@'));
                }
                userNames.add(str.replace('@', '')+'%');
            }
        }  
        
        return userNames;
    }
    
}