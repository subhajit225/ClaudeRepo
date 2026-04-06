/**
* @File Name : UpdateUserUrlsControllerTest.cls
* @description : test class for UpdateUserUrlsController and UpdateUserUrlsBatch
* @Author : Grazitti
* @Modification Log :
********************Change Logs ********************************************
* User Story 		Modified By          Date                     Description
* CS21-3349			Shailesh Kumar	 	 May 5, 2025			  Created this class
********************Change Logs Ends****************************************
**/
@IsTest(seeAllData=false)
public class UpdateUserUrlsControllerTest {
	@testSetup
    static void setup() {
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'Rubrik Customer Support User'].Id;
        User u = new User(
            ProfileId = profileId,
            FirstName = 'Test User',
            LastName = 'last',
            Email = 'testsupportuser@test.com',
            Username = System.now().millisecond() + 'testuser@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone()),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true);
        insert u;
        
        Id profileId2 = [SELECT Id, Name from Profile WHERE Name = 'Rubrik Customer Support Manager'].Id;
        User u2 = new User(
            ProfileId = profileId2,
            FirstName = 'Test User',
            LastName = 'last',
            Email = 'testsupportmanager@test.com',
            Username = System.now().millisecond() + 'testuser@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone()),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true);
        insert u2;
        
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'CS_User'];
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
        
        PermissionSet ps2 = [SELECT Id FROM PermissionSet WHERE Name = 'CS_Manager'];
        insert new PermissionSetAssignment(AssigneeId = u2.Id, PermissionSetId = ps2.Id);
	}
	@IsTest static void testUserInfo(){
		User u = [SELECT Id,Email FROM USER WHERE Email = 'testsupportuser@test.com' LIMIT 1];
		String usrId = UserInfo.getUserId();
		String jsonString = '[{"userId": "'+u.Id+'", "url": "www.invalidtest.com"}]';
		Test.startTest();
		System.runAs(u){
			UpdateUserUrlsController.saveUserInfoRecords(jsonString);
			User_Info__c uInfoRec = [SELECT Id, User__c,Url__c,Is_Updated__c,Automated_time_off_case_routing__c,Destination_queue_for_automated_time_off__c FROM User_Info__c WHERE Is_Updated__c = false];
			System.assertEquals(uInfoRec.Url__c, 'www.invalidtest.com' , 'success');

			UpdateUserUrlsBatch urlBatch = new UpdateUserUrlsBatch('SELECT Id, User__c,Url__c,Is_Updated__c,Automated_time_off_case_routing__c,Destination_queue_for_automated_time_off__c FROM User_Info__c WHERE Is_Updated__c = false');
			Database.executeBatch(urlBatch);
			
			
			String cronExp = '0 0 0 1 1 ? 2026'; // Runs once: Jan 1, 2026
        	System.schedule('Test User URL Scheduler', cronExp, new UpdateUserUrlsBatch(null));
		}
		Test.stopTest();
	}
    @IsTest static void testDestinationQueueUpdate(){
        User u = [SELECT Id,Email,Automated_time_off_case_routing__c,Destination_queue_for_automated_time_off__c FROM USER WHERE Email = 'testsupportmanager@test.com' LIMIT 1];
		String usrId = UserInfo.getUserId();
        Map<String,Object> testMap =  new Map<String,Object>{'Automated_time_off_case_routing__c' => 'Queue', 'Destination_queue_for_automated_time_off__c' => 'Upgrade'};
		//String jsonString = '[{"Automated_time_off_case_routing__c": "Queue","Destination_queue_for_automated_time_off__c":"Upgrade"}]';
		Test.startTest();
		System.runAs(u){
			UpdateUserUrlsController.saveUserFieldData(testMap);
            Boolean isManager = UpdateUserUrlsController.isUserManager();
			User_Info__c uInfoRec = [SELECT Id, User__c,Url__c,Is_Updated__c,Automated_time_off_case_routing__c,Destination_queue_for_automated_time_off__c FROM User_Info__c WHERE Is_Updated__c = false];
			System.assertEquals(uInfoRec.Destination_queue_for_automated_time_off__c, 'Upgrade' , 'success');
			System.assertEquals(isManager, true , 'success');
			UpdateUserUrlsBatch urlBatch = new UpdateUserUrlsBatch('SELECT Id, User__c,Url__c,Is_Updated__c,Automated_time_off_case_routing__c,Destination_queue_for_automated_time_off__c FROM User_Info__c WHERE Is_Updated__c = false');
			Database.executeBatch(urlBatch);
			
			String cronExp = '0 0 0 1 1 ? 2026'; // Runs once: Jan 1, 2026
        	System.schedule('Test User URL Scheduler', cronExp, new UpdateUserUrlsBatch(null));
		}
		Test.stopTest();
    }
    
    @IsTest static void testExistingUrl(){
        User u = [SELECT Id,Calendar_booking_URL__c  FROM User WHERE Email ='testsupportmanager@test.com' LIMIT 1];
        System.runAs(u){
            UpdateUserUrlsController.getExistingUrl('');
            UpdateUserUrlsController.getExistingUrl(u.Id);
            System.assertEquals(true,u.Id!=null);
        }
    }
	
}