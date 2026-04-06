public without sharing class leaderBoardController{

    @AuraEnabled
    public static List<wrapper> getActivityData(){
        List<wrapper> wrapperList = new List<Wrapper>();
        map<Id,ChatterActivity> mapUserToChatterActivity = new map<Id,ChatterActivity>();
        List<String> moderatorNickNames = label.ForumModerators.split(','); // added for CS21-712 - Veera

        for(ChatterActivity each : [SELECT Id, NetworkId, ParentId, PostCount, CommentCount, CommentReceivedCount, LikeReceivedCount, InfluenceRawRank FROM ChatterActivity where networkId =: System.Label.networkScope order by LikeReceivedCount desc]){
            mapUserToChatterActivity.put(each.parentId,each);
        }

        for(User each : [Select Id,Name,FullphotoUrl,SmallphotoUrl, Account.Name, CommunityNickname, Alias from user WHERE ID IN : mapUserToChatterActivity.keySet()]){
            if(mapUserToChatterActivity.get(each.Id).LikeReceivedCount!=0){
                Wrapper eachInstance = new Wrapper();
                eachInstance.u = each;
                eachInstance.chA =   mapUserToChatterActivity.get(each.Id);

                // added for CS21-712 - Veera
                if (each.Account.Name == 'Rubrik'
                    || moderatorNickNames.contains(each.Alias)) {
                    eachInstance.isRubrikEmployee = true;
                }
                // CS21-712 - End

                wrapperList.add(eachInstance);
        }
    }
        return wrapperList;
    }

    @AuraEnabled
    public static CustomWrap getPostsData(String filter){
        CustomWrap cw = new CustomWrap();
        List<feedItem> feedList = new List<feedItem>();
        DateTime lastNDays = System.now() - Integer.valueOf(Label.Last_N_Days);
        Integer recordLimit = Integer.valueOf(Label.Record_Limit);

        if(filter.equalsIgnoreCase('MostPopular')){
            Integer likeCount = Integer.valueOf(Label.MinimumLikeCount);
            feedList = [SELECT Id, Title, BestCommentId, CommentCount, LikeCount, ParentId, CreatedById, CreatedDate
                        FROM FeedItem
                        WHERE Type = 'QuestionPost' AND NetworkScope = :System.Label.NetworkScope
                        AND LikeCount >=: likeCount
                        ORDER BY LikeCount DESC, CreatedDate DESC LIMIT :recordLimit];
        }
        else if(filter.equalsIgnoreCase('MostReplied')){
            Integer commentCount = Integer.valueOf(Label.MinimumCommentCount);
            feedList = [SELECT Id, Title, BestCommentId, CommentCount, LikeCount, ParentId, CreatedById, CreatedDate
                        FROM FeedItem
                        WHERE Type = 'QuestionPost' AND NetworkScope = :System.Label.NetworkScope
                        AND CommentCount >=: commentCount
                        ORDER BY CommentCount DESC, CreatedDate DESC LIMIT :recordLimit];
        }
        else if(filter.equalsIgnoreCase('Recent')){
            feedList = [SELECT Id, Title, BestCommentId, CommentCount, LikeCount, ParentId, CreatedById, CreatedDate
                        FROM FeedItem
                        WHERE Type = 'QuestionPost' AND NetworkScope = :System.Label.NetworkScope
                        AND CreatedDate >: lastNDays
                        ORDER BY CreatedDate DESC LIMIT :recordLimit];
        }

        if(!feedList.isEmpty()) {
            Set<Id> feedItemIds = new Set<Id>();
            Map<Id, List<FeedItem>> mapUserTofeedItems = new Map<Id, List<FeedItem>>();

            for(feedItem each : feedList){
                feedItemIds.add(each.Id);

                if(!mapUserTofeedItems.containsKey(each.createdbyId)) {
                    mapUserTofeedItems.put(each.createdById, new List<feedItem>());
                }
                mapUserTofeedItems.get(each.createdbyId).add(each);
            }

            List<TopicAssignment> topicList = [SELECT Id, CreatedDate, EntityId, TopicId, Topic.Name
                                               FROM TopicAssignment
                                               WHERE EntityType = 'FeedItem'
                                               AND NetworkId = :System.Label.NetworkScope
                                               AND EntityId IN :feedItemIds];

            Map<Id, TopicAssignment> mapentityToTopic = new Map<Id, TopicAssignment>();
            if(!topicList.isEmpty()){
                for(TopicAssignment each : topicList){
                    mapentityToTopic.put(each.entityId,each);
                }
            }

            List<String> moderatorNickNames = Label.ForumModerators.split(','); // added for CS21-712 - Veera
            List<FeedWrapper> wrapperList = new List<FeedWrapper>();
            
            Map<Id, User> userMap = new Map<Id, User>([SELECT Id, CommunityNickName, Name, FullPhotoURL,
                                                        SmallPhotoURL, Account.Name, Alias FROM User
                                                        WHERE Id IN :mapUserTofeedItems.keySet()]);

            for(FeedItem eachFeed : feedList){
                    feedwrapper wrapper1 = new feedwrapper();
                User feedAuthor = userMap.get(eachFeed.CreatedById);
                wrapper1.u = feedAuthor;
                wrapper1.eachFeed = eachFeed;
                wrapper1.eachTopic = mapentityToTopic.get(eachFeed.Id);

                // added for CS21-712 - Veera
                if (feedAuthor.Account.Name == 'Rubrik'
                    || moderatorNickNames.contains(feedAuthor.Alias)) {
                        wrapper1.isRubrikEmployee = true;
                    }
                    // CS21-712 - End

                    wrapperList.add(wrapper1);
            }

            cw.feedWrap = wrapperList;
            cw.fetchMoreData = true;
        } else {
            cw.fetchMoreData = false;
        }

        return cw;
    }
    
    public class wrapper{
        @AuraEnabled public user u;
        @AuraEnabled public chatterActivity chA;
        @AuraEnabled public Boolean isRubrikEmployee = false; // added for CS21-712 - Veera
    }

    public class feedwrapper{
        @AuraEnabled public user u;
        @AuraEnabled public feedItem eachFeed;
        @AuraEnabled public TopicAssignment eachTopic;
        @AuraEnabled public Boolean isRubrikEmployee = false; // added for CS21-712 - Veera
    }

    public class CustomWrap{
        @AuraEnabled public List<feedwrapper> feedWrap;
        @AuraEnabled public Id lastTopicAssignmentId;
        @AuraEnabled public Id lastFeedItemId;
        @AuraEnabled public Boolean fetchMoreData;
    }
}