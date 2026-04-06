@isTest(SeeAllData=true)
private class GenerateEntitlementsForPOCOrders_Test {

	@isTest static void test_method_one() {
		FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account acct = new Account(
            Name = 'Test Account',
            Phone = '123-456-7890',
            AccountNumber='Test',
            BillingStreet = '123 street',
            BillingCity = 'Santa Clara',
            BillingState = 'California',
            BillingPostalCode = '95050',
            BillingCountry = 'United States',
            ShippingStreet = '123 street',
            ShippingCity = 'Santa Clara',
            ShippingState = 'California',
            ShippingPostalCode = '95050',
            ShippingCountry = 'United States',
            RecordTypeId = partner
        );
        insert acct;

        OpportunityStage stage = [SELECT MasterLabel FROM OpportunityStage WHERE IsWon = false AND IsClosed = false AND isActive = true LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acct.Id,
            StageName = stage.MasterLabel,
            CloseDate = System.today().addDays(15),
            PriceBook2Id = Test.getStandardPricebookId(),
            SBQQ__QuotePricebookId__c = Test.getStandardPricebookId(),
            Alliance_Partner_Name__c = 'Amazon',
            Alliance_Source_Type__c = 'Alliance Initiated Deal',
            Compelling_Bus_Driver__c = 'Instant Recovery',
            Current_State__c = 'test',
            Negative_Consequences__c = 'test',
            Future_State__c = 'test',
            Positive_Business_Outcomes__c = 'test',
            Distributor_Lookup__c = acct.Id,
            Partner_Lookup__c = acct.Id,
            Opportunity_Sub_Type__c = 'MSP',
            Opportunity_Type__c = 'New Customer',
            Rubrik_Sales_Engineer__c = UserInfo.getUserId(),
            Win_Loss_Comments__c = 'test',
            Primary_Competitor__c = 'Actifio',
            Key_Feature_Needs__c = 'None',
            Deal_Impact__c = 'Deal Blocker',
            Valooto_Quote__c = '123123123',
            Valooto_Quote_Stage__c = 'Approved',
            Partner_Level_Of_Involvement__c = '1.Rubrik initiated, Partner was fulfillment only'
        );
        insert opp;
       
        POC__c pocRequest = new POC__c();
        PageReference ref = new PageReference('/apex/POCRequestForm?id=' + opp.Id);
        Test.setCurrentPage(ref);

        ApexPages.StandardController stdController = new ApexPages.StandardController(opp);
        POCRequestFormController controller = new POCRequestFormController(stdController);

        System.assertNotEquals(null, controller.mainProduct);
        System.assertNotEquals(null, controller.mainProductJsonStr);
        System.assertNotEquals(null, controller.subProduct);
        System.assertEquals(null, controller.selectedMainProduct);
        System.assertEquals(null, controller.selectedSubProduct);
        System.assertNotEquals(null, controller.productMap);
        System.assertNotEquals(null, controller.productPicker);
        System.assertNotEquals(null, controller.productMapSrlz);
        System.assertNotEquals(null, controller.productPickerSrlz);
        System.assertNotEquals(null, controller.skipLockFields);
        //System.assertNotEquals(null, controller.getFields);

        POC__c poc = controller.poc;
        System.assertNotEquals(null, poc);

        Map<String, Object> productPicker = new Map<String, Object>();
        Map<String, Object> params = new Map<String, Object>();

        productPicker.put('accessories', '[{"codeValue":"--None--","qtyValue":""}]');
        productPicker.put('encryption', 'Yes');
        productPicker.put('polaris', 'No');
        productPicker.put('productFamily', 'r300');
        productPicker.put('requestedProduct', 'R344');
        productPicker.put('subscriptions', '[{"sbscrValue":"--None--","optionValue":"--None--","qtyValue":"1"}]');
        productPicker.put('swithType', '10GbE SFP+');

        poc.Planned_Installation_Date__c = Date.today().addDays(8);
        poc.POC_Type__c = 'Standard POC';
        poc.POC_Duration__c = '15';
        poc.POC_Relocation__c = 'No';
        poc.POC_Justification__c = 'test';
        poc.Ranger_Support_Expected__c = true;

        poc.Ship_To_Country__c = 'United States';
        poc.Shipping_Street__c = 'test';
        poc.Shipping_State__c = 'CA';
        poc.Shipping_Zip_Postal_Code__c = '2000';
        poc.Shipping_City__c = 'San Francisco';

        poc.Shipping_Company_Name__c = opp.AccountId;
        poc.Shipping_Contact__c = 'test';
        poc.Shipping_Contact_Email__c = 'test@test.cc';
        poc.Shipping_Contact_Phone__c = '12312332';
        poc.Manual_POC_Agreement__c = true;
        poc.Conditional_PO_Submitted__c = false;
        poc.MNDA_Signed__c = true;
        poc.POC_Qty__c = 1;

        poc.Support_Awareness_needed__c = 'Yes';
        poc.Total_VM_count__c = 200;
        poc.Largest_VM_size__c = 200;
        poc.Largest_disk_size_VMDK__c = 200;
        poc.Data_encrypted__c = 'Yes';
        poc.Compression__c = 'Yes';
        poc.Deduplication__c = 'Yes';
        poc.Oracle__c = 'Yes';
        poc.Largest_Oracle_database_size__c = 10;
        poc.MSSQL_Type__c = 'Standalone';
        poc.MSSQL__c = 'Yes';
        poc.Physical_Hosts__c = 'Yes';
        poc.Number_of_MSSQL_databases_per_host__c = 10;
        poc.Largest_MSSQL_Database__c = 10;
        poc.Exchange__c = 'Yes';
        poc.Large_Exchange_database__c = 15;
        poc.Archival_CloudOut__c = 'Yes';
        poc.Archival_make__c = 'default';
        poc.Archival_model__c = 'test';
        poc.Archival_bandwidth_available__c = 1000;
        poc.Largest_fileset_in_capacity__c = 1000;
        poc.Large_fileset_in_number_of_files__c = 255;
        poc.Physical_servers__c = 10;
        poc.Bandwidth_for_Replication__c = 1000;
        poc.Replication__c = 'Yes';

        poc.AWS_Customer_Account_Id__c = '123123123';
        poc.AWS_Customer_Account_Region__c = 'us-east-1';

        poc.Try_Buy_Agreement__c = true;

        poc.Partner_Disty_Signed_POC_Addendum__c = 'Yes';
        poc.Disty_with_Signed_POC_Addendum__c = opp.AccountId;
        poc.Other_Accessories__c = 'test';


        POCRequestFormController.POCRequest pr = POCRequestFormController.evaluatePOC(poc, productPicker, params);
        System.assertEquals(true, pr.isSuccess);
        //String pocStr = POCRequestFormController.validateOpportunity(opp.id);
        //System.assertEquals(true, pr.isSuccess);

        boolean bVar = POCRequestFormController.isNumeric('4');
        System.assertNotEquals(null, controller.cancel());

        Test.startTest();
        POC__c newPOC = [SELECT Id FROM POC__c WHERE Id = :pr.pocRequest.Id LIMIT 1];
        newPOC.Approval_Status__c = 'Approved';
        update newPOC;

        Order ord = [Select Id from Order where POC_Opportunity__c=:opp.Id];
        System.assertNotEquals(null, ord);

        Asset ast = [Select Id, Name from Asset LIMIT 1];
        
        List<OrderItem> orderLines = [Select Id from OrderItem where OrderId = :ord.Id];
        for(OrderItem line: orderLines){
        	line.SerialNumber__c = ast.Name;
        }
        update orderLines;

        ord.Order_Status__c = 'Shipped';
        ord.Actual_Order_Ship_Date__c = Date.today();
        update ord;

        
        //ord.Order_Status__c = 'Order Accepted';
        //update ord;

        //ord.Order_Status__c = 'Shipped';
        //update ord;

        //List<Entitlement> entitlements = [Select Id from Entitlement where Order_Service_Item__r.OrderId = :ord.Id];
        
        //System.assertNotEquals(null, entitlements);
        Test.stopTest();
	}

	@isTest static void test_method_two() {
		FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
    
        Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account acct = new Account(
            Name = 'Test Account',
            Phone = '123-456-7890',
            AccountNumber='Test',
            BillingStreet = '123 street',
            BillingCity = 'Santa Clara',
            BillingState = 'California',
            BillingPostalCode = '95050',
            BillingCountry = 'United States',
            ShippingStreet = '123 street',
            ShippingCity = 'Santa Clara',
            ShippingState = 'California',
            ShippingPostalCode = '95050',
            ShippingCountry = 'United States',
            RecordTypeId = partner
        );
        insert acct;

        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acct.Id,
            StageName = '1 Discovery',
            CloseDate = System.today().addDays(15),
            PriceBook2Id = Test.getStandardPricebookId(),
            SBQQ__QuotePricebookId__c = Test.getStandardPricebookId(),
            Alliance_Partner_Name__c = 'Amazon',
            Alliance_Source_Type__c = 'Alliance Initiated Deal',
            Compelling_Bus_Driver__c = 'Instant Recovery',
            Current_State__c = 'test',
            Negative_Consequences__c = 'test',
            Future_State__c = 'test',
            Positive_Business_Outcomes__c = 'test',
            Distributor_Lookup__c = acct.Id,
            Partner_Lookup__c = acct.Id,
            Opportunity_Sub_Type__c = 'MSP',
            Opportunity_Type__c = 'New Customer',
            Rubrik_Sales_Engineer__c = UserInfo.getUserId(),
            Win_Loss_Comments__c = 'test',
            Primary_Competitor__c = 'Actifio',
            Key_Feature_Needs__c = 'None',
            Deal_Impact__c = 'Deal Blocker',
            Valooto_Quote__c = '123123123',
            Valooto_Quote_Stage__c = 'Approved',
            Partner_Level_Of_Involvement__c = '1.Rubrik initiated, Partner was fulfillment only'
        );
        insert opp;

        POC__c pocRequest = new POC__c();
        PageReference ref = new PageReference('/apex/POCRequestForm?id=' + opp.Id);
        Test.setCurrentPage(ref);

        ApexPages.StandardController stdController = new ApexPages.StandardController(opp);
        POCRequestFormController controller = new POCRequestFormController(stdController);

        System.assertNotEquals(null, controller.mainProduct);
        System.assertNotEquals(null, controller.mainProductJsonStr);
        System.assertNotEquals(null, controller.subProduct);
        System.assertEquals(null, controller.selectedMainProduct);
        System.assertEquals(null, controller.selectedSubProduct);
        System.assertNotEquals(null, controller.productMap);
        System.assertNotEquals(null, controller.productPicker);
        System.assertNotEquals(null, controller.productMapSrlz);
        System.assertNotEquals(null, controller.productPickerSrlz);
        System.assertNotEquals(null, controller.skipLockFields);
        //System.assertNotEquals(null, controller.getFields);

        POC__c poc = controller.poc;
        System.assertNotEquals(null, poc);

        Map<String, Object> productPicker = new Map<String, Object>();
        Map<String, Object> params = new Map<String, Object>();

        productPicker.put('accessories', '[{"codeValue":"--None--","qtyValue":""}]');
        productPicker.put('encryption', 'Yes');
        productPicker.put('polaris', 'No');
        productPicker.put('productFamily', 'r300');
        productPicker.put('requestedProduct', 'R344');
        productPicker.put('subscriptions', '[{"sbscrValue":"--None--","optionValue":"--None--","qtyValue":"1"}]');
        productPicker.put('swithType', '10GbE SFP+');

        poc.Planned_Installation_Date__c = Date.today().addDays(8);
        poc.POC_Type__c = 'Standard POC';
        poc.POC_Duration__c = '15';
        poc.POC_Relocation__c = 'No';
        poc.POC_Justification__c = 'test';
        poc.Ranger_Support_Expected__c = true;

        poc.Ship_To_Country__c = 'United States';
        poc.Shipping_Country__c = 'United States';
        poc.Shipping_Street__c = 'test';
        poc.Shipping_State__c = 'CA';
        poc.Shipping_Zip_Postal_Code__c = '2000';
        poc.Shipping_City__c = 'San Francisco';

        poc.Shipping_Company_Name__c = opp.AccountId;
        poc.Shipping_Contact__c = 'test';
        poc.Shipping_Contact_Email__c = 'test@test.cc';
        poc.Shipping_Contact_Phone__c = '12312332';
        poc.Manual_POC_Agreement__c = true;
        poc.Conditional_PO_Submitted__c = false;
        poc.MNDA_Signed__c = true;
        poc.POC_Qty__c = 1;

        poc.Support_Awareness_needed__c = 'Yes';
        poc.Total_VM_count__c = 200;
        poc.Largest_VM_size__c = 200;
        poc.Largest_disk_size_VMDK__c = 200;
        poc.Data_encrypted__c = 'Yes';
        poc.Compression__c = 'Yes';
        poc.Deduplication__c = 'Yes';
        poc.Oracle__c = 'Yes';
        poc.Largest_Oracle_database_size__c = 10;
        poc.MSSQL_Type__c = 'Standalone';
        poc.MSSQL__c = 'Yes';
        poc.Physical_Hosts__c = 'Yes';
        poc.Number_of_MSSQL_databases_per_host__c = 10;
        poc.Largest_MSSQL_Database__c = 10;
        poc.Exchange__c = 'Yes';
        poc.Large_Exchange_database__c = 15;
        poc.Archival_CloudOut__c = 'Yes';
        poc.Archival_make__c = 'default';
        poc.Archival_model__c = 'test';
        poc.Archival_bandwidth_available__c = 1000;
        poc.Largest_fileset_in_capacity__c = 1000;
        poc.Large_fileset_in_number_of_files__c = 255;
        poc.Physical_servers__c = 10;
        poc.Bandwidth_for_Replication__c = 1000;
        poc.Replication__c = 'Yes';

        poc.AWS_Customer_Account_Id__c = '123123123';
        poc.AWS_Customer_Account_Region__c = 'us-east-1';

        poc.Try_Buy_Agreement__c = true;

        poc.Partner_Disty_Signed_POC_Addendum__c = 'Yes';
        poc.Disty_with_Signed_POC_Addendum__c = opp.AccountId;
        poc.Other_Accessories__c = 'test';

       
        POCRequestFormController.POCRequest pr = POCRequestFormController.evaluatePOC(poc, productPicker, params);
        System.assertEquals(true, pr.isSuccess);
        
        //String pocStr = POCRequestFormController.validateOpportunity(opp.id);
        //System.assertEquals(true, pr.isSuccess);

        //boolean bVar = POCRequestFormController.isNumeric('4');
        //System.assertNotEquals(null, controller.cancel());


        //POC__c newPOC = [SELECT Id FROM POC__c WHERE Id = :pr.pocRequest.Id LIMIT 1];
        poc.Approval_Status__c = 'Approved';
        update poc;


        Order ord = [Select Id from Order where POC_Opportunity__c=:opp.Id];
        System.assertNotEquals(null, ord);
        Test.startTest();
        Asset ast = [Select Id, Name from Asset LIMIT 1];

        List<OrderItem> orderLines = [Select Id from OrderItem where OrderId = :ord.Id];
        for(OrderItem line: orderLines){
        	line.SerialNumber__c = null;
        }
        update orderLines;

        ord.Order_Status__c = 'Shipped';
        ord.Actual_Order_Ship_Date__c = Date.today();
        update ord;
        Test.stopTest();
	}
	
}