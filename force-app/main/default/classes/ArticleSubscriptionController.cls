public class ArticleSubscriptionController {
    public boolean isSubscribed{get;set;}
    public Customer_Subscription__c subscribeRecord{get;set;}
    public Map<String,String> categoryMap = new Map<String,String>();
    public List<Customer_Subscription__c> allSubscribedList = new List<Customer_Subscription__c>();
    public List<String> subscribedList = new List<String>();
    public Id recId;
    public List<String> CategoryList = new List<String>();
    public Set<String> catList;
    public Map<String,Integer> categoryCountMap;
    public List<How_To__DataCategorySelection> subList  = new List<How_To__DataCategorySelection>();
    
    public ArticleSubscriptionController(ApexPages.StandardController sc){
        isSubscribed = false;
        categoryCountMap = new Map<String,Integer>();
        recId = (id) sc.getId();
        subscribeRecord = new Customer_Subscription__c();
        categoryClass cc = new categoryClass();
        catList = new Set<String>();
        subList = [SELECT DataCategoryName,DataCategoryGroupName ,  ParentId,Parent.title,Parent.OwnerID,Parent.ArticleNumber,Parent.KnowledgeArticleId FROM How_To__DataCategorySelection WHERE Parent.KnowledgeArticleId != null AND Parent.isLatestVersion = true];
        for(How_To__DataCategorySelection ht : subList){
            if(ht.Parent.KnowledgeArticleId == recId && !catList.Contains(ht.DataCategoryName)){
                catList.add(ht.DataCategoryName);
            }
            if(!categoryCountMap.containsKey(ht.DataCategoryName)){
                categoryCountMap.put(ht.DataCategoryName,0);
            }categoryCountMap.put(ht.DataCategoryName,categoryCountMap.get(ht.DataCategoryName)+1);
        }
        categoryMap = cc.getDescribeDataCategoryGroupStructureResultsSingle();
        allSubscribedList = [Select id,Category_Name__c,KB_ID__c  from Customer_Subscription__c where KB_ID__c  =: recId AND User__c =: UserInfo.getUserId()];
        for(Customer_Subscription__c cs : allSubscribedList){
            CategoryList.add(cs.Category_Name__c);
            isSubscribed = true;
        }
    }
    
    public void editSubscription(){
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
                        newSubscriptionList.add(new Customer_Subscription__c( Type__c = 'Article' , User__c = UserInfo.getUserId() , KB_ID__c = recId  ,Category_Label__c = ht.DataCategoryName,Title__c = ht.Parent.title,Author__c = ht.Parent.OwnerID,Article_Number__c = ht.Parent.ArticleNumber));
                    }
                }                
            }
            
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
            newSubscriptionList.addAll(customerSubsList);
            insert newSubscriptionList;
        }        
    }
    
    
}