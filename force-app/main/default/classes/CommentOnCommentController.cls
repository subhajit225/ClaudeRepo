//Contains logic for sending emails to the customer who have subscribed a post
public without sharing class CommentOnCommentController {
    
    public String subId {get;set;}
    public string commURL;
    public wrapper1 getCommentInfo(){
        wrapper1 commentDetail = new wrapper1();
        
        system.debug('cusSubId'+subId);
        if(subId != null){
            Customer_Subscription__c csrec=[Select Id,Title__c,Topic_Name__c,Topic_Id__c,Community_Feed__c from Customer_Subscription__c where Id=:subId ];
            Community_Feed__c cfmain = [SELECT Id,Parentfeed__c,Title__c,Community_Feed_Parent__c,CreatedBy.CommunityNickname,CreatedDate,FeedCommentId__c FROM Community_Feed__c WHERE Id =: csrec.Community_Feed__c];
            Community_Feed__c cf = [SELECT Id,Title__c,CreatedBy.CommunityNickname,CreatedDate FROM Community_Feed__c WHERE Id =: cfmain.Parentfeed__c];
            
            commentdetail.topicName = cfmain.Parentfeed__c;
            commentdetail.postTitle= csrec.Title__c;
            commentdetail.childComment= cfmain.Title__c;
            commentdetail.parentComment= cf .Title__c;
            commentdetail.childCommunityNickName= cfmain.CreatedBy.CommunityNickname;
            commentdetail.parentCommunityNickName= cf.CreatedBy.CommunityNickname;
            commentdetail.childDateTime= cfmain.createdDate;
            commentdetail.parentDateTime= cf.createdDate;
            commentdetail.feedcommentId= cfmain.FeedCommentId__c;
        }
        
        return  commentDetail;
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
        Customer_Subscription__c csrec=[Select Id,Title__c,Topic_Name__c,Topic_Id__c,Community_Feed__c from Customer_Subscription__c where Id=:subId ];
        Community_Feed__c cfmain = [SELECT Id,Parentfeed__c,CreatedBy.SmallPhotoUrl FROM Community_Feed__c WHERE Id =: csrec.Community_Feed__c];
        String strLogoUrl = System.URL.getSalesforceBaseUrl().toExternalForm() + cfmain.CreatedBy.SmallPhotoUrl;
        return strLogoUrl;
        
    }
    public String getParentCommentOwnerProfileImgURL(){
        Customer_Subscription__c csrec=[Select Id,Title__c,Topic_Name__c,Topic_Id__c,Community_Feed__c from Customer_Subscription__c where Id=:subId ];
        Community_Feed__c cfmain = [SELECT Id,Parentfeed__c,CreatedBy.SmallPhotoUrl FROM Community_Feed__c WHERE Id =: csrec.Community_Feed__c];
        Community_Feed__c cf = [SELECT Id,CreatedBy.SmallPhotoUrl FROM Community_Feed__c WHERE Id =: cfmain.Parentfeed__c];
        String strLogoUrl = System.URL.getSalesforceBaseUrl().toExternalForm() + cf.CreatedBy.SmallPhotoUrl;
        return strLogoUrl;
        
    }
}