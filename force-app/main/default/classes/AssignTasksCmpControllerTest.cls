@isTest
public class AssignTasksCmpControllerTest{

   @testSetup static void setup() {
       //inserted project instance
       PS_Project__c projInst = new PS_Project__c();
       projInst.Name = 'test project';
       insert projInst;
       
       //inserted task instance
       PS_Task__c taskInst = new PS_Task__c();
       taskInst.Project__c = projInst.Id;
       insert taskInst;
       
       //inserted sub-task instance
       PS_SubTask__c subTskInst = new PS_SubTask__c();
       subTskInst.Task__c = taskInst.Id;
       insert subTskInst;
   
   }
    
   public static testmethod void getPsSubTaskTest(){
       List<string> subtaskId = new List<string>();
       List<PS_Project__c> proj = [SELECT Id FROM PS_Project__c LIMIT 1];
       List<PS_SubTask__c> lstSubtasks = [SELECT Id,Task__c FROM PS_SubTask__c WHERE Task__r.Project__c = :proj[0].Id];
       for(PS_SubTask__c sub : lstSubtasks){
       		subtaskId.add(sub.Id);
       }
       Test.StartTest();
       Map<Id,PS_SubTask__c> subtaskMap = new Map<Id,PS_SubTask__c>(lstSubtasks);
       
       List<AssignTasksCmpController.PSSubTaskWrapper> wrapLst = AssignTasksCmpController.getPsSubTask(lstSubtasks[0].Task__c,subtaskId);
       //System.assertEquals(lstSubtasks.size(),wrapLst.size());
       String result = AssignTasksCmpController.assignSubtasks(Json.serialize(new List<Id>{UserInfo.getUserId()}), Json.serialize(subtaskMap.keySet()));
       Integer originalSize = lstSubtasks.size();
       //lstSubtasks = [SELECT Id,Task__c FROM PS_SubTask__c WHERE Task__r.Project__c = :proj[0].Id];
       //since a new set of subtasks will bbe created and assigned to the user, previous ones will be intact
       //System.assertEquals(originalSize*2 ,lstSubtasks.size());
       AssignTasksCmpController asg = new AssignTasksCmpController();
       AssignTasksCmpController.getPsTask(proj[0].Id);
       AssignTasksCmpController.getAllPsSubTask(proj[0].Id);
       AssignTasksCmpController.getPsSubTask(lstSubtasks[0].Task__c,subtaskId);
       Test.StopTest();     
       
   } 


}