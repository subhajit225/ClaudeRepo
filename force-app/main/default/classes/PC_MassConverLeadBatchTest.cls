@isTest
public class PC_MassConverLeadBatchTest {
 @isTest static void testMethod1() {
     Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
     Account acct = new Account(Name ='test',RecordTypeId = devRecordTypeId,Type = 'Reseller');
     insert acct;
     
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
            
            
     Lead ld = new Lead(firstname='test12',lastname='l12',company='ascc',email='gjh@gjygj.com',LeadSource='Email',status='Open',L2A_Confidence_Code__c=5,L2A_Account__c=acct.Id,country='United States');
	 insert ld;
     Test.startTest();
     PC_MassConverLeadBatch b = new PC_MassConverLeadBatch();
	 Database.executeBatch(b,100);
     Test.stopTest();
 }
 @isTest static void testMethod2() {
     Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer/Prospect').getRecordTypeId();
     List<Profile> listProfile = [Select Id From Profile Where Name = 'Rubrik Field Sales User'];
        
     List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
     listUser[0].LastName = 'test34';
     insert listUser;
     System.runAs(listUser[0]) {
     Account acct = new Account(Name ='test',RecordTypeId = devRecordTypeId);
     insert acct;
     
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
            
         Lead ld = new Lead(firstname='test12',MQL__c=true,lastname='l12',Last_MQL_Date__c=system.today().addDays(-45),company='ascc',email='gjh@gjygj.com',LeadSource='Email',status='Open',country='United States');
         insert ld;
         ld.ownerId=listUser[0].Id;
         update ld;
         
         Task tLead = new Task(WhoId = ld.id,Subject = 'Test',ActivityDate = system.today().addDays(-45),Status = 'Completed');
         insert tLead;
         Contact c = new Contact(firstname='test2',MQL__c=true,Last_MQL_Date__c=system.today().addDays(-45),lastname='c12',AccountId=acct.Id,email='a@hj.com');
         insert c;    
         c.ownerId=listUser[0].Id;
    	 update c;
         
         Task tContact= new Task(WhoId = c.id,Subject = 'Test',ActivityDate = system.today().addDays(-45),Status = 'Completed');
         insert tContact; 

    }
     Test.startTest();
     LeadUnMQLBatchController b = new LeadUnMQLBatchController();
	 Database.executeBatch(b,100);
     Test.stopTest();

     
 }   
}