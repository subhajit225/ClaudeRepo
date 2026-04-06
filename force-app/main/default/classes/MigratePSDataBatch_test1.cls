@isTest
public class MigratePSDataBatch_test1 {
    @testSetup static  void createdata(){
        List<TriggerControl__c> TriggerControlSetting =          CustomTestDataFactory.TriggerControlSetting(true);
        list<Account> accId                           =          CustomTestDataFactory.testAccounts(1);
        list<Contact>  contactId                      =          CustomTestDataFactory.createcont(accId);
        list<opportunity> oppId                       =          CustomTestDataFactory.TESTOpp(accId);
        List<order> CreateOrder                       =          CustomTestDataFactory.testorders(accId,oppId);
        List<PS_Project__c> PsprojectId               =          CustomTestDataFactory.testPSProject_c(accId);
        
        List<PS_Task__c>  pstaskInstall               =          CustomTestDataFactory.createPstaskInstall(PsprojectId, false);
        List<PS_Task__c>  pstaskConsult               =          CustomTestDataFactory.createPstaskConsult(PsprojectId, false);
        List<PS_Task__c>  TaskAll = new List<PS_Task__c> ();
        TaskAll.addAll(pstaskInstall);
        TaskAll.addAll(pstaskConsult);
        insert TaskAll;
        
        
        List<PS_SubTask__c> PsSubInstall              =          CustomTestDataFactory.createPSSubtaskInstall(pstaskInstall, false);
        List<PS_SubTask__c> PsSubConsult              =          CustomTestDataFactory.createPSSubtaskConsult(pstaskConsult, false);
        
        List<PS_SubTask__c>  Admin                    =         CustomTestDataFactory.createPSSubtaskAdmin(pstaskInstall, false);
        
        List<PS_SubTask__c>  subTaskAll = new List<PS_SubTask__c> ();
        subTaskAll.addAll(PsSubInstall);
        subTaskAll.addAll(PsSubConsult);
        subTaskAll.addAll(Admin);
        insert subTaskAll;
        
        List<PS_Time_Entry__c> Adminentry             =         CustomTestDataFactory.createPSTimeEntryAdmin(TaskAll,subTaskAll);
    }
    
    public static testmethod void TestMigratePSData(){
        Test.startTest();
            MigratePSDataBatch mgps = new MigratePSDataBatch();
            Database.executeBatch(mgps,200);
        Test.stopTest();
    }
}