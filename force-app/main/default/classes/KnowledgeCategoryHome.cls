public class KnowledgeCategoryHome{
    
    //Existing code
     public DataCategoryGroupInfo[] getDataCategoryGroupInfo() {
        return DataCategoryUtil.getInstance().getAllCategoryGroups();
    }
    
    // Below code is created for knowledge Subscription
    
    public Map<String,Boolean> subscribedMap{get;set;}   
    public Map<String,Id> categoryMap{get;set;}    
    public Map<String,List<String>> subCategoryMap{get;set;}    
    public List<SubscribedCustomer> subscribeList{get;set;}
    public Map<String,String> category;
    public Boolean selectAll{get;set;}
    public List<String> subscribedCategory{get;set;}
    public List<String> unSubscribedCategory{get;set;}
    public KnowledgeCategoryHome(){
        selectAll = false;
        subscribedCategory = new List<String>();
        unSubscribedCategory = new List<String>();
        subscribedMap = new Map<String,Boolean>();
        categoryMap = new Map<String,Id>();
        subCategoryMap = new Map<String,List<String>>(); 
        subscribeList = new List<SubscribedCustomer>();
        Integer i = 0;
        for(Customer_Subscription__c cs : [Select id,Category_Name__c,KB_ID__c,Category_Label__c,Type__c from Customer_Subscription__c where User__c =: UserInfo.getUserId()]){
            if(cs.Type__c == 'Category'){
                i++;
                subscribedMap.put(cs.Category_Name__c,true);
                categoryMap.put(cs.Category_Name__c,cs.Id);
            }else{
                if(!subCategoryMap.containsKey(cs.KB_ID__c)){
                    subCategoryMap.put(cs.KB_ID__c, new List<String>());
                }
                subCategoryMap.get(cs.KB_ID__c).add(cs.Category_Label__c);
            }
        }
        
        category = new Map<String,String>();
        categoryClass cc = new categoryClass();
        category = cc.getDescribeDataCategoryGroupStructureResults();
        subscribeList = getSubscribedData();
        System.debug(i +'--'+ category.size());
        if(i == category.size()-1)
            selectAll = true;
    }
    
   
    
    public SubscribedCustomer[] getSubscribedData(){
        
        List<SubscribedCustomer> sC = new List<SubscribedCustomer>();
        for(String ch : category.keyset()){
            sC.add(new SubscribedCustomer(ch , subscribedMap.containsKey(ch)));
        }
        return sC;
    }
    
    public void saveSubscription(){
        List<Customer_Subscription__c> customerSubsList = new List<Customer_Subscription__c>();
        subscribedMap = new Map<String,Boolean>();
        Set<Id> deletecustomerSubsList = new Set<Id>();
        for(SubscribedCustomer sc : subscribeList){
            if(sc.isSubscribed){
                subscribedMap.put(sc.categoryName,true);
                if(!categoryMap.containsKey(sc.categoryName)){
                    subscribedCategory.add(category.get(sc.categoryName));
                    customerSubsList.add(new Customer_Subscription__c(Category_Name__c = sc.categoryName , Type__c = 'Category' , User__c = UserInfo.getUserId() ,Category_Label__c = category.get(sc.categoryName))); 
                }
            }else{
                if(category.containsKey(sc.categoryName))
                    unSubscribedCategory.add(category.get(sc.categoryName));
                if(categoryMap.containsKey(sc.categoryName)){
                    deletecustomerSubsList.add(categoryMap.get(sc.categoryName));
                    categoryMap.remove(sc.categoryName);
                    subscribedMap.put(sc.categoryName,false);
                }
                
            }
            
            
        }
        if(!customerSubsList.isEmpty()){
            insert customerSubsList;
            for(Customer_Subscription__c sc : customerSubsList){
                categoryMap.put(sc.Category_Name__c,sc.Id);
            }
            createKbSubscription();
        }
        
        for(Customer_Subscription__c sc : customerSubsList){
            categoryMap.put(sc.Category_Name__c,sc.Id);
        }
        if(!deletecustomerSubsList.isEmpty()){
            delete [SELECT id from Customer_Subscription__c where User__c =: UserInfo.getUserId() AND  (Id IN: deletecustomerSubsList OR Category_Label__c IN: unSubscribedCategory)];
        }
        
    }
    
    
    public void createKbSubscription(){
        List<Customer_Subscription__c> newSubscriptionList = new List<Customer_Subscription__c>();
        Set<Id> subKbId = new Set<Id>();
        List<How_To__DataCategorySelection> subList  = [SELECT Parent.KnowledgeArticleId,DataCategoryName,DataCategoryGroupName,Parent.title,Parent.OwnerID,Parent.ArticleNumber, ParentId FROM How_To__DataCategorySelection WHERE Parent.KnowledgeArticleId != null AND  Parent.isLatestVersion = true];
        for(How_To__DataCategorySelection ht : subList){
            if(subscribedCategory.contains(ht.DataCategoryName) && !subKbId.contains(ht.Parent.KnowledgeArticleId) ){
                if(subCategoryMap.containsKey(ht.Parent.KnowledgeArticleId) && subCategoryMap.get(ht.Parent.KnowledgeArticleId).contains(ht.DataCategoryName)){
                    
                }else{
                    
                    newSubscriptionList.add(new Customer_Subscription__c( Type__c = 'Article',Title__c = ht.Parent.title,Author__c = ht.Parent.OwnerID,Article_Number__c = ht.Parent.ArticleNumber, User__c = UserInfo.getUserId() , KB_ID__c = ht.Parent.KnowledgeArticleId  ,Category_Label__c = ht.DataCategoryName));
                    if(!subCategoryMap.containsKey(ht.Parent.KnowledgeArticleId)){
                        subCategoryMap.put(ht.Parent.KnowledgeArticleId, new List<String>());
                    }
                    subCategoryMap.get(ht.Parent.KnowledgeArticleId).add(ht.DataCategoryName);
                }
                // subKbId.add(ht.Parent.KnowledgeArticleId);
            }
        }
        insert newSubscriptionList;
    }
    public void cancelSubscription(){
        subscribeList = getSubscribedData();
        System.debug(subscribedMap.keySet().size()+'--'+category.size());
        if(subscribedMap.keySet().size() == category.size()-1){
            selectAll = true;
        }else{
            selectAll = false;
        }
    }
    
    
    public class SubscribedCustomer{
        public String categoryName{get;set;}
        public Boolean isSubscribed{get;set;}
        public SubscribedCustomer(String name , Boolean isSubscribed){
            this.categoryName = name;
            this.isSubscribed = isSubscribed;
        }
    }
    
    
    
    
    
}