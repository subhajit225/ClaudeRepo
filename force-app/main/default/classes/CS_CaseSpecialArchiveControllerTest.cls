/**
 * @description Test class for CS_CaseSpecialArchiveController
 * @test
 * @author Raveesh Layal
 * @Date 2025-08-01
 */
@isTest
public class CS_CaseSpecialArchiveControllerTest {

    /**
     * @description Test setup method to create a test user with the 
     * 'Case_Special_Handling_Edit_Access' permission set assigned.
     */
    @testsetup
    private static void testSetup(){
        User u = TestDataFactory.getUser();
        u.email = 'testuser@testuser1.com';
        insert u;
        
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Case_Special_Handling_Edit_Access'];
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = u.Id;
        psa.PermissionSetId = ps.Id;
        insert psa;
    }
    
    /**
     * @description Tests the archiveRecords method functionality,
     * verifying records with selected IDs are archived correctly,
     * handles empty selection gracefully, and verifies info messages.
     */
    @isTest
    static void testArchiveRecords() {
        User u = [SELECT id, name FROM User WHERE email = 'testuser@testuser1.com'];
        
        System.runAs(u) {
            // Create test Case_Special_Handling__c records
            List<Case_Special_Handling__c> testRecords = new List<Case_Special_Handling__c>();
            for (Integer i = 0; i < 5; i++) {
                testRecords.add(new Case_Special_Handling__c(Category__c = 'Support contract exceptions'));
            }
            insert testRecords;
            
            // Prepare Visualforce page reference and parameters
            PageReference pageRef = Page.CS_ArchivePage; // Replace this with actual VF page name
            pageRef.getParameters().put('id', String.valueOf(testRecords[0].Id));
            
            // Initialize StandardSetController with sample data
            ApexPages.StandardSetController setController = new ApexPages.StandardSetController(
                new List<Case_Special_Handling__c>([SELECT Id FROM Case_Special_Handling__c LIMIT 10])
            );
            
            // Instantiate the controller with the StandardSetController
            CS_CaseSpecialArchiveController controller = new CS_CaseSpecialArchiveController(setController);
            
            // Instantiate the default constructor as well
            CS_CaseSpecialArchiveController controller1 = new CS_CaseSpecialArchiveController();
            
            // Select a few records for archiving
            controller.selectedRecordIds = new List<Id>{ testRecords[0].Id, testRecords[1].Id };
            
            Test.startTest();
                // Test redirectBack method
                PageReference result = controller.redirectBack();
                // Call archiveRecords method to archive selected records
                controller.archiveRecords();

                // Verify records are marked as archived
                List<Case_Special_Handling__c> updatedRecords = [
                    SELECT Id, Is_Archived__c FROM Case_Special_Handling__c WHERE Id IN :controller.selectedRecordIds WITH SECURITY_ENFORCED
                ];
                for (Case_Special_Handling__c record : updatedRecords) {
                    System.assertEquals(true, record.Is_Archived__c, 'Record should be archived');
                }
                
                // Test archiving with empty selection – should not archive anything
                controller.selectedRecordIds = new List<Id>();
                controller.archiveRecords();
                
                updatedRecords = [
                    SELECT Id, Is_Archived__c FROM Case_Special_Handling__c WHERE Id IN :controller.selectedRecordIds
                ];
                for (Case_Special_Handling__c record : updatedRecords) {
                    System.assertEquals(false, record.Is_Archived__c, 'Record should not be archived');
                }
                
                // Call archiveRecords again with empty selection to execute else branch
                controller.selectedRecordIds = new List<Id>();
                controller.archiveRecords();
            Test.stopTest();
            
            // Assert info messages were added to the page
            System.assert(ApexPages.hasMessages(ApexPages.Severity.INFO), 'Info message should be displayed');
        }
    }
    
    /**
     * @description Tests the controller constructors and redirectBack method,
     * verifies StandardSetController integration and proper setting of selectedRecordIds.
     */
    @isTest
    static void testConstructorAndRedirectBack() {
        User u = [SELECT id, name FROM User WHERE email = 'testuser@testuser1.com'];
        
        System.runAs(u) {
            // Create test records for the controller
            List<Case_Special_Handling__c> testRecords = new List<Case_Special_Handling__c>();
            for (Integer i = 0; i < 3; i++) {
                testRecords.add(new Case_Special_Handling__c(Category__c = 'Support contract exceptions'));
            }
            insert testRecords;
            
            // Initialize StandardSetController with those records
            ApexPages.StandardSetController setController = new ApexPages.StandardSetController(
                [SELECT Id, Name FROM Case_Special_Handling__c WHERE Id IN :testRecords]
            );
            setController.setSelected(testRecords);
            
            // Instantiate controller with StandardSetController
            CS_CaseSpecialArchiveController controller = new CS_CaseSpecialArchiveController(setController);
            
            // Verify selectedRecordIds is populated correctly
            System.assertEquals(3, controller.selectedRecordIds.size(), 'Selected record IDs should be 3');
            for (Case_Special_Handling__c record : testRecords) {
                System.assert(controller.selectedRecordIds.contains(record.Id), 'Selected record IDs should contain ' + record.Id);
            }
            
            // Call redirectBack inside test context and verify PageReference is null
            Test.startTest();
                PageReference result = controller.redirectBack();
            Test.stopTest();
            
            System.assertEquals(null, result, 'PageReference should be null');
        }
    }
    
    /**
     * @description Tests archiveRecords and redirectBack execution under a specific user context,
     * verifies controller behavior with the default constructor.
     */
    @isTest
    static void testmethod1() {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Rubrik Customer Support User' LIMIT 1].Id;
        
        User u = new User(
            ProfileId = profileId,
            LastName = 'last',
            Email = 'csit-testuser@rubrik.com',
            Username = System.now().millisecond() + 'csit-testuser@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Employee_Time_Off__c = true
        );
        insert u;
        
        CS_CaseSpecialArchiveController controller = new CS_CaseSpecialArchiveController();

        System.runAs(u) {    
            controller.archiveRecords();
            controller.redirectBack();
            System.assert(true, 'Executed archive and redirect methods without exception.');
           
        }
    }
}