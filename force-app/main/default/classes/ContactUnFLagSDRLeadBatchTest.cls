@isTest
public with sharing class ContactUnFLagSDRLeadBatchTest {
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

            
            Contact con = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
            con.firstName = 'Test Lead FN';
            con.lastName = 'Test Lead LN';
            con.Contact_Status__c = 'Open';
            con.SDRLed__c = True;
            
            con.MeetingDate__c = Date.today()-61;
            insert con;

            
        }
    }

    @isTest static void testBatch(){
        Test.startTest();
            Database.executeBatch(new ContactUnFLagSDRLeadBatch());
        Test.stopTest();
    }
    @isTest static void testBatchContactUnMql(){
        User userObj = [SELECT Id From User where Profile.Name LIKE '%Rubrik Field Sales User%' and IsActive = true LIMIT 1];
        Account act = new Account(Name = 'Test Company',Website='www.test-rubrik.com');
        insert act;
        Contact con = new Contact();
        con.firstName = 'Test Lead FN';
        con.lastName = 'Test Lead LN';
        con.Contact_Status__c = 'Open';
        con.SDRLed__c = True;
        con.AccountId = act.Id;
        con.MeetingDate__c = Date.today()-61;
        con.Last_MQL_Date__c = Date.today().addDays(-45);
        con.SAL__c = true;
        con.Last_SAL_Date__c = Date.today().addDays(-45);
        con.MQL__c = true;
        System.runAs(userObj){
            insert con;
        }
        
        Test.startTest();
            Database.executeBatch(new ContactUnMQLBatchController());
        Test.stopTest();
        Assert.areEqual(true,con.MQL__c);
    }
    

    @isTest static void testScheduler(){
        Test.startTest();
            String sch = '0 0 23 * * ?'; 
            system.schedule('Test Lead Inactivation Check', sch, new ContactUnFLagSDRLeadBatch()); 
        Test.stopTest(); 
    }
    
}