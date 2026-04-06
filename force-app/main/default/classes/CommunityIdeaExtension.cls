public without sharing class CommunityIdeaExtension
{
    private ApexPages.StandardController standardController;
 
    public CommunityIdeaExtension(ApexPages.StandardController standardController)
    {
        this.standardController = standardController;
        idea record = (idea) standardController.getRecord();
        if(!Test.isRunningTest()) record.CommunityId = system.label.ZoneID; //'09ae00000008OoL';
    }
 
    public PageReference cancel()
    {
        PageReference ideaHome = Page.IdeasHome;
        return ideaHome;
    }
    
    public PageReference save()
    {
        standardcontroller.save();
        PageReference ideaHome = Page.IdeasHome;
        ideaHome.getParameters().put('sort', 'recent');
        return ideaHome;
    }
    
}