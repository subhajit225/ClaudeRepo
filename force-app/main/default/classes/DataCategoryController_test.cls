@isTest
public class DataCategoryController_test {
    static TestMethod Void DataCategoryController_test1(){
        Topic tpc = new Topic();
        tpc.Name = 'Topic Test';
        insert tpc;
        
        FeedItem FD = new FeedItem();
        FD.ParentId = userinfo.getuserid();
        FD.Body = 'Test';
        FD.Title = 'Test';
        FD.Type = 'QuestionPost';
        Insert FD;
        
        FeedComment FC = new FeedComment();
        FC.FeedItemId = FD.Id;
        FC.CommentBody = 'Test';
        insert FC;
        
        TopicAssignment TA = new TopicAssignment();
        TA.TopicId = tpc.Id;
        TA.EntityId = FD.Id;
        insert TA;
        Forum_Info__c formInfo = new Forum_Info__c();
        formInfo.Type__c = 'Item';
        formInfo.Id__c = FD.Id;
        insert formInfo;
        
        DataCategoryController.getQuestionList(tpc.Id);
        //DataCategoryController.getQuestionListAPI(tpc.Id);
        DataCategoryController.PinPost(FD.Id, tpc.Id);
        DataCategoryController.DeletePost(FD.Id, tpc.Id);
    }
    /*static TestMethod Void DataCategoryController_test(){
        Topic tpc = new Topic();
        tpc.Name = 'Topic Test';
        insert tpc;
        DataCategoryController.getQuestionListAPI(tpc.Id);
    }*/
}