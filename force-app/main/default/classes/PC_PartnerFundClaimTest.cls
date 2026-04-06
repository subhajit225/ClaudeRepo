/**
 * @description       : Test class of PC_PartnerFundClaimTableController, PC_PartnerFundClaimController and PC_MDFSubmitClaimReminderBatch
 * @author            : Harshit Garg
 * @group             : 
 * @last modified on  : 02-26-2026
 * @last modified by  : Harshit Garg
**/
@isTest
private class PC_PartnerFundClaimTest {
    /**
     * @description setup method to create data
     */
    @TestSetup
    static void setupTestData(){
		
		List<User> users = PartnerTestDataUtility.createUsers(1, 'System Administrator', null);
		insert users;
		
		System.runAs(users[0]) {
			List<Account> accounts = new List<Account>();
			Map<String, Object> accountFields = new Map<String, Object>();
			accountFields.put('Name', 'testacc');
			accounts.addAll(PartnerTestDataUtility.createAccounts(1, 'Reseller', 'Partner/Distributor', accountFields));
			insert accounts;
				
			List<Contact> contacts = new List<Contact>();
			Map<String, Object> contactFields = new Map<String, Object>();
			contactFields.put('Email', system.label.Invoices_Email);
			contacts.addAll(PartnerTestDataUtility.createContacts(1, accounts[0].Id, contactFields));
			insert contacts;
					
			accounts[0].IsPartner = true;
			update accounts;
				
			List<PartnerMarketingBudget> budgets = PartnerTestDataUtility.createPartnerMarketingBudget(1,accounts[0].Id, null);
			insert budgets;
				
			List<PartnerFundAllocation> fundAllocations = PartnerTestDataUtility.createPartnerFundAllocation(1,accounts[0].Id, budgets[0].Id, null);
			insert fundAllocations;
				
			Map<String, Object> pfRequestFields = new Map<String, Object>();
			pfRequestFields.put('Activity', 'Digital Advertising');
			pfRequestFields.put('Activity_Objective__c', 'Enablement');
			pfRequestFields.put('RequestedAmount', 500);
			pfRequestFields.put('Amount', 500);
			pfRequestFields.put('AllocationId', fundAllocations[0].Id);
			pfRequestFields.put('Activity_Start_Date__c', System.today());
			pfRequestFields.put('Activity_End_Date__c', System.today().addDays(30));
			List<PartnerFundRequest> pfrList = PartnerTestDataUtility.createPartnerFundRequest(2,'Draft',accounts[0].Id, pfRequestFields);
			insert pfrList;
			
			List<PartnerFundClaim> pfClaimList = PartnerTestDataUtility.createPartnerFundClaim(1,'Draft',pfrList[0].Id, null);
			insert pfClaimList;
			
			List<ContentVersion> versions = PartnerTestDataUtility.createContentVersion(1,'TestDocument.pdf',null);
			insert versions;
		}
	}
	
	/**
     * @description Test getRecords with different field types and sorting scenarios
     */
    @isTest
    static void testGetRecordsWithDifferentFieldTypes() {
		
		String returnFields = 'Id,Title,Status,CreatedDate';
        String objType = 'PartnerFundClaim';
        Integer pageSize = 10;
        List<String> idSet = new List<String>();
        List<String> accIds = new List<String>();
		
		User testUser = [SELECT Id FROM User WHERE Email = 'testuser0@example.com.sandbox' LIMIT 1];

		System.runAs(testUser) {

			Test.startTest();

			// Test with date field sorting descending
			List<sobject> records1 = PC_PartnerFundClaimTableController.getRecords(
				'', returnFields, objType, pageSize, 'CreatedDate', 'desc',
				String.valueOf(System.today()), idSet, null
			);

			// Test with date field sorting ascending
			List<sobject> records2 = PC_PartnerFundClaimTableController.getRecords(
				'', returnFields, objType, pageSize, 'CreatedDate', 'asc',
				String.valueOf(System.today()), idSet, null
			);

			// Test with idSet populated
			PartnerFundClaim claim = [SELECT Id, RequestId FROM PartnerFundClaim LIMIT 1];
			idSet.add(claim.Id);
			List<sobject> records3 = PC_PartnerFundClaimTableController.getRecords(
				'', returnFields, objType, null, '', '', '', idSet, null
			);

			// Test with accIds populated
			Id reqId = claim.RequestId;
			List<sobject> records4 = PC_PartnerFundClaimTableController.getRecords(
				'', returnFields, objType, pageSize, 'Title', 'desc', '',
				new List<String>(), reqId
			);
			
			// Test with search string
			List<sobject> records5 = PC_PartnerFundClaimTableController.getRecords(
				'Test', returnFields, objType, pageSize, 'Title', 'desc', '',
				new List<String>(), null
			);
			
			// Test with Status field sorting descending
			List<sobject> records6 = PC_PartnerFundClaimTableController.getRecords(
				'', returnFields, objType, pageSize, 'Status', 'desc',
				'Draft', new List<String>(), null
			);

			Test.stopTest();

			System.assertNotEquals(null, records1, 'Records should not be null');
			System.assertNotEquals(null, records2, 'Records should not be null');
			System.assertNotEquals(null, records3, 'Records should not be null');
			System.assertNotEquals(null, records4, 'Records should not be null');
			System.assertNotEquals(null, records5, 'Records should not be null');
			System.assertNotEquals(null, records6, 'Records should not be null');
		}
	}
	
	
	/**
     * @description Test Total Records count
     */
    @isTest
    static void testTotalRecords() {
		
		String objType = 'PartnerFundClaim';
		User testUser = [SELECT Id FROM User WHERE Email = 'testuser0@example.com.sandbox' LIMIT 1];

		System.runAs(testUser) {
		
			Test.startTest();
			Integer count = PC_PartnerFundClaimTableController.getTotalRecords(objType);
			Test.stopTest();

			System.assertEquals(1, count, 'Record count should be one.');
		}
	}
	
	/**
     * @description Test controller class
     */
	@isTest static void testClaimController() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser0@example.com.sandbox' LIMIT 1];

		System.runAs(testUser) {
            Test.startTest();
			
			PartnerFundRequest pfrec = [SELECT Id FROM PartnerFundRequest LIMIT 1];
            ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];
            
			
			PC_PartnerFundClaimController.getfileBaseURL();
            PC_PartnerFundClaimController.getBaseURL();
            PC_PartnerFundClaimController.getTotalAmount(pfrec.Id);
            PC_PartnerFundClaimController.recId = pfrec.Id;
            PC_PartnerFundClaimController.status = 'Draft';
            PC_PartnerFundClaimController.claimname = 'Test';
            PC_PartnerFundClaimController.contentVersionIds = cv.Id;
            PC_PartnerFundClaimController.getRequestDetails(pfrec.Id);
            PC_PartnerFundClaimController.getPicklistValues('Fiscal_Quarter__c');
			PC_PartnerFundClaimController.getPicklistValues(null);
            PC_PartnerFundClaimController pfcont = new PC_PartnerFundClaimController();
            pfcont.saveFilesAction();
			Boolean flag = PC_PartnerFundClaimController.getStatus(pfrec.Id);
			Test.stopTest();
			
			System.assertEquals(false, flag, 'Flag should not be true.');
        }
    }
	
	/**
     * @description Test PC_MDFSubmitClaimReminderBatch class
     */
	@isTest static void testClaimReminderBatch() {
		
		User testUser = [SELECT Id FROM User WHERE Email = 'testuser0@example.com.sandbox' LIMIT 1];

		System.runAs(testUser) {

			PartnerFundRequest pfRec = [SELECT Id FROM PartnerFundRequest WHERE ID NOT IN (SELECT RequestId FROM PartnerFundClaim) LIMIT 1];
			pfRec.Activity_End_Date__c = Date.today().addDays(-1);
			pfRec.Status = 'Approved';
			pfRec.Approved_Amount_USD__c = 10;
			pfrec.Planned_Inquiries__c = 0;
			pfrec.Campaign_Focus__c = 'SFDC';
			pfRec.Executed_By__c = 'Partner Marketing';
			pfrec.Budget_Code__c = '5700 - Partner Marketing - 64003 - Channel Marketing'; 
			pfRec.Disable_MDF_Claim_Notifications__c = false;
			update pfRec;
			
			Test.startTest();
			
			Database.executeBatch(new PC_MDFSubmitClaimReminderBatch());
			
			Test.stopTest();
			
			System.assertEquals(false, pfRec.Disable_MDF_Claim_Notifications__c, 'Flag should not be true.');
		}
		
	}
	
}