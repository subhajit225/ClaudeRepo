global  without sharing class DirectCommentController {
    
    public Id subId {get;set;}
    public  Customer_Subscription__c csrec;
    public string commURL;
    global String dynamicUrl {get; set;}
   
    public DirectCommentController(){
        dynamicUrl = System.Label.Community_Base_URL;
    }
    public Customer_Subscription__c getCusSubInfo(){
       String feedComment;
        if(Null!=subId){
            csrec= new Customer_Subscription__c();  
           
            csrec=[Select Id,Title__c,Topic_Name__c,Topic_Id__c,Community_Feed__c,Community_Feed__r.Title__c,
                   Community_Feed__r.InsertedById__c,Community_Feed__r.FeedItemId__c,Community_Feed__r.FeedCommentId__c,
                   Community_Feed__r.CreatedBy.SmallPhotoUrl ,Community_Feed__r.CreatedBy.CommunityNickname ,
                   CreatedBy.CommunityNickname,CreatedDate,CreatedBy.Username,
                   Community_Feed__r.createdDate,Post_Creator__r.CommunityNickname,Post_Creator__r.SmallPhotoUrl from Customer_Subscription__c where Id=:subId ]; 
            system.debug('cusSubRecord@@@'+csrec);
            
            List<FeedComment> feedList=[SELECT Id, CommentBody  FROM FeedComment  WHERE id=: csrec.Community_Feed__r.FeedCommentId__c];
            List<String> userNames = new List<String>();
            Map<String,List<Id>> userNameToIdMap = new Map<String,List<Id>>();
             Map<String,String> userNameToAliasMap= new Map<String,String>();
            if(feedList!=NULL && feedList.size()>0){
                userNames.addAll(AttachingCusSubHelper.getNames(feedList[0].CommentBody));
                feedComment = feedList[0].CommentBody;
            }
           
            if(!userNames.isEmpty()){
                feedComment =FeedPostCommonHandler.filterUsers(userNames,feedComment);
            }
           
            csrec.Community_Feed__r.Title__c=feedComment;
           
        }
        return  csrec;
    }
    
    public string getcommunityURL(){
        
        List<Network> myCommunity = [SELECT Name,Id, UrlPathPrefix FROM Network WHERE Name ='Rubrik Support'];
        if(!test.isRunningTest()){
            ConnectApi.Community comm = ConnectApi.Communities.getCommunity(myCommunity[0].id);
            commURL=comm.siteUrl;
        }
        return commURL;
    }
    public String getRubrikLogoUrl(){
        list<Document> lstDocument = [SELECT Id FROM Document WHERE DeveloperName = 'Rubrik_logo_150_50'];
        String strOrgId = UserInfo.getOrganizationId();
        if(!test.isRunningTest()){
            String strLogoUrl = System.URL.getSalesforceBaseUrl().toExternalForm() + 
                '/servlet/servlet.ImageServer?id='+lstDocument[0].Id +
                '&oid=' + strOrgId;
            return strLogoUrl;
        }
        else{
            return '';
        }
        
    }
    public String getCommentOwnerProfileImgURL(){
        Customer_Subscription__c cs = getCusSubInfo();
        //User u = [Select id, u.SmallPhotoUrl, u.FullPhotoUrl From User u where u.id=:userInfo.getUserId()];
        String strLogoUrl = System.URL.getSalesforceBaseUrl().toExternalForm() + cs.Community_Feed__r.CreatedBy.SmallPhotoUrl;
        return strLogoUrl;
        
    }
    public String getpostOwnerProfileImgURL(){
        Customer_Subscription__c cs = getCusSubInfo();
        //User u = [Select id, u.SmallPhotoUrl, u.FullPhotoUrl From User u where u.id=:userInfo.getUserId()];
        String strLogoUrl = System.URL.getSalesforceBaseUrl().toExternalForm() + cs.Post_Creator__r.SmallPhotoUrl;
        return strLogoUrl;
        
    }
    
}