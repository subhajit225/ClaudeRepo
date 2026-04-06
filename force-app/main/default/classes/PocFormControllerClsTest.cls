@isTest
public class PocFormControllerClsTest {
    
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
        insert new ShGl_DisableBusinessLogic__c(Disable_POC_Trigger__c = true, Disable_POC_Validation_Rules__c=true, Disable_Opportunity_Triggers__c = true,
				setupOwnerId = userinfo.getuserid());
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        User sysAdmin;
        System.runAs(thisUser) {
            Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
            UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
            User sysAdminManager = new User(
                UserRoleId = portalRole.Id,
                ProfileId = profile1.Id,
                Username = System.now().millisecond() + 'sysAdmin@randomtestdomain.com',
                Alias = 'batman',
                Email = System.now().millisecond() + 'random.email@randomtestdomain.com',
                EmailEncodingKey = 'UTF-8',
                Firstname = 'test new',
                Lastname = 'test',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'America/Chicago',
                ManagerId = thisUser.Id
            );
            Database.insert(sysAdminManager);
            
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
                TimeZoneSidKey = 'America/Chicago',
                ManagerId = sysAdminManager.id,
                POC_Approver__c=sysAdminManager.id
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
            acct.Agreed_To_POC_terms__c = true;
            acct.Partner_Agreement_Status__c = 'Signed - Active';
            insert acct;
            Contact objContact = new Contact();
            objContact.AccountId = acct.Id;
            objContact.LastName = 'Test Contact';
            objContact.Email = 'test.abc@testing.com';
            insert objContact; 

            OpportunityStage stage = [SELECT MasterLabel FROM OpportunityStage WHERE IsWon = false AND IsClosed = false AND isActive = true LIMIT 1];
            Opportunity opp = new Opportunity(
                Name = 'Test Opp',
                AccountId = acct.Id,
                StageName = stage.MasterLabel,
                CloseDate = System.today().addDays(15),
                PriceBook2Id = system.label.CPQPricebookID,
                SBQQ__QuotePricebookId__c = system.label.CPQPricebookID,
                Alliance_Partner_Name__c = 'Amazon',
                Alliance_Source_Type__c = 'Alliance Initiated Deal',
                Alliance_Source_Type_SW__c = 'Test',
                Compelling_Bus_Driver__c = 'Instant Recovery',
                Current_State__c = 'test',
                Negative_Consequences__c = 'test',
                Future_State__c = 'test',
                Positive_Business_Outcomes__c = 'test',
                Distributor_Lookup__c = acct.Id,
                Opportunity_Sub_Type__c = 'MSP Overage',
                Opportunity_Type__c = 'New Customer',
                Rubrik_Sales_Engineer__c = UserInfo.getUserId(),
                Win_Loss_Comments__c = 'test',
                Primary_Competitor__c = 'Actifio',
                Key_Feature_Needs__c = 'None',
                Valooto_Quote__c = '123123123',
                Valooto_Quote_Stage__c = 'Approved',
                Partner_Level_Of_Involvement__c = '1.Rubrik initiated, Partner was fulfillment only',
                Cloud_Type__c = 'IBM'
            );

            opp.Partner_Lookup__c = acct.Id;
            opp.ETM_Theatre__c = 'AMER';
            opp.ETM_Region__c = 'BENELUX';
            insert opp;
            
            map<String,String> validationMap = PocFormControllerCls.validateCheck(opp.Id);
        }
        
        Pricebook2 pricebook = new Pricebook2(Id = Test.getStandardPricebookId());
        Product2 newProd = new Product2(Name = 'Polaris', family = 'Polaris', ProductCode = 'Polaris', RWD_LicenseAddons_Category__c=null);
        insert newProd;
        
        PriceBook2 customPriceBook  = new PriceBook2 (Name='CPQ PriceBook', IsActive=true);
        insert customPriceBook;
        
        Id standardPBId = pricebook.id;
        
        PriceBookEntry pbEntry = new PriceBookEntry(
            UnitPrice = 400,
            PriceBook2Id = pricebook.id,
            Product2Id = newProd.Id,
            IsActive = true,
            UseStandardPrice=false);
        insert pbEntry ;
        
        PriceBookEntry pbEntryC = new PriceBookEntry(
            UnitPrice = 400,
            PriceBook2Id = system.label.CPQPricebookID,
            Product2Id = newProd.Id,
            IsActive = true
            );
        insert pbEntryC ;
        
    }
    @isTest
    static void testOpportunityController() {
        Opportunity opp = [SELECT id,Name,OwnerId,Owner.Name,PartnerAccount.Name,
           Partner_Lookup__r.Name,Account.name,Distributor_Rep_Name__c,StageName,Partner_Lookup__c
           ,Partner_Lookup__r.Partner_Agreement_Status__c,Distributor_Lookup__c,Distributor_Lookup__r.Name,
           Distributor_Lookup__r.Partner_Agreement_Status__c,Partner_Lookup__r.Agreed_To_POC_terms__c
          ,Account.ShippingCountry,Account.ShippingStreet,Account.ShippingCity,
          Account.ShippingStateCode,
          Account.ShippingPostalCode,Pricebook2Id FROM Opportunity WHERE Name = :'Test Opp' LIMIT 1];
        POC__c pocRequest = new POC__c();

        POC__c poc = new POC__c();
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
        
        PocFormControllerCls.response_Wrapper pocFrom = new PocFormControllerCls.response_Wrapper();
        PocFormControllerCls.response_Wrapper pocFrom1 = new PocFormControllerCls.response_Wrapper();
        PocFormControllerCls.response_Wrapper pocFromResult = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp.filename='TestFilename.txt';
        fileListInsertTemp.base64='Test Content';
        fileListInsert.add(fileListInsertTemp);
        pocFrom.selected_UCL_RCVBackup = 1;
        pocFrom.selectedUCLRCVBackupZone = 'Single Zone';
        pocFrom.numberOfRCVTB = 1;
        pocFrom.storageRegion = 'Rubrik Hosted';
        
        

        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Virtual Lab';
        newPOCRequest.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest.POC_Qty__c = 10;
        newPOCRequest.POC_Justification__c = 'Test Justification';
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest.Approval_Status__c = 'Extension Requested';
        newPOCRequest.Number_of_Users__c = 5;
        insert newPOCRequest;
        
        Test.startTest();
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser) {
        pocFrom = PocFormControllerCls.retrunDefaultValuetoFrom(opp.Id);
        pocFrom1 = PocFormControllerCls.retrunDefaultValuetoFrom(newPOCRequest.Id);
		List<String> fileUpload = PocFormControllerCls.uploadFile(fileListInsert,opp.Id);
            System.assertNotEquals(pocFrom, null);
        }
        Test.stopTest();
    }
    
    @isTest
    static void testOpportunityControllertwo() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Name = :'Test Opp' LIMIT 1];

        POC__c pocRequest = new POC__c();
        
        POC__c poc = new POC__c();
        poc.Planned_Installation_Date__c = Date.today().addDays(8);
        poc.POC_Type__c = 'Standard POC';
        poc.Most_Recent_End_Date__c = System.Today();
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
        poc.RCV_Archive_Tier__c='No';
        poc.RCV_Backup_Tier__c='No';
        poc.Product_Categories__c='Rubrik Cloud Vault';

        poc.AWS_Customer_Account_Id__c = '123123123123';
        poc.AWS_Customer_Account_Region__c = 'us-east-1';

        poc.Try_Buy_Agreement__c = true;

        poc.Partner_Disty_Signed_POC_Addendum__c = 'Yes';
        poc.Disty_with_Signed_POC_Addendum__c = opp.AccountId;
        poc.Other_Accessories__c = 'test';
        poc.Ownerid=UserInfo.getUserId();
        PocFormControllerCls.response_Wrapper pocFrom = new PocFormControllerCls.response_Wrapper();
        PocFormControllerCls.response_Wrapper pocFromResult = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp.filename='TestFilename.txt';
        fileListInsertTemp.base64='Test Content';
        fileListInsert.add(fileListInsertTemp);
      
        Test.startTest();
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser) {
		    pocFrom.pocRequestObj=poc;
        pocFromResult = PocFormControllerCls.submitPOCRequest(pocFrom,fileListInsert,'false');
        
        Date inputDate = system.today();
	    	Date expectedEndDate = system.today();
        PocFormControllerCls.validateInstallationDate(inputDate,'PlanDateLogic','7','Standard POC',expectedEndDate);
        PocFormControllerCls.validateInstallationDate(inputDate,'ExpectedDateLogic','7','Standard POC',expectedEndDate);
        PocFormControllerCls.validateInstallationDate(inputDate,'PlanDateLogic','7','WEB TYR BUY',expectedEndDate);
        PocFormControllerCls.validateInstallationDate(inputDate,'ExpectedDateLogic','7','WEB TYR BUY',expectedEndDate);
        
        Date inputDate1 = system.today().addDays(5);
		    Date expectedEndDate1 = system.today().addDays(200);
        
        PocFormControllerCls.validateInstallationDate(inputDate1,'PlanDateLogic','180','Standard POC',expectedEndDate1);
        PocFormControllerCls.validateInstallationDate(inputDate1,'ExpectedDateLogic','14','Virtual Lab',expectedEndDate1);
        PocFormControllerCls.validateInstallationDate(inputDate1,'PlanDateLogic','7','WEB TYR BUY',expectedEndDate1);
        PocFormControllerCls.validateInstallationDate(inputDate1,'ExpectedDateLogic','7','WEB TYR BUY',expectedEndDate1);
        
        Date inputDate2 = system.today().addDays(-5);
		    Date expectedEndDate2 = system.today().addDays(10);
        
         
        PocFormControllerCls.validateInstallationDate(inputDate2,'ExpectedDateLogic','14','Virtual Lab',expectedEndDate2);
        PocFormControllerCls.validateInstallationDate(inputDate2,'PlanDateLogic','30','Web Try and Buy',expectedEndDate2);
        
        List<String> StateList  = PocFormControllerCls.getStatebyCountry('United States');

            System.assertNotEquals(StateList, null);
 
         Test.stopTest();
        }

    }
    
    @isTest
    static void testOpportunityControllerfour() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Name = :'Test Opp' LIMIT 1];

        POC__c pocRequest = new POC__c();

        POC__c poc = new POC__c();
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
        poc.RCV_Archive_Tier__c='Yes';
        poc.Archive_TB__c=12;
        poc.Product_Categories__c='Rubrik Cloud Vault';

        poc.AWS_Customer_Account_Id__c = '123123123123';
        poc.AWS_Customer_Account_Region__c = 'us-east-1';

        poc.Try_Buy_Agreement__c = true;

        poc.Partner_Disty_Signed_POC_Addendum__c = 'Yes';
        poc.Disty_with_Signed_POC_Addendum__c = opp.AccountId;
        poc.Other_Accessories__c = 'test';
        poc.Ownerid=UserInfo.getUserId();
        
        PocFormControllerCls.response_Wrapper pocFrom = new PocFormControllerCls.response_Wrapper();
        PocFormControllerCls.response_Wrapper pocFromResult = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp.filename='TestFilename.txt';
        fileListInsertTemp.base64='Test Content';
        fileListInsert.add(fileListInsertTemp);
        
        Test.startTest();
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser) {
		    pocFrom.pocRequestObj=poc;        
        pocFromResult = PocFormControllerCls.submitPOCRequest(pocFrom,fileListInsert,'false');
        
        Date inputDate = system.today();
		    Date expectedEndDate = system.today();
        PocFormControllerCls.validateInstallationDate(inputDate,'PlanDateLogic','7','Standard POC',expectedEndDate);
        PocFormControllerCls.validateInstallationDate(inputDate,'ExpectedDateLogic','7','Standard POC',expectedEndDate);
        PocFormControllerCls.validateInstallationDate(inputDate,'PlanDateLogic','7','WEB TYR BUY',expectedEndDate);
        PocFormControllerCls.validateInstallationDate(inputDate,'ExpectedDateLogic','7','WEB TYR BUY',expectedEndDate);
        
        Date inputDate1 = system.today().addDays(5);
		    Date expectedEndDate1 = system.today().addDays(200);
        
        PocFormControllerCls.validateInstallationDate(inputDate1,'PlanDateLogic','180','Standard POC',expectedEndDate1);
        PocFormControllerCls.validateInstallationDate(inputDate1,'ExpectedDateLogic','14','Virtual Lab',expectedEndDate1);
        PocFormControllerCls.validateInstallationDate(inputDate1,'PlanDateLogic','7','WEB TYR BUY',expectedEndDate1);
        PocFormControllerCls.validateInstallationDate(inputDate1,'ExpectedDateLogic','7','WEB TYR BUY',expectedEndDate1);
        
        Date inputDate2 = system.today().addDays(-5);
		    Date expectedEndDate2 = system.today().addDays(10);
        
        PocFormControllerCls.validateInstallationDate(inputDate2,'ExpectedDateLogic','14','Virtual Lab',expectedEndDate2);
        PocFormControllerCls.validateInstallationDate(inputDate2,'PlanDateLogic','30','Web Try and Buy',expectedEndDate2);
        PocFormControllerCls.validateInstallationDate(inputDate2,'','30','Web Try and Buy',expectedEndDate2);
        
        List<String> StateList  = PocFormControllerCls.getStatebyCountry('United States');
            System.assertNotEquals(StateList, null);
        }
        Test.stopTest();
    }
    
    @isTest
    static void testOpportunityControllerthree() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Name = :'Test Opp' LIMIT 1];

        POC__c pocRequest = new POC__c();
       
        POC__c poc = new POC__c();
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
		poc.POC_Type__c = 'Standard POC';
        poc.Approval_Status__c = 'Extension Requested';
        insert poc; 
        
        Test.startTest();
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser) {

            try{
            POC__c pocRecord = PocFormControllerCls.getPOCRequestDetails(poc.id);
        PocFormControllerCls.submitforPOCRequestApprovalProcress(poc.Id);
            System.assertNotEquals(pocRecord, null);
            } catch(Exception e){
                String msg = e.getMessage();
            }
        }
        
        Test.stopTest();
    }

    @isTest 
    static void testUpdatePOCRequest() {

        List<POC__c> poc_ls = new List<POC__c>();

        POC__c poc1 = new POC__c();
        poc1.Planned_Installation_Date__c = Date.today().addDays(8);
        poc1.POC_Type__c = 'Web Try and Buy';
        poc1.POC_Duration__c = '30 Days';
        poc1.POC_Relocation__c = 'No';
        poc1.POC_Justification__c = 'test';
        poc1.Ranger_Support_Expected__c = true;
        poc1.Approval_Status__c = 'Extension Requested';
        poc1.Number_of_Extensions__c = 1;

        poc_ls.add(poc1);

        POC__c poc2 = new POC__c();
        poc2.Planned_Installation_Date__c = Date.today().addDays(8);
        poc2.POC_Type__c = 'Web Try and Buy';
        poc2.POC_Duration__c = '30 Days';
        poc2.POC_Relocation__c = 'No';
        poc2.POC_Justification__c = 'test';
        poc2.Ranger_Support_Expected__c = true;
        poc2.Approval_Status__c = 'Extension Requested';

        poc_ls.add(poc2);

        POC__c poc3 = new POC__c();
        poc3.Planned_Installation_Date__c = Date.today().addDays(8);
        poc3.POC_Type__c = 'Web Try and Buy';
        poc3.POC_Duration__c = '30 Days';
        poc3.POC_Relocation__c = 'No';
        poc3.POC_Justification__c = 'test';
        poc3.Ranger_Support_Expected__c = true;
        poc3.Approval_Status__c = 'Rejected';

        poc_ls.add(poc3);
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser) { 
        insert poc_ls;
            System.assertNotEquals(thisUser, null);
        }
    }

    @isTest
    static void testSubmitRequest() {

        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Virtual Lab';
        newPOCRequest.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest.POC_Qty__c = 10;
        newPOCRequest.POC_Justification__c = 'Test Justification';
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        insert newPOCRequest;

        Product2 newProd = new Product2(Name = 'Polaris', family = 'Polaris', ProductCode = 'Polaris', RWD_LicenseAddons_Category__c=null);
        insert newProd;

        Asset objAsset1 = new Asset();
        objAsset1.SerialNumber = 'AS010AS010AS010';
        objAsset1.Name = 'Test Asset';
        objAsset1.POC_Request__c = newPOCRequest.Id;
        objAsset1.AccountId = [Select Id From Account LIMIT 1].Id;
        objAsset1.Product2Id = newProd.Id;
        insert objAsset1;


        POC_Return__c objReturn = new POC_Return__c();
        objReturn.Pick_up_Street__c = 'Test FFF';
        objReturn.Pick_up_City__c = 'TTE';
        objReturn.Pickup_Country__c = 'United States';
        objReturn.Pick_up_zip_code__c = '1212121';
        objReturn.Additional_Shipping_Notes__c = 'Test Area';
        objReturn.Return_to_Rubrik_warehouse__c = true;
        objReturn.Delivery_User__c = UserInfo.getUserId();
        objReturn.Delivery_Contact_Name__c = 'Test';
        objReturn.Delivery_Email__c = 'Test@Email.com';
        objReturn.Delivery_Phone__c = '121212121';
        objReturn.Delivery_Street__c = 'Test ySetr';
        objReturn.Delivery_City__c = 'NewYork';
        objReturn.Delivery_Country__c = 'United States';
        objReturn.Delivery_Zip_code__c = '1212121223';
        objReturn.Delivery_State__c = 'New York';
        objReturn.Pick_up_State__c = 'New York'; 	 
        objReturn.POC_Request__c = newPOCRequest.Id;
        objReturn.status__c = 'Draft';
        objReturn.Available_Pick_Up_Day__c = Date.today().addDays(10);
        //insert objReturn;

        List<POC_Return_Item__c> pocReturnItemList = new List<POC_Return_Item__c>();

        POC_Return_Item__c returnItem = new POC_Return_Item__c();
        returnItem.Damage_Details__c = null;
        returnItem.Damage_Reported_by_the_customer__c = false;
        returnItem.Data_Erase_Requested__c = false;
        returnItem.Asset__c = objAsset1.Id;
        returnItem.Name = newProd.Name + '-Return';
        returnItem.Product__c = newProd.Id;
        returnItem.Original_Packaging_Available__c = false;
        returnItem.Serial_Number__c = objAsset1.SerialNumber;
        returnItem.complete_a_SD_Reset__c = false;
        returnItem.POC_Return__c = objReturn.Id;

        pocReturnItemList.add(returnItem);

        //insert pocReturnItemList;


        Test.startTest();
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser) {
        PocFormControllerCls.response_Wrapper res = PocFormControllerCls.submitRequest(objReturn , pocReturnItemList);
        PocFormControllerCls.response_Wrapper resp = PocFormControllerCls.getOrders(newPOCRequest.Id);
            System.assertNotEquals(res, null);

        }
        Test.stopTest();
    }

    @isTest
    static void testValidateExpectedEndDate() {

        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Virtual Lab';
        newPOCRequest.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest.POC_Qty__c = 10;
        newPOCRequest.POC_Justification__c = 'Test Justification';
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest.Most_Recent_End_Date__c = System.Today();
        insert newPOCRequest;

        POC__c newPOCRequest1 = new POC__c();
        newPOCRequest1.POC_Type__c = 'Partner Software Access';
        newPOCRequest1.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest1.POC_Qty__c = 10;
        newPOCRequest1.POC_Justification__c = 'Test Justification';
        newPOCRequest1.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest1.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest1.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest1.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
		newPOCRequest1.Most_Recent_End_Date__c = System.Today();
        insert newPOCRequest1;

        POC__c newPOCRequest2 = new POC__c();
        newPOCRequest2.POC_Type__c = 'Standard POC';
        newPOCRequest2.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest2.POC_Qty__c = 10;
        newPOCRequest2.POC_Justification__c = 'Test Justification';
        newPOCRequest2.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest2.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest2.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest2.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest2.Most_Recent_End_Date__c = System.Today();
        insert newPOCRequest2;

        Test.startTest();
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser) {

        Map<String , String> mp = PocFormControllerCls.validateExpectedEndDate(newPOCRequest.Id, 'ExpectedDateLogic', Date.today());
        Map<String , String> mp1 = PocFormControllerCls.validateExpectedEndDate(newPOCRequest.Id, 'ExpectedDateLogic', Date.today().addDays(21));
        Map<String , String> mp2 = PocFormControllerCls.validateExpectedEndDate(newPOCRequest1.Id, 'ExpectedDateLogic', Date.today());
        Map<String , String> mp3 = PocFormControllerCls.validateExpectedEndDate(newPOCRequest1.Id, 'ExpectedDateLogic', Date.today().addDays(21));
        Map<String , String> mp4 = PocFormControllerCls.validateExpectedEndDate(newPOCRequest2.Id, 'ExpectedDateLogic', Date.today());
        Map<String , String> mp5 = PocFormControllerCls.validateExpectedEndDate(newPOCRequest2.Id, 'ExpectedDateLogic', Date.today().addDays(21));
        List<POC_Product_Picker_Matrix__mdt> pocProductPickerList = PocFormControllerCls.getProductSKUs();
            System.assertNotEquals(mp, null);
        }
        Test.stopTest();
    }

    @isTest
    static void testValidateExpectedEndDate2() {
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Virtual Lab';
        newPOCRequest.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest.POC_Qty__c = 10;
        newPOCRequest.POC_Justification__c = 'Test Justification';
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest.Most_Recent_End_Date__c = System.Today();
        insert newPOCRequest;

        Test.startTest();
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser) {

        Map<String , String> mp = PocFormControllerCls.validateExpectedEndDate(newPOCRequest.Id, 'ExpectedDateLogic', Date.today());
        Map<String , String> mp1 = PocFormControllerCls.validateExpectedEndDate(newPOCRequest.Id, 'ExpectedDateLogic', Date.today().addDays(21));
        Map<String , String> mp2 = PocFormControllerCls.validateExpectedEndDate(newPOCRequest.Id, null, Date.today().addDays(21));
            System.assertNotEquals(mp, null);
        }
        Test.stopTest();

    }

    @isTest
    static void testGetProductCustomMetadata1() {
        Test.startTest();
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser) {

        PocFormControllerCls.getProductCustomMetadata1();
            System.assertNotEquals(thisUser, null);
        }
        Test.stopTest();
    }

    @isTest
    static void testPopulateEmailsOnPoc() {
        List<Id> pocIdList = new List<Id>();

        Opportunity opp1 = [Select Id From Opportunity LIMIT 1];
        opp1.ETM_Theatre__c = 'AMER';
        opp1.ETM_Region__c = 'BENELUX';
        update opp1;

        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Virtual Lab';
        newPOCRequest.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest.POC_Qty__c = 10;
        newPOCRequest.POC_Justification__c = 'Test Justification';
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Opportunity__c = opp1.Id;
        insert newPOCRequest;

        POC__c newPOCRequestId = [select Id from POC__c limit 1];
        pocIdList.add(newPOCRequestId.Id);

        Test.startTest();
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser) {

        PocFormControllerCls.populateEmailsOnPoc(pocIdList);
            System.assertNotEquals(newPOCRequestId.Id, null);
        }
        Test.stopTest();
    }

    @isTest
    static void testPopulateEmailsOnPoc1() {
        List<Id> pocIdList = new List<Id>();

        Opportunity opp1 = [Select Id From Opportunity LIMIT 1];
        opp1.ETM_Theatre__c = 'APAC';
        opp1.ETM_Region__c = 'BENELUX';
        update opp1;

        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Virtual Lab';
        newPOCRequest.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest.POC_Qty__c = 10;
        newPOCRequest.POC_Justification__c = 'Test Justification';
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Opportunity__c = opp1.Id;
        insert newPOCRequest;

        POC__c newPOCRequestId = [select Id from POC__c limit 1];
        pocIdList.add(newPOCRequestId.Id);

        Test.startTest();
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser) {
        
        PocFormControllerCls.populateEmailsOnPoc(pocIdList);
            System.assertNotEquals(newPOCRequestId.Id, null);
        }
        PocFormControllerCls.submitforExtensionApprovalProcress(newPOCRequest.Id);
        Test.stopTest();
    }

    @isTest
    static void testPopulateEmailsOnPoc2() {
        List<Id> pocIdList = new List<Id>();

        Opportunity opp1 = [Select Id From Opportunity LIMIT 1];
        opp1.ETM_Theatre__c = 'EMEA';
        opp1.ETM_Region__c = 'BENELUX';
        update opp1;

        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Virtual Lab';
        newPOCRequest.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest.POC_Qty__c = 10;
        newPOCRequest.POC_Justification__c = 'Test Justification';
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Opportunity__c = opp1.Id;
        insert newPOCRequest;

        POC__c newPOCRequestId = [select Id from POC__c limit 1];
        pocIdList.add(newPOCRequestId.Id);

        Test.startTest();
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser) {

        PocFormControllerCls.populateEmailsOnPoc(pocIdList);
            System.assertNotEquals(newPOCRequestId.Id, null);
        }
        // PocFormControllerCls.submitforExtensionApprovalProcress(newPOCRequest.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetOrders2() {

        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Virtual Lab';
        newPOCRequest.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest.POC_Qty__c = 10;
        newPOCRequest.POC_Justification__c = 'Test Justification';
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);
        newPOCRequest.Approval_Status__c = 'Extension Requested';	
        newPOCRequest.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        insert newPOCRequest;

        Test.startTest();
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser) {

        PocFormControllerCls.response_Wrapper resp = PocFormControllerCls.getOrders(newPOCRequest.Id);
            System.assertNotEquals(resp, null);
        }
        Test.stopTest();
    }

    @isTest
    static void testGetOrders3() {
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Virtual Lab';
        newPOCRequest.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest.POC_Qty__c = 10;
        newPOCRequest.POC_Justification__c = 'Test Justification';
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest.Approval_Status__c = 'Extension Requested';
        insert newPOCRequest;

        Product2 newProd = new Product2(Name = 'Polaris', family = 'Polaris', ProductCode = 'Polaris', RWD_LicenseAddons_Category__c=null);
        insert newProd;

        Asset objAsset1 = new Asset();
        objAsset1.SerialNumber = 'AS010AS010AS010';
        objAsset1.Name = 'Test Asset';
        objAsset1.POC_Request__c = newPOCRequest.Id;
        objAsset1.AccountId = [Select Id From Account LIMIT 1].Id;
        objAsset1.Product2Id = newProd.Id;
        insert objAsset1;

        Test.startTest();
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser) {

        PocFormControllerCls.response_Wrapper resp = PocFormControllerCls.getOrders(newPOCRequest.Id);
            System.assertNotEquals(resp, null);
        }
        Test.stopTest();
    }

    @isTest
    static void testSubmitPOCRequest() {

        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Virtual Lab';
        newPOCRequest.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest.POC_Qty__c = 10;
        newPOCRequest.POC_Justification__c = 'Test Justification';
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest.Approval_Status__c = 'Extension Requested';
        newPOCRequest.Number_of_Users__c = 5;
        newPOCRequest.Product_Categories__c = 'Rubrik Cloud Vault';
        insert newPOCRequest;

        PocFormControllerCls.response_Wrapper obj1 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp.filename='TestFilename.txt';
        fileListInsertTemp.base64='Test Content';
        fileListInsert.add(fileListInsertTemp);

        obj1.pocRequestObj = newPOCRequest;

        POC__c newPOCRequest1 = new POC__c();
        newPOCRequest1.POC_Type__c = 'Virtual Lab';
        newPOCRequest1.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest1.POC_Qty__c = 10;
        newPOCRequest1.POC_Justification__c = 'Test Justification';
        newPOCRequest1.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest1.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest1.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest1.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest1.Approval_Status__c = 'Extension Requested';
        newPOCRequest1.Product_Categories__c = 'Rubrik Cloud Vault';
        newPOCRequest1.RCV_Archive_Tier__c = 'No';
        newPOCRequest1.RCV_Backup_Tier__c = 'No';
        insert newPOCRequest1;

        PocFormControllerCls.response_Wrapper obj2 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert1 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp1 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp1.filename='TestFilename.txt';
        fileListInsertTemp1.base64='Test Content';
        fileListInsert1.add(fileListInsertTemp1);

        obj2.pocRequestObj = newPOCRequest1;

        POC__c newPOCRequest2 = new POC__c();
        newPOCRequest2.POC_Type__c = 'Virtual Lab';
        newPOCRequest2.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest2.POC_Qty__c = 10;
        newPOCRequest2.POC_Justification__c = 'Test Justification';
        newPOCRequest2.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest2.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest2.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest2.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest2.Approval_Status__c = 'Extension Requested';
        newPOCRequest2.Product_Categories__c = 'Rubrik Cloud Vault';
        newPOCRequest2.RCV_Archive_Tier__c = 'Yes';
        newPOCRequest2.Archive_TB__c = 5;
        insert newPOCRequest2;

        PocFormControllerCls.response_Wrapper obj3 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert2 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp2 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp2.filename='TestFilename.txt';
        fileListInsertTemp2.base64='Test Content';
        fileListInsert2.add(fileListInsertTemp2);

        obj3.pocRequestObj = newPOCRequest2;


        POC__c newPOCRequest3 = new POC__c();
        newPOCRequest3.POC_Type__c = 'Virtual Lab';
        newPOCRequest3.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest3.POC_Qty__c = 10;
        newPOCRequest3.POC_Justification__c = 'Test Justification';
        newPOCRequest3.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest3.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest3.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest3.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest3.Approval_Status__c = 'Extension Requested';
        newPOCRequest3.Product_Categories__c = 'Rubrik Cloud Vault';
        newPOCRequest3.RCV_Backup_Tier__c = 'Yes';
        newPOCRequest3.Backup_TB__c = 5;
        insert newPOCRequest3;

        PocFormControllerCls.response_Wrapper obj4 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert3 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp3 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp3.filename='TestFilename.txt';
        fileListInsertTemp3.base64='Test Content';
        fileListInsert3.add(fileListInsertTemp3);

        obj4.pocRequestObj = newPOCRequest3;


        POC__c newPOCRequest4 = new POC__c();
        newPOCRequest4.POC_Type__c = 'Virtual Lab';
        newPOCRequest4.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest4.POC_Qty__c = 10;
        newPOCRequest4.POC_Justification__c = 'Test Justification';
        newPOCRequest4.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest4.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest4.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest4.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest4.Approval_Status__c = 'Extension Requested';
        newPOCRequest4.Product_Categories__c = 'Rubrik Cloud Vault';
        newPOCRequest4.RCV_Backup_Tier__c = 'No';
        newPOCRequest4.Backup_TB__c = 5;
        insert newPOCRequest4;

        PocFormControllerCls.response_Wrapper obj5 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert4 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp4 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp4.filename='TestFilename.txt';
        fileListInsertTemp4.base64='Test Content';
        fileListInsert4.add(fileListInsertTemp4);

        obj5.pocRequestObj = newPOCRequest4;

        // 

        POC__c newPOCRequest5 = new POC__c();
        newPOCRequest5.POC_Type__c = 'Virtual Lab';
        newPOCRequest5.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest5.POC_Qty__c = 10;
        newPOCRequest5.POC_Justification__c = 'Test Justification';
        newPOCRequest5.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest5.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest5.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest5.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest5.Approval_Status__c = 'Extension Requested';
        newPOCRequest5.Product_Categories__c = 'Rubrik Cloud Vault';
        newPOCRequest5.RCV_Archive_Tier__c = 'No';
        newPOCRequest5.Archive_TB__c = 5;
        insert newPOCRequest5;

        PocFormControllerCls.response_Wrapper obj6 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert5 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp5 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp5.filename='TestFilename.txt';
        fileListInsertTemp5.base64='Test Content';
        fileListInsert5.add(fileListInsertTemp5);

        obj6.pocRequestObj = newPOCRequest5;

        //

        
        POC__c newPOCRequest6 = new POC__c();
        newPOCRequest6.POC_Type__c = 'Virtual Lab';
        newPOCRequest6.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest6.POC_Qty__c = 10;
        newPOCRequest6.POC_Justification__c = 'Test Justification';
        newPOCRequest6.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest6.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest6.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest6.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest6.Approval_Status__c = 'Extension Requested';
        newPOCRequest6.Product_Categories__c = 'UCL (Cloud Cluster, Cloud Native & Entra ID)';
        newPOCRequest6.RCV_Archive_Tier__c = 'No';
        newPOCRequest6.Archive_TB__c = 5;
        newPOCRequest6.UCL_Edition__c = 'Basic UCL (No RCV)';
        insert newPOCRequest6;

        PocFormControllerCls.response_Wrapper obj7 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert6 = new List<PocFormControllerCls.fileInnerClass> ();
        /*
        PocFormControllerCls.fileInnerClass fileListInsertTemp6 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp6.filename='TestFilename.txt';
        fileListInsertTemp6.base64='Test Content';
        fileListInsert6.add(fileListInsertTemp5);
        */

        obj7.pocRequestObj = newPOCRequest6;

        List<PocFormControllerCls.fileInnerClass> fileListInsert7 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp7 = new PocFormControllerCls.fileInnerClass ();
        // fileListInsertTemp7.filename='';
        // fileListInsertTemp7.base64 = '';
        fileListInsert7.add(fileListInsertTemp7);
		
		POC__c newPOCRequest7 = new POC__c();
        newPOCRequest7.POC_Type__c = 'Virtual Lab';
        newPOCRequest7.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest7.POC_Qty__c = 10;
        newPOCRequest7.POC_Justification__c = 'Test Justification';
        newPOCRequest7.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest7.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest7.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest7.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest7.Approval_Status__c = 'Extension Requested';
        newPOCRequest7.Product_Categories__c = 'UCL (Cloud Cluster, Cloud Native & Entra ID)';
        newPOCRequest7.RCV_Archive_Tier__c = 'No';
        newPOCRequest7.Archive_TB__c = 5;
        newPOCRequest7.UCL_Edition__c = 'Basic UCL (No RCV)';
		newPOCRequest7.Number_of_Users_Salesforce__c =20;
        newPOCRequest7.Jira_Cloud__c ='Yes';
        newPOCRequest7.Number_of_Users_Atlassian__c =50;
        insert newPOCRequest7;

		PocFormControllerCls.response_Wrapper obj8 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert8 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp8 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp8.filename='TestFilename.txt';
        fileListInsertTemp8.base64='Test Content';
        fileListInsert8.add(fileListInsertTemp8);

        obj8.pocRequestObj = newPOCRequest7;

		POC__c newPOCRequest8 = new POC__c();
        newPOCRequest8.POC_Type__c = 'Virtual Lab';
        newPOCRequest8.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest8.POC_Qty__c = 10;
        newPOCRequest8.POC_Justification__c = 'Test Justification';
        newPOCRequest8.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest8.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest8.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest8.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest8.Approval_Status__c = 'Extension Requested';
        newPOCRequest8.Product_Categories__c = 'UCL (Cloud Cluster, Cloud Native & Entra ID)';
        newPOCRequest8.RCV_Archive_Tier__c = 'No';
        newPOCRequest8.Archive_TB__c = 5;
        newPOCRequest8.UCL_Edition__c = 'Basic UCL (No RCV)';
		newPOCRequest8.Salesforce__c ='Yes';
        insert newPOCRequest8;

		PocFormControllerCls.response_Wrapper obj9 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert9 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp9 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp9.filename='TestFilename.txt';
        fileListInsertTemp9.base64='Test Content';
        fileListInsert9.add(fileListInsertTemp8);

        obj9.pocRequestObj = newPOCRequest8;
		

		POC__c newPOCRequest9 = new POC__c();
        newPOCRequest9.POC_Type__c = 'Virtual Lab';
        newPOCRequest9.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest9.POC_Qty__c = 10;
        newPOCRequest9.POC_Justification__c = 'Test Justification';
        newPOCRequest9.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest9.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest9.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest9.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest9.Approval_Status__c = 'Extension Requested';
        newPOCRequest9.Product_Categories__c = 'UCL (Cloud Cluster, Cloud Native & Entra ID)';
        newPOCRequest9.RCV_Archive_Tier__c = 'No';
        newPOCRequest9.Archive_TB__c = 5;
        newPOCRequest9.UCL_Edition__c = 'Basic UCL (No RCV)';
		newPOCRequest9.Number_of_Users_Atlassian__c =20;
        insert newPOCRequest9;

		PocFormControllerCls.response_Wrapper obj10 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert10 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp10 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp10.filename='TestFilename.txt';
        fileListInsertTemp10.base64='Test Content';
        fileListInsert10.add(fileListInsertTemp9);

        obj10.pocRequestObj = newPOCRequest9;
        
        POC__c newPOCRequest10 = new POC__c();
        newPOCRequest10.POC_Type__c = 'Virtual Lab';
        newPOCRequest10.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest10.POC_Qty__c = 10;
        newPOCRequest10.POC_Justification__c = 'Test Justification';
        newPOCRequest10.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest10.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest10.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest10.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest10.Approval_Status__c = 'Extension Requested';
        newPOCRequest10.Product_Categories__c = 'UCL (Cloud Cluster, Cloud Native & Entra ID)';
        newPOCRequest10.RCV_Archive_Tier__c = 'No';
        newPOCRequest10.Archive_TB__c = 5;
        newPOCRequest10.UCL_Edition__c = 'Basic UCL (No RCV)';
		newPOCRequest10.Number_of_Users_Salesforce__c =20;
        newPOCRequest10.Salesforce__c='No';
        insert newPOCRequest10;

		PocFormControllerCls.response_Wrapper obj11 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert11 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp11 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp11.filename='TestFilename.txt';
        fileListInsertTemp11.base64='Test Content';
        fileListInsert11.add(fileListInsertTemp9);

        obj11.pocRequestObj = newPOCRequest10;
        
        POC__c newPOCRequest11 = new POC__c();
        newPOCRequest11.POC_Type__c = 'Standard POC';
        newPOCRequest11.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest11.POC_Qty__c = 10;
        newPOCRequest11.POC_Justification__c = 'Test Justification';
        newPOCRequest11.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest11.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest11.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest11.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest11.Product_Categories__c = 'UCL (Cloud Cluster, Cloud Native & Entra ID)';
        newPOCRequest11.Storage_Region_Bundle_RCV_Backup__c = null;
        insert newPOCRequest11;

		PocFormControllerCls.response_Wrapper obj12 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert12 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp12 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp12.filename='TestFilename.txt';
        fileListInsertTemp12.base64='Test Content';
        fileListInsert12.add(fileListInsertTemp9);

        obj12.pocRequestObj = newPOCRequest11;
        obj12.uclEdition = 'UCL with Rubrik-hosted Enterprise Edition (With RCV Backup tier)';
        
        
        POC__c newPOCRequest12 = new POC__c();
        newPOCRequest12.POC_Type__c = 'Virtual Lab';
        newPOCRequest12.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest12.POC_Qty__c = 10;
        newPOCRequest12.POC_Justification__c = 'Test Justification';
        newPOCRequest12.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest12.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest12.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest12.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest12.Approval_Status__c = 'Extension Requested';
		newPOCRequest12.Number_of_Users_Atlassian__c =20;
        newPOCRequest12.Jira_Cloud__c='No';
        newPOCRequest12.Hosting_Environment_Salesforce__c='';
        insert newPOCRequest12;

		PocFormControllerCls.response_Wrapper obj13 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert13 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp13 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp13.filename='TestFilename.txt';
        fileListInsertTemp13.base64='Test Content';
        fileListInsert13.add(fileListInsertTemp9);

        obj13.pocRequestObj = newPOCRequest12;
	
        POC__c newPOCRequest13 = new POC__c();
        newPOCRequest13.POC_Type__c = 'Virtual Lab';
        newPOCRequest13.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest13.POC_Qty__c = 10;
        newPOCRequest13.POC_Justification__c = 'Test Justification';
        newPOCRequest13.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest13.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest13.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest13.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest13.Approval_Status__c = 'Extension Requested';
		newPOCRequest13.Number_of_Users_Atlassian__c =20;
        newPOCRequest13.Jira_Cloud__c='Yes';
        newPOCRequest13.Hosting_Environment_Salesforce__c='';
        insert newPOCRequest13;
		
		PocFormControllerCls.response_Wrapper obj14 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert14 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp14 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp14.filename='TestFilename.txt';
        fileListInsertTemp14.base64='Test Content';
        fileListInsert14.add(fileListInsertTemp9);

        obj14.pocRequestObj = newPOCRequest13;

		POC__c newPOCRequest14 = new POC__c();
        newPOCRequest14.POC_Type__c = 'Virtual Lab';
        newPOCRequest14.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest14.POC_Qty__c = 10;
        newPOCRequest14.POC_Justification__c = 'Test Justification';
        newPOCRequest14.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest14.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest14.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest14.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest14.Approval_Status__c = 'Extension Requested';
        newPOCRequest14.How_many_identity_users_are_there__c=0;
        newPOCRequest14.Product_Categories__c ='Identity Recovery and Resilience - AD, Entra ID, Okta';
        newPOCRequest14.Add_Identity_Resilience__c = 'Yes';
        newPOCRequest14.How_many_Identity_UsersAreThere__c = 0;
        newPOCRequest14.Add_Identity_Recovery__c = 'yes';
        insert newPOCRequest14;
        
        PocFormControllerCls.response_Wrapper obj15 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert15 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp15 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp15.filename='TestFilename.txt';
        fileListInsertTemp15.base64='Test Content';
        fileListInsert15.add(fileListInsertTemp9);

        obj15.pocRequestObj = newPOCRequest14;
        
        
        POC__c newPOCRequest15 = new POC__c();
        newPOCRequest15.POC_Type__c = 'Standard POC';
        newPOCRequest15.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest15.POC_Qty__c = 10;
        newPOCRequest15.POC_Justification__c = 'Test Justification';
        newPOCRequest15.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest15.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest15.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest15.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest15.Number_Of_NCD_FETB__c = 2;
        newPOCRequest15.Product_Categories__c ='NAS Cloud Direct';
        newPOCRequest15.RCV_Archive_Tier__c = 'Yes';
        newPOCRequest15.Archive_TB__c = 15;
        newPOCRequest15.Storage_Region_Bundle_RCV_Backup__c = null;
        insert newPOCRequest15;
        
        PocFormControllerCls.response_Wrapper obj16 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert16 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp16 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp14.filename='TestFilename.txt';
        fileListInsertTemp14.base64='Test Content';
        fileListInsert14.add(fileListInsertTemp9);
			
        obj16.pocRequestObj = newPOCRequest15;
        
        
        POC__c newPOCRequest16 = new POC__c();
        newPOCRequest16.POC_Type__c = 'Standard POC';
        newPOCRequest16.Product_Categories__c ='NAS Cloud Direct';
        newPOCRequest16.POC_Qty__c = 10;
        newPOCRequest16.POC_Justification__c = 'Test Justification';
        newPOCRequest16.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest16.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest16.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest16.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest16.Number_Of_NCD_FETB__c = 2;
        newPOCRequest16.RCV_Archive_Tier__c = 'Yes';
        newPOCRequest16.Salesforce__c ='Yes';
        newPOCRequest16.Storage_Region_Bundle_RCV_Backup__c = null;
        newPOCRequest16.Data_Redundancy_Backup_NAS__c = 'Single Zone (LRS)';
        insert newPOCRequest16;
        
		
		PocFormControllerCls.response_Wrapper obj17 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert17 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp17 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp17.filename='TestFilename.txt';
        fileListInsertTemp17.base64='Test Content';
        fileListInsert17.add(fileListInsertTemp17);

        obj17.pocRequestObj = newPOCRequest16;
        
        POC__c newPOCRequest17 = new POC__c();
        newPOCRequest17.POC_Type__c = 'Standard POC';
        newPOCRequest17.Product_Categories__c ='NAS Cloud Direct';
        newPOCRequest17.POC_Qty__c = 10;
        newPOCRequest17.POC_Justification__c = 'Test Justification';
        newPOCRequest17.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest17.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest17.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest17.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest17.Number_Of_NCD_FETB__c = 12;
        newPOCRequest17.RCV_Archive_Tier__c = 'Yes';
        newPOCRequest17.Salesforce__c ='Yes';
        newPOCRequest17.Storage_Region_Bundle_RCV_Backup__c = null;
        newPOCRequest17.Backup_TB__c =12;
        insert newPOCRequest17;
        
		
		PocFormControllerCls.response_Wrapper obj18 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert18 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp18 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp18.filename='TestFilename.txt';
        fileListInsertTemp18.base64='Test Content';
        fileListInsert18.add(fileListInsertTemp17);

        obj18.pocRequestObj = newPOCRequest17;
        
        POC__c newPOCRequest18 = new POC__c();
        newPOCRequest18.POC_Type__c = 'Standard POC';
        newPOCRequest18.Product_Categories__c ='NAS Cloud Direct';
        newPOCRequest18.POC_Qty__c = 10;
        newPOCRequest18.POC_Justification__c = 'Test Justification';
        newPOCRequest18.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest18.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest18.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest18.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest18.Number_Of_NCD_FETB__c = 2;
        newPOCRequest18.RCV_Archive_Tier__c = 'Yes';
        newPOCRequest18.Salesforce__c ='Yes';
        newPOCRequest18.Storage_Region_Bundle_RCV_Backup__c = null;
        newPOCRequest18.Backup_TB__c =2;
        insert newPOCRequest18;
        
		
		PocFormControllerCls.response_Wrapper obj19 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert19 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp19 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp19.filename='TestFilename.txt';
        fileListInsertTemp19.base64='Test Content';
        fileListInsert19.add(fileListInsertTemp18);

        obj19.pocRequestObj = newPOCRequest18;

		POC__c newPOCRequest19 = new POC__c();
        newPOCRequest19.POC_Type__c = 'Standard POC';
        newPOCRequest19.POC_Qty__c = 10;
        newPOCRequest19.POC_Justification__c = 'Test Justification';
        newPOCRequest19.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest19.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest19.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest19.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest19.Number_Of_NCD_FETB__c = 5;
        newPOCRequest19.Product_Categories__c ='NAS Cloud Direct';
        newPOCRequest19.RCV_Archive_Tier__c = 'Yes';
        newPOCRequest19.Salesforce__c ='Yes';
        newPOCRequest19.Storage_Region_Bundle_RCV_Backup__c = null;
        newPOCRequest19.Hosting_Environment_Salesforce__c =null;
        insert newPOCRequest19;
        
		
		PocFormControllerCls.response_Wrapper obj20 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert20 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp20 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp20.filename='TestFilename.txt';
        fileListInsertTemp20.base64='Test Content';
        fileListInsert20.add(fileListInsertTemp20);

        obj20.pocRequestObj = newPOCRequest19;
        
        POC__c newPOCRequest20 = new POC__c();
        newPOCRequest20.POC_Type__c = 'Standard POC';
        newPOCRequest20.POC_Qty__c = 10;
        newPOCRequest20.POC_Justification__c = 'Test Justification';
        newPOCRequest20.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest20.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest20.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest20.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest20.Number_Of_NCD_FETB__c = 2;
        newPOCRequest20.Product_Categories__c ='NAS Cloud Direct';
        newPOCRequest20.RCV_Archive_Tier__c = 'Yes';
        newPOCRequest20.Salesforce__c ='No';
        newPOCRequest20.Jira_Cloud__c ='No';
        newPOCRequest20.Storage_Region_Bundle_RCV_Backup__c = null;
        newPOCRequest20.Hosting_Environment_Salesforce__c =null;
        newPOCRequest20.Data_Redundancy_Archive_NAS__c = 'Single Zone (LRS)';
        insert newPOCRequest20;
        
		
		PocFormControllerCls.response_Wrapper obj21 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert21 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp21 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp21.filename='TestFilename.txt';
        fileListInsertTemp21.base64='Test Content';
        fileListInsert21.add(fileListInsertTemp21);

        obj21.pocRequestObj = newPOCRequest20;
		
        POC__c newPOCRequest22 = new POC__c();
        newPOCRequest22.POC_Type__c = 'Standard POC';
        newPOCRequest22.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest22.POC_Qty__c = 10;
        newPOCRequest22.POC_Justification__c = 'Test Justification';
        newPOCRequest22.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest22.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest22.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest22.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest22.Product_Categories__c = 'UCL (Cloud Cluster, Cloud Native & Entra ID)';
        newPOCRequest22.Data_Redundancy_Backup_UCL__c = 'Single Zone (LRS)';
        newPOCRequest22.Storage_Region_Bundle_RCV_Backup__c = null;
        insert newPOCRequest22;

		PocFormControllerCls.response_Wrapper obj22 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert22 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp22 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp22.filename='TestFilename.txt';
        fileListInsertTemp22.base64='Test Content';
        fileListInsert22.add(fileListInsertTemp22);

        obj22.pocRequestObj = newPOCRequest11;
        obj22.uclEdition = 'UCL with Rubrik-hosted Enterprise Edition (With RCV Backup tier)';
        obj22.pocRequestObj = newPOCRequest22;
        
        POC__c newPOCRequest23 = new POC__c();
        newPOCRequest23.POC_Type__c = 'Standard POC';
        newPOCRequest23.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest23.POC_Qty__c = 10;
        newPOCRequest23.POC_Justification__c = 'Test Justification';
        newPOCRequest23.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest23.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest23.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest23.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest23.Number_Of_NCD_FETB__c = 2;
        newPOCRequest23.Product_Categories__c ='Rubrik Cloud Vault - Government';
        newPOCRequest23.RCV_Archive_Tier__c = 'Yes';
        newPOCRequest23.Data_Redundancy_Archive__c = 'Multi Zone (ZRS)';
        newPOCRequest23.Storage_Region_Bundle_RCV_Backup__c = null;
        newPOCRequest23.Archive_TB__c = 5;
        insert newPOCRequest23;
        
        PocFormControllerCls.response_Wrapper obj23 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert23 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp23 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp23.filename='TestFilename.txt';
        fileListInsertTemp23.base64='Test Content';
        fileListInsert23.add(fileListInsertTemp23);
			
        obj23.pocRequestObj = newPOCRequest23;
        
        POC__c newPOCRequest24 = new POC__c();
        newPOCRequest24.POC_Type__c = 'Standard POC';
        newPOCRequest24.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest24.POC_Qty__c = 10;
        newPOCRequest24.POC_Justification__c = 'Test Justification';
        newPOCRequest24.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest24.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest24.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest24.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest24.Number_Of_NCD_FETB__c = 2;
        newPOCRequest24.Product_Categories__c ='Rubrik Cloud Vault - Government';
        newPOCRequest24.RCV_Backup_Tier__c = 'No';
        newPOCRequest24.Data_Redundancy_Archive__c = 'Multi Zone (ZRS)';
        newPOCRequest24.Archive_TB__c = 5;
        insert newPOCRequest24;
        
        PocFormControllerCls.response_Wrapper obj24 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert24 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp24 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp24.filename='TestFilename.txt';
        fileListInsertTemp24.base64='Test Content';
        fileListInsert24.add(fileListInsertTemp24);
			
        obj24.pocRequestObj = newPOCRequest23;
        
        
        
        
        POC__c newPOCRequest25 = new POC__c();
        newPOCRequest25.POC_Type__c = 'Standard POC';
        newPOCRequest25.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest25.POC_Qty__c = 10;
        newPOCRequest25.POC_Justification__c = 'Test Justification';
        newPOCRequest25.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest25.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest25.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest25.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest25.Number_Of_NCD_FETB__c = 2;
        newPOCRequest25.Product_Categories__c ='Rubrik Cloud Vault - Government';
        newPOCRequest25.RCV_Backup_Tier__c = 'No';
        newPOCRequest25.Data_Redundancy_Archive__c = 'Multi Zone (ZRS)';
        newPOCRequest25.Archive_TB__c = 5;
        insert newPOCRequest25;
        
        PocFormControllerCls.response_Wrapper obj25 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert25 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp25 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp24.filename='TestFilename.txt';
        fileListInsertTemp24.base64='Test Content';
        fileListInsert25.add(fileListInsertTemp24);
			
        obj25.pocRequestObj = newPOCRequest23;
        
        
        POC__c newPOCRequest26 = new POC__c();
        newPOCRequest26.POC_Type__c = 'Standard POC';
        newPOCRequest26.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest26.POC_Qty__c = 10;
        newPOCRequest26.POC_Justification__c = 'Test Justification';
        newPOCRequest26.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest26.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest26.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest26.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest26.Number_Of_NCD_FETB__c = 2;
        newPOCRequest26.Product_Categories__c ='Rubrik Cloud Vault - Government';
        newPOCRequest26.RCV_Backup_Tier__c = 'Yes';
        newPOCRequest26.Data_Redundancy_Archive__c = 'Multi Zone (ZRS)';
        newPOCRequest26.Backup_TB__c = 5;
        newPOCRequest26.RCV_Archive_Tier__c = 'No';
        newPOCRequest26.UCL_Edition__c = 'UCL with Rubrik-hosted Enterprise Edition (With RCV Backup tier)';
        insert newPOCRequest26;
        
        PocFormControllerCls.response_Wrapper obj26 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert26 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp26 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp24.filename='TestFilename.txt';
        fileListInsertTemp24.base64='Test Content';
        fileListInsert26.add(fileListInsertTemp24);
			
        obj26.pocRequestObj = newPOCRequest26;
        
        POC__c newPOCRequest27 = new POC__c();
        newPOCRequest27.POC_Type__c = 'Standard POC: RSC-G';
        newPOCRequest27.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest27.POC_Qty__c = 10;
        newPOCRequest27.POC_Justification__c = 'Test Justification';
        newPOCRequest27.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest27.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest27.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest27.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest27.How_many_identity_users_areThere__c = 0;
        newPOCRequest27.Product_Categories__c ='Identity Recovery';
        newPOCRequest27.RCV_Archive_Tier__c = 'Yes';
        newPOCRequest27.Storage_Region_Bundle_RCV_Backup__c = null;
        insert newPOCRequest27;
        
        POC__c newPOCRequest28 = new POC__c();
        newPOCRequest28.POC_Type__c = 'Standard POC';
        newPOCRequest28.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest28.POC_Qty__c = 10;
        newPOCRequest28.POC_Justification__c = 'Test Justification';
        newPOCRequest28.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest28.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest28.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest28.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest28.How_many_identity_users_areThere__c = 0;
        newPOCRequest28.Product_Categories__c ='Cloud Unstructured (S3, Azure Blob, and Cloud Files)';
        newPOCRequest28.How_much_FETB_do_you_need__c = 0;
        newPOCRequest28.RCV_Archive_Tier__c = 'Yes';
        newPOCRequest28.Storage_Region_Bundle_RCV_Backup__c = null;
        insert newPOCRequest28;
        
        PocFormControllerCls.response_Wrapper obj27 = new PocFormControllerCls.response_Wrapper();
        obj27.pocRequestObj = newPOCRequest27;
        PocFormControllerCls.response_Wrapper obj28 = new PocFormControllerCls.response_Wrapper();
        obj27.pocRequestObj = newPOCRequest28;
        
        POC__c newPOCRequest29 = new POC__c();
        newPOCRequest29.POC_Type__c = 'Standard POC : RSC-G	';
        newPOCRequest29.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest29.POC_Qty__c = 10;
        newPOCRequest29.POC_Justification__c = 'Test Justification';
        newPOCRequest29.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest29.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest29.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest29.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest29.Product_Categories__c ='Rubrik Cloud Vault - Government';
        newPOCRequest29.RCV_Archive_Tier__c = 'Yes';
        newPOCRequest29.Archive_TB__c = null;
        insert newPOCRequest29;
       
        PocFormControllerCls.response_Wrapper obj29 = new PocFormControllerCls.response_Wrapper();
        obj29.pocRequestObj = newPOCRequest29;
		
        List<PocFormControllerCls.fileInnerClass> fileListInsert29 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp29 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp24.filename='TestFilename.txt';
        fileListInsertTemp24.base64='Test Content';
        fileListInsert29.add(fileListInsertTemp24);
        
		POC__c newPOCRequest30 = new POC__c();
        newPOCRequest30.POC_Type__c = 'Standard POC : RSC-G	';

        newPOCRequest30.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest30.POC_Qty__c = 10;
        newPOCRequest30.POC_Justification__c = 'Test Justification';
        newPOCRequest30.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest30.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest30.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest30.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest30.How_many_identity_users_areThere__c = 0;
        newPOCRequest30.Product_Categories__c ='Rubrik Cloud Vault - Government';
        newPOCRequest30.How_much_FETB_do_you_need__c = 0;
        newPOCRequest30.RCV_Backup_Tier__c = 'No';
        newPOCRequest30.Backup_TB__c = null;
        insert newPOCRequest30;
       
        PocFormControllerCls.response_Wrapper obj30 = new PocFormControllerCls.response_Wrapper();
        obj30.pocRequestObj = newPOCRequest30;
		
        List<PocFormControllerCls.fileInnerClass> fileListInsert30 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp30 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp24.filename='TestFilename.txt';
        fileListInsertTemp24.base64='Test Content';
        fileListInsert30.add(fileListInsertTemp24);
        
		POC__c newPOCRequest32 = new POC__c();
        newPOCRequest32.POC_Type__c = 'Standard POC';
        newPOCRequest32.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest32.POC_Qty__c = 10;
        newPOCRequest32.POC_Justification__c = 'Test Justification';
        newPOCRequest32.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest32.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest32.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest32.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest32.Product_Categories__c ='Rubrik Cloud Vault';
        newPOCRequest32.RCV_Backup_Tier__c = 'Yes';
        newPOCRequest32.Backup_TB__c = null;
        insert newPOCRequest32;
       
        PocFormControllerCls.response_Wrapper obj32 = new PocFormControllerCls.response_Wrapper();
        obj32.pocRequestObj = newPOCRequest32;
		
        List<PocFormControllerCls.fileInnerClass> fileListInsert32 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp32 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp24.filename='TestFilename.txt';
        fileListInsertTemp24.base64='Test Content';
        fileListInsert32.add(fileListInsertTemp24);

        POC__c newPOCRequest31 = new POC__c();
        newPOCRequest31.POC_Type__c = 'Standard POC : RSC-G';
        newPOCRequest31.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest31.POC_Qty__c = 10;
        newPOCRequest31.POC_Justification__c = 'Test Justification';
        newPOCRequest31.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest31.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest31.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest31.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest31.Product_Categories__c ='Rubrik Cloud Vault - Government';
        newPOCRequest31.RCV_Backup_Tier__c = 'Yes';
        newPOCRequest31.Backup_TB__c = null;
        insert newPOCRequest31;
       
        PocFormControllerCls.response_Wrapper obj31 = new PocFormControllerCls.response_Wrapper();
        obj31.pocRequestObj = newPOCRequest31;
		
        List<PocFormControllerCls.fileInnerClass> fileListInsert31 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp31 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp24.filename='TestFilename.txt';
        fileListInsertTemp24.base64='Test Content';
        fileListInsert31.add(fileListInsertTemp24);
        
         POC__c newPOCRequest33 = new POC__c();
        newPOCRequest33.POC_Type__c = 'Standard POC';
        newPOCRequest33.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest33.POC_Qty__c = 10;
        newPOCRequest33.POC_Justification__c = 'Test Justification';
        newPOCRequest33.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest33.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest33.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest33.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest33.Product_Categories__c ='Rubrik Cloud Vault';
        newPOCRequest33.RCV_Archive_Tier__c = 'Yes';
        newPOCRequest33.Archive_TB__c = null;
        insert newPOCRequest33;
       
        PocFormControllerCls.response_Wrapper obj33 = new PocFormControllerCls.response_Wrapper();
        obj33.pocRequestObj = newPOCRequest33;
		
        List<PocFormControllerCls.fileInnerClass> fileListInsert33 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp33 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp24.filename='TestFilename.txt';
        fileListInsertTemp24.base64='Test Content';
        fileListInsert33.add(fileListInsertTemp24);
        
        POC__c newPOCRequest34 = new POC__c();
        newPOCRequest34.POC_Type__c = 'Standard POC : RSC-G	';
        newPOCRequest34.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest34.POC_Qty__c = 10;
        newPOCRequest34.POC_Justification__c = 'Test Justification';
        newPOCRequest34.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest34.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest34.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest34.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest34.Product_Categories__c ='Rubrik Cloud Vault - Government';
        newPOCRequest34.RCV_Archive_Tier__c = 'Yes';
        newPOCRequest34.Archive_TB__c = 10;
        newPOCRequest34.Data_Redundancy_Archive__c = '';
        newPOCRequest34.Storage_Region_Bundle_RCV_Archive__c=null;
        insert newPOCRequest34;
         //PocFormControllerCls.validateExpectedEndDate(newPOCRequest34.Id, 'ExpectedDateLogic', Date.today().addDays(21));
       
        PocFormControllerCls.response_Wrapper obj34 = new PocFormControllerCls.response_Wrapper();
        obj34.pocRequestObj = newPOCRequest34;
		
        List<PocFormControllerCls.fileInnerClass> fileListInsert34 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp34 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp24.filename='TestFilename.txt';
        fileListInsertTemp24.base64='Test Content';
        fileListInsert34.add(fileListInsertTemp24);
        
        POC__c newPOCRequest36 = new POC__c();
        newPOCRequest36.POC_Type__c = 'Standard POC';
        newPOCRequest36.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest36.POC_Qty__c = 10;
        newPOCRequest36.POC_Justification__c = 'Test Justification';
        newPOCRequest36.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest36.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest36.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest36.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest36.Product_Categories__c ='SaaS (Jira Cloud, Salesforce, Dynamics)';
        newPOCRequest36.Salesforce__c = 'No';
        newPOCRequest36.Jira_Cloud__c = 'No';
        insert newPOCRequest36;
       
        PocFormControllerCls.response_Wrapper obj36 = new PocFormControllerCls.response_Wrapper();
        obj36.pocRequestObj = newPOCRequest36;
		
        List<PocFormControllerCls.fileInnerClass> fileListInsert36 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp36 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp24.filename='TestFilename.txt';
        fileListInsertTemp24.base64='Test Content';
        fileListInsert36.add(fileListInsertTemp24);
        
        
        POC__c newPOCRequest35 = new POC__c();
        newPOCRequest35.POC_Type__c = 'Standard POC';
        newPOCRequest35.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest35.POC_Qty__c = 10;
        newPOCRequest35.POC_Justification__c = 'Test Justification';
        newPOCRequest35.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest35.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest35.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest35.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest35.Product_Categories__c ='Rubrik Cloud Vault';
        newPOCRequest35.RCV_Backup_Tier__c = 'Yes';
        newPOCRequest35.Backup_TB__c = 20;
        newPOCRequest35.Data_Redundancy_Backup__c = 'Single Zone (LRS)';
        newPOCRequest35.Storage_Region_Bundle_RCV_Archive__c=null;
        insert newPOCRequest35;
       
        PocFormControllerCls.response_Wrapper obj35 = new PocFormControllerCls.response_Wrapper();
        obj35.pocRequestObj = newPOCRequest35;
		
        List<PocFormControllerCls.fileInnerClass> fileListInsert35 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp35 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp24.filename='TestFilename.txt';
        fileListInsertTemp24.base64='Test Content';
        fileListInsert35.add(fileListInsertTemp24);
        
        POC__c newPOCRequest37 = new POC__c();
        newPOCRequest37.POC_Type__c = 'Standard POC';
        newPOCRequest37.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest37.POC_Qty__c = 10;
        newPOCRequest37.POC_Justification__c = 'Test Justification';
        newPOCRequest37.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest37.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest37.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest37.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest37.Product_Categories__c ='SaaS (Jira Cloud, Salesforce, Dynamics)';
        newPOCRequest37.Salesforce__c = 'Yes';
        newPOCRequest37.Number_of_Users_Salesforce__c = 2;
        newPOCRequest37.Hosting_Environment_Salesforce__c = null;
        insert newPOCRequest37;
       
        PocFormControllerCls.response_Wrapper obj37 = new PocFormControllerCls.response_Wrapper();
        obj37.pocRequestObj = newPOCRequest37;
		
        List<PocFormControllerCls.fileInnerClass> fileListInsert37 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp37 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp24.filename='TestFilename.txt';
        fileListInsertTemp24.base64='Test Content';
        fileListInsert37.add(fileListInsertTemp24);
        
        
        POC__c newPOCRequest38 = new POC__c();
        newPOCRequest38.POC_Type__c = 'Standard POC';
        newPOCRequest38.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest38.POC_Qty__c = 10;
        newPOCRequest38.POC_Justification__c = 'Test Justification';
        newPOCRequest38.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest38.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest38.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest38.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest38.Product_Categories__c ='SaaS (Jira Cloud, Salesforce, Dynamics)';
        newPOCRequest38.Jira_Cloud__c = 'Yes';
        newPOCRequest38.Hosting_Environment_Salesforce__c = null;
        newPOCRequest38.Number_of_Users_Salesforce__c = 2;
        insert newPOCRequest38;
       
        PocFormControllerCls.response_Wrapper obj38 = new PocFormControllerCls.response_Wrapper();
        obj38.pocRequestObj = newPOCRequest38;
		
        POC__c newPOCRequest39 = new POC__c();
        newPOCRequest39.POC_Type__c = 'Standard POC';
        newPOCRequest39.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest39.POC_Qty__c = 10;
        newPOCRequest39.POC_Justification__c = 'Test Justification';
        newPOCRequest39.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest39.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest39.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest39.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest39.Number_Of_NCD_FETB__c = 2;
        newPOCRequest39.Product_Categories__c ='NAS Cloud Direct';
        newPOCRequest39.NCD_Editions__c = 'Bundled with Cloud Unstructured';
        newPOCRequest39.RCV_Archive_Tier__c = 'Yes';
        newPOCRequest39.Archive_TB__c = 15;
        newPOCRequest39.Storage_Region_Bundle_RCV_Backup__c = null;
        insert newPOCRequest39;
        
        PocFormControllerCls.response_Wrapper obj39 = new PocFormControllerCls.response_Wrapper();
        obj39.pocRequestObj = newPOCRequest39;
        
        POC__c newPOCRequest40 = new POC__c();
        newPOCRequest40.POC_Type__c = 'Standard POC';
        newPOCRequest40.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest40.POC_Qty__c = 10;
        newPOCRequest40.POC_Justification__c = 'Test Justification';
        newPOCRequest40.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest40.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest40.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest40.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest40.Number_Of_NCD_FETB__c = 2;
        newPOCRequest40.Product_Categories__c ='NAS Cloud Direct';
        newPOCRequest40.NCD_Editions__c = 'Business Edition Rubrik Hosted (w/RCV + Ransomware Monitoring)';
        newPOCRequest40.RCV_Archive_Tier__c = 'Yes';
        newPOCRequest40.Archive_TB__c = 15;
        newPOCRequest40.Storage_Region_Bundle_RCV_Backup__c = null;
        insert newPOCRequest40;
        
        PocFormControllerCls.response_Wrapper obj40 = new PocFormControllerCls.response_Wrapper();
        obj40.pocRequestObj = newPOCRequest40;
        
        POC__c newPOCRequest41 = new POC__c();
        newPOCRequest41.POC_Type__c = 'Standard POC';
        newPOCRequest41.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest41.POC_Qty__c = 10;
        newPOCRequest41.POC_Justification__c = 'Test Justification';
        newPOCRequest41.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest41.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest41.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest41.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest41.Product_Categories__c ='NAS Cloud Direct;Rubrik Cloud Vault';
        newPOCRequest41.NCD_Editions__c = 'Enterprise Edition (w/RCV + Ransomware Monitoring + Sensitive Data Discovery)';
        newPOCRequest41.RCV_Archive_Tier__c = 'Yes';
        newPOCRequest41.Archive_TB__c = 15;
        newPOCRequest41.Number_Of_NCD_FETB__c = 11;
        newPOCRequest41.Storage_Region_Bundle_RCV_Backup__c = null;
        insert newPOCRequest41;
        
        PocFormControllerCls.response_Wrapper obj41 = new PocFormControllerCls.response_Wrapper();
        obj41.pocRequestObj = newPOCRequest41;
        
        POC__c newPOCRequest42 = new POC__c();
        newPOCRequest42.POC_Type__c = 'Standard POC';
        newPOCRequest42.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest42.POC_Qty__c = 10;
        newPOCRequest42.POC_Justification__c = 'Test Justification';
        newPOCRequest42.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest42.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest42.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest42.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest42.How_many_identity_users_areThere__c = 0;
        newPOCRequest42.Product_Categories__c ='Cloud Unstructured (S3, Azure Blob, and Cloud Files);NAS Cloud Direct';
        //newPOCRequest42.How_much_FETB_do_you_need__c = 0;
        //newPOCRequest42.RCV_Archive_Tier__c = 'Yes';
        //newPOCRequest42.Storage_Region_Bundle_RCV_Backup__c = null;
        insert newPOCRequest42;
        
        PocFormControllerCls.response_Wrapper obj42 = new PocFormControllerCls.response_Wrapper();
        obj42.pocRequestObj = newPOCRequest42;
		
        List<PocFormControllerCls.fileInnerClass> fileListInsert38 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp38 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp24.filename='TestFilename.txt';
        fileListInsertTemp24.base64='Test Content';
        fileListInsert38.add(fileListInsertTemp24);

        /*Start - Added for MKT26-490*/
        POC__c newPOCRequest43 = new POC__c();
        
        newPOCRequest43.POC_Type__c = 'Standard POC';
        newPOCRequest43.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest43.POC_Qty__c = 10;
        newPOCRequest43.POC_Justification__c = 'Test Justification';
        newPOCRequest43.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest43.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest43.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest43.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest43.How_many_identity_users_areThere__c = 0;
        newPOCRequest43.Product_Categories__c ='Codebase Recovery';
        //newPOCRequest42.Number_of_repositories_to_back_up_1_500__c  = 400;
        //newPOCRequest42.RCV_Archive_Tier__c = 'Yes';
        //newPOCRequest42.Storage_Region_Bundle_RCV_Backup__c = null;
        insert newPOCRequest43;
        PocFormControllerCls.response_Wrapper obj43 = new PocFormControllerCls.response_Wrapper();
        obj43.pocRequestObj = newPOCRequest43;
        
        List<PocFormControllerCls.fileInnerClass> fileListInsert39 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp39 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp39.filename='TestFilename.txt';
        fileListInsertTemp39.base64='Test Content';
        fileListInsert39.add(fileListInsertTemp39);
        
        POC__c newPOCRequest44 = new POC__c();
        newPOCRequest44.POC_Type__c = 'Standard POC';
        newPOCRequest44.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest44.POC_Qty__c = 10;
        newPOCRequest44.POC_Justification__c = 'Test Justification';
        newPOCRequest44.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest44.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest44.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest44.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest44.How_many_identity_users_areThere__c = 0;
        newPOCRequest44.Product_Categories__c ='Codebase Recovery';
        //newPOCRequest44.Number_of_repositories_to_back_up_1_500__c  = 400;
        //newPOCRequest42.RCV_Archive_Tier__c = 'Yes';
        //newPOCRequest42.Storage_Region_Bundle_RCV_Backup__c = null;
        insert newPOCRequest44;
        
        PocFormControllerCls.response_Wrapper obj44 = new PocFormControllerCls.response_Wrapper();
        obj44.pocRequestObj = newPOCRequest44;
        
        List<PocFormControllerCls.fileInnerClass> fileListInsert40 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp40 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp40.filename='TestFilename.txt';
        fileListInsertTemp40.base64='Test Content';
        fileListInsert40.add(fileListInsertTemp40);
        /*End - Added for MKT26-490*/
        
        /*Start - Added for MKT26-410*/
        POC__c newPOCRequest45 = new POC__c();
        
        newPOCRequest45.POC_Type__c = 'Standard POC';
        newPOCRequest45.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest45.POC_Qty__c = 10;
        newPOCRequest45.POC_Justification__c = 'Test Justification';
        newPOCRequest45.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest45.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest45.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest45.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest45.How_many_identity_users_areThere__c = 0;
        newPOCRequest45.Product_Categories__c ='RSC Enterprise and Proactive Editions';
        newPOCRequest45.RSC_Enterprise_Edition__c = 'Yes';
        newPOCRequest45.RSC_G_Proactive_Edition__c  = 'Yes';
        //newPOCRequest42.RCV_Archive_Tier__c = 'Yes';
        //newPOCRequest42.Storage_Region_Bundle_RCV_Backup__c = null;
        insert newPOCRequest45;
        
        PocFormControllerCls.response_Wrapper obj45 = new PocFormControllerCls.response_Wrapper();
        obj45.pocRequestObj = newPOCRequest45;
        
        List<PocFormControllerCls.fileInnerClass> fileListInsert41 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp41 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp41.filename='TestFilename.txt';
        fileListInsertTemp41.base64='Test Content';
        fileListInsert41.add(fileListInsertTemp41);
        
        POC__c newPOCRequest46 = new POC__c();
        newPOCRequest46.POC_Type__c = 'Standard POC : RSC-G';
        newPOCRequest46.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest46.POC_Qty__c = 10;
        newPOCRequest46.POC_Justification__c = 'Test Justification';
        newPOCRequest46.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest46.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest46.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest46.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest46.How_many_identity_users_areThere__c = 0;
        newPOCRequest46.Product_Categories__c ='RSC-G Enterprise and Proactive Editions';
        newPOCRequest46.RSC_G_Proactive_Edition__c  = 'Yes';
        newPOCRequest46.RSC_G_Enterprise_Edition__c	  = 'Yes';
        //newPOCRequest42.RCV_Archive_Tier__c = 'Yes';
        //newPOCRequest42.Storage_Region_Bundle_RCV_Backup__c = null;
        insert newPOCRequest46;
        
        POC__c newPOCRequest47 = new POC__c();
        newPOCRequest47.POC_Type__c = 'Standard POC : RSC-G';
        newPOCRequest47.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest47.POC_Qty__c = 10;
        newPOCRequest47.POC_Justification__c = 'Test Justification';
        newPOCRequest47.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest47.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest47.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest47.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest47.How_many_identity_users_areThere__c = 0;
        newPOCRequest47.Product_Categories__c ='SaaS (Jira Cloud, Salesforce, Dynamics)';
        newPOCRequest47.Salesforce__c  = 'Yes';
        newPOCRequest47.Number_of_Users_Salesforce__c = 0;
        newPOCRequest47.Jira_Cloud__c  = 'Yes';
        newPOCRequest47.Number_of_Users_Atlassian__c = 0;
        newPOCRequest47.Dynamics__c  = 'Yes';
        newPOCRequest47.Number_of_Users_Dynamics__c = 0;
        //newPOCRequest42.RCV_Archive_Tier__c = 'Yes';
        //newPOCRequest42.Storage_Region_Bundle_RCV_Backup__c = null;
        insert newPOCRequest47;
         PocFormControllerCls.response_Wrapper obj47 = new PocFormControllerCls.response_Wrapper();
        obj47.pocRequestObj = newPOCRequest47;
        
        PocFormControllerCls.response_Wrapper obj46 = new PocFormControllerCls.response_Wrapper();
        obj46.pocRequestObj = newPOCRequest46;
        
        POC__c newPOCRequest48 = new POC__c();
        newPOCRequest48.POC_Type__c = 'Virtual Lab';
        newPOCRequest48.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest48.POC_Qty__c = 10;
        newPOCRequest48.POC_Justification__c = 'Test Justification';
        newPOCRequest48.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest48.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest48.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest48.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest48.Approval_Status__c = 'Extension Requested';
        newPOCRequest48.Product_Categories__c ='Identity Recovery and Resilience - AD, Entra ID, Okta';
        newPOCRequest48.How_many_Identity_UsersAreThere__c = 0;
        newPOCRequest48.Add_Identity_Recovery__c = 'yes';
        insert newPOCRequest48;
        
        PocFormControllerCls.response_Wrapper obj48 = new PocFormControllerCls.response_Wrapper();
        obj48.pocRequestObj = newPOCRequest48;
        
        POC__c newPOCRequest49 = new POC__c();
        newPOCRequest49.POC_Type__c = 'Virtual Lab';
        newPOCRequest48.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest48.POC_Qty__c = 10;
        newPOCRequest49.POC_Justification__c = 'Test Justification';
        newPOCRequest49.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest49.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest49.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest49.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest49.Approval_Status__c = 'Extension Requested';
        newPOCRequest49.Product_Categories__c ='Identity Recovery and Resilience - AD, Entra ID, Okta';
        newPOCRequest49.Add_Identity_Resilience__c = 'No';
        newPOCRequest49.Add_Identity_Recovery__c = 'No';
        insert newPOCRequest49;
        
        PocFormControllerCls.response_Wrapper obj49 = new PocFormControllerCls.response_Wrapper();
        obj49.pocRequestObj = newPOCRequest49;
        
        POC__c newPOCRequest50 = new POC__c();
        newPOCRequest50.POC_Type__c = 'Standard POC : RSC-G';
        newPOCRequest50.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest50.POC_Qty__c = 10;
        newPOCRequest50.POC_Justification__c = 'Test Justification';
        newPOCRequest50.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest50.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest50.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest50.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest50.How_many_identity_users_areThere__c = 0;
        newPOCRequest50.Product_Categories__c ='SaaS (Salesforce)';
        newPOCRequest50.Salesforce_plus_DevOps_Add_on__c  = 'No';
        insert newPOCRequest50;
         PocFormControllerCls.response_Wrapper obj50 = new PocFormControllerCls.response_Wrapper();
        obj50.pocRequestObj = newPOCRequest50;
        
        POC__c newPOCRequest51 = new POC__c();
        newPOCRequest51.POC_Type__c = 'Standard POC : RSC-G';
        newPOCRequest51.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest51.POC_Qty__c = 10;
        newPOCRequest51.POC_Justification__c = 'Test Justification';
        newPOCRequest51.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest51.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest51.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest51.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest51.How_many_identity_users_areThere__c = 0;
        newPOCRequest51.Product_Categories__c ='SaaS (Salesforce)';
        newPOCRequest51.Salesforce_plus_DevOps_Add_on__c  = 'Yes';
        newPOCRequest51.Number_of_Users_Saas__c  = 6;
        insert newPOCRequest51;
         PocFormControllerCls.response_Wrapper obj51 = new PocFormControllerCls.response_Wrapper();
        obj51.pocRequestObj = newPOCRequest51;
          
          POC__c newPOCRequest52 = new POC__c();
        newPOCRequest52.POC_Type__c = 'Standard POC';
        newPOCRequest52.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest52.POC_Qty__c = 10;
        newPOCRequest52.POC_Justification__c = 'Test Justification';
        newPOCRequest52.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest52.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest52.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest52.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest52.Product_Categories__c ='Identity Cyber Recovery for Okta';
        newPOCRequest52.Identity_Cyber_Recovery_for_Okta__c = 'No';
        insert newPOCRequest52;
        
        PocFormControllerCls.response_Wrapper obj52 = new PocFormControllerCls.response_Wrapper();
        obj52.pocRequestObj = newPOCRequest52;
        
        POC__c newPOCRequest53 = new POC__c();
        newPOCRequest53.POC_Type__c = 'Standard POC';
        newPOCRequest53.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest53.POC_Qty__c = 10;
        newPOCRequest53.POC_Justification__c = 'Test Justification';
        newPOCRequest53.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest53.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest52.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest52.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest53.Product_Categories__c ='Identity Cyber Recovery for Okta';
        newPOCRequest53.Identity_Cyber_Recovery_for_Okta__c = 'Yes';
        newPOCRequest53.How_many_users_are_there_in_the_Okta_IdP__c = 0;
        insert newPOCRequest53;
        
        PocFormControllerCls.response_Wrapper obj53 = new PocFormControllerCls.response_Wrapper();
        obj53.pocRequestObj = newPOCRequest53;
          
          POC__c newPOCRequest56 = new POC__c();
        newPOCRequest56.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest56.POC_Type__c = 'Web Try and Buy';
        newPOCRequest56.POC_Duration__c = '30 Days';
        newPOCRequest56.POC_Relocation__c = 'No';
        newPOCRequest56.POC_Justification__c = 'test';
        newPOCRequest56.Ranger_Support_Expected__c = true;
        newPOCRequest56.Number_of_Extensions__c = 1;
        newPOCRequest56.M365_Hosting_environment__c = 'Rubrik Hosted EE, DSPM, Identity Recovery & Resilience';
        insert newPOCRequest56;
        
        PocFormControllerCls.response_Wrapper obj56 = new PocFormControllerCls.response_Wrapper();
        obj56.pocRequestObj = newPOCRequest56;
        
        POC__c newPOCRequest57 = new POC__c();
        newPOCRequest57.POC_Type__c = 'Standard POC';
        newPOCRequest57.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest57.POC_Qty__c = 10;
        newPOCRequest57.POC_Justification__c = 'Test Justification';
        newPOCRequest57.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest57.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest57.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest57.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest57.Product_Categories__c ='M365 and Entra ID';
        newPOCRequest57.M365_Hosting_environment__c = 'Rubrik Hosted EE, DSPM, Identity Recovery & Resilience';
        insert newPOCRequest57;
        PocFormControllerCls.response_Wrapper obj57 = new PocFormControllerCls.response_Wrapper();
        obj57.pocRequestObj = newPOCRequest57;
        
        List<PocFormControllerCls.fileInnerClass> fileListInsert42 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp42 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp41.filename='TestFilename.txt';
        fileListInsertTemp41.base64='Test Content';
        fileListInsert42.add(fileListInsertTemp42);
        /*End - Added for MKT26-410*/
        
        /* Start of M365 and Google Workspace */
        Id oppId =  [Select Id From Opportunity LIMIT 1].Id;
        POC__c newPOCRequestM365GSpace = new POC__c();
        newPOCRequestM365GSpace.POC_Type__c = 'Standard POC';
        newPOCRequestM365GSpace.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequestM365GSpace.POC_Qty__c = 10;
        newPOCRequestM365GSpace.POC_Justification__c = 'Test Justification';
        newPOCRequestM365GSpace.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequestM365GSpace.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequestM365GSpace.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequestM365GSpace.Opportunity__c = oppId;
        newPOCRequestM365GSpace.Number_Of_NCD_FETB__c = 2;
        newPOCRequestM365GSpace.Product_Categories__c ='M365 and Google Workspace';
        newPOCRequestM365GSpace.RCV_Backup_Tier__c = 'No';
        newPOCRequestM365GSpace.Data_Redundancy_Archive__c = 'Multi Zone (ZRS)';
        newPOCRequestM365GSpace.Archive_TB__c = 5;
        
        newPOCRequestM365GSpace.M365_Option__c = '';
        newPOCRequestM365GSpace.Google_Workspace__c = '';
        newPOCRequestM365GSpace.M365_Hosting_environment__c = 'Rubrik Hosted EE, DSPM, Identity Recovery & Resilience';
        newPOCRequestM365GSpace.Add_Identity_Resilience__c = 'No';
        insert newPOCRequestM365GSpace;

        PocFormControllerCls.response_Wrapper objM365GSpace = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsertM365 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTempM365 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTempM365.filename='TestFilename.txt';
        fileListInsertTempM365.base64='Test Content';
        fileListInsertM365.add(fileListInsertTempM365);
        objM365GSpace.pocRequestObj = newPOCRequestM365GSpace;
        
        POC__c newPOCRequestM365GSpace1 = new POC__c();
        newPOCRequestM365GSpace1.POC_Type__c = 'Standard POC';
        newPOCRequestM365GSpace1.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequestM365GSpace1.POC_Qty__c = 10;
        newPOCRequestM365GSpace1.POC_Justification__c = 'Test Justification';
        newPOCRequestM365GSpace1.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequestM365GSpace1.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequestM365GSpace1.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequestM365GSpace1.Opportunity__c = oppId;
        newPOCRequestM365GSpace1.Number_Of_NCD_FETB__c = 2;
        newPOCRequestM365GSpace1.Product_Categories__c ='M365 and Google Workspace';
        newPOCRequestM365GSpace1.RCV_Backup_Tier__c = 'No';
        newPOCRequestM365GSpace1.Data_Redundancy_Archive__c = 'Multi Zone (ZRS)';
        newPOCRequestM365GSpace1.Archive_TB__c = 5;
        
        newPOCRequestM365GSpace1.M365_Option__c = 'No';
        newPOCRequestM365GSpace1.Google_Workspace__c = '';
        insert newPOCRequestM365GSpace1;

        PocFormControllerCls.response_Wrapper objM365GSpace1 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsertM3651 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTempM3651 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTempM3651.filename='TestFilename.txt';
        fileListInsertTempM3651.base64='Test Content';
        fileListInsertM3651.add(fileListInsertTempM3651);
        objM365GSpace1.pocRequestObj = newPOCRequestM365GSpace1;
        /* End of M365 and Google Workspace */
        
        POC__c newPOCRequest58 = new POC__c();
        newPOCRequest58.POC_Type__c = 'Standard POC';
        newPOCRequest58.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest58.POC_Qty__c = 10;
        newPOCRequest58.POC_Justification__c = 'Test Justification';
        newPOCRequest58.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest58.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest58.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest58.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest58.Number_Of_NCD_FETB__c = 2;
        newPOCRequest58.Product_Categories__c ='Identity Recovery and Resilience - AD, Entra ID, Okta';
        newPOCRequest58.RCV_Backup_Tier__c = 'No';
        newPOCRequest58.Data_Redundancy_Archive__c = 'Multi Zone (ZRS)';
        newPOCRequest58.Archive_TB__c = 5;
        
        newPOCRequest58.Add_Identity_Resilience__c = 'Yes';
        newPOCRequest58.Add_Identity_Recovery__c = 'Yes';
        newPOCRequest58.Identity_Cyber_Recovery_for_Okta__c = 'Yes';
        newPOCRequest58.How_many_identity_users_are_there__c = null;
        newPOCRequest58.How_many_Identity_UsersAreThere__c = null;
        newPOCRequest58.How_many_users_are_there_in_the_Okta_IdP__c = null;
        insert newPOCRequest58;

        PocFormControllerCls.response_Wrapper obj58 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert58 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp58 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp58.filename='TestFilename.txt';
        fileListInsertTemp58.base64='Test Content';
        fileListInsert58.add(fileListInsertTemp58);
        obj58.pocRequestObj = newPOCRequest58;
        
        POC__c newPOCRequest59 = new POC__c();
        newPOCRequest59.POC_Type__c = 'Standard POC';
        newPOCRequest59.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest59.POC_Qty__c = 10;
        newPOCRequest59.POC_Justification__c = 'Test Justification';
        newPOCRequest59.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest59.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest59.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest59.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest59.Number_Of_NCD_FETB__c = 2;
        newPOCRequest59.Product_Categories__c ='Identity Recovery and Resilience - AD, Entra ID, Okta';
        newPOCRequest59.RCV_Backup_Tier__c = 'No';
        newPOCRequest59.Data_Redundancy_Archive__c = 'Multi Zone (ZRS)';
        newPOCRequest59.Archive_TB__c = 5;
        
        newPOCRequest59.Add_Identity_Recovery__c = 'Yes';
        newPOCRequest59.How_many_Identity_UsersAreThere__c = null;
        insert newPOCRequest59;

        PocFormControllerCls.response_Wrapper obj59 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert59 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp59 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp59.filename='TestFilename.txt';
        fileListInsertTemp59.base64='Test Content';
        fileListInsert59.add(fileListInsertTemp59);
        obj59.pocRequestObj = newPOCRequest59;
        
        POC__c newPOCRequest60 = new POC__c();
        newPOCRequest60.POC_Type__c = 'Standard POC';
        newPOCRequest60.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest60.POC_Qty__c = 10;
        newPOCRequest60.POC_Justification__c = 'Test Justification';
        newPOCRequest60.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest60.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest60.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest60.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest60.Number_Of_NCD_FETB__c = 2;
        newPOCRequest60.Product_Categories__c ='Identity Recovery and Resilience - AD, Entra ID, Okta';
        newPOCRequest60.RCV_Backup_Tier__c = 'No';
        newPOCRequest60.Data_Redundancy_Archive__c = 'Multi Zone (ZRS)';
        newPOCRequest60.Archive_TB__c = 5;
        
        newPOCRequest58.Identity_Cyber_Recovery_for_Okta__c = 'Yes';
        newPOCRequest60.How_many_users_are_there_in_the_Okta_IdP__c = null;
        insert newPOCRequest60;

        PocFormControllerCls.response_Wrapper obj60 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert60 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp60 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp60.filename='TestFilename.txt';
        fileListInsertTemp60.base64='Test Content';
        fileListInsert60.add(fileListInsertTemp60);
        obj60.pocRequestObj = newPOCRequest60;
        
        POC__c newPOCRequest61 = new POC__c();
        newPOCRequest61.POC_Type__c = 'Standard POC';
        newPOCRequest61.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest61.POC_Qty__c = 10;
        newPOCRequest61.POC_Justification__c = 'Test Justification';
        newPOCRequest61.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest61.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest61.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest61.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest61.Number_Of_NCD_FETB__c = 2;
        newPOCRequest61.Product_Categories__c ='Identity Recovery and Resilience - AD, Entra ID, Okta';
        newPOCRequest61.RCV_Backup_Tier__c = 'No';
        newPOCRequest61.Data_Redundancy_Archive__c = 'Multi Zone (ZRS)';
        newPOCRequest61.Archive_TB__c = 5;
        
        newPOCRequest61.Add_Identity_Resilience__c = 'No';
        newPOCRequest61.Add_Identity_Recovery__c = 'No';
        newPOCRequest61.Identity_Cyber_Recovery_for_Okta__c = 'No';
        newPOCRequest61.How_many_identity_users_are_there__c = null;
        newPOCRequest61.How_many_Identity_UsersAreThere__c = null;
        newPOCRequest61.How_many_users_are_there_in_the_Okta_IdP__c = null;
        insert newPOCRequest61;
        
        PocFormControllerCls.response_Wrapper obj61 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert61 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp61 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp61.filename='TestFilename.txt';
        fileListInsertTemp61.base64='Test Content';
        fileListInsert61.add(fileListInsertTemp61);
        obj61.pocRequestObj = newPOCRequest61;
          
          POC__c newPOCRequest62 = new POC__c();
        newPOCRequest62.POC_Type__c = 'Standard POC';
        newPOCRequest62.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest62.POC_Qty__c = 10;
        newPOCRequest62.POC_Justification__c = 'Test Justification';
        newPOCRequest62.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest62.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest62.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest62.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest62.Number_Of_NCD_FETB__c = 2;
        newPOCRequest62.Product_Categories__c ='Rubrik Agent Cloud';
        newPOCRequest62.RCV_Backup_Tier__c = 'No';
        newPOCRequest62.Data_Redundancy_Archive__c = 'Multi Zone (ZRS)';
        newPOCRequest62.Archive_TB__c = 5;
        newPOCRequest62.Add_Identity_Resilience__c = 'No';
        insert newPOCRequest62;
        
        PocFormControllerCls.response_Wrapper obj62 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert62 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp62 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp62.filename='TestFilename.txt';
        fileListInsertTemp62.base64='Test Content';
        fileListInsert61.add(fileListInsertTemp62);
        obj62.pocRequestObj = newPOCRequest62;
        

        Test.startTest();
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser) {

        PocFormControllerCls.response_Wrapper resp = PocFormControllerCls.submitPOCRequest(obj1 , fileListInsert , 'false');
        PocFormControllerCls.response_Wrapper resp1 = PocFormControllerCls.submitPOCRequest(obj2 , fileListInsert , 'false');
        PocFormControllerCls.response_Wrapper resp2 = PocFormControllerCls.submitPOCRequest(obj3 , fileListInsert , 'false');
        PocFormControllerCls.response_Wrapper resp3 = PocFormControllerCls.submitPOCRequest(obj4 , fileListInsert , 'false');
        PocFormControllerCls.response_Wrapper resp4 = PocFormControllerCls.submitPOCRequest(obj5 , fileListInsert , 'false');
        PocFormControllerCls.response_Wrapper resp5 = PocFormControllerCls.submitPOCRequest(obj6 , fileListInsert , 'false');
        PocFormControllerCls.response_Wrapper resp6 = PocFormControllerCls.submitPOCRequest(obj7 , fileListInsert6 , 'true');
        PocFormControllerCls.response_Wrapper resp7 = PocFormControllerCls.submitPOCRequest(obj7 , fileListInsert7 , 'true');
        PocFormControllerCls.response_Wrapper resp8 = PocFormControllerCls.submitPOCRequest(obj8 , fileListInsert8 , 'false');
        PocFormControllerCls.response_Wrapper resp9 = PocFormControllerCls.submitPOCRequest(obj9 , fileListInsert9 , 'false');
        PocFormControllerCls.response_Wrapper resp10 = PocFormControllerCls.submitPOCRequest(obj10 , fileListInsert10 , 'false');
		PocFormControllerCls.response_Wrapper resp11 = PocFormControllerCls.submitPOCRequest(obj11 , fileListInsert11 , 'false');
        PocFormControllerCls.response_Wrapper resp12 = PocFormControllerCls.submitPOCRequest(obj12 , fileListInsert12 , 'false');
        PocFormControllerCls.response_Wrapper resp13 = PocFormControllerCls.submitPOCRequest(obj13 , fileListInsert13 , 'false');
        PocFormControllerCls.response_Wrapper resp14 = PocFormControllerCls.submitPOCRequest(obj14 , fileListInsert14 , 'false');
        PocFormControllerCls.response_Wrapper resp15 = PocFormControllerCls.submitPOCRequest(obj15 , fileListInsert15 , 'false');
        PocFormControllerCls.response_Wrapper resp16 = PocFormControllerCls.submitPOCRequest(obj16 , fileListInsert16 , 'false');
        PocFormControllerCls.response_Wrapper resp17 = PocFormControllerCls.submitPOCRequest(obj17 , fileListInsert17 , 'false');
        PocFormControllerCls.response_Wrapper resp18 = PocFormControllerCls.submitPOCRequest(obj18 , fileListInsert18 , 'false');
        PocFormControllerCls.response_Wrapper resp19 = PocFormControllerCls.submitPOCRequest(obj19 , fileListInsert19 , 'false');
        PocFormControllerCls.response_Wrapper resp20 = PocFormControllerCls.submitPOCRequest(obj20 , fileListInsert20 , 'false');
        PocFormControllerCls.response_Wrapper resp21 = PocFormControllerCls.submitPOCRequest(obj21 , fileListInsert21 , 'false');
        PocFormControllerCls.response_Wrapper resp22 = PocFormControllerCls.submitPOCRequest(obj22 , fileListInsert22 , 'false');
        PocFormControllerCls.response_Wrapper resp23 = PocFormControllerCls.submitPOCRequest(obj23 , fileListInsert23 , 'false');
        PocFormControllerCls.response_Wrapper resp24 = PocFormControllerCls.submitPOCRequest(obj24 , fileListInsert24 , 'false');
        PocFormControllerCls.response_Wrapper resp25 = PocFormControllerCls.submitPOCRequest(obj25 , fileListInsert25 , 'false');
        PocFormControllerCls.response_Wrapper resp26 = PocFormControllerCls.submitPOCRequest(obj26 , fileListInsert26 ,  'false');
        PocFormControllerCls.response_Wrapper resp27 = PocFormControllerCls.submitPOCRequest(obj27 , fileListInsert26 ,  'false');
        PocFormControllerCls.response_Wrapper resp28 = PocFormControllerCls.submitPOCRequest(obj28 , fileListInsert26 ,  'false');
            PocFormControllerCls.response_Wrapper resp29 = PocFormControllerCls.submitPOCRequest(obj29 , fileListInsert29 ,  'false');
            PocFormControllerCls.response_Wrapper resp30 = PocFormControllerCls.submitPOCRequest(obj30 , fileListInsert30 ,  'false');
            PocFormControllerCls.response_Wrapper resp31 = PocFormControllerCls.submitPOCRequest(obj31 , fileListInsert31 ,  'false');
            PocFormControllerCls.response_Wrapper resp32 = PocFormControllerCls.submitPOCRequest(obj32 , fileListInsert32 ,  'false');
            PocFormControllerCls.response_Wrapper resp33 = PocFormControllerCls.submitPOCRequest(obj33 , fileListInsert33 ,  'false');
            PocFormControllerCls.response_Wrapper resp34 = PocFormControllerCls.submitPOCRequest(obj34 , fileListInsert34 ,  'false');
            PocFormControllerCls.response_Wrapper resp35 = PocFormControllerCls.submitPOCRequest(obj35 , fileListInsert35 ,  'false');
            PocFormControllerCls.response_Wrapper resp36 = PocFormControllerCls.submitPOCRequest(obj36 , fileListInsert36 ,  'false');
            PocFormControllerCls.response_Wrapper resp37 = PocFormControllerCls.submitPOCRequest(obj37 , fileListInsert37 ,  'false');
            PocFormControllerCls.response_Wrapper resp38 = PocFormControllerCls.submitPOCRequest(obj38 , fileListInsert38 ,  'false');
            PocFormControllerCls.response_Wrapper resp39 = PocFormControllerCls.submitPOCRequest(obj39 , fileListInsert38 ,  'false');
            PocFormControllerCls.response_Wrapper resp40 = PocFormControllerCls.submitPOCRequest(obj40 , fileListInsert38 ,  'false');
            PocFormControllerCls.response_Wrapper resp41 = PocFormControllerCls.submitPOCRequest(obj41 , fileListInsert38 ,  'false');
            PocFormControllerCls.response_Wrapper resp42 = PocFormControllerCls.submitPOCRequest(obj42 , fileListInsert38 ,  'false');
            PocFormControllerCls.response_Wrapper resp43 = PocFormControllerCls.submitPOCRequest(obj43 , fileListInsert39 ,  'false');/*Start - Added for MKT26-490*/
            PocFormControllerCls.response_Wrapper resp44 = PocFormControllerCls.submitPOCRequest(obj44 , fileListInsert40 ,  'false');/*Start - Added for MKT26-490*/
            PocFormControllerCls.response_Wrapper resp45 = PocFormControllerCls.submitPOCRequest(obj45 , fileListInsert41 ,  'false');/*Start - Added for MKT26-490*/
            PocFormControllerCls.response_Wrapper resp46 = PocFormControllerCls.submitPOCRequest(obj46 , fileListInsert42 ,  'false');/*Start - Added for MKT26-490*/
            //PocFormControllerCls.response_Wrapper resp47 = PocFormControllerCls.submitPOCRequest(obj47 , fileListInsert42 ,  'false');/*Start - Added for MKT26-*/
            PocFormControllerCls.response_Wrapper resp48 = PocFormControllerCls.submitPOCRequest(obj48 , fileListInsert42 ,  'false');
            PocFormControllerCls.response_Wrapper resp49 = PocFormControllerCls.submitPOCRequest(obj49 , fileListInsert42 ,  'false');
            PocFormControllerCls.response_Wrapper resp50 = PocFormControllerCls.submitPOCRequest(obj50 , fileListInsert42 ,  'false');
            PocFormControllerCls.response_Wrapper resp51 = PocFormControllerCls.submitPOCRequest(obj51 , fileListInsert42 ,  'false');
          PocFormControllerCls.response_Wrapper resp52 = PocFormControllerCls.submitPOCRequest(obj52 , fileListInsert42 ,  'false');
            PocFormControllerCls.response_Wrapper resp53 = PocFormControllerCls.submitPOCRequest(obj53 , fileListInsert42 ,  'false');
          PocFormControllerCls.response_Wrapper resp56 = PocFormControllerCls.submitPOCRequest(obj56 , fileListInsert42 ,  'false');
            PocFormControllerCls.response_Wrapper resp57 = PocFormControllerCls.submitPOCRequest(obj57 , fileListInsert42 ,  'false');
            PocFormControllerCls.response_Wrapper resp58 = PocFormControllerCls.submitPOCRequest(obj58 , fileListInsert58 ,  'false');
            PocFormControllerCls.response_Wrapper resp59 = PocFormControllerCls.submitPOCRequest(obj59 , fileListInsert59 ,  'false');
            PocFormControllerCls.response_Wrapper resp60 = PocFormControllerCls.submitPOCRequest(obj60 , fileListInsert60 ,  'false');
            PocFormControllerCls.response_Wrapper resp61 = PocFormControllerCls.submitPOCRequest(obj61 , fileListInsert61 ,  'false');
            PocFormControllerCls.response_Wrapper respM365GSpace = PocFormControllerCls.submitPOCRequest(objM365GSpace , fileListInsertM365 ,  'false');
            PocFormControllerCls.response_Wrapper respM365GSpace1 = PocFormControllerCls.submitPOCRequest(objM365GSpace1 , fileListInsertM3651 ,  'false');
            
        PocFormControllerCls.updatePOCRequest(newPOCRequest13);
            PocFormControllerCls pocformcntrl = new PocFormControllerCls();
            //pocformcntrl.selected_UCL_RCVBackup = 1;
            //pocformcntrl.selectedUCLRCVBackupZone = 'Single Zone';
            System.assertNotEquals(resp28, null);
        }
        Test.stopTest();
    }

    @isTest
    static void testGetPriceBook() {
        PriceBook2 pb1 = new Pricebook2(Name = 'Test PriceBook', Description = 'Price Book 2009 Products 1', IsActive = true);
        insert pb1;
		
        Test.startTest();
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser) {

        Pricebook2 pricebookResp = PocFormControllerCls.getPriceBook(pb1.Id);
            System.assertNotEquals(pricebookResp, null);
        }
        Test.stopTest();
    }

    @isTest
    static void testValidateCheck() {
        id rId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        OpportunityStage stage = [SELECT MasterLabel FROM OpportunityStage WHERE IsWon = false AND IsClosed = false AND isActive = true LIMIT 1];

        Account acct = new Account( recordTypeId = rId, Name = 'Test Account');
        acct.Agreed_To_POC_terms__c = true;
        acct.Partner_Agreement_Status__c = 'Signed - Active';
        insert acct;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acct.Id,
            StageName = '7 Closed Won',
            CloseDate = System.today().addDays(15),
            PriceBook2Id = system.label.CPQPricebookID,
            SBQQ__QuotePricebookId__c = system.label.CPQPricebookID,
            Alliance_Partner_Name__c = 'Amazon',
            Alliance_Source_Type__c = 'Alliance Initiated Deal',
            Alliance_Source_Type_SW__c = 'Test',
            Compelling_Bus_Driver__c = 'Instant Recovery',
            Current_State__c = 'test',
            Negative_Consequences__c = 'test',
            Future_State__c = 'test',
            Positive_Business_Outcomes__c = 'test',
            Distributor_Lookup__c = null,
            Opportunity_Sub_Type__c = 'MSP Overage',
            Opportunity_Type__c = 'New Customer',
            Rubrik_Sales_Engineer__c = UserInfo.getUserId(),
            Win_Loss_Comments__c = 'test',
            Primary_Competitor__c = 'Actifio',
            Key_Feature_Needs__c = 'None',
            Valooto_Quote__c = '123123123',
            Valooto_Quote_Stage__c = 'Approved',
            Partner_Level_Of_Involvement__c = '1.Rubrik initiated, Partner was fulfillment only',
            Cloud_Type__c = 'IBM'
        );

        opp.Partner_Lookup__c = null;
        opp.ETM_Theatre__c = 'AMER';
        opp.ETM_Region__c = 'BENELUX';
        insert opp;

        // Opportunity opp1 = new Opportunity();
        // opp1.Pricebook2Id = system.label.CPQPricebookID;
        // opp1.Economic_Buyer__c= 'test';
        // opp1.Partner_Lookup__c= acct.Id;
        // opp1.Distributor_Lookup__c= acct.Id;
        // opp1.Champion__c= 'test';
        // opp1.StageName= stage.MasterLabel;

        // insert opp1;

        Test.startTest();
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser) {

        Map<String , String> res = PocFormControllerCls.validateCheck(opp.Id);
            System.assertNotEquals(res, null);
        }
        // Map<String , String> res1 = PocFormControllerCls.validateCheck(opp1.Id);
        Test.stopTest();
    }

    @isTest
    static void testValidateInstallationDate() {
        Date inputDate = system.today().addDays(-2); // 2024-06-7 00:00:00
        Date expectedEndDate = system.today().addDays(-2);

        Date inputDate1 = system.today().addDays(5); // 2024-06-7 00:00:00
		
        Test.startTest();
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser) {

            Map<String , String> res = PocFormControllerCls.validateInstallationDate(inputDate,'PlanDateLogic','7','Standard POC',expectedEndDate);
        PocFormControllerCls.validateInstallationDate(inputDate,'ExpectedDateLogic','7','Standard POC',expectedEndDate);
        PocFormControllerCls.validateInstallationDate(inputDate,'','7','Standard POC',expectedEndDate);
        PocFormControllerCls.validateInstallationDate(inputDate1,'PlanDateLogic','7','Web Try and Buy',expectedEndDate);
            System.assertNotEquals(res, null);
        Test.stopTest();
    }
    }
    @isTest
    static void teststandardPOCRSCG(){
        List<Id> pocIdLists = new List<Id>();
        List<Contact> lstContact = [Select Id, Name FROM Contact];
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Standard POC';
        newPOCRequest.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest.POC_Qty__c = 10;
        newPOCRequest.POC_Justification__c = 'Test Justification';
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Opportunity__c = createOpportunity().Id;
        newPOCRequest.Number_of_Users__c = 504;
        newPOCRequest.RCV_Backup_Tier__c = 'Yes';
        newPOCRequest.Backup_TB__c = null;
        //newPOCRequest.RSC_G_Contact__c  = lstContact[0].Id;
        insert newPOCRequest;
        
        PocFormControllerCls.response_Wrapper obj = new PocFormControllerCls.response_Wrapper();
        obj.pocRequestObj = newPOCRequest;
        
        POC__c newPOCRequest1 = new POC__c();
        newPOCRequest1.POC_Type__c = 'Standard POC';
        newPOCRequest1.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest1.POC_Qty__c = 10;
        newPOCRequest1.POC_Justification__c = 'Test Justification';
        newPOCRequest1.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest1.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest1.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest1.Opportunity__c = createOpportunity().Id;
        newPOCRequest1.Number_of_Users_RSCG__c = 504;
        newPOCRequest1.RCV_Backup_Tier__c = 'Yes';
        newPOCRequest1.Backup_TB__c = null;
        newPOCRequest1.AE_Email__c = 'test@rubrik.com';
        insert newPOCRequest1;
        pocIdLists.add(newPOCRequest1.Id);
        
        POC__c newPOCRequest2 = new POC__c();
        newPOCRequest2.POC_Type__c = 'Standard POC';
        newPOCRequest2.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest2.POC_Qty__c = 10;
        newPOCRequest2.POC_Justification__c = 'Test Justification';
        newPOCRequest2.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest2.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest2.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest2.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest2.Number_Of_NCD_FETB__c = 2;
        newPOCRequest2.Product_Categories__c ='Identity Recovery';
        newPOCRequest2.How_many_identity_users_areThere__c = 0;
        insert newPOCRequest2;
        
        POC__c newPOCRequest3 = new POC__c();
        newPOCRequest3.POC_Type__c = 'Standard POC';
        newPOCRequest3.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest3.POC_Qty__c = 10;
        newPOCRequest3.POC_Justification__c = 'Test Justification';
        newPOCRequest3.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest3.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest3.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest3.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest3.Product_Categories__c ='NAS Cloud Direct;Rubrik Cloud Vault';
        newPOCRequest3.NCD_Editions__c = 'Enterprise Edition (w/RCV + Ransomware Monitoring + Sensitive Data Discovery)';
        newPOCRequest3.Archive_TB__c = 15;
        insert newPOCRequest3;
        
        POC__c newPOCRequest4 = new POC__c();
        newPOCRequest4.POC_Type__c = 'Standard POC';
        newPOCRequest4.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest4.POC_Qty__c = 10;
        newPOCRequest4.POC_Justification__c = 'Test Justification';
        newPOCRequest4.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest4.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest4.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest4.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest4.Product_Categories__c ='NAS Cloud Direct;Rubrik Cloud Vault';
        newPOCRequest4.NCD_Editions__c = 'Enterprise Edition (w/RCV + Ransomware Monitoring + Sensitive Data Discovery)';
        newPOCRequest4.Backup_TB__c = 15;
        insert newPOCRequest4;
        
        POC__c newPOCRequest5 = new POC__c();
        newPOCRequest5.POC_Type__c = 'Standard POC';
        newPOCRequest5.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest5.POC_Qty__c = 10;
        newPOCRequest5.POC_Justification__c = 'Test Justification';
        newPOCRequest5.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest5.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest5.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest5.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest5.Product_Categories__c ='NAS Cloud Direct;Rubrik Cloud Vault';
        newPOCRequest5.NCD_Editions__c = 'Enterprise Edition (w/RCV + Ransomware Monitoring + Sensitive Data Discovery)';
        newPOCRequest5.Backup_TB__c = 5;
        insert newPOCRequest5;
        
        POC__c newPOCRequest6 = new POC__c();//Start - MKT26-99
        newPOCRequest6.POC_Type__c = 'Standard POC : RSC-G';
        newPOCRequest6.POC_Qty__c = 10;
        newPOCRequest6.POC_Justification__c = 'Test Justification';
        newPOCRequest6.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest6.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest6.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest6.Opportunity__c = createOpportunity().Id;
        newPOCRequest6.Number_of_Users__c = 504;
        newPOCRequest6.RCV_Backup_Tier__c = 'Yes';
        newPOCRequest6.Backup_TB__c = null;
        newPOCRequest6.RSC_G_Contact__c  = lstContact[0].Id;
        insert newPOCRequest6;
        
        POC__c newPOCRequest7 = new POC__c();
        newPOCRequest7.POC_Type__c = 'Standard POC : RSC-G';
        newPOCRequest7.POC_Qty__c = 10;
        newPOCRequest7.POC_Justification__c = 'Test Justification';
        newPOCRequest7.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest7.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest7.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest7.Opportunity__c = createOpportunity().Id;
        newPOCRequest7.Number_of_Users__c = 504;
        newPOCRequest7.RCV_Backup_Tier__c = 'Yes';
        newPOCRequest7.Backup_TB__c = null;
        newPOCRequest7.RSC_G_Contact__c  = null;
        newPOCRequest7.RCV_Backup_Tier__c  = 'Yes';
        newPOCRequest7.Backup_TB__c  = 50;
        newPOCRequest7.Product_Categories__c = 'Rubrik Cloud Vault - Government';
        insert newPOCRequest7;
        ///End - MKT26-99
        
        POC__c newPOCRequest8 = new POC__c();
        newPOCRequest8.POC_Type__c = 'Standard POC';
        newPOCRequest8.POC_Qty__c = 10;
        newPOCRequest8.POC_Justification__c = 'Test Justification';
        newPOCRequest8.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest8.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest8.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest8.Opportunity__c = createOpportunity().Id;
        newPOCRequest8.Dynamics__c = 'Yes';
        newPOCRequest8.Number_of_Users_Dynamics__c = 0;
        newPOCRequest8.Salesforce__c = 'No';
        newPOCRequest8.Number_of_Users_Salesforce__c = 0;
        newPOCRequest8.Jira_Cloud__c = 'No';
        newPOCRequest8.Number_of_Users_Atlassian__c = 0;
        newPOCRequest8.Product_Categories__c = 'SaaS (Jira Cloud, Salesforce, Dynamics)';
        insert newPOCRequest8;//MKT26-93

        PocFormControllerCls.response_Wrapper obj1 = new PocFormControllerCls.response_Wrapper();
        obj1.pocRequestObj = newPOCRequest1;
        PocFormControllerCls.response_Wrapper obj2 = new PocFormControllerCls.response_Wrapper();
        obj2.pocRequestObj = newPOCRequest2;
        PocFormControllerCls.response_Wrapper obj3 = new PocFormControllerCls.response_Wrapper();
        obj3.pocRequestObj = newPOCRequest3;
        PocFormControllerCls.response_Wrapper obj4 = new PocFormControllerCls.response_Wrapper();
        obj4.pocRequestObj = newPOCRequest4;
        PocFormControllerCls.response_Wrapper obj5 = new PocFormControllerCls.response_Wrapper();
        obj5.pocRequestObj = newPOCRequest5;
        PocFormControllerCls.response_Wrapper obj6 = new PocFormControllerCls.response_Wrapper();//MKT26-99
        obj6.pocRequestObj = newPOCRequest6;//MKT26-99
        PocFormControllerCls.response_Wrapper obj7 = new PocFormControllerCls.response_Wrapper();//MKT26-99
        obj7.pocRequestObj = newPOCRequest7;//MKT26-99
        PocFormControllerCls.response_Wrapper obj8 = new PocFormControllerCls.response_Wrapper();//MKT26-99
        obj8.pocRequestObj = newPOCRequest8;//MKT26-93
        
        List<PocFormControllerCls.fileInnerClass> fileListInsert = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp.filename='TestFilename.txt';
        fileListInsertTemp.base64='Test Content';
        fileListInsert.add(fileListInsertTemp);
        
        POC__c newPOCRequestM365GSpace1 = new POC__c();
        newPOCRequestM365GSpace1.POC_Type__c = 'Standard POC';
        newPOCRequestM365GSpace1.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequestM365GSpace1.POC_Qty__c = 10;
        newPOCRequestM365GSpace1.POC_Justification__c = 'Test Justification';
        newPOCRequestM365GSpace1.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequestM365GSpace1.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequestM365GSpace1.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequestM365GSpace1.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequestM365GSpace1.Number_Of_NCD_FETB__c = 2;
        newPOCRequestM365GSpace1.Product_Categories__c ='M365 and Google Workspace';
        newPOCRequestM365GSpace1.RCV_Backup_Tier__c = 'No';
        newPOCRequestM365GSpace1.Data_Redundancy_Archive__c = 'Multi Zone (ZRS)';
        newPOCRequestM365GSpace1.Archive_TB__c = 5;
        
        newPOCRequestM365GSpace1.M365_Option__c = 'Yes';
        newPOCRequestM365GSpace1.M365_Hosting_environment__c = 'Rubrik Hosted EE, DSPM, Identity Recovery & Resilience';
        insert newPOCRequestM365GSpace1;

        PocFormControllerCls.response_Wrapper objM365GSpace1 = new PocFormControllerCls.response_Wrapper();
        List<PocFormControllerCls.fileInnerClass> fileListInsert1M365 = new List<PocFormControllerCls.fileInnerClass> ();
        PocFormControllerCls.fileInnerClass fileListInsertTemp1M365 = new PocFormControllerCls.fileInnerClass ();
        fileListInsertTemp1M365.filename='TestFilename.txt';
        fileListInsertTemp1M365.base64='Test Content';
        fileListInsert1M365.add(fileListInsertTemp1M365);
        objM365GSpace1.pocRequestObj = newPOCRequestM365GSpace1;
        
        
        Test.startTest();
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser) {

            PocFormControllerCls.response_Wrapper resp = PocFormControllerCls.submitPOCRequest(obj , fileListInsert , 'false');
            PocFormControllerCls.response_Wrapper resp1 = PocFormControllerCls.submitPOCRequest(obj1 , fileListInsert , 'false');
            PocFormControllerCls.response_Wrapper resp2 = PocFormControllerCls.submitPOCRequest(obj2 , fileListInsert , 'false');
            PocFormControllerCls.response_Wrapper resp3 = PocFormControllerCls.submitPOCRequest(obj3 , fileListInsert , 'false');
            PocFormControllerCls.response_Wrapper resp4 = PocFormControllerCls.submitPOCRequest(obj4 , fileListInsert , 'false');
            PocFormControllerCls.response_Wrapper resp5 = PocFormControllerCls.submitPOCRequest(obj5 , fileListInsert , 'true');
            PocFormControllerCls.response_Wrapper resp6 = PocFormControllerCls.submitPOCRequest(obj6 , fileListInsert , 'true');//MKT26-99
            PocFormControllerCls.response_Wrapper resp7 = PocFormControllerCls.submitPOCRequest(obj7 , fileListInsert , 'true');//MKT26-99
            PocFormControllerCls.response_Wrapper resp8 = PocFormControllerCls.submitPOCRequest(obj8 , fileListInsert , 'true');//MKT26-93
            newPOCRequest8.Dynamics__c = 'Yes';
            newPOCRequest8.Number_of_Users_Dynamics__c = 0;
            newPOCRequest8.Salesforce__c = 'Yes';
            newPOCRequest8.Number_of_Users_Salesforce__c = 201;
            newPOCRequest8.Jira_Cloud__c = 'Yes';
            newPOCRequest8.Number_of_Users_Atlassian__c = 201;
            resp8 = PocFormControllerCls.submitPOCRequest(obj8 , fileListInsert , 'true');//MKT26-93
            newPOCRequest8.Dynamics__c = 'Yes';
            newPOCRequest8.Number_of_Users_Dynamics__c = 201;
            newPOCRequest8.Salesforce__c = 'Yes';
            newPOCRequest8.Number_of_Users_Salesforce__c = 201;
            newPOCRequest8.Jira_Cloud__c = 'Yes';
            newPOCRequest8.Number_of_Users_Atlassian__c = 0;
            resp8 = PocFormControllerCls.submitPOCRequest(obj8 , fileListInsert , 'true');//MKT26-93
            newPOCRequest8.Dynamics__c = 'No';
            newPOCRequest8.Number_of_Users_Dynamics__c = 201;
            newPOCRequest8.Salesforce__c = 'Yes';
            newPOCRequest8.Number_of_Users_Salesforce__c = 201;
            newPOCRequest8.Jira_Cloud__c = 'Yes';
            newPOCRequest8.Number_of_Users_Atlassian__c = 201;
            resp8 = PocFormControllerCls.submitPOCRequest(obj8 , fileListInsert , 'true');//MKT26-93
            newPOCRequest8.Dynamics__c = 'Yes';
            newPOCRequest8.Number_of_Users_Dynamics__c = 201;
            newPOCRequest8.Salesforce__c = 'No';
            newPOCRequest8.Number_of_Users_Salesforce__c = 201;
            newPOCRequest8.Jira_Cloud__c = 'Yes';
            newPOCRequest8.Number_of_Users_Atlassian__c = 201;
            resp8 = PocFormControllerCls.submitPOCRequest(obj8 , fileListInsert , 'true');//MKT26-93
            newPOCRequest8.Dynamics__c = 'Yes';
            newPOCRequest8.Number_of_Users_Dynamics__c = 201;
            newPOCRequest8.Salesforce__c = 'Yes';
            newPOCRequest8.Number_of_Users_Salesforce__c = 201;
            newPOCRequest8.Jira_Cloud__c = 'No';
            newPOCRequest8.Number_of_Users_Atlassian__c = 201;
            resp8 = PocFormControllerCls.submitPOCRequest(obj8 , fileListInsert , 'true');//MKT26-93     
            
            PocFormControllerCls.response_Wrapper respM365GSpace1 = PocFormControllerCls.submitPOCRequest(objM365GSpace1 , fileListInsert1M365 ,  'false');
           PocFormControllerCls.retrunDefaultValuetoFrom(createOpportunity().Id);
        }
        System.assertEquals(true, newPOCRequest1.Id != null);
        Test.stopTest();
        PocFormControllerCls.populateEmailsOnPoc(pocIdLists);
        PocFormControllerCls.PicklistEntryWrapper clsVar = new PocFormControllerCls.PicklistEntryWrapper();
        clsVar.defaultValue = 'test';
        clsVar.active = 'test';
        account acct = [Select id from Account limit 1];
        PocFormControllerCls.getPicklistValues('RSCInstance__c', 'RSCAccountType__c');
        PocFormControllerCls.getRscInstance(acct.Id);
        
    }
    
    /**
   * @description Submits a Proof of Concept (POC) request based on the provided request object.
   * @return response_Wrapper An object containing the POC request response, including validation errors, if any.
  */
    public static opportunity createOpportunity(){
        Account acc = [SELECT Id,RSC_G_Eligible__c FROM Account LIMIT 1];
        acc.RSC_G_Eligible__c = true;
        update acc;
        User usrd = [select id,Email from user where name = 'test test' LIMIT 1];
        Opportunity o = new Opportunity();
        o.AccountId = acc.Id;
        o.PriceBook2Id = Test.getStandardPricebookId();
        o.Amount = 10.00;
        o.Name = 'Unit Test Purposes2';
        o.Rubrik_Security_Cloud_Gov_t_Owner__c = null;
        o.CloseDate = Date.Today().addDays(5);
        o.StageName = 'Prospecting';
        o.Economic_Buyer__c = 'test';
        o.Partner_Lookup__c = acc.Id;
        o.Distributor_Lookup__c = acc.Id;
        o.Champion__c = 'test';
        o.OwnerId = usrd.Id;
        o.Rubrik_Sales_Engineer__c = usrd.Id;
        insert o;
        return o;
    }
}