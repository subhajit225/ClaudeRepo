public class OssnDocumentController {
    
    @AuraEnabled
    public static String getOssnDocument(String pageName){
        AWS_S3_Creds__c aws = AWS_S3_Creds__c.getInstance();
        String secretKey = aws.secretKey__c;
        String AccessKey = aws.AccessKey__c;
        
        List<OSSN_Documents__mdt> documentList=[SELECT id,Document_URL__c from OSSN_Documents__mdt where Label=:pageName ];
        if(documentList.size()==1){
            return  DocumentationController.getSignedUrlFromS3('rubrik-support-download', documentList[0].Document_URL__c, secretKey, AccessKey, 10)+'#toolbar=0&navpanes=0&scrollbar=0';
        }
        else{
            return null;
        }
    } 
}