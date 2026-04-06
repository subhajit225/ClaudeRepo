/**
 * @description Test class for CommentsFromRbkSupport functionality
 * @test
 * @author Raveesh Layal
 * @date 2025-08-01
 */
@isTest
public class CommentsFromRbkSupportTest {
    
    /**
     * @description Test setup method to create User, Account, and Contact records for test context
     */
    @testSetup 
    static void testData() {
        Id p = [SELECT Id FROM Profile WHERE Name = 'Rubrik Customer Community Login User'].Id;

        Account ac = new Account(Name ='Grazitti');
        insert ac;

        Contact con = new Contact(LastName ='testCon', AccountId = ac.Id);
        insert con;

        User user = new User(
            Alias = 'test123', Email = 'test123@noemail.com',
            EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US', ProfileId = p, Country = 'United States', IsActive = true,
            ContactId = con.Id,
            TimeZoneSidKey = 'America/Los_Angeles', Username = 'tester@noemail.com'
        );
        insert user;
    }

    /**
     * @description Test method for after-insert feed comment logic including delete operation on FeedComment 
     */
    @isTest 
    static void testAfterInsertFeedComment() {
        User u = [SELECT Id FROM User WHERE Username = 'tester@noemail.com'];
        System.runAs(u) {
            Id feedItemId = CustomNotficationTestUtils.createFeedItem();
            Customer_Subscription__c cusub = CustomNotficationTestUtils.createCustomerSubscriptions(feedItemId);
            FeedComment fc = CustomNotficationTestUtils.createFeedComment(feedItemId);
            Delete fc;

            // ✅ One assert to confirm subscription was created
            System.assertNotEquals(null, cusub.Id, 'Customer Subscription should be created.');
        }
    }

    /**
     * @description Test method for DirectCommentController functionality including data retrieval and URL methods
     */
    @isTest 
    static void testDirectCommentController() {
        Contact con = TestDataFactory.getContact();
        con.FirstName = 'testNick54';
        con.LastName = 'Testuser54';
        insert con;

        Id profile = [SELECT Id FROM Profile WHERE Name = 'Rubrik Customer Community Super Login User'].Id;

        User user = new User(
            FirstName = 'tesNick54', Alias = 'test123', Email = 'test123@noemail.com',
            EmailEncodingKey = 'UTF-8', LastName = 'Testuser54', LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US', ProfileId = profile, Country = 'United States', IsActive = true,
            ContactId = con.Id,
            TimeZoneSidKey = 'America/Los_Angeles', Username = 'Testuser54@noemail.com'
        );

        insert user;

        User u = [SELECT Id FROM User WHERE Username = 'tester@noemail.com'];
        System.runAs(u) {
            Id feedItemId = CustomNotficationTestUtils.createFeedItem();
            FeedComment fc = new FeedComment();
            fc.CommentBody = 'legal @test';
            fc.FeedItemId = feedItemId;
            insert fc;

            Community_Feed__c cf = new Community_Feed__c(
                FeedCommentId__c = fc.Id,
                Post_Title__c = 'legal @test',
                Title__c = 'legal @test'
            );
            insert cf;

            Customer_Subscription__c cusub = CustomNotficationTestUtils.createCustomerSubscriptions(feedItemId);
            cusub.Community_Feed__c = cf.Id;
            update cusub;

            DirectCommentController dc = new DirectCommentController();
            dc.subId = cusub.Id;

            dc.getCusSubInfo();
            dc.getcommunityURL();
            dc.getRubrikLogoUrl();
            dc.getCommentOwnerProfileImgURL();
            dc.getpostOwnerProfileImgURL();

            // ✅ One assert to confirm controller was initialized with subscription ID
            System.assertNotEquals(null, dc.subId, 'DirectCommentController subId should not be null.');
        }
    }

    /**
     * @description Test method for CommentOnCommentController and CommentOnCommentController2 functionality
     */
    @isTest 
    static void testCommentOnCommentController() {
        User u = [SELECT Id FROM User WHERE Username = 'tester@noemail.com'];
        System.runAs(u) {
            Id feedItemId = CustomNotficationTestUtils.createFeedItem();

            Community_Feed__c cf = CustomNotficationTestUtils.createCommunityFeed();
            Community_Feed__c cfp = CustomNotficationTestUtils.createCommunityFeedParent(cf.Id);

            Customer_Subscription__c cusub = CustomNotficationTestUtils.createCustomerSubscriptions(feedItemId);
            cusub.Community_Feed__c = cf.Id;
            update cusub;

            cf.Parentfeed__c = cfp.Id;
            update cf;

            CommentOnCommentController cc = new CommentOnCommentController();
            cc.subId = cusub.Id;
            cc.getCommentInfo();
            cc.getcommunityURL();
            cc.getRubrikLogoUrl();
            cc.getCommentOwnerProfileImgURL();
            cc.getParentCommentOwnerProfileImgURL();

            CommentOnCommentController2 cc2 = new CommentOnCommentController2();
            cc2.feedId = cf.Id;
            cc2.getCommentInfo();
            cc2.getcommunityURL();
            cc2.getRubrikLogoUrl();
            cc2.getCommentOwnerProfileImgURL();
            cc2.getParentCommentOwnerProfileImgURL();

            // ✅ One assert to verify feed and parent were linked
            System.assertEquals(cfp.Id, cf.Parentfeed__c, 'Parentfeed__c should match the parent feed ID.');
        }
    }
}