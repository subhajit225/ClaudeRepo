@isTest
private class EntitlementsWithMissingAssets_Test {
     
    @isTest static void test_method_one() {
        ShGl_TestFactoryHelper.insertTriggerControls();

        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        
        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        prdHW.ProductCode = 'RBK-SVC-test-product';
        prdHW.Category__c = 'Support';
        insert prdHW;
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        insert pbeHW;
        
        Entitlement ent = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        ent.AccountId = act.Id;
        ent.Product__c = prdHW.Id;
        ent.StartDate = Date.today().addDays(-365);
        ent.EndDate = Date.today().addDays(365);
        insert ent;

        List<Entitlement> entList = new List<Entitlement>();
        entList.add(ent);

        Test.startTest();
        Test.setCurrentPage(Page.EntitlementsWithMissingAssets);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(entList);
        stdSetController.setSelected(entList);
        EntitlementsWithMissingAssetsController cont = new EntitlementsWithMissingAssetsController();
        List<Entitlement> entitlementsReturned = cont.getEntitlements();
        //System.assertEquals(1, entitlementsReturned.size());
        System.assertEquals(false, cont.hasNext);
        System.assertEquals(false, cont.hasPrevious);
        cont.next();
        cont.previous();

       // System.schedule('EntitlementsWithMissingAssetsEmailAlert', '0 0 2 * * ?', new EntitlementsWithMissingAssetsEmailAlert());
         DateTime scheduleTime = Datetime.now().addminutes(1);
                String hour = String.valueOf(scheduleTime.hour()); 
                String minute = String.valueOf(scheduleTime.minute());
                String second = String.valueOf(scheduleTime.second());  
                String nextFireTime = '0 ' + minute + ' ' + hour + ' ' + String.valueOf(scheduleTime.day()) + ' ' + String.valueOf(scheduleTime.month()) + ' ?' + ' ' + String.valueOf(scheduleTime.year());
                 
                // System.schedule('AssetsAndEntitlementsEmailAlert' + String.valueOf(Datetime.now()), nextFireTime, new AssetsAndEntitlementsEmailAlert());
                  System.schedule('EntitlementsWithMissingAssetsEmailAlert1', '0 0 2 * * ?', new AssetsAndEntitlementsEmailAlert());
        Test.stopTest();
    }
}