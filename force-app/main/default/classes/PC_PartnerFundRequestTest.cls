/**
 * @description       : Test class of PC_PartnerFundReqTableController and PC_PartnerFundReqController
 * @author            : Harshit Garg
 * @group             : 
 * @last modified on  : 02-26-2026
 * @last modified by  : Harshit Garg
**/
@isTest
private class PC_PartnerFundRequestTest {
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
			List<PartnerFundRequest> pfrList = PartnerTestDataUtility.createPartnerFundRequest(1,'Draft',accounts[0].Id, pfRequestFields);
			insert pfrList;
			
			List<ContentVersion> versions = PartnerTestDataUtility.createContentVersion(1,'TestDocument.pdf',null);
			insert versions;
		}
	}
	
	/**
     * @description Test getRecords with different field types and sorting scenarios
     */
    @isTest
    static void testGetRecordsWithDifferentFieldTypes() {
		
		String returnFields = 'Id,Title,Status,Activity_Start_Date__c,Activity_End_Date__c,CreatedDate';
        String objType = 'PartnerFundRequest';
        Integer pageSize = 10;
        List<String> IdSet = new List<String>();
        List<String> accIds = new List<String>();
		
		User testUser = [SELECT Id FROM User WHERE Email = 'testuser0@example.com.sandbox' LIMIT 1];

		System.runAs(testUser) {

			Test.startTest();

			// Test with date field sorting descending
			List<sobject> records1 = PC_PartnerFundReqTableController.getRecords(
				'', returnFields, objType, pageSize, 'Activity_Start_Date__c', 'desc',
				String.valueOf(System.today()), IdSet, '', '', accIds
			);

			// Test with date field sorting ascending
			List<sobject> records2 = PC_PartnerFundReqTableController.getRecords(
				'', returnFields, objType, pageSize, 'Activity_Start_Date__c', 'asc',
				String.valueOf(System.today()), IdSet, '', '', accIds
			);

			// Test with datetime field sorting
			List<sobject> records3 = PC_PartnerFundReqTableController.getRecords(
				'', returnFields, objType, pageSize, 'CreatedDate', 'desc',
				String.valueOf(System.now()), IdSet, '', '', accIds
			);

			// Test with IdSet populated
			IdSet.add([SELECT Id FROM PartnerFundRequest LIMIT 1].Id);
			List<sobject> records4 = PC_PartnerFundReqTableController.getRecords(
				'', returnFields, objType, null, '', '', '', IdSet, '', '', accIds
			);

			// Test with start and end dates
			List<sobject> records5 = PC_PartnerFundReqTableController.getRecords(
				'', returnFields, objType, pageSize, 'Title', 'desc', '',
				new List<String>(), String.valueOf(System.today()), String.valueOf(System.today().addDays(30)), accIds
			);

			// Test with accIds populated
			accIds.add([SELECT Id FROM Account LIMIT 1].Id);
			List<sobject> records6 = PC_PartnerFundReqTableController.getRecords(
				'', returnFields, objType, pageSize, 'Title', 'desc', '',
				new List<String>(), '', '', accIds
			);
			
			// Test with search string
			List<sobject> records7 = PC_PartnerFundReqTableController.getRecords(
				'Test', returnFields, objType, pageSize, 'Title', 'desc', '',
				new List<String>(), '', '', accIds
			);
			
			// Test with Activity_Objective__c field sorting descending
			List<sobject> records8 = PC_PartnerFundReqTableController.getRecords(
				'', returnFields, objType, pageSize, 'Activity_Objective__c', 'desc',
				String.valueOf(System.today()), IdSet, '', '', new List<String>()
			);

			Test.stopTest();

			System.assertNotEquals(null, records1, 'Records should not be null');
			System.assertNotEquals(null, records2, 'Records should not be null');
			System.assertNotEquals(null, records3, 'Records should not be null');
			System.assertNotEquals(null, records4, 'Records should not be null');
			System.assertNotEquals(null, records5, 'Records should not be null');
			System.assertNotEquals(null, records6, 'Records should not be null');
			System.assertNotEquals(null, records7, 'Records should not be null');
			System.assertNotEquals(null, records8, 'Records should not be null');
		}
	}
	
	/**
     * @description Test Total Records count
     */
    @isTest
    static void testTotalRecords() {
		
		String objType = 'PartnerFundRequest';
		User testUser = [SELECT Id FROM User WHERE Email = 'testuser0@example.com.sandbox' LIMIT 1];

		System.runAs(testUser) {
		
			Test.startTest();
			
			Id pfId = [SELECT Id FROM PartnerFundRequest LIMIT 1].Id;
			Integer count = PC_PartnerFundReqTableController.getTotalRecords(objType);
			PC_PartnerFundReqTableController.getStatus(pfId);
			PC_PartnerFundReqTableController.getFiscalYearData();
				
			Test.stopTest();

			System.assertEquals(1, count, 'Record count should be one.');
		}
	}
	
	/**
     * @description Test controller class
     */
	@isTest static void testReqController() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser0@example.com.sandbox' LIMIT 1];

		System.runAs(testUser) {
            Test.startTest();
			
			PartnerFundRequest pfrec = [SELECT Id FROM PartnerFundRequest LIMIT 1];
            ApexPages.StandardController sc = new ApexPages.StandardController(pfrec);
            PC_PartnerFundReqController testpc = new PC_PartnerFundReqController(sc);
            PC_PartnerFundReqController.getPicklistValues('Activity');
            PC_PartnerFundReqController.getPicklistValues(null);
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            PC_PartnerFundReqController.savePartnerFundReq('test','USD','Expansion','Enablement','Cisco',System.today(),System.today(),'200','asdsd',new List<Id> {documents[0].Id},'d1','Dev','mos1','mos2','mos3','mos4');
            PC_PartnerFundReqController.savePartnerFundReq('test','USD','Training and Readiness','Enablement','Cisco',System.today(),System.today(),null,'asdsd',new List<Id> {documents[0].Id},'d1','Dev','mos1','mos2','mos3','mos4');
            PC_PartnerFundClaimController.getStatus(pfrec.Id);
            
            testpc.callcheckCancel();
			 
			List<ContentDocumentLink> links = PC_PartnerFundReqController.attachUploadedDocuments(new List<Id> {documents[0].Id},pfrec.Id);
            System.assertEquals(false, links.isEmpty(), 'Links should not be empty.');
        }
    }
}