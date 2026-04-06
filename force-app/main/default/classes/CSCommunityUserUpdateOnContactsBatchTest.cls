/**
* @description Test class for CSCommunityUserUpdateOnContactsBatch
*  - JIRA - CS21-788
*/
@isTest(SeeAllData=false)
public class CSCommunityUserUpdateOnContactsBatchTest {
    
    @testSetup
    static void dataSetUp() {
        
        OktaUserUtilityTest.oktaCustomSettingsParams();
        insert new TriggerControl__c(Name='User');
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
        User u = [SELECT Id, Name FROM User 
                  WHERE Profile.Name ='System Administrator' 
                  AND IsActive=true 
                  AND UserRoleId != null LIMIT 1];
        
        system.runas(u) {
            Account account = new Account();
            account.Name = 'test';
            account.BillingStreet = 'street';
            account.BillingCity = 'city';
            account.BillingCountry = 'India';
            account.BillingPostalCode = '456789';
            account.Type = 'Partner';
            insert account;
            
            Contact contact = new Contact(LastName = 'lastname',
                                          FirstName = 'firstname',
                                          AccountId = account.Id,
                                          CommunityUser__c = null,
                                          Email = 'a@a.com',
                                          Primary_Role__c='Admin');
            insert contact;
            
            User newPortalUser = new User();
            newPortalUser.ProfileID = ID.valueOf(system.label.PartnerSFDCProfileId);
            newPortalUser.EmailEncodingKey = 'ISO-8859-1';
            newPortalUser.LanguageLocaleKey = 'en_US';
            newPortalUser.TimeZoneSidKey = 'America/New_York';
            newPortalUser.LocaleSidKey = 'en_US';
            newPortalUser.Alias ='puser';
            newPortalUser.FirstName = contact.FirstName;
            newPortalUser.LastName = contact.LastName;
            newPortalUser.Username = system.label.PortalUserNamePrefix + contact.Email + 1;   
            newPortalUser.CommunityNickname =String.ValueOf(Math.random());
            newPortalUser.Email = contact.Email;
            newPortalUser.IsActive = true;
            newPortalUser.ContactId = contact.Id;
            newPortalUser.Phone = contact.Phone;
            newPortalUser.Street= contact.MailingStreet;
            newPortalUser.City = contact.MailingCity;
            newPortalUser.State = contact.MailingState;
            newPortalUser.Country = contact.MailingCountry;
            newPortalUser.PostalCode = contact.MailingPostalCode;
            newPortalUser.UserPermissionsSFContentUser= true;
            newPortalUser.CompanyName = contact.Account.Name;
            insert newPortalUser;  
        } 
    }
    
    @istest
    static void batchTest() {

        Contact contRec = [SELECT Id, CommunityUser__c FROM Contact WHERE Email = 'a@a.com' AND FirstName = 'firstname' AND LastName = 'lastname'];
        User userRec = [SELECT Id, ContactId FROM User WHERE ContactId =: contRec.Id];
        contRec.CommunityUser__c = null;

        test.startTest();

        User u = [SELECT Id, Name FROM User 
                  WHERE Profile.Name ='System Administrator' 
                  AND IsActive=true 
                  AND UserRoleId != null LIMIT 1];
        
        system.runas(u) {
            UPDATE contRec;
        }
        
        string query = 'SELECT Id, ContactId FROM User WHERE Id = \'' + String.escapeSingleQuotes(userRec.Id) + '\'';
        CSCommunityUserUpdateOnContactsBatch batchjob = new CSCommunityUserUpdateOnContactsBatch(query);
        Database.executeBatch(batchjob, 10); 
        test.stopTest();

		Contact contRec1 = [SELECT Id, CommunityUser__c FROM Contact WHERE Id =: contRec.Id];     
        System.assertEquals(userRec.Id, contRec1.CommunityUser__c, 'CommunityUser__c should be updated with User Id.');
    }   
}