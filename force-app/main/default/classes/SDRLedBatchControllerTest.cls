/**
 * @description  Test class for SDRLedBatchController
 * @Developer    Rubrik Dev
 */
@isTest
public class SDRLedBatchControllerTest {
    @TestSetUp
    static void initialDataSetup() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User managerUser = new User(
            FirstName = 'Manager', LastName = 'User', Email = 'manageruser@example.com',
            Username = 'manager91878@example.com', Alias = 'mgruser', TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert managerUser;
        
        User testUser2 = new User(
            FirstName = 'Test2', LastName = 'User2', Email = 'testusernew24591878@example.com',
            Username = 'testusernew24591878@example.com', Alias = 'tuser2', TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US',
            ProfileId = p.Id, ManagerId = managerUser.Id);
        insert testUser2;
        
        User testUser3 = new User(
            FirstName = 'Test3', LastName = 'User3', Email = 'testusernew391878@example.com',
            Username = 'testusernew391878@example.com', Alias = 'tuser3', TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US',
            ProfileId = p.Id, ManagerId = managerUser.Id);
        insert testUser3;
        
        System.runAs(testUser2) {
            Account objAccount = new Account();
            Contact objContact = new Contact();
            Contact objContact2 = new Contact();
            Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            objAccount.Name = 'Test Account 35-05';
            objAccount.RecordTypeId = recordTypeId;
            insert objAccount;
            objContact.Account = objAccount;
            objContact.LastName = 'Test Contact 34-05';
            insert objContact; 
            objContact2.Account = objAccount;
            objContact2.LastName = 'Test Contact 34-06';
            insert objContact2; 
            
            Opportunity newCustomerOpp = new Opportunity();
            newCustomerOpp.StageName = '1 Discovery';
            newCustomerOpp.closeDate = System.Today() + 30;
            newCustomerOpp.Name = 'Test Opp 35-05';
            newCustomerOpp.Opportunity_Type__c = 'New Customer';
            newCustomerOpp.Opportunity_Sub_Type__c = 'Regular';
            newCustomerOpp.Initial_Contacts_Name__c = objContact.Id;
            newCustomerOpp.Distributor_Lookup__c = objAccount.Id;
            newCustomerOpp.Partner_Lookup__c = objAccount.Id;
            newCustomerOpp.SDR_Led_override__c = false;
            newCustomerOpp.SDR_Led__c = false;
            insert newCustomerOpp;
            
            Opportunity existingCustomerOpp = new Opportunity();
            existingCustomerOpp.StageName = '1 Discovery';
            existingCustomerOpp.closeDate = System.Today() + 30;
            existingCustomerOpp.Name = 'Test Opp 35-06';
            existingCustomerOpp.Opportunity_Type__c = 'Existing Customer';
            existingCustomerOpp.Opportunity_Sub_Type__c = 'Regular';
            existingCustomerOpp.Initial_Contacts_Name__c = objContact.Id;
            existingCustomerOpp.Distributor_Lookup__c = objAccount.Id;
            existingCustomerOpp.Partner_Lookup__c = objAccount.Id;
            existingCustomerOpp.SDR_Led_override__c = false;
            existingCustomerOpp.SDR_Led__c = false;
            existingCustomerOpp.Credit_SDR_ISR_Meeting_link__c = '';
            insert existingCustomerOpp;
            
            OpportunityContactRole newCustomerRole = new OpportunityContactRole(
                OpportunityId = newCustomerOpp.Id,
                ContactId = objContact.Id,
                Role = 'Decision Maker'
            );
            insert newCustomerRole;
            OpportunityContactRole existingCustomerRole = new OpportunityContactRole(
                OpportunityId = existingCustomerOpp.Id,
                ContactId = objContact2.Id,
                Role = 'Decision Maker'
            );
            insert existingCustomerRole;
        }        
    }
    
    @isTest
    static void testSDRLedBatchForNewCustomer() {
        User u = [Select id from user where Username = 'testusernew24591878@example.com' limit 1];
        System.runAs(u) {
            ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
            sdb.Disable_Opportunity_Validation_Rules__c = true;
            insert sdb; 
            
            Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp 35-05' LIMIT 1];
            Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'Test Contact 34-05' LIMIT 1];
            
            Event newCustomerEvent = new Event(
                Subject = 'Test New Customer Meeting',
                StartDateTime = DateTime.now(),
                EndDateTime = DateTime.now().addHours(1),
                WhoId = testContact.Id,
                Type = 'Inside Sales Led Meeting',
                Post_Meeting_Status__c = 'Opportunity Sourced',
                Event_Status__c = 'Completed'
            );
            insert newCustomerEvent;
            
            Test.startTest();
            SDRLedBatchController batch = new SDRLedBatchController();
            Database.executeBatch(batch);
            Test.stopTest();
            
            Opportunity updatedOpp = [SELECT Id, SDR_Led__c, Meeting_Id__c, OriginalLeadOwner__c FROM Opportunity WHERE Id = :testOpp.Id];
            System.assertNotEquals(null, updatedOpp.Meeting_Id__c, 'Meeting_Id__c should be populated');
        }
    }
    
    @isTest
    static void testSDRLedBatchForExisitingCustomer() {
        User u = [Select id from user where Username = 'testusernew24591878@example.com' limit 1];
        System.runAs(u) {
            ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
            sdb.Disable_Opportunity_Validation_Rules__c = true;
            insert sdb; 
            
            Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp 35-06' LIMIT 1];
            Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'Test Contact 34-06' LIMIT 1];
            
            Event newCustomerEvent = new Event(
                Subject = 'Test Existing Customer Meeting',
                StartDateTime = DateTime.now(),
                EndDateTime = DateTime.now().addHours(1),
                WhoId = testContact.Id,
                Type = 'Inside Sales Led Meeting',
                Post_Meeting_Status__c = 'Opportunity Sourced',
                Event_Status__c = 'Completed'
            );
            insert newCustomerEvent;
            
            Test.startTest();
            SDRLedBatchController batch = new SDRLedBatchController();
            Database.executeBatch(batch);
            Test.stopTest();
            
            Opportunity updatedOpp = [SELECT Id, SDR_Led__c, Credit_SDR_ISR_Meeting_link__c, OriginalLeadOwner__c FROM Opportunity WHERE Id = :testOpp.Id];
            System.assertNotEquals('', updatedOpp.Credit_SDR_ISR_Meeting_link__c, 'Credit_SDR_ISR_Meeting_link__c should be populated');
        }
    }
    
    @isTest
    static void testSDRLedBatchWithNoMatchingData() {
        User u = [Select id from user where Username = 'testusernew391878@example.com' limit 1];
        System.runAs(u) {
            ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
            sdb.Disable_Opportunity_Validation_Rules__c = true;
            insert sdb; 
            
            Opportunity noMatchOpp = new Opportunity(
                Name = 'No Match Opportunity',
                StageName = 'Qualification',
                CloseDate = Date.today().addDays(30),
                Opportunity_Type__c = 'New Customer',
                SDR_Led_override__c = false,
                SDR_Led__c = false
            );
            insert noMatchOpp;
                        
            Test.startTest();
            SDRLedBatchController batch = new SDRLedBatchController();
            Database.executeBatch(batch);
            Test.stopTest();
            
            Opportunity updatedOpp = [SELECT Id, SDR_Led__c, Meeting_Id__c FROM Opportunity WHERE Id = :noMatchOpp.Id];
            System.assertEquals(false, updatedOpp.SDR_Led__c, 'SDR_Led__c should still be false');
            System.assertEquals(null, updatedOpp.Meeting_Id__c, 'Meeting_Id__c should still be null');
        }
    }
}