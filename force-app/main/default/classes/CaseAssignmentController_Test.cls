/**
* @File Name : CaseAssignmentController_Test.cls
* @description : Test Class for CaseAssignmentController.cls
* @Modification Log :
********************Change Logs ********************************************
* User Story            Modified By          Date               Description
* CS21-3349             Shailesh Kumar	    June 04, 2025		Added methods for coverage
********************Change Logs Ends****************************************
**/
@IsTest(seeAllData=false)
public class CaseAssignmentController_Test {
	@TestSetup static void setup(){
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'System Administrator'].Id;
        User u = new User(
            ProfileId = profileId,FirstName = 'Test User',
            LastName = 'last123',
            Email = 'testsupportmanager@test.com',
            Username = System.now().millisecond() + 'testuser@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone()),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            is_Customer_Success_User__c = true,
            IsActive = true);
        insert u;
        
        User u2 = new User(
            ProfileId = profileId,FirstName = 'Test User',
            LastName = 'last123',
            Email = 'testsupportuser@test.com',
            Username = System.now().millisecond() + 'testsupportuser@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone()),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            is_Customer_Success_User__c = true,
            IsActive = true);
        insert u2;
        Group csmGroup = new Group(
            Name = 'CSM_Group',
            Type = 'Regular'
        );
        insert csmGroup;

        List<GroupMember> grpmList = new List<GroupMember>();
        GroupMember grpm1 = new GroupMember(GroupId = csmGroup.Id, UserOrGroupId = u.Id);
        GroupMember grpm2 = new GroupMember(GroupId = csmGroup.Id, UserOrGroupId = u2.Id);
        grpmList.add(grpm1);
        grpmList.add(grpm2);
        insert grpmList;
    }
	static testmethod void testGetList(){
		User u = [SELECT Id,Email FROM USER WHERE Email = 'testsupportmanager@test.com' LIMIT 1];
		Group csQueue = [SELECT Id,Name,Type,Email FROM Group WHERE DeveloperName ='Customer_Success' AND Type = 'Queue'];
		insert new RoundRobinSetting__c(Name = 'LastCSMId', Last_Assigned_CSM__c ='');
		Id recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Success').getRecordTypeId();
		Account acct = new Account(Name = 'Test Account');
    	insert acct;
        
		Test.startTest();
		List<Case> testCases = new List<Case>();
		for (Integer i = 0; i < 3; i++) {
            testCases.add(new Case(
                Subject = 'Test Case ' + i,
                Status = 'New',
                RecordTypeId = recTypeId,
                AccountId = acct.Id,
                OwnerId = csQueue.Id,
                Phase__c = Math.mod(i, 2) == 0 ? 'Onboarding' : 'Adoption',
                Product_Name__c = Math.mod(i, 2) == 0 ? 'CDM' : 'Appflows'
            ));
		}
        testCases.add(new Case(
            Subject = 'Test Case ' + 123,
            Status = 'New',
            RecordTypeId = recTypeId,
            OwnerId = u.Id,
            AccountId = acct.Id,
            Phase__c = 'Onboarding',
            Product_Name__c = 'CDM'
        ));
		insert testCases;
        System.runAs(u){
            List<User> usrList = [SELECT Id FROM User WHERE LastName ='last123' Order By CreatedDate Desc LIMIT 2];
            //RoundRobinCaseAssignment.csms = usrList;
			CaseAssignmentController.WrapperRoundRobinResult roundRobinResult = CaseAssignmentController.getRoundRobinedCases(25);
            System.assertNotEquals(0,roundRobinResult.roundRobinCases.size(),'Case count should not be zero');
            for (CaseAssignmentController.WrapperCaseDetails wrapperCase : roundRobinResult.roundRobinCases) {
                wrapperCase.ownerId = u.Id;
            }
            CaseAssignmentController.updateCaseOwners(roundRobinResult.roundRobinCases, u.Id);
		}
        Test.stopTest();
	}
    
    static testmethod void testAssignCasesToCSM(){
		User u = [SELECT Id,Email FROM USER WHERE Email = 'testsupportmanager@test.com' LIMIT 1];
		Group csQueue = [SELECT Id FROM Group WHERE DeveloperName= 'Customer_Success' AND Type ='Queue'];
		insert new RoundRobinSetting__c(Name = 'LastCSMId', Last_Assigned_CSM__c =u.Id);
		Id recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Success').getRecordTypeId();
		Account acct = new Account(Name = 'Test Account');
    	insert acct;
		Case cs = new Case(
                Subject = 'Test Case new 123',
                Status = 'New',
                RecordTypeId = recTypeId,
                OwnerId = u.Id,
                AccountId = acct.Id,
                Phase__c = 'Onboarding',
                Product_Name__c = 'CDM');
        insert cs;
		List<Case> testCases = new List<Case>();
		for (Integer i = 0; i <= 3; i++) {
            testCases.add(new Case(
                Subject = 'Test Case ' + i,
                Status = 'New',
                RecordTypeId = recTypeId,
                OwnerId = csQueue.Id,
                AccountId = acct.Id,
                Phase__c = Math.mod(i, 2) == 0 ? 'Onboarding' : 'Adoption',
                Product_Name__c = Math.mod(i, 2) == 0 ? 'CDM' : 'Appflows'
            ));
		}
		insert testCases;
        
        Test.startTest();
        System.runAs(u){
            List<User> usrList = [SELECT Id FROM User WHERE LastName ='last123' Order By CreatedDate Desc LIMIT 2];
            //RoundRobinCaseAssignment.csms = usrList;
            List<Case> existingTestCases = [SELECT Id, CaseNumber, AccountId,Account.Name, OwnerId, Phase__c, Product_Name__c, Status, CreatedDate FROM Case WHERE OwnerId=:csQueue.Id 
                             AND AccountId != null AND RecordTypeId=:recTypeId  
                             AND Phase__c IN ('Onboarding','Adoption') And isClosed = false];
			RoundRobinCaseAssignment.WrapperRoundRobin roundRobinResult = RoundRobinCaseAssignment.assignCasesToCSM(existingTestCases);
            System.assertNotEquals(0,roundRobinResult.cases.size(),'Case count should not be zero');
		}
        Test.stopTest();
	}
    
    static testmethod void testGetUserName(){
        User u = [SELECT Id,Email,Name FROM USER WHERE Email = 'testsupportmanager@test.com' LIMIT 1];
        Test.startTest();
        System.runAs(u){
            String uName = CaseAssignmentController.getUserName(String.valueOf(u.Id));
			System.assertEquals(u.Name,uName);      
            CaseAssignmentController.WrapperCaseDetails testObj = new CaseAssignmentController.WrapperCaseDetails();
            testObj.queueName = 'test';
        }
        Test.stopTest();
    }
}