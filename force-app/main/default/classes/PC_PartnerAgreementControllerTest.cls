@isTest
public class PC_PartnerAgreementControllerTest {
    static User createUserAdmin() {
        Profile profile1 = [SELECT Id FROM Profile WHERE Name = 'System Administrator']; //System Administrator
        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        User sysAdmin = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() + 'sys1Admin12663@randomtestdomain.com',
            Alias = 'xmen',
            Email = System.now().millisecond() + 'random1.email2343@randomtestdomain.com',
            EmailEncodingKey = 'UTF-8',
            Firstname = 'test',
            Lastname = 'test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Chicago'
        );
        Database.insert(sysAdmin);
        return sysAdmin;
     }  
public static testMethod void testMethod1() {
    User user1 = createUserAdmin();
    User newPortalUser = new User();
    system.runas(user1){
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account AccRecord = new Account();
        AccRecord.Name = 'test';
        AccRecord.BillingStreet = 'street';
        AccRecord.BillingCity = 'city';
        AccRecord.BillingCountry = 'India';
        AccRecord.BillingPostalCode = '456789';
        AccRecord.RecordTypeId= devRecordTypeId;
        AccRecord.Type = 'Reseller';
        AccRecord.Contract_Status__c = 'Expired';
        insert AccRecord;
        
        Contact conObj = new Contact(LastName = 'lastname',
                                     FirstName = 'firstname',
                                     AccountId = AccRecord.Id,
                                     Email = 'a@a.com',Primary_Role__c='Admin');
        insert conObj;   
            
            newPortalUser.ProfileID = ID.valueOf(system.label.PartnerSFDCProfileId);
            newPortalUser.EmailEncodingKey = 'ISO-8859-1';
            newPortalUser.LanguageLocaleKey = 'en_US';
            newPortalUser.TimeZoneSidKey = 'America/New_York';
            newPortalUser.LocaleSidKey = 'en_US';
            newPortalUser.Alias ='puser';
            newPortalUser.FirstName = conObj.FirstName;
            newPortalUser.LastName = conObj.LastName;
            newPortalUser.Username = system.label.PortalUserNamePrefix+conObj.Email+1;   
            newPortalUser.CommunityNickname =String.ValueOf(Math.random());
            newPortalUser.Email = conObj.Email;
            newPortalUser.IsActive = true;
            newPortalUser.ContactId = conObj.Id;
            newPortalUser.Phone = conObj.Phone;
            newPortalUser.Street= conObj.MailingStreet;
            newPortalUser.City = conObj.MailingCity;
            newPortalUser.State = conObj.MailingState;
            newPortalUser.Country = conObj.MailingCountry;
            newPortalUser.PostalCode = conObj.MailingPostalCode;
            newPortalUser.UserPermissionsSFContentUser= true;
            newPortalUser.CompanyName = conObj.Account.Name;
            insert newPortalUser;  
        }
    system.runAs(newPortalUser){
        PC_PartnerAgreementController.getEmail();
        PC_PartnerAgreementController.getpartnerType();
        PC_PartnerAgreementController.save();
    }
}    
}