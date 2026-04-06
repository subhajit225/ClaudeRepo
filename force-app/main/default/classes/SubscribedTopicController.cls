global class SubscribedTopicController {
    
    public String currentUserId{get;set;} 
    public string baseURL{get;set;}
    public String topicUrl{get; set;}
   
    //Ticket : CS21-1267 - November was assigned to 9 instead of 11, corrected that
    public map<Integer,String>monthMap= new map<Integer,String>{1=>'January', 2=>'February',3=>'March',4=>'April',5=>'May',6=>'June',7=>'July',8=>'August',9=>'September',10=>'October',11=>'November',12=>'December'};

    public SubscribedTopicController(){
        topicUrl = System.Label.Community_Base_URL;
        List<Network> myCommunity = [SELECT Name,Id, UrlPathPrefix FROM Network WHERE Name ='Rubrik Support'];
        if(!test.isRunningTest()){
            ConnectApi.Community comm = ConnectApi.Communities.getCommunity(myCommunity[0].id);
            baseURL=comm.siteUrl;
        }
        
    }
    public  Map<String,List<wrapperclass>> getsubscribedTopicVsSusbscribedPosts(){
        // Map<String,List<wrapperclass>> topicNameVsWrapperList= new Map<String,List<wrapperclass>>();
        Map<String,List<wrapperclass>> topicVsPosts= new  Map<String,List<wrapperclass>>();
        Map<Id,String>feedItemIdVsTopicName= new Map<Id,String>();
        Date todayDate = System.today().addDays(-7) ;
        Set<Id>subscribedTopicId= new Set<Id>();
        Map<Id,String>questionIdVsLatestCommentDate = new Map<Id,String>();   //AND  DAY_ONLY(CreatedDate) >=: todayDate
        
        for(EntitySubscription esub: [SELECT CreatedById,CreatedDate,Id,IsDeleted,NetworkId,ParentId,SubscriberId FROM EntitySubscription where SubscriberId =:currentUserId AND NetworkId=:system.label.networkScope ]){
            subscribedTopicId.add(esub.ParentId);
        }
        
        Date sevenDaysBackDate = System.today().addDays(-7) ;
        for(TopicAssignment  ta:[SELECT CreatedById,CreatedDate,EntityId,EntityKeyPrefix,EntityType,Id,IsDeleted,NetworkId,SystemModstamp,TopicId,Topic.Name FROM TopicAssignment where TopicId IN :subscribedTopicId AND  CreatedDate>=: sevenDaysBackDate ]){
            
                                     feedItemIdVsTopicName.put(ta.EntityId,string.valueOf( ta.Topic.Name));
                                             
                                         }
        
        for(FeedItem fedItm:[SELECT Id,(SELECT Id,CreatedDate,FeedItemId From FeedComments order by CreatedDate DESC limit 1),ParentId ,RelatedRecordId,Title,Type,Visibility,CreatedDate FROM FeedItem WHERE ID IN :feedItemIdVsTopicName.keyset()]){
            
            if( ! fedItm.FeedComments.isEmpty() && ! questionIdVsLatestCommentDate.containsKey(fedItm.Id)){
             
                //fedItm.FeedComments[0].CreatedDate.format;
               /* Ticket : CS21-1267
                * Changes : 1. month & year were getting fetched from the CreatedDate of FeedItem, however, it should be fetched from the CreatedDate of FeedComment
                               because we need date of the latest comment.
                            2. In the monthMap above, November was assigned to 9 instead of 11, corrected that.
                            3. Using dayGmt(), monthGmt() and yearGmt() to avoid discrepancy related to the GMT time zone and context user's local time zone.
                */
                DateTime formattedDate = fedItm.FeedComments[0].CreatedDate;
                String day = String.valueOf(formattedDate.dayGmt());
                String year = String.valueof(formattedDate.yearGmt());
                String month=monthMap.get(formattedDate.monthGmt());
                String latestCommentDate= month+' '+day+', '+year;
                               
                system.debug('latestCommentDate@@@ '+latestCommentDate);
                questionIdVsLatestCommentDate.put(fedItm.Id,latestCommentDate);
                
            }
            
            if(fedItm.FeedComments.isEmpty() && ! questionIdVsLatestCommentDate.containsKey(fedItm.Id)){
                
                //questionIdVsLatestCommentDate.put(fedItm.Id,'Unanswered Post');
                questionIdVsLatestCommentDate.put(fedItm.Id,'Unanswered Post');
            }
        }
        
        for(FeedItem fedItm:[SELECT Id,ParentId ,RelatedRecordId,Title,Type,Visibility,CreatedDate FROM FeedItem
                                          WHERE ID IN :feedItemIdVsTopicName.keyset()]){
                                             
                                             
                                             if(feedItemIdVsTopicName.containsKey(fedItm.Id) && !topicVsPosts.containskey(feedItemIdVsTopicName.get(fedItm.Id))){
                                                 topicVsPosts.put(feedItemIdVsTopicName.get(fedItm.Id), new List<wrapperclass>());
                                             }
                                             
                                             if(questionIdVsLatestCommentDate.containsKey(fedItm.Id) ){
                                                 
                                                 topicVsPosts.get(feedItemIdVsTopicName.get(fedItm.Id)).add(new wrapperclass(fedItm,questionIdVsLatestCommentDate.get(fedItm.Id)));
                                             }
                                             
                                             
                                         } 
        
      
        system.debug('topicVsPosts@@@@'+topicVsPosts);  
        return !topicVsPosts.isEmpty()?topicVsPosts:null;
    }
    
    public class wrapperclass{
        public FeedItem feedItem{get; set;}
        public String latestResponse{get;set;}  
        
        
        public wrapperclass(FeedItem feedItem , String latestResponse){
            
            this.feedItem=feedItem;
            this.latestResponse=latestResponse;
           
            
        }
        
    }
    
    
    
    
}