/**Test class for  SendChatterNotification*/
@isTest
private class SendChatterNotificationTest {
    @TestSetup
    static void setupData() {
        insert new ShGl_DisableBusinessLogic__c(SetupOwnerId=UserInfo.getUserId(),Disable_Opportunity_Triggers__c=true );

        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account acct = new Account(Name='testAccount', RecordTypeId = partnerRecordTypeId, Account_Deal_Desk_Notes__c = 'Test Notes');
        Account acc = new Account(Name='testAccount1');
        insert new List<Account>{acct, acc};

                                
        Opportunity oppr = TestDataFactory.getOpportunity(acct);
        insert oppr;
        
        PriceBook2 pb1  = new Pricebook2(Name = 'V68_2017_08_09_12_26_43', Description = 'Price Book 2009 Products 1', IsActive = true);
        insert pb1;
        
        Map<String, Object>  quoteMap = new Map<String, Object> {
                        'SBQQ__Account__c' => acct.Id,
                            'SBQQ__Opportunity2__c' => oppr.Id
                            };
                                
                                    
                                SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppr.Id;
        qt1.SBQQ__Primary__c = false;
        qt1.SBQQ__PriceBook__c = pb1.Id;
        qt1.ApprovalStatus__c = 'Approved';
        qt1.SBQQ__Type__c = 'Renewal';
        qt1.SBQQ__StartDate__c = Date.today();
        qt1.Manual_Billing__c = false;
        qt1.Consolidate_Lines__c = false;
        insert qt1;
        
    }
    
    
    @isTest
    static void testSendNotification() {
        
        List<SBQQ__Quote__c> listQuote = [SELECT Id, Name, Email_Sent__c FROM sbqq__quote__c LIMIT 1];
        //Map < Id, sbqq__quote__c > quotesmap = new Map < Id, sbqq__quote__c > ([SELECT Id, Name, Email_Sent__c FROM sbqq__quote__c where Id in: quoteids]);
        
        SBQQ__Quote__c testQuote = listQuote[0];
        
        Id testUserId = UserInfo.getUserId();
        Set<Id> userIdSet = new Set<Id>{testUserId};
        Map<Id, SBQQ__Quote__c> opptyOwnerQuoteIdMap = new Map<Id, SBQQ__Quote__c>{testUserId => testQuote};
        
        
        Test.startTest();
        SendChatterNotification.sendNotification(userIdSet, opptyOwnerQuoteIdMap, 'Created');
        SendChatterNotification.sendNotification(userIdSet, opptyOwnerQuoteIdMap, 'Approved');
        Test.stopTest();
        
        List<FeedItem> feedItems = [SELECT Id FROM FeedItem WHERE ParentId = :testUserId];
        System.assertEquals(1, feedItems.size());
    }
    
    @isTest
    static void testSendEmailNotification() {
        List<SBQQ__Quote__c> listQuote = [SELECT Id, Name, Email_Sent__c, SBQQ__Account__r.Name FROM sbqq__quote__c LIMIT 1];
        SBQQ__Quote__c testQuote = listQuote[0];
        
        Id testUserId = UserInfo.getUserId();
        System.debug(testUserId);
        Set<String> emailSet = new Set<String>{'test@example.com'};
        Map<Id, Set<String>> quoteIdEmailSet = new Map<Id, Set<String>>{testQuote.Id => emailSet};
        Map<Id, SBQQ__Quote__c> quoteNewMap = new Map<Id, SBQQ__Quote__c>{testQuote.Id => testQuote};
        
        Test.startTest();
        SendChatterNotification.sendEmailNotification(quoteIdEmailSet, 'Created', quoteNewMap);
        SendChatterNotification.sendEmailNotification(quoteIdEmailSet, 'Approved', quoteNewMap);
        System.assert(testQuote.Id !=null);
        Test.stopTest();
        
    }
    
}