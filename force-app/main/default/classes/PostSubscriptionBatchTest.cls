@isTest
public class PostSubscriptionBatchTest {

    @testSetup static void setup() {
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
                            //Allow_weekly_notification__c=true,
                            LocaleSidKey ='en_US'
                           );
        insert usr;
        system.debug('usrId@@@@@@@'+usr.Id);
        Network rubrikSupport =[Select id,Name from Network where Name='Rubrik Support' limit 1];
        FeedItem ques1= new  FeedItem();
        ques1.NetworkScope=rubrikSupport.id;
        ques1.ParentId=usr.id;
        ques1.Title='TitleTest';
        ques1.Type='QuestionPost';
        insert ques1;

        Topic  testTopic = new   Topic();
        testTopic.Name='TestTopic';
        testTopic.NetworkId=rubrikSupport.id;
        insert  testTopic;

        EntitySubscription esub= new EntitySubscription();
        esub.ParentId=testTopic.id;
        esub.NetworkId=rubrikSupport.id;
        esub.SubscriberId=usr.id;
        insert esub;

        TopicAssignment topictestass= new   TopicAssignment();
        topictestass.EntityId=ques1.id;
        topictestass.TopicId=testTopic.id;
        topictestass.NetworkId=rubrikSupport.id;
        insert topictestass;
    }

     static testMethod void batchTest () {
        Test.startTest();//WHERE DAY_ONLY(CreatedDate) >=: sevenDaysBackDate
         String cronExpr = '0 0 0 15 3 ? 2024';
         PostSubscribtionScheduler pss =new PostSubscribtionScheduler();
         system.schedule('testjob', cronExpr, pss);
         pss.execute(null);
        //String q='SELECT CreatedById,CreatedDate,EntityId,EntityKeyPrefix,EntityType,Id,IsDeleted,NetworkId,SystemModstamp,TopicId,Topic.Name FROM TopicAssignment ';
        //PostSubscriptionBatch bC = new  PostSubscriptionBatch(q);
        //ID batchprocessid = Database.executeBatch( bC,200);
        Test.stopTest();
    }
}