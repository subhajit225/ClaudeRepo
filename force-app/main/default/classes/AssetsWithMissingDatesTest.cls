@isTest
private class AssetsWithMissingDatesTest {
    
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

        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(Name='RBK-Test-Prod'), prdMap);
        insert prdHW;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pBList.add(pbeHW);
        insert pBList;
        List<Asset> assetList = new List<Asset>();
        List<Asset> astList = (List<Asset>) ShGl_TestFactory.createSObjectList(new Asset(Product2Id = prdHW.Id), actList.size() * 5, null);
        
        for(Integer i = 0; i < astList.size(); i++){
            astList.get(i).AccountId = actList.get(MATH.mod(i, actList.size())).Id;
            astList.get(i).Status = 'Purchased';
            astList.get(i).SerialNumber = 'AA012345678910';
            astList.get(i).Support_Start_Date__c = null;
            astList.get(i).Premium_Support_End_Date__c = null;
            assetList.add(astList.get(i));
        }
        insert astList;

        System.debug(astList);
        Test.startTest();
        Test.setCurrentPage(Page.AssetsWithMissingDates);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(assetList);
        stdSetController.setSelected(astList);
        AssetsWithMissingDatesController cont = new AssetsWithMissingDatesController();
        List<Asset> assetsReturned = cont.getAssets();
        System.assertEquals(actList.size() * 5, assetsReturned.size());
        System.assertEquals(false, cont.hasNext);
        System.assertEquals(false, cont.hasPrevious);
        cont.next();
        cont.previous();

        //System.schedule('AssetsWithMissingDatesAlert', '0 0 2 * * ?', new AssetsWithMissingDatesAlert());
        System.schedule('EntitlementsWithMissingAssetsEmailAlert1', '0 0 2 * * ?', new AssetsAndEntitlementsEmailAlert());
        Test.stopTest();
    }
    
}