public class ArticlesInfoController {
    @AuraEnabled
    public Static Alldatawrapp getAllData(String articleStatus){
        Alldatawrapp adw = new Alldatawrapp();
        adw.kavsList = getArticles1(articleStatus);
        adw.softwaresList = getSoftwareVersions();
        adw.categoriesList = getAllCategoryGroups();
        return adw;
    }
    @AuraEnabled
    public static List<KavObj> getArticles1(String articleStatus){
        String fetchQuery = 'SELECT Id,ArticleNumber, KnowledgeArticleId, Title, PublishStatus, VersionNumber, LastModifiedDate, CreatedDate,CreatedBy.Name,Summary,Software_Versions__c,(SELECT DataCategoryName FROM DataCategorySelections) FROM How_To__kav WHERE PublishStatus=\''+articleStatus +'\'';
        System.debug('query'+fetchQuery);
        List<How_To__kav> articlesList = Database.query(fetchQuery);
        List<KavObj> customObjectList = new List<KavObj>();
        System.debug('articlesList'+articlesList);
        for(How_To__kav kav : articlesList){
            KavObj wrapper = new KavObj();
            wrapper.objId = kav.Id;
            wrapper.ArticleNumber = kav.ArticleNumber;
            wrapper.KnowledgeArticleId = kav.KnowledgeArticleId;
            wrapper.Title = kav.Title;
            wrapper.PublishStatus = kav.PublishStatus;
            wrapper.VersionNumber = kav.VersionNumber.format();
            wrapper.LastModifiedDate = kav.LastModifiedDate.format();
            wrapper.CreatedDate = kav.CreatedDate.format();
            wrapper.CreatedByName = kav.CreatedBy.Name;
            wrapper.Summary = kav.Summary;
            wrapper.SoftwareVersion = kav.Software_Versions__c;
            wrapper.categoryCount = kav.DataCategorySelections.size();
            wrapper.categoryList = new List<String>();
            for(How_To__DataCategorySelection dcs: kav.DataCategorySelections){
                system.debug('dcs.DataCategoryName'+dcs.DataCategoryName);
                wrapper.categoryList.add(dcs.DataCategoryName);
            }
            
            customObjectList.add(wrapper);
        }
        System.debug('wrapper'+customObjectList);
        return customObjectList;
    }
    
    @AuraEnabled
    public static List<categorywrapper> getAllCategoryGroups() {
        List<categorywrapper> wrapperList = new List<categorywrapper>();
        categoryClass CC = new categoryClass();
        Map<String,String> categories = new Map<String,String>();
        categories = CC.getDescribeDataCategoryGroupStructureResults();
        for(string each : categories.keyset()){
            if(each != 'All'){
                categorywrapper eachCateg = new categorywrapper();
                eachCateg.label = each;
                eachCateg.value = categories.get(each);
                wrapperList.add(eachCateg);
            }
        }
        return wrapperList;
    }
    
    @AuraEnabled
    public static List<KavObj> searchArticle(String articleNumber,String articleStatus){
        string tempInput = '*' + articleNumber.trim() + '*';
        String queryString = '';
        List<KavObj> returnList = new List<KavObj>();
        List<How_to__kav> returnList1 = new List<How_to__kav>();
        if(test.isRunningTest()){
            returnList1 = [Select id,ArticleNumber,KnowledgeArticleId,Title,URLName,LastModifiedDate,CreatedBy.Name,PublishStatus,CreatedDate,Summary,VersionNumber,Software_Versions__c From How_to__kav WHERE PublishStatus =: articleStatus];
        }
        else{
            queryString = 'FIND \'' + tempInput + '\' IN ALL FIELDS RETURNING How_To__kav (id,ArticleNumber,KnowledgeArticleId,Title,URLName,LastModifiedDate,CreatedBy.Name,PublishStatus,CreatedDate,Summary,VersionNumber,Software_Versions__c WHERE PublishStatus = \'' + articleStatus + '\')';
        }
        //system.debug('####'+queryString);
        //system.debug('####'+search.query(queryString));
        List<List <sObject>> searchList = new List<List <sObject>>();
        if(!test.isRunningTest()){
            searchList = search.query(queryString);
            returnList1 = searchList[0]; 
        }
        System.debug('returnList1---'+returnList1);
        Set<Id> kavIds = new Set<Id>();
        for(How_To__Kav kav : returnList1){
            kavIds.add(kav.Id);
        }
        Map<Id,How_To__Kav> kavMap = new Map<Id,How_To__Kav>([SELECT Id,ArticleNumber, KnowledgeArticleId, Title, PublishStatus, VersionNumber, LastModifiedDate, CreatedDate,CreatedBy.Name,Summary,Software_Versions__c,(SELECT DataCategoryName FROM DataCategorySelections) FROM How_To__kav WHERE Id IN : kavIds]);
        for(How_To__kav kav : kavMap.values()){
            KavObj wrapper = new KavObj();
            wrapper.objId = kav.Id;
            wrapper.ArticleNumber = kav.ArticleNumber;
            wrapper.KnowledgeArticleId = kav.KnowledgeArticleId;
            wrapper.Title = kav.Title;
            wrapper.PublishStatus = kav.PublishStatus;
            wrapper.VersionNumber = kav.VersionNumber.format();
            wrapper.LastModifiedDate = kav.LastModifiedDate.format();
            wrapper.CreatedDate = kav.CreatedDate.format();
            wrapper.CreatedByName = kav.CreatedBy.Name;
            wrapper.Summary = kav.Summary;
            wrapper.SoftwareVersion = kav.Software_Versions__c;
            wrapper.categoryCount = kav.DataCategorySelections.size();
            wrapper.categoryList = new List<String>();
            for(How_To__DataCategorySelection dcs: kav.DataCategorySelections){
                system.debug('dcs.DataCategoryName'+dcs.DataCategoryName);
                wrapper.categoryList.add(dcs.DataCategoryName);
            }
            returnList.add(wrapper);
        }
        return returnList;
        
    }
    
    
    //KbManagement class are calculated as DML Limit so need to check and fix on the client side
    //Max can be 150 DML
    @AuraEnabled
    public Static wrapper changeStatus1(List<KavObj> selectedArticles,String changeStatusTo,String showArticle){
        String errorMessage;
        Integer index = 0;
        Integer errorArticleIndex;
        Map<Id,Integer> indexMap = new Map<Id,Integer>();
        Set<Id> kavIds = new Set<Id>();
        List<String> articlesGotPublished = new List<String>();
        for(KavObj obj : selectedArticles){
            indexMap.put(obj.objId,index);
            index++;
        }
        for(KavObj obj : selectedArticles){
            if(obj.PublishStatus == 'Online' && changeStatusTo == 'Archived'){
                KbManagement.PublishingService.archiveOnlineArticle(obj.KnowledgeArticleId,null);
            }
            if(obj.PublishStatus == 'Online' && changeStatusTo == 'Draft'){   
                KbManagement.PublishingService.editOnlineArticle (obj.KnowledgeArticleId, false);
            }
            if(obj.PublishStatus == 'Draft' && changeStatusTo == 'Online'){
                try {
                    KbManagement.PublishingService.publishArticle(obj.KnowledgeArticleId, true);
                    articlesGotPublished.add(obj.ArticleNumber);
                }
                catch (Exception e) {
                    errorMessage = 'Something is wrong with article '+obj.ArticleNumber+' . Please remove it.';
                    errorArticleIndex = indexMap.get(obj.objId);
                    for(Integer i = errorArticleIndex;i < selectedArticles.size();i++){
                        Id kavId = selectedArticles.get(i).objId;
                        kavIds.add(kavId);
                    }
                    break;
                }   
            }
            if(obj.PublishStatus == 'Archived' && changeStatusTo == 'Online'){
                try {
                    KbManagement.PublishingService.publishArticle(obj.KnowledgeArticleId, true);
                    articlesGotPublished.add(obj.ArticleNumber);
                }
                catch (Exception e) {
                    errorMessage = 'Something is wrong with article '+obj.ArticleNumber+' . Please remove it.';
                    errorArticleIndex = indexMap.get(obj.objId);
                    for(Integer i = errorArticleIndex;i < selectedArticles.size();i++){
                        Id kavId = selectedArticles.get(i).objId;
                        kavIds.add(kavId);
                    }
                    break;
                }   
            }
            if(obj.PublishStatus == 'Archived' && changeStatusTo == 'Draft'){
                KbManagement.PublishingService.editArchivedArticle(obj.KnowledgeArticleId);
                
            }
        }
        wrapper wrap = new wrapper();
        wrap.kavsList = getArticles1(showArticle);
        wrap.errorMsg = errorMessage;
        wrap.toSelecteKavIds = kavIds;
        wrap.publishedArticles = articlesGotPublished;
        return wrap;
    }
    
    
    //Can we add check if the datacategory already exist . As it might create issue while adding with already existing
    @AuraEnabled
    public Static List<KavObj> changeCategory1(List<KavObj> selectedArticles,String[] changeCategoryTo,String showArticle){
        List<How_To__DataCategorySelection> dcsInsertList = new List<How_To__DataCategorySelection>();
        for(KavObj kav : selectedArticles){
            for(String category : changeCategoryTo){
                How_To__DataCategorySelection dcs = new How_To__DataCategorySelection();
                dcs.ParentId = kav.objId;
                dcs.DataCategoryGroupName = 'Article';
                dcs.DataCategoryName = category;
                dcsInsertList.add(dcs);
            }
        }
        System.debug('dcsInsertList : '+dcsInsertList);
        Insert dcsInsertList; 
        List<KavObj> kavList = getArticles1(showArticle);
        return kavList;
    }
    
    @AuraEnabled
    public Static List<softwareVerWrap> getSoftwareVersions(){
        List<softwareVerWrap> pickListValuesList= new List<softwareVerWrap>();
        Schema.DescribeFieldResult fieldResult = How_To__kav.Software_Versions__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(new softwareVerWrap(pickListVal.getLabel(),pickListVal.getValue()));
        }     
        return pickListValuesList;
    }
    
    
    //KbManagement class are calculated as DML Limit so need to check and fix on the client side
    //Max can be 150 DML
    @AuraEnabled
    public Static List<KavObj> setSoftwareVersion(List<KavObj> selectedArticles,String changeSoftTo,String showArticle){
        List<How_To__Kav> updatedKavList = new List<How_To__Kav>();
        List<Id> updatedOnlineKavIds = new List<Id>();
        for(KavObj kav: selectedArticles){
            if(kav.PublishStatus == 'Online'){
                Id kavId = KbManagement.PublishingService.editOnlineArticle (kav.KnowledgeArticleId, false);
                updatedOnlineKavIds.add(kavId);
            }
            else{
                How_To__Kav updateKav = new How_To__Kav();
                updateKav.Id = kav.objId;
                updateKav.Software_Versions__c = changeSoftTo;
                updatedKavList.add(updateKav);
            }
        }
        if(updatedOnlineKavIds.size()>0){
            for(Id kavId : updatedOnlineKavIds){
                How_To__Kav updateKav = new How_To__Kav();
                updateKav.Id = kavId;
                updateKav.Software_Versions__c = changeSoftTo;
                updatedKavList.add(updateKav);
            }
        }
        
        Update updatedKavList;
        if(updatedOnlineKavIds.size()>0){
            for(KavObj kav : selectedArticles){
                KbManagement.PublishingService.publishArticle(kav.KnowledgeArticleId, true);
            }
        }
        List<KavObj> kavList = getArticles1(showArticle);
        return kavList;
    }
    
    public class categorywrapper{
        @AuraEnabled
        public string label{get;set;}
        @AuraEnabled
        public string value{get;set;}
    }
    
    public class softwareVerWrap{
        @AuraEnabled
        public string label{get;set;}
        @AuraEnabled
        public string value{get;set;}
        public softwareVerWrap(String lab,String val){
            label = lab;
            value = val;
        }
    }
    
    public Class KavObj{
        @AuraEnabled
        public Id objId{get; set;}
        @AuraEnabled
        public String ArticleNumber{get; set;}
        @AuraEnabled
        public Id KnowledgeArticleId{get; set;}
        @AuraEnabled
        public String Title{get; set;}
        @AuraEnabled
        public String PublishStatus{get; set;}
        @AuraEnabled
        public String VersionNumber{get; set;}
        @AuraEnabled
        public String LastModifiedDate{get; set;}
        @AuraEnabled
        public String CreatedDate{get; set;}
        @AuraEnabled
        public String CreatedByName{get; set;}
        @AuraEnabled
        public String Summary {get; set;}
        @AuraEnabled
        public String SoftwareVersion {get; set;}
        @AuraEnabled
        public Integer categoryCount {get; set;}
        @AuraEnabled
        public List<String> categoryList {get; set;}
        
        public void KavObj(Id idOfObj,String ArticleNumb, Id KnowledgeArtId, String objTitle, String PubStatus, String VNumber, String LastModiDate, String CreDate,String CreByName,String Smry,String softVer,Integer count,List<String> categList){
            objId = idOfObj;
            ArticleNumber = ArticleNumb;
            KnowledgeArticleId =KnowledgeArtId;
            Title = objTitle;
            PublishStatus = PubStatus;
            VersionNumber = VNumber;
            LastModifiedDate =LastModiDate;
            CreatedDate = CreDate;
            CreatedByName = CreByName;
            Summary =  Smry;
            SoftwareVersion = softVer;
            categoryCount = count;
            categoryList = categList;
        }
    }
    
    public Class Alldatawrapp{
        @AuraEnabled
        public List<KavObj> kavsList{get; set;}
        @AuraEnabled
        public List<softwareVerWrap> softwaresList{get; set;}
        @AuraEnabled
        public List<categorywrapper> categoriesList{get; set;}
    }
    public Class wrapper{
        @AuraEnabled
        public List<KavObj> kavsList{get; set;}
        @AuraEnabled
        public String errorMsg{get; set;}
        @AuraEnabled
        public Set<Id> toSelecteKavIds{get; set;}
        @AuraEnabled
        public List<String> publishedArticles{get; set;}
    }
}