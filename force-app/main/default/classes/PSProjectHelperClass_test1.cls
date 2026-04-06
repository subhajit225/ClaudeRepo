@isTest
public class PSProjectHelperClass_test1 {
    @testSetup static  void Createrecord(){
        List<TriggerControl__c> TriggerControlSetting = CustomTestDataFactory.TriggerControlSetting(false);    
        insert new TriggerControl__c(Name='Order', DisableTrigger__c=true);
        SBQQ.TriggerControl.disable();

        List<Account> actlst                          = CustomTestDataFactory.createAccounts(1);
        List<Contact> cntlst                          = CustomTestDataFactory.createcont(actlst);
        List<Opportunity> opplst                      = CustomTestDataFactory.createOpp(actlst, cntlst);  
        List<OpportunityContactRole> Ocr              = CustomTestDataFactory.createOpportunityContactRole(cntlst,opplst); 
        List<PS_Project__c> Pspro1                    = CustomTestDataFactory.createPS_Projectwithopp(opplst,cntlst,actlst);
        List<Order> ordlst                            = CustomTestDataFactory.testorderPoc(actlst,opplst,Pspro1);
        List<Product2> Product2                      = CustomTestDataFactory.ALLPRODUCT(ordlst);
        List<PS_Task__c> PStask3                      = CustomTestDataFactory.createPS_Task1(Pspro1,actlst);
        
        Id pricebookId = Test.getStandardPricebookId();
        list<PricebookEntry> PbEntryInserted = new list<PricebookEntry>();
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = Product2[0].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        PbEntryInserted.add(pbEntry);
        
        PricebookEntry pbEntry1 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = Product2[1].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
         PbEntryInserted.add(pbEntry1);
        
          PricebookEntry pbEntry2 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = Product2[2].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
         PbEntryInserted.add(pbEntry2);
        
        PricebookEntry pbEntry3 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = Product2[3].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
         PbEntryInserted.add(pbEntry3);
        
        PricebookEntry pbEntry4 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = Product2[4].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
         PbEntryInserted.add(pbEntry4); 
        
         PricebookEntry pbEntry5 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = Product2[5].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
         PbEntryInserted.add(pbEntry5);
        
         PricebookEntry pbEntry6 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = Product2[6].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        PbEntryInserted.add(pbEntry6);
        
           PricebookEntry pbEntry7 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = Product2[7].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
         PbEntryInserted.add(pbEntry7); 
        
         PricebookEntry pbEntry8 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = Product2[8].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
         PbEntryInserted.add(pbEntry8);
        
         PricebookEntry pbEntry9 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = Product2[9].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
         PbEntryInserted.add(pbEntry9);
        
        insert PbEntryInserted;
        
        
        List<Order> odList = [ SELECT Id,Pricebook2Id FROM Order];
        for(Order od : odList) od.Pricebook2Id = pricebookId;
        update odList;
        
        List<OrderItem> ordItemList = new List<OrderItem>();
        OrderItem oli = new OrderItem(
            OrderId = ordlst[0].Id,
            Quantity = 5,
            Product2Id =  Product2[0].Id,
            PricebookEntryId = PbEntryInserted[0].Id,
            UnitPrice = 100,
            SerialNumber__c = 'Test1234567Asset2',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        ordItemList.add(oli);
        
        OrderItem oli1 = new OrderItem(
            OrderId = ordlst[1].Id,
            Quantity = 4,
            Product2Id =  Product2[1].Id,
            PricebookEntryId = PbEntryInserted[1].Id,
            UnitPrice = 100,
            SerialNumber__c = 'Test1234567Asset21111',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        ordItemList.add(oli1);  
        
        OrderItem oli2 = new OrderItem(
            OrderId = ordlst[2].Id,
            Quantity = 3,
            Product2Id =  Product2[2].Id,
            PricebookEntryId = PbEntryInserted[2].Id,
            UnitPrice = 100,
            SerialNumber__c = 'Test1234567Asset2456',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        ordItemList.add(oli2); 
        
           OrderItem oli3 = new OrderItem(
            OrderId = ordlst[3].Id,
            Quantity = 12,
            Product2Id =  Product2[4].Id,
            PricebookEntryId = PbEntryInserted[4].Id,
            UnitPrice = 100,
            SerialNumber__c = 'Test1234567Asset2',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
         ordItemList.add(oli3);
        
         OrderItem oli4 = new OrderItem(
            OrderId = ordlst[4].Id,
            Quantity = 5,
            Product2Id =  Product2[5].Id,
            PricebookEntryId = PbEntryInserted[5].Id,
            UnitPrice = 100,
            SerialNumber__c = 'Test1234567Asset2',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
         ordItemList.add(oli4); 
        
         OrderItem oli5 = new OrderItem(
            OrderId = ordlst[5].Id,
            Quantity = 5,
            Product2Id =  Product2[6].Id,
            PricebookEntryId = PbEntryInserted[6].Id,
            UnitPrice = 100,
            SerialNumber__c = 'Test1234567Asset2',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
         ordItemList.add(oli5); 
        
       /*    OrderItem oli6 = new OrderItem(
            OrderId = ordlst[6].Id,
            Quantity = 5,
            Product2Id =  Product2[3].Id,
            PricebookEntryId = PbEntryInserted[3].Id,
            UnitPrice = 100,
            SerialNumber__c = 'Test1234567Asset2',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
         ordItemList.add(oli6);  
        
          OrderItem oli7 = new OrderItem(
            OrderId = ordlst[7].Id,
            Quantity = 5,
            Product2Id =  Product2[7].Id,
            PricebookEntryId = PbEntryInserted[7].Id,
            UnitPrice = 100,
            SerialNumber__c = 'Test1234567Asset2',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
         ordItemList.add(oli7); 
        
         OrderItem oli8 = new OrderItem(
            OrderId = ordlst[8].Id,
            Quantity = 5,
            Product2Id =  Product2[8].Id,
            PricebookEntryId = PbEntryInserted[8].Id,
            UnitPrice = 100,
            SerialNumber__c = 'Test1234567Asset2',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
         ordItemList.add(oli8); */
        
      OrderItem oli9 = new OrderItem(
            OrderId = ordlst[9].Id,
            Quantity = 5,
            Product2Id =  Product2[9].Id,
            PricebookEntryId = PbEntryInserted[9].Id,
            UnitPrice = 100,
            SerialNumber__c = 'Test1234567Asset2',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        Asana_PS_Configuration__c apc = new Asana_PS_Configuration__c();
            apc.SKU__c = Product2[0].Name;
            apc.Task_Label__c = 'Remote';
            apc.Task_Type__c = 'Consulting';
            apc.Is_PS_SKU__c = true;
            apc.Quantity_or_Subscription__c = 'Quantity';
            apc.Asana_Section_template_Id__c = '123389';
            insert apc;
            
         ordItemList.add(oli9);
        
        insert ordItemList;  
    } 
    
    
    public static testmethod void methodINSTALL1(){
        Test.startTest();
        List<Order> orderList                = [select Id, Name,TotalAmount, AccountId, Account.Name, Account.BillingState, 
                                                Account.BillingCountry, Account_Billing_Address_Region__c, OpportunityId, Opportunity.Name,
                                                OrderNumber,Order_Status__c,Status, PS_Project__c, PoNumber, Welcome_Letter_Contact__c
                                                FROM Order];
        PSProjectHelperClass.createPSProject(orderList);
        Test.stopTest();
    }
    
    
    public static testmethod void methodINSTALL2(){
        Test.startTest();
        Boolean createBillablesubtask = true;
        Set<Id> OrdIDs                       = new Set<Id>();
        for(order ord:[Select Id from order]){
            OrdIDs.add(ord.Id);
        }
        PSProjectHelperClass.createPSProjectWithRelatedRecords(OrdIDs,createBillablesubtask);
        Test.stopTest();
    }
    
    
    public static testmethod void methodINSTALL3(){
        Test.startTest();
        Map<Id, Id> psOldProjectVsNewProject = new Map<Id, Id>();
        for(PS_Task__c tsk :[select Id, Name, Project__c from PS_Task__c]){
            psOldProjectVsNewProject.put(tsk.Project__c,tsk.Project__c);
        }
        PSProjectHelperClass.updatePSTaskOnProjectUpdate(psOldProjectVsNewProject);
        Test.stopTest();
    }
    
    
    public static testmethod void methodINSTALL4(){
        Test.startTest();
        Boolean allowAdminSubTaskCreation;
        Set<Id> projectIdSet                 = new Set<Id>();
        for(PS_Project__c project :[select Id, name, Account__c,RecordType.DeveloperName FROM PS_Project__c]){
            projectIdSet.add(project.id);
        }
        PSProjectHelperClass.createAdminTaskSubtaskRecords(projectIdSet,allowAdminSubTaskCreation);
        Test.stopTest(); 
    }
    
}