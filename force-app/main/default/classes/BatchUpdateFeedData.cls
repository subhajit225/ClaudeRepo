global class BatchUpdateFeedData  implements Database.Batchable<sObject>, Schedulable{
    global String theQuery = '';
    
    global BatchUpdateFeedData(String queryForThisBatch){
        if(queryForThisBatch!=null && queryForThisBatch!='')
            theQuery = queryForThisBatch;
        else
            theQuery = 'SELECT Id,bestCommentId, ParentId, Type, CreatedBy.Name, CreatedById, CreatedDate, LastModifiedDate, Revision, LastEditDate, CommentCount, LikeCount, Title, Body, Visibility FROM FeedItem where type= \'QuestionPost\'';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(theQuery);
    }
    
    global void execute(Database.BatchableContext BC,List<FeedItem> scopeList) {
        map<Id,List<ConnectApi.Comment>> mapItemToComments = new map<Id,List<ConnectApi.Comment>>();
        List<FeedItem> lstUpdate = new List<FeedItem>();
        for(FeedItem each : scopeList){
            Integer LikesForBestComment = 0;
            if(each.bestCommentID!=null) LikesForBestComment = ConnectApi.ChatterFeeds.getLikesForComment(System.Label.networkScope,each.bestCommentId).total;
            if(!Test.isRunningTest()){ List<ConnectApi.Comment>  comments = ConnectApi.ChatterFeeds.getCommentsForFeedElement( System.Label.networkScope,each.Id).items;        
            
            for(ConnectApi.Comment each1 : comments){
                if(each1.likes.total >= 3 && each1.likes.total>LikesForBestComment && each1.Id!=each.bestCommentId){ ConnectApi.QuestionAndAnswersCapabilityInput qaInput = new ConnectApi.QuestionAndAnswersCapabilityInput();
                    qaInput.bestAnswerId = each1.Id; ConnectApi.QuestionAndAnswersCapability qa = ConnectApi.QuestionAndAnswers.updateQuestionAndAnswers(System.Label.networkScope, each.Id, qaInput);    
                }
            }
            }
        }        
    }
    global void finish(Database.BatchableContext BC){
        
    }  
    global void execute(SchedulableContext sc){
        BatchUpdateFeedData bc = new BatchUpdateFeedData('');
        database.executeBatch(bc);
    }  
}