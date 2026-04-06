public class FeedPostCommonHandler {
    public static List<FlowWrapper> fwList = new List<FlowWrapper>();
    
    /*****************************************************************************************************************************************
* Method Name 			: getIdFromTrigger
* CreatedDate	 		: 16-12-2022
* Description	 		: Method to call Flow and send Email to All the subscribers on every FeedItem.
*****************************************************************************************************************************************/
    @future
    public static void getIdFromTrigger(List<id> feedItemIdSet){
        try{
            List<FeedItem> feedItemList = [Select Id, Title, CreatedDate,CreatedById from FeedItem where Id IN :feedItemIdSet];
            List<User> usersList= getSubscribedUserList(feedItemList,false,true,NULL);

            if(usersList!=NULL && !usersList.isEmpty()){
                FlowWrapper fw = new FlowWrapper(usersList, feedItemList[0], null, null);
                fwList.clear();
                fwList.add(fw);
                
                Flow.Interview.FeedCommentFlow flow1 = new Flow.Interview.FeedCommentFlow(new Map<String, Object>());
                flow1.start();
            }
        }catch(Exception e){
            System.debug('Error ----> '+ e.getMessage());
        }
    }

    /*****************************************************************************************************************************************
* Method Name			: feedCommentAfterInsertMethod 
* CreatedDate	 		: 16-12-2022
* Description	 		: Method to call Flow and send Email to All the subscribers on every FeedComment.
*****************************************************************************************************************************************/
    public static void feedCommentAfterInsertMethod(List<FeedComment> feedCommentList){
        Set<Id> feedItemIdSet = new Set<Id>(); 
        List<String> userNames = new List<String>();
        FlowWrapper fw;
        string feedComment='';
        for(FeedComment fc : feedCommentList){
            string parent=fc.ParentId;
            if(parent.startsWithIgnoreCase('005')){
                feedItemIdSet.add(fc.feedItemId); 
            }
        }
        
        if(feedItemIdSet!=NULL && !feedItemIdSet.isEmpty() && feedCommentList!=NULL && feedCommentList.size()>0){
            feedComment= feedCommentList[0].CommentBody;
            userNames.addAll(AttachingCusSubHelper.getNames(feedComment));
        }
       
        if(!userNames.isEmpty()){
            feedComment =filterUsers(userNames,feedComment);
        }
       
        List<FeedItem> fitemobj = [Select Id, Title, CreatedDate from FeedItem WHERE Id IN :feedItemIdSet];
        List<User> subscribedUserList = getSubscribedUserList(fitemobj,True,False,feedCommentList);
        if(subscribedUserList!=NULL && subscribedUserList.size()>0 && fitemobj!=NULL && fitemobj.size()>0 && feedComment!=''){
            fw = new FlowWrapper(subscribedUserList, fitemobj[0], feedCommentList[0], feedComment);
        }
        
        fwList.clear();
        fwList.add(fw);
        
        if(!Test.isRunningTest()){
            Flow.Interview.FeedCommentFlow flow1 = new Flow.Interview.FeedCommentFlow(new Map<String, Object>());
            flow1.start();   
        }
        
    }
    
    public static string filterUsers(List<String> userNames,string feedbody){
        Map<String,List<Id>> userNameToIdMap = new Map<String,List<Id>>();
        Map<String,String> userNameToAliasMap= new Map<String,String>(); 
        String feedComment='';
        feedComment=feedbody; 
        List<User> userList = [SELECT id, Name,Contact.Name, CommunityNickName,alias FROM User WHERE Contact.Name LIKE: userNames ];
      
        for(User usr : userList){
            if(!userNameToIdMap.containsKey(usr.Name)){
                userNameToIdMap.put(usr.Contact.Name, new List<Id>());
            }
            userNameToIdMap.get(usr.Contact.Name).add(usr.Id);
            userNameToAliasMap.put(usr.Contact.Name,usr.CommunityNickName);
        }
       
        if(!userNameToIdMap.isEmpty()){ 
            for(String key : userNameToIdMap.keySet()){
               
                if(feedComment.contains('@'+key)){
                   
                    if(userNameToIdMap.get(key).size() > 1){
                         
                        feedComment = feedComment.replaceAll('@'+key+'?','@tagged User').replaceAll('@'+key,'@tagged User');
                       
                    }else{
                        
                        feedComment = feedComment.replaceAll('@'+key+'?',userNameToAliasMap.get(key)).replaceAll('@'+key,userNameToAliasMap.get(key));
                        
                    }
                }
            }
        }
       
        return feedComment;
    }
    public static List<User> getSubscribedUserList(List<FeedItem> feedItemList,Boolean feedComment,Boolean FeedItem,List<FeedComment> feedCommentList){
        List<String> TopicAssignmentId=new List<String> ();
        Set<Id> userIdSet = new Set<Id>();
        
        for(TopicAssignment taObj:[Select Id, topicId from TopicAssignment WHERE EntityId IN : feedItemList]){
            TopicAssignmentId.add(taObj.topicId);
        }
        List<Customer_Subscription__c> csList = [Select Id, Topic_Id__c, User__c, Subscribed_User_Email__c from Customer_Subscription__c WHERE Topic_Id__c IN : TopicAssignmentId AND Type__c = 'Forum Category'];
        for(Customer_Subscription__c cs : csList){
            if(FeedItem){
                if(feedItemList[0].createdById != cs.user__c)
                    userIdSet.add(cs.user__c);
            }else if(feedComment){
                if(feedCommentList[0].createdById != cs.user__c)
                    userIdSet.add(cs.user__c);
            }
        }
        List<User> subscribedUserList = [Select Id,Email,FirstName,CommunityNickname  from User Where Id IN :userIdSet AND Daily_Subscription__c = true];
        return subscribedUserList;
    }

    @InvocableMethod
    public static List<FlowWrapper> returnWrapper(){
        return fwList;
    }
    public class FlowWrapper{
        @InvocableVariable
        public List<User> userToFlowList;
        @InvocableVariable
        public FeedItem feedItemRecord;
        @InvocableVariable
        public FeedComment feedCommentPost;
        @InvocableVariable
        public String feedCom;
        public FlowWrapper(List<User> usrList, FeedItem fi, FeedComment fc, String FeedCommentBody){
            this.userToFlowList = usrList;
            this.feedItemRecord = fi;
            this.feedCommentPost = fc;
            this.feedCom = FeedCommentBody;
        }
    }
}