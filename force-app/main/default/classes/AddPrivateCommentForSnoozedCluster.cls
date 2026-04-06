public without sharing class AddPrivateCommentForSnoozedCluster {
    @InvocableMethod
    public static void addComment(List<Id> caseIds){
        List<caseComment> caseCommentList = new List<caseComment>();
        for(Id cId : caseIds){
            caseComment cc = new caseComment();
            cc.ParentId = cId;
            cc.CommentBody = 'Alerts are snoozed for the related cluster';
            cc.IsPublished = false;
            caseCommentList.add(cc);
        }
        Insert caseCommentList;
    }
}