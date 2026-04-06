@istest
class AccountL3EntitlementsBatchTest {

    public static Account act;
    public static Entitlement ent;
    public static Product2 prdHW;
    public static PricebookEntry pbeHW;
    public static Asset ast;
    
    static {
        String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(
            Alias = 'adminU', Email='AdminUser@rubrik.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName=uniqueUserName
        );
        insert u;
        System.runAs(u) {
        ShGl_DisableBusinessLogic__c settingDisable2 = new ShGl_DisableBusinessLogic__c();
        settingDisable2.Name = 'System Administrator';
        settingDisable2.Disable_Entitlement_Validation_Rules__c = true;
        insert settingDisable2;
            
        ShGl_TestFactoryHelper.insertTriggerControls();

        act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        
        prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        prdHW.ProductCode = 'RBK-test-product';
        prdHW.Category__c = 'Support';
        prdHW.Support_Type__c = 'L3';
        insert prdHW;
        
        pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        insert pbeHW;
        
        ent = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        ent.AccountId = act.Id;
        ent.Product__c = prdHW.Id;
        ent.StartDate = Date.today().addDays(-365);
        ent.EndDate = Date.today().addDays(365);
        insert ent;
        }
    }
    
   static testmethod void test() {
   	  Test.startTest();
       
      String CRON_EXP = '0 0 0 5 4 ? 2025';
      String jobId = System.schedule('AccountL3EntitlementsBatchScheduler', CRON_EXP, new AccountL3EntitlementsBatchScheduler());

      Test.stopTest();
 }
}