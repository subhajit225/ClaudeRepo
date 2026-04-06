@isTest
public class StopStandardEmailForFeedBatch_Test1 {
  public testmethod static void  stopStandardEmailTest(){
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
        
        StopStandardEmailForFeedBatch c = new StopStandardEmailForFeedBatch(theQuery);
        Database.executeBatch(c);
    }
    
}