/****************** LeadInactivationBatchTest is the Test Class for LeadInactivationBatch Class *************************/
@isTest
public with sharing class LeadInactivationBatchTest {
    
    /*Perpare the Setup Data*/
    @testSetup static void testDataSetup() {
        User user1 = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = TRUE LIMIT 1];
        system.runas(user1){
            //insert Custom Setting
            WorkflowTriggerBypass__c wtb = new WorkflowTriggerBypass__c(Name='cnsFirstAttemptUpdateLeadStatus',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb1 = new WorkflowTriggerBypass__c(Name='CreateSDRLedMeetingTask',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb2 = new WorkflowTriggerBypass__c(Name='leadReassignOnBusinessUnitChange',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb3 = new WorkflowTriggerBypass__c(Name='updateLastOwnershipUpdateDate',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb4 = new WorkflowTriggerBypass__c(Name='updateOpportunitySource',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb5 = new WorkflowTriggerBypass__c(Name='salesOperationInvokePatchManager',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb6 = new WorkflowTriggerBypass__c(Name='salesOperationsAssignAccountSIC',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb7 = new WorkflowTriggerBypass__c(Name='salesOperationsSetEUResident',ByPassTrigger__c=false);
            insert new List<WorkflowTriggerBypass__c>{wtb,wtb1,wtb2,wtb3,wtb4,wtb5,wtb6,wtb7};

            //initialize custom label
            String testLbl = Label.LeadCountryCodes; 
            String testLb2 = Label.LeadSourceValues;

            Lead led = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
            led.firstName = 'Test Lead FN';
            led.lastName = 'Test Lead LN';
            led.Status = 'Open';
            led.CountryCode = 'US';
            led.MQL__c = true;
            led.Campaign_Sourced_By__c = 'Marketing';
            //led.LastActivityDate = Date.today()-12;
            led.Last_MQL_Date__c = Date.today()-31;
            insert led;

            Task t = new Task(WhoId = led.id,
                            Subject = 'Test',
                            ActivityDate = Date.today()-20,
                            Status = 'Completed');
            insert t;
        }
    }

    /*Test the Batch Class*/
    @isTest static void testBatch(){
        List<Lead> leadQuery = [SELECT Id, Status, MQL__c, Last_MQL_Date__c, MeetingDate__c, LastActivityDate, Lead_Rejection_Reason__c FROM Lead LIMIT 100];
        Test.startTest();
            Database.executeBatch(new LeadInactivationBatch());
        	System.AssertEquals(leadQuery[0].Status, 'Open');
        Test.stopTest();
    }

    /*Test the Schedule Job*/
    @isTest static void testScheduler(){
        List<Lead> queryLeads = [SELECT Id, Status, MQL__c, Last_MQL_Date__c, MeetingDate__c, LastActivityDate, Lead_Rejection_Reason__c, CountryCode FROM Lead LIMIT 100];
        if(!queryLeads.isEmpty()){
            queryLeads[0].MQL__c = true;
            queryLeads[0].Status = 'Working';
            update queryLeads;
        }
        Test.startTest();
            String sch = '0 0 23 * * ?'; 
            system.schedule('Test Lead Inactivation Check', sch, new LeadInactivationBatch(queryLeads[0].Id));
        	System.AssertEquals(queryLeads[0].CountryCode, 'US');
        Test.stopTest(); 
    }
}