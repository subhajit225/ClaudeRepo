/********************************************************************************************************
* Name              : POLARIS_OrderFulfillmentTest 
* Purpose           : POLARIS_OrderFulfillmentTest is Used for Testing POLARIS_OrderFulfillment Class
*********************************************************************************************************/
@isTest
public class POLARIS_OrderFulfillmentTest {
    
    static void createTestData() {
        ShGl_TestFactoryHelper.insertCustomSettings();
		FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Name = 'System Administrator',Disable_SBQQ_Quote_Validation_Rules__c =true);
    	insert disableLogic;
        
        TriggerControl__c PortalUserCreation = new TriggerControl__c();
        PortalUserCreation.Name = 'PortalUserCreation';
        // PortalUserCreation.DisableTrigger__c = true;
        insert PortalUserCreation; 
        
        StateNameCode__c custset = new StateNameCode__c();
        custset.Name = 'California';
        custset.Code__c = 'US-CA';
        insert custset;
        
        Date closeDt = System.Today()+30;
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
        Account acct = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        acct.RecordTypeId = partnerRecordTypeId;
        insert acct;
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => acct.Id,
            'Email'  =>'leademail@hidden.com'
        };
        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);        
        insert cnt1;
        
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => acct.Id,
            'Initial_Contacts_Name__c' => cnt1.Id,
            'Primary_Competitor__c' => 'Other',
            'Other_Primary_Competitor__c' => 'Other',
            'Other_Competitor_Field__c' => 'Other',
            'Lost_To_Won_Against__c' => 'Other',
            'Polaris_Region__c' => 'US',
            'StageName' => '1 Discovery',
          'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId()
        };
        List<Opportunity> opptyList = (List<Opportunity>) ShGl_TestFactory.createSObjectList(new Opportunity(), 1, oppMap);
        insert opptyList;
        
        List<POC__c> pocList = new List<POC__c> ();
        POC__c poc1 = new POC__c();
        poc1.POC_Duration__c = '60 Days';//30 Days
        poc1.Planned_Installation_Date__c = closeDt;
        poc1.Support_Awareness_needed__c = 'Yes';
        poc1.POC_Type__c = 'Standard POC';
        pocList.add(poc1);
        
        POC__c poc2 = new POC__c();
        poc2.POC_Duration__c = '30 Days';//30 Days
        poc2.Planned_Installation_Date__c = closeDt;
        poc2.Support_Awareness_needed__c = 'Yes';
        poc2.POC_Type__c = 'Standard POC';
        pocList.add(poc2);
        
        insert pocList;
        
        List<Product2> prodlist = new List<Product2>();
        Map<String, Object>  prodMap = new Map<String, Object> {
            'Name' => 'Pord A',
            'ProductCode' => 'ProductXYZ',
            'isActive' => true,
            'Family' => 'POLARIS',
            'Product_Type__c' => 'Appliance'
        };
        Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);  
        prodlist.add(pd);
        
        Map<String, Object>  prodMap2 = new Map<String, Object> {
            'Name' => 'Pord B',
            'ProductCode' => 'ProductXYZ',
            'isActive' => true,
            'Family' => 'POLARIS',
            'Product_Type__c' => 'GPS'
        };
        Product2 pd2 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap2);  
        prodlist.add(pd2);
        
        Map<String, Object>  prodMap3 = new Map<String, Object> {
            'Name' => 'Pord C',
            'ProductCode' => 'ProductXYZ',
            'isActive' => true,
            'Family' => 'POLARIS',
            'Product_Type__c' => 'RADAR'
        };
        Product2 pd3 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap3);  
        prodlist.add(pd3);
        
        insert prodlist;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        Map<String, Object>  quoteMap = new Map<String, Object> {
            'SBQQ__Account__c' => acct.Id,
            'SBQQ__Opportunity2__c' => opptyList[0].Id
        };
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = opptyList[0].Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__PriceBook__c = pricebookId;
        insert qt1;

        qt1.ApprovalStatus__c = 'Approved';
        update qt1;
        
        //opptyList[0].Deal_Registration_Link__c = objlead.Id;
        opptyList[0].Partner_Lookup__c = acct.Id; 
        opptyList[0].pricebook2Id = pricebookId;
        //opptyList[0].StageName = System.Label.Order_Creation_Stage;
        opptyList[0].Partner_Level_Of_Involvement__c = '4.Partner or joint initiated opportunity, partner brought substantial value in sales cycle and getting deal closed';
        opptyList[0].SBQQ__PrimaryQuote__c = qt1.Id;
        opptyList[0].Installation_Assigned_To__c = 'Partner Install';
        update opptyList;
        
        List<order> listorder = new List<order>();
        Order od = new Order();
        od.Status = 'Draft';
        od.AccountId = acct.Id;
        od.OpportunityId =opptyList[0].Id;
        od.EffectiveDate = Date.Today();
        od.ShippingStreet ='Test Street';
        od.ShippingCity ='Test City';
        od.ShippingState ='California';
        od.ShippingCountry ='United States';
        od.ShippingPostalcode ='94820';
        //od.ship_To_Name__c=acct.id;
        od.Type = 'POC';
        od.Est_Ship_Date__c = system.today();
        od.Order_Status__c = 'Pending';
        od.Hold_Code__c = 'Missing ship to information';
        //od.Hold_Code__c = 'Delayed Ship Date';
        od.POC_Request__c = pocList[1].id;
        od.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId();
        od.Pricebook2Id = pricebookId;
        listorder.add(od);
        
        Order od2 = new Order();
        od2.Status = 'Draft';
        od2.AccountId = acct.Id;
        od2.OpportunityId =opptyList[0].Id;
        od2.EffectiveDate = Date.Today();
        od2.ShippingStreet ='Test Streett';
        od2.ShippingCity ='Test Cityy';
        od2.ShippingState ='California';
        od2.ShippingCountry ='United States';
        od2.ShippingPostalcode ='94820';
        //od2.ship_To_Name__c=acct.id;
        od2.Pricebook2Id = pricebookId;
        od2.Est_Ship_Date__c = system.today();
        od2.Type = 'Revenue';
        //od2.POC_Request__c = pocobj2.id;
        od2.Order_Status__c = 'Pending';
        od2.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Revenue Order').getRecordTypeId();
        listorder.add(od2);
        
        Order od3 = new Order();
        od3.Status = 'Draft';
        od3.AccountId = acct.Id;
        od3.OpportunityId =opptyList[0].Id;
        od3.EffectiveDate = Date.Today();
        od3.ShippingStreet ='Test Street';
        od3.ShippingCity ='Test City';
        od3.ShippingState ='California';
        od3.ShippingCountry ='United States';
        od3.ShippingPostalcode ='94820';
        od3.Pricebook2Id = pricebookId;
        //od3.ship_To_Name__c=acct.id;
        od3.Type = 'Revenue';
        od3.POC_Request__c = pocList[0].id;
        od3.Order_Status__c='Pending';
        od3.Original_Est_Ship_Date__c = date.today()+30;
        //od3.Order_Sub_Type__c = 'Renewal';
        listorder.add(od3);
        Order od4 = new Order();
        od4.Status = 'Draft';
        od4.AccountId = acct.Id;
        od4.OpportunityId =opptyList[0].Id;
        od4.EffectiveDate = Date.Today();
        od4.ShippingStreet ='Test Street';
        od4.ShippingCity ='Test City';
        od4.ShippingState ='California';
        od4.ShippingCountry ='United States';
        od4.ShippingPostalcode ='94820';
        //od4.ship_To_Name__c=acct.id;
        od4.Type = 'POC';
        od4.POC_Request__c = pocList[0].id;
        od4.Pricebook2Id = pricebookId;
        listorder.add(od4);
  
        insert listorder;
        
        List<Order> ordList = [SELECT Id, Pricebook2Id FROM Order];
        for(Order ord : ordList) {
            ord.Pricebook2Id = pricebookId;
        }
        update ordList;
          
        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prodlist[0].Id, UnitPrice = 100.00, IsActive = true );
        insert pbEntry;
        
        List<OrderItem> OrderItemlist = new List<OrderItem>();
        
        OrderItem oitem1 = new OrderItem();
        oitem1.product2Id = prodlist[0].id;
        oitem1.orderid = listorder[0].id;
        oitem1.Quantity = 2;
        oitem1.PricebookEntryId = pbEntry.id;
        oitem1.UnitPrice = pbEntry.UnitPrice;
        OrderItemlist.add(oitem1);
        
        OrderItem oitem2 = new OrderItem();
        oitem2.product2Id = prodlist[0].id;
        oitem2.orderid = listorder[1].id;
        oitem2.Quantity = 2;
        oitem2.PricebookEntryId = pbEntry.id;
        oitem2.UnitPrice = pbEntry.UnitPrice;
        OrderItemlist.add(oitem2);
        
        insert OrderItemlist;       
		//FlowControll.AccountTrigger = true;
        //FlowControll.opportunityTriggerHandler = true;
        
    }  
    
    public static testMethod void polaristask() {
        createTestData();
        opportunity opp = [SELECT Id,StageName from opportunity limit 1];
        
        List<order> ord = [SELECT Id,type,Order_Status__c,POC_Request__c,OpportunityId,Order_Sub_Type__c,Est_Ship_Date__c,AccountId FROM order ]; //where opportunityid=:opp.id and POC_Request__r.POC_Duration__c = '7 Days'];

        Test.startTest();
        
        Map<Id, Order> oldOrderMap = new Map<Id, Order>();
        for(Order od : ord) {
            oldOrderMap.put(od.Id, od);  
        }
        
        for(Order od : ord) {
            if(od.Type == 'Revenue') {
                od.Order_Status__c = 'Order Accepted';
            } else {
                od.Order_Status__c = 'Pending';
            }
            
            od.Est_Ship_Date__c = system.today()+9;
        }
        
        Map<Id, Task> accIdTsksMap = new Map<Id, Task>();
        POLARIS_OrderFulfillment.createTaskOnOrderActivation(null,null,null);
        POLARIS_OrderFulfillment.createTaskOnOrderActivation(ord,oldOrderMap,accIdTsksMap);
        POLARIS_OrderFulfillment.updateExistingTask(ord,oldOrderMap);
        //POLARIS_OrderFulfillment.checkTaskComplete(ord,oldOrderMap); 
        
        list<Task> tasklist = new list<Task>();
        
        Task t1 = new Task();
        t1.Subject = system.label.Polaris_Task_Subject_Activation;
        t1.WhatId = ord[2].id;
        //t1.Order_Number__c = ord[2].id;
        tasklist.add(t1);
        
        Task t2 = new Task();
        t2.Subject = system.label.Polaris_Task_Subject_Activation;
        t2.WhatId = ord[3].id;
        //t2.Order_Number__c = ord[3].id;
        tasklist.add(t2);
        
        insert tasklist ;
        
        for(order od : ord) {
            od.Hold_Code__c = '';
            od.Order_Status__c = 'Pending';             
        }
        update ord;
        
        Map<Id, Order> oldOrderMap2 = new Map<Id, Order>();
        List<Order> ord2 = [SELECT Id, Type, Order_Status__c, POC_Request__c, OpportunityId, Order_Sub_Type__c, Est_Ship_Date__c, AccountId FROM Order ]; 
        for(Order od : ord2){
            oldOrderMap2.put(od.Id, od);  
        }
        
        for(Order od : ord2) {
            if(od.Type == 'Revenue') {
                od.Order_Status__c = 'Order Accepted';
            } else {
                od.Order_Status__c = 'Pending';
            }            
            od.Est_Ship_Date__c = system.today()+11; 
        }
        
        List<Task> tasklst = [SELECT Id, WhatId, Subject FROM Task limit 1];
        
        for(Task tk : tasklst) {
            accIdTsksMap.put(ord2[0].AccountId, tk);
        }
        
        POLARIS_OrderFulfillment.createTaskOnOrderActivation(ord2,oldOrderMap2,accIdTsksMap);
        
        for(Order od : ord2) {
            od.Order_Status__c = 'Shipped'; 
        }
        //POLARIS_OrderFulfillment.checkTaskComplete(ord2,oldOrderMap2);
        
        Test.stopTest();
        
    }
}