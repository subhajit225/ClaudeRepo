public class PC_MarketContentDetails {
 @AuraEnabled
    public static List<ContentVersion> fetchContentDetails(){
        List<ContentVersion> contentList=new List<ContentVersion>();
        
            for(ContentVersion content:[select id, Title, Description, FileType,FeaturedContentDate,FeaturedContentBoost, Owner.Name, VersionNumber, ContentDocumentId,TagCsv from ContentVersion
                                        Order By CreatedDate Desc LIMIT 1 ]){
                                         contentList.add(content);
             }
        
        return contentList;
    }
    @AuraEnabled
    public static Id PreviewContentDetails(string ContentIds){
        Id contentdocId;
        List<contentversion> contentList=new List<contentversion>();
        contentList= [select id,contentDocumentId from contentversion  where Id=:ContentIds];
        if(contentList.size()>0){
            contentdocId=contentList[0].contentDocumentId;
        }
            return contentdocId;
           
    }

}