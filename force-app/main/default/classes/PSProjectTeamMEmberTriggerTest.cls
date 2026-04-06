@isTest
public class PSProjectTeamMEmberTriggerTest {
	@testSetup static  void createdata(){
        ShGl_TestFactoryHelper.insertCustomSettings();
		ShGl_TestFactoryHelper.WorkflowTriggerBypass();
        
        List<PS_Task__c> taskList = new List<PS_Task__c>();
        List<PS_SubTask__c> subtaskList = new List<PS_SubTask__c>(); 
        List<PS_Time_Entry__c> psoList = new List<PS_Time_Entry__c>();
         
        Account acc = new Account(name='test1239');
        insert acc;
        
        PS_Project__c proj = new PS_Project__c(Account__c=acc.Id,Project_Status__c='Open');
        insert proj;

        PS_Task__c task1 = new PS_Task__c(Project__c=proj.Id,Task_Type__c='Install',Task_Status__c='Open');
        taskList.add(task1);
        PS_Task__c task2 = new PS_Task__c(Project__c=proj.Id,Task_Type__c='Install',Task_Status__c='Open');
        taskList.add(task2);
        insert taskList;
         
        PS_SubTask__c subtask11 = new PS_SubTask__c(Subtask_End_Date__c=system.today(),Subtask_Start_Date__c=system.today(),Subtask_Type__c='Install',Hours_logged__c=10,PS_Assignee__c=userinfo.getuserid(),Task__c=taskList[0].Id,Task_Type__c='Install');
        subtaskList.add(subtask11); 
        PS_SubTask__c subtask21 = new PS_SubTask__c(Subtask_End_Date__c=system.today(),Subtask_Start_Date__c=system.today(),Subtask_Type__c='Install',Hours_logged__c=10,Task__c=taskList[1].Id,Task_Type__c='Install');
        subtaskList.add(subtask21); 
        PS_SubTask__c subtask12 = new PS_SubTask__c(Subtask_End_Date__c=system.today(),Subtask_Start_Date__c=system.today(),Subtask_Type__c='Install',Hours_logged__c=10,PS_Assignee__c=userinfo.getuserid(),Task__c=taskList[0].Id,Task_Type__c='Install');
        subtaskList.add(subtask12);  
        insert subtaskList;
        PS_Project_Team_Member__C mem = new PS_Project_Team_Member__C();
        mem.Team_Member__c = userinfo.getuserId();
        mem.PS_Project__c = proj.Id;
        insert mem;
    }
    public static testMethod void testupdateteammems() {
        User u = [select Id,name from User where isActive = true AND ContactId=null limit 1];
        PS_Project__c proj1 = [select Id from PS_Project__c limit 1];
        PS_Project_Team_Member__C mem = [select Id,Team_Member__c from PS_Project_Team_Member__C limit 1];
        mem.Team_Member__c = u.Id;
        update mem;
    }
}