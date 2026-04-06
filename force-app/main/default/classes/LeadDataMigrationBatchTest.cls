@isTest
private class LeadDataMigrationBatchTest {

    @isTest
    static void testLeadDataMigrationBatch() {
        List<Lead> leads = new List<Lead>();
		WorkflowTriggerBypass__c wtb = new WorkflowTriggerBypass__c(Name='cnsFirstAttemptUpdateLeadStatus',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb1 = new WorkflowTriggerBypass__c(Name='CreateSDRLedMeetingTask',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb2 = new WorkflowTriggerBypass__c(Name='leadReassignOnBusinessUnitChange',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb3 = new WorkflowTriggerBypass__c(Name='updateLastOwnershipUpdateDate',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb4 = new WorkflowTriggerBypass__c(Name='updateOpportunitySource',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb5 = new WorkflowTriggerBypass__c(Name='salesOperationInvokePatchManager',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb6 = new WorkflowTriggerBypass__c(Name='salesOperationsAssignAccountSIC',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb7 = new WorkflowTriggerBypass__c(Name='salesOperationsSetEUResident',ByPassTrigger__c=false);
            insert new List<WorkflowTriggerBypass__c>{wtb,wtb1,wtb2,wtb3,wtb4,wtb5,wtb6,wtb7};
            
            TriggerControl__c trigcontrl = new TriggerControl__c(name='Entitlement', DisableTrigger__c  = true);
            insert trigcontrl;    
		
        leads.add(new Lead(LastName = 'Lead A', Company = 'Company A', DSCORGPKG__IT_Budget__c = 5000,Status = 'Open',CountryCode = 'US'));
        leads.add(new Lead(LastName = 'Lead B', Company = 'Company B', DSCORGPKG__Company_Phone__c = '1234567890',Status = 'Open',CountryCode = 'US'));
        leads.add(new Lead(LastName = 'Lead C', Company = 'Company C', DSCORGPKG__Other_Phone__c = '9876543210',Status = 'Open',CountryCode = 'US'));

        leads.add(new Lead(LastName = 'Lead D', Company = 'Company D',Status = 'Open',CountryCode = 'US'));

        insert leads;
		


        Test.startTest();
        System.runAs([SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1][0]) {
            LeadDataMigrationBatch batch = new LeadDataMigrationBatch();
            Database.executeBatch(batch);
        }
        Test.stopTest();

        List<Lead> updatedLeads = [
            SELECT IT_Budget__c, Company_Phone__c, Other_Phone__c, DSCORGPKG__IT_Budget__c, 
                   DSCORGPKG__Company_Phone__c, DSCORGPKG__Other_Phone__c 
            FROM Lead
            WHERE LastName IN ('Test Lead LN')
        ];

        for (Lead ld : updatedLeads) {
            if (ld.LastName == 'Lead A') {
                System.assertEquals(ld.DSCORGPKG__IT_Budget__c, ld.IT_Budget__c, 'IT Budget should be copied correctly');
            } else if (ld.LastName == 'Lead B') {
                System.assertEquals(ld.DSCORGPKG__Company_Phone__c, ld.Company_Phone__c, 'Company Phone should be copied correctly');
            } else if (ld.LastName == 'Lead C') {
                System.assertEquals(ld.DSCORGPKG__Other_Phone__c, ld.Other_Phone__c, 'Other Phone should be copied correctly');
            } else if (ld.LastName == 'Lead D') {
                System.assertEquals(null, ld.IT_Budget__c, 'No fields should be updated');
                System.assertEquals(null, ld.Company_Phone__c, 'No fields should be updated');
                System.assertEquals(null, ld.Other_Phone__c, 'No fields should be updated');
            }
        }
    }
}