@isTest
public class PSTAskInfoControllerTest {
    @testSetup
    static void setup(){        
        List<TriggerControl__c> TriggerCon = CustomTestDataFactory.TriggerControlSetting(true); 
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();    
        Account acct = new Account(Name='testAccount',RecordTypeId= devRecordTypeId);
        insert acct;
        
        Contact con  = new Contact(LastName = 'testContact', AccountId = acct.id);
        insert con;
        
        Date closeDt = System.Today()+30;
        opportunity oppr = new opportunity(Name='testing DIEtestsalesforce 27/1/2017' ,  AccountId= acct.Id,StageName = '4 Business Justification',
                                           CloseDate = closeDt, Lead_Email_Hidden__c='', Partner_Lookup__c =acct.id, Alliance_Source_Type__c='Alliance Initiated Deal');
        insert oppr;
        
        PS_Project__c PSPro = new PS_Project__c(Account__c = acct.id,Name = 'test Pro',Welcome_Letter_Contact__c = con.id,Customer_Project_Contact__c =con.id,Opportunity__c = oppr.id );
        insert PSPro;
        
        PS_Task__c  PsTask = new PS_Task__c(Task_Start_Date__c = system.today(),Task_Status__c='Not Started',Task_Type__c = 'Migration',
                                            Consult_Quantity__c = 1,Project__c = PSPro.Id,Task_End_date__c = system.today()+7,Account__c = acct.id,Billable_Hours_Expected__c = 40);
        insert PsTask;
        PsTask.Account__c = acct.Id;
        PsTask.Contact__c = con.Id;
        PsTask.Task_Status__c = 'Open';
        update PsTask;
    }
    static testmethod void test() {      
        PS_Task__c psTask = [SELECT id from PS_Task__c limit 1];
        Apexpages.standardcontroller sc = new Apexpages.standardcontroller(psTask);
        PSTAskInfoController psTaskController = new PSTAskInfoController(sc);
        psTaskController.saveandClose();
     }
}