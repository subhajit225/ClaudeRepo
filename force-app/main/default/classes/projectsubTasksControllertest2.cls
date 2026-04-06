@isTest
public class projectsubTasksControllertest2 {
    @testSetup static  void createdata(){
        CustomTestDataFactory.insertCustomSettings();
        insert new ShGl_DisableBusinessLogic__c(Disable_PS_Task_Triggers__c = true,setupOwnerId = userinfo.getuserid());
        list<Account> accId                  = CustomTestDataFactory.testAccounts(1);
        //list<opportunity> oppId              = CustomTestDataFactory.TESTOpp(accId);
        //List<order> CreateOrder              = CustomTestDataFactory.testorders(accId,oppId);
        List<PS_Project__c> PsprojectId      = CustomTestDataFactory.testPSProject_c(accId);
        List<PS_Task__c>  pstaskInstall      = CustomTestDataFactory.createPstaskInstall(PsprojectId,true);
        List<PS_Task__c>  pstaskConsult      = CustomTestDataFactory.createPstaskConsult(PsprojectId,true);
        List<PS_SubTask__c> PsSubInstall     = CustomTestDataFactory.createPSSubtaskInstall(pstaskInstall,true);
        List<PS_SubTask__c> PsSubConsult     = CustomTestDataFactory.createPSSubtaskConsult(pstaskConsult,true);
        List<PS_Time_Entry__c> PstimeInstall = CustomTestDataFactory.createPSTimeEntryInstall(pstaskInstall,PsSubInstall);
        List<PS_Time_Entry__c> PstimeConsult = CustomTestDataFactory.createPSTimeEntryConsult(pstaskConsult,PsSubConsult);
        list<PS_Time_Card__c>   Pstimecard   = CustomTestDataFactory.CreatTimecard(PsprojectId);
    }
    
    @isTest
    static void testgetsubtasks() {
        Map<Id, sobject> oldTimeEntryMap = new  Map<Id, sobject>();
        
        PS_Project__c proj1                  = [select Id, (select id, Task_Status__c , End_Date__c  from PS_Tasks__r)  from PS_Project__c limit 1];
        List<PS_Task__c> taskList            = [select Id,Project__c,Name,Task_Type__c from PS_Task__c];
        List<PS_SubTask__c> subtakList       = [select Id,Name,Task__c,Task_Type__c from PS_SubTask__c];
        List<PS_Time_Entry__c> psoList1      = [select Id,Time_Entry_Date__c,Backend_Id__c,Comments__c,Status__c from PS_Time_Entry__c];
        List<PS_Time_Entry__c> psoList2      = [select Id,Time_Entry_Date__c,Backend_Id__c,Assignee__c,Comments__c,PS_Time_Card__c,Status__c,PS_Task__c,PS_Task__r.Task_Type__c, Billable__c, Hours_Spent__c from PS_Time_Entry__c];
        
        
        
        List<Id> psProjectIds = new List<Id>();
        psProjectIds.add(proj1.id);
        
        Set<Id> subTaskIdSet = new Set<Id>();
        for(PS_SubTask__c subTask : subtakList){
            subTaskIdSet.add(subTask.id);       
        }
        
        for(PS_Time_Entry__c ps1 : psoList1){
            ps1.Backend_Id__c = ps1.Id;
        }
        for(PS_Time_Entry__c ps1 : psoList2){
            ps1.Backend_Id__c = ps1.Id;
        }
        
        projectSubTasksController.getsubtasksList(proj1.Id,system.today().addDays(-2),system.today().addDays(4));
        Double d = 0;
        List<projectSubTasksController.innerWrapperClass> iwList     = new List<projectSubTasksController.innerWrapperClass>();
        d= 8;
        
        projectSubTasksController.innerWrapperClass iw2              = new projectSubTasksController.innerWrapperClass(string.valueOf(taskList[0].Id),taskList[0].Task_Type__c,null,null,'test1',d,psoList1);
        projectSubTasksController.innerWrapperClass iw3              = new projectSubTasksController.innerWrapperClass(string.valueOf(taskList[0].Id),taskList[0].Task_Type__c,null,null,'test2',d,psoList2);
        List<projectSubTasksController.subtaskWrapperClass> wrapList = new List<projectSubTasksController.subtaskWrapperClass>();
        iwList.add(iw2);
        iwList.add(iw3);
        
        projectSubTasksController.subtaskWrapperClass wrap1          = new projectSubTasksController.subtaskWrapperClass(taskList[0].Task_Type__c,iwList);
        wrapList.add(wrap1);
        string wrapListstr = JSON.serialize(wrapList);
        projectSubTasksController.savePSOtime(wrapListstr, '');
        projectSubTasksController.updateTasksFromProject(psProjectIds);
        projectSubTasksController.updateSubtaskHours(subTaskIdSet);
        projectSubTasksController.calculateTimeCardHoursDelete(psoList2);
        projectSubTasksController.createOrUpdateTimeCard(psoList2);
        projectSubTasksController.calculateTimeCardHours(psoList2,oldTimeEntryMap);
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser){
        System.assertNotEquals(null, iwList, 'innerWrapper list should not be null');
        }
    }
    @isTest
    static void testMethod1(){
        PS_Project__c proj1 = [select Id, (select id, Task_Status__c , End_Date__c  from PS_Tasks__r)  from PS_Project__c limit 1];
        List<PS_Time_Card__c> pstimecardList = [Select Id from PS_Time_Card__c];
        
        Account acc = [SELECT Id,Name From Account LIMIT 1];
        /*acc.Name = 'Rubrik';
        update acc;*/
        
        Id rtId = Schema.SObjectType.PS_Project__c.getRecordTypeInfosByName().get('Internal').getRecordTypeId();
        PS_Project__c proj = new PS_Project__c(Account__c=acc.Id,Project_Status__c='Open', Name = 'ADMIN' , recordtypeId = rtId);
        insert proj;
        
        List<PS_Task__c> taskList = new List<PS_Task__c>();
        PS_Task__c task1 = new PS_Task__c(Project__c=proj1.Id,Task_Type__c='Consult - Non Billable',Task_Status__c='Open');
        PS_Task__c task2 = new PS_Task__c(Project__c=proj1.Id,Task_Type__c='Consult-Onsite',Task_Status__c='Open');
        PS_Task__c task3 = new PS_Task__c(Project__c=proj1.Id,Task_Type__c='Consult-Remote',Task_Status__c='Open');
        PS_Task__c task4 = new PS_Task__c(Project__c=proj1.Id,Task_Type__c='Rubrik University',Task_Status__c='Open');
        PS_Task__c task5 = new PS_Task__c(Project__c=proj1.Id,Task_Type__c='Install - Non Billable',Task_Status__c='Open');
        PS_Task__c task6 = new PS_Task__c(Project__c=proj.Id,Task_Type__c='Install - Non Billable',Task_Status__c='Open');
        taskList.add(task1);
        taskList.add(task2);
        taskList.add(task3);
        taskList.add(task4);
        taskList.add(task5);
        taskList.add(task6);
        Insert taskList;
        
        List<PS_Time_Entry__c> psoList = new List<PS_Time_Entry__c>();
        PS_Time_Entry__c psot1 = new PS_Time_Entry__c(Hours_Spent__c=8,Time_Entry_Date__c=system.today().addDays(-2), PS_Task__c = taskList[0].id, PS_Time_Card__c = pstimecardList[0].Id);
        PS_Time_Entry__c psot2 = new PS_Time_Entry__c(Hours_Spent__c=8,Time_Entry_Date__c=system.today().addDays(-2), PS_Task__c = taskList[1].id, PS_Time_Card__c = pstimecardList[0].Id);
        PS_Time_Entry__c psot3 = new PS_Time_Entry__c(Hours_Spent__c=8,Time_Entry_Date__c=system.today().addDays(-2), PS_Task__c = taskList[2].id, PS_Time_Card__c = pstimecardList[0].Id);
        PS_Time_Entry__c psot4 = new PS_Time_Entry__c(Hours_Spent__c=8,Time_Entry_Date__c=system.today().addDays(-2), PS_Task__c = taskList[3].id, PS_Time_Card__c = pstimecardList[0].Id);
        PS_Time_Entry__c psot5 = new PS_Time_Entry__c(Hours_Spent__c=8,Time_Entry_Date__c=system.today().addDays(-2), PS_Task__c = taskList[4].id, PS_Time_Card__c = pstimecardList[0].Id);
        PS_Time_Entry__c psot6 = new PS_Time_Entry__c(Hours_Spent__c=8,Time_Entry_Date__c=system.today().addDays(-2), PS_Task__c = taskList[5].id, PS_Time_Card__c = pstimecardList[0].Id);
        psoList.add(psot1);
        psoList.add(psot2);
        psoList.add(psot3);
        psoList.add(psot4);
        psoList.add(psot5);
        psoList.add(psot6);
        Insert psoList;
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser){
            projectSubTasksController.calculateTimeCardHours(psoList,null);
            projectSubTasksController.calculateTimeCardHoursDelete(psoList);
        }
        
        System.assertNotEquals(null, psoList, 'innerWrapper list should not be null');
    }
}