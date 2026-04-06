public class IdeaCommentExtension
{
    public IdeaComment comment { get; set; }
    public Id IdeaID {get; set;}

    public IdeaCommentExtension(ApexPages.StandardController stdController) 
    {
        IdeaId = stdController.getId();
        this.comment = new IdeaComment(IdeaId = stdController.getId());
    }

    public PageReference saveComment()
    {
        insert comment;
        PageReference IdeaPage = Page.IdeasHome;
        //IdeaPage.getParameters().put('id', IdeaID);
        return IdeaPage;
    }

    public PageReference cancel()
    {
        PageReference Ideahome = Page.IdeasHome;
        return Ideahome;
    }

}