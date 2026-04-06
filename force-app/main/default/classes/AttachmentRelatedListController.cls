public class AttachmentRelatedListController {
    
    public List<Attachment> attachments{get;set;} 
    
    public Assist_Request__c arRec {get;set;} 
    
    //Constructor 
    
    public AttachmentRelatedListController(ApexPages.StandardController controller) { 
        arRec = (Assist_Request__c)controller.getRecord();
        Id caseRecId = [Select Id,Case__c from Assist_Request__c where Id=:arRec.Id].Case__c;
        attachments = new List<Attachment>();
        for(Case cs:[SELECT Id,(select Id,Name,LastModifiedById,CreatedById from Attachments) from Case where Id =:caseRecId]){
            System.debug('case '+cs.AttachedContentDocuments.size());
            for(Attachment at:cs.Attachments){
                System.debug('attachment'+at);
                attachments.add(at);
            }
        }    
    } 
    
    
    public pageReference viewAtt(){  

        String attId = Apexpages.currentpage().getParameters().get('attId');  

        pageReference pageRef = new pageReference('/servlet/servlet.FileDownload?file=' + attId );  

        return pageRef;  

    }  
    
    
}