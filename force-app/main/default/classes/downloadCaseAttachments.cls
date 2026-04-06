global with sharing class downloadCaseAttachments { 
	public String caseRecordId{get;set;} 
    public String fileName{get;set;} 
    public downloadCaseAttachments(ApexPages.StandardController con){
        caseRecordId = con.getId();
        Case cs = [select casenumber from  case where id =: caseRecordId];
        fileName = cs.casenumber+'---'+ System.now();
    }
    
    /*Function to check whether there are any attachments*/
    webservice static Boolean checkfile(String csId){
        system.debug('Id : '+csId);
        List<AttachedContentDocument> docList = new List<AttachedContentDocument>();
        for(Case cs:[SELECT Id,(select Id,ContentDocumentId from AttachedContentDocuments) from Case where Id =:csId]){
            for(AttachedContentDocument at:cs.AttachedContentDocuments){
                docList.add(at);
            }
        }
        System.debug('Documents :'+docList);

        if(docList.size()>0){
            return true;
        }
        else{
            return false;
        }
    }
    /*Function to fetch the attachments related to the Case*/
    @RemoteAction
    public static List<AttachmentWrapper> getAttachments(String caseId){
        List<Id> lstAttachments = new List<Id>();
        List <AttachmentWrapper> lstAttachmentWrapper = new List <AttachmentWrapper>();
        for(Case cs:[SELECT Id,(select Id,ContentDocumentId from AttachedContentDocuments) from Case where Id =:caseId]){
            for(AttachedContentDocument at:cs.AttachedContentDocuments){
                lstAttachments.add(at.ContentDocumentId);
            }
        }
        List<ContentVersion> docsList = [Select Id,VersionData,Title,FileExtension,Description from ContentVersion where ContentDocumentId In:lstAttachments];
        System.debug('List'+ docsList);
        for(ContentVersion att : docsList){
            AttachmentWrapper wrapper = new AttachmentWrapper();
            wrapper.attEncodedBody = EncodingUtil.base64Encode(att.VersionData);
            wrapper.attName = att.Title;
            System.debug(wrapper);
            lstAttachmentWrapper.add(wrapper);
        }
        for(Integer j=0;j<lstAttachmentWrapper.size();j++){
            Integer num = 1;
            for(Integer i=j+1;i<lstAttachmentWrapper.size();i++){
                
                if(lstAttachmentWrapper[i].attName == lstAttachmentWrapper[j].attName){
                    lstAttachmentWrapper[i].attName = lstAttachmentWrapper[i].attName.substringBefore('.') + '('+ num + ').'+docsList[i].FileExtension;
                    num++;
                }
            }
        }
        return lstAttachmentWrapper;
    }
    /*Wrapper Class which holds the Name and Body of Attachments*/
    public class AttachmentWrapper {
        public String attName {get; set;}
        public String attEncodedBody {get; set;}
    }
}