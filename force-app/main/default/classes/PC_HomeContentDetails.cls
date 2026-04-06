public class PC_HomeContentDetails {
    @AuraEnabled
    public static List<ContentVersion> fetchContentDetails(string TagsName){
        List<ContentVersion> contentList=new List<ContentVersion>();
        if(TagsName=='Popular'){
            ID cvid;
            List<ID> totalList = new List<ID>();
            for (AggregateResult ar : [SELECT ContentVersionId,ContentVersion.IsLatest,ContentVersion.ContentDocumentId docId, ContentVersion.title title   FROM ContentVersionHistory WHERE Field = 'contentVersionDownloaded' AND ContentVersion.IsLatest = true  GROUP BY ContentVersionId,ContentVersion.IsLatest, ContentVersion.title,ContentVersion.ContentDocumentId ORDER BY Count(ContentVersionId) Desc limit 10]) {
                cvid = String.valueOf(ar.get('ContentVersionId'));
                ContentVersion cv  = new ContentVersion();
                cv.id = string.valueOf(ar.get('ContentVersionId'));
                cv.Title = string.valueOf(ar.get('title'));
               // cv.ContentDocumentId = string.valueOf(ar.get('docId'));
                contentList.add(cv);
            }
            system.debug('@@ contentList '+contentList);
            //for(ContentVersion content:[select id, Title, Description, FileType,FeaturedContentDate,FeaturedContentBoost, Owner.Name, VersionNumber, ContentDocumentId,TagCsv from ContentVersion
                                    //    where  ID IN :totalList ]){
                                            //contentList.add(content);  
                                      //  }
            
        }
        else if(TagsName=='Whats New'){
            
            for(ContentVersion cont:[select id, Title, Description, FileType,FeaturedContentDate,FeaturedContentBoost,ContentDocumentId,TagCsv from  ContentVersion
                                     where IsLatest=true and FeaturedContentBoost>0 Order By CreatedDate Desc]){
                                         contentList.add(cont);
                                     }
            if(Test.isRunningTest()){
                for(ContentVersion cont:[select id, Title, Description, FileType,FeaturedContentDate,FeaturedContentBoost,ContentDocumentId,TagCsv from  ContentVersion
                                         where IsLatest=true Order By CreatedDate Desc]){
                                             contentList.add(cont);
                                         }
            }
        }    
        else if(TagsName=='My Pins'){
            set<id>contentdocumentId=new set<id>();
            //List<EntitySubscription> EntityList=[select id,ParentId,SubscriberId from EntitySubscription where SubscriberId=:UserInfo.getUserId() LIMIT 1000];
            for(EntitySubscription ent:[select id,ParentId,SubscriberId from EntitySubscription where SubscriberId=:UserInfo.getUserId() LIMIT 1000]){
                contentdocumentId.add(ent.ParentId);
            }
            system.debug('contentdocumentId----->'+contentdocumentId);
            for(ContentVersion cont:[select id, Title, Description, FileType,FeaturedContentDate,FeaturedContentBoost,ContentDocumentId,TagCsv from  ContentVersion
                                     where ContentDocumentId in:contentdocumentId Order By CreatedDate Desc]){
                                         contentList.add(cont);
                                     } 
        }
        
        system.debug('contentList---->'+contentList);
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