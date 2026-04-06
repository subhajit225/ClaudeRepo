/**
* @File Name : CaseDetailsControllerLWC_Test.cls
* @Description : Test Class for CaseDetailsControllerLWC apex class used for Hero Header section of Case Detail Page
* @Author : Grazitti
* @Last Modified By :
* @Last Modified On : March 6, 2025
* @Modification Log :
*========================================================
* Ver | Date | Author | Modification
*========================================================
* 1.0 | March 5, 2025 |   | Initial Version
**/

/********************Change Logs *************************************************************************
* Date | Author | Modification
* 25-03-2025 / Shailesh Kumar / increased test coverage for getCaseInfo method
* 14-April 2025 / Shailesh Kumar / added new method testGetEntitlementDetails
********************Change Logs Ends********************************************************************/
/**
    * @description Test Class for CaseDetailsControllerLWC apex class used for Hero Header section of Case Detail Page
*/
@IsTest
public class CaseDetailsControllerLWC_Test {
    /**
     * @description This method creates test data.
     * 
     */
    @testSetup
    static void setup() {
        Case cs = new Case();
        Id recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Case').getRecordTypeId();
        Id successCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Success').getRecordTypeId();
        Account acc = new Account(Name = 'Test Account',Type = 'Prospect',Partner_Agreement_Status__c = 'Signed - Inactive');
        INSERT acc;
        cs = new Case(AccountId = acc.Id,Subject = 'Test Case',Description = 'This is Test Case', RecordTypeId= recTypeId, Priority = 'P4 - Low',ownerid=UserInfo.getUserId(),Initial_Milestone_Flag_Name__c='Yellow');
        INSERT cs;
        
        Case cs2 = new Case(AccountId = acc.Id,Subject = 'Test Case CS',Description = 'This is Test CS Case', RecordTypeId= successCaseId, Priority = 'P4 - Low',ownerid=UserInfo.getUserId());
        INSERT cs2;
    }
    /**
    * @description This method tests the getFields methods using the CaseDetailsControllerLWC class.
    * @param: none
    */
    @IsTest
	public static void testGetFieldsFromCustomerSuccess() {
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'System Administrator'].Id;

        User u = new User(
            ProfileId = profileId,
            FirstName = 'Test User',
            LastName = 'last',
            Email = 'testuser@test.com',
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

        Test.startTest();
        System.runAs(u){
            CASE csRec = [SELECT Id, Subject, RecordTypeId, Priority, OwnerId,AccountId,Initial_Milestone_Flag_Name__c FROM CASE WHERE RecordType.Name ='Support Case' LIMIT 1];
            string recType = CaseDetailsControllerLWC.getRecType(csRec.Id);
            CaseDetailsControllerLWC.wrapperCase objWraper;
            objWraper = CaseDetailsControllerLWC.getFields(csRec.Id);
            System.assert(recType!=null,null);
        }
        Test.stopTest();
    }

    @IsTest
	public static void testGetCaseInfo() {
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'Rubrik Customer Support User'].Id;

        User u = new User(
            ProfileId = profileId,
            FirstName = 'Test User',
            LastName = 'last',
            Email = 'testuser@test.com',
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

        Test.startTest();
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'CS_User'];
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
        
        System.runAs(u){
            CASE csRec = [SELECT Id, Subject, RecordTypeId, Priority, OwnerId,AccountId,Initial_Milestone_Flag_Name__c FROM CASE LIMIT 1];
            CaseDetailsControllerLWC.WrapperCaseDetails csDetails = CaseDetailsControllerLWC.getCaseInfo(csRec.Id);//LIG-3
            System.assert(csDetails.recordTypeName!=null,null);
        }
        Test.stopTest();
    }
    @IsTest
	public static void testCustomerSuccesCase() {
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'Rubrik Customer Support User'].Id;

        User u = new User(
            ProfileId = profileId,
            FirstName = 'Test User',
            LastName = 'last',
            Email = 'testuser@test.com',
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

        Test.startTest();
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'CS_User'];
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
        
        System.runAs(u){
            CASE csRec = [SELECT Id, Subject, RecordTypeId, Priority, OwnerId,AccountId,Initial_Milestone_Flag_Name__c FROM CASE WHERE RecordType.Name ='Customer Success' LIMIT 1];
            CaseDetailsControllerLWC.Wrappercase csDetails = CaseDetailsControllerLWC.getFields(csRec.Id);//LIG-3
            System.assert(csDetails.recordDetail!=null,null);
        }
        Test.stopTest();
    }
}