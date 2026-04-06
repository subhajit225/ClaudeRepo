@isTest
public class BatchUpdateFeedData_Test {
    public static testMethod void BatchUpdateFeedData_Test(){
        
        Database.QueryLocator QL;
        Database.BatchableContext BC;
        List<FeedItem> FeedList = new List<FeedItem>();
        FeedItem fd = new FeedItem();
        fd.Title ='test';
        fd.Body ='test';
        fd.ParentId = userinfo.getuserid();
        FeedList.add(fd);
        insert FeedList;
        BatchUpdateFeedData b = new BatchUpdateFeedData('SELECT Id,bestCommentId, ParentId, Type, CreatedBy.Name, CreatedById, CreatedDate, LastModifiedDate, Revision, LastEditDate, CommentCount, LikeCount, Title, Body, Visibility FROM FeedItem');
        database.executeBatch(b);
    } 
    public static testMethod void BatchUpdateFeedData_Test1(){
        Database.QueryLocator QL;
        Database.BatchableContext BC;
        BatchUpdateFeedData b = new BatchUpdateFeedData('');
        database.executeBatch(b);
    }
    public static testMethod void BatchUpdateFeedData_Test2(){
       System.schedule('BatchUpdateFeedData', '0 0 * * * ?', new BatchUpdateFeedData('') );

    }
}