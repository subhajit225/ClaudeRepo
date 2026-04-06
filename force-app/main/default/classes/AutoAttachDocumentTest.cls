@isTest
public class AutoAttachDocumentTest {
    
    @isTest
    public static void testAutoAttachDocument(){
        //triggers
        ShGl_DisableBusinessLogic__c dbl = ShGl_DisableBusinessLogic__c.getInstance();
        dbl.Disable_Account_Triggers__c = true;
        dbl.Disable_Opportunity_Triggers__c = true;
        dbl.Disable_SBQQ_Quote_Triggers__c = true;
        dbl.Disable_SBQQ_QuoteLine_Triggers__c = true;
        insert dbl;
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        
        
        //create account
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Type='Distributor';
        acc.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        insert acc;
        
        //create opp
        Opportunity opportunityObj = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opportunityObj.AccountId = acc.Id;
        opportunityObj.Name = 'Testing Opportunity';
        opportunityObj.CloseDate = System.today().addMonths(12);
        opportunityObj.StageName = 'Prospecting';
        opportunityObj.Pricebook2Id = Test.getStandardPricebookId();
        insert opportunityObj;
        
        //create quote 
        SBQQ__Quote__c quoteObj= new SBQQ__Quote__c(SBQQ__Account__c=acc.Id,
                                                    SBQQ__Opportunity2__c=opportunityObj.Id,
                                                    SBQQ__StartDate__c=System.today(),
                                                    SBQQ__Primary__c=true,
                                                    SBQQ__SubscriptionTerm__c = 36,
                                                    SBQQ__ExpirationDate__c = System.today().addYears(1)
                                                   );
        insert quoteObj;
        
        //create document
        SBQQ__QuoteDocument__c doc = new SBQQ__QuoteDocument__c(
            SBQQ__Quote__c = quoteObj.Id
        );
        insert doc;
        
        List<SBQQ__Quote__c> quotes = [SELECT Id, SBQQ__Opportunity2__c, (SELECT Id FROM SBQQ__R00N70000001lX7YEAU__r) FROM SBQQ__Quote__c WHERE Id=:quoteObj.Id];
        
        Test.startTest();
        AutoAttachDocument autoAttach = new AutoAttachDocument(quotes);
        System.enqueueJob(autoAttach);
        Test.stopTest();
        
    }
    
}