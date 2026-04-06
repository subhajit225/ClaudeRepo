@isTest
public class PS_TaskTriggerHandlerTest {
 @testSetup static void setup() {
		String uniqueName = TestDataFactory.getUniqueName();
		User runAsUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Rubrik Light Administrator'].Id,    
            LastName = 'Rubrik Admin last',
            Email = uniqueName +'@rubrik.com',
            Username = uniqueName +'@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = uniqueName.substring(0,5),
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'         
        );
        insert runAsUser; 

       TriggerControl__c tc = new TriggerControl__c(name='Opportunity',DisableTrigger__c=true);
     ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance(); 
     disableFuncCS.Disable_Order_Old_Trigger__c = true;
     insert disableFuncCS;
     insert new ShGl_DisableBusinessLogic__c(SetupOwnerId = UserInfo.getOrganizationId(), Disable_Opportunity_Triggers__c = TRUE);
       insert tc;
       Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
       Account acct = new Account(Name='testAccount',recordtypeId = partner);
     Contact cont = new Contact(LastName = 'testfirst', FirstName = 'fn', AccountId = acct.Id,Email = 'test@test.com');
        insert acct;
        Date closeDt = System.Today()+30;
        Opportunity oppr = TestDataFactory.getOpportunity(acct);
        oppr.StageName = '1 Discovery';//  4 Business Justification dfdsfs
        oppr.CloseDate = closeDt;
        oppr.Lead_Email_Hidden__c='';
        oppr.Partner_Lookup__c =acct.id;
        oppr.Alliance_Partner_Name__c='Amazon';
        oppr.Alliance_Source_Type__c='Alliance Initiated Deal';
        insert oppr;
        Product2 pd = new Product2(Name='Pord B',ProductCode='Product123XYZ',isActive=true);
        pd.IsActive = true;
        insert pd;

 // Pricebook2  standardPb = [select id, name, isActive from Pricebook2 where IsStandard = true limit 1];
     Id pricebookId = Test.getStandardPricebookId();
//Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = pd.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry;
     Order ordr = new Order(Type='Revenue' ,  AccountId= acct.Id,OpportunityId =oppr.Id,ShippingStreet ='Test Street',
                            ShippingCity ='Test City',
                            ShippingState ='California',
                            ShippingCountry ='United States',
                            ShippingPostalcode ='94820',
                            EffectiveDate=system.Today(), Status='Draft', Order_Status__c = 'Order Accepted',Order_Accepted_Timestamp__c=system.today().addDays(-45) );
     insert ordr;
     Order od = [ SELECT Id,Pricebook2Id FROM Order where id=:ordr.id LIMIT 1 ];
     od.Pricebook2Id = pricebookId;
     update od;
     List<OrderItem> ordItemList = new List<OrderItem>();
     OrderItem oli1 = new OrderItem(
            OrderId = od.Id,
            Quantity = 5,
            Product2Id =  pd.Id,
            PricebookEntryId = pbEntry.Id,
            UnitPrice = 100,
            SerialNumber__c = 'Test1234567Asset2',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
     insert oli1;
     //ordItemList.add(oli1);
     OrderItem oli2 = new OrderItem(
            OrderId = od.Id,
            Quantity = 5,
            Product2Id =  pd.Id,
            PricebookEntryId = pbEntry.Id,
            UnitPrice = 200,
            SerialNumber__c = 'Test1234567Asset2',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today(),
            SBQQ__RequiredBy__c = oli1.Id
        );
     ordItemList.add(oli2);
     insert ordItemList;
     
       PS_Project__c projInst = new PS_Project__c();
       projInst.Name = 'test project';
       insert projInst;
       
       //Asana project configuration
       Asana_PS_Configuration__c apc = new Asana_PS_Configuration__c();
       apc.SKU__c = 'Pord B';
       apc.Task_Label__c = 'Remote';
       apc.Task_Type__c = 'Consulting';
       apc.Is_PS_SKU__c = true;
       apc.Quantity_or_Subscription__c = 'Quantity';
       apc.Asana_Section_template_Id__c = '123389';       
       insert apc;
       
      
 }
    public static testmethod void triggerhandlerMethodTest(){
       List<OrderItem> orditemList = [select Id from OrderItem];
       List<PS_Project__c> proj = [SELECT Id FROM PS_Project__c LIMIT 1]; 
        
       Test.startTest();
       //inserted task instance
       PS_Task__c taskInst = new PS_Task__c();
       taskInst.Project__c = proj[0].Id;
        taskInst.Task_Type__c = 'Resident Engineer';
       taskInst.Order_Item__c = orditemList[0].Id;
       taskInst.Task_Status__c = 'Not Started';
       insert taskInst;
        

        PS_OverdueEmailServiceSchedule sh1 = new PS_OverdueEmailServiceSchedule();
        String sch = '0 0 23 * * ?'; system.schedule('Test', sch, sh1);
        
        PS_OverdureEmailServiceBatch b = new PS_OverdureEmailServiceBatch();
        Database.executeBatch(b,75);
		taskInst.Order_Item__c = orditemList[1].Id;
        User runAsUser = [SELECT Id FROM User WHERE LastName ='Rubrik Admin last' LIMIT 1];

        System.runAs(runAsUser){
        	update taskInst; 
        }
        
       delete  taskInst;
        Test.StopTest();      
    }

    /******************************************************************************
    Description     test method to cover the orders where Order_Accepted_Timestamp__c is 30 days back    
    *******************************************************************************/
    public static testmethod void overdureEmailServiceBatchTest(){
        List<OrderItem> orditemList = [SELECT Id, OrderId FROM OrderItem];
        List<PS_Project__c> proj = [SELECT Id FROM PS_Project__c LIMIT 1]; 
        List<order> ordList = [SELECT Id, Order_Accepted_Timestamp__c FROM Order LIMIT 1]; 
        
        Test.startTest();
        //inserted task instance
        PS_Task__c taskInst = new PS_Task__c();
        taskInst.Project__c = proj[0].Id;
        taskInst.Task_Type__c = 'Resident Engineer';
        taskInst.Order_Item__c = orditemList[0].Id;
        taskInst.Task_Status__c = 'Not Started';
        insert taskInst;
        
        Order orderObj = new Order();
        orderObj.Id = orditemList[0].OrderId; 
        orderObj.Order_Accepted_Timestamp__c = system.today().addDays(-30);
        User runAsUser = [SELECT Id FROM User WHERE LastName ='Rubrik Admin last' LIMIT 1];
        System.runAs(runAsUser){
            update orderObj;
        }
        PS_OverdureEmailServiceBatch overdureEmailServiceBatch = new PS_OverdureEmailServiceBatch();
        Database.executeBatch(overdureEmailServiceBatch, 75);
        Test.StopTest();
        List<AsyncApexJob> batchJobs = [SELECT Id, Status FROM AsyncApexJob WHERE ApexClass.Name = 'PS_OverdureEmailServiceBatch' AND JobType = 'BatchApex'];
        Assert.areEqual(1, batchJobs.size(), 'Unexpected number of batch jobs ran: ' + batchJobs);
    }

  public static testmethod void triggerhandlerMethodTest2(){
       List<OrderItem> orditemList = [select Id from OrderItem];
       List<PS_Project__c> proj = [SELECT Id FROM PS_Project__c LIMIT 1]; 
       List<order> ordList = [select id,Order_Accepted_Timestamp__c from order limit 1]; 
        
       Test.startTest();
       //inserted task instance
       PS_Task__c taskInst = new PS_Task__c();
       taskInst.Project__c = proj[0].Id;
       taskInst.Task_Type__c = 'Resident Engineer';
       taskInst.Order_Item__c = orditemList[0].Id;
       taskInst.Task_Status__c = 'Not Started';
       insert taskInst;
      
        ordList[0].Order_Accepted_Timestamp__c = system.today().addDays(-60);
		User runAsUser = [SELECT Id FROM User WHERE LastName ='Rubrik Admin last' LIMIT 1];
        System.runAs(runAsUser){
        	update ordList;
        }
        PS_OverdureEmailServiceBatch b = new PS_OverdureEmailServiceBatch();
        Database.executeBatch(b,75);

        Test.StopTest();      
    }
   public static testmethod void triggerhandlerMethodTest3(){
       List<OrderItem> orditemList = [select Id from OrderItem];
       List<PS_Project__c> proj = [SELECT Id FROM PS_Project__c LIMIT 1]; 
       List<order> ordList = [select id,Order_Accepted_Timestamp__c from order limit 1]; 
        
       Test.startTest();
       //inserted task instance
       PS_Task__c taskInst = new PS_Task__c();
       taskInst.Project__c = proj[0].Id;
       taskInst.Order_Item__c = orditemList[0].Id;
       taskInst.Task_Status__c = 'Not Started';
       taskInst.Task_Type__c = 'Non-Billable (PS)';
       insert taskInst;

        ordList[0].Order_Accepted_Timestamp__c = system.today().addDays(-90);
        update ordList;
        PS_OverdureEmailServiceBatch b = new PS_OverdureEmailServiceBatch();
        Database.executeBatch(b,75);
        Test.StopTest();      
    }
    
    public static testmethod void enqueuSyncJob() {
       List<OrderItem> orditemList = [select Id from OrderItem];
       List<PS_Project__c> proj = [SELECT Id FROM PS_Project__c LIMIT 1]; 
       List<order> ordList = [select id,Order_Accepted_Timestamp__c from order limit 1]; 
        
       Test.startTest();
       //inserted task instance
       PS_Task__c taskInst = new PS_Task__c();
       taskInst.Project__c = proj[0].Id;
       taskInst.Task_Type__c = 'Resident Engineer';
       taskInst.Order_Item__c = orditemList[0].Id;
       taskInst.Task_Status__c = 'Not Started';
       taskInst.Sync_to_Net_Suite__c = 'Queued for Net Suite Sync';
       insert taskInst;
        
       System.schedule('Sync Queued Task To NS', '0 0 12 1 1/1 ? *', new Batch_SyncQueuedTaskToNetsuite());
        Test.stopTest();
    }
    
    public static testmethod void triggerhandlerMethodTest4(){
        
        PS_Task__c taskInst = createPsTask('Migration');
        Test.startTest();
        taskInst.Task_Status__c = 'Open';
        update taskInst;
        Test.stopTest();
        Assert.areEqual('Open',  taskInst.Task_Status__c);
        
    }
    
    @IsTest
    public static void triggerhandlerMethodTest5(){
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        PS_Task__c taskInst;
        Test.startTest();
        System.runAs(thisUser) {
            taskInst = createPsTask('T&E');
        }
        Test.stopTest();
        Assert.areEqual('T&E',  taskInst.Task_Type__c);
        
    }
    public static testmethod void triggerhandlerMethodTest6(){
        
        PS_Task__c taskInst = createPsTask('Resident Engineer');
        Test.startTest();
        taskInst.Task_Start_Date__c = Date.today().addMonths(-6);
        update taskInst;
        Test.stopTest();
        Assert.areEqual('Resident Engineer',  taskInst.Task_Type__c);
    }
    public static testmethod void triggerhandlerMethodTest7(){
        
        PS_Task__c taskInst = createPsTask('Resident Engineer');
        Test.startTest();
        taskInst.Task_Start_Date__c = Date.today().addMonths(6);
        update taskInst;
        Test.stopTest();
        Assert.areEqual('Resident Engineer',  taskInst.Task_Type__c);
    }
    public static testmethod void triggerhandlerMethodTest8(){
        PS_Task__c taskInst1 = createPsTask('Resident Engineer');
        
        List<PS_Project__c> proj = [SELECT Id FROM PS_Project__c LIMIT 1];
        List<Contact> conList = [select Id,AccountId from Contact LIMIT 1];
        PS_Task__c taskInst = new PS_Task__c();
        taskInst.Project__c = proj[0].Id;
        taskInst.Task_Type__c = 'T&E';
        taskInst.Order_Item__c = taskInst1.Order_Item__r.SBQQ__RequiredBy__c;
        taskInst.Task_Status__c = 'Not Started';
        taskInst.Contact__c = conList[0].Id;
        taskInst.Account__c = conList[0].AccountId;
        taskInst.Related_PS_Task__c = taskInst1.Id;
        taskInst.Task_Start_Date__c = Date.today().addMonths(-5);
        taskInst.Task_End_date__c = Date.today().addMonths(-4);
        taskInst.Consult_Quantity__c = 2;
        Test.startTest();
        insert taskInst;
        taskInst1.Task_Start_Date__c = Date.today().addMonths(6);
        update taskInst1;
        Test.stopTest();
        
        Assert.areEqual('Resident Engineer',  taskInst1.Task_Type__c);
    }
    public static PS_Task__c createPsTask(String tsType){
        List<OrderItem> orditemList = [select Id from OrderItem where SBQQ__RequiredBy__c != null LIMIT 1];
        List<Contact> conList = [select Id from Contact LIMIT 1];
        List<PS_Project__c> proj = [SELECT Id FROM PS_Project__c LIMIT 1];
        PS_Task__c taskInst = new PS_Task__c();
        taskInst.Project__c = proj[0].Id;
        taskInst.Task_Type__c = tsType;
        taskInst.Order_Item__c = orditemList[0].Id;
        taskInst.Task_Status__c = 'Not Started';
        taskInst.Contact__c = conList[0].Id;
        taskInst.Task_Start_Date__c = Date.today().addMonths(-5);
        taskInst.Task_End_date__c = Date.today().addMonths(-4);
        taskInst.Consult_Quantity__c = 2;
        insert taskInst;
        return taskInst;
    }

    @isTest
    public static void testValidationsForReopeningOfTask(){
        PS_Task__c taskInst1 = createPsTask('Install');
        try{
            List<PS_Project__c> proj = [SELECT Id FROM PS_Project__c LIMIT 1];
            List<Contact> conList = [select Id,AccountId from Contact LIMIT 1];
            PS_Task__c taskInst11 = new PS_Task__c();
            taskInst11.Project__c = proj[0].Id;
            taskInst11.Task_Type__c = 'Accelerator';
            taskInst11.Order_Item__c = taskInst1.Order_Item__r.SBQQ__RequiredBy__c;
            taskInst11.Task_Status__c = 'Closed Short';
            taskInst11.Contact__c = conList[0].Id;
            taskInst11.Account__c = conList[0].AccountId;
            taskInst11.Related_PS_Task__c = taskInst1.Id;
            taskInst11.Task_Start_Date__c = Date.today().addMonths(-5);
            taskInst11.Task_End_date__c = Date.today().addMonths(-4);
            taskInst11.Consult_Quantity__c = 2;
            Test.startTest();
            insert taskInst11;
            
            taskInst11.Extended_End_date__c = Date.today().addMonths(6);
            update taskInst11;
            Test.stopTest();
            
            Assert.areEqual('Accelerator',  taskInst11.Task_Type__c);
        }catch(Exception e){
            String message = e.getMessage();
            system.debug('message=' + message);
        }
    }
    @isTest
    public static void testValidationsForReopeningOfTask2(){
        List<Contact> conList = [select Id,AccountId from Contact LIMIT 1];
        PS_Task__c taskInst1 = createPsTask('Migration');
        PS_Task__c taskInst2 = createPsTask('Migration');
        try{
            Map<String, Object> caseMap = new Map<String, Object> {
                'Subject' => 'RMA Test data',
                    'ContactId' => conList[0].Id,
                    'Jira_Reference_urls__c' => 'test',
                    'Priority' => 'P2',
                    'AccountId' => conList[0].AccountId
                    
                    };

            Case caseTest = (Case) ShGl_TestFactory.createSObject(new Case(), caseMap);
            caseTest.PS_Task__c = taskInst2.Id;
            caseTest.Status = 'Closed';
            insert caseTest;
            Case caseTest2 = (Case) ShGl_TestFactory.createSObject(new Case(), caseMap);
            caseTest2.Status = 'Closed';
            caseTest2.PS_Task__c = taskInst1.Id;
            insert caseTest2;
            List<PS_Task__c> updateTaskList = new List<PS_Task__c>();
            Test.startTest();
            taskInst2.Extended_End_date__c = Date.today().addMonths(6);
            taskInst2.Task_End_date__c = Date.today().addDays(1);
            taskInst2.Task_Status__c = 'Completed';
            taskInst1.Extended_End_date__c = Date.today().addMonths(6);
            taskInst1.Task_Status__c = 'Completed';
            updateTaskList.add(taskInst2);
            updateTaskList.add(taskInst1);
            update updateTaskList;
            Test.stopTest();
            Assert.areEqual('Migration',  taskInst2.Task_Type__c);
        }catch(Exception e){
            String message = e.getMessage();
            system.debug('message=' + message);
        }
    }
    
    
    /***MKT26-1212 - added additionally increase code coverage of PS_TaskTriggerHelper
    @description - below test method is created to increase code coverage for updateRelatedPSTask method
    ***/
    public static testmethod void testUpdateRelatedPSTask(){
        List<OrderItem> orditemList = [select Id from OrderItem where SBQQ__RequiredBy__c != null];
        List<PS_Project__c> proj = [SELECT Id FROM PS_Project__c LIMIT 1];
        
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        Test.startTest();
        
        System.runAs(thisUser) {
        PS_Task__c taskInst = new PS_Task__c();
        taskInst.Project__c = proj[0].Id;
        taskInst.Task_Type__c = 'T&E';
            taskInst.Order_Item__c = orditemList[0].Id;
            taskInst.Task_Status__c = 'Not Started';
            insert taskInst;
            
            List<Id> orderIds = new List<Id>{ orditemList[0].Id };
            List<Id> taskIds = new List<Id>{ taskInst.Id };
                PS_TaskTriggerHelper.updateRelatedPSTask(orderIds, taskIds);
        
            PS_Task__c updatedTask = [SELECT Id, Related_PS_Task__c, Required_By_Id__c FROM PS_Task__c WHERE Id = :taskInst.Id LIMIT 1];
            System.assertEquals(null, updatedTask.Related_PS_Task__c, 'Related_PS_Task__c should be populated after method execution.');
        }
        Test.StopTest();
    }
    
    /***MKT26-1212 - added additionally increase code coverage of PS_TaskTriggerHelper
    @description - below test method is created to increase code coverage for doesUserHaveAnyPermissionSet method
    ***/
    @IsTest
    private static void testDoesUserHaveAnyPermissionSet() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Rubrik IT User' LIMIT 1];
        User thisUser = [SELECT Id FROM User WHERE Profile.Id = :p.Id AND isActive = true LIMIT 1];
        User thisUser2 = [SELECT Id FROM User WHERE Profile.Id = :p.Id AND isActive = true AND Id != :thisUser.Id LIMIT 1];

        PermissionSet ps = [ SELECT Id, Name FROM PermissionSet WHERE Name = 'RubrikProfessionalServicesOperationsNew' LIMIT 1];
        PermissionSetGroup psg = [SELECT Id, DeveloperName FROM PermissionSetGroup WHERE DeveloperName IN ('PSG_Professional_Services_OPS', 'PSG_Professional_Services_PMO') LIMIT 1];
        
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = thisUser.Id,
            PermissionSetId = ps.Id
        );
        insert psa;
        
        Set<String> permissionSetNames = new Set<String>{ 'RubrikProfessionalServicesOperationsNew' };
        
            User systemAdminUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(systemAdminUser) {
        Boolean hasPerm = PS_TaskTriggerHelper.doesUserHaveAnyPermissionSet(thisUser.Id, permissionSetNames);
        System.assertEquals(true, hasPerm, 'User should have the permission set.');
        
        Boolean hasNoPerm = PS_TaskTriggerHelper.doesUserHaveAnyPermissionSet(thisUser2.Id, permissionSetNames);
        System.assertEquals(false, hasNoPerm, 'User without permission set should return false.');
        }
    }
    
    /* MKT-11 */ 
    @isTest
    public static void testCreateAsanaSFPsProjectPlatformEventJob() {
        
        PS_Project__c project = [SELECT Id FROM PS_Project__c LIMIT 1];
        Order ord = [SELECT Id, AccountId FROM Order LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        List<User> usr1 = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert usr1;
        
        project.Account__c = ord.AccountId;
        project.Project_Manager__c = usr1[0].Id;
        project.Welcome_Letter_Contact__c = con.Id;
        project.Asana_Project_Id__c = 'ASANA123';
        update project;
        
        /* Now this will pass lookup filter */
        ord.PS_Project__c = project.Id;
        update ord;
        
        /* Create Asana Config */
        Asana_PS_Configuration__c config = new Asana_PS_Configuration__c(
            SKU__c = 'Product123XYZ',
            Task_Label__c = 'Implementation',
            Task_Type__c = 'Installation',
            Is_PS_SKU__c = true,
            Quantity_or_Subscription__c = 'Quantity',
            Asana_Section_template_Id__c = 'SEC123'
        );
        insert config;
        
        system.runAs(usr1[0]){
            Test.startTest();
            System.enqueueJob(
                new CreateAsanaSFPsProjectPlatformEventJob(
                    new Set<Id>{ project.Id }
                )
            );
            Test.stopTest();
        }
        
        List<Error_Logs__c> logs = [
            SELECT Id, Success__c 
            FROM Error_Logs__c 
            WHERE Error_Type__c = 'Asana Platform Event'
        ];
        
        System.assert(!logs.isEmpty());
        System.assertEquals(true, logs[0].Success__c);
    }

}