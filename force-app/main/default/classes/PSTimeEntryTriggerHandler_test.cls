@isTest
public class PSTimeEntryTriggerHandler_test {
    @testSetup static void setup() {
         List<TriggerControl__c> TriggerCon = CustomTestDataFactory.TriggerControlSetting(true); 
        List<PS_Task__c> taskList = new List<PS_Task__c>();
        List<PS_SubTask__c> subtaskList = new List<PS_SubTask__c>(); 
        List<PS_Time_Entry__c> psoList = new List<PS_Time_Entry__c>();
          List<PS_Time_Entry__c> psoList1 = new List<PS_Time_Entry__c>();
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();   
        Account acc = new Account(name='test1239',RecordTypeId= devRecordTypeId);
        insert acc;
        update acc;
        Date closeDt = System.Today()+30;
        opportunity oppr = new opportunity(Name='testing DIEtestsalesforce 4/6/2015' ,  AccountId= acc.Id,StageName = '1 Discovery',
                                           CloseDate = closeDt, Lead_Email_Hidden__c='', partner_lookup__c=acc.id, Alliance_Source_Type__c='Alliance Initiated Deal', Installation_Assigned_To__c ='FE Install');
        insert oppr;
        update oppr;
        Order od2 = new Order();
        od2.AccountId = acc.Id;
        od2.OpportunityId =oppr.Id;
        od2.EffectiveDate = Date.Today();
        //od2.Status = 'PO Received';
        od2.Order_Status__c = 'PO Received';
        od2.ShippingStreet ='Test Street';
        od2.ShippingCity ='Test City';
        od2.ShippingState ='California';
        od2.ShippingCountry ='United States';
        od2.ShippingPostalcode ='94820';
        //od2.ship_To_Name__c=acc.id;
        od2.Shipping_Address_Label__c = null;
        insert od2;
        od2.Order_Status__c = 'Returned';
        update od2;
        PS_Project__c proj = new PS_Project__c(Account__c=acc.Id,Project_Status__c='Open');
        insert proj;
        update proj;
        PS_Task__c task1 = new PS_Task__c(Project__c=proj.Id,Task_Type__c='Install',Task_Status__c='Open');
        taskList.add(task1);
        PS_Task__c task2 = new PS_Task__c(Project__c=proj.Id,Task_Type__c='Consult',Task_Status__c='Open');
        taskList.add(task2);
        insert taskList;
        update  taskList;   
        PS_SubTask__c subTask1 = new PS_SubTask__c(PS_Assignee__c = userinfo.getUserId(), Task__c=task1.id,Task_Type__c='Install');
        subtaskList.add(subTask1);
        PS_SubTask__c subTask2 = new PS_SubTask__c(PS_Assignee__c = userinfo.getUserId(), Task__c=task2.Id,Task_Type__c='Consult');
        subtaskList.add(subTask2);  
        insert subtaskList;
        update subtaskList;
        PS_Time_Entry__c psot1 = new PS_Time_Entry__c(status__c= 'Approved',PS_SubTask__c = subTask1.id, PS_Task__c = task1.id,Time_Entry_Date__c=system.today().addDays(-2),Comments__c='hello');
        psoList.add(psot1);
        PS_Time_Entry__c psot2 = new PS_Time_Entry__c(PS_SubTask__c = subTask1.id, PS_Task__c = task1.id,Time_Entry_Date__c=system.today(),Comments__c='hello');
        psoList.add(psot2);
        PS_Time_Entry__c psot3 = new PS_Time_Entry__c(PS_SubTask__c = subTask1.id, PS_Task__c = task1.id,Time_Entry_Date__c=system.today().addDays(1),Comments__c='hello');
        psoList.add(psot3); 
        PS_Time_Entry__c psot4 = new PS_Time_Entry__c(PS_SubTask__c = subTask2.id, PS_Task__c = task2.id,Time_Entry_Date__c=system.today().addDays(-2),Comments__c='hello');
        psoList.add(psot4);
        PS_Time_Entry__c psot5 = new PS_Time_Entry__c(PS_SubTask__c = subTask2.id, PS_Task__c = task2.id,Time_Entry_Date__c=system.today(),Comments__c='hello');
        psoList.add(psot5);
        PS_Time_Entry__c psot6 = new PS_Time_Entry__c(PS_SubTask__c = subTask2.id, PS_Task__c = task2.id, Time_Entry_Date__c=system.today().addDays(1),Comments__c='hello');
        psoList.add(psot6); 
        insert psoList;
        update psoList; 
    /*   PS_Time_Entry__c psot12 = new PS_Time_Entry__c(PS_SubTask__c = subTask1.id, PS_Task__c = task1.id, Hours_Spent__c=2,Time_Entry_Date__c=system.today().addDays(-2),Comments__c='hello');
        psoList1.add(psot12);
        PS_Time_Entry__c psot22 = new PS_Time_Entry__c(PS_SubTask__c = subTask1.id, PS_Task__c = task1.id, Hours_Spent__c=3,Time_Entry_Date__c=system.today(),Comments__c='hello');
        psoList1.add(psot22);
        PS_Time_Entry__c psot32 = new PS_Time_Entry__c(PS_SubTask__c = subTask1.id, PS_Task__c = task1.id, Hours_Spent__c=4,Time_Entry_Date__c=system.today().addDays(1),Comments__c='hello');
        psoList1.add(psot32); 
        PS_Time_Entry__c psot42 = new PS_Time_Entry__c(PS_SubTask__c = subTask2.id, PS_Task__c = task2.id, Hours_Spent__c=1,Time_Entry_Date__c=system.today().addDays(-2),Comments__c='hello');
        psoList1.add(psot42);
        PS_Time_Entry__c psot52 = new PS_Time_Entry__c(PS_SubTask__c = subTask2.id, PS_Task__c = task2.id, Hours_Spent__c=3,Time_Entry_Date__c=system.today(),Comments__c='hello');
        psoList1.add(psot52);
        PS_Time_Entry__c psot62 = new PS_Time_Entry__c(PS_SubTask__c = subTask2.id, PS_Task__c = task2.id, Time_Entry_Date__c=system.today().addDays(1),Comments__c='hello');
        psoList1.add(psot62); 
        delete psoList1; */
    }
    
    public static testMethod void PSTimeEntryTriggerHandler() {
        Test.startTest();
        PS_Project__c proj1 = [select Id from PS_Project__c limit 1];
        List<Order> orderList = [select Id from Order];
        List<PS_Task__c> taskList = [select Id,Project__c,Name,Task_Type__c from PS_Task__c];
        List<PS_SubTask__c> subtakList = [select Id,Name,Task__c,Task_Type__c from PS_SubTask__c];  
        Test.StopTest();
    }
   
    
    
    
    
}