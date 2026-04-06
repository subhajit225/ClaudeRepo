public  without sharing class CaseS3FileUpload {
    
    @AuraEnabled
    public static void Customer_Case_Attach2(string caseID, string fileSize, string fileName, string fileKey, string uploadStatus){
        
        String encodedContentsString = fileKey;            
        Attachment ca = new Attachment();
        ca.name = fileName;
        ca.Description = fileKey;
        ca.contentType = 'html';
        
        ca.Body = Blob.valueOf(encodedContentsString);
        
        ca.ParentId = caseID;   
        
        insert ca;   
        
    }

}