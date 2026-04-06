/********************************************************************************************************
* Name              : LeadTriggerHandlerTest
* Purpose           : LeadTriggerHandlerTest is Used for Testing LeadTriggerHandler Class
*********************************************************************************************************/
@isTest
private class LeadTriggerHandlerTest{  
    @isTest static void testLeadTriggerHandlerMethods(){
        User user1 = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = TRUE AND UserRole.PortalType = 'None' LIMIT 1];
        Lead led;
        system.runas(user1){
            WorkflowTriggerBypass__c wtb = new WorkflowTriggerBypass__c(Name='cnsFirstAttemptUpdateLeadStatus',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb1 = new WorkflowTriggerBypass__c(Name='CreateSDRLedMeetingTask',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb2 = new WorkflowTriggerBypass__c(Name='leadReassignOnBusinessUnitChange',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb3 = new WorkflowTriggerBypass__c(Name='updateLastOwnershipUpdateDate',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb4 = new WorkflowTriggerBypass__c(Name='updateOpportunitySource',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb5 = new WorkflowTriggerBypass__c(Name='salesOperationInvokePatchManager',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb6 = new WorkflowTriggerBypass__c(Name='salesOperationsAssignAccountSIC',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb7 = new WorkflowTriggerBypass__c(Name='salesOperationsSetEUResident',ByPassTrigger__c=false);
            insert new List<WorkflowTriggerBypass__c>{wtb,wtb1,wtb2,wtb3,wtb4,wtb5,wtb6,wtb7};

            
            led = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
            led.firstName = 'Test Lead FN';
            led.lastName = 'Test Lead LN';
            led.Status = 'Open';
            led.CountryCode = 'US';
            insert led;
        }

        update led;
        /*
        LeadTriggerHandler leadHandler = new LeadTriggerHandler();
        Lead oldLead = led.clone(true, true, true, true);
        leadHandler.newList = new List<Lead>{led};
        leadHandler.newMap = new Map<Id, Lead>{led.Id => led};
        leadHandler.oldMap = new Map<Id, Lead>{led.Id => oldLead};
        Test.startTest();
            leadHandler.onBeforeInsert(new List<Lead>{led});
            led.Status = 'Marketing Nurture';
            led.Lead_Rejection_Reason__c = 'Contacted/No Interest';
            update led;
            leadHandler.onBeforeUpdate(new Map<Id, Lead>{led.Id => oldLead}, new Map<Id, Lead>{led.Id => led});
        Test.stopTest();*/
    }
    
}