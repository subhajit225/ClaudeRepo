@isTest
public class CloneQuotewithQLIs_Test{
    
    public static testMethod void cloneQuoteTest(){
        ShGl_TestFactoryHelper.insertTriggerControls();
        SBQQ_QuoteLineTriggerHandler handler = new SBQQ_QuoteLineTriggerHandler();
        Test.startTest();
        
        Product2 prod = new Product2(Name='TestProd', IsActive=true, Quotable_Date__c = System.Today().addDays(-5));  
        insert prod;
        
        Account acc = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert acc;
        
        List<Account> accountList = new List<Account>();
        Account vAccount = new Account();
        accountList.add(vAccount);
        vAccount.Name = 'Test Account';
        vAccount.Type='Distributor';
        vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
        Account vAccount2 = new Account();
        vAccount2.Name = 'Test Account';
        vAccount2.recordTypeId = vAccount.recordTypeId;
        accountList.add(vAccount2);
        insert accountList;
        
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {'AccountId' => acc.Id};
            
            Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        insert(opp);
        
        opp.Partner_Lookup__c = vAccount2.id;
        opp.Distributor_Lookup__c = vAccount.id;
        update opp;
        
        Asset asset = new Asset();
        asset.Name = '123456';
        asset.Serial_Number__c = '123456';
        asset.AccountId = acc.id;
        asset.Product2Id = prod.Id;
        insert asset;
         List<PricebookEntry>entries = new List<PricebookEntry>();
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, IsActive = true, 
                                       UnitPrice = 100));
                                       
        SBQQ__Quote__c q = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp.Id, SBQQ__PriceBook__c = Test.getStandardPricebookId());        
        insert(q);
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prod.Id, SBQQ__Quantity__c=10, SBQQ__Number__c=1, 
                                                         SBQQ__SubscribedAssetIds__c=asset.Id,SubscribedAssetNames__c = 'BB192863040046' );  
        insert qli1;
        

       
        set<ID> quotedIDs = new set<ID>();
        quotedIDs.add(q.ID);
        CloneQuotewithQLIs cloneQuoteBatchInst = new CloneQuotewithQLIs(quotedIDs);
        Database.executeBatch(cloneQuoteBatchInst, 1);
        Map<Id, Id> oldToNewQuoteMap = new  Map<Id, Id>();
        oldToNewQuoteMap.put(q.ID,q.ID);
        cloneQuoteBatchInst.cloneSObject(oldToNewQuoteMap, 'SBQQ__QuoteLine__c', 'SBQQ__Quote__c');
        Test.stopTest();
    }
}