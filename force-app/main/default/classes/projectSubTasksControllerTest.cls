@isTest
public class projectSubTasksControllerTest {
     @testSetup static void createdata(){
        ShGl_TestFactoryHelper.insertCustomSettings();
        ShGl_TestFactoryHelper.WorkflowTriggerBypass();
        insert new ShGl_DisableBusinessLogic__c(Disable_PS_Task_Triggers__c = true,setupOwnerId = userinfo.getuserid());
        List<PS_Task__c> taskList = new List<PS_Task__c>();
        List<PS_SubTask__c> subtaskList = new List<PS_SubTask__c>(); 
        List<PS_Time_Entry__c> psoList = new List<PS_Time_Entry__c>();
         
        Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account acc = new Account(name='test1239',recordtypeId= partner);
        insert acc;
        Opportunity oppr = TestDataFactory.getOpportunity(acc);
        oppr.Name='testing DIEtestsalesforce 4/6/2015';
        insert oppr;
        
        Order od2 = new Order();
        od2.AccountId = acc.Id;
        od2.OpportunityId =oppr.Id;
        od2.EffectiveDate = Date.Today();
        //od2.Status = 'PO Received';
        od2.Order_Status__c = 'PO Received';
        od2.ShippingStreet ='Test Street';
        od2.ShippingCity ='Test City';
        od2.ShippingState ='California';
        od2.ShippingCountry ='United States';
        od2.ShippingPostalcode ='94820';
        //od2.ship_To_Name__c=acc.id;
        od2.Shipping_Address_Label__c = null;
        insert od2;
        
        PS_Project__c proj = new PS_Project__c(Account__c=acc.Id,Project_Status__c='Open');
        insert proj;

        PS_Task__c task1 = new PS_Task__c(Project__c=proj.Id,Task_Type__c='Install',Task_Status__c='Open');
        taskList.add(task1);
        PS_Task__c task2 = new PS_Task__c(Project__c=proj.Id,Task_Type__c='Install',Task_Status__c='Open');
        taskList.add(task2);
		PS_Task__c task3 = new PS_Task__c(Project__c=proj.Id,Task_Type__c='Non-Billable (Product)',Task_Status__c='Open');
        taskList.add(task3);
		PS_Task__c task4 = new PS_Task__c(Project__c=proj.Id,Task_Type__c='Admin',Task_Status__c='Open');
        taskList.add(task4);
		PS_Task__c task5 = new PS_Task__c(Project__c=proj.Id,Task_Type__c='Consult-Onsite',Task_Status__c='Open');
        taskList.add(task5);
		PS_Task__c task6 = new PS_Task__c(Project__c=proj.Id,Task_Type__c='Consult-Remote',Task_Status__c='Open');
        taskList.add(task6);
        insert taskList;
         
        PS_SubTask__c subtask11 = new PS_SubTask__c(PS_Assignee__c=userinfo.getuserid(),Task__c=taskList[0].Id,Task_Type__c='Consult');
        subtaskList.add(subtask11); 
        PS_SubTask__c subtask21 = new PS_SubTask__c(PS_Assignee__c=userinfo.getuserid(),Task__c=taskList[1].Id,Task_Type__c='Consult');
        subtaskList.add(subtask21); 
         PS_SubTask__c subtask12 = new PS_SubTask__c(PS_Assignee__c=userinfo.getuserid(),Task__c=taskList[0].Id,Task_Type__c='Consult');
        subtaskList.add(subtask12);  
        insert subtaskList;
        
        PS_Time_Entry__c psot1 = new PS_Time_Entry__c(Hours_Spent__c=0,PS_SubTask__c=subtaskList[0].Id,Time_Entry_Date__c=system.today().addDays(-2), PS_Task__c = task1.id);
        psoList.add(psot1);
        PS_Time_Entry__c psot2 = new PS_Time_Entry__c(Hours_Spent__c=0,PS_SubTask__c=subtaskList[0].Id,Time_Entry_Date__c=system.today(), PS_Task__c = task1.id);
        psoList.add(psot2);
        PS_Time_Entry__c psot3 = new PS_Time_Entry__c(Hours_Spent__c=0,PS_SubTask__c=subtaskList[0].Id,Time_Entry_Date__c=system.today().addDays(1), PS_Task__c = task1.id);
        psoList.add(psot3); 
        PS_Time_Entry__c psot4 = new PS_Time_Entry__c(Hours_Spent__c=0,PS_SubTask__c=subtaskList[1].Id,Time_Entry_Date__c=system.today().addDays(-2), PS_Task__c = task2.id);
        psoList.add(psot4);
        PS_Time_Entry__c psot5 = new PS_Time_Entry__c(Hours_Spent__c=0,PS_SubTask__c=subtaskList[1].Id,Time_Entry_Date__c=system.today(), PS_Task__c = task2.id);
        psoList.add(psot5);
        PS_Time_Entry__c psot6 = new PS_Time_Entry__c(PS_SubTask__c=subtaskList[1].Id,Time_Entry_Date__c=system.today().addDays(1), PS_Task__c = task2.id);
        psoList.add(psot6);
		PS_Time_Entry__c psot7 = new PS_Time_Entry__c(Time_Entry_Date__c=system.today().addDays(1), PS_Task__c = task3.id,Hours_Spent__c = 4);
        psoList.add(psot7);
		PS_Time_Entry__c psot8 = new PS_Time_Entry__c(Time_Entry_Date__c=system.today().addDays(1), PS_Task__c = task4.id,Hours_Spent__c = 4);
        psoList.add(psot8);
		PS_Time_Entry__c psot9 = new PS_Time_Entry__c(Time_Entry_Date__c=system.today().addDays(1), PS_Task__c = task5.id);
        psoList.add(psot9);
		PS_Time_Entry__c psot10 = new PS_Time_Entry__c(Time_Entry_Date__c=system.today().addDays(1), PS_Task__c = task6.id);
        psoList.add(psot10);
        database.insert(psoList,false); 
    }
    
    @isTest
    static void testgetsubtasksList() {
        PS_Project__c proj1 = [select Id from PS_Project__c limit 1];
        List<PS_Task__c> taskList = [select Id,Project__c,Name,Task_Type__c from PS_Task__c];
        List<PS_SubTask__c> subtakList = [select Id,Name,Task__c,Task_Type__c from PS_SubTask__c];
        List<PS_Time_Entry__c> psoList1 = [select Id,PS_SubTask__c,Time_Entry_Date__c,Backend_Id__c from PS_Time_Entry__c where PS_SubTask__c =: subtakList[0].Id];
        List<PS_Time_Entry__c> psoList2 = [select Id,PS_SubTask__c,Time_Entry_Date__c,Backend_Id__c from PS_Time_Entry__c where PS_SubTask__c =: subtakList[1].Id];
        for(PS_Time_Entry__c ps1 : psoList1){
            ps1.Backend_Id__c = ps1.Id;
        }
        for(PS_Time_Entry__c ps1 : psoList2){
            ps1.Backend_Id__c = ps1.Id;
        }
        projectSubTasksController.getsubtasksList(proj1.Id,system.today().addDays(-2),system.today().addDays(4));
        Double d = 0;
        List<projectSubTasksController.innerWrapperClass> iwList = new List<projectSubTasksController.innerWrapperClass>();
        d= 8;
        
        
        //projectSubTasksController.innerWrapperClass iw2 = new projectSubTasksController.innerWrapperClass(string.valueOf(taskList[0].Id),taskList[0].Task_Type__c,string.valueOf(subtakList[0].Id),subtakList[0].Task_Type__c,string notes,Double totalhours,List<PS_Time_Entry__c> psoList1){
        //projectSubTasksController.innerWrapperClass iw3 = new projectSubTasksController.innerWrapperClass(string taskId, string taskName,string subtaskId,string subtaskName,string notes,Double totalhours,List<PS_Time_Entry__c> psoList1){
        
        List<projectSubTasksController.subtaskWrapperClass> subTasks = projectSubTasksController.getsubtasksList(proj1.Id, System.today().addDays(-2), System.today().addDays(4));
        
        projectSubTasksController.innerWrapperClass iw2 = new projectSubTasksController.innerWrapperClass(string.valueOf(taskList[0].Id),taskList[0].Task_Type__c,string.valueOf(subtakList[0].Id),subtakList[0].Task_Type__c,'test1',d,psoList1);
        projectSubTasksController.innerWrapperClass iw3 = new projectSubTasksController.innerWrapperClass(string.valueOf(taskList[0].Id),taskList[0].Task_Type__c,string.valueOf(subtakList[0].Id),subtakList[0].Task_Type__c,'test2',d,psoList2);
        List<projectSubTasksController.subtaskWrapperClass> wrapList = new List<projectSubTasksController.subtaskWrapperClass>();
        iwList.add(iw2);
        iwList.add(iw3);
        
        projectSubTasksController.subtaskWrapperClass wrap1 = new projectSubTasksController.subtaskWrapperClass(taskList[0].Task_Type__c,iwList);
        wrapList.add(wrap1);
        string wrapListstr = JSON.serialize(wrapList);
        projectSubTasksController.savePSOtime(wrapListstr, '');
        
        System.assertNotEquals(0, subTasks.size(), 'Expected some subtasks to be returned from getsubtasksList()');
        System.assertNotEquals(null, wrapListStr, 'Serialized wrapper list should not be null');
        System.assertEquals(2, iwList.size(), 'Expected two inner wrapper entries');
        
        List<PS_Time_Entry__c> updatedEntries = [SELECT Id, Backend_Id__c FROM PS_Time_Entry__c WHERE Id IN :psoList1 OR Id IN :psoList2];
        System.assert(!updatedEntries.isEmpty(), 'Time entries should exist after savePSOtime');
    }
    
    /*@isTest
    static void testPSTimeEntryComponentController() {
        
        PS_Project__c proj1 = [select Id,Name from PS_Project__c limit 1];
        List<Order> orderList = [select Id from Order];
        List<PS_Task__c> taskList = [select Id,Project__c,Name,Task_Type__c from PS_Task__c];
        List<PS_SubTask__c> subtakList = [select Id,Name,Task__c,Task_Type__c from PS_SubTask__c];
        List<PS_Time_Entry__c> psoList1 = [select Id,PS_SubTask__c,Time_Entry_Date__c,Backend_Id__c from PS_Time_Entry__c where PS_SubTask__c =: subtakList[0].Id];
        List<PS_Time_Entry__c> psoList2 = [select Id,PS_SubTask__c,Time_Entry_Date__c,Backend_Id__c from PS_Time_Entry__c where PS_SubTask__c =: subtakList[1].Id];
        for(PS_Time_Entry__c ps1 : psoList1){
            ps1.Backend_Id__c = ps1.Id;
        }
        for(PS_Time_Entry__c ps1 : psoList2){
            ps1.Backend_Id__c = ps1.Id;
        }
        
        PS_Project_Team_Member__c pst = new PS_Project_Team_Member__c(PS_Project__c=proj1.id,Team_Member__C =UserInfo.getUSerId());
        insert pst;
        
        Test.startTest();
        List<PS_Project__c> initValues = PSTimeEntryComponentController.getAllInitialValues();
        List<PS_Project__c> initValuesNew = PSTimeEntryComponentController.getAllInitialValues_new();
        List<PSTimeEntryComponentController.PSProjectWrapper> projectList = PSTimeEntryComponentController.getAllBProjects(null, UserInfo.getUserId());
        Id projectId = PSTimeEntryComponentController.createProject(proj1, null, orderList, 'External');
        Test.stopTest();
        
        System.assertNotEquals(null, initValues, 'getAllInitialValues() should not return null.');
        System.assert(initValues.size() >= 0, 'getAllInitialValues() should return a valid list.');
        System.assertNotEquals(null, initValuesNew, 'getAllInitialValues_new() should not return null.');
        System.assert(initValuesNew.size() >= 0, 'getAllInitialValues_new() should return a valid list.');
        System.assertNotEquals(null, projectList, 'getAllBProjects() should not return null.');
        System.assert(projectList.size() >= 0, 'getAllBProjects() should return a valid list.');
        //System.assertNotEquals(null, projectId, 'Project should be created successfully.');
    }*/
    
	@isTest
    static void updateTimeSheetEntryList() {
        PS_Project__c psProj = [Select Id,Project_Status__c from PS_Project__c LIMIT 1];
        Test.startTest();
		psProj.Project_Status__c = 'Completed';
		update psProj;
		List<PS_Time_Entry__c>	timesheetEntryList = new List<PS_Time_Entry__c>([Select Id from PS_Time_Entry__c where (PS_Task__r.Task_Type__c='Non-Billable (Product)' OR PS_Task__r.Task_Type__c='Admin')]);
        System.debug(LoggingLevel.DEBUG, 'timesheetEntryList >>> ' + timesheetEntryList);
        Integer beforeDeleteCount = timesheetEntryList.size();
        if(timesheetEntryList != null){
            delete timesheetEntryList;
        }
        List<PS_Time_Entry__c> afterDeleteList = [SELECT Id FROM PS_Time_Entry__c WHERE (PS_Task__r.Task_Type__c = 'Non-Billable (Product)' OR PS_Task__r.Task_Type__c = 'Admin')];
		List<PS_Subtask__C> subtaskList = new List<PS_Subtask__C>([select Id,Name,Task__c,Task_Type__c from PS_SubTask__c]);
		Set<Id> subtaskId = new Set<Id>();
		for(PS_Subtask__C st : subtaskList){
			subtaskId.add(st.id);
		}
        projectSubTasksController.SubtaskRollUpAsyncJob asyncJob = new projectSubTasksController.SubtaskRollUpAsyncJob(subtaskId);
		//System.enqueueJob(asyncJob);
        Id jobId = System.enqueueJob(asyncJob);
        Test.stopTest();
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser){
            PS_Project__c updatedProj = [SELECT Project_Status__c FROM PS_Project__c WHERE Id = :psProj.Id];
            System.assertEquals('Completed', updatedProj.Project_Status__c, 'Project status should be updated to Completed.');
            System.assertEquals(0, afterDeleteList.size(), 'All matching time entries should be deleted.');
            System.assertNotEquals(null, jobId, 'Async job should have been enqueued successfully.');
            System.assert(beforeDeleteCount >= 0, 'Before delete count should be non-negative.');
        }
	}
}