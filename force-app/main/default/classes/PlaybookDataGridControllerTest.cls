/**
 * @author Abhishek Mahajan
 * @date 25th September 2023
 * @description Controller to PlaybookDataGridController
 */
@isTest
public class PlaybookDataGridControllerTest {
    @TestSetup
    static void setup(){
        List<Playbook_Template__c> templates = new List<Playbook_Template__c>{
            new Playbook_Template__c(Name = 'Playbook Template 1', Active__c=true),
            new Playbook_Template__c(Name = 'Playbook Template 2', Active__c=true)
        };
        insert templates;

        Playbook_Sub_Task__c subTask = new Playbook_Sub_Task__c(Name = 'Playbook Sub Task 1', Playbook_Template__c = templates[0].Id);
        insert subTask;
        insert new Playbook_Checklist__c(Name = 'Playbook Checklist', Playbook_Sub_Task__c = subTask.id);
        Account account = new Account(Name = 'Test Account');
        insert account;
        PlaybookTemplatesController.createPlayBookRecords(templates[0].Id, 'Test Playbook', account.Id);
    }
    
    @isTest
    public static void test_getTasksBySubtasks() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        List<Sub_Task__c> subtasks= PlaybookDataGridController.getTasksBySubtasks(testAccount.Id);
        Test.stopTest();
        System.assert(!subtasks.isEmpty(), 'subtasks should have been found');

    }

    @isTest
    public static void testDeleteTask() {
        Checklist__c checklist = [SELECT Id FROM Checklist__c LIMIT 1];
        Test.startTest();
        PlaybookDataGridController.deleteTask(checklist.Id);
        Test.stopTest();

        Checklist__c[] deletedTask = [SELECT Id FROM Checklist__c WHERE Id = :checklist.Id LIMIT 1];
        System.assert(deletedTask.isEmpty(), 'Checklist should have been deleted');
    }

    @isTest
    public static void testDeleteTask_NotFound() {
        Test.startTest();
        Exception ex;
        try {
            PlaybookDataGridController.deleteTask('invalidId');
        } catch (AuraHandledException e) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, ex, 'An exception should be thrown for an invalid recordId');
    }
}