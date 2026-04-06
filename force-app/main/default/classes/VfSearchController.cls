public with sharing class VfSearchController{
    
    
    // kb Subscription Start
    public List<String> subscribedCategory = new List<String>();
    public boolean isSubscribed{get;set;}
    public Customer_Subscription__c subscribeRecord{get;set;}
    public String label;
    public Map<String,String> categoryMap = new Map<String,String>();
    public List<Customer_Subscription__c> allSubscribedList = new List<Customer_Subscription__c>();
    public List<String> subscribedList = new List<String>();
    
    public VfSearchController(){
        isSubscribed = false;
        subscribeRecord = new Customer_Subscription__c();
        label = System.currentPageReference().getParameters().Get('categoryType_Article');
        categoryClass cc = new categoryClass();
        categoryMap = cc.getDescribeDataCategoryGroupStructureResultsSingle();
        if(label == 'All'){
            allSubscribedList = [Select id,Category_Name__c,Category_Label__c from Customer_Subscription__c where Type__c = 'Category' AND User__c =: UserInfo.getUserId()];
            for(Customer_Subscription__c sub : allSubscribedList){
                subscribedList.add(sub.Category_Label__c);
            }
            if(allSubscribedList.size() == categoryMap.keyset().size() -1 ){
                isSubscribed = true;
            }
        }else{
            List<Customer_Subscription__c> sublist = [Select id,Category_Name__c from Customer_Subscription__c where Type__c = 'Category' AND User__c =: UserInfo.getUserId() AND Category_Label__c = : label];
            if(sublist.size() == 1){
                subscribeRecord = sublist[0];
                isSubscribed = true;
            }
        }
        
        
    }
    
    public void editSubscription(){
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
            createKbSubscription();
        }            
    }
    
    public void createKbSubscription(){
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
    // kb Subscription End
    //Page Size
    private Static Final Integer PAGE_NUMBER = 10;
    
    //Search String used in ArticleList tag
    public String searchstring { get; set; }
    public string selectedVal {get;set;}
    //Is new List reqd 
    private boolean isRefRequired = true;
    //Exclude filter criteria for UI only
    private static final String EXCLUDE_CRITERIA_FILTER  = 'All';
    
    //Keeps track of current page & max size of article list
    Integer currentPage = 1;
    public Integer maxSize{get;set;}
    
    //Returns array of Category Groups
    public DataCategoryGroupInfo[] getDataCategoryGroupInfo() {
        return DataCategoryUtil.getInstance().getAllCategoryGroups();
    }
    
    //Returns category keyword required to filter articleList.
    public String getCategoryKeyword() {
        DataCategoryGroupInfo[] categoryGroups = DataCategoryUtil.getInstance().getAllCategoryGroups();
        String categoryCondition = '';
        for (DataCategoryGroupInfo categoryGroup : categoryGroups) {
            String selectedCategoryName = System.currentPageReference().getParameters().Get('categoryType_'+categoryGroup.getName());
            if(selectedCategoryName != null && !selectedCategoryName.equals('NoFilter')) {
                if(categoryCondition=='' && selectedCategoryName != null){
                    categoryCondition=categoryCondition+categoryGroup.getName() + ':' + System.currentPageReference().getParameters().Get('categoryType_'+categoryGroup.getName());
                }else {
                    categoryCondition=categoryCondition + ',' +categoryGroup.getName() + ':' + System.currentPageReference().getParameters().Get('categoryType_'+categoryGroup.getName());
                }
            }
        }
        String categoryFilter = '';
        for (DataCategoryGroupInfo categoryGroup : categoryGroups) {
            String categoryType = System.currentPageReference().getParameters().Get('categoryType_'+categoryGroup.getName());
            if(categoryType != null &&  !categoryType.equals('NoFilter')) {
                if(categoryFilter == ''){
                    categoryFilter = categoryGroup.getName() + '__c ABOVE_OR_BELOW ' + categoryType  +'__c';
                } else {
                    categoryFilter = categoryFilter + ' AND ' + categoryGroup.getName() +'__c ABOVE_OR_BELOW ' + categoryType +'__c';
                }
            }
        }
        try {
            if(categoryFilter.length()>0) {
                if(searchString != null && searchString.length() >0 ) {
                    String searchquery = 'FIND \'' + searchString + '*\'IN ALL FIELDS RETURNING KnowledgeArticleVersion(Id, title, UrlName, LastPublishedDate,LastModifiedById where PublishStatus =\'online\' and Language = \'en_US\') WITH DATA CATEGORY '+categoryFilter ;
                    List<List<SObject>>searchList = search.query(searchquery);
                    List<KnowledgeArticleVersion> articleList = (List<KnowledgeArticleVersion>)searchList[0];
                    maxSize = articleList.size() ;
                    //                    maxSize = maxSize.divide(PAGE_NUMBER,2,System.RoundingMode.UP);
                } else {
                    String qryString = 'SELECT Id, title, UrlName, CreatedDate, LastPublishedDate,LastModifiedById FROM KnowledgeArticleVersion WHERE (PublishStatus = \'online\' and Language = \'en_US\') WITH DATA CATEGORY '+categoryFilter; 
                    List<KnowledgeArticleVersion> articleList= Database.query(qryString);
                    maxSize = articleList.size() ;
                    //                    maxSize = maxSize.divide(PAGE_NUMBER,2,System.RoundingMode.UP);
                }
            } else {
                String qryString = 'SELECT Id, title, UrlName, CreatedDate, LastPublishedDate,LastModifiedById FROM KnowledgeArticleVersion WHERE (PublishStatus = \'online\' and Language = \'en_US\')';
                List<KnowledgeArticleVersion> articleList= Database.query(qryString);
                maxSize = articleList.size() ;
                //                maxSize = maxSize.divide(PAGE_NUMBER,2,System.RoundingMode.UP);
            }        
        } catch(Exception e) {
            Apexpages.addmessages( e );
        }
        if(categoryFilter =='') {
            //            maxSize = 0;
            categoryCondition = '' ;   
        }
        return categoryCondition;
    }
    
    // Action call when the new list needs to be fetched
    public PageReference refreshSearchResult() {
        maxSize = currentPage = 1;
        return null;
    }
    
    // Returns whether we need to see previous button or not
    public boolean getPrevRequired() {
        return currentPage > 1;
    }
    
    // Returns whether we need to see next button or not
    public boolean getNextRequired() {
        return currentPage * PAGE_NUMBER < maxSize;
    }
    
    //Returns current page number 
    public Decimal getCurrentPageNumber() {
        return this.currentPage;
    }
    
    //action for next click
    public PageReference next() {
        if(maxSize > this.currentPage * PAGE_NUMBER) {
            this.currentPage = this.currentPage + 1;
        }
        return null;
    }    
    
    //action for previous click
    public PageReference previous() {        
        if(this.currentPage > 1)
            this.currentPage = this.currentPage - 1;
        return null;
    }
    
}