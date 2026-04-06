/**
* @Author       :   Saakshi Gupta
* @CreatedDate  :   05-06-2020
* @Jira Ticket  :   CS21-183 - Configure and Implement Salesforce Surveys with PS Project
* @Description  :   Test class for PSProjectSurveyController.cls
*/
@isTest(seeAllData=true)
public class PSProjectsSurveyControllerTest {
    /*@testSetup
    public static void dataSetup() {
        Account acc = new Account(name='testAcc');
        insert acc;

        Contact cont = new Contact(lastName='testCont');
        cont.Notify_For_case_creation__c = true;
        cont.Email='testcontact@test.com';
        cont.AccountId=acc.Id;
        insert cont;

        PS_Project__c psProject = new PS_Project__c();
        psProject.Name = 'Test PS Project';
        psProject.Account__c = acc.Id;
        insert psProject;
    }*/

    private static testMethod void testIsInvitationCreationAllowed() {
        Boolean isAllowed = PSProjectsSurveyController.isInvitationCreationAllowed();
        System.assert(isAllowed);
    }

    private static testMethod void testGetPSProjectRecord() {
        Account acc = new Account(name='testAcc');
        insert acc;

        PS_Project__c psProject = new PS_Project__c();
        psProject.Name = 'Test PS Project';
        psProject.Account__c = acc.Id;
        insert psProject;

        //PS_Project__c psProject = [SELECT Id FROM PS_Project__c];

        PS_Project__c queriedPsProject = PSProjectsSurveyController.getPSProjectRecord(psProject.Id);
        System.assert(queriedPsProject != null);
    }

    private static testMethod void testGetContacts() {
        Account acc = new Account(Name='testAcc');
        insert acc;

        Contact cont = new Contact(lastName='testCont');
        cont.Notify_For_case_creation__c = true;
        cont.Email='testcontact@test.com';
        cont.AccountId=acc.Id;
        insert cont;

        Account accountRecord = [SELECT Id FROM Account WHERE Name = 'testAcc' LIMIT 1];
        List<Contact> contactsList = PSProjectsSurveyController.getContacts(accountRecord.Id);
        System.assert(contactsList.size() > 0);
    }

    private static testMethod void testSendSurveyInvitations() {
        Account acc = new Account(name='testAcc');
        insert acc;

        Contact cont = new Contact(lastName='testCont');
        cont.Notify_For_case_creation__c = true;
        cont.Email='testcontact@test.com';
        cont.AccountId=acc.Id;
        insert cont;

        PS_Project__c psProject = new PS_Project__c();
        psProject.Name = 'Test PS Project';
        psProject.Account__c = acc.Id;
        insert psProject;

        //PS_Project__c psProject = [SELECT Id FROM PS_Project__c WHERE Name = 'Test PS Project'];
        List<Contact> contactList = [SELECT Id, AccountId, Name, Email FROM Contact WHERE Email = 'testcontact@test.com'];
        Survey surveyRecord = [SELECT Id, DeveloperName FROM Survey LIMIT 1];

        String message = PSProjectsSurveyController.sendSurveyInvitations(contactList, surveyRecord, psProject.Id);
       // System.assert(message.startsWith('Survey invitations sent successfully for'));
    }
}