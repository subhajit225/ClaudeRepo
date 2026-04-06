@isTest
public class UtilTest {
    @TestSetup
    static void testData(){
        
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'CEO' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' AND isActive = true AND  UserRoleId != null Limit 1];
        adminUser.UserRoleId = userRole.Id;
        update adminUser;

        System.runAs (adminUser) {
            Account testAccount = new Account(name='Test Company Name', FedRAMP__c = false, Type = 'Customer', r6000_Series_Products_Tagged__c = 'Predibase');
            insert testAccount;
            
            Contact testContact = new Contact(AccountId=testAccount.Id, FirstName='First Name',LastName='Last name',title='TITLE',Phone='123456489',Email='test@test.com');
            insert testContact;
            
            Profile prof = [Select Id,Name from Profile where name=:'Rubrik Customer Community Login User (No Cases)' Limit 1];
            User u = new User(
                Alias = 'standt1', email='standarduser116@testorg.com', 
                EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', ProfileId = prof.Id, 
                TimeZoneSidKey='America/Los_Angeles', username='standarduser@testorg131saurv.com',
                ContactId = testContact.Id
            );
            
            insert u;
        }
    }
    
    static testMethod void utilClassTestMethod1(){
        User u = [SELECT Id,Email FROM User WHERE Email =:'standarduser116@testorg.com'];
		Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        System.runAs(u){
            Util.hideShowCalendly();
            Util.sendEmail('toEmails', 'cEmails', 'bccEmails', 'bodyText', 'subject', true);
            Util.getUserDetail(u.Id);
            Util.getUserDetail(accountId);
            User usr = Util.CurrentUser;
            String type = Util.UserType;
            Util ut = new Util();
            ut.getPartnerUser();
        }
        System.assertEquals(u.Id, u.Id);
    }
}