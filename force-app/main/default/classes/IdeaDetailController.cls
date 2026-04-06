public class IdeaDetailController{
    
    @Auraenabled
    public static Idea getIdeaDetails(String recordId){
        Id currentUserId = Userinfo.getUserId();
        Idea currentRecord = [select id,title,body,status,createddate,Categories,createdby.name,CreatedBy.CommunityNickname,NumComments,VoteScore,VoteTotal,(select id,CommentBody,createddate,createdby.name,CreatedBy.CommunityNickname from comments order by createddate desc),(select id,type from votes where createdbyid=:currentUserId) from idea where id =:recordId];
        
        return currentRecord;
    }
    
    @AuraEnabled
    public static Idea savecomment(String parentId, String body){
        IdeaComment comm = new IdeaComment(IdeaId=parentid,commentBody=body);
        insert comm;
        
        return getIdeaDetails(parentId);
    }
    
    @AuraEnabled
    public static Idea addVote(String parentId, String type){
        List<Vote> existingVote = [select id,type from vote where parentid =:parentid and createdbyid =:Userinfo.getUserId()];
        if(existingVote != null && !existingVote.isEmpty() && existingVote[0].type != type){
            try{
                delete existingVote;
            }catch(Exception e){}
        }
        
        Vote setVote = new Vote();
        setVote.Type = type;
        setVote.ParentId = parentId;
         try{
            insert setVote;
         }catch(Exception e){}
        return getIdeaDetails(parentId);
    }
}