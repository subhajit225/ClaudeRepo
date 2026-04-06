/** Description: Test class for AccountUpdateTypeStatusBatch apex batch class. (SAL25-107) */
@isTest
private class AccountUpdateTypeStatusBatchTest {

    @testsetup
    private static void createTestData() {
        Test.startTest();

        ShGl_DisableBusinessLogic__c disableBusLogic = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
        disableBusLogic.Disable_Opportunity_Validation_Rules__c = true;
        INSERT disableBusLogic;

        Opportunity opportunity = TestDataFactory.getOpportunity();
        opportunity.Opportunity_Type__c = 'Existing Customer';
        INSERT opportunity;
        System.assert(opportunity.Id != null);
        Test.stopTest();
    }
    
    @isTest
    static void executeTest1() {
        Test.startTest();

        Opportunity opportunity = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        
        ShGl_TestFactoryHelper.insertTriggerControls();
        triggerControl.stopEntitlementTrigger = true;

        INSERT getEntitlement(opportunity.AccountId, Date.today().addDays(-365), Date.today().addDays(-100));
        
        Account newAccount = new Account(Name = 'Test Account123', Type = 'Prospect');
        INSERT newAccount;
        INSERT getEntitlement(newAccount.Id, Date.today().addDays(-365), Date.today().addDays(100));
      
        Database.executeBatch(new AccountUpdateTypeStatusBatch(null));
        Test.stopTest();
        System.assertEquals('Prospect', [SELECT Id, Type FROM Account WHERE Id =: opportunity.AccountId].Type);
        System.assertEquals('Prospect', [SELECT Id, Status__c FROM Account WHERE Id =: opportunity.AccountId].Status__c);
        System.assertEquals('Prospect', [SELECT Id, Account_Status__c FROM Account WHERE Id =: opportunity.AccountId].Account_Status__c);
        System.assertEquals('Customer', [SELECT Id, Type FROM Account WHERE Id =: newAccount.Id].Type);
    }

    @isTest
    static void executeTest2() {
        Test.startTest();

        ShGl_TestFactoryHelper.insertTriggerControls();
        triggerControl.stopEntitlementTrigger = true;
        Opportunity opportunity = [SELECT Id, AccountId FROM Opportunity LIMIT 1];

        INSERT getEntitlement(opportunity.AccountId, Date.today().addDays(-365), Date.today().addDays(365));

        Database.executeBatch(new AccountUpdateTypeStatusBatch(null));        
        Test.stopTest();
        System.assertEquals('Customer', [SELECT Id, Type FROM Account WHERE Id =: opportunity.AccountId].Type);
        System.assertEquals('Existing Customer', [SELECT Id, Account_Status__c FROM Account WHERE Id =: opportunity.AccountId].Account_Status__c);
    }
    
    @isTest
    static void executeTest3() {
        Test.startTest();

        Opportunity opportunity = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        
        Account account = [SELECT Id, Type, Status__c FROM Account WHERE Id = :opportunity.AccountId];
        account.Type = 'Customer';
        account.Status__c = 'Customer';
        UPDATE account;
        
        AccountUpdateTypeStatusBatch accBatch = new AccountUpdateTypeStatusBatch(null);
        opportunity.closeDate = System.Today().addDays(20);
        opportunity.RecordTypeId = accBatch.OPP_RECORD_TYPE_RENEWAL;
        opportunity.Opportunity_Sub_Type__c='Renewal';
        opportunity.StageName = '1 Discovery';
        opportunity.Lost_To_Won_Against__c ='Actifio';
        UPDATE opportunity;

        ShGl_TestFactoryHelper.insertTriggerControls();
        triggerControl.stopEntitlementTrigger = true;

        INSERT getEntitlement(opportunity.AccountId, Date.today().addDays(-365), Date.today().addDays(-100));

        Database.executeBatch(new AccountUpdateTypeStatusBatch(null));
        Test.stopTest();
        System.assertEquals('Customer', [SELECT Id, Type FROM Account WHERE Id =: opportunity.AccountId].Type);
        System.assertEquals('Customer', [SELECT Id, Status__c FROM Account WHERE Id =: opportunity.AccountId].Status__c);
        System.assertEquals('Existing Customer', [SELECT Id, Account_Status__c FROM Account WHERE Id =: opportunity.AccountId].Account_Status__c);
    }

    @istest
    static void sendErrorReportTest() {
    Test.startTest();  
        AccountUpdateTypeStatusBatch accBatchObj = new AccountUpdateTypeStatusBatch(null);
        accBatchObj.sendErrorReport();
    Test.stopTest();
    }
    
    private static Entitlement getEntitlement(Id accountId, Date startDate, Date endDate) {
        return new Entitlement(Name = 'Test Entitlement',
                               AccountId = accountId,
                               StartDate = startDate,
                               EndDate = endDate,
                               Type = 'Phone Support');
    }
}