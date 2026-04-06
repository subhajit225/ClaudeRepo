@RestResource(urlMapping='/knowledgeapi/*')
global with sharing class KnowledgeAPIClass {
    @HttpPost
    global static List<response> createRecord(List<KnowledgeError> KnowledgeErrors){
        Map<String,String> errMap = new Map<String,String>();
        List<response> returnVal = new List<response>();
        
        categoryClass catCls = new categoryClass();
    	Map<String,String> categoryMap = catCls.getDescribeDataCategoryGroupStructureResults();
        
        for(KnowledgeError k:KnowledgeErrors){
            errMap.put(k.error_code,k.status);
        }
        Set<Id> alreadyDrafted = new Set<Id>();
        for(How_To__kav kb:[select PublishStatus, KnowledgeArticleId, Error_Code__c from How_To__kav where PublishStatus = 'Draft' AND Error_Code__c In:errMap.keySet()]){
            alreadyDrafted.add(kb.KnowledgeArticleId);
        }
        Map<string,How_To__kav> publishedArticleMap = new Map<string,How_To__kav>();
        for(How_To__kav kb:[select PublishStatus, KnowledgeArticleId, Error_Code__c from How_To__kav where Error_Code__c In:errMap.keySet()]){
            if(kb.PublishStatus == 'Online' && !alreadyDrafted.contains(kb.KnowledgeArticleId)){
                try{
                    String id = KbManagement.PublishingService.editOnlineArticle(kb.KnowledgeArticleId, false);    
                }catch(Exception e){
                
                }
            }
        }
        List<How_To__kav> publishedArticle = [select Id,Summary,PublishStatus,Error_Code__c,KnowledgeArticleId,Change_Log__c,Additional_Note__c,Cause__c,Solution_Detail__c from How_To__kav where (Error_Code__c In:errMap.keySet() AND PublishStatus='Draft')];
        for(How_To__kav kb:publishedArticle){
            publishedArticleMap.put(kb.Error_Code__c, kb);
        }
        List<How_To__kav> knowledgebaseCreateList = new List<How_To__kav>();
        List<How_To__kav> knowledgebaseModifyList = new List<How_To__kav>();
        for(KnowledgeError k:KnowledgeErrors){
            if(publishedArticleMap.containsKey(k.error_code)){
                How_To__kav article = new How_To__kav(
                    id=publishedArticleMap.get(k.error_code).Id,
                    Title = k.name,
                    IsVisibleInPkb = true,
                    IsVisibleInCsp = true,
                    IsVisibleInPrm = true,
                    Error_Code__c = k.error_code,
                    UrlName= k.error_code,
                    Cause__c = k.Cause,
                    Summary__c = k.Summary,
                    Resolution__c = k.Resolution,
                    Change_Log__c=publishedArticleMap.get(k.error_code).Change_Log__c +'<br>'+ k.Change_Log_entry
                );
                knowledgebaseModifyList.add(article);
            }
            else{
                How_To__kav article = new How_To__kav(
                    Title = k.name,
                    Error_Code__c = k.error_code,
                    UrlName= k.error_code,
                    Cause__c = k.Cause,
                    Summary__c = k.Summary,
                    Resolution__c = k.Resolution,
                    IsVisibleInPkb = true,
                    IsVisibleInCsp = true,
                    IsVisibleInPrm = true,
                    Change_Log__c=k.Change_Log_entry
                );
                knowledgebaseCreateList.add(article);
                returnVal.add(new response(article.Portal_URL__c, article));
            }
        }
        if(knowledgebaseModifyList.size()>0){
            for(How_To__kav kb:knowledgebaseModifyList){
                returnVal.add(new response(kb.Portal_URL__c, kb));
            }
        }
        insert knowledgebaseCreateList;
        update knowledgebaseModifyList;
        Set<Id> kbsIds = new Set<Id>();
        Map<String,Id> kbErrorMap = new  Map<String,Id>();
        for(How_To__kav hw : knowledgebaseCreateList){
            kbsIds.add(hw.id);
            kbErrorMap.put(hw.Error_Code__c,hw.id);
        }
        for(How_To__kav hw : knowledgebaseModifyList){
            kbsIds.add(hw.id);
            kbErrorMap.put(hw.Error_Code__c,hw.id);
        }
        Map<Id,List<String>> kbCatMap = new Map<Id,List<String>>();
        for(How_To__DataCategorySelection cat : [SELECT Id, ParentId, DataCategoryGroupName, DataCategoryName FROM How_To__DataCategorySelection where ParentId IN: kbsIds]){
            if(!kbCatMap.containsKey(cat.ParentId)){
                kbCatMap.put(cat.ParentId,new List<String>());
            }
            kbCatMap.get(cat.ParentId).add(cat.DataCategoryName);
        }
        List<How_To__DataCategorySelection> toInsert = new List<How_To__DataCategorySelection>();
        for(KnowledgeError kbRec :KnowledgeErrors){
            if(kbErrorMap.containsKey(kbRec.error_code) && kbRec.Category != null){
                Id kbId = kbErrorMap.get(kbRec.error_code);
                toInsert.add(new How_To__DataCategorySelection(
                    DataCategoryGroupName = 'Article',
                    DataCategoryName = categoryMap.get(kbRec.Category),
                    ParentId = kbId
                ));
            }
        }
        database.insert(toInsert,false);
        return returnVal;
    }
    @Httpget
    global static How_To__kav getArticle(){
        String urlCode  = RestContext.request.params.get('url_code');
        return [select Summary,Error_Code__c,Additional_Note__c,Cause__c,Solution_Detail__c,Change_Log__c from How_To__kav where UrlName =:urlCode];
    }
    @HttpPut
    global static List<response> draftRecord(List<KnowledgeError> KnowledgeErrors){
        Map<String,String> errMap = new Map<String,String>();
        List<response> returnVal = new List<response>();
        for(KnowledgeError k:KnowledgeErrors){
            errMap.put(k.error_code,k.status);
        }
        Map<string,How_To__kav> publishedArticleMap = new Map<string,How_To__kav>();
        for(How_To__kav kb:[select PublishStatus, KnowledgeArticleId, Error_Code__c from How_To__kav where Error_Code__c In:errMap.keySet()]){
            if(errMap.containsKey(kb.Error_Code__c) && errMap.get(kb.Error_Code__c) == 'Draft' && kb.PublishStatus == 'Online'){
                String id = KbManagement.PublishingService.editOnlineArticle(kb.KnowledgeArticleId, false);    
            }
            if(errMap.containsKey(kb.Error_Code__c) && errMap.get(kb.Error_Code__c) == 'Online' && kb.PublishStatus == 'Draft'){
                KbManagement.PublishingService.publishArticle(kb.KnowledgeArticleId, true);    
            }
        }
        
        return returnVal;
    }
    global class KnowledgeError{
        global String name;        
        global String error_code;
        global String status;
        global String Summary;  
        global String Cause;  
        global String Resolution; 
        global String Category;
        global string Change_Log_entry;
    }
    global class response{
        global string hyperlink; 
        global How_To__kav article;
        global response(string hyperlink, How_To__kav article){
            this.hyperlink = hyperlink;
            this.article = article;
        }
    }
}