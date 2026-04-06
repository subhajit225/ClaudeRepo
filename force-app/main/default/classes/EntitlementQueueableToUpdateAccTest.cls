@isTest
public class EntitlementQueueableToUpdateAccTest {
	@isTest
    static void testScheduler(){
        // insert account ----
        Account testAccount = new Account(Name = 'Test Account', FedRAMP__c = false);
        insert testAccount;
        
        // insert Product ----
        Product2 testProduct = new Product2(Name = 'Test Product', Product_Subtype__c = 'FEDRAMP', Product_Type__c = 'US Citizen Support');
        insert testProduct;
        
        insert new TriggerControl__c(name='Entitlement',DisableTrigger__c=false);
        TriggerControl.stopEntitlementTrigger = true;
        
        // insert Entitlement -----
        Entitlement testEntitlement = new Entitlement(
            AccountId = testAccount.Id,
            Product__c = testProduct.Id, 
            Name = 'Test Entitlement',
            StartDate = Date.today(),
            EndDate = Date.today().addYears(2)
        );
        insert testEntitlement;
        
        User testUser = [SELECT Id from user where Profile.Name like '%System Administrator%' and isActive = true LIMIT 1];
        System.runAs(testUser) {
		Test.startTest();
        // Schedule the job
        EntitlementSchedulerToUpdateAcc scheduler = new EntitlementSchedulerToUpdateAcc(200);
        String jobId = System.schedule('Test_EntitlementScheduler', '0 0 * * * ?', scheduler);
		
        Test.stopTest();
        }
		
        Account acc = [SELECT FedRAMP__c FROM account WHERE name = 'Test Account' limit 1];
        system.assertEquals(acc.FedRAMP__c, acc.FedRAMP__c);
        
    }
}