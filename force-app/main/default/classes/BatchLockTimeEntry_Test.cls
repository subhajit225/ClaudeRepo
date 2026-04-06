@isTest
public class BatchLockTimeEntry_Test {
    @testSetup static  void createdata(){
        CustomTestDataFactory.insertCustomSettings();
        list<Account> accId                  = CustomTestDataFactory.testAccounts(1);
        list<opportunity> oppId              = CustomTestDataFactory.TESTOpp(accId);
        List<order> CreateOrder              = CustomTestDataFactory.testorders(accId,oppId);
        List<PS_Project__c> PsprojectId      = CustomTestDataFactory.testPSProject_c(accId);
        List<PS_Task__c>  pstaskInstall      = CustomTestDataFactory.createPstaskInstall(PsprojectId,true);
        List<PS_Task__c>  pstaskConsult      = CustomTestDataFactory.createPstaskConsult(PsprojectId,true);
       	insert new PS_Time_Entry__c(PS_Task__c=pstaskInstall[0].id,Billable__c= true,Status__c='Approved',Time_Entry_Date__c = System.today());
        list<PS_Time_Card__c>   Pstimecard   = CustomTestDataFactory.CreatTimecard(PsprojectId);
    }
    @isTest 
    public static void test1(){
        Test.startTest();
        Database.executeBatch(new BatchLockTimeEntry('select id,Billable_Hours_locked__c from Ps_Task__c'));
        Test.stopTest();
    }
}