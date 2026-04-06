@isTest
public class Batch_OneTimeCopyDataUsePermittedTest {
    
    /**
     * @description - Copy value of Privacy_Compliance__c to Data Use Permitted.
     */
    @IsTest
    static void testBatchForCampaignLeadContactCDM() {
        Profile pf = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1]; 
        User usr1 = (User) ShGl_TestFactory.createSObject(new User(), null);
        usr1.ProfileId = pf.Id;
        insert usr1;
        
        Lead leadRec;
        system.runAs(usr1){
            WorkflowTriggerBypass__c wtb = new WorkflowTriggerBypass__c(Name='cnsFirstAttemptUpdateLeadStatus',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb1 = new WorkflowTriggerBypass__c(Name='CreateSDRLedMeetingTask',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb2 = new WorkflowTriggerBypass__c(Name='leadReassignOnBusinessUnitChange',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb3 = new WorkflowTriggerBypass__c(Name='updateLastOwnershipUpdateDate',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb4 = new WorkflowTriggerBypass__c(Name='updateOpportunitySource',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb5 = new WorkflowTriggerBypass__c(Name='salesOperationInvokePatchManager',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb6 = new WorkflowTriggerBypass__c(Name='salesOperationsAssignAccountSIC',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb7 = new WorkflowTriggerBypass__c(Name='salesOperationsSetEUResident',ByPassTrigger__c=false);
            insert new List<WorkflowTriggerBypass__c>{wtb,wtb1,wtb2,wtb3,wtb4,wtb5,wtb6,wtb7};
                
            leadRec = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
            leadRec.firstName = 'Test';
            leadRec.lastName = 'Lead';
            leadRec.Status = 'Open';
            leadRec.CountryCode = 'US';
            leadRec.Routing_Rule_Applied__c ='test';
            leadRec.Last_MQL_Date__c = Date.today();
            leadRec.Privacy_Compliance__c = true;
            insert leadRec;
        }
        
        Test.startTest();
        Batch_OneTimeCopyDataUsePermitted batch = new Batch_OneTimeCopyDataUsePermitted();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        List<Lead> leads = [SELECT Privacy_Compliance__c, Data_Use_Permitted__c, IsConverted FROM Lead ORDER BY LastName];
        System.assertEquals(true, leads[0].Privacy_Compliance__c);
        System.assertEquals(true, leads[0].Data_Use_Permitted__c);
    }

}