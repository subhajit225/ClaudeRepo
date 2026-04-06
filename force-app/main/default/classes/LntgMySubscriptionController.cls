public class LntgMySubscriptionController {
    
    @AuraEnabled
    public static  Map<String,List<SubscribedRecord>>  mySubscriptionController(){
        Boolean hasRecords = false;
        categoryClass cc = new categoryClass();
        Map<String,String> categoryMap = cc.getDescribeDataCategoryGroupStructureResultsSingle();
        Map<String,String>  subscribedMap = new Map<String,String>();
        Map<String,List<SubscribedRecord>> kbArticlesMap = new Map<String,List<SubscribedRecord>>();
        Map<id,Integer> newArticles = new Map<id,Integer>();
        for (AggregateResult ar : [Select KB_ID__c,count(Category_Label__c)  from Customer_Subscription__c where User__c =: UserInfo.getUserId() Group By KB_ID__c])  {
            if(!newArticles.containsKey((String)ar.get('KB_ID__c'))){
                newArticles.put((String)ar.get('KB_ID__c'),0);
            }
            newArticles.put((String)ar.get('KB_ID__c'),newArticles.get((String)ar.get('KB_ID__c'))+Integer.valueOf(ar.get('expr0')));
        }
        Map<id,String> kavNameMap = new Map<id,String>();
        Map<id,String>  articleNumberMap = new Map<id,String>();
        for(How_To__kav kav : [SELECT Id, KnowledgeArticleId,UrlName, Title FROM How_To__kav]){
            kavNameMap.put(kav.KnowledgeArticleId, kav.Title);
            articleNumberMap.put(kav.KnowledgeArticleId, kav.UrlName);
        }
        
        return kbArticlesMap;
    }
    @AuraEnabled
    public static Map<String,List<SubscribedRecord>> getSubscribedList(){
        Boolean hasRecords = false;
        categoryClass cc = new categoryClass();
        Map<String,String> categoryMap = cc.getDescribeDataCategoryGroupStructureResultsSingle();
        Map<String,String> subscribedMap = new Map<String,String>();
        Map<String,List<SubscribedRecord>> kbArticlesMap = new Map<String,List<SubscribedRecord>>();
        Map<id,Integer> newArticles = new Map<id,Integer>();
        for (AggregateResult ar : [Select KB_ID__c,count(Category_Label__c)  from Customer_Subscription__c where User__c =: UserInfo.getUserId() Group By KB_ID__c])  {
            if(!newArticles.containsKey((String)ar.get('KB_ID__c'))){
                newArticles.put((String)ar.get('KB_ID__c'),0);
            }
            newArticles.put((String)ar.get('KB_ID__c'),newArticles.get((String)ar.get('KB_ID__c'))+Integer.valueOf(ar.get('expr0')));
        }
        Map<id,String> kavNameMap = new Map<id,String>();
        Map<id,String> articleNumberMap = new Map<id,String>();
        for(How_To__kav kav : [SELECT Id, KnowledgeArticleId,UrlName, Title FROM How_To__kav]){
            kavNameMap.put(kav.KnowledgeArticleId, kav.Title);
            articleNumberMap.put(kav.KnowledgeArticleId, kav.UrlName);
        }
        for(Customer_Subscription__c cs : [Select id,Category_Name__c,Category_Label__c,Type__c,KB_ID__c from Customer_Subscription__c where User__c =: UserInfo.getUserId() ORDER BY Category_Label__c]){
            if(!subscribedMap.containsKey(cs.Category_Label__c)){
                subscribedMap.put(cs.Category_Label__c , categoryMap.get(cs.Category_Label__c));
            }
            if(cs.Type__c == 'Article' && cs.KB_ID__c != null){
                if(!kbArticlesMap.containsKey(categoryMap.get(cs.Category_Label__c))){
                    kbArticlesMap.put(categoryMap.get(cs.Category_Label__c) , new List<SubscribedRecord>());
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
                kbArticlesMap.get(categoryMap.get(cs.Category_Label__c) ).add(new SubscribedRecord(cs ,articleName ,urlName ,bt ));
            }
        }
        if(!kbArticlesMap.isEmpty() )
            hasRecords = true;
        return kbArticlesMap;
    }
    
    @AuraEnabled
    public static void DelRecord(id delRec){
        system.debug('chec------' + delRec);
        List<Customer_Subscription__c> cs = [Select id,Category_Name__c,Category_Label__c,Type__c,KB_ID__c from Customer_Subscription__c where KB_ID__c =: delRec And User__c =: UserInfo.getUserId() ];
        system.debug('c------' + cs);      
        Delete cs ;
    }
    
    
    public class SubscribedRecord {
        @AuraEnabled
        public String Name{get;set;}
        @AuraEnabled
        public String kbId{get;set;}
        @AuraEnabled
        public String urlName{get;set;}
        @AuraEnabled
        public Boolean multiCategory{get;set;}
        public SubscribedRecord(Customer_Subscription__c cs ,String name,String urlName, Boolean bt){
            this.Name = name;
            this.urlName = urlName;
            this.kbId = cs.KB_ID__c;
            this.multiCategory = bt; 
        }
    }
}