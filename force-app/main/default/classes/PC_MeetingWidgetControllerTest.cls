@isTest(SeeAllData=false) 
public class PC_MeetingWidgetControllerTest {
    @TestSetup
    static void makeData(){
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        Profile adminProf = [Select Id from Profile where name = 'System Administrator'];
        Profile portalProfile = [SELECT Id FROM Profile Where Name='Rubrik Partner community Manager' Limit 1];

        User portalAccountOwner1 = new User(
            UserRoleId = portalRole.Id,
            ProfileId = adminProf.Id,
            Username = System.now().millisecond() + 'testpuser2@test.com',
            Alias = 'batman',
            Email='bruce.wayne@wayneenterprises.com',
            EmailEncodingKey='UTF-8',
            Firstname='Bruce',
            Lastname='Wayne',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago'
        );
        Database.insert(portalAccountOwner1);
        System.runAs ( portalAccountOwner1 ) {
            //Create Account
            Account portalAccount1 = new Account(Name = 'TestAccount', OwnerId = portalAccountOwner1.Id);
            Database.insert(portalAccount1);
            
            //Create contact
            Contact contact1 = new Contact(
                FirstName = 'Test',
                Lastname = 'McTesty',
                AccountId = portalAccount1.Id,
                Email = System.now().millisecond() + 'test@test.com',
                Primary_Role__c = 'Admin'
            );
            insert contact1;
            
            User portalUser = new User(
                Username = System.now().millisecond() + 'tespuser1@test.com',
                ContactId = contact1.Id,
                ProfileId = portalProfile.Id,
                Alias = 'test123',
                Email = 'test12345@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'McTesty',
                CommunityNickname = 'test12345',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            Database.insert(portalUser);

            List<WorkflowTriggerBypass__c> wtList = new List<WorkflowTriggerBypass__c>();
            WorkflowTriggerBypass__c wt = new WorkflowTriggerBypass__c(name='leadReassignOnBusinessUnitChange',ByPassTrigger__c=false);
            wtList.add(wt);
            WorkflowTriggerBypass__c wt1 = new WorkflowTriggerBypass__c(name='cnsFirstAttemptUpdateLeadStatus',ByPassTrigger__c=false);
            wtList.add(wt1);
            WorkflowTriggerBypass__c wt2 = new WorkflowTriggerBypass__c(name='CreateSDRLedMeetingTask',ByPassTrigger__c=false);
            wtList.add(wt2);
            WorkflowTriggerBypass__c wt3 = new WorkflowTriggerBypass__c(name='updateLastOwnershipUpdateDate',ByPassTrigger__c=false);
            wtList.add(wt3);
            WorkflowTriggerBypass__c wt4 = new WorkflowTriggerBypass__c(name='updateOpportunitySource',ByPassTrigger__c=false);
            wtList.add(wt4);
            WorkflowTriggerBypass__c wt5 = new WorkflowTriggerBypass__c(name='salesOperationsAssignAccountSIC',ByPassTrigger__c=false);
            wtList.add(wt5);
            WorkflowTriggerBypass__c wt6 = new WorkflowTriggerBypass__c(name='salesOperationsSetEUResident',ByPassTrigger__c=false);
            wtList.add(wt6);
            insert wtList;
        }
        
    }

    @isTest static void testMeeting(){
        User u = [SELECT Id FROM User where lastname = 'McTesty'];
        system.runas(u){
            Lead  newLead = TestDataFactory.insertLead();
            insert newLead;
            PC_MeetingWidgetController.createMeeting(System.now(),system.now().addDays(4),newLead.Id);
            Event e = PC_MeetingWidgetController.getLatestMeeting(newLead.Id);
            PC_MeetingWidgetController.rescheduleMeeting(System.now(),system.now().addDays(3),e.Id);
            PC_MeetingWidgetController.updateOutcome('No Opportunity sourced','No found potential champion',null,e.Id);
        }
    }

    @isTest static void testExceptionHandling(){
        User u = [SELECT Id FROM User where lastname = 'McTesty'];
        system.runas(u){
            Lead  newLead = TestDataFactory.insertLead();
            insert newLead;
            try{
                PC_MeetingWidgetController.createMeeting(System.now(),system.now().addDays(-4),newLead.Id);
            }catch(Exception e){
                system.debug(e);
            }
            
            try{
                PC_MeetingWidgetController.getLatestMeeting('test');
            }catch(Exception e){
                system.debug(e);
            }

            try{
                PC_MeetingWidgetController.createMeeting(System.now(),system.now().addDays(4),newLead.Id);
                Event e = PC_MeetingWidgetController.getLatestMeeting(newLead.Id);
                PC_MeetingWidgetController.rescheduleMeeting(System.now(),system.now().addDays(-3),e.Id);
            }catch(Exception e){
                system.debug(e);
            }

            try{
                PC_MeetingWidgetController.createMeeting(System.now(),system.now().addDays(4),newLead.Id);
                Event e = PC_MeetingWidgetController.getLatestMeeting(newLead.Id);
                PC_MeetingWidgetController.updateOutcome('test','No found potential champion',null,e.Id);
            }catch(Exception e){
                system.debug(e);
            }
        }
    }
}