public class forumMerticsLikeCountController{
    public Map<Id, Id> topicToFeedItem = new Map<Id, Id>();
    public Map<Id, Set<Id>> topicToFeedItem1 = new Map<Id, Set<Id>>();
    public Set<Id> topicIds= new Set<Id>();
    public List<feedItemLikeWrapper> wrapperList {get;set;}
    public List<feedItemLikeWrapper> feedItemLikeWrapList {get;set;}
    
    public List<feedItemLikeWrapper> myfeedItemLikeWrapList {get;set;}
    public Integer totalSize ;
    public Integer pageNumber = 0;
    public Integer totalPageNumber = 0;
    public Integer pageSize = 50;
    public Integer newPageIndex = 1;
    
    public void Previous()
    {
        myfeedItemLikeWrapList.clear();
        BindData(pageNumber - 1);
    }
    
    public Integer getPageNumber()
    {
        return pageNumber;
    }
    public Integer getPageSize()
    {
        return pageSize;
    }
    public Integer getTotalsize() {
        return totalsize;
    }
    public void ViewData(){
        totalPageNumber = 0;
        BindData(1);
    }
    
    public void BindData(Integer newPageIndex){
        Transient Integer counter = 0;
        Transient Integer min = 0;
        Transient Integer max = 0;
        if (newPageIndex > pageNumber){
            min = pageNumber * pageSize;
            max = newPageIndex * pageSize;
        }
        else{
            max = newPageIndex * pageSize;
            min = max - pageSize;
        }
        for(feedItemLikeWrapper a : feedItemLikeWrapList)
        {
            Counter++;
            if (counter > min && counter <= max){
                myfeedItemLikeWrapList.add(a);
            }
            pageNumber = newPageIndex;
        }
        totalSize  = feedItemLikeWrapList.size();   
        if (feedItemLikeWrapList == null || feedItemLikeWrapList.size() <= 0)
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Data not available.'));
    }
    
    public void Next()
    {
        myfeedItemLikeWrapList.clear();
        BindData(pageNumber + 1);
    }
    
    public boolean getprev()
    {
        return !(pageNumber > 1);
    }
    
    public boolean getnxt()
    {
        if (feedItemLikeWrapList== null) { 
            return true;
        }
        Else
        {
            return ((pageNumber * pageSize) >= totalsize);
        }
    }
    
    public Integer getTotalPageNumber()
    {
        if(totalPageNumber == 0 && feedItemLikeWrapList!=null ){
            if(totalSize < pageSize && totalSize!=0){
                totalPageNumber = 1;
            }else{
                totalPageNumber = totalsize / pageSize;
                Integer mod = totalsize  - (totalPageNumber * pageSize);
                if (mod > 0)
                    totalPageNumber++;
            }
        }
        return totalPageNumber;
    }
    
    public forumMerticsLikeCountController(){   
        feedItemLikeWrapList = getFeedItemForumLikes();
        myfeedItemLikeWrapList = new List<feedItemLikeWrapper>();
        ViewData();
    }
    
    public List<feedItemLikeWrapper> getFeedItemForumLikes(){
        Map<Id, Topic> topicMap= new Map<Id, Topic>([SELECT Id, name, NetworkId FROM Topic WHERE NetworkId  != '']); 
        
        Set<Id> feedItemIds= new Set<Id>();
        Set<Id> networkIds= new Set<Id>();
        if(topicMap !=null && !topicMap.isEmpty()){
            //Fetch topic to feed item records from Topic Assignment 
            for(TopicAssignment topicAssgn: [SELECT Id, TopicId, NetworkId, EntityId FROM TopicAssignment WHERE TopicId IN: topicMap.KeySet()]){
                networkIds.add(topicAssgn.NetworkId);
                if(topicToFeedItem1 != NULL && topicToFeedItem1.containsKey(topicAssgn.TopicId)){
                    Set<Id> temp= topicToFeedItem1.get(topicAssgn.TopicId);
                    if(temp != NULL) temp.add(topicAssgn.EntityId);
                    topicToFeedItem1.put(topicAssgn.TopicId, temp);
                    feedItemIds.add(topicAssgn.EntityId);
                }else{
                    topicToFeedItem1.put(topicAssgn.TopicId, new Set<Id>{topicAssgn.EntityId});
                    feedItemIds.add(topicAssgn.EntityId);
                }      
            }
        } 
        
        Map<Id, Network> networkMap= new Map<Id, Network>([SELECT Id, Name, Status FROM Network WHERE Id IN: networkIds]);
        //Fetch FeedItem records 
        Map<Id, FeedItem> feedItemMap= new Map<Id, FeedItem>([SELECT Id, ParentId, Type, Title, Body, CreatedById, CreatedBy.Name, CreatedDate, CommentCount, LikeCount, NetworkScope, (SELECT Id, createdbyid, createdby.Name, createdby.Email, createdby.UserRole.Name, createdby.Usertype, createddate, FeedItemId FROM feedlikes) FROM FeedItem WHERE Id IN: feedItemIds]);
        wrapperList = new List<feedItemLikeWrapper>();
        
        for(Id eachTopicId: topicToFeedItem1.keySet()){
            if(topicToFeedItem1.containsKey(eachTopicId) && topicToFeedItem1.get(eachTopicId)!=null){
                for(Id eachFeedItemId: topicToFeedItem1.get(eachTopicId)){
                    if(feedItemMap != NULL && feedItemMap.containsKey(eachFeedItemId) && feedItemMap.get(eachFeedItemId) != NULL){
                        //for(FeedLike eachFeedLike: feedItemMap.get(eachFeedItemId).feedlikes){
                        
                        if(feedItemMap.get(eachFeedItemId).feedlikes != NULL && feedItemMap.get(eachFeedItemId).feedlikes.size() > 0){
                            for(FeedLike each1: feedItemMap.get(eachFeedItemId).feedlikes){
                                feedItemLikeWrapper wrap= new feedItemLikeWrapper();
                                wrap.topicRecordId= eachTopicId;
                                wrap.feedItemRecord= feedItemMap.get(eachFeedItemId);
                                wrap.feedLikeRecord= each1;
                                wrap.TopicName= topicMap.get(eachTopicId).Name;
                                if(!Test.isRunningTest()){
                                    if(networkMap.containsKey(feedItemMap.get(eachFeedItemId).NetworkScope))
                                        wrap.NetworkName= networkMap.get(feedItemMap.get(eachFeedItemId).NetworkScope).Name;
                                }
                                else
                                    wrap.NetworkName= feedItemMap.get(eachFeedItemId).NetworkScope;
                                wrapperList.add(wrap);  
                            }
                        }else{
                            feedItemLikeWrapper wrap= new feedItemLikeWrapper();
                            wrap.topicRecordId= eachTopicId;
                            wrap.TopicName= topicMap.get(eachTopicId).Name;
                            wrap.feedItemRecord= feedItemMap.get(eachFeedItemId);
                            wrap.feedLikeRecord= NULL;
                            if(!Test.isRunningTest()){
                                if(networkMap.containsKey(feedItemMap.get(eachFeedItemId).NetworkScope)){
                                    wrap.NetworkName= networkMap.get(feedItemMap.get(eachFeedItemId).NetworkScope).Name;
                                }
                            }
                            else
                                wrap.NetworkName= feedItemMap.get(eachFeedItemId).NetworkScope;
                            wrapperList.add(wrap);  
                        }
                        //}
                    }
                }         
            }     
        } 
        return wrapperList;
    }
    
    public class feedItemLikeWrapper{
        public Id topicRecordId{get;set;}
        public FeedItem feedItemRecord{get;set;}
        public FeedLike feedLikeRecord{get;set;}
        public String NetworkName{get;set;}
        public String TopicName{get;set;}
    }
}