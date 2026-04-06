@isTest
public class TaskHandler_Test {
        static testMethod void test() {
       List<WorkflowTriggerBypass__c> settings = new List<WorkflowTriggerBypass__c>();
       settings.add(new WorkflowTriggerBypass__c(Name='cnsFirstAttemptUpdateLeadStatus', ByPassTrigger__c = true));
       settings.add(new WorkflowTriggerBypass__c(Name='CreateSDRLedMeetingTask', ByPassTrigger__c = true));
       settings.add(new WorkflowTriggerBypass__c(Name='updateLastOwnershipUpdateDate', ByPassTrigger__c = true));
       settings.add(new WorkflowTriggerBypass__c(Name='leadReassignOnBusinessUnitChange', ByPassTrigger__c = true));
       settings.add(new WorkflowTriggerBypass__c(Name='updateOpportunitySource', ByPassTrigger__c = true));
       settings.add(new WorkflowTriggerBypass__c(Name='salesOperationInvokePatchManager', ByPassTrigger__c = true));
       settings.add(new WorkflowTriggerBypass__c(Name='salesOperationsAssignAccountSIC', ByPassTrigger__c = true));
       settings.add(new WorkflowTriggerBypass__c(Name='salesOperationsSetEUResident', ByPassTrigger__c = true));
       insert settings;
        Lead ld=TestDataFactory.insertLead();
        insert ld;
		List<Contact> conList = new List<contact>();
            for(Integer i=1;i<6;i++){
                Contact con = TestDataFactory.getContact();
        		con.Contact_Status__c ='Open';
				conList.add(con);
            }
        
		insert conList;
		Account accRec = TestDataFactory.getAccount();
        insert accRec;
        
        List<Deal_registration__c> dealLst=new List<Deal_registration__c>();
        dealLst.add(TestDataFactory.getDealRegistration());
        dealLst[0].Lead__c = ld.Id;
        dealLst[0].Primary__c = true;
        insert dealLst;
        
        List<Task> tskList=new List<Task>();
        for(Integer i=1;i<6;i++){
            Task t=new Task();
            t.WhoId=ld.id;
            t.Subject='PID Meeting';
            t.Activity_Type__c = 'Call';
            t.Status = 'Open';
            //t.Post_Meeting_Status__c='Convert to Opportunity';
           // t.Status='Completed';
            tskList.add(t);
        }
		Product2 pd = new Product2(Name='Pord B',ProductCode='Product123XYZ',isActive=true, Bundle_Features__c ='Appliance');
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
        Order ordr = new Order(Type='Revenue' ,  AccountId= accRec.Id,ShippingStreet ='Test Street',
                               ShippingCity ='Test City',
                               ShippingState ='California',
                               ShippingCountry ='United States',
                               ShippingPostalcode ='94820',
                               EffectiveDate=system.Today(), Order_Status__c = 'Order Accepted',Order_Accepted_Timestamp__c=system.today().addDays(-45) );
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
		Task taskRec = new Task();
        taskRec.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Polaris Fullfillment').getRecordTypeId();
		taskRec.WhoId = conList[0].Id;
		taskRec.WhatId = ordr.Id;
		taskRec.Subject='Email: Rubrik - Follow Up';
		taskRec.Activity_Type__c = 'Call';
        taskRec.SalesloftDisposition__c='Working - Left VM';
		tskList.add(taskRec);
        

		Task taskRec2 = new Task();
        taskRec2.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Polaris Fullfillment').getRecordTypeId();
		taskRec2.WhoId = conList[1].Id;
		taskRec2.WhatId = ordr.Id;
		taskRec2.Subject='Email: Rubrik - Follow Up';
		taskRec2.Activity_Type__c = 'Call';
		taskRec2.SalesloftDisposition__c='Working - Left VM';
		tskList.add(taskRec2);

		Task taskRec3 = new Task();
        taskRec3.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Polaris Fullfillment').getRecordTypeId();
		taskRec3.WhoId = conList[2].Id;
		taskRec3.WhatId = ordr.Id;
		taskRec3.Subject='Email: Rubrik - Follow Up';
		taskRec3.Activity_Type__c = 'Call';
		taskRec3.SalesloftDisposition__c='Working - Left VM';
		tskList.add(taskRec3);
		
		Task taskRec4 = new Task();
        taskRec4.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Polaris Fullfillment').getRecordTypeId();
		taskRec4.WhoId = conList[3].Id;
		taskRec4.WhatId = ordr.Id;
		taskRec4.Subject='Email: Rubrik - Follow Up';
		taskRec4.Activity_Type__c = 'Call';
		taskRec4.SalesloftDisposition__c='NQ - Partner/Reseller';
		tskList.add(taskRec4);
        
		Task taskRec5 = new Task();
        taskRec5.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Polaris Fullfillment').getRecordTypeId();
		taskRec5.WhoId = conList[4].Id;
		taskRec5.WhatId = ordr.Id;
		taskRec5.Subject='Email: Rubrik - Follow Up';
		taskRec5.Activity_Type__c = 'Call';
		taskRec5.SalesloftDisposition__c='NQ - Partner/Reseller';
		tskList.add(taskRec5);
            
        Test.startTest();
         insert tskList;
        //tskList[0].Did_meeting_happen__c = 'Yes';
        tskList[0].Post_Meeting_Status__c = 'Convert to Opportunity';
        tskList[0].Status='Completed';
		tskList[0].SalesloftDisposition__c='Working - Left VM';	
		tskList[1].SalesloftDisposition__c='NQ - No Potential';
        tskList[2].SalesloftDisposition__c='NQ - Bad Title';
		tskList[3].SalesloftDisposition__c='NQ - Bad Phone/Email';
        tskList[4].SalesloftDisposition__c='NQ - Partner/Reseller';
		tskList[5].SalesloftDisposition__c='NQ - Partner/Reseller';	
        tskList[6].SalesloftDisposition__c='NQ - No Potential';
		tskList[7].SalesloftDisposition__c='NQ - Bad Phone/Email';
        tskList[8].SalesloftDisposition__c='NQ - Bad Title';
		tskList[9].SalesloftDisposition__c ='Working - Left VM';
        update tskList;
        /*List<Deal_registration__c> dList=[select Deal_Registration_Status__c,id,Lead__c from Deal_registration__c where Lead__c=:ld.id];
        for(Deal_registration__c dr : dList) {
            system.assertEquals(dr.Deal_Registration_Status__c,'Approved');
        }*/
        
        
        Test.stopTest();
    }

   static testMethod void testTaskHandler(){
       Task tsk = new Task();
       TaskHandler tksHandler = new TaskHandler();
       tksHandler.bulkBefore(); 
       tksHandler.afterDelete(tsk); 
       tksHandler.beforeInsert(tsk);
       tksHandler.afterInsert(tsk);
       tksHandler.beforeUpdate(tsk, tsk);
       tksHandler.afterUpdate(tsk, tsk);
       tksHandler.beforeDelete(tsk);
       tksHandler.andFinally();
       tksHandler.forTestClass();
        
   }
    static testMethod void testSendTaskEmail(){
		Contact con = TestDataFactory.getContact();
        con.Contact_Status__c ='Open';
        insert con;
		List<Task> tskList = new List<Task>();
        Task taskRec = new Task();
        taskRec.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Polaris Fullfillment').getRecordTypeId();
		taskRec.WhoId = con.Id;
		//taskRec6.WhatId = ordr.Id;
		taskRec.Subject='Email: Rubrik - Follow Up';
		taskRec.Activity_Type__c = 'Call';
		taskRec.SalesloftDisposition__c='NQ - Partner/Reseller';
		tskList.add(taskRec);

        TaskObjectTriggerHelper.sendTaskEmail(tskList, null);
    }
}