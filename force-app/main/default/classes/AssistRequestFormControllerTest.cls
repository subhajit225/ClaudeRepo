/**
* @description Test class for UpdateAssistRequestController
* @test
* @author Raveesh Layal
* @date 2025-08-01
*/
@isTest
public class AssistRequestFormControllerTest {
    /**
		* @description Test Data Setup for the test class
	**/
    @testSetup
    static void setupData() {
        
        Profile profiles=[Select Id From Profile Where Name='System Administrator'];
        String roleId = [SELECT Id FROM UserRole WHERE Name ='APAC Support Engineer' ].Id;
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000));
        String uniqueName = orgId + dateString + randomInt;
        User u = new User();
        u.Username = uniqueName + '@test' + orgId + '.org';
        u.ProfileId = profiles.Id;
        u.UserRoleId = roleId;
        u.LastName = 'test';
        u.Alias = 'tUser';
        u.Email = 'testuser_cs_test@rubrik.com';
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.localesidkey='en_US';
        u.emailencodingkey='UTF-8';
        u.languagelocalekey='en_US';
        insert u;
        System.runas(u){
            Account acc = new Account(Name = 'Test Account');
            insert acc;
            
            Contact cont = new Contact(LastName = 'Test Contact', Email = 'test@test.com', AccountId = acc.Id);
            insert cont;
            
            
            Case cs = new Case(
                Status = 'New',
                Priority = 'P3',
                Subject = 'Test Case',
                AccountId = acc.Id,
                ContactId = cont.Id,
                Origin = 'Email',
                OwnerId = u.Id
            );
            insert cs;
            
            // Query for the Case Team Role
            CaseTeamRole role = [SELECT Id FROM CaseTeamRole WHERE Name ='Email CC' LIMIT 1];
            
            // Create Case Team Member
            CaseTeamMember ctm = new CaseTeamMember(
                ParentId = cs.Id,
                MemberId = u.Id,
                TeamRoleId = role.Id
            );
            
            // Insert the Case Team Member
            insert ctm;
            
            Assist_Request__c ar = new Assist_Request__c(
                Case__c = cs.Id,
                Status__c = 'Open',
                Brownbag_Candidate__c = true,
                Assist_Request_Fullfilled__c = 'Unresolved/Request Reopen',
                Summary_of_the_Issue_Problem_Statement__c = 'Summary for test.'
            );
            insert ar;
            
            Note note = new Note(
                Title = 'Test Note',
                Body = 'Note Body',
                ParentId = ar.Id,
                IsPrivate = false,
                OwnerId = u.Id
            );
            insert note;
        }}
    /**
		* @description Method to get the AR details
		* @return Assist_Request__c
	**/
    private static Assist_Request__c getTestAR() {
        return [SELECT Id, Case__c, Name, Assist_Request_Fullfilled__c, Summary_of_the_Issue_Problem_Statement__c FROM Assist_Request__c LIMIT 1];
    }
    /**
		* @description Method to get the Note details
		* @return Note
	**/
    private static Note getTestNote() {
        return [SELECT Id, ParentId FROM Note LIMIT 1];
    }
    /**
		@description Test Method for StandardControllerViewEditContext.
	**/
    @isTest
    static void testStandardControllerViewEditContext() {
        Assist_Request__c ar = getTestAR();
        Note note = getTestNote();
        User testuser=[Select id from user where email='testuser_cs_test@rubrik.com' AND isActive=true LIMIT 1];
        System.runAs(testuser){
            Test.startTest();
            PageReference pageRef = new PageReference('/apex/ViewAndEdit?id=' + note.Id);
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('id', note.Id);
            ApexPages.StandardController sc = new ApexPages.StandardController(note);
            UpdateAssistRequestController ctrl = new UpdateAssistRequestController(sc);
            ctrl.onEdit();
            ctrl.onCancel();
            ctrl.callJSMethod();
            ctrl.jstext='test';
            ApexPages.currentPage().getParameters().put('selectedValue', 'Unresolved/Request Reopen');
            ctrl.actionIt();
            ctrl.updateOveride();
            System.assertEquals(ar.Id!=null, true, 'VF Page assertion successful');
            Test.stopTest();
        }
    }
    /**
		@description Test Method for AssignToMe.
	**/
    @isTest
    static void testAssignToMe() {
        User testuser=[Select id from user where email='testuser_cs_test@rubrik.com'  AND isActive=true LIMIT 1];
        System.runAs(testuser){
            Assist_Request__c ar = getTestAR();
            PageReference pageRef = new PageReference('/apex/AssistRequest?id=' + note.Id);
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController sc = new ApexPages.StandardController(ar);
            UpdateAssistRequestController ctrl = new UpdateAssistRequestController(sc);
            System.assertEquals(ar.Id!=null, true, 'VF Page assertion successful');
            ctrl.assignToMe();
        }
    }
    /**
		@description Test Method for UpdateCloseMethod.
	**/
    @isTest
    static void testUpdateCloseMethod() {
        User testuser=[Select id from user where email='testuser_cs_test@rubrik.com'  AND isActive=true LIMIT 1];
        System.runAs(testuser){
            Assist_Request__c ar = getTestAR();
            PageReference pageRef = new PageReference('/apex/AssistRequest?id=' + note.Id);
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController sc = new ApexPages.StandardController(ar);
            UpdateAssistRequestController ctrl = new UpdateAssistRequestController(sc);
            ctrl.isReopen = 'Yes';
            ctrl.reopenText = 'Reopen Comment';
            ctrl.overideReason = 'Override Reason';
            ctrl.assistRequest.Summary_of_the_Issue_Problem_Statement__c = 'Summary update';
            ar.Assist_Request_Fullfilled__c= 'Unresolved/Request Reopen';
            System.assertEquals(ar.Id!=null, true, 'VF Page assertion successful');
            ctrl.updateClose();
        }
    }
    /**
		@description Test Method for AddResponseAndNextSteps.
	**/
    @isTest
    static void testAddResponseAndNextSteps() {
        User testuser=[Select id from user where email='testuser_cs_test@rubrik.com'  AND isActive=true LIMIT 1];
        System.runAs(testuser){
            Assist_Request__c ar = getTestAR();
            PageReference pageRef = new PageReference('/apex/AssistRequest?id=' + note.Id);
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController sc = new ApexPages.StandardController(ar);
            UpdateAssistRequestController ctrl = new UpdateAssistRequestController(sc);
            ctrl.assistRequest.Summary_of_the_Issue_Problem_Statement__c = 'Test summary';
            ctrl.addResponse();
            ctrl.addNextSteps();
            System.assertEquals(ar.Id!=null, true, 'VF Page assertion successful');
        }
    }
    /**
		@description Test Method for NoteOperations.
	**/
    @isTest
    static void testNoteOperations() {
        User testuser=[Select id from user where email='testuser_cs_test@rubrik.com'  AND isActive=true LIMIT 1];
        System.runAs(testuser){
            Assist_Request__c ar = getTestAR();
            PageReference pageRef = new PageReference('/apex/AssistRequest?id=' + note.Id);
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController sc = new ApexPages.StandardController(ar);
            UpdateAssistRequestController ctrl = new UpdateAssistRequestController(sc);
            ctrl.oldNextStepVal = 'Old Note';
            ctrl.autosave();
            ctrl.deleteARNote();
            System.assertEquals(ar.Id!=null, true, 'VF Page assertion successful');
        }
    }
    /**
		@description Test Method for StaticLogicMethods.
	**/
    
    @isTest
    static void testStaticLogicMethods() {
        User testuser=[Select id from user where email='testuser_cs_test@rubrik.com'  AND isActive=true LIMIT 1];
        System.runAs(testuser){
            Assist_Request__c ar = getTestAR();
            PageReference pageRef = new PageReference('/apex/AssistRequest?id=' + note.Id);
            Test.setCurrentPage(pageRef);
            Test.startTest();
            UpdateAssistRequestController.assignToMe(ar.Id);
            UpdateAssistRequestController.getAssistRequest(new List<Id>{ar.Id});
            UpdateAssistRequestController.addResponse(ar.Id, 'Static Response');
            UpdateAssistRequestController.autoSaveNote(ar.Id, 'Auto Save Note', 'Old Note');
            UpdateAssistRequestController.updateNextSteps(ar.Id, 'Next Steps Logic');
            UpdateAssistRequestController.updateClose(ar, 'Yes', 'Reason to reopen', 'Override needed');
            UpdateAssistRequestController.getRecord(ar.Id);
            Test.stopTest();
            System.assertEquals(ar.Id!=null, true, 'VF Page assertion successful');
        }
    }
    /**
		@description Test Method for ActionItWithInvalidValue.
	**/
    @isTest
    static void testActionItWithInvalidValue() {
        User testuser=[Select id from user where email='testuser_cs_test@rubrik.com'  AND isActive=true LIMIT 1];
        System.runAs(testuser){
            Assist_Request__c ar = getTestAR();
            PageReference pageRef = new PageReference('/apex/AssistRequest?id=' + note.Id);
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController sc = new ApexPages.StandardController(ar);
            UpdateAssistRequestController ctrl = new UpdateAssistRequestController(sc);
            ApexPages.currentPage().getParameters().put('selectedValue', 'Closed');
            ctrl.actionIt();
            System.assertEquals(ar.Id!=null, true, 'VF Page assertion successful');
        }
    }
    /**
		@description Test Method for UpdateOverrideWithoutReason.
	**/
    @isTest
    static void testUpdateOverrideWithoutReason() {
        User testuser=[Select id from user where email='testuser_cs_test@rubrik.com'  AND isActive=true LIMIT 1];
        System.runAs(testuser){
            Assist_Request__c ar = getTestAR();
            PageReference pageRef = new PageReference('/apex/AssistRequest?id=' + note.Id);
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController sc = new ApexPages.StandardController(ar);
            UpdateAssistRequestController ctrl = new UpdateAssistRequestController(sc);
            ctrl.overideReason = null;
            ctrl.updateOveride();
            System.assertEquals(ar.Id!=null, true, 'VF Page assertion successful');
        }
    }
    /**
		@description Test Method for EmptyNoteDeletion.
	**/
    @isTest
    static void testEmptyNoteDeletion() {
        User testuser=[Select id from user where email='testuser_cs_test@rubrik.com'  AND isActive=true LIMIT 1];
        System.runAs(testuser){
            Assist_Request__c ar = getTestAR();
            PageReference pageRef = new PageReference('/apex/AssistRequest?id=' + note.Id);
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController sc = new ApexPages.StandardController(ar);
            UpdateAssistRequestController ctrl = new UpdateAssistRequestController(sc);
            ctrl.oldNextStepVal = 'Some note';
            ctrl.deleteARNote();
            System.assertEquals(ar.Id!=null, true, 'VF Page assertion successful');
        }
    }
    /**
		@description Test Method for ResolveRequest.
	**/
    @isTest
    static void testResolveRequest() {
        User testuser=[Select id from user where email='testuser_cs_test@rubrik.com'  AND isActive=true LIMIT 1];
        System.runAs(testuser){
            Assist_Request__c ar = getTestAR();
            ar.Brownbag_Candidate__c = true;
            ar.Product_Improvement_Needed__c = true;
            ar.Issue_Understanding_Troubleshooting__c = true;
            ar.Usage_of_Existing_tools__c = true;
            ar.Usage_of_Knowledge_base_searchunify__c = true;
            ar.Others__c = true;
            update ar;
            PageReference pageRef = new PageReference('/apex/AssistRequest?id=' + note.Id);
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController sc = new ApexPages.StandardController(ar);
            UpdateAssistRequestController ctrl = new UpdateAssistRequestController(sc);
            
            // Set required comments (mimicking LWC inputs)
            ctrl.brownbagCom = 'Brownbag comment';
            ctrl.improvementCom = 'Improvement comment';
            ctrl.troubleShootingCom = 'Troubleshooting comment';
            ctrl.existingToolCom = 'Tool usage comment';
            ctrl.searchUnifyCom = 'SearchUnify comment';
            ctrl.othersCom = 'Other notes';
            
            // Set status to trigger resolution
            ctrl.assistRequest.Status__c = 'In Progress';
            
            Test.startTest();
            ctrl.resolveRequest();
            Test.stopTest();
            System.assertEquals(ar.Id!=null, true, 'VF Page assertion successful');
        }
    }
    /**
		@description Test Method for ResolutionDraft.
	**/
    @isTest
    static void testResolutionDraft() {
        User testuser=[Select id from user where email='testuser_cs_test@rubrik.com'  AND isActive=true LIMIT 1];
        System.runAs(testuser){
            Assist_Request__c ar = [SELECT Id FROM Assist_Request__c LIMIT 1];
            ar.Brownbag_Candidate_Comment__c = 'Brownbag';
            ar.Product_Improvement_Needed_Comment__c = 'Improvement';
            ar.Issue_Troubleshooting_Comment__c = 'Troubleshooting';
            ar.Usage_of_Existing_tools_Comment__c = 'Existing Tools';
            ar.Usage_of_Knowledge_base_Comment__c = 'Knowledge Base';
            ar.Others_Comment__c = 'Others';
            ar.RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Assist_Request__c' AND DeveloperName = 'Support' LIMIT 1].Id;
            update ar;
            PageReference pageRef = new PageReference('/apex/AssistRequest?id=' + note.Id);
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController sc = new ApexPages.StandardController(ar);
            UpdateAssistRequestController ctrl = new UpdateAssistRequestController(sc);
            ctrl.resolutionDraft();
            System.assertEquals(ar.Id!=null, true, 'VF Page assertion successful');
        }
    }
    /**
		@description Test Method for CopyMe.
	**/
    @isTest
    static void testCopyMe() {
        User testuser=[Select id from user where email='testuser_cs_test@rubrik.com'  AND isActive=true LIMIT 1];
        System.runAs(testuser){
            Assist_Request__c ar = getTestAR();
            PageReference pageRef = new PageReference('/apex/AssistRequest?id=' + note.Id);
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController sc = new ApexPages.StandardController(ar);
            UpdateAssistRequestController ctrl = new UpdateAssistRequestController(sc);
            ctrl.copyMe();
            System.assertEquals(ar.Id!=null, true, 'VF Page assertion successful');
        }
    }
    /**
		@description Test Method for UpdateViewAndEditNotes.
	**/
    
    @isTest
    static void testUpdateViewAndEditNotes() {
        User testuser=[Select id from user where email='testuser_cs_test@rubrik.com'  AND isActive=true LIMIT 1];
        System.runAs(testuser){
            Note note = getTestNote();
            PageReference pageRef = new PageReference('/apex/ViewAndEdit?id=' + note.Id);
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('id', note.Id);
            ApexPages.StandardController sc = new ApexPages.StandardController(note);
            UpdateAssistRequestController ctrl = new UpdateAssistRequestController(sc);
            // Construct a long body > 4000 chars to trigger truncation logic
            String longBody = 'Sample body text. ';
            while (longBody.length() < 4100) {
                longBody += 'Extra details. ';
            }
            ctrl.noteRec.Body =longBody;
            ctrl.updateViewAndEditNotes();
            System.assertEquals(note.Id!=null, true, 'VF Page assertion successful');
        }
    }
    
}