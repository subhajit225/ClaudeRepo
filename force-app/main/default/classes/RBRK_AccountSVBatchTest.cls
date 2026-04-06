@isTest
private class RBRK_AccountSVBatchTest {
	public static Account act;
    public static Entitlement ent;
    public static Product2 prdHW;
    public static PricebookEntry pbeHW;
    public static Asset ast;
    public static ContractLineItem contractLineItem;
    public static ServiceContract serviceContract;
    public static Opportunity opportunityObj;
    public static Id pricebookId;
    /**
     * @description Test method to verify that the RBRK_AccountSVBatch executes without errors.
     */
    @isTest
    static void testBatchExecution() {
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser[0];
        system.runas(listUser[0]){
        // Step 1: Create test Accounts that match the batch query filter
		act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        
        prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        prdHW.ProductCode = 'IGS-SVC-PREM-HW';
        prdHW.Family = 'HPE';
        insert prdHW;

        pricebookId = Test.getStandardPricebookId();
        
        pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pbeHW.PriceBook2Id = pricebookId;
        insert pbeHW;



        opportunityObj = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opportunityObj.AccountId = act.Id;
        opportunityObj.Name = 'EntitlementTriggerHelper Opportunity';
        opportunityObj.CloseDate = System.today().addMonths(12);
        opportunityObj.StageName = 'Prospecting';
        opportunityObj.Pricebook2Id = pricebookId;
        opportunityObj.SBQQ__QuotePricebookId__c = pricebookId;
        insert opportunityObj;

        serviceContract = new ServiceContract();
        serviceContract.Name = 'EntitlementTriggerHelper Contract';
        serviceContract.SBQQSC__Opportunity__c = opportunityObj.Id;
        serviceContract.AccountId = act.Id;
        serviceContract.StartDate = System.today();
        serviceContract.PriceBook2Id = pricebookId;
        serviceContract.Term = 36;
        insert serviceContract;
        
        contractLineItem = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        contractLineItem.SBQQSC__Account__c = act.Id;
        contractLineItem.PricebookEntryId = pbeHW.Id;
        contractLineItem.SBQQSC__Product__c = prdHW.ID;
        contractLineItem.ServiceContractId = serviceContract.Id;
        contractLineItem.StartDate = System.today();
        contractLineItem.SBQQSC__Quantity__c = 20;
        insert contractLineItem;
		
        // Step 2: Run the batch class
        Test.startTest();
        RBRK_AccountSVBatch batch = new RBRK_AccountSVBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Step 3: Assert that accounts were inserted and eligible for processing
        Integer count = [SELECT COUNT() FROM Account WHERE Id in (Select SBQQSC__Account__c from ContractLineItem WHERE Status = 'Active')];
        System.assertEquals(1, count, '1 accounts should have matched the query');
    }
    }
       /**
     * @description Test method to verify that the RBRK_AccountSVBatch is Schedulable without errors.
     */
    @isTest
static void testSchedulableExecution() {
    List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        insert listUser;
    system.runas(listUser[0]){
    Test.startTest();
    RBRK_AccountSVBatch batch = new RBRK_AccountSVBatch();
    batch.execute(null); // SchedulableContext is not used in your logic
    Test.stopTest();
        Integer count = [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'BatchApex' AND Status = 'Completed'];
    System.assert(count > 0, 'Batch job should have completed successfully.');
}
}

}