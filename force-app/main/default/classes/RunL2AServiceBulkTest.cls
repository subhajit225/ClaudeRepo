@isTest
public class RunL2AServiceBulkTest implements HttpCalloutMock{
    @testSetup static void testDataSetup(){
        User userTest = [SELECT Id From User Where Profile.Name ='System Administrator' and userRoleId != null and isActive = true LIMIT 1];        
        
        system.runas(userTest){
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
                
            Lead led = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
            led.firstName = 'Test Lead FN1';
            led.lastName = 'Test Lead LN1';
            led.Status = 'Open';
            led.Salesloft_Cadence_Most_Recent__c='MM-';
            led.CountryCode = 'IN';
            led.Deal_Registration__c = false;
            led.Run_L2A__c = true;
            insert led;    
        }
    }
    
    @isTest static void testRunL2AService(){
        
        Test.setMock(HttpCalloutMock.class, new RunL2AServiceBulkTest());
        
        Lead led = [SELECT Id From Lead LIMIT 1];
        
        List<id> LeadId=new List<id>();
        LeadId.add(led.id);
        
        List<Boolean> runPatchManager=new List<Boolean>{true};
            
        Test.startTest();
        Id jobId = System.enqueueJob(new runL2AServiceBulk(LeadId, runPatchManager));
        Test.stopTest();
        
        Assert.areNotEqual(null, jobId);
    }
    public HTTPResponse respond(HTTPRequest req) {
        String fullJson ='{"statusDescription":"Success","statusDescription":"Success","statusCode":"200","status":null,"l2aAccount":[{"matchStatus":"Not Matched","matchConfidence":"3","matchCriteria":"","accountId":"","sourceId":"00Q4000001IrbyEEAR"}]}';       
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'text/json');
        res.setBody(fullJson);
        res.setStatusCode(200);
        return res;
    }
   
}