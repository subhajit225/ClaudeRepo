@isTest
public class EventBatchSetMeetingCancelTest{
     @testSetup static void createTestData(){
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
         }
         Contact con = new Contact(lastName='test1', email='test@test.com');
         insert con;
         Lead ld = new Lead(lastname='test2',email='test2@test.com',country='India',Status='Open',Company='Test');
         insert ld;
     }
     
    @isTest
    public static void testMethod1(){
        Contact con = [select Id from Contact];
        Lead ld = [select Id from Lead];
        
        Event eve6 = new Event(Type = 'inside sales led meeting',Subject='call',activityDateTime=system.now().addDays(-65),activitydate=system.today().addDays(-65),whoId=con.Id,DurationInMinutes=30);
         Event eve7 = new Event(Type = 'inside sales led meeting',Subject='call',activityDateTime=system.now().addDays(-65),activitydate=system.today().addDays(-65),whoId=ld.Id,DurationInMinutes=30);
       
        List<Event> eveList = new List<Event>(); 
        //eveList.add(eve1);
       // eveList.add(eve2);
       
        insert eve6;
        insert eve7;
        
    
      
         Event eveUpdate5 = new Event();
        Event eveUpdate7 = new Event();
         eveUpdate7.id=eve7.id;
        //MKT24-1078
        //eveUpdate7.MeetingCancelled__c=true; 
        
        update eveUpdate7;
        
         eveUpdate5.id=eve6.id;
      //  eveUpdate5.What_is_the_next_step__c ='Sizing discussion';
        //eveUpdate5.Next_Steps__c ='Meeting with other stakeholders';
      //  eveUpdate5.Did_this_account_have_budget__c='Budget allocated within 12 months';
       // eveUpdate5.NBM_Complete__c='Yes';
        //MKT24-1078
        //eveUpdate5.MeetingCancelled__c=false;
        
        /*
        eve4.id=eve4.id;
        eve4.Post_Meeting_Status__c='Productive - immediate opportunity';
        eve5.id=eve5.id;
        eve5.Post_Meeting_Status__c='Productive - immediate opportunity';
        eve5.NBM_Complete__c='Yes';
        
        
        update eve2;
         update eve3;
         update eve5;
         update eve4;*/
		 
		 
		   Test.startTest();
            Database.executeBatch(new EventBatchSetMeetingCancel());
           Test.stopTest();
        
        
        
    }
    @isTest
    public static void testMethodLeadUnMQLBatch(){
         User userObj = [SELECT Id From User where Profile.Name = 'Rubrik Field Sales User' and IsActive = true LIMIT 1];
        
        Lead ld1 = new Lead(lastname='test2',email='test3@test.com',country='India',Status='Open',Company='Test',Deal_Registration__c = false,MQL__c =true,OwnerId = userObj.Id,MeetingDate__c = Date.today().addDays(-65),Last_MQL_Date__c =Date.today().addDays(-65));
        insert ld1;
        
        Test.startTest();
            Database.executeBatch(new LeadUnMQLBatchController());
           Test.stopTest();
        Assert.areEqual(true,ld1.MQL__c);
    }
    @isTest
    public static void testMethodLeadMatchStatus1(){
        Lead ld = [SELECT Id,status,MQL__c from Lead LIMIT 1];
        ld.status = 'Open';
        ld.MQL__c = false;
        update ld;
        
        Test.startTest();
            Database.executeBatch(new matchStatusForOldLeadsBatch());
           Test.stopTest();
        Assert.areEqual('Open',ld.status);
    }
    @isTest
    public static void testMethodLeadMatchStatus2(){
        Lead ld = [SELECT Id,status,MQL__c from Lead LIMIT 1];
        ld.status = 'RAW';
        ld.MQL__c = true;
        update ld;
        
        Test.startTest();
            Database.executeBatch(new matchStatusForOldLeadsBatch());
           Test.stopTest();
        Assert.areEqual('RAW',ld.status);
    }
    
    @isTest static void testScheduler(){
        Test.startTest();
            String sch = '0 0 23 * * ?'; 
            system.schedule('Test Lead Inactivation Check', sch, new  EventBatchSetMeetingCancel()); 
        Test.stopTest(); 
    }
}