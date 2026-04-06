/**
 * @author Abhishek Mahajan
 * @date 25th September 2023
 * @description Controller to PlaybookTemplatesController
 */
@isTest
public class PlaybookTemplatesControllerTest {

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
        insert new Account(Name = 'Test Account');
    }

    @isTest
    static void testGetPlaybookTemplates(){
        System.assertEquals(2, PlaybookTemplatesController.getPlaybookTemplates().size());
    }

    @isTest
    static void testCreatePlayBookRecords() {       
        Id accountId = [SELECT Id FROM Account WHERE Name = 'Test Account'].Id;
		Playbook_Template__c template = [SELECT Id FROM Playbook_Template__c WHERE Name = 'Playbook Template 1'];
        Test.startTest();
        PlaybookTemplatesController.createPlayBookRecords(template.Id, 'Test Playbook', accountId);
        Test.stopTest();

        List<Playbook__c> playbooks = [SELECT Id, Name FROM Playbook__c WHERE Account__c=:accountId];
        System.assertEquals(1, playbooks.size(), 'Expected Account to have a Playbook');

        List<Sub_Task__c> subTasks = [SELECT Id, Name, Playbook__c FROM Sub_Task__c];
        System.assertNotEquals(0, subTasks.size(), 'Expected Playbook to have subTasks');

        List<Checklist__c> checklists = [SELECT Id FROM Checklist__c];
        System.assertNotEquals(0, checklists.size(), 'Expected Playbook to have checklist');

    }
}