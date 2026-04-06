@isTest
public class PSTaskExpiryNotificationTest {

    @testSetup static  void createdata(){
        
        List<TriggerControl__c> TriggerControlSetting =CustomTestDataFactory.TriggerControlSetting(true);
        List<Account> actlst = CustomTestDataFactory.createAccounts(1);
        List<Contact> cntlst = CustomTestDataFactory.createcont(actlst);
        List<PS_Project__c> projlst = CustomTestDataFactory.createPS_Project(cntlst, actlst);
        List<PS_Task__c> tasklst = CustomTestDataFactory.createPS_Task(projlst, actlst, 100);
        
    }
    
    public static testmethod void methodschedule(){
    
        Test.startTest();
            for(PS_Task__c pst : [SELECT ID, Task_Status__c, Actual_End_date__c, Task_End_date__c, Approved_Hours__c, Task_Type__c FROM PS_Task__c]){
                system.debug('Task_Status__c____'+pst.Task_Status__c +'___Actual_End_date__c___'+pst.Actual_End_date__c+ '___Task_End_date__c____'+pst.Task_End_date__c + '___Approved_Hours__c____'+pst.Approved_Hours__c+'___Approved_Hours__c'+pst.Approved_Hours__c + '_____Task_Type__c___'+pst.Task_Type__c);
            }
            PSTaskExpiryNotificationScheduler sh1 = new PSTaskExpiryNotificationScheduler();
        PSTaskExpiryNotificationBatch btch = new PSTaskExpiryNotificationBatch();
        btch.dummy();
            sh1.execute(null);
        Test.stopTest();
        
    }
}