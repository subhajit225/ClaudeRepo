//18-Oct-2024 - Changes from release team to rollback US-0005105
@isTest
public class EventTriggerTest{
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
         Account testAccount = (Account)ShGl_TestFactory.createSObject(new Account(), null);
        testAccount.Name = 'Test SDR Account';
        Id customerRecordTypeId = Schema.sObjectType.Account.getRecordTypeInfosByName().get('Customer/Prospect').getRecordTypeId();
        testAccount.RecordtypeId = customerRecordTypeId;
         Test.startTest();
        insert testAccount;
         Contact con = new Contact(lastName='test1', email='test@test.com',AccountId=testAccount.Id,Contact_Status__c='Open',Meeting_Id__c='tests' , MailingCountry = 'India');
         insert con;
         Lead ld = new Lead(lastname='test2',email='test2@test.com',country='India',Status='Open',Company='Test',Winning_L2A_Account__c=testAccount.Id,Meeting_Id__c='tests');
         insert ld;
         
         
         
         Lead mqlLd = new Lead(lastname='test3',email='test3@test.com',country='India',Status='Open',Company='Test3',Winning_L2A_Account__c=testAccount.Id,Meeting_Id__c='tests',MQL__c =true);
         insert mqlLd;
		Event eveSetUpLead = new Event(Type = 'Inside Sales Led Meeting',Post_Meeting_Status__c = 'No Opportunity sourced',Disqualified_Reason__c='Prospect Not Ready',Subject='call',StartDateTime=system.now(),whoId=mqlLd.Id,DurationInMinutes=30,Created_Through_Quick_Action__c=true);
		insert eveSetUpLead;
         eveSetUpLead.Event_Status__c = 'Completed';
         update eveSetUpLead;
         Event eveSetUpLead2 = new Event(Type = 'Inside Sales Led Meeting',Post_Meeting_Status__c = 'No Opportunity sourced',Disqualified_Reason__c='Prospect Not Ready',Subject='call',StartDateTime=system.now(),whoId=mqlLd.Id,DurationInMinutes=30,Created_Through_Quick_Action__c=true, Event_Status__c = 'Not Started');
		insert eveSetUpLead2;
         
         Contact mqlCon = new Contact(lastName='test11', email='test11@test.com',AccountId=testAccount.Id,Contact_Status__c='Open',Meeting_Id__c='tests', MQL__c = true,MailingCountry = 'India');
         insert mqlCon;
         Event eveSetUpContact = new Event(Type = 'Inside Sales Led Meeting',Post_Meeting_Status__c = 'No Opportunity sourced',Disqualified_Reason__c='Prospect Not Ready',Subject='call',StartDateTime=system.now(),whoId=mqlCon.Id,DurationInMinutes=60,Created_Through_Quick_Action__c=true);
		insert eveSetUpContact;
         eveSetUpContact.Event_Status__c = 'Completed';
         update eveSetUpContact;
         Event eveSetUpContact2 = new Event(Type = 'Inside Sales Led Meeting',Post_Meeting_Status__c = 'No Opportunity sourced',Disqualified_Reason__c='Prospect Not Ready',Subject='call',StartDateTime=system.now(),whoId=mqlCon.Id,DurationInMinutes=60,Created_Through_Quick_Action__c=true,Event_Status__c = 'Not Started');
		insert eveSetUpContact2;
         Test.stopTest();
     }
    @isTest
    public static void testMethod1(){
        Contact con = [select Id from Contact WHERE lastName='test1'];
        Lead ld = [select Id from Lead WHERE lastname='test2'];
        Event eve1 = new Event(Type = 'Field Sales Led Meeting',Subject='call',StartDateTime=system.now().addDays(-65),whoId=ld.Id,DurationInMinutes=30,Created_Through_Quick_Action__c=true);
        Event eve2 = new Event(Type = 'Marketing Generated Meeting',Subject='call',StartDateTime=system.now().addDays(-65),whoId=con.Id,DurationInMinutes=30);
        Event eve3 = new Event(Type = 'IAE Led Meeting',Subject='call',StartDateTime=system.now(),whoId=ld.Id,DurationInMinutes=30);
        Event eve4 = new Event(Type = 'SaaS Expansion Meeting',Subject='call',StartDateTime=system.now(),whoId=ld.Id,DurationInMinutes=30);
        Event eve5 = new Event(Type = 'Field Sales Led Meeting',Subject='call',StartDateTime=system.now(),whoId=con.Id,DurationInMinutes=30,Created_Through_Quick_Action__c=true);
        Event eve6 = new Event(Type = 'Field Sales Led Meeting',Subject='call',StartDateTime=system.now().addDays(-65),whoId=con.Id,DurationInMinutes=30,Created_Through_Quick_Action__c=true);
         Event eve7 = new Event(Type = 'Field Sales Led Meeting',Subject='call',StartDateTime=system.now().addDays(-65),whoId=con.Id,DurationInMinutes=30,Event_Status__c ='Not Started',Created_Through_Quick_Action__c=true);
         Event eve8 = new Event(Type = 'Field Sales Led Meeting',Subject='call',StartDateTime=system.now().addDays(-65),whoId=ld.Id,DurationInMinutes=30,Created_Through_Quick_Action__c=true);
         Event eve9 = new Event(Type = 'Field Sales Led Meeting',Subject='call',StartDateTime=system.now().addDays(-65),whoId=con.Id,DurationInMinutes=30,Event_Status__c ='Not Started',Created_Through_Quick_Action__c=true);
       
        List<Event> eveList = new List<Event>();
        eveList.add(eve1);
        eveList.add(eve2);
        eveList.add(eve3);
        eveList.add(eve4);
        eveList.add(eve5);
        eveList.add(eve6);
        eveList.add(eve7);
        Test.startTest();
        System.runAs([SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1][0]) {
            insert eveList;
            // insert eve1;
            //  insert eve2;
            // insert eve3;
            // insert eve4;
            // insert eve5;
            // insert eve6;
            // insert eve7;
        // insert eve8;
        // insert eve9;
            
            Lead UpdateLead = new Lead();
            
            UpdateLead.Id= ld.Id;
            UpdateLead.Meeting_Id__c =eve4.Id;
            
            Update UpdateLead;
            
            delete eve4;
            delete eve5;
        // delete eve8;
            
        Event eveUpdate1 = new Event();
            Event eveUpdate2 = new Event();
            Event eveUpdate3 = new Event();
            Event eveUpdate4 = new Event();
            Event eveUpdate5 = new Event();
            Event eveUpdate7 = new Event();
            
            eveUpdate1.id=eve1.id;
            //MKT24-694    
            //eveUpdate1.Did_meeting_happen__c='Yes';
            eveUpdate1.Post_Meeting_Status__c='No Opportunity Sourced';
            eveUpdate1.Disqualified_Reason__c ='Prospect Not Ready';
            update eveUpdate1;
            eveUpdate2.id=eve2.id;
            //MKT24-694
            //eveUpdate2.Did_meeting_happen__c='Yes';
            eveUpdate2.Post_Meeting_Status__c='Opportunity Sourced';
            //eveUpdate2.What_is_the_next_step__c ='Sizing discussion';
            //eveUpdate2.Next_Steps__c ='Meeting with other stakeholders';
            update eveUpdate2;
            
        
            eveUpdate3.id=eve3.id;
            //MKT24-694
            //eveUpdate3.Did_meeting_happen__c='Yes';
            eveUpdate3.Post_Meeting_Status__c='Opportunity Sourced';
            //eveUpdate3.What_is_the_next_step__c ='Sizing discussion';
        // eveUpdate3.Next_Steps__c ='Meeting with other stakeholders';
            update eveUpdate3;
            
            eveUpdate7.id=eve7.id;
            eveUpdate7.Post_Meeting_Status__c='Opportunity Sourced';
            //MKT24-1078
            //eveUpdate7.MeetingCancelled__c=true; 
            
        
            
            update eveUpdate7;
            
            eveUpdate5.id=eve6.id;
            //MKT24-694
            //eveUpdate5.Did_meeting_happen__c='Yes';
            eveUpdate5.Post_Meeting_Status__c='Opportunity Sourced';
            //eveUpdate5.What_is_the_next_step__c ='Sizing discussion';
        // eveUpdate5.Next_Steps__c ='Meeting with other stakeholders';
            eveUpdate5.NBM_Complete__c='Yes';
            //MKT24-1078
            //eveUpdate5.MeetingCancelled__c=true;
            List<Event> oldEvent = new List<Event>();
            oldEvent.add(eve1);
            oldEvent.add(eve7);
            //EventTriggerHandler.updateEventRecordNBMComplete(oldEvent,true);
            /*
            eve4.id=eve4.id;
            eve4.Did_meeting_happen__c='Yes';
            eve4.Post_Meeting_Status__c='Opportunity Sourced';
            eve5.id=eve5.id;
            eve5.Did_meeting_happen__c='Yes';
            eve5.Post_Meeting_Status__c='Opportunity Sourced';
            eve5.NBM_Complete__c='Yes';
            
            
            update eve2;
            update eve3;
            update eve5;
            update eve4;*/
            Assert.areEqual('Opportunity Sourced',eveUpdate5.Post_Meeting_Status__c);
        }
        
        Test.stopTest();
        
    }
    
    @isTest
    public static void testMethod2(){
        Account testAccount = [Select id FROM Account LIMIT 1];
        Contact con = new Contact(lastName='test123', email='test123@test.com',AccountId=testAccount.Id,Contact_Status__c='Open',Meeting_Id__c='tests', MailingCountry = 'India');
        
        User userObj = [SELECT Id FROM User WHERE Profile.Name = 'Rubrik Marketing User' AND isActive = TRUE LIMIT 1];
        Event eve2;
        System.runAs(userObj){
            insert con;
            eve2 = new Event(Subject='call',StartDateTime=system.now().addDays(-65),whoId=con.Id,DurationInMinutes=30);
            insert eve2;
            Assert.areEqual('call',eve2.Subject);
        }
    }
    @isTest
    public static void testMethod3(){
        Lead ld = [select Id from Lead WHERE lastname='test2'];
        Event eve8 = new Event(Type = 'Field Sales Led Meeting',Subject='meeting',StartDateTime=system.now().addDays(-65),whoId=ld.Id,DurationInMinutes=30,Created_Through_Quick_Action__c=true);
        System.runAs([SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1][0]) {
            insert eve8;
            delete eve8;
            List<Event> getEve = [SELECT Id from Event where Subject = 'meeting' LIMIT 1];
            Assert.areEqual(true,getEve.isEmpty());
        }
    }
     @isTest
    public static void testMethod4(){
        Contact con = [select Id from Contact WHERE lastName='test1'];
        Event eve8 = new Event(Type = 'Inside Sales Led Meeting',Subject='call',StartDateTime=system.now().addDays(-65),whoId=con.Id,DurationInMinutes=30,Created_Through_Quick_Action__c=true);
        System.runAs([SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1][0]) {
            insert eve8;
            eve8.Post_Meeting_Status__c ='Meeting Cancelled';
            eve8.Event_Status__c = 'Not Started';
            update eve8;
        }
        Assert.areEqual('call',eve8.Subject);
    }
     @isTest
    public static void testMethod5(){
        Lead ld = [select Id from Lead WHERE lastname='test2'];
        Event eve8 = new Event(Type = 'Field Sales Led Meeting',Post_Meeting_Status__c = 'Opportunity sourced',Subject='call',StartDateTime=system.now().addDays(-65),whoId=ld.Id,DurationInMinutes=30,Created_Through_Quick_Action__c=true);
        Test.startTest();
        System.runAs([SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1][0]) {
            insert eve8;
            eve8.Post_Meeting_Status__c ='Meeting Cancelled';
            update eve8;
        }
        Assert.areEqual('call',eve8.Subject);
        Test.stopTest();
    }
    @isTest
    public static void testMethod6(){
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test SDR Account'];
        Lead ld = new Lead(lastname='test6-2',email='test6-2@test.com',country='India',Status='Open',Company='Test',Winning_L2A_Account__c=testAccount.Id,Meeting_Id__c='tests',MQL__c=true);
        System.runAs([SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1][0]) {
            insert ld;
            ld.Last_MQL_Date__c = System.today().addDays(-7);
            update ld;
            
            Test.StartTest();
            Event eve9 = new Event(Type = 'Inside Sales Led Meeting',Post_Meeting_Status__c = 'No Opportunity sourced',Disqualified_Reason__c='Prospect Not Ready',Subject='call',StartDateTime=system.now(),whoId=ld.Id,DurationInMinutes=30,Created_Through_Quick_Action__c=true);
            insert eve9;
            eve9.Post_Meeting_Status__c ='Opportunity sourced';
            eve9.Event_Status__c = 'Completed';
            update eve9;
            Assert.areEqual('call',eve9.Subject);
            
            Event eve10 = new Event(Type = 'Inside Sales Led Meeting',Post_Meeting_Status__c = 'No Opportunity sourced',Disqualified_Reason__c='Prospect Not Ready',Subject='call',StartDateTime=system.now(),whoId=ld.Id,DurationInMinutes=60,Created_Through_Quick_Action__c=true);
            insert eve10;
            eve10.Post_Meeting_Status__c ='Opportunity sourced';
            update eve10;
            Assert.areEqual('call',eve10.Subject);
            
            Event eve11 = new Event(Type = 'Inside Sales Led Meeting',Post_Meeting_Status__c = 'No Opportunity sourced',Disqualified_Reason__c='Prospect Not Ready',Subject='call',StartDateTime=system.now(),whoId=ld.Id,DurationInMinutes=60,Created_Through_Quick_Action__c=true);
            insert eve11;
            eve11.Post_Meeting_Status__c ='Opportunity sourced';
            eve11.Event_Status__c = 'Completed';
            update eve11;
            Assert.areEqual('call',eve11.Subject);
        }
        Test.StopTest();
    }
    @isTest
    public static void testMethod7(){
		Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test SDR Account'];
        Contact con = new Contact(lastName='test12', email='test12@test12.com',AccountId=testAccount.Id,Contact_Status__c='Open',Meeting_Id__c='tests', MQL__c = true, MailingCountry = 'India');
        System.runAs([SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1][0]) {
            insert con;
            con.Last_MQL_Date__c = System.today().addDays(-7);
            update con;        
            
            Test.startTest();
            Event eve12 = new Event(Type = 'Inside Sales Led Meeting',Post_Meeting_Status__c = 'No Opportunity sourced',Disqualified_Reason__c='Prospect Not Ready',Subject='call',StartDateTime=system.now(),whoId=con.Id,DurationInMinutes=30,Created_Through_Quick_Action__c=true);
            insert eve12;
            eve12.Post_Meeting_Status__c ='Opportunity sourced';
            eve12.Event_Status__c = 'Completed';
            update eve12;
            Assert.areEqual('call',eve12.Subject);
            
            Event eve13 = new Event(Type = 'Inside Sales Led Meeting',Post_Meeting_Status__c = 'No Opportunity sourced',Disqualified_Reason__c='Prospect Not Ready',Subject='call',StartDateTime=system.now(),whoId=con.Id,DurationInMinutes=60,Created_Through_Quick_Action__c=true);
            insert eve13;
            eve13.Post_Meeting_Status__c ='Opportunity sourced';
            update eve13;
            Assert.areEqual('call',eve13.Subject);
            
            Event eve14 = new Event(Type = 'Inside Sales Led Meeting',Post_Meeting_Status__c = 'No Opportunity sourced',Disqualified_Reason__c='Prospect Not Ready',Subject='call',StartDateTime=system.now(),whoId=con.Id,DurationInMinutes=60,Created_Through_Quick_Action__c=true);
            insert eve14;
            eve14.Post_Meeting_Status__c ='Opportunity sourced';
            eve14.Event_Status__c = 'Completed';
            update eve14;
            Assert.areEqual('call',eve14.Subject);
        }
        Test.stopTest();
    }
    @isTest
    public static void testMethod8(){
        Lead ld = [select Id from Lead WHERE lastname='test3'];        
        Test.startTest();
        Event eve15 = new Event(Type = 'Inside Sales Led Meeting',Post_Meeting_Status__c = 'No Opportunity sourced',Disqualified_Reason__c='Prospect Not Ready',Subject='call',StartDateTime=system.now(),whoId=ld.Id,DurationInMinutes=60,Created_Through_Quick_Action__c=true);
        System.runAs([SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1][0]) {
            insert eve15;
            eve15.Post_Meeting_Status__c ='Completed';
            update eve15;
            Assert.areEqual('call',eve15.Subject);
        }
        Test.stopTest();
    }
    @isTest
    public static void testMethod9(){
		//User user1 = [SELECT Id,Name FROM User WHERE Name = 'Outreach Integration User' AND isActive = TRUE  LIMIT 1];
        Contact con = [select Id from Contact WHERE lastName='test11'];
        Test.startTest();
        Event eve16 = new Event(Type = 'Inside Sales Led Meeting',Post_Meeting_Status__c = 'No Opportunity sourced',Disqualified_Reason__c='Prospect Not Ready',Subject='call',StartDateTime=system.now(),whoId=con.Id,DurationInMinutes=60,Created_Through_Quick_Action__c=true);
        System.runAs([SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1][0]) {
            insert eve16;
            eve16.Post_Meeting_Status__c ='Completed';
            //eve16.OwnerId = user1.Id;
            update eve16;
            Assert.areEqual('call',eve16.Subject);
        }
        Test.stopTest();
    }

	@isTest
    public static void testMethod10(){
		User user1 = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = TRUE LIMIT 1];
        Contact con = [select Id from Contact WHERE lastName='test11'];
        Test.startTest();
        Event eve16 = new Event(Type = 'Inside Sales Led Meeting',Post_Meeting_Status__c = 'No Opportunity sourced',Disqualified_Reason__c='Prospect Not Ready',Subject='call',StartDateTime=system.now(),whoId=con.Id,DurationInMinutes=60,Created_Through_Quick_Action__c=true);
        System.runAs([SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1][0]) {
            insert eve16;
            eve16.Post_Meeting_Status__c = 'Meeting Cancelled';
            eve16.MeetingCancelled__c = TRUE;
            eve16.SOPs_Selected_Owner__c = user1.Id;
            update eve16;
            eve16 = [SELECT Id ,Post_Meeting_Status__c FROM EVENT WHERE Id=:eve16.Id];
            Assert.areEqual('Meeting Cancelled',eve16.Post_Meeting_Status__c);
        }
        Test.stopTest();
    }
}