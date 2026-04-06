@isTest
private class PR_Request_Service_isTest{
    @testSetup static void setupMethod() {
        List<Partner_Page_Configuration__c> pageList = new List<Partner_Page_Configuration__c>();
        List<Contact> contList = new List<Contact>();
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        Profile profile1 = [Select Id from Profile where name = 'System Administrator'];

        User portalAccountOwner1 = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() + 'testpuser211@test.com',
            Alias = 'batman11',
            Email='bruce.wayne11@wayneenterprises.com',
            EmailEncodingKey='UTF-8',
            Firstname='Bruce',
            Lastname='Wayne',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago'
        );
        Database.insert(portalAccountOwner1);
        System.runAs ( portalAccountOwner1 ) {
            insert new ShGl_DisableBusinessLogic__c(SetupOwnerId=UserInfo.getOrganizationId(), Disable_PartnerRegRequest_Triggers__c=true);
            Account portalAccount1 = new Account(
                Name = 'TestAccount11',
                OwnerId = portalAccountOwner1.Id,
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId()
                //Focused_Partner__c = true
            );
            Database.insert(portalAccount1);
            
            //Create contact
            Contact contact1 = new Contact(
                FirstName = 'Test11',
                Lastname = 'McTesty11',
                AccountId = portalAccount1.Id,
                Email = System.now().millisecond() + 'test@test.com',
                Primary_Role__c = 'Admin'
            );
            contList.add(contact1);
            insert contList;
            
            Profile portalProfile = [SELECT Id FROM Profile Where Name='Rubrik Partner community Manager' Limit 1];
            User user1 = new User(
                Username = System.now().millisecond() + 'tespuser133@test.com',
                ContactId = contact1.Id,
                ProfileId = portalProfile.Id,
                Alias = 'test3',
                Email = 'test1233345@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'McTestyyy',
                CommunityNickname = 'test1234533',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            Database.insert(user1);
        }
    }
	//Commented as only coverage required for PR_Request_Main Trigger
    /*static testMethod void createPRRequest(){
        CountryWithCode__c CountrySetting1 = new CountryWithCode__c();
        CountrySetting1.Name = 'United States';
        CountrySetting1.Code__c = 'US';
        insert CountrySetting1;
        CountryWithCode__c countrySetting2 = new CountryWithCode__c();
        countrySetting2.Name = 'Canada';
        countrySetting2.Code__c = 'CA';
        insert CountrySetting2;

        StateCodeName__C stateSetting1 = new StateCodeName__C();
        stateSetting1.Name = 'US-AL';
        stateSetting1.State_Name__c = 'Alabama';
        insert stateSetting1;
        StateCodeName__C stateSetting2 = new StateCodeName__C();
        stateSetting2.Name = 'US-CA';
        stateSetting2.State_Name__c = 'California';
        insert stateSetting2;
        PageReference pageRef = Page.PartnerRegistrationForm;
        Test.setCurrentPage(pageRef);
        Partner_Registration_Request__c PR_Rec = new Partner_Registration_Request__c(
            First_Name__c = 'Test', 
            Last_Name__c = 'Last Name is_Test_class', 
            Company_Name__c = 'Test Company', 
            Email__c = 'test@test123.com', 
            Phone_Number__c = '1234567890', 
            Address__c = 'test street', 
            City__c = 'test City', 
            Country__c = 'United States', 
            Country_Picklist__c = 'United States', 
            State__c = 'CA', 
            Postal_Code__c = '93506', 
            Partner_Registration_Status__c = 'Submitted', 
            is_Converted__c = false
        );
        ApexPages.StandardController sc = new ApexPages.standardController(PR_Rec);

        PartnerRegistrationRequestExtension PRExtn = new PartnerRegistrationRequestExtension(sc);
        PRExtn.isitRequired();
        PRExtn.zipLength();
        PRExtn.saveRequest();
    }*/

    static testMethod void convertPRRequestToContact(){
		User u = [SELECT Id FROM User WHERE Email = 'bruce.wayne11@wayneenterprises.com'];
		System.runAs(u){
			CountryWithCode__c CountrySetting1 = new CountryWithCode__c();
			CountrySetting1.Name = 'United States';
			CountrySetting1.Code__c = 'US';
			insert CountrySetting1;
			CountryWithCode__c countrySetting2 = new CountryWithCode__c();
			countrySetting2.Name = 'Canada';
			countrySetting2.Code__c = 'CA';
			insert CountrySetting2;

			StateCodeName__C stateSetting1 = new StateCodeName__C();
			stateSetting1.Name = 'US-AL';
			stateSetting1.State_Name__c = 'Alabama';
			insert stateSetting1;
			StateCodeName__C stateSetting2 = new StateCodeName__C();
			stateSetting2.Name = 'US-CA';
			stateSetting2.State_Name__c = 'California';
			insert stateSetting2;
			
			WorkflowTriggerBypass__c wfSetting = new WorkflowTriggerBypass__c();
			wfSetting.Name = 'PRRequestMainTrigger';
			wfSetting.ByPassTrigger__c = false;
			insert wfSetting;
			
			insert new ShGl_DisableFunctionalityLogic__c(SetupOwnerId=UserInfo.getOrganizationId(), Allow_account_Transfer__c=true);
			
			
			Account accRec = ShGl_TestFactory.testMethod_PartnerAccount('Test Account');
			accRec.Name = 'Test Company 2';
			accRec.Website = 'www.TestCompany2.com';
			accRec.BillingCountry = 'United States';
			accRec.type = 'Reseller';
			accRec.OwnerId = UserInfo.getUserId();
			update accRec;
	 
			List<Contact> conList = ShGl_TestFactory.testMethod_PartnerContact(1, accRec);
			List<String> conIdList = new List<String>();
			conIdList.add(conList[0].Id);
			
			Test.startTest();
			List<User> userList = ShGl_TestFactory.testMethod_PartnerUser(1, conList);
			Test.stopTest();
			
			PR_Request_Service.updateUser(conIdList);
			
			Partner_Registration_Request__c prTestRecord = new Partner_Registration_Request__c(
				First_Name__c = 'Test 2', 
				Last_Name__c = 'Last Name is_Test_class 2', 
				Company_Name__c = 'Test Company 2', 
				Email__c = 'test@testnewcontact.com', 
				Phone_Number__c = '1234567890', 
				Address__c = 'test street', 
				City__c = 'test City', 
				Country__c = 'United States', 
				Country_Picklist__c = 'United States', 
				State__c = 'CA', 
				Partner_Registration_Status__c = 'Submitted', 
				is_Converted__c = false, 
				Partner_Account_Lookup__c = accRec.Id
			);
			insert prTestRecord;
			Partner_Registration_Request__c queryRecord = [select id, Last_Name__c, First_Name__c, Partner_Registration_Status__c, is_Converted__c
														   from Partner_Registration_Request__c
														   where Last_Name__c = 'Last Name is_Test_class 2'
														   LIMIT 1];
			system.assertEquals(queryRecord.Last_Name__c, 'Last Name is_Test_class 2');
			system.assertEquals(queryRecord.Partner_Registration_Status__c, 'Submitted');
			system.assertEquals(queryRecord.is_Converted__c, false);
			queryRecord.Partner_Registration_Status__c = 'Approved';
			queryRecord.is_Converted__c = true;
			TriggerControl__c setting = new TriggerControl__c();
			setting.Name = 'Contact';
			setting.DisableTrigger__c = False;
			insert setting;
			update queryRecord;
			Partner_Registration_Request__c queryRecordAfterUpdate = [select id, Last_Name__c, First_Name__c, Partner_Registration_Status__c, is_Converted__c
																	  from Partner_Registration_Request__c
																	  where Last_Name__c = 'Last Name is_Test_class 2'
																	  LIMIT 1];
			system.assertEquals(queryRecordAfterUpdate.Partner_Registration_Status__c, 'Approved', 'Status is scuessefully Approved');
			//system.assertEquals(queryRecordAfterUpdate.is_Converted__c, true);
		}
    }

	//Commented as only coverage required for PR_Request_Main Trigger
    /*static testMethod void convertPRRequestToContactTest(){
        Test.startTest();
        Account accRec = ShGl_TestFactory.testMethod_PartnerAccount('Test Account');
        accRec.Name = 'PARTNER_MSP ';
        accRec.Website = 'www.test3.com';
        accRec.BillingCountry = 'United States';
        accRec.type = 'Reseller';
        update accRec;
        List<Contact> lstContact = ShGl_TestFactory.testMethod_PartnerContact(1, accRec);
        lstContact[0].MailingCountry = 'United States';
        update lstContact;
        Partner_Registration_Request__c pr = new Partner_Registration_Request__c();
        pr.First_Name__c = 'test partner0';
        pr.Last_Name__c = 'request0';
        pr.Address__c = 'test address';
        pr.State__c = 'testState';
        pr.Country__c = 'United States';
        pr.Company_Name__c = accRec.Name;
        pr.Email__c = lstContact[0].email;
        pr.State_Picklist__c = 'AZ';
        pr.Country_Picklist__c = 'United States';
        insert pr;

        List<Partner_Registration_Request__c> lstPR = new List<Partner_Registration_Request__c>();
        lstPR.add(pr);
        PR_Request_Service.convertPRtoContact(lstPR);
        Test.stopTest();
    }

    static testMethod void convertPRRequestToContactTest2(){
        Test.startTest();
        Account accRec = ShGl_TestFactory.testMethod_PartnerAccount('Test Account');
        accRec.Name = 'PARTNER_MSP';
        accRec.Website = 'www.test3.com';
        accRec.BillingCountry = 'United States';
        accRec.type = 'Reseller';
        update accRec;
        List<Contact> lstContact = ShGl_TestFactory.testMethod_PartnerContact(1, accRec);
        lstContact[0].MailingCountry = 'United States';
        update lstContact;
        Partner_Registration_Request__c pr = new Partner_Registration_Request__c();
        pr.First_Name__c = 'test partner1';
        pr.Last_Name__c = 'request1';
        pr.Address__c = 'test address';
        pr.State__c = 'testState';
        pr.Country__c = 'United State';
        pr.Company_Name__c = 'PARTNER_MSP';
        pr.Email__c = 'abc@a.com0';
        pr.State_Picklist__c = 'AZ';
        pr.Country_Picklist__c = 'United States';
        pr.Partner_Account_Lookup__c = accRec.Id;
        insert pr;
        List<Partner_Registration_Request__c> lstPR = new List<Partner_Registration_Request__c>();
        lstPR.add(pr);
        PR_Request_Service.convertPRtoContact(lstPR);
        Test.stopTest();
    }
    
    static testMethod void convertPRRequestToContactTest3(){
        Account accRec = [SELECT Id from Account WHERE Name='TestAccount11' LIMIT 1];
        User u = [SELECT Id,UserType from USer WHERE LastName = 'McTestyyy'];
        Partner_Registration_Request__c pr = new Partner_Registration_Request__c();
        pr.First_Name__c = 'test partner';
        pr.Last_Name__c = 'request';
        pr.Address__c = 'test address';
        pr.State__c = 'testState';
        pr.Country__c = 'United State';
        pr.Company_Name__c = 'PARTNER_MSP';
        pr.Email__c = 'test1233345@test.com';
        pr.State_Picklist__c = 'AZ';
        pr.Country_Picklist__c = 'United States';
        pr.Partner_Account_Lookup__c = accRec.Id;
        pr.Admin_Access__c = true;
        insert pr;
        test.startTest();
        PR_Request_Service.convertPRtoContact(new List<Partner_Registration_Request__c>{pr});
        test.stoptest();
        System.assert(true);
    }*/

}