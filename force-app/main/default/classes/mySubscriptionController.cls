public class mySubscriptionController {
    public Map<String,String> subscribedMap{get;set;}   
    public Map<String,List<SubscribedRecord>> kbArticlesMap{get;set;}   
    public Map<id,Integer> newArticles;
    public Map<id,String> kavNameMap;
    public Boolean hasRecords{get;set;}   
    public Map<id,String> articleNumberMap;
    public Map<String,String> categoryMap = new Map<String,String>();
    
    public mySubscriptionController(){
        hasRecords = false;
        categoryClass cc = new categoryClass();
        categoryMap = cc.getDescribeDataCategoryGroupStructureResultsSingle();
        subscribedMap = new Map<String,String>();
        kbArticlesMap = new Map<String,List<SubscribedRecord>>();
        newArticles = new Map<id,Integer>();
        for (AggregateResult ar : [Select KB_ID__c,count(Category_Label__c)  from Customer_Subscription__c where User__c =: UserInfo.getUserId() Group By KB_ID__c])  {
            if(!newArticles.containsKey((String)ar.get('KB_ID__c'))){
                newArticles.put((String)ar.get('KB_ID__c'),0);
            }
            newArticles.put((String)ar.get('KB_ID__c'),newArticles.get((String)ar.get('KB_ID__c'))+Integer.valueOf(ar.get('expr0')));
        }
        kavNameMap = new Map<id,String>();
        articleNumberMap = new Map<id,String>();
        for(How_To__kav kav : [SELECT Id, KnowledgeArticleId,UrlName, Title FROM How_To__kav]){
            kavNameMap.put(kav.KnowledgeArticleId, kav.Title);
            articleNumberMap.put(kav.KnowledgeArticleId, kav.UrlName);
        }
        
        
    }
    
    public Map<String,List<SubscribedRecord>> getSubscribedList(){
        kbArticlesMap = new Map<String,List<SubscribedRecord>>();
        for(Customer_Subscription__c cs : [Select id,Category_Name__c,Category_Label__c,Type__c,KB_ID__c from Customer_Subscription__c where User__c =: UserInfo.getUserId()]){
            if(!subscribedMap.containsKey(cs.Category_Label__c)){
                subscribedMap.put(cs.Category_Label__c , categoryMap.get(cs.Category_Label__c));
            }
            if(cs.Type__c == 'Article' && cs.KB_ID__c != null){
                if(!kbArticlesMap.containsKey(cs.Category_Label__c)){
                    kbArticlesMap.put(cs.Category_Label__c , new List<SubscribedRecord>());
                }
                Boolean bt = false;
                if(newArticles.containsKey(cs.KB_ID__c) && newArticles.get(cs.KB_ID__c) > 1)
                    bt = true;
                
                String articleName = '';
                if(kavNameMap.containsKey(cs.KB_ID__c))
                    articleName = kavNameMap.get(cs.KB_ID__c);
                
                String urlName = '';
                if(articleNumberMap.containsKey(cs.KB_ID__c))
                    urlName = articleNumberMap.get(cs.KB_ID__c);
                kbArticlesMap.get(cs.Category_Label__c ).add(new SubscribedRecord(cs ,articleName ,urlName ,bt ));
            }
        }
        if(!kbArticlesMap.isEmpty() )
            hasRecords = true;
        return kbArticlesMap;
    }
    
    public Boolean deleteAll{get;set;}
    public String kbId{get;set;}
    public String articleCat{get;set;}
    public Integer rowNum{get;set;}

    public void unsSubscribeArticle(){
        deleteAll = false;
        List<String> catList = new List<String>();
        subscribedMap = new Map<String,String>();
        if(kbArticlesMap.containsKey(articleCat)){
            if(kbArticlesMap.get(articleCat).size() > 0){
                kbArticlesMap.get(articleCat).remove(rowNum-1);
            }
            if(kbArticlesMap.get(articleCat).size() == 0){
                kbArticlesMap.remove(articleCat);
            }
        }
        
        if(!deleteAll)
            catList.add(articleCat);
        List<Customer_Subscription__c> subscriptionList = new List<Customer_Subscription__c>();
        for(Customer_Subscription__c cs : [Select id,Category_Name__c,Category_Label__c,Type__c,KB_ID__c from Customer_Subscription__c where User__c =: UserInfo.getUserId()]){
            if(cs.KB_ID__c == kbId){
                if(cs.Category_Label__c == articleCat){
                    subscriptionList.add(cs);
                }
            }
        }
        delete subscriptionList;
        //rowNumgetSubscribedList();
        delete [Select id,Category_Name__c,KB_ID__c  from Customer_Subscription__c where Category_Name__c  IN: catList AND User__c =: UserInfo.getUserId()];
        
    }
    
   
    public class SubscribedRecord {
        public String Name{get;set;}
        public String kbId{get;set;}
        public String urlName{get;set;}
        public Boolean multiCategory{get;set;}
        public SubscribedRecord(Customer_Subscription__c cs ,String name,String urlName, Boolean bt){
            this.Name = name;
            this.urlName = urlName;
            this.kbId = cs.KB_ID__c;
            this.multiCategory = bt;
        }
    }
}