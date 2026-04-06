/**
* Test class for Forum Gamification functionality
*
* Classes:
* RubrikCommunityBestAnswerCalculation
* RubrikCommunityBestAnswerUpdate
*
* SeeAllData is set to true as BestCommentId is not a writeable field 
* and it is required to cover RubrikCommunityBestAnswerCalculation batch
*/
@isTest(SeeAllData=true)
public class RubrikCommunityBestAnswerCalculationTest {
    
    @isTest
    static void forumBestAnswerCalculationTest() {
        test.startTest();
        RubrikCommunityBestAnswerCalculation rubrikBestAnswerCalculation = new RubrikCommunityBestAnswerCalculation();
        Database.executeBatch(rubrikBestAnswerCalculation, 200);
        test.stopTest();
    }
    
    @isTest
    static void forumBestAnswerUpdateTest() {
        Map<String, Integer> bestAnswersSummary = new Map<String, Integer>();
        bestAnswersSummary.put(userInfo.getUserId(), 10);
        
        
        test.startTest();
        RubrikCommunityBestAnswerUpdate updateBestAnswerCountOnForumUser = new RubrikCommunityBestAnswerUpdate(bestAnswersSummary);
        Database.executeBatch(updateBestAnswerCountOnForumUser, 10);
        test.stopTest();
        
        User currentUser = [SELECT Id, BestAnswerCount__c FROM User WHERE Id = :userInfo.getUserId()];
        system.assertEquals(10, currentUser.BestAnswerCount__c);
        
    }
}