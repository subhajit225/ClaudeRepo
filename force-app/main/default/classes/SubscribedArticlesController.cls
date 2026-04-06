global class SubscribedArticlesController {
    global String currentUserId{get;set;}
    public Map<String,String> categoryMap = new Map<String,String>();
    public Map<Id,List<String>> kbNameMap{get;set;}
    public Map<Id,DateTime> kbDateMap{get;set;}
    
    public Map<String,List<How_To__kav>> getsubscribedMapval(){
        kbNameMap = new Map<Id,List<String>>();
        kbDateMap = new Map<Id,DateTime>();
        categoryClass cc = new categoryClass();
        categoryMap = cc.getDescribeDataCategoryGroupStructureResultsSingle();
        Set<id> kbIds = new Set<Id>();
        Set<id> oldKkbIds = new Set<Id>();
        Set<id> newKkbIds = new Set<Id>();
        for(KnowledgeArticle kb :[SELECT Id, IsDeleted, CreatedDate, CreatedById,LastPublishedDate FROM KnowledgeArticle where DAY_ONLY(LastPublishedDate) >=:  System.today().addDays(-7)]){
            kbIds.add(kb.Id);
            kbDateMap.put(kb.Id,kb.CreatedDate);
            if(kb.createdDate >= Date.today()){
                newKkbIds.add(kb.Id);
            }else{
                oldKkbIds.add(kb.Id);
            }
        }
        Set<id> subKbs = new Set<Id>();
        List<String> catName = new List<String>();
        Map<id,String> kbIdMap = new  Map<id,String>();
        for(Customer_Subscription__c kbSub : [SELECT Id, Type__c, KB_ID__c, User__c, Category_Name__c, Category_Label__c FROM Customer_Subscription__c WHERE ( KB_ID__c IN: kbIds OR  Type__c = 'Category') AND User__c=: currentUserId] ){
            if(kbSub.Type__c == 'Category'){
                catName.add(kbSub.Category_Label__c);
            }else{
                subKbs.add(kbSub.KB_ID__c);
                kbIdMap.put(kbSub.KB_ID__c,kbSub.Category_Label__c);
            }
        }
        Set<id> filteredKbIds = new Set<Id>();
        for(How_To__DataCategorySelection howto : [SELECT Id, ParentId,Parent.KnowledgeArticleId, DataCategoryGroupName, DataCategoryName FROM How_To__DataCategorySelection where (Parent.KnowledgeArticleId IN: kbIds OR ParentId  IN: kbIds) AND Parent.isVisibleInPkb = true]){
            if(catName.contains(howto.DataCategoryName) || (kbIdMap.containsKey(howto.Parent.KnowledgeArticleId) && kbIdMap.get(howto.Parent.KnowledgeArticleId) == howto.DataCategoryName)){
                if(catName.contains(howto.DataCategoryName) || subKbs.contains(howto.Parent.KnowledgeArticleId)){
                    filteredKbIds.add(howto.Parent.Id);
                }
                if(!kbNameMap.containsKey(howto.Parent.Id)){
                    kbNameMap.put(howto.Parent.Id , new List<String>());
                }
                if(categoryMap.containsKey(howto.DataCategoryName)){
                    kbNameMap.get(howto.Parent.Id).add(categoryMap.get(howto.DataCategoryName));
                }
            }
            
            
        }
        Map<String,List<How_To__kav>> kbMap = new Map<String,List<How_To__kav>>();
        for(How_To__kav kb :[SELECT Id, KnowledgeArticleId,Summary,urlname,FirstPublishedDate,LastPublishedDate, ArticleNumber , OwnerId, IsDeleted, PublishStatus, VersionNumber, IsLatestVersion, IsVisibleInApp, IsVisibleInPkb, IsVisibleInCsp, IsVisibleInPrm, CreatedDate,Title FROM How_To__kav  where ID IN: filteredKbIds AND IsLatestVersion = true]){
            if(newKkbIds.contains(kb.KnowledgeArticleId)){
                if(!kbMap.containsKey('New')){
                    kbMap.put('New',new List<How_To__kav>());
                }
                kbMap.get('New').add(kb);
            }else{
                if(!kbMap.containsKey('Old')){
                    kbMap.put('Old',new List<How_To__kav>());
                }
                kbMap.get('Old').add(kb);
            }
        }
        return kbMap;
    }
}