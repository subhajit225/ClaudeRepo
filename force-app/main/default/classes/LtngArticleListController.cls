public without sharing class LtngArticleListController {
    public static string kavSql ='SELECT Id, knowledgearticleid, Title,Articlenumber,urlName ,Summary, FirstPublishedDate, LastPublishedDate,ArticleArchivedDate, LastmodifiedDate FROM KnowledgeArticleVersion ';
    
    
    @AuraEnabled
    Public static Boolean checkIfSubscribed(String label){
        //CS21-1383 - Modified the below code to fix this bug
        boolean isSubscribed= false;
        Map<String,String> categoryMap = new categoryClass().getDescribeDataCategoryGroupStructureResultsSingle();

        if(label == 'All'){
            List<Customer_Subscription__c> allSubscribedList = [Select id from Customer_Subscription__c where Type__c = 'Category' AND User__c =: UserInfo.getUserId()];
            if(allSubscribedList.size() == categoryMap.keyset().size()){
                isSubscribed = true;
            }
        }else{
            List<Customer_Subscription__c> sublist = [Select id from Customer_Subscription__c where Type__c = 'Category' AND User__c =: UserInfo.getUserId() AND Category_Label__c = : label];
            if(!sublist.isEmpty()){
                isSubscribed = true;
            }
        }
        return isSubscribed;
    }
    
    @AuraEnabled
    Public static articleInfo getSubscription(String recId){ 
        List<String> linkedCategory = new List<String>();
        Boolean isSubscribed = false;
        categoryClass cc = new categoryClass();
        Map<String,String> categoryMap = cc.getDescribeDataCategoryGroupStructureResultsSingle();
        for(How_To__DataCategorySelection ds : [SELECT id,DataCategoryName from How_To__DataCategorySelection WHERE ParentID =:recId]){
            if(categoryMap.containsKey(ds.DataCategoryName))
            linkedCategory.add(categoryMap.get(ds.DataCategoryName));
        }
        How_To__kav ht = [SELECT Id, KnowledgeArticleId FROM How_To__kav where id =: recId];
        for(Customer_Subscription__c cs : [Select id,Category_Name__c,KB_ID__c  from Customer_Subscription__c where KB_ID__c  =: ht.KnowledgeArticleId  AND User__c =: UserInfo.getUserId()]){
            isSubscribed = true;
        }
        return new articleInfo(isSubscribed,linkedCategory);
    }
    
    @AuraEnabled
    Public static Boolean deleteSubscription(String recId,Boolean isSubscribed){ 
        Map<String,Integer> categoryCountMap = new Map<String,Integer>();
        Customer_Subscription__c subscribeRecord = new Customer_Subscription__c();
        categoryClass cc = new categoryClass();
        Set<String> catList = new Set<String>();
         recId = [SELECT Id, KnowledgeArticleId FROM How_To__kav where id =: recId].KnowledgeArticleId ;
         List<How_To__DataCategorySelection> subList = [SELECT DataCategoryName,DataCategoryGroupName ,  ParentId,Parent.title,Parent.OwnerID,Parent.ArticleNumber,Parent.KnowledgeArticleId FROM How_To__DataCategorySelection WHERE Parent.KnowledgeArticleId != null AND Parent.isLatestVersion = true];
        for(How_To__DataCategorySelection ht : subList){
            if(ht.Parent.KnowledgeArticleId == recId && !catList.Contains(ht.DataCategoryName)){
                catList.add(ht.DataCategoryName);
            }
            if(!categoryCountMap.containsKey(ht.DataCategoryName)){
                categoryCountMap.put(ht.DataCategoryName,0);
            }categoryCountMap.put(ht.DataCategoryName,categoryCountMap.get(ht.DataCategoryName)+1);
        }
        Map<String,String> categoryMap = cc.getDescribeDataCategoryGroupStructureResultsSingle();
         List<Customer_Subscription__c> allSubscribedList = new List<Customer_Subscription__c>();
         List<String> CategoryList = new List<String>();
        allSubscribedList = [Select id,Category_Name__c,KB_ID__c  from Customer_Subscription__c where KB_ID__c  =: recId AND User__c =: UserInfo.getUserId()];
        for(Customer_Subscription__c cs : allSubscribedList){
            CategoryList.add(cs.Category_Name__c);
        }
        
         if(isSubscribed){
            isSubscribed =false;
            delete allSubscribedList;
            delete  [Select id,Category_Name__c,KB_ID__c  from Customer_Subscription__c where Category_Name__c  IN: catList AND User__c =: UserInfo.getUserId()];
            allSubscribedList  = new List<Customer_Subscription__c>();
        }else{
            isSubscribed = true;
            List<Customer_Subscription__c> newSubscriptionList = new List<Customer_Subscription__c>();
            Map<String,integer> newArticles = new Map<String,integer>();
            for(How_To__DataCategorySelection ht : subList){
                If(ht.Parent.KnowledgeArticleId == recId){
                    if(!newArticles.containsKey(ht.DataCategoryName)){
                        newArticles.put(ht.DataCategoryName,0);
                    }newArticles.put(ht.DataCategoryName,newArticles.get(ht.DataCategoryName)+1);
                    if(!CategoryList.Contains(ht.DataCategoryName)){
                        CategoryList.add(ht.DataCategoryName);
                        newSubscriptionList.add(new Customer_Subscription__c( Type__c = 'Article' , User__c = UserInfo.getUserId() , KB_ID__c = recId  ,Category_Label__c = ht.DataCategoryName,Title__c = ht.Parent.title,Article_Number__c = ht.Parent.ArticleNumber));
                    }
                }                
            }
            System.debug(newSubscriptionList);
            allSubscribedList.addAll(newSubscriptionList);
            for (AggregateResult ar : [Select Category_Label__c,count(KB_ID__c)  from Customer_Subscription__c where User__c =: UserInfo.getUserId() Group By Category_Label__c])  {
                if(!newArticles.containsKey((String)ar.get('Category_Label__c'))){
                    newArticles.put((String)ar.get('Category_Label__c'),Integer.valueOf(ar.get('expr0')));
                }
                newArticles.put((String)ar.get('Category_Label__c'),newArticles.get((String)ar.get('Category_Label__c'))+Integer.valueOf(ar.get('expr0')));
            }
            List<Customer_Subscription__c> customerSubsList = new List<Customer_Subscription__c>();
            for(Customer_Subscription__c csn : newSubscriptionList){
                System.debug('to'+categoryCountMap.get(csn.Category_Label__c) +'---'+  newArticles.get(csn.Category_Label__c));
                if(categoryCountMap.get(csn.Category_Label__c) ==  newArticles.get(csn.Category_Label__c)){
                    customerSubsList.add(new Customer_Subscription__c(Category_Name__c = csn.Category_Label__c , Type__c = 'Category' , User__c = UserInfo.getUserId() ,Category_Label__c = csn.Category_Label__c)); 

                }
            }
            System.debug(newArticles);
            System.debug(customerSubsList);
            newSubscriptionList.addAll(customerSubsList);
            System.debug(newSubscriptionList);
            insert newSubscriptionList;
            
        }        
        return isSubscribed;
    }
    
    
   /*@AuraEnabled
    Public static Boolean DeleSubscription(String label){
        Map<String,String> categoryMap = cc.getDescribeDataCategoryGroupStructureResultsSingle();
        List<String> subscribedCategory = new List<String>();
         Customer_Subscription__c subscribeRecord = new Customer_Subscription__c ();
        List<Customer_Subscription__c> allSubscribedList = new List<Customer_Subscription__c>();
        List<String> subscribedList = new List<String>();
        boolean isSubscribed= false;
        if(isSubscribed){
            if(label == 'All'){
                delete allSubscribedList;
                delete [Select Category_Name__c,KB_ID__c,Category_Label__c,Type__c,Id from Customer_Subscription__c where User__c =: UserInfo.getUserId()];
                isSubscribed =false;
            }else{
                isSubscribed =false;
                delete subscribeRecord;
                delete [Select Category_Name__c,KB_ID__c,Category_Label__c,Type__c,Id from Customer_Subscription__c where Category_Label__c =: label and User__c =: UserInfo.getUserId()];
            }
        }else{
            if(label == 'All'){
                List<Customer_Subscription__c> newSubscriptionList = new List<Customer_Subscription__c>();
                isSubscribed = true;
                for(String lab : categoryMap.keySet()){
                    if(lab != 'All' && !subscribedList.contains(lab)){
                        subscribedCategory.add(lab);
                        newSubscriptionList.add(new Customer_Subscription__c(Category_Name__c = categoryMap.get(lab) , Type__c = 'Category' , User__c = UserInfo.getUserId() ,Category_Label__c = lab));
                        
                    }
                }
                insert newSubscriptionList;
            }else{
                isSubscribed = true;
                subscribedCategory.add(label);
                subscribeRecord = new Customer_Subscription__c(Category_Name__c = categoryMap.get(label) , Type__c = 'Category' , User__c = UserInfo.getUserId() ,Category_Label__c = label);
                insert subscribeRecord;
            }
          
        }   
         return isSubscribed;
    }*/
    
    @AuraEnabled
    Public static Boolean editSubscription(String label, boolean isSubscribed){
        //CS21-1383 - Modified the below code to fix this bug
        Map<String,String> categoryMap = new categoryClass().getDescribeDataCategoryGroupStructureResultsSingle();
        List<String> subscribedCategory = new List<String>();
        Customer_Subscription__c subscribeRecord = new Customer_Subscription__c ();
        List<Customer_Subscription__c> allSubscribedList = new List<Customer_Subscription__c>();
        List<String> subscribedList = new List<String>();

        if(label == 'All'){
            allSubscribedList = [Select id,Category_Name__c,Category_Label__c from Customer_Subscription__c where Type__c = 'Category' AND User__c =: UserInfo.getUserId()];
            for(Customer_Subscription__c sub : allSubscribedList){
                subscribedList.add(sub.Category_Label__c);
            }
            if(allSubscribedList.size() == categoryMap.keyset().size()){
                isSubscribed = true;
            }
        }else{
            List<Customer_Subscription__c> sublist = [Select id,Category_Name__c from Customer_Subscription__c where Type__c = 'Category' AND User__c =: UserInfo.getUserId() AND Category_Label__c = : label];
            if(!sublist.isEmpty()){
                isSubscribed = true;
            }
        }

        if(isSubscribed != null && isSubscribed){
            if(label == 'All'){
                delete [Select Id from Customer_Subscription__c where User__c =: UserInfo.getUserId()];
                isSubscribed =false;
            }else{
                isSubscribed =false;
                delete [Select Id from Customer_Subscription__c where Category_Label__c =: label and User__c =: UserInfo.getUserId()];
            }
        }else{
            if(label == 'All'){
                List<Customer_Subscription__c> newSubscriptionList = new List<Customer_Subscription__c>();
                isSubscribed = true;
                for(String lab : categoryMap.keySet()){
                    if(!subscribedList.contains(lab)){
                        subscribedCategory.add(lab);
                        newSubscriptionList.add(new Customer_Subscription__c(Category_Name__c = categoryMap.get(lab) , Type__c = 'Category' , User__c = UserInfo.getUserId() ,Category_Label__c = lab));
                        
                    }
                }
                insert newSubscriptionList;
            }else{
                isSubscribed = true;
                subscribedCategory.add(label);
                subscribeRecord = new Customer_Subscription__c(Category_Name__c = categoryMap.get(label) , Type__c = 'Category' , User__c = UserInfo.getUserId() ,Category_Label__c = label);
                insert subscribeRecord;
            }
            List<Customer_Subscription__c> newSubscriptionList = new List<Customer_Subscription__c>();
            Set<Id> subKbId = new Set<Id>();
            Map<String,List<String>> subCategoryMap = new Map<String,List<String>>();
            for(Customer_Subscription__c cs : [Select id,Category_Name__c,Category_Label__c ,KB_ID__c from Customer_Subscription__c where  User__c =: UserInfo.getUserId()]){
                if(!subCategoryMap.containsKey(cs.KB_ID__c)){
                    subCategoryMap.put(cs.KB_ID__c, new List<String>());
                }
                subCategoryMap.get(cs.KB_ID__c).add(cs.Category_Label__c);
            }
            List<How_To__DataCategorySelection> subList  = [SELECT Parent.KnowledgeArticleId,DataCategoryName,DataCategoryGroupName , ParentId,Parent.title,Parent.OwnerID,Parent.ArticleNumber FROM How_To__DataCategorySelection WHERE Parent.KnowledgeArticleId != null AND  Parent.isLatestVersion = true];
            for(How_To__DataCategorySelection ht : subList){
                if(subscribedCategory.contains(ht.DataCategoryName)){
                    if(subCategoryMap.containsKey(ht.Parent.KnowledgeArticleId) && subCategoryMap.get(ht.Parent.KnowledgeArticleId).contains(ht.DataCategoryName)){
                        
                    }else{
                        newSubscriptionList.add(new Customer_Subscription__c( Type__c = 'Article',Title__c = ht.Parent.title,/*Author__c = ht.Parent.OwnerID,*/Article_Number__c = ht.Parent.ArticleNumber,  User__c = UserInfo.getUserId() , KB_ID__c = ht.Parent.KnowledgeArticleId  ,Category_Label__c = ht.DataCategoryName));
                        if(!subCategoryMap.containsKey(ht.Parent.KnowledgeArticleId)){
                            subCategoryMap.put(ht.Parent.KnowledgeArticleId, new List<String>());
                        }
                        subCategoryMap.get(ht.Parent.KnowledgeArticleId).add(ht.DataCategoryName);
                    }
                }
            }
            if(!newSubscriptionList.isEmpty()){
                insert newSubscriptionList;
            }
        }
        return isSubscribed;
    }
    @AuraEnabled
    public static void createKbSubscription(){
        List<String> subscribedCategory = new List<String>();
        List<Customer_Subscription__c> newSubscriptionList = new List<Customer_Subscription__c>();
        Set<Id> subKbId = new Set<Id>();
        Map<String,List<String>> subCategoryMap = new Map<String,List<String>>();
        for(Customer_Subscription__c cs : [Select id,Category_Name__c,Category_Label__c ,KB_ID__c from Customer_Subscription__c where  User__c =: UserInfo.getUserId()]){
            if(!subCategoryMap.containsKey(cs.KB_ID__c)){
                subCategoryMap.put(cs.KB_ID__c, new List<String>());
            }
            subCategoryMap.get(cs.KB_ID__c).add(cs.Category_Label__c);
        }
        List<How_To__DataCategorySelection> subList  = [SELECT Parent.KnowledgeArticleId,DataCategoryName,DataCategoryGroupName , ParentId,Parent.title,Parent.OwnerID,Parent.ArticleNumber FROM How_To__DataCategorySelection WHERE Parent.KnowledgeArticleId != null AND  Parent.isLatestVersion = true];
        for(How_To__DataCategorySelection ht : subList){
            if(subscribedCategory.contains(ht.DataCategoryName)){
                if(subCategoryMap.containsKey(ht.Parent.KnowledgeArticleId) && subCategoryMap.get(ht.Parent.KnowledgeArticleId).contains(ht.DataCategoryName)){
                    
                }else{
                    newSubscriptionList.add(new Customer_Subscription__c( Type__c = 'Article',Title__c = ht.Parent.title,/*Author__c = ht.Parent.OwnerID,*/Article_Number__c = ht.Parent.ArticleNumber,  User__c = UserInfo.getUserId() , KB_ID__c = ht.Parent.KnowledgeArticleId  ,Category_Label__c = ht.DataCategoryName));
                    if(!subCategoryMap.containsKey(ht.Parent.KnowledgeArticleId)){
                        subCategoryMap.put(ht.Parent.KnowledgeArticleId, new List<String>());
                    }
                    subCategoryMap.get(ht.Parent.KnowledgeArticleId).add(ht.DataCategoryName);
                }
            }
        }
        insert newSubscriptionList;
    }
    
    @AuraEnabled
    public static list<ArticleWrapper> getArticleList(string pageNumber,String pageSize , string category){
        system.debug('psize====' + pageSize);
        system.debug('pageNumber====' + pageNumber);
        system.debug('category====' + category);
        Integer pSize = Integer.valueOf(pageSize);
        Integer pNumber = Integer.valueof(pageNumber);
        Integer offset = (pNumber - 1) * pSize;
        Integer recordEnd = pSize * pNumber;
        Integer totalRecords;
        string queryLimit = '';
        string  queryOffset = '';
        string fetchKavSoql ='';
        string categsql = '';
        category =category.replaceAll(' ','_');
        list<ArticleWrapper> ArticleWrapperlist = new list<ArticleWrapper>( );
        List<KnowledgeArticleVersion> kavlist = new List <KnowledgeArticleVersion>();
        String queryAll = queryLimit;
        if(pageSize != null && pageSize != ''){
            queryLimit = ' LIMIT '+ pageSize  ; 
        }
        if(pageNumber != null && pageNumber != ''){
            queryOffset = ' offset '+ offset  ; 
        }
        if(Category!='All' && Category!= null && Category!='' && Category!='\'\''){
            CategSql = ' WITH DATA CATEGORY Article__c AT  ('+ Category+'__c)';
        }
        queryAll = kavSql+categsql;
        system.debug('cate==='+ CategSql);  
        fetchKavSoql = kavSql+categsql;
        Integer totalRec = database.query(queryAll).size();
        system.debug('fetchKavSoql=======' + fetchKavSoql);
        kavlist = database.query(fetchKavSoql);
        Map<id,KnowledgeArticleVersion> kbMap = new Map<id,KnowledgeArticleVersion>();
        for(KnowledgeArticleVersion k : kavList){
            kbMap.put(k.KnowledgeArticleID,k);
        }
        for(How_To__ViewStat views : [SELECT Id,parentId, ViewCount FROM How_To__ViewStat where ParentId IN: kbMap.keySet() and channel = 'AllChannels']){
            articleWrapper ac = new articleWrapper();
            ac.kav = kbMap.get(views.parentId);
            ac.viewCount = views.ViewCount;
            ac.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
            ac.totalcount = totalRec ;
            system.debug('@@@@'+ac);
            ArticleWrapperlist.add(ac);
        }
        //system.debug('kavlist===='+  kavlist);
        /*for(KnowledgeArticleVersion kv:kavlist){
            ArticleWrapper wrap = new ArticleWrapper();
            wrap.kav=kv;
            wrap.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
            wrap.totalcount = totalRec ;
            ArticleWrapperlist.add(wrap);
        }*/
        
        return ArticleWrapperlist;
    }
    
    public class ArticleWrapper{
        @AuraEnabled public KnowledgeArticleVersion kav;
        @AuraEnabled
        public Integer recordStart {get;set;}
        @AuraEnabled 
        public Integer recordEnd {get;set;}
        @AuraEnabled 
        public Integer totalcount{get;set;}
        @AuraEnabled
        public Integer viewCount{get;set;}
        
        
    }
    
    public class articleInfo{
        @AuraEnabled public Boolean isSubscribed{get;set;}
        @AuraEnabled public List<String> linkedCategory{get;set;}
        public articleInfo(Boolean isSubscribed,List<String> linkedCategory){
            this.isSubscribed = isSubscribed;
            this.linkedCategory = linkedCategory;
        }
    } 
}