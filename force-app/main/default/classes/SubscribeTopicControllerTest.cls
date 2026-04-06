/**
 * @description Test class for SubscribeTopicController to validate topic subscription functionality in community networks
 * @test
 * @author Raveesh Layal
 * @date 2025-08-01
 */
@isTest 
public class SubscribeTopicControllerTest {
    
    /**
     * @description Setup method to create test data that will be used across all test methods
     * Creates:
     * - Test Account
     * - Test Contact
     * - Test User with Community profile
     */
    @testSetup 
    static void setup() {
        Account ac = new Account(name ='Grazitti');
        insert ac;
        
        Contact con = new Contact(LastName ='testCon', AccountId = ac.Id);
        insert con;
        
        Profile profileId = [SELECT Id FROM Profile WHERE Name ='Rubrik Community Super User' LIMIT 1];
        
        User usr = new User(
            LastName = 'LIVESTON',
            FirstName='JASON',
            Alias = 'jliv',
            Email = 'jason.liveston@asdf.com',
            Username = 'jason.liveston@asdf.com',
            ProfileId = profileId.id,
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ContactId=con.id,
            LocaleSidKey ='en_US',
            IsActive=true
        );  
        insert usr;
    }
    
    /**
     * @description Tests the getSusbcriptionInfo method of SubscribeTopicController
     * Verifies:
     * - Subscription status for a topic can be retrieved
     * - unsubscribe and subscribe operations work as expected
     * - Topic information can be retrieved
     */
    @isTest  
    static void getSubscriptionInfo(){
        User testu = [Select id from user limit 1];
        User user1 = [Select ProfileId,LastName from User WHERE Email='jason.liveston@asdf.com'];
        
        System.runAs(user1){
            List<NetworkMember> membership = [SELECT network.name, networkId, memberID FROM NetworkMember WHERE network.name ='Rubrik Support' limit 1];   
            
            // Create test topic
            Topic tp = new Topic();
            tp.Description='Test';
            tp.Name='Testname';
            tp.NetworkId=membership[0].networkId;
            insert tp;
            
            // Create test subscription
            EntitySubscription esub= new EntitySubscription();
            esub.ParentId=tp.id;
            esub.NetworkId=membership[0].networkId;  
            esub.SubscriberId=UserInfo.getUserId();
            insert esub;
            
            // Test get subscription info
            Boolean isSubscribed = SubscribeTopicController.getSusbcriptionInfo(membership[0].networkId,tp.Id);
            System.assertEquals(true, isSubscribed, 'User should be subscribed to the topic');
            
            // Test unsubscribe
            Boolean unsubResult = SubscribeTopicController.unSubscribe(membership[0].networkId,tp.Id);
            System.assertEquals(true, unsubResult, 'Unsubscribe should succeed');
            
            // Test subscribe
            Boolean subResult = SubscribeTopicController.subscribe(membership[0].networkId,tp.Id);
            System.assertEquals(true, subResult, 'Subscribe should succeed');
            
            // Verify topic info can be retrieved
            TopicInfoController.getTopicInfo(membership[0].networkId,tp.Id);
        }
    }
    
    /**
     * @description Tests the exception handling in the subscribe method
     * Verifies:
     * - Method returns false when invalid network/topic IDs are provided
     * - Exception handling works as expected
     */
    @isTest
    static void testSubscribeException(){
        User user1 = [Select ProfileId,LastName from User WHERE Email='jason.liveston@asdf.com'];
        System.runAs(user1){
            Boolean result = SubscribeTopicController.subscribe('invalidNetworkId', 'invalidTopicId');
            System.assertEquals(false, result, 'Should return false for invalid IDs');
        }
    }
}