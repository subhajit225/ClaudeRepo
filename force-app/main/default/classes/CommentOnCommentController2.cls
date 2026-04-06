//Contains logic for sending emails to those customers on whose commentssomebody replied
public class CommentOnCommentController2 {
    
    public Id feedId {get;set;}
    public  Community_Feed__c csrec;
    public string commURL;
    
    public wrapper1 getCommentInfo(){
        wrapper1 commentDetail = new wrapper1();
        if(Null!=feedId){
            csrec= new Community_Feed__c();
            system.debug('cusSubId'+feedId);
            Community_Feed__c cfmain=[SELECT Id,Parentfeed__c,Title__c,Community_Feed_Parent__c,CreatedBy.CommunityNickname,CreatedDate,FeedCommentId__c FROM Community_Feed__c WHERE Id =:feedId];
            Community_Feed__c cf = [SELECT Id,Title__c,CreatedBy.CommunityNickname,CreatedDate FROM Community_Feed__c WHERE Id =: cfmain.Parentfeed__c];
            
            /* csrec=[Select Id,Title__c,Community_Feed_Parent__r.Title__c,Post_Title__c,FeedCommentId__c,
Community_Feed_Parent__r.InsertedById__c,Community_Feed_Parent__r.FeedItemId__c,Community_Feed_Parent__r.FeedCommentId__c,
Community_Feed_Parent__r.CreatedBy.CommunityNickname ,Community_Feed_Parent__r.Post_Title__c,
CreatedBy.CommunityNickname,
CreatedDate,Community_Feed_Parent__r.createdDate
from Community_Feed__c
where Id=:feedId ];  */ 
            commentdetail.topicName = cfmain.Parentfeed__c;
            commentdetail.postTitle= cfmain.Title__c;
            commentdetail.childComment= cfmain.Title__c;
            commentdetail.parentComment= cf .Title__c;
            commentdetail.childCommunityNickName= cfmain.CreatedBy.CommunityNickname;
            commentdetail.parentCommunityNickName= cf.CreatedBy.CommunityNickname;
            commentdetail.childDateTime= cfmain.createdDate;
            commentdetail.parentDateTime= cf.createdDate;
            commentdetail.feedcommentId= cfmain.FeedCommentId__c;
            system.debug('cusSubRecord@@@'+csrec);   } return  commentDetail;
    }
    
    public class wrapper1{
        public  string  topicName{get;set;}
        public  string  postTitle{get;set;}
        public  string  childComment{get;set;}  
        public  string  parentComment{get;set;}
        public  string  childCommunityNickName{get;set;}
        public  string  parentCommunityNickName{get;set;}   
        public  dateTime childDateTime{get;set;}
        public  dateTime parentDateTime{get;set;}
        public  String feedcommentId{get;set;}
    }
    public string getcommunityURL(){
        List<Network> myCommunity = [SELECT Name,Id, UrlPathPrefix FROM Network WHERE Name ='Rubrik Support'];
        if(!test.isRunningTest()){ConnectApi.Community comm = ConnectApi.Communities.getCommunity(myCommunity[0].id);
            commURL=comm.siteUrl; } return commURL;
    }
    public String getRubrikLogoUrl(){
        list<Document> lstDocument = [SELECT Id FROM Document WHERE DeveloperName = 'Rubrik_logo_150_50'];
        String strOrgId = UserInfo.getOrganizationId();
        if(!test.isRunningTest()){ String strLogoUrl = System.URL.getSalesforceBaseUrl().toExternalForm() +  '/servlet/servlet.ImageServer?id='+lstDocument[0].Id +'&oid=' + strOrgId;
            return strLogoUrl;}
        else{ return ''; }
    }
    public String getCommentOwnerProfileImgURL(){
        Community_Feed__c cfmain = [SELECT Id,Parentfeed__c,CreatedBy.SmallPhotoUrl FROM Community_Feed__c WHERE Id =: feedId];
        String strLogoUrl = System.URL.getSalesforceBaseUrl().toExternalForm() + cfmain.CreatedBy.SmallPhotoUrl; return strLogoUrl;
    }
    public String getParentCommentOwnerProfileImgURL(){
        Community_Feed__c cfmain = [SELECT Id,Parentfeed__c,CreatedBy.SmallPhotoUrl FROM Community_Feed__c WHERE Id =: feedId];
        Community_Feed__c cf = [SELECT Id,CreatedBy.SmallPhotoUrl FROM Community_Feed__c WHERE Id =: cfmain.Parentfeed__c];
        String strLogoUrl = System.URL.getSalesforceBaseUrl().toExternalForm() + cf.CreatedBy.SmallPhotoUrl;return strLogoUrl;
    }
}