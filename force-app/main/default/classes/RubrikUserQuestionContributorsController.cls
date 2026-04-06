/**
* @description Controller class for RubrikUserQuestionContributors Aura Component,
* Class fetches Contributors on a Feed/Question, Contributors are the Forum members who
* answer on a Post
*
* @CreatedDate 5th August 2021
* @Created By Veera Gandi
*
*/
public without sharing class RubrikUserQuestionContributorsController {

    /**
    * @description method fetches counts of Best Answers, Posts liked, comment etc
    * for the users who has answered on a specific post/feed.
    * @param Post/FeedItem Id
    * @return Wrapper
    */
    @AuraEnabled(cacheable=true)
    public static List<UserInfluence> getContributorDetails(String questionId) {
        //String customerCommunityId = [SELECT Id FROM Network WHERE Name = :Label.ForumCommunityName].Id; - Commented for performance
        String customerCommunityId = Label.NetworkId;

        Map<String, UserInfluence> contributors = new Map<String, UserInfluence>();
        Set<Id> contributorIds = new Set<Id>();
        List<String> moderatorNickNames = label.ForumModerators.split(',');
        Integer contributorsLimit = Integer.valueOf(Label.ForumContributorsLimit);

        /*
        * Ticket : CS21-1238
        * Description : Contributors were not shown because there was an instance when user clicks on the detail page of the post with comment's Id
                      then, for-loop SOQL on FeedItem below does not return any record
        * Solution : Added a check on questionId that if it is a commentId instead of feedItem Id then fetching FeedItemId from the comment's Id
                     and assigning again into the variable questionId so that for-loop SOQL on FeedItem return the record
        */
        if (String.isNotBlank(questionId) && questionId.startsWith('0D7')) {
            List<FeedComment> feedCommentList = [SELECT Id, FeedItemId FROM FeedComment WHERE Id =:questionId];
            if (feedCommentList != null && !feedCommentList.isEmpty()) {
                questionId = feedCommentList[0].FeedItemId;
            }
        }

        //CS21-1351 : Clubbing the Feeditem and FeedComment queries into 1 to improve page load performance
        for (FeedItem question : [SELECT CreatedById,
                                    (SELECT FeedItemId, ParentId, CreatedById
                                    FROM FeedComments
                                    ORDER BY CreatedDate DESC
                                    LIMIT :contributorsLimit)
                                  FROM FeedItem
                                  WHERE Id = :questionId]){
            contributorIds.add(question.CreatedById);
            contributors.put(question.CreatedById, new UserInfluence());
            contributors.get(question.CreatedById).isAuthor = true;

            for (FeedComment eachComment : question.FeedComments) {
                contributorIds.add(eachComment.CreatedById);
            }
        }

        if (!contributorIds.isEmpty()) {
            for(NetworkMember eachNetworkMember : [SELECT MemberId, Member.Name, Member.CommunityNickname, ReputationPoints,
                                                   Member.SmallPhotoUrl, Member.Account.Name, Member.Alias, Member.BestAnswerCount__c
                                                   FROM NetworkMember
                                                   WHERE MemberId IN :contributorIds
                                                   AND NetworkId = :customerCommunityId
                                                   ORDER BY ReputationPoints DESC])
            {
                if (!contributors.containsKey(eachNetworkMember.MemberId)) {
                    contributors.put(eachNetworkMember.MemberId, new UserInfluence());
                }

                contributors.get(eachNetworkMember.MemberId).Name = eachNetworkMember.Member.CommunityNickname;
                contributors.get(eachNetworkMember.MemberId).UserId = eachNetworkMember.MemberId;
                contributors.get(eachNetworkMember.MemberId).ReputationPoints = (Integer) eachNetworkMember.ReputationPoints;
                contributors.get(eachNetworkMember.MemberId).PhotoURL = eachNetworkMember.Member.SmallPhotoUrl;

                if (eachNetworkMember.Member.BestAnswerCount__c != null) {
                    contributors.get(eachNetworkMember.MemberId).BestAnswerReceivedCount = (Integer) eachNetworkMember.Member.BestAnswerCount__c;
                }

                if (eachNetworkMember.Member.Account.Name == 'Rubrik'
                    || moderatorNickNames.contains(eachNetworkMember.Member.Alias)) {
                    contributors.get(eachNetworkMember.MemberId).isRubrikEmployee = true;
                }
            }

            for (ChatterActivity eachChatterActivity : [SELECT ParentId, PostCount, LikeReceivedCount,
                                                        CommentCount
                                                        FROM ChatterActivity
                                                        WHERE ParentId IN :contributorIds
                                                        AND NetworkId = :customerCommunityId])
            {
                contributors.get(eachChatterActivity.ParentId).PostCount = eachChatterActivity.PostCount;
                contributors.get(eachChatterActivity.ParentId).CommentCount = eachChatterActivity.CommentCount;
                contributors.get(eachChatterActivity.ParentId).LikeReceivedCount = eachChatterActivity.LikeReceivedCount;
            }

            /*
             * Commented for next sprint - badges are not included in sprint 1
             *
             for (AggregateResult eachUserbadgeCount : [SELECT Count(Id) badgeCount, RecipientId userId
                                                       FROM WorkBadge
                                                       WHERE RecipientId IN :contributorIds
                                                       GROUP BY RecipientId])
            {
                Id userId = (Id) eachUserbadgeCount.get('userId');
                contributors.get(userId).BadgeCount = (Integer) eachUserbadgeCount.get('badgeCount');
            } */

            return contributors.values();
        } else {
            return new List<UserInfluence>();
        }
    }

    /**
    * @description Wrapper class to construct Influence Object
    */
    public class UserInfluence {
        @AuraEnabled
        public String Name;
        @AuraEnabled
        public String UserId;
        @AuraEnabled
        public String PhotoURL;
        @AuraEnabled
        public Integer ReputationPoints = 0;
        @AuraEnabled
        public Integer PostCount = 0;
        @AuraEnabled
        public Integer CommentCount = 0;
        @AuraEnabled
        public Integer LikeReceivedCount = 0;
        @AuraEnabled
        public Integer BadgeCount = 0;
        @AuraEnabled
        public Integer BestAnswerReceivedCount = 0;
        @AuraEnabled
        public Boolean isRubrikEmployee = false;
        @AuraEnabled
        public Boolean isAuthor = false;
    }
}