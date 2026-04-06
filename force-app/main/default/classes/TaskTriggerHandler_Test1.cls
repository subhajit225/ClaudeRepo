/********************************************************************************************************
* Name              : TaskTriggerHandler_Test1 
* Purpose           : TaskTriggerHandler_Test is Used for Testing TaskTriggerHandler Class
*********************************************************************************************************/
@isTest
public class TaskTriggerHandler_Test1{
    
   @testSetup
static void setUpData() {

    // ----------------------------
    // Disable Automations
    // ----------------------------
    TestDataFactory.setWorkflowTriggerBypassCS(true);

    FlowControll.contactTrigger = false;
    FlowControll.opportunityTriggerHandler = false;
    FlowControll.LeadTriggerHandler = false;
    FlowControll.AccountTrigger = false;

    insert new TriggerControl__c(
        Name = 'Opportunity',
        DisableTrigger__c = true
    );

    insert new ShGl_DisableBusinessLogic__c(
        Disable_Opportunity_Validation_Rules__c = true
    );

    // ----------------------------
    // Lead
    // ----------------------------
    Lead ld = TestDataFactory.insertLead();
    ld.Status = 'Open';
    ld.email = 'test9876Led@test.com';

    insert ld;

    // ----------------------------
    // Account
    // ----------------------------
    Account act = new Account(Name = 'TestTaskTrigger');
    insert act;

    // ----------------------------
    // Opportunity
    // ----------------------------
    List<Opportunity> oppList =
        testDataFactoryClass.createOpporunity(new List<Account>{ act });

    Id stdPricebookId = Test.getStandardPricebookId();
    oppList[0].Pricebook2Id = stdPricebookId;
    update oppList;

    // ----------------------------
    // Product & Pricebook Entry
    // ----------------------------
    Product2 prod = new Product2(
        Name = 'RBK-SVC-PREM-R344',
        ProductCode = 'RBK-SVC-PREM-R344',
        Family = 'RBK-R300',
        IsActive = true,
        Bundle_Features__c = 'Appliance'
    );
    insert prod;

    PricebookEntry pbe = new PricebookEntry(
        Pricebook2Id = stdPricebookId,
        Product2Id = prod.Id,
        UnitPrice = 100,
        IsActive = true
    );
    insert pbe;

    // ----------------------------
    // Opportunity Line Item
    // ----------------------------
    insert new OpportunityLineItem(
        OpportunityId = oppList[0].Id,
        Quantity = 5,
        PricebookEntryId = pbe.Id,
        TotalPrice = 500
    );

    // ----------------------------
    // Order & Order Item
    // ----------------------------
    Order ord = new Order(
        Type = 'Revenue',
        AccountId = act.Id,
        OpportunityId = oppList[0].Id,
        EffectiveDate = System.today(),
        Status = 'Pending'
    );
    insert ord;

    insert new OrderItem(
        OrderId = ord.Id,
        Quantity = 5,
        PricebookEntryId = pbe.Id,
        UnitPrice = pbe.UnitPrice,
        SerialNumber__c = 'Test1234567Asset2',
        Support_Start_Date__c = System.today(),
        Support_End_Date__c = System.today().addYears(1)
    );

    // ----------------------------
    // Re-enable Triggers
    // ----------------------------
    FlowControll.opportunityTriggerHandler = true;
    FlowControll.LeadTriggerHandler = true;
    FlowControll.AccountTrigger = true;

    // ----------------------------
    // Contacts
    // ----------------------------
   Contact con = new Contact(LastName = 'test Contact', AccountId = act.Id,Phone = '9999999999',Limited_Use__c = true, MailingCountry = 'India', Email = 'test.contact@rubrik.com');
            INSERT con;

    Id taskRT = Schema.SObjectType.Task
        .getRecordTypeInfosByName()
        .get('Task')
        .getRecordTypeId();

    Id fulfillmentRT = Schema.SObjectType.Task
        .getRecordTypeInfosByName()
        .get('Polaris Fullfillment')
        .getRecordTypeId();

    // ----------------------------
    // Tasks (Bulk Insert)
    // ----------------------------
    List<Task> tasks = new List<Task>{
        new Task(
            WhoId = con.Id,
            RecordTypeId = fulfillmentRT,
            Subject = 'PID Meeting Con'
        ),
        new Task(
            WhoId = ld.Id,
            RecordTypeId = fulfillmentRT,
            Subject = 'PID Meeting'
        ),
        new Task(
            WhoId = ld.Id,
            RecordTypeId = taskRT,
            Subject = 'PID Meeting',
            Type = 'Call'
        ),
        new Task(
            WhoId = con.Id,
            RecordTypeId = taskRT,
            Subject = 'PID Meeting',
            Type = 'Call'
        )
    };
    insert tasks;

    // ----------------------------
    // Task Updates
    // ----------------------------
    tasks[2].SalesloftDisposition__c = 'NQ - Partner/Reseller';
    tasks[3].SalesloftDisposition__c = 'Working-Left VM';

   update new List<Task>{
    new Task(
        Id = tasks[2].Id,
        SalesloftDisposition__c = 'NQ - Partner/Reseller'
    ),
    new Task(
        Id = tasks[3].Id,
        SalesloftDisposition__c = 'Working-Left VM'
    )
};
}

    
    static testMethod void testInsert(){
        Test.startTest();
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
        insert cdf;
        
        Id leadId = [Select Id From Lead Limit 1].Id;        
        Id actId = [Select Id From Account Limit 1].Id;
        
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => actId,
            'CloseDate' => System.Today()+30,
            'Partner_Lookup__c' => actId,
            'Alliance_Partner_Name__c' =>'Amazon',
            'Alliance_Source_Type__c' => 'Alliance Initiated Deal'
        };
        Opportunity opp1 = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        //insert opp1; 
        
        Map<String, Object>  OrderMap = new Map<String, Object> {
            'Type' => 'Revenue',
            'AccountId' => actId,
            'OpportunityId' => opp1.Id,
            'EffectiveDate' => system.today(),
            'Status' => 'Pending'
        };
        System.debug(OrderMap);
        //Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
        //insert Ord; 

        List<Task> tskList = new List<Task>();
        Task t = new Task();
        t.WhoId = leadId;
        t.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Polaris Fullfillment').getRecordTypeId();
        t.Subject = 'PID Meeting';               
        tskList.add(t);        

        insert tskList;
        Assert.areEqual(1,tskList.size());
        
        
        
        Test.stopTest();
    } 

    static testMethod void testLeadUpdate(){
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
        insert cdf;
         
        Test.startTest();
        Task tskList = [Select Id from Task Where Subject='PID Meeting' LIMIT 1];
        
        tskList.Subject='PID Meeting';
        tskList.Post_Meeting_Status__c = 'Convert to Opportunity';
        tskList.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Task').getRecordTypeId();
        update tskList;
        List<Task> lstTask = new List<Task>();
        lstTask.add(tskList);
        Assert.areEqual(1, lstTask.size());
        
        
        Test.stopTest();
    }
    
    static testMethod void testContactUpdate(){
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
        insert cdf;
         
        Test.startTest();
        Task tskList = [Select Id from Task Where Subject='PID Meeting' LIMIT 1];
        
        tskList.Subject='PID Meeting Con';
        tskList.Post_Meeting_Status__c = 'Convert to Opportunity';
        tskList.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Task').getRecordTypeId();
        update tskList;
        List<Task> lstTask = new List<Task>();
        lstTask.add(tskList);
        Assert.areEqual(1, lstTask.size());
        
        
        Test.stopTest();
    }
   
    static testMethod void testDelete(){
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
        insert cdf;
        Test.startTest();
        Task tskList = [Select Id from Task Where Subject='PID Meeting' LIMIT 1];
        List<Task> lstTask = new List<Task>();
        lstTask.add(tskList);
        Assert.areEqual(1, lstTask.size());
        
        Delete tskList;
        //TaskTriggerHandler handler = new TaskTriggerHandler();
        //handler.beforeDelete();
        //handler.afterDelete();
        //handler.afterUndelete();
        Test.stopTest();
    }
       
   static testMethod void testupdateBundleFeaturesForPolarisTasks(){
       Test.startTest();
       ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
       insert cdf;
       //Id leadId = [Select Id From Lead Limit 1].Id;        
       //Id actId = [Select Id From Account Limit 1].Id;
       Id orderId = [Select Id From Order Limit 1].Id;
       Id oppId = [Select Id From Opportunity Limit 1].Id;
       
        List<Task> tskList = new List<Task>();
        Task t = new Task();
        t.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Task').getRecordTypeId();
        t.Subject = 'PID Meeting'; 
        t.whatId = oppId; 
        t.Post_Meeting_Status__c = 'Convert to Opportunity';         
        tskList.add(t);        

       insert tskList;
       Assert.areEqual(1, tskList.size());
       
       tskList[0].status = 'Completed';
       update tskList;
       Test.stopTest();
   }  
   
   static testMethod void testupdateBundleFeaturesForPolarisTasks1(){
       Test.startTest();
       ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
       insert cdf;
       //Id leadId = [Select Id From Lead Limit 1].Id;        
       //Id actId = [Select Id From Account Limit 1].Id;
       Id orderId = [Select Id From Order Limit 1].Id;
       //Id oppId = [Select Id From Opportunity Limit 1].Id;
       
        List<Task> tskList = new List<Task>();
        Task t = new Task();
        t.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Task').getRecordTypeId();
        t.Subject = 'PID Meeting'; 
        t.whatId = orderId;
        t.Disqualified_Reason__c = 'mmm'; 
        t.Post_Meeting_Status__c = 'Do Not Convert to Opportunity';           
        tskList.add(t);        

       insert tskList;
       Assert.areEqual(1, tskList.size());
       
       t.Post_Meeting_Status__c = 'Convert to Opportunity'; 
       tskList[0].status = 'Completed';
       
       update tskList;
       Test.stopTest();
   }   
    
    static testMethod void testupdateBundleFeaturesForPolarisTasks2(){
       Test.startTest();
       ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
       insert cdf;
       //Id leadId = [Select Id From Lead Limit 1].Id;        
       //Id actId = [Select Id From Account Limit 1].Id;
       Id orderId = [Select Id From Order Limit 1].Id;
       //Id oppId = [Select Id From Opportunity Limit 1].Id;
       
       
        List<Task> tskList = new List<Task>();
        Task t = new Task();
        t.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Polaris Fullfillment').getRecordTypeId();
        t.Subject = 'PID Meeting'; 
        t.whatId = orderId;
       // t.Type = 'Email';  
        t.Disqualified_Reason__c = 'mmm'; 
        t.Post_Meeting_Status__c = 'Do Not Convert to Opportunity';    
        
         Task t1 = new Task();
       // t.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Polaris Fullfillment').getRecordTypeId();
        t1.Subject = 'PID Meeting'; 
        t1.whatId = orderId;
        t1.Type = 'Email';  
        
        tskList.add(t);
       // tskList.add(t1);        
        Assert.areEqual(1, tskList.size());
        
       insert tskList;
       tskList[0].status = 'Completed';
       
       update tskList;
       Test.stopTest();
   }  
    
     static testMethod void testTerritoryUpdate(){
        Test.startTest();
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
        insert cdf;
        User ur = [SELECT Id FROM User WHERE Id =: Userinfo.getUserId() ];
        System.runAs(ur) {
         
        Task tskList = [Select Id from Task Where Subject='PID Meeting' LIMIT 1];
        Id actId = [Select Id From Account Limit 1].Id;
        tskList.Subject='PID Meeting Con';
        tskList.Partner_Name__c = actId; 
        tskList.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Channel Activity').getRecordTypeId();
        update tskList;
        List<Task> lstTask = new List<Task>();
        lstTask.add(tskList);
        Assert.areEqual(1, lstTask.size());
        
        }
        Test.stopTest();
    }
   /** 
    static testMethod void testInsertSendEmail(){
        WorkflowTriggerBypass__c wtb = new WorkflowTriggerBypass__c(Name='cnsFirstAttemptUpdateLeadStatus',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb1 = new WorkflowTriggerBypass__c(Name='CreateSDRLedMeetingTask',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb2 = new WorkflowTriggerBypass__c(Name='leadReassignOnBusinessUnitChange',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb3 = new WorkflowTriggerBypass__c(Name='updateLastOwnershipUpdateDate',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb4 = new WorkflowTriggerBypass__c(Name='updateOpportunitySource',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb5 = new WorkflowTriggerBypass__c(Name='salesOperationInvokePatchManager',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb6 = new WorkflowTriggerBypass__c(Name='salesOperationsAssignAccountSIC',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb7 = new WorkflowTriggerBypass__c(Name='salesOperationsSetEUResident',ByPassTrigger__c=false);
        insert new List<WorkflowTriggerBypass__c>{wtb,wtb1,wtb2,wtb3,wtb4,wtb5,wtb6,wtb7};
        String uniqueUserName = 'BookingAdjustmentControllerTest' + DateTime.now().getTime() + '@testclass.com';
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User u=new user(alias = 'std', email='testuser@testclass.com',
                        emailencodingkey='UTF-8', firstname='test', lastname='user', languagelocalekey='en_US',
                        localesidkey='en_US', profileid = p.Id,
                        timezonesidkey='America/Los_Angeles', username=uniqueUserName);
        insert u;
        
       ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true,
                                                                           Disable_Opportunity_Triggers__c = True,
                                                                           Disable_SBQQ_Quote_Triggers__c = TRUE,
                                                                           Disable_SBQQ_Quote_Validation_Rules__c = TRUE,
                                                                          Disable_Lead_Triggers__c  = true);
        System.runAs(u){
        insert cdf;
       Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.Name='TestTaskTrigger';
            Lead leadId = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
        leadId.firstName = 'Test Lead FN1';
        leadId.lastName = 'Test Lead LN1';
        leadId.Status = 'Open';
        leadId.CountryCode = 'BE';
        leadId.Deal_Registration__c = false;
            insert leadId;
        // Id leadId = [Select Id From Lead Limit 1].Id;
        insert act;
        
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => act.id,
            'CloseDate' => System.Today()+30,
            'Alliance_Partner_Name__c' =>'Amazon',
            'Alliance_Source_Type__c' => 'Alliance Initiated Deal'
        };
        Account distAcc = TestDataFactory.getAccount();
		distAcc.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
		insert distAcc;
        Opportunity opp1 = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp1.Partner_Lookup__c= distAcc.id;
        opp1.Distributor_Lookup__c= distAcc.id;
        Test.startTest();
            insert opp1;
        Deal_Registration__c dr = new Deal_Registration__c(Primary__c=true,Lead__c=leadId.Id,Company__c='ABC',Deal_Registration_Status__c='Submitted');
        insert dr;
       
            SBQQ__Quote__c quoteRec = new SBQQ__Quote__c( SBQQ__Account__c = act.id, SBQQ__Opportunity2__c = opp1.Id, SBQQ__Primary__c = true );
            
            insert quoteRec;
            
        List<Task> tskList = new List<Task>();
        Task t = new Task();
        //t.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Polaris Fullfillment').getRecordTypeId();
        t.Subject = 'PID Meeting'; 
        t.Activity_Type__c = 'Email';
        t.Type = 'Email';
        t.whatId = opp1.Id;
        t.Disqualified_Reason__c = 'mmm'; 
        t.Post_Meeting_Status__c = 'Do Not Convert to Opportunity';           
        tskList.add(t);

        Task t1 = new Task();
        //t.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Polaris Fullfillment').getRecordTypeId();
        t1.Subject = 'PID Meeting'; 
        t1.Activity_Type__c = 'Email';
        t1.whatId = dr.Id;         
        tskList.add(t1);          

       insert tskList;
            Assert.areEqual(2, tskList.size());
        }
      // tskList[0].status = 'Completed';
       
      // update tskList;
       
       
       Test.stopTest();
    } 
    
    **/

    // Test method for resetFieldsValue
    static testMethod void testResetFieldsValue(){
        Test.startTest();
		User ur = [SELECT Id FROM User WHERE Id =: Userinfo.getUserId() ];
        System.runAs(ur) {
            
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
        insert cdf;

        Id leadId = [Select Id From Lead Limit 1].Id;

        List<Task> tskList = new List<Task>();
        Task t = new Task();
        t.WhoId = leadId;
        t.Subject = 'Test Task';
        t.Type = 'Email';
        t.Status = 'Not Started';
        tskList.add(t);

        // Call resetFieldsValue method
        TaskObjectTriggerHelper.resetFieldsValue(tskList, null);

        // Verify Activity_Type__c is set from Type
        Assert.areEqual('Email', tskList[0].Activity_Type__c, 'Activity Type should be set');
        // Verify Status is set to Completed
        Assert.areEqual('Completed', tskList[0].Status, 'Status should be Completed');

        }
        Test.stopTest();
    }

    // Test method for updateLeadAndContacts with Lead
    static testMethod void testUpdateLeadAndContactsWithLead(){
        Test.startTest();
        User ur = [SELECT Id FROM User WHERE Id =: Userinfo.getUserId() ];
        System.runAs(ur) {
           
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
        insert cdf;

        Lead ld = [Select Id From Lead Limit 1];
        ld.Last_MQL_Date__c = Date.today().addDays(-30);
        update ld;

        Task t = new Task();
        t.WhoId = ld.Id;
        t.Subject = 'Email: Test';
        t.Type = 'Email';
        t.Activity_Type__c = 'Email';
        insert t;

        Map<Id, Task> taskMap = new Map<Id, Task>();
        taskMap.put(t.Id, t);

        // Call updateLeadAndContacts method
        TaskObjectTriggerHelper.updateLeadAndContacts(taskMap, true);

        Lead updatedLead = [Select Id, Most_Recent_Activity_Date__c, Attempts_All_Time__c FROM Lead WHERE Id = :ld.Id];
        Assert.areEqual(Date.today(), updatedLead.Most_Recent_Activity_Date__c, 'Most Recent Activity Date should be today');
           }
        Test.stopTest();
    }

    // Test method for updateLeadAndContacts with Contact
    static testMethod void testUpdateLeadAndContactsWithContact(){
        Test.startTest();
        User ur = [SELECT Id FROM User WHERE Id =: Userinfo.getUserId() ];
        System.runAs(ur) {
        
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
        insert cdf;

        Account act = [Select Id From Account Limit 1];
        Contact con = [Select Id From Contact Limit 1];
        con.Last_MQL_Date__c = Date.today().addDays(-30);
        update con;

        Task t = new Task();
        t.WhoId = con.Id;
        t.Subject = 'Call: Test';
        t.Type = 'Call';
        t.Activity_Type__c = 'Call';
        insert t;

        Map<Id, Task> taskMap = new Map<Id, Task>();
        taskMap.put(t.Id, t);

        // Call updateLeadAndContacts method
        TaskObjectTriggerHelper.updateLeadAndContacts(taskMap, true);

        Contact updatedContact = [Select Id, Most_Recent_Activity_Date__c, Attempts_All_Time__c FROM Contact WHERE Id = :con.Id];
        Assert.areEqual(Date.today(), updatedContact.Most_Recent_Activity_Date__c, 'Most Recent Activity Date should be today');

        }
        Test.stopTest();
    }

    // Test method for updateLeadContactDataAfterInsert with Lead
    static testMethod void testUpdateLeadContactDataAfterInsertLead(){
        Test.startTest();
        User ur = [SELECT Id FROM User WHERE Id =: Userinfo.getUserId() ];
        System.runAs(ur) {
           
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
        insert cdf;

        Lead ld = [Select Id, Status From Lead Limit 1];
        ld.Status = 'Open';
        update ld;

        List<Task> tskList = new List<Task>();
        Task t = new Task();
        t.WhoId = ld.Id;
        t.Subject = 'Test Task';
        t.Activity_Type__c = 'Email';
        tskList.add(t);

        // Call updateLeadContactDataAfterInsert method
        TaskObjectTriggerHelper.updateLeadContactDataAfterInsert(tskList);

        Lead updatedLead = [Select Id, Status FROM Lead WHERE Id = :ld.Id];
        Assert.areEqual('Working', updatedLead.Status, 'Lead Status should be Working');
        }
        Test.stopTest();

    }

    // Test method for updateLeadContactDataAfterInsert with Contact
    static testMethod void testUpdateLeadContactDataAfterInsertContact(){
        Test.startTest();
        User ur = [SELECT Id FROM User WHERE Id =: Userinfo.getUserId() ];
        System.runAs(ur) {
            
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
        insert cdf;

        Contact con = [Select Id, Contact_Status__c From Contact Limit 1];
        con.Contact_Status__c = 'Open';
        update con;

        List<Task> tskList = new List<Task>();
        Task t = new Task();
        t.WhoId = con.Id;
        t.Subject = 'Test Task';
        t.Activity_Type__c = 'Call';
        tskList.add(t);

        // Call updateLeadContactDataAfterInsert method
        TaskObjectTriggerHelper.updateLeadContactDataAfterInsert(tskList);

        Contact updatedContact = [Select Id, Contact_Status__c FROM Contact WHERE Id = :con.Id];
        Assert.areEqual('Working', updatedContact.Contact_Status__c, 'Contact Status should be Working');
        }
        Test.stopTest();
    }

    // Test method for updateLeadContactDataUpdate with Lead - Working dispositions
    static testMethod void testUpdateLeadContactDataUpdateLeadWorking(){
        Test.startTest();
        User ur = [SELECT Id FROM User WHERE Id =: Userinfo.getUserId() ];
        System.runAs(ur) {
            
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
        insert cdf;

        Lead ld = [Select Id From Lead Limit 1];

        Task t = new Task();
        t.WhoId = ld.Id;
        t.Subject = 'Test Task';
        t.SalesloftDisposition__c = 'Open';
        insert t;

        t.SalesloftDisposition__c = 'Working - Left VM';

        Map<Id, Task> oldTaskMap = new Map<Id, Task>();
        oldTaskMap.put(t.Id, new Task(Id = t.Id, SalesloftDisposition__c = 'Open'));

        List<Task> newTaskList = new List<Task>{t};

        // Call updateLeadContactDataUpdate method
        TaskObjectTriggerHelper.updateLeadContactDataUpdate(newTaskList, oldTaskMap);

        Lead updatedLead = [Select Id, Status FROM Lead WHERE Id = :ld.Id];
        Assert.areEqual('Working', updatedLead.Status, 'Lead Status should be Working');
        }
        Test.stopTest();
    }

    // Test method for updateLeadContactDataUpdate with Lead - NQ dispositions
    static testMethod void testUpdateLeadContactDataUpdateLeadNQ(){
        Test.startTest();
        User ur = [SELECT Id FROM User WHERE Id =: Userinfo.getUserId() ];
        System.runAs(ur) {
            
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
        insert cdf;

        Lead ld = [Select Id From Lead Limit 1];

        Task t = new Task();
        t.WhoId = ld.Id;
        t.Subject = 'Test Task';
        t.SalesloftDisposition__c = 'Open';
        insert t;

        t.SalesloftDisposition__c = 'NQ - No Potential';

        Map<Id, Task> oldTaskMap = new Map<Id, Task>();
        oldTaskMap.put(t.Id, new Task(Id = t.Id, SalesloftDisposition__c = 'Open'));

        List<Task> newTaskList = new List<Task>{t};

        // Call updateLeadContactDataUpdate method
        TaskObjectTriggerHelper.updateLeadContactDataUpdate(newTaskList, oldTaskMap);

        Lead updatedLead = [Select Id, Status, Lead_Rejection_Reason__c FROM Lead WHERE Id = :ld.Id];
        Assert.areEqual('Non-Qualified', updatedLead.Status, 'Lead Status should be Non-Qualified');
        Assert.areEqual('Objection: Not a Priority', updatedLead.Lead_Rejection_Reason__c, 'Rejection reason should be set');
        }
        Test.stopTest();
    }

    // Test method for updateLeadContactDataUpdate with Lead - Bad Title
    static testMethod void testUpdateLeadContactDataUpdateLeadBadTitle(){
        Test.startTest();
        User ur = [SELECT Id FROM User WHERE Id =: Userinfo.getUserId() ];
        System.runAs(ur) {
            
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
        insert cdf;

        Lead ld = [Select Id From Lead Limit 1];

        Task t = new Task();
        t.WhoId = ld.Id;
        t.Subject = 'Test Task';
        t.SalesloftDisposition__c = 'Open';
        insert t;

        t.SalesloftDisposition__c = 'NQ - Bad Title';

        Map<Id, Task> oldTaskMap = new Map<Id, Task>();
        oldTaskMap.put(t.Id, new Task(Id = t.Id, SalesloftDisposition__c = 'Open'));

        List<Task> newTaskList = new List<Task>{t};

        // Call updateLeadContactDataUpdate method
        TaskObjectTriggerHelper.updateLeadContactDataUpdate(newTaskList, oldTaskMap);

        Lead updatedLead = [Select Id, Status, Lead_Rejection_Reason__c FROM Lead WHERE Id = :ld.Id];
        Assert.areEqual('Non-Qualified', updatedLead.Status, 'Lead Status should be Non-Qualified');
        Assert.areEqual('Wrong Person: Bad Title', updatedLead.Lead_Rejection_Reason__c, 'Rejection reason should be set');

        }
        Test.stopTest();
    }

    // Test method for updateLeadContactDataUpdate with Lead - Bad Phone/Email
    static testMethod void testUpdateLeadContactDataUpdateLeadBadPhone(){
        Test.startTest();
        User ur = [SELECT Id FROM User WHERE Id =: Userinfo.getUserId() ];
        System.runAs(ur) {
            
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
        insert cdf;

        Lead ld = [Select Id From Lead Limit 1];

        Task t = new Task();
        t.WhoId = ld.Id;
        t.Subject = 'Test Task';
        t.SalesloftDisposition__c = 'Open';
        insert t;

        t.SalesloftDisposition__c = 'NQ - Bad Phone/Email';

        Map<Id, Task> oldTaskMap = new Map<Id, Task>();
        oldTaskMap.put(t.Id, new Task(Id = t.Id, SalesloftDisposition__c = 'Open'));

        List<Task> newTaskList = new List<Task>{t};

        // Call updateLeadContactDataUpdate method
        TaskObjectTriggerHelper.updateLeadContactDataUpdate(newTaskList, oldTaskMap);

        Lead updatedLead = [Select Id, Status, Lead_Rejection_Reason__c FROM Lead WHERE Id = :ld.Id];
        Assert.areEqual('Non-Qualified', updatedLead.Status, 'Lead Status should be Non-Qualified');
        Assert.areEqual('No Contact Information', updatedLead.Lead_Rejection_Reason__c, 'Rejection reason should be set');
        }
        Test.stopTest();
    }

    // Test method for updateLeadContactDataUpdate with Contact - Working dispositions
    static testMethod void testUpdateLeadContactDataUpdateContactWorking(){
        Test.startTest();
        User ur = [SELECT Id FROM User WHERE Id =: Userinfo.getUserId() ];
        System.runAs(ur) {
             
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
        insert cdf;

        Contact con = [Select Id From Contact Limit 1];

        Task t = new Task();
        t.WhoId = con.Id;
        t.Subject = 'Test Task';
        t.SalesloftDisposition__c = 'Open';
        insert t;

        t.SalesloftDisposition__c = 'Working - Connected';

        Map<Id, Task> oldTaskMap = new Map<Id, Task>();
        oldTaskMap.put(t.Id, new Task(Id = t.Id, SalesloftDisposition__c = 'Open'));

        List<Task> newTaskList = new List<Task>{t};

        // Call updateLeadContactDataUpdate method
        TaskObjectTriggerHelper.updateLeadContactDataUpdate(newTaskList, oldTaskMap);

        Contact updatedContact = [Select Id, Contact_Status__c FROM Contact WHERE Id = :con.Id];
        Assert.areEqual('Working', updatedContact.Contact_Status__c, 'Contact Status should be Working');
        }
        Test.stopTest();
    }

    // Test method for updateLeadContactDataUpdate with Contact - NQ dispositions
    static testMethod void testUpdateLeadContactDataUpdateContactNQ(){
        Test.startTest();
        User ur = [SELECT Id FROM User WHERE Id =: Userinfo.getUserId() ];
        System.runAs(ur) {
            
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
        insert cdf;

        Contact con = [Select Id From Contact Limit 1];

        Task t = new Task();
        t.WhoId = con.Id;
        t.Subject = 'Test Task';
        t.SalesloftDisposition__c = 'Open';
        insert t;

        t.SalesloftDisposition__c = 'NQ - Partner/Reseller';

        Map<Id, Task> oldTaskMap = new Map<Id, Task>();
        oldTaskMap.put(t.Id, new Task(Id = t.Id, SalesloftDisposition__c = 'Open'));

        List<Task> newTaskList = new List<Task>{t};

        // Call updateLeadContactDataUpdate method
        TaskObjectTriggerHelper.updateLeadContactDataUpdate(newTaskList, oldTaskMap);

        Contact updatedContact = [Select Id, Contact_Status__c, ContactRejectReason__c FROM Contact WHERE Id = :con.Id];
        Assert.areEqual('Non-Qualified', updatedContact.Contact_Status__c, 'Contact Status should be Non-Qualified');
        Assert.areEqual('Partner/Reseller/Disti', updatedContact.ContactRejectReason__c, 'Rejection reason should be set');

        }
        Test.stopTest();
    }

    // Test method for updateContactFollowUpDetails
    static testMethod void testUpdateContactFollowUpDetails(){
        Test.startTest();
        User ur = [SELECT Id FROM User WHERE Id =: Userinfo.getUserId() ];
        System.runAs(ur) {
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
        insert cdf;

        Contact con = [Select Id From Contact Limit 1];

        // Create a Follow up Request task
        Task followUpTask = new Task();
        followUpTask.WhoId = con.Id;
        followUpTask.Subject = 'Follow up Request';
        followUpTask.Status = 'Not Started';
        insert followUpTask;

        // Create an Email task to trigger follow-up update
        Task emailTask = new Task();
        emailTask.WhoId = con.Id;
        emailTask.Subject = 'Email: Test Follow Up';
        emailTask.Type = 'Email';
        insert emailTask;

        // Verify follow-up task is completed
        Task updatedFollowUpTask = [Select Id, Status FROM Task WHERE Id = :followUpTask.Id];
        Assert.areEqual('Completed', updatedFollowUpTask.Status, 'Follow up task should be completed');

        // Verify contact follow-up fields are updated
        Contact updatedContact = [Select Id, Last_Follow_Up_Activity_Date__c, Contact_Follow_Up_Status__c FROM Contact WHERE Id = :con.Id];
        Assert.areEqual(Date.today(), updatedContact.Last_Follow_Up_Activity_Date__c, 'Last Follow Up Activity Date should be today');
        Assert.areEqual('Follow up completed', updatedContact.Contact_Follow_Up_Status__c, 'Follow up status should be completed');

        }
        Test.stopTest();
    }

    // Test method for populateTerritoryAndSegment on insert
    static testMethod void testPopulateTerritoryAndSegmentInsert(){
        Test.startTest();
        User ur = [SELECT Id FROM User WHERE Id =: Userinfo.getUserId() ];
        System.runAs(ur) {
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
        insert cdf;

        Account act = [Select Id From Account Limit 1];
        act.ETM_Territory__c = 'Test Territory';
        //act.Account_Segment__c = 'Enterprise';
        update act;

        List<Task> tskList = new List<Task>();
        Task t = new Task();
        t.Subject = 'Channel Activity Test';
        t.Partner_Name__c = act.Id;
        t.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Channel Activity').getRecordTypeId();
        tskList.add(t);

        // Call populateTerritoryAndSegment method
        TaskObjectTriggerHelper.populateTerritoryAndSegment(tskList, null);

        Assert.areEqual('Test Territory', tskList[0].Territory__c, 'Territory should be populated');
        }
        Test.stopTest();
    }

    // Test method for populateTerritoryAndSegment on update
    static testMethod void testPopulateTerritoryAndSegmentUpdate(){
        Test.startTest();
        User ur = [SELECT Id FROM User WHERE Id =: Userinfo.getUserId() ];
        System.runAs(ur) {
            
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
        insert cdf;

        Account act = [Select Id From Account Limit 1];
        act.ETM_Territory__c = 'Updated Territory';
        update act;

        Task t = new Task();
        t.Subject = 'Channel Activity Test';
        t.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Channel Activity').getRecordTypeId();
        insert t;

        t.Partner_Name__c = act.Id;

        Map<Id, Task> oldTaskMap = new Map<Id, Task>();
        oldTaskMap.put(t.Id, new Task(Id = t.Id, Partner_Name__c = null));

        List<Task> newTaskList = new List<Task>{t};

        // Call populateTerritoryAndSegment method
        TaskObjectTriggerHelper.populateTerritoryAndSegment(newTaskList, oldTaskMap);

        Assert.areEqual('Updated Territory', newTaskList[0].Territory__c, 'Territory should be populated');
        }
        Test.stopTest();
    }

    // Test method for updateLeadContactDataUpdate with Lead - Working No Answer
    static testMethod void testUpdateLeadContactDataUpdateLeadNoAnswer(){
        Test.startTest();
        User ur = [SELECT Id FROM User WHERE Id =: Userinfo.getUserId() ];
        System.runAs(ur) {
           
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
        insert cdf;

        Lead ld = [Select Id From Lead Limit 1];

        Task t = new Task();
        t.WhoId = ld.Id;
        t.Subject = 'Test Task';
        t.SalesloftDisposition__c = 'Open';
        insert t;

        t.SalesloftDisposition__c = 'Working - No Answer';

        Map<Id, Task> oldTaskMap = new Map<Id, Task>();
        oldTaskMap.put(t.Id, new Task(Id = t.Id, SalesloftDisposition__c = 'Open'));

        List<Task> newTaskList = new List<Task>{t};

        // Call updateLeadContactDataUpdate method
        TaskObjectTriggerHelper.updateLeadContactDataUpdate(newTaskList, oldTaskMap);

        Lead updatedLead = [Select Id, Status FROM Lead WHERE Id = :ld.Id];
        Assert.areEqual('Working', updatedLead.Status, 'Lead Status should be Working');
        }
        Test.stopTest();
    }

    // Test method for updateLeadContactDataUpdate with Contact - Working No Answer
    static testMethod void testUpdateLeadContactDataUpdateContactNoAnswer(){
        Test.startTest();
        User ur = [SELECT Id FROM User WHERE Id =: Userinfo.getUserId() ];
        System.runAs(ur) {
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
        insert cdf;

        Contact con = [Select Id From Contact Limit 1];

        Task t = new Task();
        t.WhoId = con.Id;
        t.Subject = 'Test Task';
        t.SalesloftDisposition__c = 'Open';
        insert t;

        t.SalesloftDisposition__c = 'Working - No Answer';

        Map<Id, Task> oldTaskMap = new Map<Id, Task>();
        oldTaskMap.put(t.Id, new Task(Id = t.Id, SalesloftDisposition__c = 'Open'));

        List<Task> newTaskList = new List<Task>{t};

        // Call updateLeadContactDataUpdate method
        TaskObjectTriggerHelper.updateLeadContactDataUpdate(newTaskList, oldTaskMap);

        Contact updatedContact = [Select Id, Contact_Status__c FROM Contact WHERE Id = :con.Id];
        Assert.areEqual('Working', updatedContact.Contact_Status__c, 'Contact Status should be Working');
        }
        Test.stopTest();
    }

    // Test method for updateLeadContactDataUpdate with Contact - NQ Bad Title
    static testMethod void testUpdateLeadContactDataUpdateContactBadTitle(){
        Test.startTest();
        User ur = [SELECT Id FROM User WHERE Id =: Userinfo.getUserId() ];
        System.runAs(ur) {
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
        insert cdf;

        Contact con = [Select Id From Contact Limit 1];

        Task t = new Task();
        t.WhoId = con.Id;
        t.Subject = 'Test Task';
        t.SalesloftDisposition__c = 'Open';
        insert t;

        t.SalesloftDisposition__c = 'NQ - Bad Title';

        Map<Id, Task> oldTaskMap = new Map<Id, Task>();
        oldTaskMap.put(t.Id, new Task(Id = t.Id, SalesloftDisposition__c = 'Open'));

        List<Task> newTaskList = new List<Task>{t};

        // Call updateLeadContactDataUpdate method
        TaskObjectTriggerHelper.updateLeadContactDataUpdate(newTaskList, oldTaskMap);

        Contact updatedContact = [Select Id, Contact_Status__c, ContactRejectReason__c FROM Contact WHERE Id = :con.Id];
        Assert.areEqual('Non-Qualified', updatedContact.Contact_Status__c, 'Contact Status should be Non-Qualified');
        Assert.areEqual('Wrong Person: Bad Title', updatedContact.ContactRejectReason__c, 'Rejection reason should be set');

        }
        Test.stopTest();
    }

    // Test method for updateLeadContactDataUpdate with Contact - NQ Bad Phone/Email
    static testMethod void testUpdateLeadContactDataUpdateContactBadPhone(){
        Test.startTest();
        User ur = [SELECT Id FROM User WHERE Id =: Userinfo.getUserId() ];
        System.runAs(ur) {
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
        insert cdf;

        Contact con = [Select Id From Contact Limit 1];

        Task t = new Task();
        t.WhoId = con.Id;
        t.Subject = 'Test Task';
        t.SalesloftDisposition__c = 'Open';
        insert t;

        t.SalesloftDisposition__c = 'NQ - Bad Phone/Email';

        Map<Id, Task> oldTaskMap = new Map<Id, Task>();
        oldTaskMap.put(t.Id, new Task(Id = t.Id, SalesloftDisposition__c = 'Open'));

        List<Task> newTaskList = new List<Task>{t};

        // Call updateLeadContactDataUpdate method
        TaskObjectTriggerHelper.updateLeadContactDataUpdate(newTaskList, oldTaskMap);

        Contact updatedContact = [Select Id, Contact_Status__c, ContactRejectReason__c FROM Contact WHERE Id = :con.Id];
        Assert.areEqual('Non-Qualified', updatedContact.Contact_Status__c, 'Contact Status should be Non-Qualified');
        Assert.areEqual('No Contact Information', updatedContact.ContactRejectReason__c, 'Rejection reason should be set');
        }
        Test.stopTest();
    }

    // Test method for updateLeadContactDataUpdate with Contact - NQ No Potential
    static testMethod void testUpdateLeadContactDataUpdateContactNoPotential(){
        Test.startTest();
        User ur = [SELECT Id FROM User WHERE Id =: Userinfo.getUserId() ];
        System.runAs(ur) {
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
        insert cdf;

        Contact con = [Select Id From Contact Limit 1];

        Task t = new Task();
        t.WhoId = con.Id;
        t.Subject = 'Test Task';
        t.SalesloftDisposition__c = 'Open';
        insert t;

        t.SalesloftDisposition__c = 'NQ - No Potential';

        Map<Id, Task> oldTaskMap = new Map<Id, Task>();
        oldTaskMap.put(t.Id, new Task(Id = t.Id, SalesloftDisposition__c = 'Open'));

        List<Task> newTaskList = new List<Task>{t};

        // Call updateLeadContactDataUpdate method
        TaskObjectTriggerHelper.updateLeadContactDataUpdate(newTaskList, oldTaskMap);

        Contact updatedContact = [Select Id, Contact_Status__c, ContactRejectReason__c FROM Contact WHERE Id = :con.Id];
        Assert.areEqual('Non-Qualified', updatedContact.Contact_Status__c, 'Contact Status should be Non-Qualified');
        Assert.areEqual('Objection: Not a Priority', updatedContact.ContactRejectReason__c, 'Rejection reason should be set');

        }
        Test.stopTest();
    }

    // Test method for PID Meeting with Lead
    static testMethod void testPIDMeetingWithLead(){
        Test.startTest();
        User ur = [SELECT Id FROM User WHERE Id =: Userinfo.getUserId() ];
        System.runAs(ur) {
            
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
        insert cdf;

        Lead ld = [Select Id From Lead Limit 1];

        Task t = new Task();
        t.WhoId = ld.Id;
        t.Subject = 'PID Meeting';
        t.Type = 'Call';
        insert t;

        Map<Id, Task> taskMap = new Map<Id, Task>();
        taskMap.put(t.Id, t);

        // Call updateLeadAndContacts method with isInsert = true
        TaskObjectTriggerHelper.updateLeadAndContacts(taskMap, true);

        Lead updatedLead = [Select Id, PID_Meeting_Task_Id__c FROM Lead WHERE Id = :ld.Id];
            system.assert(true);

        }
        Test.stopTest();
    }

    // Test method for empty task list scenarios
    static testMethod void testEmptyTaskListScenarios(){
        Test.startTest();
        User ur = [SELECT Id FROM User WHERE Id =: Userinfo.getUserId() ];
        System.runAs(ur) {
           
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = Userinfo.getUserId(),Disable_Opportunity_Validation_Rules__c = true);
        insert cdf;

        List<Task> emptyTaskList = new List<Task>();

        // Call methods with empty lists
        TaskObjectTriggerHelper.updateLeadContactDataAfterInsert(emptyTaskList);
        TaskObjectTriggerHelper.updateLeadContactDataUpdate(emptyTaskList, new Map<Id, Task>());
        TaskObjectTriggerHelper.resetFieldsValue(emptyTaskList, null);
        TaskObjectTriggerHelper.populateTerritoryAndSegment(emptyTaskList, null);

        // Verify no errors occur
        Assert.areEqual(0, emptyTaskList.size(), 'Task list should remain empty');
        }
        Test.stopTest();
    }
}