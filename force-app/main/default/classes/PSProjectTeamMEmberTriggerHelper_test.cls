@isTest
public class PSProjectTeamMEmberTriggerHelper_test {
    @testSetup static void setup() {
        
        List<Account> AccountId                        =     CustomTestDataFactory.createAccounts(1);
        List<PS_Project__c> ProjectId                  =     CustomTestDataFactory.testPSProject_c(AccountId); 
        List<PS_Project_Team_Member__c>  TeamMember    =     CustomTestDataFactory.createTeamMem(ProjectId);   
        List<PS_Task__c>  PsTask                       =     CustomTestDataFactory.createPS_Task1(ProjectId,AccountId);
        List<PS_Time_Entry__c> PsTimeEntry             =     CustomTestDataFactory.createPSTime(PsTask);
    }
    
    public static testmethod void Test(){
        List<PS_Project__c>  PSProject = [select id from PS_Project__c];
      List<PS_Project_Team_Member__c> Team  =   [SELECT Id, PS_Project__c FROM PS_Project_Team_Member__c
                                                WHERE PS_Project__c =: PSProject]; 
                                                              
        list<PS_Time_Entry__c>  PstimeEntry = [SELECT Id, Assignee__c, PS_Task__c, PS_Task__r.Project__c, Status__c 
                                                   FROM PS_Time_Entry__c WHERE 
                                                   PS_Task__r.Project__c =: PSProject AND 
                                                   Status__c != 'Approved'];
 id projId;  
 id UserId;   

          PSProjectTeamMEmberTriggerHelper.cleanTimeEntryRecord(projId,UserId);
        
    }
    
}