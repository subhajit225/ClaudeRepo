trigger CommentsFromRbkSupport on FeedComment (after insert,before insert,before delete) {
    
    User u = [SELECT Id,Profile.Name,UserType FROM User WHERE Id =: userinfo.getUserId()];
    if(u.Profile.Name.contains('Community')){
        if(Trigger.isafter && Trigger.isinsert){
            
            CommentsFromRbkSupportHelper.afterInsert(Trigger.new , Trigger.newMap);
            
            if(u.UserType=='CspLitePortal'){
                FeedPostCommonHandler.feedCommentAfterInsertMethod(trigger.new);
            }
        }
        
        if(Trigger.isBefore && Trigger.isDelete){
            
            CommentsFromRbkSupportHelper.beforeDelete(Trigger.old);
            
        }
        
    }
}