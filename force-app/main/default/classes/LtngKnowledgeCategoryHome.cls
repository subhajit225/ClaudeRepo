public class LtngKnowledgeCategoryHome {
    
    @AuraEnabled
    public static Map<String,String> getAllCategoryGroups() {
        categoryClass CC = new categoryClass();
        return cc.getDescribeDataCategoryGroupStructureResults();
    }
   /* @AuraEnabled
    public static list<CategwrapperList> getCategories(){
        List<CategwrapperList> cwList = new List<CategwrapperList>();
        DataCategoryGroupSobjectTypePair pair = new DataCategoryGroupSobjectTypePair();
        pair.setSobject('KnowledgeArticleVersion'); //KnowledgeArticleVersion & Question
        pair.setDataCategoryGroupName('Article');
        List<Schema.DescribeDataCategoryGroupStructureResult> results = Schema.describeDataCategoryGroupStructures(new List<DataCategoryGroupSobjectTypePair>{pair}, false);
        system.debug('results--->'+results);
        if(!results.isEmpty()){
               list<string> topCategs = new list<string>();
             for(Schema.DescribeDataCategoryGroupStructureResult result: results){
                for(Datacategory topCateg: result.getTopCategories()){
                    system.debug('--->'+topCateg.getlabel());
                    CategwrapperList cp1 = new CategwrapperList();
                   // cp1.topCateg = topCateg.getlabel();
                   // cwList.add(cp1);
                    for(DataCategory childCateg :topCateg.getChildCategories()){
                        system.debug('--->>'+childCateg.getName());
                        CategwrapperList cp = new CategwrapperList();
                       // topCategs.add(childCateg.getlabel());
                        cp.childcateg = childCateg.getlabel();
                       // cp.topCateg = topCateg.getlabel();
                        List<CategwrapperList> childcwList = new List<CategwrapperList>();
                        for(DataCategory childCateg1 :childCateg.getChildCategories()){
                            CategwrapperList categWrap = new  CategwrapperList();
                            categWrap.childcateg = childCateg1.getlabel();
                         //   categWrap.topCateg = childCateg.getlabel();
                            childcwList.add(categWrap);
                            system.debug('--->>>'+childCateg1.getName());
                           system.debug('cssp--->>>'+childCateg1.getlabel());
                        }
                        cp.childcategList = childcwList;
                         system.debug('cp--->>>'+cp);
                        cwList.add(cp);
                    }             
                }
               
            }
            
        }
        return cwList;
    }*/
  /*  public  class CategwrapperList{
        @AuraEnabled
        public string childcateg;
        @AuraEnabled
        public List<CategwrapperList> childcategList;
    }*/
    
    @AuraEnabled
    
      public static  List<SubscribedCustomer> getSubscription(){
          boolean  selectAll = false;
         Map<String,Boolean> subscribedMap = new Map<String,Boolean>();
         Map<String,Id> categoryMap = new Map<String,Id>();
         Map<String,List<String>>  subCategoryMap = new Map<String,List<String>>(); 
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
          
          categoryClass cc = new categoryClass();
          Map<String,String> category = cc.getDescribeDataCategoryGroupStructureResults();
          List<SubscribedCustomer> sC = new List<SubscribedCustomer>();
          for(String ch : category.keyset()){
              sC.add(new SubscribedCustomer(ch , subscribedMap.containsKey(ch),category.get(ch)));
          }
          return sc;  
          
    }
  
    @AuraEnabled
    public static void saveSubscription( list<SubscribedCustomer> subsCategList){
        
        Map<String,Boolean> subscribedMap = new Map<String,Boolean>();
        Map<string , string>  category = new Map<String,String>();
        Set<Id> deletecustomerSubsList = new Set<Id>();
        List<String> subscribedCategory = New List<String>();
        
        List<String> unSubscribedCategory = New List<string>();
        Map<String,Id> categoryMap = new Map<String,Id>();
        Map<String,List<String>>  subCategoryMap = new Map<String,List<String>>(); 
        List<Customer_Subscription__c> customerSubsList = new List<Customer_Subscription__c>();
        subscribedCategory = new List<String>();
        unSubscribedCategory = new List<String>();
        subscribedMap = new Map<String,Boolean>();
        categoryMap = new Map<String,Id>();
        subCategoryMap = new Map<String,List<String>>(); 
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
        System.debug(i +'--'+ category.size());
        for(SubscribedCustomer sc : subsCategList){
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
            List<Customer_Subscription__c> newSubscriptionList = new List<Customer_Subscription__c>();
            Set<Id> subKbId = new Set<Id>();
            List<How_To__DataCategorySelection> subList  = [SELECT Parent.KnowledgeArticleId,DataCategoryName,DataCategoryGroupName,Parent.title,Parent.OwnerID,Parent.ArticleNumber, ParentId FROM How_To__DataCategorySelection WHERE Parent.KnowledgeArticleId != null AND  Parent.isLatestVersion = true];
            for(How_To__DataCategorySelection ht : subList){
                if(subscribedCategory.contains(ht.DataCategoryName) && !subKbId.contains(ht.Parent.KnowledgeArticleId) ){
                    if(subCategoryMap.containsKey(ht.Parent.KnowledgeArticleId) && subCategoryMap.get(ht.Parent.KnowledgeArticleId).contains(ht.DataCategoryName)){
                        
                    }else{
                        
                        newSubscriptionList.add(new Customer_Subscription__c( Type__c = 'Article',Title__c = ht.Parent.title,Article_Number__c = ht.Parent.ArticleNumber, User__c = UserInfo.getUserId() , KB_ID__c = ht.Parent.KnowledgeArticleId  ,Category_Label__c = ht.DataCategoryName));
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
        
        for(Customer_Subscription__c sc : customerSubsList){
            categoryMap.put(sc.Category_Name__c,sc.Id);
        }
        
        if(!deletecustomerSubsList.isEmpty()){
            delete [SELECT id from Customer_Subscription__c where User__c =: UserInfo.getUserId() AND  (Id IN: deletecustomerSubsList OR Category_Label__c IN: unSubscribedCategory)];
        }
        
    }
     @AuraEnabled
    public static void createKbSubscription(){
        List<String> subscribedCategory = New List<String>();
        Map<String,List<String>>  subCategoryMap = new Map<String,List<String>>(); 
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
    
     public class SubscribedCustomer{
         @auraEnabled
         public String categoryName{get;set;}
         @auraEnabled
         public String api{get;set;}
         @auraEnabled
         public Boolean isSubscribed{get;set;}
         public SubscribedCustomer(String name , Boolean isSubscribed,String api){
             this.categoryName = name;
             this.isSubscribed = isSubscribed;
             this.api = api;
        }
         
         public SubscribedCustomer(){}
    }
}