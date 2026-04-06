@isTest
public with sharing class LeadUnFLagAfterRouteFeildBatchTest {
	//MKT23-717 Deployment
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

            
           Lead ld = new Lead(firstname='test12',AssignLeadInAfter__c=true,lastname='l12',company='ascc',email='gjh@gjygj.com',LeadSource='Email',status='Open',country='United States');
	 insert ld;
           // insert ld;

            
        }
    }

    @isTest static void testBatch(){
        Test.startTest();
            Database.executeBatch(new LeadUnFLagAfterRouteFeildBatch());
        Test.stopTest();
    }

    @isTest static void testScheduler(){
        Test.startTest();
            String sch = '0 0 23 * * ?'; 
            system.schedule('Test Lead Inactivation Check', sch, new LeadUnFLagAfterRouteFeildBatch()); 
        Test.stopTest(); 
    }
}