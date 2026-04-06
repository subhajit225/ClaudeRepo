@isTest
private class POCRequestFormControllerTest {

    @testSetup
    static void setup() {

        insert new list<TriggerControl__c> {
           new TriggerControl__c(Name='Contact', DisableTrigger__c=false),
           new TriggerControl__c(Name='Opportunity', DisableTrigger__c=false),
           new TriggerControl__c(Name='Entitlement', DisableTrigger__c=false),
           new TriggerControl__c(Name='Asset', DisableTrigger__c=false)
        };
        insert new Test_Controls__c(Bypass_Pricebook_Setting_on_Opp__c = true, Bypass_Pricebook_Setting_on_Quote__c = true);
        insert new PatchManagerSettings__c(Default_User_Id__c = UserInfo.getUserId(), Default_Account_User__c = UserInfo.getUserId());
        insert new ShGl_DisableBusinessLogic__c(SetupOwnerId = UserInfo.getOrganizationId(), Disable_Opportunity_Triggers__c = TRUE, Disable_Opportunity_Validation_Rules__c = TRUE,Disable_POC_Trigger__c = TRUE);
        //insert new ShGl_DisableBusinessLogic__c(SetupOwnerId = UserInfo.getOrganizationId(), Disable_POC_Trigger__c = TRUE);

        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        User sysAdmin;
        System.runAs(thisUser) {

            Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
            UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
            sysAdmin = new User(
                UserRoleId = portalRole.Id,
                ProfileId = profile1.Id,
                Username = System.now().millisecond() + 'sysAdmin@randomtestdomain.com',
                Alias = 'batman',
                Email = System.now().millisecond() + 'random.email@randomtestdomain.com',
                EmailEncodingKey = 'UTF-8',
                Firstname = 'test',
                Lastname = 'test',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'America/Chicago'
            );
            Database.insert(sysAdmin);
        }

        System.runAs(sysAdmin) {
            id rId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            Account acct = new Account(
                recordTypeId = rId,
                Type = 'Distributor',
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
                ShippingCountry = 'United States'
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
                Alliance_Source_Type_SW__c = 'Test',
                Compelling_Bus_Driver__c = 'Instant Recovery',
                Current_State__c = 'test',
                Negative_Consequences__c = 'test',
                Future_State__c = 'test',
                Positive_Business_Outcomes__c = 'test',
                Distributor_Lookup__c = acct.Id,
                Opportunity_Sub_Type__c = 'MSP',
                Opportunity_Type__c = 'New Customer',
                Rubrik_Sales_Engineer__c = UserInfo.getUserId(),
                Win_Loss_Comments__c = 'test',
                Primary_Competitor__c = 'Actifio',
                Key_Feature_Needs__c = 'None',
                //Deal_Impact__c = 'Deal Blocker',
                Valooto_Quote__c = '123123123',
                Valooto_Quote_Stage__c = 'Approved',
                Partner_Level_Of_Involvement__c = '1.Rubrik initiated, Partner was fulfillment only'
            );
            insert opp;
        }
        Pricebook2 pricebook = POCRequestTriggerHandler.stdPriceBook;
        Product2 newProd = new Product2(Name = 'Polaris', family = 'Polaris', ProductCode = 'Polaris');
        insert newProd;
        
        Id standardPBId = pricebook.id;
        
        PriceBookEntry pbEntry = new PriceBookEntry(
            UnitPrice = 400,
            PriceBook2Id = pricebook.id,
            Product2Id = newProd.Id,
            IsActive = true,
            UseStandardPrice=false);
        insert pbEntry ;
        
    }

    @isTest
    static void testAccountController() {
        Account acc = [SELECT Id, Name FROM Account WHERE Name = :'Test Account' LIMIT 1];

        PageReference ref = new PageReference('/apex/POCRequestAccount?id=' + acc.Id);
        Test.setCurrentPage(ref);

        ApexPages.StandardController stdController = new ApexPages.StandardController(acc);
        POCRequestFormController controller = new POCRequestFormController(stdController);

        System.assertEquals(1, controller.opps.size());
        System.assertEquals(null, controller.newOppError);

        System.assertEquals(false, controller.getPartnerDistributorSignedPOCAddendum());

        System.assertEquals(null, controller.initForm());
        System.assertNotEquals(null, controller.cancel());

        System.assertEquals(null, controller.pocAgreementFileBody);
        System.assertEquals(null, controller.pocAgreementFileName);
        System.assertEquals(null, controller.mndaAgreementFileBody);
        System.assertEquals(null, controller.mndaAgreementFileName);
        System.assertEquals(null, controller.testPlanFileBody);
        System.assertEquals(null, controller.testPlanFileName);
    }


    @isTest
    static void testOpportunityController() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Name = :'Test Opp' LIMIT 1];

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

        productPicker.put('accessories', '[{"codeValue":"RBK-SFP28-TSR-01;RBK-SFP-TSR-01","qtyValue":""}]');
        productPicker.put('encryption', 'Yes');
        productPicker.put('polaris', 'No');
        productPicker.put('productFamily', 'r300');
        productPicker.put('requestedProduct', 'R344');
        productPicker.put('subscriptions', '[{"sbscrValue":"--None--","optionValue":"--None--","qtyValue":"1"}]');
        productPicker.put('swithType', '10Base-T NIC (RJ45, Copper)');

        poc.Planned_Installation_Date__c = Date.today().addDays(8);
        poc.POC_Type__c = 'Standard POC';
        poc.POC_Duration__c = '30 Days';
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

        poc.AWS_Customer_Account_Id__c = '123123123123';
        poc.AWS_Customer_Account_Region__c = 'us-east-1';

        poc.Try_Buy_Agreement__c = true;

        poc.Partner_Disty_Signed_POC_Addendum__c = 'Yes';
        poc.Disty_with_Signed_POC_Addendum__c = opp.AccountId;
        poc.Other_Accessories__c = 'test';


        POCRequestFormController.POCRequest pr = POCRequestFormController.evaluatePOC(poc, productPicker, params);
        System.assertEquals(poc.Other_Accessories__c, 'test');

        String pocStr = POCRequestFormController.validateOpportunity(opp.id);
        //System.assertEquals(true, pr.isSuccess);

        boolean bVar = POCRequestFormController.isNumeric('4');

        System.assertNotEquals(null, controller.cancel());


        POC__c newPOC = [SELECT Id FROM POC__c WHERE Id = :pr.pocRequest.Id LIMIT 1];

        PageReference ref2 = new PageReference('/apex/POCRequest?id=' + newPOC.Id);
        Test.setCurrentPage(ref2);

        ApexPages.StandardController updStdController = new ApexPages.StandardController(newPOC);
        POCRequestFormController updController = new POCRequestFormController(updStdController);

        System.assertNotEquals(null, updController.selectedProductPicker);
        System.assertEquals('Test Account', controller.getAccountName());

        POC__c pocUpd = updController.poc;
        pocUpd.Other_Accessories__c = 'test2';

        Test.startTest();
        POCRequestFormController.POCRequest pr2 = POCRequestFormController.evaluatePOC(pocUpd, productPicker, params);
        System.assertEquals(true, pr.isSuccess);

        System.assertNotEquals(null, controller.cancel());

        POC__c newPOCUpdated = [SELECT Id, Other_Accessories__c, Product_Codes__c, POC_Product_Code__c, Order__c FROM POC__c WHERE Id = :pr2.pocRequest.Id LIMIT 1];
        Map<Id, Set<String>> mapProductCodesByPOCId = new Map<Id, Set<String>>();
        Set<String> allProductCodes = new Set<String>();
        PocTriggerHelper.setProductCodes(newPOCUpdated, mapProductCodesByPOCId, allProductCodes);
        System.assertEquals(newPOCUpdated.Other_Accessories__c, 'test2');
        PocTriggerHelper.reassignRetunredAssets(new Set<Id>{newPOCUpdated.Order__c});
        PocTriggerHelper.syncPocLines(new List<POC__c>{newPOCUpdated}, new Set<String>(), mapProductCodesByPOCId); 
        System.assertEquals(true, POCRequestFormController.doesRunningUserHavePermissions());
        Test.stopTest();

    }
    
    @isTest
    static void testConvertPOC(){
    
         Profile profile1 = [Select Id from Profile where name = 'Rubrik Light Administrator'];
            UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
            user sysAdmin1 = new User(
                UserRoleId = portalRole.Id,
                ProfileId = profile1.Id,
                Username = System.now().millisecond() + 'sysAdmin@randomtestdomain.com',
                Alias = 'batman',
                Email = System.now().millisecond() + 'random.email@randomtestdomain.com',
                EmailEncodingKey = 'UTF-8',
                Firstname = 'test',
                Lastname = 'test',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'America/Chicago'
            );
            Database.insert(sysAdmin1);
        System.runAs(sysAdmin1){    
         Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Name = :'Test Opp' LIMIT 1];

        POC__c poc = new POC__c();
        poc.POC_Type__c ='Conditional PO';
        poc.POC_Duration__c = '30 Days';
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
        poc.Planned_Installation_Date__c = Date.today().addDays(8);
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
        poc.Opportunity__c = opp.id;
            insert poc;

        POC__c poc1 = new POC__c();
        poc1.POC_Type__c ='Conditional PO';
        poc1.POC_Duration__c = '30 Days';
        poc1.POC_Relocation__c = 'No';
        poc1.POC_Justification__c = 'test';
        poc1.Ranger_Support_Expected__c = true;

        poc1.Ship_To_Country__c = 'United States';
        poc1.Shipping_Street__c = 'test';
        poc1.Shipping_State__c = 'CA';
        poc1.Shipping_Zip_Postal_Code__c = '2000';
        poc1.Shipping_City__c = 'San Francisco';

        poc1.Shipping_Company_Name__c = opp.AccountId;
        poc1.Shipping_Contact__c = 'test';
        poc1.Shipping_Contact_Email__c = 'test@test.cc';
        poc1.Shipping_Contact_Phone__c = '12312332';
        poc1.Manual_POC_Agreement__c = true;
        poc1.Conditional_PO_Submitted__c = false;
        poc1.MNDA_Signed__c = true;
        poc1.POC_Qty__c = 1;
        poc1.Planned_Installation_Date__c = Date.today().addDays(8);
        poc1.Support_Awareness_needed__c = 'Yes';
        poc1.Total_VM_count__c = 200;
        poc1.Largest_VM_size__c = 200;
        poc1.Largest_disk_size_VMDK__c = 200;
        poc1.Data_encrypted__c = 'Yes';
        poc1.Compression__c = 'Yes';
        poc1.Deduplication__c = 'Yes';
        poc1.Oracle__c = 'Yes';
        poc1.Largest_Oracle_database_size__c = 10;
        poc1.MSSQL_Type__c = 'Standalone';
        poc1.MSSQL__c = 'Yes';
        poc1.Physical_Hosts__c = 'Yes';
        poc1.Number_of_MSSQL_databases_per_host__c = 10;
        poc1.Largest_MSSQL_Database__c = 10;
        poc1.Exchange__c = 'Yes';
        poc1.Large_Exchange_database__c = 15;
        poc1.Archival_CloudOut__c = 'Yes';
        poc1.Archival_make__c = 'default';
        poc1.Archival_model__c = 'test';
        poc1.Archival_bandwidth_available__c = 1000;
        poc1.Largest_fileset_in_capacity__c = 1000;
        poc1.Large_fileset_in_number_of_files__c = 255;
        poc1.Physical_servers__c = 10;
        poc1.Bandwidth_for_Replication__c = 1000;
        poc1.Replication__c = 'Yes';

        poc1.AWS_Customer_Account_Id__c = '123123123';
        poc1.AWS_Customer_Account_Region__c = 'us-east-1';

        poc1.Try_Buy_Agreement__c = true;

        poc1.Partner_Disty_Signed_POC_Addendum__c = 'Yes';
        poc1.Disty_with_Signed_POC_Addendum__c = opp.AccountId;
        poc1.Other_Accessories__c = 'test';
        poc1.Opportunity__c = opp.id;
        insert poc1;

        Test.startTest();
        Opportunity opp_1 = [Select ID, Most_Recent_POC_Request__c from Opportunity where ID = : opp.id];
        System.assertEquals(poc.Other_Accessories__c, 'test');
        System.debug(poc.id + ', ' + poc1.id + '\n\n~~~~ Most_Recent_POC_Request__c: '+ opp_1);
            
        ApexPages.StandardController updStdController = new ApexPages.StandardController(poc);
        POCConverted updController = new POCConverted(updStdController);
        updController.markAsConvertedNonConverted();
        updController.cancelPOC();
        
        ApexPages.StandardController updStdController2 = new ApexPages.StandardController(poc);
        POCConverted updController2 = new POCConverted(updStdController2);
        updController2.markAsConvertedNonConverted();
        
        
        poc.POC_Type__c ='Standard PO';
        poc.POC_Converted__c = false;
        update POC;
        
        ApexPages.StandardController updStdController1 = new ApexPages.StandardController(poc);
        POCConverted updController1 = new POCConverted(updStdController1);
        updController1.markAsConvertedNonConverted();
        
        Test.stopTest();
        
            }
    } 
    
    @isTest
    static void testPOCAutoFulfilment() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Name = :'Test Opp' LIMIT 1];

        POC__c pocRequest = new POC__c();
        PageReference ref = new PageReference('/apex/POCRequestForm?id=' + opp.Id);
        Test.setCurrentPage(ref);

        ApexPages.StandardController stdController = new ApexPages.StandardController(opp);
        POCRequestFormController controller = new POCRequestFormController(stdController);

        POC__c poc = controller.poc;
        System.assertNotEquals(null, poc);

        Map<String, Object> productPicker = new Map<String, Object>();
        Map<String, Object> params = new Map<String, Object>();

        productPicker.put('accessories', '[{"codeValue":"--None--","qtyValue":""}]');
        productPicker.put('encryption', 'Yes');
        productPicker.put('polaris', 'No');
        productPicker.put('productFamily', 'EDGE');
        productPicker.put('requestedProduct', 'EDGE');
        productPicker.put('subscriptions', '[{"sbscrValue":"--None--","optionValue":"--None--","qtyValue":"1"}]');
        productPicker.put('swithType', '10Base-T NIC (RJ45, Copper)');

        poc.Planned_Installation_Date__c = Date.today().addDays(8);
        poc.POC_Type__c = 'Standard POC';
        poc.POC_Duration__c = '30 Days';
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

        poc.AWS_Customer_Account_Id__c = '123123123123';
        poc.AWS_Customer_Account_Region__c = 'us-east-1';

        poc.Try_Buy_Agreement__c = true;

        poc.Partner_Disty_Signed_POC_Addendum__c = 'Yes';
        poc.Disty_with_Signed_POC_Addendum__c = opp.AccountId;
        poc.Other_Accessories__c = 'test';


        POCRequestFormController.POCRequest pr = POCRequestFormController.evaluatePOC(poc, productPicker, params);
        System.assertEquals(poc.Other_Accessories__c, 'test');

        Test.startTest();
        POC__c newPOC = [SELECT Id FROM POC__c WHERE Id = :pr.pocRequest.Id LIMIT 1];
        newPOC.Approval_Status__c = 'Approved';
        update newPOC;
        Test.stopTest();
        //Order ord = [Select Id, Order_Status__c from Order];
        System.assertEquals(poc.Other_Accessories__c ,'test');

    }
    @isTest
    static void testPocWebTryNBuy() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Name = :'Test Opp' LIMIT 1];
        POC__c poc = new POC__c();
        poc.Planned_Installation_Date__c = Date.today().addDays(8);
        poc.POC_Type__c = 'Web Try and Buy';
        poc.POC_Duration__c = '30 Days';
        poc.POC_Relocation__c = 'No';
        poc.POC_Justification__c = 'test';
        poc.Ranger_Support_Expected__c = true;
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

        poc.AWS_Customer_Account_Id__c = '123123123123';
        poc.AWS_Customer_Account_Region__c = 'us-east-1';

        poc.Try_Buy_Agreement__c = true;

        poc.Partner_Disty_Signed_POC_Addendum__c = 'Yes';
        poc.Disty_with_Signed_POC_Addendum__c = opp.AccountId;
        poc.Other_Accessories__c = 'test';
        poc.Product_Codes__c = 'Polaris#1#test';
        poc.POC_Product_Code__c = 'Polaris';
        poc.POC_End_Date__c = system.today();
        poc.Opportunity__c = opp.id;
        insert poc;
        //POCRequestFormController.POCRequest pr = POCRequestFormController.evaluatePOC(poc, productPicker, params);
        //System.assertEquals(true, pr.isSuccess);


        Test.startTest();
        //poc.POC_Stage__c = 'Extended POC';
        poc.Approval_Status__c = 'Approved';
        update poc;
        
        Test.stopTest();
    }

    @isTest
    static void testPocWebTryNBuyExt() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Name = :'Test Opp' LIMIT 1];
        POC__c poc = new POC__c();
        poc.Planned_Installation_Date__c = Date.today().addDays(8);
        poc.POC_Type__c = 'Web Try and Buy';
        poc.POC_Duration__c = '30 Days';
        poc.POC_Relocation__c = 'No';
        poc.POC_Justification__c = 'test';
        poc.Ranger_Support_Expected__c = true;
        poc.Manual_POC_Agreement__c = true;
        poc.Conditional_PO_Submitted__c = false;
        poc.MNDA_Signed__c = true;
        poc.POC_Qty__c = 1;
        poc.Approval_Status__c = 'Approved';
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

        poc.AWS_Customer_Account_Id__c = '123123123123';
        poc.AWS_Customer_Account_Region__c = 'us-east-1';

        poc.Try_Buy_Agreement__c = true;

        poc.Partner_Disty_Signed_POC_Addendum__c = 'Yes';
        poc.Disty_with_Signed_POC_Addendum__c = opp.AccountId;
        poc.Other_Accessories__c = 'test';
        poc.Product_Codes__c = 'Polaris#1#test';
        poc.POC_Product_Code__c = 'Polaris';
        poc.POC_End_Date__c = system.today();
        poc.Opportunity__c = opp.id;
        insert poc;
        //POCRequestFormController.POCRequest pr = POCRequestFormController.evaluatePOC(poc, productPicker, params);
        //System.assertEquals(true, pr.isSuccess);


        Test.startTest();
        poc.POC_Stage__c = 'Extended POC';
        update poc;
        
        Test.stopTest();
    }
     @isTest
    static void testgetCurrentProductPicker(){
        POC__c poc = createPOC();
        String acodes ='RBK-R334-01;RBK-SFP-TSR-01';
        String mcodes ='RBK-R334-01#RBK-SFP-TSR-01';
        POCRequestFormController.getCurrentProductPicker(acodes,mcodes,poc);
        System.assertEquals(mcodes ,'RBK-R334-01#RBK-SFP-TSR-01');
    }
    @isTest
    static void testgetCurrentProductPicker1(){
        POC__c poc = createPOC();
        String acodes ='RBK-M365H#1#M365 Rubrik Hosted#Polaris;RBK-SFP-TSR-01';
        String mcodes ='RBK-R334-01#RBK-SFP-TSR-01';
        POCRequestFormController.getCurrentProductPicker(acodes,mcodes,poc);
        POCRequestFormController.AdminAccessHelper obj = new POCRequestFormController.AdminAccessHelper();
        obj.recallApproval(poc);
        POCRequestFormController.checkPOCContactAgreement('test');
        System.assertEquals(mcodes ,'RBK-R334-01#RBK-SFP-TSR-01');
    }
    public static POC__c createPOC(){
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Name = :'Test Opp' LIMIT 1];
        POC__c poc = new POC__c();
        poc.Planned_Installation_Date__c = Date.today().addDays(8);
        poc.POC_Type__c = 'Web Try and Buy';
        poc.POC_Duration__c = '30 Days';
        poc.POC_Relocation__c = 'No';
        poc.POC_Justification__c = 'test';
        poc.Ranger_Support_Expected__c = true;
        poc.Manual_POC_Agreement__c = true;
        poc.Conditional_PO_Submitted__c = false;
        poc.MNDA_Signed__c = true;
        poc.POC_Qty__c = 1;
        poc.Approval_Status__c = 'Approved';
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

        poc.AWS_Customer_Account_Id__c = '123123123123';
        poc.AWS_Customer_Account_Region__c = 'us-east-1';

        poc.Try_Buy_Agreement__c = true;

        poc.Partner_Disty_Signed_POC_Addendum__c = 'Yes';
        poc.Disty_with_Signed_POC_Addendum__c = opp.AccountId;
        poc.Other_Accessories__c = 'test';
        poc.Product_Codes__c = 'Polaris#1#test';
        poc.POC_Product_Code__c = 'Polaris';
        poc.POC_End_Date__c = system.today();
        poc.Opportunity__c = opp.id;
        insert poc;
        return poc;
    }
    

}