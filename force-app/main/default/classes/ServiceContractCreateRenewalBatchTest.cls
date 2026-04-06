/**Test class for ServiceContractCreateRenewalBatch */
@isTest
public with sharing class ServiceContractCreateRenewalBatchTest{
    
    @TestSetUp
    static void initialDataSetup() {
        
        Account accObj = TestDataFactory.getAccount();
        insert accObj;

        System.runAs(new User(Id=UserInfo.getUserId())) {
			Profile profile1 = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
			UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
			User sysAdmin = new User(
				UserRoleId = portalRole.Id,
				ProfileId = profile1.Id,
				Username = System.now().millisecond() + 'sysAdmin@randomtestdomain.com.sandbox',
				Alias = 'xmen',
				Email = System.now().millisecond() + 'random.email@randomtestdomain.com.sandbox',
				EmailEncodingKey = 'UTF-8',
				Firstname = 'test',
				Lastname = 'test',
				LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US',
				TimeZoneSidKey = 'America/Chicago'
			);
			Database.insert(sysAdmin);
		}

        List<ServiceContract> listServiceContracts = new List<ServiceContract>();
        
            listServiceContracts.add(
                new ServiceContract(
                    Name = 'Test Contract',
                    AccountId = accObj.Id,
                    StartDate = Date.today(),
                    Term = 12
                    //EndDate =  Date.today().addDays(365)
                )
            );
            listServiceContracts.add(
                new ServiceContract(
                    Name = 'Test2 Contract',
                    AccountId = accObj.Id,
                    StartDate = Date.today(),
                    Term = 12
                    //EndDate =  Date.today().addDays(365)
                )
            );
        
        insert listServiceContracts;
        
        Datetime yesterday = Datetime.now().addDays(-1);
        Test.setCreatedDate(listServiceContracts[0].Id, yesterday);
    }

    /**testBatchSuccessProcessing */
    public static testMethod void testBatchSuccessProcessing() {
        Profile p1 = [SELECT Id FROM Profile WHERE Name='System Administrator' Limit 1]; 
        User u1 = new User(Alias = 'standt', Email='test.testmethod@rubrik.com.invalid', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p1.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduserdemo@testorg.com');
        System.runAs(u1) {
        
            Account accObj = TestDataFactory.getAccount();
            insert accObj;
            List<Account> accList = new List<Account>();
            accList.add(accObj);
            Assert.areEqual(1, accList.size());
            
            List<ServiceContract> listServiceContracts = new List<ServiceContract>();
            //for (Integer i = 0; i < 1; i++) {
                listServiceContracts.add(
                    new ServiceContract(
                        Name = 'Test Contract',
                        AccountId = accObj.Id,
                        StartDate = Date.today(),
                        Term = 12
                        //EndDate =  Date.today().addDays(120)
                    )
                );
            //}
            
            //for (Integer i = 0; i < 1; i++) {
                listServiceContracts.add(
                    new ServiceContract(
                        Name = 'Test Contract',
                        AccountId = accObj.Id,
                        StartDate = Date.today(),
                        Term = 12
                        //EndDate =  Date.today().addDays(121)
                    )
                );
            
            insert listServiceContracts;
            
            Test.startTest();
            Id batchJobId = Database.executeBatch(new ServiceContractCreateRenewalBatch(), 20);
            Test.stopTest(); 
            
            List<ServiceContract> listContracts = [Select Id, SBQQSC__RenewalQuoted__c from ServiceContract Limit 1];
            
            System.assertEquals(false, listContracts[0].SBQQSC__RenewalQuoted__c, 'RenewalQuoted should be set to false');
        }
    }
    
    /**testBatchSuccessProcessing */
    @istest
    public static void testBatchSuccessProcessing2() {
        Profile p1 = [SELECT Id FROM Profile WHERE Name='System Administrator' Limit 1]; 
        User u1 = new User(Alias = 'standt', Email='test.testmethod@rubrik.com.invalid', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p1.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduserdemo@testorg.com');
        System.runAs(u1) {
        	Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            Account accObj = TestDataFactory.getAccount();
            Account  objAccount = TestDataFactory.getAccount();
            objAccount.Name = 'Test Account 31-05';
            objAccount.RecordTypeId = recordTypeId;
            objAccount.Payment_Term__c = 'Net 30';
            objAccount.Aspen_Eligible__c=true;
            //insert accObj;
            List<Account> accList = new List<Account>();
            accList.add(accObj);
            accList.add(objAccount);
            insert accList;
            Assert.areEqual(2, accList.size());
			
			 opportunity oppr = new opportunity(
             Name = 'testing DIEtestsalesforce 4/6/2015',
             Opportunity_Sub_Type__c = 'Regular',
             Distributor_Lookup__c = objAccount.Id,
             Alliance_Source_Type_HW__c = 'Rubrik Initiated Alliance Deal',
             Mosaic_Customer_Environment__c = 'AWS',
             CloseDate = Date.Today().addDays(10),
             Lead_Email_Hidden__c = '',
             AccountId = accObj.Id,
             StageName = '1 Discovery',
             Rubrik_Sales_Engineer__c = UserInfo.getUserId(),
             Alliance_Partner_Name__c = 'Amazon',
             Alliance_Source_Type__c = 'Alliance Initiated Deal',
             Installation_Assigned_To__c = 'FE Install',
             Economic_Buyer__c = 'Test',
             Metric__c = 'Test',
             Decision_Process__c = 'Test',
             Decision_Criteria__c = 'Test',
             Alliance_Source_Type_SW__c = 'Rubrik Initiated Alliance Deal',
             Champion__c = 'Test',
             ForecastCategoryName = 'Best Case',
             Override__c = false,
             Aspen_Eligibility__c = 'Actual Aspen'
             );

			insert oppr;
			
			SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
			qt.SBQQ__Account__c = accObj.Id;
			qt.SBQQ__Opportunity2__c = oppr.Id;
			qt.SBQQ__Primary__c = true;
			qt.SBQQ__SubscriptionTerm__c = 36;
			qt.SBQQ__ExpirationDate__c = date.today().addDays(10);
			qt.SBQQ__PaymentTerms__c = 'Net 45';
			qt.SBQQ__Type__c = 'Renewal+Expansion';
			qt.Is_Refreshed__c = true;
			qt.ProcessType__c = 'Aspen';
            
			insert qt;
        Id overviewRecordTypeId = Schema.SObjectType.ShipmentDetail__c.getRecordTypeInfosByName().get('Overview').getRecordTypeId();
            
        ShipmentDetail__c shpEx = new ShipmentDetail__c();
        shpEx.HW_SerialNumber__c = 'Ass-65431';
        shpEx.ContractManufacturer__c = 'Super Micro Computer, Inc.';
        shpEx.ProductName__c = 'prdHW.Name';
        shpEx.Quantity__c = 2;
        shpEx.QuoteNumber__c = qt.Name ;
        shpEx.Status__c = 'Success';
        shpEx.ShippedDate__c = '12/16/15';
        shpEx.Quote__c = qt.Id;
        shpEx.Quote_ShipmentValidation__c = 'Complete';
        shpEx.RecordTypeId=overviewRecordTypeId;
        insert shpEx;
			
		Map<String, Object> OrderMap = new Map<String, Object>{
        'Type' => 'Revenue',
        'Send_for_Polaris_Fulfilment__c' => true,
        'AccountId' => oppr.AccountId,
        'OpportunityId' => oppr.Id,
        'EffectiveDate' => system.today(),
        'Order_Status__c' => null,
        'Status' => 'Pending',
        'Sync_to_NetSuite__c' => true,
        'ShippingCountryCode' => 'US',
        'ShippingStateCode' => 'CA',
        'ShippingStreet' => 'Test Street',
        'ShippingCity' => 'Test City',
        'ShippingState' => 'California',
        'ShippingCountry' => 'United States',
        'ShippingPostalcode' => '94820',
        'ship_To_Name__c' => oppr.AccountId,
        'ShipToContactName__c' => 'Test',
        'Pricebook2Id' => test.getStandardPricebookId(),
        'Have_Polaris_Products__c' => false,
        'Polaris_Fulfillment_Status__c' => 'Completed',
        'Original_Est_Ship_Date__c' => Date.today().addDays(30),
        'Est_Ship_Date__c' => null,
        'Order_Split_Type__c' => 'Not needed',
        'ProcessType__c' => 'Aspen',
        'Overview_Shipment_Detail__c' => shpEx.Id
      };
 	  
      Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
        insert ord;    
            List<ServiceContract> listServiceContracts = new List<ServiceContract>();
            //for (Integer i = 0; i < 1; i++) {
                listServiceContracts.add(
                    new ServiceContract(
                        Name = 'Test Contract',
                        AccountId = accObj.Id,
                        StartDate = Date.today(),
                        SBQQSC__Order__c = ord.id,
                        SBQQSC__RenewalQuoted__c=false,
                        Is_Renewed__c=false,
                        Term = 12
                        //EndDate =  Date.today().addDays(120)
                    )
                );
            //}
            
            //for (Integer i = 0; i < 1; i++) {
                listServiceContracts.add(
                    new ServiceContract(
                        Name = 'Test Contract',
                        AccountId = accObj.Id,
                        StartDate = Date.today(),
                        Term = 12
                        //EndDate =  Date.today().addDays(121)
                    )
                );
            
            insert listServiceContracts;
            
            Test.startTest();
            Id batchJobId = Database.executeBatch(new ServiceContractCreateRenewalBatch(), 20);
            Test.stopTest(); 
            
            List<ServiceContract> listContracts = [Select Id, SBQQSC__RenewalQuoted__c from ServiceContract WITH SECURITY_ENFORCED Limit 1];
            
            System.assertEquals(false, listContracts[0].SBQQSC__RenewalQuoted__c, 'RenewalQuoted should be set to false');
        }
    }

    /** testSchedulableSuccessProcessing*/
    public static testMethod void testSchedulableSuccessProcessing() {
        Profile p1 = [SELECT Id FROM Profile WHERE Name='System Administrator' WITH SECURITY_ENFORCED Limit 1]; 
        User u1 = new User(Alias = 'standt', Email='test.testmethod@rubrik.com.invalid', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p1.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduserdemo@testorg.com');
        System.runAs(u1) {
        Test.startTest();
        Id batchJobId = System.schedule('SC Renewal', '0 0 23 * * ?', new ServiceContractCreateRenewalBatch());
        Test.stopTest();
        
        List<ServiceContract> listContracts = [Select Id, SBQQSC__RenewalQuoted__c from ServiceContract Limit 1];
        System.assertEquals(false, listContracts[0].SBQQSC__RenewalQuoted__c, 'RenewalQuoted should be set to true');  
        }
    }

    /**testBatchSuccessProcessing */
    public static testMethod void testBatchErrorProcessing() {
        Profile p1 = [SELECT Id FROM Profile WHERE Name='System Administrator' Limit 1]; 
        User u1 = new User(Alias = 'standt', Email='test.testmethod@rubrik.com.invalid', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p1.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduserdemo@testorg.com');
        System.runAs(u1) {

                Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
                Account accObj = TestDataFactory.getAccount();
                Account  objAccount = TestDataFactory.getAccount();
                objAccount.Name = 'Test Account 31-05';
                objAccount.RecordTypeId = recordTypeId;
                objAccount.Payment_Term__c = 'Net 30';
                objAccount.Aspen_Eligible__c=true;
                //insert accObj;
                List<Account> accList = new List<Account>();
                accList.add(accObj);
                accList.add(objAccount);
                insert accList;
                Assert.areEqual(2, accList.size());
                
                opportunity oppr = new opportunity(
                Name = 'testing DIEtestsalesforce 4/6/2015',
                Opportunity_Sub_Type__c = 'Regular',
                Distributor_Lookup__c = objAccount.Id,
                Alliance_Source_Type_HW__c = 'Rubrik Initiated Alliance Deal',
                Mosaic_Customer_Environment__c = 'AWS',
                CloseDate = Date.Today().addDays(10),
                Lead_Email_Hidden__c = '',
                AccountId = accObj.Id,
                StageName = '1 Discovery',
                Rubrik_Sales_Engineer__c = UserInfo.getUserId(),
                Alliance_Partner_Name__c = 'Amazon',
                Alliance_Source_Type__c = 'Alliance Initiated Deal',
                Installation_Assigned_To__c = 'FE Install',
                Economic_Buyer__c = 'Test',
                Metric__c = 'Test',
                Decision_Process__c = 'Test',
                Decision_Criteria__c = 'Test',
                Alliance_Source_Type_SW__c = 'Rubrik Initiated Alliance Deal',
                Champion__c = 'Test',
                ForecastCategoryName = 'Best Case',
                Override__c = false,
                Aspen_Eligibility__c = 'Actual Aspen'
                );

                insert oppr;
                
                SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
                qt.SBQQ__Account__c = accObj.Id;
                qt.SBQQ__Opportunity2__c = oppr.Id;
                qt.SBQQ__Primary__c = true;
                qt.SBQQ__SubscriptionTerm__c = 36;
                qt.SBQQ__ExpirationDate__c = date.today().addDays(10);
                qt.SBQQ__PaymentTerms__c = 'Net 45';
                qt.SBQQ__Type__c = 'Renewal+Expansion';
                qt.Is_Refreshed__c = true;
                qt.ProcessType__c = 'Aspen';
                
                insert qt;
            Id overviewRecordTypeId = Schema.SObjectType.ShipmentDetail__c.getRecordTypeInfosByName().get('Overview').getRecordTypeId();
                
            ShipmentDetail__c shpEx = new ShipmentDetail__c();
            shpEx.HW_SerialNumber__c = 'Ass-65431';
            shpEx.ContractManufacturer__c = 'Super Micro Computer, Inc.';
            shpEx.ProductName__c = 'prdHW.Name';
            shpEx.Quantity__c = 2;
            shpEx.QuoteNumber__c = qt.Name ;
            shpEx.Status__c = 'Success';
            shpEx.ShippedDate__c = '12/16/15';
            shpEx.Quote__c = qt.Id;
            shpEx.Quote_ShipmentValidation__c = 'Complete';
            shpEx.RecordTypeId=overviewRecordTypeId;
            insert shpEx;
            
            Map<String, Object> OrderMap = new Map<String, Object>{
                'Type' => 'Revenue',
                'Send_for_Polaris_Fulfilment__c' => true,
                'AccountId' => oppr.AccountId,
                'OpportunityId' => oppr.Id,
                'EffectiveDate' => system.today(),
                'Order_Status__c' => null,
                'Status' => 'Pending',
                'Sync_to_NetSuite__c' => true,
                'ShippingCountryCode' => 'US',
                'ShippingStateCode' => 'CA',
                'ShippingStreet' => 'Test Street',
                'ShippingCity' => 'Test City',
                'ShippingState' => 'California',
                'ShippingCountry' => 'United States',
                'ShippingPostalcode' => '94820',
                'ship_To_Name__c' => oppr.AccountId,
                'ShipToContactName__c' => 'Test',
                'Pricebook2Id' => test.getStandardPricebookId(),
                'Have_Polaris_Products__c' => false,
                'Polaris_Fulfillment_Status__c' => 'Completed',
                'Original_Est_Ship_Date__c' => Date.today().addDays(30),
                'Est_Ship_Date__c' => null,
                'Order_Split_Type__c' => 'Not needed',
                'ProcessType__c' => 'Aspen',
                'Overview_Shipment_Detail__c' => shpEx.Id
            };
            
            Order mspOrd = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
            insert mspOrd;

            Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
            ord.Migrated_MSP_Order__c = mspOrd.Id;
            insert ord;
            
            List<ServiceContract> listServiceContracts = new List<ServiceContract>();
            //for (Integer i = 0; i < 1; i++) {
                listServiceContracts.add(
                    new ServiceContract(
                        Name = 'Test Contract',
                        AccountId = accObj.Id,
                        StartDate = Date.today(),
                        SBQQSC__Order__c = ord.id,
                        SBQQSC__RenewalQuoted__c=false,
                        Is_Renewed__c=false,
                        Term = 12
                        //EndDate =  Date.today().addDays(120)
                    )
                );
            //}
            
            insert listServiceContracts;
            
            Test.startTest();
            Id batchJobId = Database.executeBatch(new ServiceContractCreateRenewalBatch(), 20);
            Test.stopTest(); 
            
            List<ServiceContract> listContracts = [Select Id, SBQQSC__RenewalQuoted__c from ServiceContract Limit 1];
            
            System.assertEquals(false, listContracts[0].SBQQSC__RenewalQuoted__c, 'RenewalQuoted should be set to false');
        }
    }

}