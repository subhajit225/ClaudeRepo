@isTest
private class QuoteLineMain_Test {
    testMethod static void testMethod_1() {
        ShGl_TestFactoryHelper.insertTriggerControls();
        Id pb = Test.getStandardPricebookId();//[  select Id,createddateby from Pricebook2 where isStandard=true];
        Product2 prod= new Product2(Name='TestProd', IsActive=true);  
        Product2 prodSupp = new Product2(Name='TestProdSupport', IsActive=true);  
        Product2 prodSub = new Product2(Name='TestProdSubscription', IsActive=true);  
        List<Product2> prdList = new List<Product2> {prod, prodSupp, prodSub}; 
            insert prdList;  
        
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=pb, Product2Id=prod.Id, IsActive=true, UnitPrice=10);    
        PricebookEntry pbeSupp = new PricebookEntry(Pricebook2Id=pb, Product2Id=prodSupp.Id, IsActive=true, UnitPrice=10);    
        PricebookEntry pbeSub = new PricebookEntry(Pricebook2Id=pb, Product2Id=prodSub.Id, IsActive=true, UnitPrice=10);    
        List<PricebookEntry> pbeList = new List<PricebookEntry> {pbe,pbeSupp, pbeSub}; 
            insert pbeList;
        
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
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => acc.Id
                };
                    
                    Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        insert(opp);
            
            vAccount2.Distributor__c = vAccount.id;
            update vAccount2;
            
            opp.Partner_Lookup__c = vAccount2.id;
            opp.Deal_Registration_Type__c = '';
            opp.Teaming_Partner__c = null;
        opp.Distributor_Lookup__c = vAccount.id;
        update opp;
        
        Asset asset = new Asset();
        asset.Name = '123456';
        asset.Serial_Number__c = '123456';
        asset.AccountId = acc.id;
        asset.Product2Id = prod.Id;
        insert asset;
        
        Test.startTest(); 
        
        SBQQ__Quote__c q = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp.Id);        
        insert(q);
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prod.Id, SBQQ__Quantity__c=10, SBQQ__Number__c=1, 
                                                         SBQQ__SubscribedAssetIds__c=asset.Id,SubscribedAssetNames__c = 'BB192863040046' );  
        insert qli1;
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodSupp.Id, SBQQ__Quantity__c=10, SBQQ__Number__c=2, 
                                                         SBQQ__SubscriptionTerm__c=12, Is_Premium_Support__c=TRUE, SubscribedAssetNames__c = 'BB192863040046'); 
       
        SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodSub.Id, SBQQ__Quantity__c=10, SBQQ__Number__c=3, 
                                                         SBQQ__SubscriptionTerm__c=12, SubscribedAssetNames__c = 'BB192863040046');
        
        qli2.SBQQ__RequiredBy__c=qli1.id;
        qli3.SBQQ__RequiredBy__c=qli1.id;
        
        qliList.add( qli2 );//insert qli2;
        qliList.add( qli3 );//insert qli3;
        
        
        
        //SBQQ_QuoteLineTriggerHelper.populateBundlePremiumSupportAndSubscriptionTerm(qliList);
        insert qliList;
        Test.stopTest();
    }
}