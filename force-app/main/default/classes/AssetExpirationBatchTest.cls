@isTest
private class AssetExpirationBatchTest {

	@testSetup
	static void setup() {
		insert new list<TriggerControl__c> {
			new TriggerControl__c(Name='Contact', DisableTrigger__c=false),
			new TriggerControl__c(Name='Opportunity', DisableTrigger__c=false),
			new TriggerControl__c(Name='Entitlement', DisableTrigger__c=false),
			new TriggerControl__c(Name='Asset', DisableTrigger__c=false)
		};
		insert new Test_Controls__c(Bypass_Pricebook_Setting_on_Opp__c=true, Bypass_Pricebook_Setting_on_Quote__c=true);
		insert new PatchManagerSettings__c(Default_User_Id__c=UserInfo.getUserId(), Default_Account_User__c=UserInfo.getUserId());

		System.runAs(new User(Id=UserInfo.getUserId())) {
			Profile profile1 = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
			UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
			User sysAdmin = new User(
				UserRoleId = portalRole.Id,
				ProfileId = profile1.Id,
				Username = System.now().millisecond() + 'sysAdmin@randomtestdomain.com',
				Alias = 'xmen',
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
	}

	@isTest
	private static void test_Send_Expiration_Emails() {
        FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
		Account test_account = new Account(
			Name='Test Account', Phone='123-456-7890', AccountNumber='Test',
			BillingStreet='123 street', BillingCity='Santa Clara', BillingState='California', BillingPostalCode='95050', BillingCountry='United States'
		);
		insert test_account;

		Contact test_contact = new Contact(
			LeadSource='Channel', FirstName='Tasty', LastName='Toaster', AccountId=test_account.Id, Email='test124@test.com'
		);
		insert test_contact;

		User test_user = [SELECT Id, Email FROM User WHERE Email != NULL LIMIT 1];

		OpportunityStage stage = [SELECT MasterLabel FROM OpportunityStage WHERE IsWon = false AND IsClosed = false AND isActive = true LIMIT 1];
		Opportunity test_oppty = new Opportunity(
			Name = 'Test Opp', AccountId = test_account.Id, StageName = stage.MasterLabel, CloseDate = System.today().addDays(15), PriceBook2Id = Test.getStandardPricebookId(),
			SBQQ__QuotePricebookId__c = Test.getStandardPricebookId(), Alliance_Partner_Name__c='None', Alliance_Source_Type__c='Alliance Initiated Deal', Alliance_Source_Type_SW__c='Alliance Initiated Deal',
			Rubrik_Sales_Engineer__c=test_user.Id
		);
		insert test_oppty;

		Order test_order = new Order(
			Type='Revenue', AccountId=test_account.Id, OpportunityId=test_oppty.Id, ShippingStreet='123 Shipping Street', ShippingCity='Shipping City',
			ShippingState='California', ShippingCountry='United States', ShippingPostalcode='94820', EffectiveDate=System.Today(), Status='Shipped',Rubrik_Sales_Engineer__c='goforward@rubrik.com'
           
		);
		insert test_order;
        
        
		
        Product2 pd = new Product2(Name='Pord A',ProductCode='ProductXYZ',isActive=true);
    pd.IsActive = true;
    insert pd;
    Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=pricebookId, Product2Id=pd.Id, UnitPrice=99, isActive=true);
    insert pbe;
        List<OrderItem> lstOrdrItems = new List<OrderItem>{
        new OrderItem(
          OrderId = test_order.Id,
          Quantity = 5,
          PricebookEntryId = pbe.Id,
          UnitPrice = pbe.UnitPrice,
          SerialNumber__c = 'S3F4NXMM416324',
          Failed_Serial_Number__c = 'S3F4NXM416324',
          Support_End_Date__c = System.Today().addYears(1),
          Support_Start_Date__c = System.Today()
        )
      };

      insert lstOrdrItems;
        
		POC__c poc = new POC__c(
			Opportunity__c=test_oppty.Id, Planned_Installation_Date__c=System.today().addDays(10), POC_Qty__c=1, Shipping_Company_Name__c=test_account.Id,
			Order__c=test_order.Id, Support_Awareness_needed__c='No', Contact__c=test_contact.Id, POC_Type__c = 'Standard POC'
		);
		insert poc;
        test_order.POC_Request__c= poc.Id;
        update test_order;
		Test.startTest();
		DataBase.executeBatch(new AssetExpirationBatch());
		System.schedule('Test', '0 0 3 4 * ?', new AssetExpirationBatch());
		Test.stopTest();

		POC__c test_poc = [SELECT Id, Last_Expiration_Notification_Sent__c FROM POC__c];
		System.assertNotEquals(null, test_poc.Last_Expiration_Notification_Sent__c);

		AssetExpirationBatch aeb = new AssetExpirationBatch(new ApexPages.StandardController(test_poc));
		aeb.send_email_page_action();
	}

}