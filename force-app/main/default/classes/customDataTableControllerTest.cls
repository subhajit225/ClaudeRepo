/**
 * @description Test class for customDataTableController
 * @test
 * @author Vijay Kumar K R
 * @date May 5, 2023
 */
@isTest
public with sharing class customDataTableControllerTest {
    
    /**
     * @description Test setup method to create test data including User, Configuration settings, and related records
     */
    @TestSetup
    static void makeData(){
        
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'Rubrik Customer Support User'].Id;
        
        User u = new User(
            ProfileId = profileId,
            LastName = 'last',
            Email = 'csit-testuser@rubrik.com',
            Username = System.now().millisecond() + 'csit-testuser@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Employee_Time_Off__c = true);
        insert u;
        System.runAs(u){
            insert new E2CAdv__E2CAConfiguration__c(
                Name = 'E2C Advance Configuration',
                E2CAdv__EnableTrigger__c = false
            );
            
            // Insert the AccountTrigger setting record (List Custom Setting)
            insert new E2CAdv__E2CATriggers__c(
                Name = 'AccountTrigger',
                E2CAdv__IsActive__c = true
            );
            
            E2CAdv__E2CAConfiguration__c generalConfiguration = E2CAdv__E2CAConfiguration__c.getInstance('E2C Advance Configuration');
            E2CAdv__E2CATriggers__c accountTriggerSetting = E2CAdv__E2CATriggers__c.getInstance('AccountTrigger');
            EscalationManagementTeamControllerTest.makeData();
        }
    }
    
    /**
     * @description Test method to verify saving notes for escalation records and validate field updates
     */
    @isTest
    static void saveNotesForEscalationTest(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            
            Escalation__c objEsc = [SELECT Id FROM Escalation__c Limit 1];
            Note__c objNote = [SELECT Id FROM Note__c Limit 1];
            objNote.Area_Of_Improvement__c = '<p>Escalation next steps</p>';
            List<Note__c> noteList = new List<Note__c>();
            noteList.add(objNote);
            
            customDataTableController.saveNotes(JSON.serialize(noteList));
            customDataTableController.getFieldsInfo('Note__c', 'LL_Areas_of_Improvement', objEsc.Id, 'LL_Area_of_Improvement');
            System.assertEquals('<p>Escalation next steps</p>', [SELECT Id, Area_Of_Improvement__c FROM Note__c WHERE Id =: objNote.Id].Area_Of_Improvement__c);
        }
    }
    
    /**
     * @description Test method to verify saving notes for lessons learned records and validate field updates
     */
    @isTest
    static void saveNotesForLessonsLearnedTest(){ 
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Lessons_Learned__c objll = [SELECT Id FROM Lessons_Learned__c Limit 1];
            Note__c objNote = [SELECT Id FROM Note__c Limit 1];
            objNote.Area_Of_Improvement__c = '<p>Escalation next steps</p>';
            
            List<Note__c> noteList = new List<Note__c>();
            noteList.add(objNote);
            
            customDataTableController.saveNotes(JSON.serialize(noteList));
            customDataTableController.getFieldsInfo('Note__c', 'LL_Areas_of_Improvement', objll.Id, 'LL_Area_of_Improvement');
            System.assertEquals('<p>Escalation next steps</p>', [SELECT Id, Area_Of_Improvement__c FROM Note__c WHERE Id =: objNote.Id].Area_Of_Improvement__c);
        }
    }
}