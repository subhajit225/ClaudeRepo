public without sharing class AttachmentUploadController 
{
    public String parentId {get;set;}
    public Attachment attach {get;set;}
   
    public AttachmentUploadController()
    {
        attach = new Attachment();
        parentId = ApexPages.currentPage().getParameters().get('ID');
    }
   
    public ApexPages.Pagereference upload()
    {
        
        attach.ParentId = parentId;
        insert attach;
        
         PageReference casePage = Page.CaseView;
         CasePage.getParameters().put('id', ApexPages.currentPage().getParameters().get('ID') );
         return casePage;
        
       // return new ApexPages.Standardcontroller(attach).view();   
    }
}