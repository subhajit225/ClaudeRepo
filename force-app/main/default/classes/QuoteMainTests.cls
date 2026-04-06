@isTest
private class QuoteMainTests {
    
    testMethod static void testMethod_1() {
        
        ShGl_TestFactoryHelper.insertTriggerControls();

        Id pb = Test.getStandardPricebookId();
        Product2 prod = new Product2(Name='TestProd', IsActive=true);  
        insert prod;  
        
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=pb, Product2Id=prod.Id, IsActive=true, UnitPrice=10);    
        insert pbe;
        
        Account acc = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert acc;

        Map<String, Object> oppMap = new Map<String, Object> {
            'AccountId' => acc.Id,
            'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId()
        };

        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);      
        insert opp;
        
        Test.startTest(); 
        
        SBQQ__Quote__c q = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp.Id);        
        insert(q);
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prod.Id, SBQQ__Quantity__c=10, SBQQ__Number__c=1 );  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prod.Id, SBQQ__RequiredBy__c=qli1.id, SBQQ__Quantity__c=10, SBQQ__Number__c=2); 
        SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prod.Id, SBQQ__RequiredBy__c=qli1.id, SBQQ__Quantity__c=10, SBQQ__Number__c=3);
        qliList.add( qli1 );
        qliList.add( qli2 );
        qliList.add( qli3 );
        insert qliList;
        
        q.SBQQ__Primary__c = true;
        update q;
        
        Test.stopTest();
    }
    
}