@isTest(SeeAllData = false)
public class RecalculatePlanhatImportBatchTest {
    
        
    @testSetup
    static void testSetUp() {
        
        List<Account> accounts = new List<Account>();
        
        for (integer i=0 ; i< 20; i++) {
            Account account = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            account.Name = 'Test Account' + i;
            accounts.add(account);
        }
        
        Account account = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Distributor').getRecordTypeId();
        account.Partner_Agreement_Status__c = 'Approved ';
        account.Name = 'PartnerResellerAccount';
        accounts.add(account);
        insert accounts;
        
        TriggerControl__c control= new TriggerControl__c();
        control.Name='Opportunity';
        control.DisableTrigger__c=true;
        insert control;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        List<Opportunity> opportunities = new List<Opportunity>();
        Opportunity opportunity = TestDataFactory.getOpportunity(accounts[0]);
        opportunity.closeDate = Date.today() + 5;
        opportunity.StageName = '4 Business Justification';
        opportunity.Pricebook2Id = pricebookId;
        opportunities.add(opportunity);
		
        Opportunity opportunity1 = TestDataFactory.getOpportunity(accounts[0]);
        opportunity1.closeDate = Date.today() + 5;
        opportunity1.StageName = '7 Closed Won';
        opportunity1.Opportunity_Type__c= 'Debooking';
        opportunity1.Opportunity_Sub_Type__c= 'MSP Overage';
       
        opportunity1.Pricebook2Id = pricebookId;
        opportunities.add(opportunity1);
		
        insert opportunities;
    }
    
    @istest
    static void testRecalculatePlanhatImportBatch() {
        test.startTest();
        RecalculateActivePlanhatImportBatch recalculateActiveAccounts = new RecalculateActivePlanhatImportBatch();
        Database.executeBatch(recalculateActiveAccounts, 25);
        test.stopTest();
        
        List<Account> accounts = [SELECT Id, IsPlanhatImport__c FROM Account WHERE Name = 'PartnerResellerAccount' LIMIT 1];
        System.assertEquals(false, accounts[0].IsPlanhatImport__c);
        accounts = [SELECT Id, IsPlanhatImport__c FROM Account WHERE Name = 'Test Account0' LIMIT 1];
        System.assertEquals(true, accounts[0].IsPlanhatImport__c);
        
    }
    
    @istest
    static void testRecalculateInactivePlanhatImportBatch() {
        List<Account> accounts = [SELECT Id, IsPlanhatImport__c FROM Account WHERE Name = 'PartnerResellerAccount' LIMIT 1];
        accounts[0].Partner_Agreement_Status__c = 'Pending';
        accounts[0].IsPlanhatImport__c = true;
        update accounts[0];
        
        test.startTest();
        RecalculateInActivePlanhatImportBatch recalculateInActiveAccounts = new RecalculateInActivePlanhatImportBatch();
        Database.executeBatch(recalculateInActiveAccounts, 10);
        test.stopTest();
        
        accounts = [SELECT Id, IsPlanhatImport__c FROM Account WHERE Name = 'PartnerResellerAccount' LIMIT 1];
        System.assertEquals(false, accounts[0].IsPlanhatImport__c);
    }
}