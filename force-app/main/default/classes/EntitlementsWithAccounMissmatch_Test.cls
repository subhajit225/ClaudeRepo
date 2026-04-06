@isTest
private class EntitlementsWithAccounMissmatch_Test {
    //test Class updated
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
        ent.Entitlement_Usage__c = 34;
        insert ent;

        List<Entitlement> entList = new List<Entitlement>();
        entList.add(ent);
        
        Entitlement_Use__c entuse = new Entitlement_Use__c();
        entuse.serial_number__c='Teste00010002';
        entuse.Name ='Teste00010002';
        entuse.entitlement__c = ent.id;
        insert entuse;

        Test.startTest();
       
        String strId = Id.valueOf(entuse.Id);
        Decommission_Nodeclass.clearUsagecounter(strId);
       
        Test.setCurrentPage(Page.EntitlementAccountMismatVFPage);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(entList);
        stdSetController.setSelected(entList);
        EntitlementAccountMismatchcontroller cont = new EntitlementAccountMismatchcontroller();
        DateTime scheduleTime = Datetime.now().addminutes(1);
                String hour = String.valueOf(scheduleTime.hour()); 
                String minute = String.valueOf(scheduleTime.minute());
                String second = String.valueOf(scheduleTime.second());  
                String nextFireTime = '0 ' + minute + ' ' + hour + ' ' + String.valueOf(scheduleTime.day()) + ' ' + String.valueOf(scheduleTime.month()) + ' ?' + ' ' + String.valueOf(scheduleTime.year());
                
       System.schedule('EntitlementAccountMismatchEmailAlert1', '0 0 2 * * ?', new EntitlementAccountMismatchEmailAlert());
        Test.stopTest();
    }
}