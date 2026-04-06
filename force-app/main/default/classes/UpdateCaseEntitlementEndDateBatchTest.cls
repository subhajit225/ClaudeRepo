/*****************************************************************************
 
* @Author      : Sushant Arora
* @Related Apex Class   : UpdateCaseEntitlementEndDateBatch 

******************************************************************************/

@isTest
public class UpdateCaseEntitlementEndDateBatchTest {

    static testMethod void testBatchJob() {
        // Disable the trigger for this test
        TriggerControl__c triggerControlSetting = new TriggerControl__c(
            Name = 'Entitlement',
            DisableTrigger__c = true 
        );
        insert triggerControlSetting;

        // Create a test Account
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;


        // Create a test User as the Case Owner
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User']; 
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testEmailRubrik@gmail.com',
            UserName = 'testEmailRubrik@gmail.com',
            Alias = 'Tester',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        // Create a test Entitlement record
        Entitlement testEntitlement = new Entitlement(
            Name = 'Test Entitlement',
            StartDate= Date.today(),
            EndDate= Date.today().addDays(30),
            AccountId = testAccount.Id
        );
        insert testEntitlement;

        // Create test data: Case records with required fields
        List<Case> testCases = new List<Case>();
        for (Integer i = 0; i < 20; i++) {
            Case testCase = new Case(
                RecordType = new RecordType(Name = 'Customer Success'), 
                AccountId = testAccount.Id, 
                OwnerId = testUser.Id, 
                Priority = 'High', 
                Status = 'New', 
                Origin = 'Web', 
                Platform__c = 'Duplicate', 
                Subject = 'Test Case Subject', 
                Description = 'This is a test case description',
                Entitlement__c =testEntitlement.Id
            );
            testCases.add(testCase);
        }
        insert testCases;

        // Start the batch job
        Test.startTest();
        UpdateCaseEntitlementEndDateBatch batchJob = new UpdateCaseEntitlementEndDateBatch();
        Database.executeBatch(batchJob);
        Test.stopTest();

        // Verify the results & Ensure that all cases were updated

        List<Case> updatedCases = [SELECT Id, Entitlement_End_Date__c FROM Case WHERE Id IN :testCases];
        System.assertEquals(20, updatedCases.size()); 

    }
}