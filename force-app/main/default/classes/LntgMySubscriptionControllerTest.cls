@isTest 
public class LntgMySubscriptionControllerTest {
    static testmethod void LntgMySubscriptionControllerTest(){
        
        List<Customer_Subscription__c> cs = new List<Customer_Subscription__c>();
        //Id userLicenseId = [ select Id from UserLicense where NAME LIKE '%Customer Community%' LIMIT 1].id;
        //Id communityprofileId = [select Id from Profile where name like '%Customer Community%' and UserLicenseId=:userLicenseId].id;    
        //Account acc = new Account(name ='Test Account') ;
        //Database.insert(acc); 
        
        //Contact con = new Contact(AccountId = acc.Id,LastName ='test Last', FirstName = 'Test First',   Email = System.now().millisecond() + 'test@test.com');
        //Database.insert(con);
        //User userInfo = new User(alias = 'test123', email='test123@noemail.com',emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',localesidkey='en_US', profileid = communityprofileId, country='United States',IsActive =true,FirstName = 'Test First', timezonesidkey='America/Los_Angeles', username='tester@noemail.com',ContactId = con.Id);
        
        
        
        //Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        //User userInfo = new User(Alias = 'test', Email='test4@test.com',EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US', ProfileId = p.Id,TimeZoneSidKey='America/Los_Angeles', UserName='test4@test.com');
        //system.runAs(userInfo){
        //
        Customer_Subscription__c a = new Customer_Subscription__c(Article_Number__c ='TestAccount',Title__c='Title',user__c = UserInfo.getUserId(),Category_Label__c='label',KB_ID__c='kA01W0000000Y7nSAE',Type__c = 'Article');
        How_To__kav kav = new How_To__kav(UrlName='URL',Title='Title');
        insert a;
        insert kav;
        how_to__kav articleToPublish = [select id,KnowledgeArticleId from how_to__kav where Id =: kav.Id];
        KbManagement.PublishingService.publishArticle(articleToPublish.KnowledgeArticleId, true);
        LntgMySubscriptionController.mySubscriptionController();
        
        
        LntgMySubscriptionController.getSubscribedList();  
        system.debug('Debuging >>> '+ a);
        LntgMySubscriptionController.SubscribedRecord sub = new LntgMySubscriptionController.SubscribedRecord(a,'test','test',true);
        LntgMySubscriptionController.DelRecord(a.KB_ID__c);
    }
}