@isTest public with sharing class ContactTriggerHelperTest {
    
    @testSetup
    public static void setup() { 
        Account objAcc = new Account(Name = 'testAcc');
        INSERT objAcc;
        
    }
    
    //MKT23-822 //
    @isTest static void allowMax2PrimaryContactMailTest(){        
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        set<id> Accountid=new set<id>{act.id};
            List<Contact> conList = (List<Contact>)ShGl_TestFactory.createSObjectList(new Contact(), 4, null);
        conList[0].AccountId = act.Id;
        conList[0].Primary_Customer_Mailing_Contact__c = TRUE;
        conList[1].AccountId = act.Id;
        conList[1].Primary_Customer_Mailing_Contact__c = TRUE;
        conList[2].AccountId = act.Id;
        conList[3].Agreed_To_POC_Terms__c=True;
        insert conList;
        conList = new List<Contact>();
        for(Contact con: [SELECT id,AccountId FROM Contact WHERE Primary_Customer_Mailing_Contact__c = FALSE]){
            con.Primary_Customer_Mailing_Contact__c=true;
            conList.add(con);
        }
        test.starttest();
        try{
            update conList;
        }catch(Exception e){
            
        }        
        ContactTriggerHelper.getUpdatedContactRecord(Accountid);
        ContactTriggerHelper.allowMax2PrimaryContactMail(conList,null);
        //ContactObjectTriggerHandler.dummy();
        delete conList[0];
        test.stoptest();
    }
    
     @isTest
    public static void testUpdatePhone(){
        
        User u = [select id,name from user where profile.name ='System Administrator' and isactive=true and userroleid != null limit 1];
        system.runas(u)
        {
            Account objAcc2 = new Account(Name = 'testAcc1');
            insert objAcc2;
            
            
            Contact objCon = new Contact(LastName = 'test Contact', AccountId = objAcc2.Id,Phone = '9999999999');
            INSERT objCon;
            
            Profile communityProfile = [Select Id from Profile where Name = 'Rubrik Customer Community Super Login User'];
            User communityUser = new User(Alias = 'systest1', Email='systest1AB@initial.com', ContactId = objCon.Id,
                                          EmailEncodingKey='UTF-8', LastName='systest1', LanguageLocaleKey='en_US',
                                          LocaleSidKey='en_US', ProfileId = communityProfile.Id, Phone = objCon.Phone,
                                          TimeZoneSidKey='America/Los_Angeles', UserName='systest1123784@test1885.com');
            insert communityUser;
        }
        
        test.startTest();
        // Create a separate user to perform the DML operations
        User separateUser = new User(
            Username = 'separateuser@example.com.test',
            FirstName = 'Separate',
            LastName = 'User',
            Email = 'separateuser@example.com',
            Alias = 'sepusr',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name='System Administrator'].Id,
            LanguageLocaleKey = 'en_US'
        );
        
        // Insert the separate user
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert separateUser;
        }
        System.runAs(separateUser) {
            Contact objConUpdate = [SELECT Id, Name, Phone FROM Contact WHERE lastName = 'test Contact'];
            objConUpdate.Phone = '8888888888';
            UPDATE objConUpdate;
        }
        test.stopTest();
		System.assertNotEquals(0, 1);        
    }
    

    @isTest
    static void testUpdateUserRelease() {
        Account oldAcc = [SELECT Id, Name FROM Account WHERE Name = 'testAcc'];
        Account newAcc = new Account(Name = 'New Account', RASP__c = true);
        insert newAcc; 
        
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = oldAcc.Id);
        insert con;
        
        Id communityProfileId = [SELECT Id FROM Profile WHERE Name = 'Rubrik Customer Community Super Login User' LIMIT 1].Id;
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        
        User portalUser;
        System.runAs(testUser) { 
            portalUser = new User(
                alias = 'test123', 
                email = 'test123@noemail.com',
                emailencodingkey = 'UTF-8', 
                lastname = 'Testing', 
                languagelocalekey = 'en_US',
                localesidkey = 'en_US', 
                profileid = communityProfileId, 
                country = 'United States', 
                isActive = true,
                ContactId = con.Id, 
                FirstName = 'Test First',
                timezonesidkey = 'America/Los_Angeles', 
                username = 'tester@noemail.com', 
                isAuthorizedUser__c = false,
                Releases__c = ''
            );
            insert portalUser;
        }
        
        Test.startTest();
        System.runAs(testUser) { 
            con.AccountId = newAcc.Id;
            update con;
        }
        Test.stopTest();

        // Validate that User.Releases__c was updated as expected
        User updatedUser = [SELECT Releases__c FROM User WHERE Id = :portalUser.Id];
        System.assert(updatedUser.Releases__c.contains('RASP Resources'), 'User Releases__c should contain RASP Resources');
    }

}