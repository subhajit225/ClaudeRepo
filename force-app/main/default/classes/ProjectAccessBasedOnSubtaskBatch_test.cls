@isTest
public class ProjectAccessBasedOnSubtaskBatch_test {
    @testSetup static void setup() { 
        List<Account> accId                        = CustomTestDataFactory.createAccounts(1);
        
        List<Contact> conId                        = CustomTestDataFactory.createContacts(accId);
        
        List<PS_Project__c> projId                 = CustomTestDataFactory.createPS_Project(conId,accId);
        
        List<PS_Project_Team_Member__c> CreateTeam = CustomTestDataFactory.createTeamMem(projId);
        
        List<PS_Task__c>  PsTaskId                 = CustomTestDataFactory.createPS_Task1(projId,accId);
        
        List<PS_SubTask__c> CreatePsSubtask        = CustomTestDataFactory.createPSSubtask(PsTaskId);
        
    }
    public static testmethod void Test(){
        Test.startTest();
      Id bacthId = Database.executebatch(new ProjectAccessBasedOnSubtaskBatch());
        Test.stopTest();
    }
}