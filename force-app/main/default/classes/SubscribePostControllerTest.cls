@isTest(seeAllData=True)
public class SubscribePostControllerTest { 
    @isTest  static  void testConnecAPimethods(){
        
        Account ac = new Account(name ='Grazitti') ;
        insert ac;
        Contact con = new Contact(LastName ='testCon',AccountId = ac.Id);
        insert con;
        Profile profileId = [SELECT Id FROM Profile WHERE Name ='Rubrik Community Super User' LIMIT 1];
        
        User usr = new User(LastName = 'LIVESTON',
                            FirstName='JASON',
                            Alias = 'jliv',
                            Email = 'jason.liveston@asdf.com',
                            Username = 'jason.liveston@asdf.com',
                            ProfileId = profileId.id,
                            TimeZoneSidKey = 'GMT',
                            LanguageLocaleKey = 'en_US',
                            EmailEncodingKey = 'UTF-8',
                            ContactId=con.id,
                            LocaleSidKey ='en_US'
                           );      
        
        Network rubrikSupport =[Select id,Name from Network where Name='Rubrik Support' limit 1];
        FeedItem ques1= new  FeedItem();
        ques1.NetworkScope=rubrikSupport.id;
        ques1.ParentId=UserInfo.getUserId();
        ques1.Title='TitleTest';
        ques1.Type='QuestionPost';
        insert ques1;
        
        Topic  testTopic = new   Topic();
        testTopic.Name='TestTopic';
        testTopic.NetworkId=rubrikSupport.id;
        insert  testTopic;
        
        TopicAssignment topictestass= new   TopicAssignment();
        topictestass.EntityId=ques1.id;
        topictestass.TopicId=testTopic.id;
        topictestass.NetworkId=rubrikSupport.id;
        insert topictestass;
        
        
        SubscribePostController.getBookmarkInfo(rubrikSupport.id, ques1.id);
        boolean addBookMarkInfo= SubscribePostController.addBookMark(rubrikSupport.id, ques1.id,true);
        boolean removeBookMarkInfo =SubscribePostController.removeBookMark(rubrikSupport.id, ques1.id,true,UserInfo.getUserId());
        addBookMarkInfo= SubscribePostController.addBookMark(rubrikSupport.id, ques1.id,true);
        SubscribePostController.unsubscribeAll();
        system.assertEquals(true, addBookMarkInfo);
        system.assertEquals(true, removeBookMarkInfo);
        
    }
    
    @isTest  static  void getSubscriptionInfoTest(){
        
        Account ac = new Account(name ='Grazitti') ;
        insert ac;
        Contact con = new Contact(LastName ='testCon',AccountId = ac.Id);
        insert con;
        Profile profileId = [SELECT Id FROM Profile WHERE Name ='Rubrik Community Super User' LIMIT 1];
        
        User usr = new User(LastName = 'LIVESTON',
                            FirstName='JASON',
                            Alias = 'jliv',
                            Email = 'jason.liveston@asdf.com',
                            Username = 'jason.liveston@asdf.com',
                            ProfileId = profileId.id,
                            TimeZoneSidKey = 'GMT',
                            LanguageLocaleKey = 'en_US',
                            EmailEncodingKey = 'UTF-8',
                            ContactId=con.id,
                            LocaleSidKey ='en_US'
                           );
        List<NetworkMember> membership = [SELECT network.name, networkId, memberID FROM NetworkMember WHERE network.name ='Rubrik Support'  limit 1];   
        system.debug('membership'+membership);
        
        Topic tp = new Topic();
        tp.Description='Test';
        tp.Name='Testname';
        tp.NetworkId=membership[0].networkId;
        insert tp;
        
        FeedItem fd= new FeedItem();
        fd.Body='testbody';
        fd.Title='testtitle';
        fd.Status='Published';
        fd.ParentId=UserInfo.getUserId();
        Insert fd;
        
        List<Customer_Subscription__c> customersubs= new List<Customer_Subscription__c>();
        Customer_Subscription__c cs= new Customer_Subscription__c();
        cs.Type__c='FeedItem';
        cs.KB_ID__c=fd.Id;
        cs.Title__c='Test';
        cs.Topic_Name__c='TestName1';
        cs.Topic_Id__c='01';
        cs.User__c=UserInfo.getUserId();
        customersubs.add(cs);
        
        insert customersubs;
        
        
        SubscribePostController.getPostSubscriptionInfo();
        
        
    }
    
    
}