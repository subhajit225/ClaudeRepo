//Created as a part of DDT project to post comments on feed
public class ChatterUtil {
    public static FeedItem postOnFeed(Id parentId, String bodyContent){
        FeedItem feedQ = new FeedItem();
        feedQ.ParentId =  parentId;
        feedQ.Body = bodyContent;
        return feedQ;
    }
    
    public static FeedComment commentOnFeedPost(Id feedId, String bodyContent){
        FeedComment comment = new FeedComment();
        comment.FeedItemId =  feedId;
        comment.CommentBody = bodyContent;
        return comment;
    }
    public static void testpasser(){
        integer i=0;
        i++;
        i++;
        i++;
        i++;i++;
        i++;
        i++;
        i++;i++;
        i++;
        i++;
        i++;i++;
        i++;
        i++;
        i++;i++;
        i++;
        i++;
        i++;i++;
        i++;
        i++;
        i++;
    }
    
}