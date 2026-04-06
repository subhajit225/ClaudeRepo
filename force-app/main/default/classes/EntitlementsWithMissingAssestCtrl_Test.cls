@isTest
public class EntitlementsWithMissingAssestCtrl_Test {
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
        EntitlementsWithMissingAssestCtrl.getEntitlemetsWithMissingAssets();
        Test.stopTest();
    }
}