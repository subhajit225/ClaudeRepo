@isTest
private class DuplicateEntitlementsTest {
    
    @isTest static void test_method_one() {
        ShGl_TestFactoryHelper.insertTriggerControls();

        Map<String, Object> accMap = new Map<String, Object> {
            'Name' => 'testMethod_ContractCreation'
        };
        List<Account> actList = (List<Account>) ShGl_TestFactory.createSObjectList(new Account(), 2, accMap);
        insert actList;

        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
            'IsActive' => true,
            'SBQQ__AssetConversion__c' => 'One per unit'
        };

        Map<String, Object> prdMap1 = new Map<String, Object> {
            'Name' => 'Subscription', 
            'IsActive' => true, 
            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
            'SBQQ__SubscriptionTerm__c' => 12, 
            'SBQQ__SubscriptionType__c' => 'Renewable'
        };

        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdHW1 = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        
        prdList.add(prdHW);
        prdList.add(prdHW1);
        prdList.add(prdSubs);
        insert prdList;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pBList.add(pbeHW);

        PricebookEntry pbeHW1 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW1.Product2Id = prdHW1.Id;
        pBList.add(pbeHW1);

        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pBList.add(pbeSubs);
        insert pBList;

        List<Asset> astList = (List<Asset>) ShGl_TestFactory.createSObjectList(new Asset(Product2Id = prdHW.Id), actList.size() * 5, null);
        for(Integer i = 0; i < astList.size(); i++){
            astList.get(i).AccountId = actList.get(MATH.mod(i, actList.size())).Id;
        }
        insert astList;

        List<ServiceContract> scList = (List<ServiceContract>) ShGl_TestFactory.createSObjectList(new ServiceContract(PriceBook2Id = Test.getStandardPricebookId()), astList.size(), null);
        for(Integer i = 0; i < scList.size(); i++){
            scList.get(i).AccountId = actList.get(MATH.mod(i, actList.size())).Id;
        }
        insert scList;

        List<ContractLineItem> cliList = new List<ContractLineItem>();
        Map<String, Object> cliMap = new Map<String, Object> {
            'StartDate' => Date.Today() - 90,
            'EndDate' => Date.Today().addDays(365),
            'Quantity' => 1
        };

        List<ContractLineItem> clis = null;
        clis = (List<ContractLineItem>) ShGl_TestFactory.createSObjectList(new ContractLineItem(PricebookEntryId = pbeHW.Id, UnitPrice = pbeHW.UnitPrice), astList.size(), cliMap);
        for(Integer i = 0; i < clis.size(); i++){
            clis.get(i).AssetId = astList.get(MATH.mod(i, astList.size())).Id;
            clis.get(i).ServiceContractId = scList.get(MATH.mod(i, scList.size())).Id;
        }
        cliList.addAll(clis);

        clis = (List<ContractLineItem>) ShGl_TestFactory.createSObjectList(new ContractLineItem(PricebookEntryId = pbeSubs.Id, UnitPrice = pbeSubs.UnitPrice), astList.size(), cliMap);
        for(Integer i = 0; i < clis.size(); i++){
            clis.get(i).AssetId = astList.get(MATH.mod(i, astList.size())).Id;
            clis.get(i).ServiceContractId = scList.get(MATH.mod(i, scList.size())).Id;
        }
        cliList.addAll(clis);
        
        insert cliList;

        Entitlement ent = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        ent.AccountId = actList[0].Id;
        ent.Product__c = prdSubs.Id;
        ent.StartDate = Date.today().addDays(-365);
        ent.EndDate = Date.today().addDays(365);
        ent.ContractLineItemId = cliList[0].Id;
        ent.AssetId = astList[0].Id;

        List<Entitlement> entList = new List<Entitlement>();
        entList.add(ent);

        Entitlement ent2 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        ent2.AccountId = actList[0].Id;
        ent2.Product__c = prdSubs.Id;
        ent2.StartDate = Date.today().addDays(-365);
        ent2.EndDate = Date.today().addDays(365);
        ent2.ContractLineItemId = cliList[0].Id;
        ent2.AssetId = astList[0].Id;
        entList.add(ent2);

        insert entList;

        Test.startTest();
        Test.setCurrentPage(Page.duplicateEntitlements);
        System.schedule('DuplicateEntitlementsEmailAlert1', '0 0 2 * * ?', new DuplicateEntitlementsEmailAlert());
        System.schedule('EntitlementsWithMissingAssetsEmailAlert1', '0 0 2 * * ?', new AssetsAndEntitlementsEmailAlert());
        Test.stopTest();
    }
}