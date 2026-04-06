public without sharing class TopicCatelogController {

    @AuraEnabled
    public static List<topicClass> getTopicsList(String networkId){
        Id currentUserId= UserInfo.getUserId();
        List<Topic> topicsList = [SELECT Id, NetworkId, Name, Description, ManagedTopicType, SystemModstamp, TalkingAbout,(Select Id,SubscriberId From FeedSubscriptionsForEntity WHERE  SubscriberId=:currentUserId),(Select Id,createddate,EntityId from Topicassignments Where EntityType = 'FeedItem' order by createddate desc) FROM Topic WHERE ManagedTopicType LIKE '%Content%' order by Name];
        Set<Id> topicAssignments = new Set<Id>();

        for(Topic t : topicsList){
            for(TopicAssignment tassign : t.Topicassignments)
                topicAssignments.add(tassign.EntityId);
        }

        Map<id,FeedItem> feedMap = new Map<id,FeedItem>([Select id,LikeCount,CommentCount from FeedItem where Id IN: topicAssignments]);
        List<topicClass> topics = new List<topicClass>();
        for(Topic t : topicsList){
            Integer countsLike = 0;
            Integer commentLike = 0;
            Boolean topicSubscriptions=false;
            for(TopicAssignment tassign : t.Topicassignments){
                if(feedMap.containsKey(tassign.EntityId)){
                    countsLike += feedMap.get(tassign.EntityId).LikeCount;
                    commentLike += feedMap.get(tassign.EntityId).CommentCount;
                }
            }
            // added by Akash
            //  added topicSubscriptions
            if(t.FeedSubscriptionsForEntity.size()>0)
                topicSubscriptions=true;
            topics.add(new topicClass(t,countsLike,commentLike,topicSubscriptions));
        }
        return topics;
    }

    @AuraEnabled
    public static User getCurrentUserRecord(){
        try {
            return [SELECT Id, Is_Rubrik_Employee__c FROM User WHERE Id =: UserInfo.getUserId()]; } catch (Exception e) { throw new AuraHandledException(e.getMessage());}
    }

    @AuraEnabled
    public static void saveSubscription( list<topicClass> topicsList, String networkId){
        List<EntitySubscription> entitySubscriptionToInsert = new List<EntitySubscription>();
        Map<Id, String> subscribedTopicIdNameMap = new Map<Id, String>();
        //set<Id> subscribedIds = new set<Id>();
        set<Id> unsubscribedIds = new set<Id>();
        List<Customer_Subscription__c> newSubscriptionList = new List<Customer_Subscription__c>();

        for(topicClass sc : topicsList){
            if(sc.isSubscribed){
                //subscribedIds.add(sc.topic.Id);
                subscribedTopicIdNameMap.put(sc.topic.Id, sc.topic.Name);
            }else{
                unsubscribedIds .add(sc.topic.Id);
            }
        }
        if(!subscribedTopicIdNameMap.isEmpty()){
            set<id> subscribedtopicIds = new set<Id>();
            for(EntitySubscription subscribedTopics : [SELECT Id, ParentId FROM EntitySubscription WHERE subscriberId =: UserInfo.getUserId() AND parentId IN: subscribedTopicIdNameMap.keySet() and networkId =: networkId]){
                subscribedtopicIds.add(subscribedTopics.parentId);
            }

            Customer_Subscription__c newSubscription;
            for(Id each : subscribedTopicIdNameMap.keySet()){
                if(!subscribedtopicIds.contains(each)){
                    EntitySubscription newsb = new EntitySubscription();
                    newsb.parentId = each;
                    newsb.networkId = networkId;
                    newsb.subscriberId = userInfo.getUserId();
                    entitySubscriptionToInsert.add(newsb);

                    //CS21-858 : Insert customer subscriptions for Forums only for reporting purpose
                    newSubscription = new Customer_Subscription__c();
                    newSubscription.Type__c = 'Forum Category';
                    newSubscription.Topic_Name__c = subscribedTopicIdNameMap.get(each);
                    newSubscription.Topic_Id__c = each;
                    newSubscription.Subscribed_User_Email__c = UserInfo.getUserEmail();
                    newSubscription.User__c = UserInfo.getUserId();
                    newSubscriptionList.add(newSubscription);
                }
        }
        }

        if(!unsubscribedIds.isEmpty()){
            delete [SELECT Id FROM EntitySubscription WHERE subscriberId =: UserInfo.getUserId() AND (parentId IN: unsubscribedIds and networkId =: networkId)];

            //CS21-858 : Delete unsubscribed topics from customer subscriptions for Forums only for reporting purpose
            delete [SELECT Id FROM Customer_Subscription__c WHERE User__c =: UserInfo.getUserId() AND Topic_Id__c IN: unsubscribedIds AND Type__c ='Forum Category'];
        }
        if(!entitySubscriptionToInsert.isEmpty()){
            insert entitySubscriptionToInsert;

            //CS21-858 : Insert customer subscriptions for Forums only for reporting purpose
            insert newSubscriptionList;
        }
    }

    @AuraEnabled
    public static List<wrapper> getActivityData(){
        List<wrapper> wrapperList = new List<Wrapper>();
        map<Id,ChatterActivity> mapUserToChatterActivity = new map<Id,ChatterActivity>();
        for(ChatterActivity each : [SELECT Id, NetworkId, ParentId, PostCount, CommentCount, CommentReceivedCount, LikeReceivedCount, InfluenceRawRank FROM ChatterActivity where networkId =: System.Label.networkScope order by LikeReceivedCount desc limit 5]){
            mapUserToChatterActivity.put(each.parentId,each);
        }

        for(User each : [Select Id,Name,CommunityNickname,FullphotoUrl,SmallphotoUrl from user WHERE ID IN : mapUserToChatterActivity.keySet()]){
            if(mapUserToChatterActivity.get(each.Id).LikeReceivedCount!=0){
                Wrapper eachInstance = new Wrapper();
                eachInstance.u = each;
                eachInstance.chA =   mapUserToChatterActivity.get(each.Id);
                wrapperList.add(eachInstance);
        }
    }
        return wrapperList;
    }

    public class topicClass{
        @AuraEnabled public Topic topic{get;set;}
        @AuraEnabled public DateTime lastDate{get;set;}
        @AuraEnabled public String lastDateFormatted{get;set;}
        @AuraEnabled public String imageName{get;set;}
        @AuraEnabled public Integer comments{get;set;}
        @AuraEnabled public Integer likes{get;set;}
        @AuraEnabled public Boolean IsSubscribed{get;set;}

        public topicClass(Topic topic,Integer likes,Integer comments,Boolean IsSubscribed){
            this.topic = topic;
            this.likes = likes;
            this.comments = comments;
            this.IsSubscribed=IsSubscribed;
            this.imageName = topic.Name.replaceAll(' ','_').replaceAll('/','_');
            if(!topic.Topicassignments.isEmpty()){
                this.lastDate = topic.Topicassignments[0].createddate;
                this.lastDateFormatted = lastDate.format('MMM dd, yyyy h:mm aa');
            }
    }
        public topicClass(){}
        }

    public class wrapper{
        @AuraEnabled public user u;
        @AuraEnabled public chatterActivity chA;
    }
}