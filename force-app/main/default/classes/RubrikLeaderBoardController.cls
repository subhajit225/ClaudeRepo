/**
* @description Controller class for RubrikLeaderBoard Aura Component,
* Class fetches the Top 10 Forum members who has top reputation points.
* Reputation points are awarded base in the Forum member activities like #Likes, #Posts, #Comments etc
*
* @CreatedDate 5th August 2021
* @Created By Veera Gandi
* 
*/
public without sharing class RubrikLeaderBoardController {
    
    /**
    * @description method fetches counts of Best Answers, Posts liked, comment etc
    * by the community user form Rubrik support community
    * @return Wrapper
    */
    @AuraEnabled(cacheable=true)
    public static List<Leader> getLeaders() {
        String customerCommunityId = Label.NetworkId;
        Map<String, Leader> leaders = new Map<String, Leader>();
        Integer leaderboardLimit = Integer.valueOf(Label.ForumLeaderBoardLimit);
        
        for(NetworkMember eachNetworkMember : [SELECT MemberId, Member.Name, Member.CommunityNickname, ReputationPoints, 
                                               Member.SmallPhotoUrl, Member.Account.Name, Member.Alias, Member.isActive, Member.BestAnswerCount__c 
                                               FROM NetworkMember 
                                               WHERE NetworkId = :customerCommunityId
                                               AND Member.isActive = true
                                               AND Member.Account.Name != 'Rubrik'
                                               AND Member.Account.Name != ''
                                               AND Member.Is_Rubrik_Employee__c = false
                                               ORDER BY ReputationPoints DESC
                                               LIMIT :leaderboardLimit])
        {
            leaders.put(eachNetworkMember.MemberId, new Leader());
            leaders.get(eachNetworkMember.MemberId).Name = eachNetworkMember.Member.CommunityNickname;
            leaders.get(eachNetworkMember.MemberId).UserId = eachNetworkMember.MemberId;
            leaders.get(eachNetworkMember.MemberId).ReputationPoints = (Integer) eachNetworkMember.ReputationPoints;
            leaders.get(eachNetworkMember.MemberId).PhotoURL = eachNetworkMember.Member.SmallPhotoUrl;
            if (eachNetworkMember.Member.BestAnswerCount__c != null) {
                leaders.get(eachNetworkMember.MemberId).BestAnswerReceivedCount = (Integer) eachNetworkMember.Member.BestAnswerCount__c;
            }
        }
        
        for (ChatterActivity eachChatterActivity : [SELECT ParentId, PostCount, LikeReceivedCount,
                                                    CommentCount
                                                    FROM ChatterActivity  
                                                    WHERE NetworkId = :customerCommunityId
                                                    AND ParentId IN :leaders.keySet()
                                                    ORDER BY LikeReceivedCount DESC]) 
        {
            leaders.get(eachChatterActivity.ParentId).PostCount = eachChatterActivity.PostCount;
            leaders.get(eachChatterActivity.ParentId).CommentCount = eachChatterActivity.CommentCount;
            leaders.get(eachChatterActivity.ParentId).LikeReceivedCount = eachChatterActivity.LikeReceivedCount;
        }
        
        return leaders.values();
    }
    
    /**
    * @description Wrapper class to construct Influence Object
    */
    public class Leader {
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
    }
    
}