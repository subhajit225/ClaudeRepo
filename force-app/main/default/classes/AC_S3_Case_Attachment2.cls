global without sharing class  AC_S3_Case_Attachment2 {
    
    //public Rubrik_Case_Attachment__c case_atch;
    // private ApexPages.StandardController sc;    
    
    public string caseid {get; set;}
    public string caseNumber {get; set;}      
    public String parentId {get;set;}
    
    public AC_S3_Case_Attachment2(){
        
        parentId = ApexPages.currentPage().getParameters().get('ID');
        
        if(parentId ==null)
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'<font color=red>Case Attachment needs to be created from a Case</font>'));
        }
        else{            
            case theCase = [select id, CaseNumber from case where id =:parentId];
            
            system.debug(LoggingLevel.INFO,'caseNumber: '+ theCase);
            //this.sc = sc;
            system.debug(LoggingLevel.INFO,'case: '+ parentId);
            caseid = theCase.id;
            caseNumber = theCase.CaseNumber;    
        }
        

    }
    
	@RemoteAction
    global static void Customer_Case_Attach2 (string caseID, string fileSize, string fileName, string fileKey, string uploadStatus){
    //override the save button
    //create the Rubrik_Case_Attachment__c    
	   system.debug(LoggingLevel.INFO,'case ID: '+ caseID); 	
    
        /*
    //    system.debug('file size: '+ getupload_file_size());
      Rubrik_Case_Attachment__c ca = new Rubrik_Case_Attachment__c();
        ca.Case__c = caseID;
        ca.File_Name__c = fileName;
        ca.File_Path__c = fileKey;
        ca.Status__c = uploadStatus;
        //the filepath should be the full path to the file
        //s3 domain + bucket + caseNumber + randomNumber for security + fileName.
        ca.Attachment_Size_Bytes__c = integer.valueof(fileSize);
        */
        //SELECT Id, BodyLength, ParentId, Name, Description FROM Attachment
  
        String encodedContentsString = fileKey;            
        Attachment ca = new Attachment();
        ca.name = fileName;
        ca.Description = fileKey;
        ca.contentType = 'html';
        
  		ca.Body = Blob.valueOf(encodedContentsString);
  
  		ca.ParentId = caseID;   
        
        try{
        insert ca;        
        }catch(dmlexception e){
         system.debug('exception:' + e);
            //Todo - generate error log
        }        
        
    }

    public PageReference Attach_Success_Redirect(){
        PageReference casePage = new PageReference(parentId);
        return casePage;
    }


}