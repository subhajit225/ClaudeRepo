@IsTest
public class CS_CaseRetentionControllerTest {
    
    @TestSetup
    static void setupData() {
        // Insert Risk Profile Assignment 
        Risk_Profile_Assignment__c rp = new Risk_Profile_Assignment__c();
        rp.Last_Assigned_Index__c = 1;
        insert rp;
        
        // Insert Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Insert Contact
        Contact con = new Contact(LastName = 'Test Contact', AccountId = acc.Id);
        insert con;
        
        // Insert Risk Profile
        Risk_Profile__c riskProfile = new Risk_Profile__c(
            Account__c = acc.Id,
            Risk_Type__c = 'Account Risk',
            Primary_Risk_Reason__c = 'Support issues',
            Secondary_Risk_Reason__c = 'Support issues',
            Risk_Validation_Status__c = 'Invalid'
        );
        insert riskProfile;
        
        // Insert Case
        Case caseRecord = new Case(
            AccountId = acc.Id,
            ContactId = con.Id,
            Risk_Profile__c = riskProfile.Id,
            Subject = 'Test Case',
            Description = 'Test Case Description',
            Status = 'New',
            Priority = 'P1 - Critical'
        );
        insert caseRecord;
        
        // Insert Risk Profile PDM Features
        Risk_Profile_PDM_Feature__c pdmFeature1 = new Risk_Profile_PDM_Feature__c(
            Risk_Profile__c = riskProfile.Id
        );
        insert pdmFeature1;
        
        Risk_Profile_PDM_Feature__c pdmFeature2 = new Risk_Profile_PDM_Feature__c(
            Risk_Profile__c = riskProfile.Id
        );
        insert pdmFeature2;
    }
    
    @IsTest
    static void testGetRetentionCaseRecord() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        // Retrieve the test case
        Case testCase = [SELECT Id, Subject, Risk_Profile__c FROM Case LIMIT 1];
        
        // Call the method under test
        CS_CaseRetentionController cs = new CS_CaseRetentionController();
        CS_CaseRetentionController.CasePDMWrapper result = CS_CaseRetentionController.getRetentionCaseRecord(testCase.Id);
        
        // Add assertions to validate the response
        System.assertNotEquals(null, result, 'Result should not be null');
        
        // Validate the case record in the wrapper
        System.assertNotEquals(null, result.caseRecord, 'Case record in the wrapper should not be null');
        System.assertEquals(testCase.Id, result.caseRecord.Id, 'The Case ID in the wrapper should match the test case ID');
        System.assertEquals('Test Case', result.caseRecord.Subject, 'The Case Subject should match the test data');
        }
        
    }
}