/**
* Test class for Forum Gamification functionality
*
* Classes:
* RubrikLeaderBoardController
* RubrikUserInfluenceCardController
* RubrikUserProfileCardController
* RubrikUserQuestionContributorsController
* RubrikRecognitionBadgeController
*
* these test classes need Network and Network member records which are setup objects 
* and cannot be created
* 
* 
* https://ideas.salesforce.com/s/idea/a0B8W00000GdfrDUAR/insert-network-chatter-community-related-objects-in-test-classes
*/
@isTest(SeeAllData=true)
public class RubrikForumGamificationTest {
    
    @istest
    static void forumGamificationTest() {
        RubrikUserProfileCardController.getUserDetails(UserInfo.getUserId());
        RubrikRecognitionBadgeController.getRecognitionBadges(UserInfo.getUserId());
        RubrikLeaderBoardController.getLeaders();
        RubrikUserInfluenceCardController.getUserInfluenceSummary(UserInfo.getUserId());
    }
    
    @isTest
    static void forumGamificationContributorTest() {
        FeedItem post = new FeedItem();
        post.Title = 'Have a Question?';
        post.Type = 'QuestionPost'; 
        post.ParentId = userinfo.getuserid();
        post.Body = 'Too many questions related to Forum.';
        insert post;
        
        FeedComment comment = new FeedComment();
        comment.FeedItemId = post.Id;
        comment.CommentBody = 'I have the best answer. I am awesome.';
        insert comment;
        
        RubrikUserQuestionContributorsController.getContributorDetails(post.Id);  
    }
    
    @isTest
    static void forumGamificationLeaderBoardTest() {
        String customerCommunityId = [SELECT Id FROM Network WHERE Name = :Label.ForumCommunityName].Id;
        
        NetworkMember eachNetworkMember = [SELECT MemberId
                                           FROM NetworkMember 
                                           WHERE NetworkId = :customerCommunityId
                                           AND Member.Account.Name != 'Rubrik'
                                           AND Member.Account.Name != ''
                                           AND Member.IsActive = true
                                           ORDER BY ReputationPoints DESC
                                           LIMIT 1];
        
        
    }
    
}