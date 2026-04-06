@isTest
public class PSTaskNetSuiteStatusUpdate_test {
    
// MKT23-889 Development//
      @testSetup static void setup() {
        FlowControll.opportunityTriggerHandler = false;
        FlowControll.AccountTrigger=false;
        Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account acct = new Account(Name='testAccount',recordtypeId = partner);
        insert acct;
        Contact con  = new Contact(LastName = 'testContact', AccountId = acct.id);
        insert con;
        
        Date closeDt = System.Today()+30;
        Opportunity oppr = TestDataFactory.getOpportunity(acct);
        oppr.ContactId = con.id;
        oppr.StageName = '1 Discovery';
        oppr.CloseDate = closeDt;
        oppr.Lead_Email_Hidden__c='';
        oppr.Partner_Lookup__c =acct.id;
        oppr.Alliance_Partner_Name__c='Amazon';
        oppr.Alliance_Source_Type__c='Alliance Initiated Deal';
        insert oppr;
        Product2 pd = new Product2(Name='Pord B',ProductCode='Product123XYZ',isActive=true);
        pd.IsActive = true;
        insert pd;

 // Pricebook2  standardPb = [select id, name, isActive from Pricebook2 where IsStandard = true limit 1];
     Id pricebookId = Test.getStandardPricebookId();
//Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = pd.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry;
     Order ordr = new Order(Type='Revenue' ,  AccountId= acct.Id,OpportunityId =oppr.Id,ShippingStreet ='Test Street',
                            ShippingCity ='Test City',
                            ShippingState ='California',
                            ShippingCountry ='United States',
                            ShippingPostalcode ='94820',
                            EffectiveDate=system.Today(), Status = 'Draft', Order_Status__c = 'Order Accepted',Order_Accepted_Timestamp__c=system.today().addDays(-45) );
     insert ordr;
     Order od = [ SELECT Id,Pricebook2Id FROM Order where id=:ordr.id LIMIT 1 ];
     od.Pricebook2Id = pricebookId;
     update od;
     List<OrderItem> ordItemList = new List<OrderItem>();
     OrderItem oli1 = new OrderItem(
            OrderId = od.Id,
            Quantity = 5,
            Product2Id =  pd.Id,
            PricebookEntryId = pbEntry.Id,
            UnitPrice = 100,
            SerialNumber__c = 'Test1234567Asset2',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
     ordItemList.add(oli1);
     OrderItem oli2 = new OrderItem(
            OrderId = od.Id,
            Quantity = 5,
            Product2Id =  pd.Id,
            PricebookEntryId = pbEntry.Id,
            UnitPrice = 200,
            SerialNumber__c = 'Test1234567Asset2',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
     ordItemList.add(oli2);
     insert ordItemList;
     Test.startTest();
       PS_Project__c projInst = new PS_Project__c();
       projInst.Name = 'test project';
       insert projInst;
        Test.stopTest();
       
    }
 
 
 public static testmethod void Ps_TaskTriggerTestMethod(){
    
        Contact con = [select id from contact LIMIT 1];
        Opportunity oppr = [select id from Opportunity LIMIT 1];
        Account acct = [select id from Account LIMIT 1];
        PS_Project__c PSPro = new PS_Project__c(Account__c = acct.id,Name = 'test Pro',Welcome_Letter_Contact__c = con.id,Customer_Project_Contact__c =con.id,Opportunity__c = oppr.id );
        insert PSPro;
        
        PSPro.Name='test PRO (1)';
        update PSPro;
        PS_Task__c  PsTask = new PS_Task__c(Task_Start_Date__c = system.today(),Task_Status__c='Open',Task_Type__c = 'Resident Engineer',
                                            Consult_Quantity__c = 1,Project__c = PSPro.Id,Task_End_date__c = system.today()+7,Account__c = acct.id,Billable_Hours_Expected__c = 40);
        insert PsTask;
        PS_Task__c  PsTask2 = new PS_Task__c(Task_Status__c='Open',Task_Type__c =  'Consult-Remote',
                                             Consult_Quantity__c = 1,Project__c = PSPro.Id,Task_End_date__c = system.today()+7,Account__c = acct.id,Billable_Hours_Expected__c = 40);
        insert PsTask2;
        PS_Task__c  PsTask1 = new PS_Task__c(Task_Start_Date__c = system.today(),Task_Status__c='Open',Task_Type__c = 'T&E',
                                             Consult_Quantity__c = 1,Project__c = PSPro.Id,Task_End_date__c = system.today()+7,Account__c = acct.id,Billable_Hours_Expected__c = 40);
        insert PsTask1;
        PS_Task__c  PsTask4 = new PS_Task__c(Task_Start_Date__c = system.today(),Task_Status__c='Not Started',Task_Type__c = 'Migration', Contact__c = con.Id,
                                             Consult_Quantity__c = 1,Project__c = PSPro.Id,Task_End_date__c = system.today()+7,Account__c = acct.id,Billable_Hours_Expected__c = 40);
        insert PsTask4;
        
        PsTask1.Task_Type__c ='Consult';
        update PsTask1; 
        List<Id> orderIds1 = new List<Id>();
        List<Id> taskIds1 = new List<Id>();
        List<OrderItem> orditemList = [select Id from OrderItem];
        List<PS_Project__c> proj = [SELECT Id FROM PS_Project__c LIMIT 1];
        set<id> TaskIds = new set<id>();
        PS_Task__c taskInst = new PS_Task__c();
        taskInst.Project__c = proj[0].Id;
        //taskInst.Order_Item__c = orditemList[0].Id;
        //insert taskInst;
        //taskInst.Order_Item__c = orditemList[1].Id;
        //update taskInst; 
        //TaskIds.add(taskInst.Id);
        TaskIds.add(PsTask4.Id);
        PS_TaskTriggerHelper.createCases(TaskIds);
        PS_TaskTriggerHelper.updateRelatedPSTask(orderIds1,taskIds1);
        delete  PsTask1;
		
		Test.startTest();
            Database.executeBatch(new PSTaskNetSuiteStatusUpdate());
        Test.stopTest();
        
    }
	
	 @isTest static void testScheduler(){
        Test.startTest();
            String sch = '0 0 23 * * ?'; 
            system.schedule('Test Lead Inactivation Check', sch, new PSTaskNetSuiteStatusUpdate()); 
        Test.stopTest(); 
    }
	
}