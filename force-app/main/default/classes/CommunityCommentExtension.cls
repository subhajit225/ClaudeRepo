public class CommunityCommentExtension
{
    public CaseComment comment { get; set; }
    public Id caseID {get; set;}
    private final Case caseRec;


    public CommunityCommentExtension(ApexPages.StandardController stdController) 
    {
        caseId = stdController.getId();
        caseRec = (Case)stdController.getRecord();
        this.comment = new CaseComment(ParentId = stdController.getId(), ispublished=true);
    }

    public PageReference saveComment()
    {
        PageReference CasePage = Page.CaseView;
        CasePage.getParameters().put('id', caseID);
        insert comment;
        return CasePage;
    }

    public PageReference escalate()
    {   
        PageReference CasePage = Page.CaseView;
        CasePage.getParameters().put('id', caseID);
        insert comment;
        
        caseRec.isEscalated=true;
        update caseRec;
        
        return CasePage;
    }
    
    public PageReference reopen()
    {   
       PageReference CasePage = Page.CaseView;
       CasePage.getParameters().put('id', caseID);
       insert comment;
        
        caseRec.Status='Reopen';
        update caseRec;
        
        return CasePage;
    }


    public PageReference cancel()
    {
        PageReference CasePage = Page.CaseView;
        CasePage.getParameters().put('id', caseID);
        return CasePage;
    }


       //Get All CasesComments for the View Page
        public List<CaseComment> getComments() {

          if (caseId != null) {
             string querystring='Select CommentBody,CreatedById,CreatedBy.Name,CreatedDate,Id,IsDeleted,IsPublished,LastModifiedById,LastModifiedDate,ParentId,SystemModstamp FROM CaseComment where IsPublished=true and ParentId = :caseId';
             querystring+=' order by SystemModstamp desc';
             List<CaseComment> cseCC = Database.query(querystring);
             return cseCC;
           } 
          return new List<CaseComment> ();
        }   
    


}