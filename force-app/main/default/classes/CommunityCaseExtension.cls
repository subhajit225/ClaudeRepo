public without sharing class CommunityCaseExtension
{
    private ApexPages.StandardController standardController;
 
    public CommunityCaseExtension(ApexPages.StandardController standardController)
    {
        this.standardController = standardController;
        case record = (Case) standardController.getRecord();
        string subject = ApexPages.currentPage().getParameters().get('subject');
        string clusterID = ApexPages.currentPage().getParameters().get('clusterID');
        string ctype = ApexPages.currentPage().getParameters().get('type');
        if(subject!=null) record.Subject = EncodingUtil.urlDecode(subject, 'UTF-8');
        if(clusterID!=null) record.Cluster__c = clusterID;
        if(ctype=='upgrade') record.Type='Software';        
        
    }
 
    public PageReference closeCase()
    {
        // Apex code for handling record from a Detail page goes here
        Id recordId = standardController.getId();
        Case record = (Case) standardController.getRecord();
        record.Status = 'Customer Requested Close';

        update record;
        
        ApexPages.currentPage().getParameters().put('selfclose','true');
        return null;
    }
    
    public void refresh(){
    
      }

     public PageReference saveAndUpload() 
        {
            try{
            standardController.save();
            
            }catch(dmlexception e){
             system.debug('### exception:' + e);
            }  
        
            PageReference redirectPage = Page.UploadFile;
            redirectPage.setRedirect(true);
            redirectPage.getParameters().put('id',standardController.getId());
            return redirectPage;
            
            
        }
    
       //Get All CasesComments for the View Page
        public List<CaseComment> getComments() {
             Id cseID = standardController.getId();

          if (cseID != null) {
             string querystring='Select CommentBody,CreatedById,CreatedBy.Name,CreatedDate,Id,IsDeleted,IsPublished,LastModifiedById,LastModifiedDate,ParentId,SystemModstamp FROM CaseComment where IsPublished=true and ParentId = :cseID';
             querystring+=' order by SystemModstamp desc';
             List<CaseComment> cseCC = Database.query(querystring);
             return cseCC;
           } 
          return new List<CaseComment> ();
        }   
     
}