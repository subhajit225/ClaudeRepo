public  without sharing  class SubscribeTopicController {

    @AuraEnabled
    public static boolean getSusbcriptionInfo(String networkId, String topicId){
        Topic selectedTopic=[SELECT Id, NetworkId, Name, Description, ManagedTopicType, SystemModstamp, TalkingAbout,
                            (SELECT Id, SubscriberId FROM FeedSubscriptionsForEntity WHERE SubscriberId=:UserInfo.getUserId() ) FROM Topic WHERE Id=:topicId and NetworkId=:networkId];

        return (!selectedTopic.FeedSubscriptionsForEntity.isEmpty());
    }

    @AuraEnabled
    public static boolean unSubscribe(String networkId, String topicId1){
           try{
            delete[SELECT Id FROM EntitySubscription where ParentId=:topicId1 and NetworkId =:networkId and SubscriberId=:UserInfo.getUserId()];

            //CS21-858 : Delete unsubscribed topics from customer subscriptions for Forums only for reporting purpose
            delete [SELECT Id FROM Customer_Subscription__c WHERE User__c =: UserInfo.getUserId() AND (Topic_Id__c =: topicId1)];
            return true;
           }
           catch(exception e){
            return false;
           }
    }

    @AuraEnabled
    public static boolean subscribe(String networkId, String topicId){
                try{
                    EntitySubscription newsb = new EntitySubscription();
                    newsb.parentId = topicId;
                    newsb.networkId = networkId;
                    newsb.subscriberId = userInfo.getUserId();
                    insert  newsb;

            Topic topicRecord = [SELECT Id, Name FROM Topic WHERE Id =: topicId];
            //CS21-858 : Insert customer subscriptions for Forums only for reporting purpose
            Customer_Subscription__c newSubscription = new Customer_Subscription__c();
            newSubscription.Type__c = 'Forum Category';
            newSubscription.Topic_Name__c = topicRecord.Name;
            newSubscription.Topic_Id__c = topicRecord.Id;
            newSubscription.Subscribed_User_Email__c = UserInfo.getUserEmail();
            newSubscription.User__c = UserInfo.getUserId();
            insert newSubscription;

                    return true;
           }
           catch(exception e){
            return false;
           }
    }
}