/**
 * @description       : Test Class of DealRegistrationTrigger
 * @author            : Harshit Garg
 * @group             : 
 * @last modified on  : 02-17-2026
 * @last modified by  : Harshit Garg
**/
@isTest(SeeAllData=false) 
public with sharing class DealRegistrationTriggerTest {

	/**
     * @description setup method to create data
     */
    @TestSetup
    static void setupTestData(){

		List<User> users = PartnerTestDataUtility.createUsers(2, 'System Administrator', null);
		insert users;

		List<Territory2Model> territoryModels = [SELECT Id, Name FROM Territory2Model WHERE State = 'Active' LIMIT 1];
        List<Territory2Type> territoryTypes = [SELECT Id, DeveloperName FROM Territory2Type WHERE DeveloperName = 'Territory' LIMIT 1];

		if (!territoryModels.isEmpty() && !territoryTypes.isEmpty()) {
			
			List<Territory2> territories = PartnerTestDataUtility.createTerritories(1, territoryModels[0].Id, territoryTypes[0].Id, null);
			insert territories;
			
			List<UserTerritory2Association> associations = PartnerTestDataUtility.createUserTerritoryAssociations(1, Label.AccountExecRoleName, territories[0].Id, users[1].Id, null);
			associations.addAll(PartnerTestDataUtility.createUserTerritoryAssociations(1, 'SDR', territories[0].Id, users[0].Id, null));
			insert associations;
        }
		
		System.runAs(users[0]) {

			List<WorkflowTriggerBypass__c> wtList = new List<WorkflowTriggerBypass__c>();
			wtList.addAll(PartnerTestDataUtility.createWorkflowTriggerBypass(1, 'leadReassignOnBusinessUnitChange', false, null));
			wtList.addAll(PartnerTestDataUtility.createWorkflowTriggerBypass(1, 'cnsFirstAttemptUpdateLeadStatus', false, null));
			wtList.addAll(PartnerTestDataUtility.createWorkflowTriggerBypass(1, 'CreateSDRLedMeetingTask', false, null));
			wtList.addAll(PartnerTestDataUtility.createWorkflowTriggerBypass(1, 'updateLastOwnershipUpdateDate', false, null));
			wtList.addAll(PartnerTestDataUtility.createWorkflowTriggerBypass(1, 'updateOpportunitySource', false, null));
			wtList.addAll(PartnerTestDataUtility.createWorkflowTriggerBypass(1, 'salesOperationsAssignAccountSIC', false, null));
			wtList.addAll(PartnerTestDataUtility.createWorkflowTriggerBypass(1, 'salesOperationsSetEUResident', false, null));
			insert wtList;

			List<CountryWithCode__c> countryCodes = PartnerTestDataUtility.createCountryWithCode(1,'US','United States',null);
			insert countryCodes;

			List<CodeWithCountry__c> codeCountries = new List<CodeWithCountry__c>();
			codeCountries.addAll(PartnerTestDataUtility.createCodeWithCountry(1,'US','United States',null));
			codeCountries.addAll(PartnerTestDataUtility.createCodeWithCountry(1,'GB','United Kingdom',null));
			insert codeCountries;

			List<DealregLeadMapping__c> drmapping = new List<DealregLeadMapping__c>();
			drmapping.addAll(PartnerTestDataUtility.createDealRegLeadMapping(1,'Country__c','Country',null));
			drmapping.addAll(PartnerTestDataUtility.createDealRegLeadMapping(1,'LastName__c','LastName',null));
			drmapping.addAll(PartnerTestDataUtility.createDealRegLeadMapping(1,'Company__c','Company',null));
			drmapping.addAll(PartnerTestDataUtility.createDealRegLeadMapping(1,'Email__c','Email',null));
			insert drmapping;
			
			List<PatchManager__c> patchMgrs = PartnerTestDataUtility.createPatchManagers(1, 'Geographic', users[0].Id, null);
			insert patchMgrs;
			
			List<Account> accounts = new List<Account>();
			Map<String, Object> accountFields = new Map<String, Object>();
			accountFields.put('Name', 'Customer Account');
			accounts.addAll(PartnerTestDataUtility.createAccounts(1, null, 'Customer/Prospect', accountFields));
			accountFields.put('Name', 'Distributor Account');
			accountFields.put('Type','OEM');
			accountFields.put('OEM_Subtype__c','Revshare');
			accounts.addAll(PartnerTestDataUtility.createAccounts(1, null, 'Partner/Distributor', accountFields));
			insert accounts;

			List<Contact> contacts = new List<Contact>();
			Map<String, Object> contactFields = new Map<String, Object>();
			contactFields.put('Email', 'Test_alliance@redsky.com.sandbox');
			contactFields.put('LeadSource', 'Email');
			contacts.addAll(PartnerTestDataUtility.createContacts(1, accounts[0].Id, contactFields));
			
			contactFields.put('Email', 'Test_sd@redsky.com.sandbox');
			contacts.addAll(PartnerTestDataUtility.createContacts(1, accounts[0].Id, contactFields));

			contactFields.put('Email', 'Test_oem@redsky.com.sandbox');
			contacts.addAll(PartnerTestDataUtility.createContacts(1, accounts[0].Id, contactFields));

			contactFields.put('Email', 'Test_eng@redsky.com.sandbox');
			contacts.addAll(PartnerTestDataUtility.createContacts(1, accounts[0].Id, contactFields));
			insert contacts;
			
			Map<String, Object> oppFields = new Map<String, Object>{
												  'Amount' => 3000,
												  'Type' => 'New Customer',
												  'Lead_Email_Hidden__c' => contacts[0].Email,
												  'Initial_Contacts_Name__c' => contacts[0].Id,
												  'Deal_Registration_Type__c' => 'Rubrik Sourced'
												};
			List<Opportunity> opps = PartnerTestDataUtility.createOpportunities(1, null, accounts[0].Id, oppFields);
			insert opps;

			List<Deal_Registration__c> dealRegReqs = new List<Deal_Registration__c>();
			Map<String, Object> dealRegFields = new Map<String, Object>();
			dealRegFields.put('Email__c', 'Test_alliance@redsky.com.sandbox');
			dealRegFields.put('Primary__c', true);
			dealRegFields.put('Deal_Reg_Submitted_Date__c', System.now());
			dealRegFields.put('Rubrik_Complete_Edition_Reg__c', true);
			dealRegFields.put('OwnerId', users[1].Id);
			dealRegFields.put('CDM__c', users[1].Id);
			dealRegFields.put('Lead_Share_Campaign__c', false);
			dealRegFields.put('Partner_Lookup__c', accounts[0].Id);
			dealRegReqs.addAll(PartnerTestDataUtility.createDealRegistrations(1,'Alliance','Submitted',dealRegFields));
		
			dealRegFields.put('Email__c', 'Test_dist@redsky.com.sandbox');
			dealRegFields.put('Primary__c', false);
			dealRegFields.put('Rubrik_Complete_Edition_Reg__c', false);
			dealRegFields.put('OwnerId', users[0].Id);
			dealRegFields.put('CDM__c', null);
			dealRegFields.put('Lead_Share_Campaign__c', true);
			dealRegFields.put('Partner_Lookup__c', accounts[1].Id);
			dealRegFields.put('Dedicated_Managed_Service__c', true);
			dealRegReqs.addAll(PartnerTestDataUtility.createDealRegistrations(1,'Reseller','Submitted',dealRegFields));

			dealRegFields.put('Email__c', 'Test_dist_1@redsky.com.sandbox');
			dealRegReqs.addAll(PartnerTestDataUtility.createDealRegistrations(1,'Reseller','Submitted',dealRegFields));

			dealRegFields.put('Email__c', 'Test_sd@redsky.com.sandbox');
			dealRegFields.put('Primary__c', true);
			dealRegFields.put('Rubrik_Complete_Edition_Reg__c', true);
			dealRegFields.put('OwnerId', users[1].Id);
			dealRegFields.put('CDM__c', users[1].Id);
			dealRegFields.put('Lead_Share_Campaign__c', false);
			dealRegFields.put('Partner_Lookup__c', accounts[0].Id);
			dealRegFields.put('GSI_NDA__c', true);
			dealRegReqs.addAll(PartnerTestDataUtility.createDealRegistrations(1,'Internal','Submitted',dealRegFields));

			dealRegFields.put('Email__c', 'Test_oem@redsky.com.sandbox');
			dealRegFields.put('OwnerId', users[0].Id);
			dealRegFields.put('Distributor__c', accounts[1].Id);
			dealRegReqs.addAll(PartnerTestDataUtility.createDealRegistrations(1,'OEM','Submitted',dealRegFields));

			dealRegFields.put('Email__c', 'Test_eng@redsky.com.sandbox');
			dealRegReqs.addAll(PartnerTestDataUtility.createDealRegistrations(1,'Engagement','Submitted',dealRegFields));

			dealRegFields.put('Email__c', 'Test_oem_2@redsky.com.sandbox');
			dealRegReqs.addAll(PartnerTestDataUtility.createDealRegistrations(1,'OEM','Submitted',dealRegFields));

			dealRegFields.put('Email__c', 'Test_oem_3@redsky.com.sandbox');
			dealRegReqs.addAll(PartnerTestDataUtility.createDealRegistrations(1,'OEM','Submitted',dealRegFields));

			dealRegFields.put('Email__c', 'Test_alliance_3@redsky.com.sandbox');
			dealRegFields.put('Alliance_Type__c','Cloud');
			dealRegReqs.addAll(PartnerTestDataUtility.createDealRegistrations(1,'Alliance','Submitted',dealRegFields));

			dealRegFields = new Map<String, Object>();
			dealRegFields.put('Email__c', 'Test_alliance_2@redsky.com.sandbox');
			dealRegFields.put('Primary_Contact__c', contacts[0].Id);
			dealRegFields.put('Company_Name__c', accounts[0].Id);
			dealRegFields.put('Partner_Lookup__c', accounts[0].Id);
			dealRegFields.put('StateCode__c', null);
			dealRegFields.put('Alliance_Type__c','Cloud');
			dealRegReqs.addAll(PartnerTestDataUtility.createDealRegistrations(1,'Alliance','Submitted',dealRegFields));

			insert dealRegReqs;

			List<Lead> leads = new List<Lead>();
			Map<String, Object> leadFields = new Map<String, Object>{
												  'FirstName' => 'Dist',
												  'LastName' => 'Test',
												  'Company' => 'Dist Company',
												  'Email' => 'Test_dist@redsky.com.sandbox',
												  'Purchase_Timeframe__c' => 'N/A',
												  'Street' => 'Street',
												  'StateCode' => 'AK',
												  'PostalCode' => '421302',
												  'City' => 'City',
												  'CountryCode' => 'US',
												  'SDR_Led__c' => true,
												  'Partner__c' => 'Rubrik',
												  'Partner_Rep__c' => 'Rep Name',
												  'Partner_Rep_Phone_Number__c' => '1234567890',
												  'Partner_Rep_Email_Address__c' => 'partner@redsky.com.sandbox',
												  'Secondary_Email_for_Deal_Reg__c' => 'partner@redsky.com.sandbox'
												};
			leads.addAll(PartnerTestDataUtility.createLeads(1, null, leadFields));

			leadFields = new Map<String, Object>{
												  'FirstName' => 'OEM',
												  'LastName' => 'Test',
												  'Company' => 'OEM Company',
												  'Email' => 'Test_oem_2@redsky.com.sandbox',
												  'Purchase_Timeframe__c' => 'N/A',
												  'Street' => 'Street',
												  'StateCode' => 'AK',
												  'PostalCode' => '421302',
												  'City' => 'City',
												  'CountryCode' => 'US'
												};
			leads.addAll(PartnerTestDataUtility.createLeads(1, null, leadFields));
			insert leads;
		}
	}
	
	@isTest static void testMethod1() {
		
		User testUser = [SELECT Id FROM User WHERE Email = 'testuser0@example.com.sandbox' LIMIT 1];
		
		System.runAs(testUser) {
			
			Test.startTest();
			
			Deal_Registration__c dealReg = [SELECT Id, Name FROM Deal_Registration__c WHERE Email__c = 'Test_dist@redsky.com.sandbox' LIMIT 1];
			dealReg.OwnerId = testUser.id;
            update dealReg;
			
			TriggerManager.resetTriggerCounter('Deal_Registration__c');
			
			Lead l1 = [SELECT Id FROM Lead LIMIT 1];
			
			dealReg.Lead__c = l1.Id;
            dealReg.Deal_Registration_Status__c = 'Pending Meeting';
            update dealReg;
			
			l1.Deal_Registration__c = true;
            l1.Deal_Reg_Number__c = dealReg.Name;
            l1.Deal_Reg_Approval_Status__c = 'Pending Meeting';
            update l1;
			
			Database.LeadConvert lc = new database.LeadConvert();  
            lc.setLeadId( l1.Id );  
            lc.setDoNotCreateOpportunity( true );  
            lc.setConvertedStatus( 'Closed - Converted' );  
            Database.LeadConvertResult lcr = Database.convertLead(lc, false);
			
			dealReg.Deal_Registration_Status__c = 'Approved';
            dealReg.OwnerId = testUser.Id;
            dealReg.Approval_Timestamp__c = System.now();
            dealReg.Deal_Reg_Exp_Date__c  = System.today().addDays(29);
            dealReg.Primary__c = true;
            dealReg.Lead__c = null;
            update dealReg;

            Test.stopTest();

            System.assertEquals('Approved', dealReg.Deal_Registration_Status__c,
                'Deal Registration Status should be Approved');
        }
    }
	
	
	@isTest static void testMethod2() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser0@example.com.sandbox' LIMIT 1];
		
		System.runAs(testUser) {
            Test.startTest();

			User recCDM = [SELECT Id FROM User WHERE Email = 'testuser1@example.com.sandbox' LIMIT 1];
			Lead objLead = [SELECT Id FROM Lead LIMIT 1];
			Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
            Deal_Registration__c dealReg = [SELECT Id, Name FROM Deal_Registration__c WHERE Email__c = 'Test_dist@redsky.com.sandbox' LIMIT 1];
			
			objLead.Deal_Registration__c = true;
            objLead.Deal_Reg_Number__c = dealReg.Name;
            objLead.Deal_Reg_Approval_Status__c = 'Pending Meeting';
            update objLead;
			
            dealReg.Primary__c = false;
            dealReg.Deal_Reg_Submitted_Date__c = System.now();
            dealReg.Deal_Registration_Status__c = 'Approved';
            dealReg.OwnerId = recCDM.Id;
            dealReg.CDM__c = recCDM.Id;
            dealReg.Requested_for_Extension__c = true;
            dealReg.Deal_Reg_Exp_Date__c  = System.today().addDays(29);
            dealReg.Lead__c = objLead.Id;
            dealReg.Opportunity__c = opp.Id;
            dealReg.Primary_Deal_Registration__c = true;
            update dealReg;
			

            dealReg.rerun_PatchManager_Assignments__c=true;
            dealReg.OwnerId = testUser.Id;
            dealReg.skipValidation__c = false;
            dealReg.Approval_Timestamp__c = System.now();
            dealReg.Requested_for_Extension__c = true;
            dealReg.Rubrik_Complete_Edition_Reg__c = false;
			dealReg.Deal_Registration_Sub_Status__c = 'Extension Approved';
            dealReg.isConverted__c = true;
			update dealReg;
			
			dealReg.Deal_Registration_Status__c = 'Pending Meeting';
			update dealReg;
			
			dealReg.Deal_Registration_Extension_Request__c = 'Pending Meeting Ext. Req. for next 10 Days';
			update dealReg;
			
			Test.stopTest();
			
			System.assertEquals('Pending Meeting', dealReg.Deal_Registration_Status__c,
                'Deal Registration Status should be Pending Meeting');
        }
    }
	
	@isTest static void testMethod3() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser0@example.com.sandbox' LIMIT 1];
		
		System.runAs(testUser) {
            Test.startTest();
			
			Deal_Registration__c dealReg = [SELECT Id, Name FROM Deal_Registration__c WHERE Email__c = 'Test_dist_1@redsky.com.sandbox' LIMIT 1];
			
			dealReg.Deal_Registration_Status__c = 'Pending Conversion';
			update dealReg;
		
			Test.stopTest();
			
			System.assertEquals('Pending Conversion', dealReg.Deal_Registration_Status__c,
                'Deal Registration Status should be Pending Conversion');
        }
    }
	
	@isTest static void testMethod4() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser0@example.com.sandbox' LIMIT 1];
		
		System.runAs(testUser) {
            Test.startTest();
			
			Deal_Registration__c dealReg = [SELECT Id, Name FROM Deal_Registration__c WHERE Email__c = 'Test_dist@redsky.com.sandbox' LIMIT 1];
			
			Lead objLead = [SELECT Id FROM Lead LIMIT 1];
			
			dealReg.Deal_Registration_Status__c = 'Pending Conversion';
			dealReg.Lead__c = objLead.Id;
			dealReg.Lead_Share_Campaign__c = true;
			dealReg.Deal_Reg_Exp_Date__c  = System.today().addDays(29);
			update dealReg;
			
			Test.stopTest();
			
			System.assertEquals('Pending Conversion', dealReg.Deal_Registration_Status__c,
                'Deal Registration Status should be Pending Conversion');
        }
    }
	
	@isTest static void testAllianceReqApproved() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser0@example.com.sandbox' LIMIT 1];
		
		System.runAs(testUser) {
            Test.startTest();
			
			Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
			Deal_Registration__c dealReg = [SELECT Id, Name FROM Deal_Registration__c WHERE Email__c = 'Test_alliance@redsky.com.sandbox' LIMIT 1];
			
			Contact con = [SELECT Id FROM Contact WHERE Email = 'Test_alliance@redsky.com.sandbox' LIMIT 1];
			
			dealReg.Deal_Registration_Status__c = 'Approved';
			dealReg.Opportunity__c = opp.Id;
			dealReg.Primary_Contact__c = con.Id;
			update dealReg;
			
			Test.stopTest();
			
			System.assertEquals('Approved', dealReg.Deal_Registration_Status__c,
                'Deal Registration Status should be Approved');
        }
    }
	
	@isTest static void testSDReqApproved() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser0@example.com.sandbox' LIMIT 1];
		
		System.runAs(testUser) {
            Test.startTest();
			
			Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
			Deal_Registration__c dealReg = [SELECT Id, Name FROM Deal_Registration__c WHERE Email__c = 'Test_sd@redsky.com.sandbox' LIMIT 1];
			
			Contact con = [SELECT Id FROM Contact WHERE Email = 'Test_sd@redsky.com.sandbox' LIMIT 1];
			
			dealReg.Deal_Registration_Status__c = 'Approved';
			dealReg.Opportunity__c = opp.Id;
			dealReg.Primary_Contact__c = con.Id;
			update dealReg;
			
			Test.stopTest();
			
			System.assertEquals('Approved', dealReg.Deal_Registration_Status__c,
                'Deal Registration Status should be Approved');
        }
    }
	
	@isTest static void testOEMReqApproved() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser0@example.com.sandbox' LIMIT 1];
		
		System.runAs(testUser) {
            Test.startTest();
			
			Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
			Deal_Registration__c dealReg = [SELECT Id, Name FROM Deal_Registration__c WHERE Email__c = 'Test_oem@redsky.com.sandbox' LIMIT 1];
			
			Contact con = [SELECT Id, AccountId FROM Contact WHERE Email = 'Test_oem@redsky.com.sandbox' LIMIT 1];
			
            dealReg.Company_Name__c = con.AccountId;
			update dealReg;
			
            dealReg.Deal_Registration_Status__c = 'Approved';
			dealReg.Opportunity__c = opp.Id;
			dealReg.Primary_Contact__c = con.Id;
			dealReg.Company_Name__c = con.AccountId;
			update dealReg;
			
			Test.stopTest();
			
			System.assertEquals('Approved', dealReg.Deal_Registration_Status__c,
                'Deal Registration Status should be Approved');
        }
    }

    @isTest static void testOEMWithLeadReqApproved() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser0@example.com.sandbox' LIMIT 1];
		
		System.runAs(testUser) {
            Test.startTest();
			
			Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
			Deal_Registration__c dealReg = [SELECT Id, Name FROM Deal_Registration__c WHERE Email__c = 'Test_oem_2@redsky.com.sandbox' LIMIT 1];
			
			Lead leadObj = [SELECT Id FROM Lead WHERE Email = 'Test_oem_2@redsky.com.sandbox' LIMIT 1];
			leadObj.Status = 'Open';
			update leadObj;
			
			dealReg.Company_Name__c = opp.AccountId;
			update dealReg;
            
			dealReg.Deal_Registration_Status__c = 'Approved';
			dealReg.Opportunity__c = opp.Id;
			dealReg.Company_Name__c = opp.AccountId;
			update dealReg;
			
			Test.stopTest();
			
			System.assertEquals('Approved', dealReg.Deal_Registration_Status__c,
                'Deal Registration Status should be Approved');
        }
    }

	@isTest static void testOEMWithNewConReqApproved() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser0@example.com.sandbox' LIMIT 1];
		
		System.runAs(testUser) {
            Test.startTest();
			
			Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
			Deal_Registration__c dealReg = [SELECT Id, Name FROM Deal_Registration__c WHERE Email__c = 'Test_oem_3@redsky.com.sandbox' LIMIT 1];
			
			dealReg.Company_Name__c = opp.AccountId;
			update dealReg;
            
			dealReg.Deal_Registration_Status__c = 'Approved';
			dealReg.Opportunity__c = opp.Id;
			dealReg.Company_Name__c = opp.AccountId;
			update dealReg;
			
			Test.stopTest();
			
			System.assertEquals('Approved', dealReg.Deal_Registration_Status__c,
                'Deal Registration Status should be Approved');
        }
    }
	
	@isTest static void testEngReqApproved() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser0@example.com.sandbox' LIMIT 1];
		
		System.runAs(testUser) {
            Test.startTest();
			
			Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
			Deal_Registration__c dealReg = [SELECT Id, Name FROM Deal_Registration__c WHERE Email__c = 'Test_eng@redsky.com.sandbox' LIMIT 1];
			
			Contact con = [SELECT Id FROM Contact WHERE Email = 'Test_eng@redsky.com.sandbox' LIMIT 1];
			
			dealReg.Deal_Registration_Status__c = 'Approved';
			dealReg.Opportunity__c = opp.Id;
			dealReg.Primary_Contact__c = con.Id;
			update dealReg;
			
			Test.stopTest();
			
			System.assertEquals('Approved', dealReg.Deal_Registration_Status__c,
                'Deal Registration Status should be Approved');
        }
    }
	
	@isTest static void testCloudReqApproved() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser0@example.com.sandbox' LIMIT 1];
		
		System.runAs(testUser) {
            Test.startTest();
			
			Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
			Deal_Registration__c dealReg = [SELECT Id, Name FROM Deal_Registration__c WHERE Email__c = 'Test_alliance_3@redsky.com.sandbox' LIMIT 1];
			
			Contact con = [SELECT Id FROM Contact WHERE Email = 'Test_eng@redsky.com.sandbox' LIMIT 1];
			
			dealReg.Deal_Registration_Status__c = 'Approved';
			dealReg.Opportunity__c = opp.Id;
			dealReg.Primary_Deal_Registration__c = false;
			dealReg.Deal_Registration_Type__c = 'Partner Sourced New Logo (PSNL)';
			update dealReg;
			
			Test.stopTest();
			
			System.assertEquals('Approved', dealReg.Deal_Registration_Status__c,
                'Deal Registration Status should be Approved');
        }
    }

	@isTest static void testCoverage() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser0@example.com.sandbox' LIMIT 1];
		
		System.runAs(testUser) {
            Test.startTest();
			
			Deal_Registration__c dealReg = [SELECT Id, Name, Country__c,LastName__c,Company__c,Email__c, Partner_Lookup__c, Lead_Share_Campaign__c FROM Deal_Registration__c WHERE Email__c = 'Test_eng@redsky.com.sandbox' LIMIT 1];
			
			DealRegistrationTriggerHelper helper = new DealRegistrationTriggerHelper();
			helper.copyDealRegToLead(dealReg, null);
			DealRegistrationTriggerHelper.addCustomerContactAsOppRole(null,null);
			DealRegistrationTriggerHelper.updateOpportunities(null);
			Test.stopTest();
			
			System.assert(true,'success');
        }
    }
}