@isTest
public class PC_PartnerRegistrationRequestQblTest {
	@testSetup static void setupmethod() {
        Profile p = [SELECT Id FROM Profile WHERE Name ='System Administrator'];
		Userrole usrRole = [SELECT Id FROM UserRole WHERE DeveloperName='Channel_Development_Manager'];
        String userName = 'PRUsr';
		User u = new User(Alias = 'std'+userName, Email=userName+'testuserdetails@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing'+userName, LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='testuserdetail@gmail.com'+userName, UserRoleId = usrRole.Id);
        System.runAs(u){
            Account accRec = ShGl_TestFactory.testMethod_PartnerAccount('Test Account');
            accRec.Name = 'TestCompany';
            update accRec;
                        
            List<Contact> contList = ShGl_TestFactory.testMethod_PartnerContact(2,accRec);
            contList[0].Email = 'partnerCommunityUser@gmailtest.sandbox.com';
            contList[1].Email = 'inactiveUser@gmailtest.sandbox.com';
            update contList;
            
            CountryWithCode__c CountrySetting1 = new CountryWithCode__c();
            CountrySetting1.Name = 'United States';
            CountrySetting1.Code__c = 'US';
            insert CountrySetting1;
    
            StateCodeName__C stateSetting1 = new StateCodeName__C();
            stateSetting1.Name = 'US-AL';
            stateSetting1.State_Name__c = 'Alabama';
            insert stateSetting1;
            
            List<User> userList = new List<User>();
            User portalUser0 = ShGl_TestFactoryHelper.createPortalUser(0,contList[0]); 
            portalUser0.ProfileId = ID.valueOf(system.label.PartnerSFDCProfileId);
            
            User portalUser1 = ShGl_TestFactoryHelper.createPortalUser(1,contList[1]); 
            portalUser1.isActive = false;
            
            userList.add(portalUser0);
            userList.add(portalUser1);
            insert userList;
        }
	}
    
    @isTest
    public static void testUserUpdate(){
        Profile p = [SELECT Id FROM Profile WHERE Name ='System Administrator'];
        String userName = 'adm';
        User adminUser = new User(Alias = 'Adm'+userName, Email=userName+'adminUserForTestClass@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing'+userName, LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='adminUserForTestClass@gmail.com'+userName);
        system.runAs(adminUser){
            Set<Id> activateUserIds = new Set<Id>();
            Set<Id> updateUserProfileIds = new Set<Id>();
            
            for(User u : [SELECT id, email, isActive, ProfileId FROM User WHERE Email IN ('inactiveUser@gmailtest.sandbox.com','partnerCommunityUser@gmailtest.sandbox.com')]){
                if(u.Email == 'inactiveUser@gmailtest.sandbox.com'){
                    activateUserIds.add(u.Id);
                }
                if(u.Email == 'partnerCommunityUser@gmailtest.sandbox.com'){
                    updateUserProfileIds.add(u.Id);
                }
            }
            
            Test.startTest();
            	System.enqueueJob(new PC_PartnerRegistrationRequestQueueable(activateUserIds,updateUserProfileIds));
            Test.stopTest();
            List<User> users = [SELECT id, email, isActive, Profile.Name FROM User WHERE Email IN ('inactiveUser@gmailtest.sandbox.com','partnerCommunityUser@gmailtest.sandbox.com')];
            System.assert(users[0].isActive, 'User 1 is activated');
            System.assertEquals(users[1].Profile.Name, 'Rubrik Partner Community Manager', 'User 2 profile is update');
        }
        
    }
}