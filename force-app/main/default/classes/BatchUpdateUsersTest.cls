/** Created By : Grazitti
* Purpose : Test class for batchupdateUser
Last Modified : Grazitti Akash - CS-67 Jira Ticket

**/
@isTest(seeAllData=false)
public class BatchUpdateUsersTest {
    @isTest static void custCommSuperLogin(){
        Account acc = new Account();
        acc.Name = 'test';
        insert acc;
        Contact con = new Contact(LastName = 'lastname',
                                  FirstName = 'firstname',
                                  AccountId = acc.Id);
        insert con;
        //Id userLicenseId = [ select Id from UserLicense where NAME LIKE '%Customer Community%' LIMIT 1].id;
        //Id communityprofileId = [select Id from Profile where name like '%Rubrik Customer Community Super Login User%' and UserLicenseId=:userLicenseId].id;
        Id communityprofileId = [select Id from Profile where name like '%Rubrik Customer Community Login User%' LIMIT 1].id;
        
        User portalAccountOwner = new User(alias = 'test123', email='test123@noemail.com',
                                           emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                                           localesidkey='en_US', profileid = communityprofileId, country='United States',IsActive =true,
                                           ContactId = con.Id, FirstName = 'Test First',
                                           TimeZoneSidKey='America/Los_Angeles', username='tester@noemail.com', isAuthorizedUser__c=true);
        
        Database.insert(portalAccountOwner);
        String theQuery = '';

        theQuery = 'Select id,Usertype,TimeZoneSidKey,profile.name, Name,contactId,contact.user_profile__c,contact.Time_Zone__c from user where username = \'tester@noemail.com\'';
        
        BatchUpdateUsers c = new BatchUpdateUsers(theQuery);
        Database.executeBatch(c);

    }
    @isTest static void custComm(){
        Account acc = new Account();
        acc.Name = 'test';
        insert acc;
        Contact con = new Contact(LastName = 'lastname',
                                  FirstName = 'firstname',
                                  AccountId = acc.Id);
        insert con;
        Id userLicenseId = [ select Id from UserLicense where NAME LIKE '%Customer Community%' LIMIT 1].id;
        Id communityprofileId = [select Id from Profile where name like '%Rubrik Customer Community Login User%' LIMIT 1].id;
        
        User portalAccountOwner = new User(alias = 'test123', email='test123@noemail.com',
                                           emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                                           localesidkey='en_US', profileid = communityprofileId, country='United States',IsActive =true,
                                           ContactId = con.Id, FirstName = 'Test First',
                                           timezonesidkey='America/Los_Angeles', username='tester@noemail.com', isAuthorizedUser__c=true);
        
        Database.insert(portalAccountOwner);
        String theQuery = '';

        theQuery = 'Select id,Usertype,TimeZoneSidKey,profile.name, Name,contactId,contact.user_profile__c,contact.Time_Zone__c FROM User where username = \'tester@noemail.com\'';
        
        BatchUpdateUsers c = new BatchUpdateUsers(theQuery);
        Database.executeBatch(c);

    } 
    @isTest static void Partner(){
        
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
        Account AccRecord = new Account();
        AccRecord.Name = 'test';
        AccRecord.BillingStreet = 'street';
        AccRecord.BillingCity = 'city';
        AccRecord.BillingCountry = 'India';
        AccRecord.BillingPostalCode = '456789';
        AccRecord.RecordTypeId= devRecordTypeId;
        AccRecord.Type = 'Partner';
        insert AccRecord;
        
        Contact conObj = new Contact(LastName = 'lastname',
                                     FirstName = 'firstname',
                                     AccountId = AccRecord.Id,
                                     Email = 'a@a.com',Primary_Role__c='Admin');
        insert conObj;   
        User u = [select id,name from user where profile.name ='System Administrator' and isactive=true limit 1];
        User newPortalUser = new User();
        Id communityprofileId = [select Id from Profile where name like '%Rubrik Customer Community Login User%' LIMIT 1].id;

        system.runas(u)
        {
           
            newPortalUser.ProfileID = communityprofileId;
            newPortalUser.EmailEncodingKey = 'ISO-8859-1';
            newPortalUser.LanguageLocaleKey = 'en_US';
            newPortalUser.TimeZoneSidKey = 'America/New_York';
            newPortalUser.LocaleSidKey = 'en_US';
            newPortalUser.Alias ='puser';
            newPortalUser.FirstName = conObj.FirstName;
            newPortalUser.LastName = conObj.LastName;
            newPortalUser.Username = system.label.PortalUserNamePrefix+conObj.Email;   
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
            newPortalUser.CompanyName = conObj.Account.Name;
            insert newPortalUser;  
        }
        test.startTest();
        string theQuery = 'SELECT id,Usertype,TimeZoneSidKey,profile.name, Name,contactId,contact.user_profile__c,contact.Time_Zone__c FROM User where username =\''+ newPortalUser.username+'\'';
        BatchUpdateUsers  bc = new BatchUpdateUsers(theQuery );
        Database.executeBatch(bc);
        test.stopTest();
        //System.abortJob(batchID);
        
    }
    
    
    
    
}