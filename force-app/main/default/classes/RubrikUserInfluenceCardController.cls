/**
 * @author By Veera Gandi
 * @description Controller class for RubrikUserInfluenceCard Aura Component,
 *   Class fetches the influence metrics of the logged in user.
 * @date 5th August 2021
 */
public without sharing class RubrikUserInfluenceCardController {
    
    /**
     * @description 
     *   Method fetches counts of Best Answers, Posts liked, comments etc 
     *   by the community user from Rubrik support community.
     * 
     * @param userId The Id of the user whose influence summary is to be fetched.
     * @return UserInfluence Wrapper containing influence metrics.
     */
    @AuraEnabled(cacheable=true)
    public static UserInfluence getUserInfluenceSummary(String userId) {
        //String customerCommunityId = [SELECT Id FROM Network WHERE Name = :Label.ForumCommunityName].Id; - Commented for performance
        String customerCommunityId = Label.NetworkId;
        
        NetworkMember networkMember = [SELECT Member.BestAnswerCount__c 
                                       FROM NetworkMember
                                       WHERE MemberId = :userId
                                       AND NetworkId = :customerCommunityId];
        
        List<ChatterActivity> chatterActivities = [SELECT Id, PostCount, LikeReceivedCount,
                                                   CommentCount
                                                   FROM ChatterActivity  
                                                   WHERE ParentId  = :userId
                                                   AND NetworkId = :customerCommunityId
                                                   LIMIT 1];
        
        UserInfluence influenceDetails = new UserInfluence();
        if(Test.isRunningTest()){
            // As we cannot cover Chatter Activities in test context, mock data is used
            String mockJson = '[{"PostCount": 5,"LikeReceivedCount": 10,"CommentCount": 3}]';
            chatterActivities = (List<ChatterActivity>) JSON.deserialize(mockJson, List<ChatterActivity>.class);
        }
        
        if (!chatterActivities.isEmpty()) {
            influenceDetails.PostCount = chatterActivities[0].PostCount;
            influenceDetails.CommentCount = chatterActivities[0].CommentCount;
            influenceDetails.LikeReceivedCount = chatterActivities[0].LikeReceivedCount;
        }
        
        influenceDetails.BestAnswerReceivedCount = networkMember.Member.BestAnswerCount__c != null 
            ? (Integer)networkMember.Member.BestAnswerCount__c : 0;
        
        return influenceDetails;       
    }
    
    /**
     * @description
     *   Wrapper class to construct and return influence metrics to the Aura component.
     */
    public class UserInfluence {
        
        /**
         * @description Number of posts by the user.
         */
        @AuraEnabled
        public Integer PostCount = 0;
        
        /**
         * @description Icon representing posts.
         */
        @AuraEnabled
        public String PostIcon = 'utility:share_post';
        
        /**
         * @description Text label for posts icon.
         */
        @AuraEnabled
        public String PostIconText = 'Posts';
        
        /**
         * @description Number of comments/replies by the user.
         */
        @AuraEnabled
        public Integer CommentCount = 0;
        
        /**
         * @description Icon representing comments.
         */
        @AuraEnabled
        public String CommentIcon = 'utility:comments';
        
        /**
         * @description Text label for comments icon.
         */
        @AuraEnabled
        public String CommentIconText = 'Replies';
        
        /**
         * @description Number of likes received by the user.
         */
        @AuraEnabled
        public Integer LikeReceivedCount = 0;
        
        /**
         * @description Icon representing likes.
         */
        @AuraEnabled
        public String LikeReceivedIcon = 'utility:like';
        
        /**
         * @description Text label for likes icon.
         */
        @AuraEnabled
        public String LikeReceivedIconText = 'Likes';
        
        /**
         * @description Number of best answers received by the user.
         */
        @AuraEnabled
        public Integer BestAnswerReceivedCount = 0;
        
        /**
         * @description Icon representing best answers.
         */
        @AuraEnabled
        public String BestAnswerReceivedIcon = 'utility:check';
        
        /**
         * @description Text label for best answers icon.
         */
        @AuraEnabled
        public String BestAnswerReceivedIconText = 'Best Answers';        
    }
}