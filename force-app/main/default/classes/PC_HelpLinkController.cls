public class PC_HelpLinkController {
    @AuraEnabled
    public static string getContentversionId(string docId){
        return [select id,contentdocumentid from contentversion where contentdocumentid=:docId].id;
    }
   /* @AuraEnabled
    public static string getUrl(){
        String fileURL = URL.getFileFieldURL('087000000000123','AttachmentBody');
       
        return fileURL;
        
    }*/
}