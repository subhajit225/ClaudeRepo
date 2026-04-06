@isTest
public class leaderBoardController_Test {
    @isTest static void leaderBoardController1() {
        feeditem FD = new feeditem();
        FD.Title = 'Test';
        FD.type = 'QuestionPost'; 
        FD.networkscope = System.Label.networkScope;
        FD.ParentId = userinfo.getuserid();
        FD.Body = 'Test';
        insert FD;
        leaderBoardController.getActivityData();
        leaderBoardController.getPostsData('MostPopular');
        leaderBoardController.getPostsData('MostReplied');
        leaderBoardController.getPostsData('Recent');
    }
}