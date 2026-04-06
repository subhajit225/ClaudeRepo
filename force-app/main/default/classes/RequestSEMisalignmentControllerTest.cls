@isTest
private class RequestSEMisalignmentControllerTest {
    
    @testsetup static void createData() {
        Test.startTest();
        OktaUserUtilityTest.oktaCustomSettingsParams();
        Test.stopTest();
    }
    
    @isTest static void test_method_one() {
        ShGl_TestFactoryHelper.insertCustomSettings();
        String manageruniqueUserName = 'managerAdminUser' + DateTime.now().getTime() + '@rubrik.com';
        String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
        String runninguniqueUserName = 'runninguserAdminUser' + DateTime.now().getTime() + '@rubrik.com';
        
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        
        OpportunityUtil.defaultPriceBookId = Test.getStandardPricebookId();
        
        ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c();
        settingDisable.Trigger_Max_Loop_Count__c = 10;
        settingDisable.Disable_Opportunity_Validation_Rules__c = true;
        insert settingDisable;
        
        upsert disableFuncCS;
        
        Account act = new Account();
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act.Name = 'Test Account 31-05';
        act.RecordTypeId = recordTypeId;
        insert act;
        
        Pricebook2 pbk1 = new Pricebook2(Name = 'Test Pricebook Entry 1', Description = 'Test Pricebook Entry 1', isActive = true);
            insert pbk1;
            
            Product2 prd1 = new Product2(Name = 'Test Product Entry 1', Description = 'Test Product Entry 1', productCode = 'OPTY-SPLIT', isActive = true);
            insert prd1;
            
            PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prd1.Id, UnitPrice = 40, IsActive = true, UseStandardPrice = false);
            insert standardPrice;
            
            Id standardPBId = test.getStandardPricebookId();
            PriceBookEntry pbEntry = new PriceBookEntry(
                UnitPrice = 300,
                PriceBook2Id = standardPBId,
                Product2Id = prd1.Id,
                IsActive = true,
                UseStandardPrice = false);
            
            
            //Generate the Contact
            Map < String, Object > cntMap = new Map < String, Object > {
                'AccountId' => act.Id,
                    'Email' => 'leademail@hidden.com.sandbox'
                    };
                        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
            insert cnt1;
            
            //Generate the Opportunity
            Map < String, Object > oppMap = new Map < String, Object > {
                'AccountId' => act.Id,
                    'Initial_Contacts_Name__c' => cnt1.Id,
                    'StageName' => '1 Discovery'
                    };
                        
            List < Opportunity > opptyList = (List < Opportunity > ) ShGl_TestFactory.createSObjectList(new Opportunity(), 3, oppMap);
            opptyList[0].Lead_Email_Hidden__c = 'leademail@hidden.com.sandbox';
            opptyList[0].Converted_From_Lead__c = true;
            opptyList[0].Pricebook2Id = Test.getStandardPricebookId();
            opptyList[0].Primary_Competitor__c = 'Other';
            opptyList[0].ForecastCategoryName = 'Best Case';
            opptyList[0].Other_Competitor_Field__c = 'Testing';
            insert opptyList;
    
            ApexPages.StandardController sc = new ApexPages.StandardController(opptyList[0]);
            RequestSEMisalignmentController controllerObj = new RequestSEMisalignmentController(sc);
            PageReference pageRef = Page.RequestSEMisalignment;
            pageRef.getParameters().put('id', String.valueOf(opptyList[0].Id));
            Test.setCurrentPage(pageRef);
            PageReference errorPageRef = controllerObj.save();
            
            RequestSEMisalignmentControllerLWC.getOppDetails(opptyList[0].Id);
            RequestSEMisalignmentControllerLWC.save(opptyList[0]);
            
            System.assertEquals(null, errorPageRef);
    
            opptyList[0].SE_Misalignment_User__c = userInfo.getUserId() ;
            
            flowControll.opportunityTriggerHandler = false;
            update opptyList[0];
            PageReference successPageRef = controllerObj.save();
            
               RequestSEMisalignmentControllerLWC.getOppDetails(opptyList[0].Id);
               RequestSEMisalignmentControllerLWC.save(opptyList[0]);
        
        RequestSEMisalignmentController.unlockRecord(opptyList[0].Id);
    }
    
        
    
     @isTest static void test_method_two() {
        ShGl_TestFactoryHelper.insertCustomSettings();
        String manageruniqueUserName = 'managerAdminUser' + DateTime.now().getTime() + '@rubrik.com';
        String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
        String runninguniqueUserName = 'runninguserAdminUser' + DateTime.now().getTime() + '@rubrik.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        Profile p2 = [SELECT Id FROM Profile WHERE Name='Sales Operations'];
        User manageruser = new User(
            Alias = 'adminU', Email='AdminUser@rubrik.com.sandbox',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p2.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName=manageruniqueUserName
        );
        insert manageruser;
        User runninguser = new User(
            Alias = 'adminU', Email='AdminUser@rubrik.com.sandbox',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName=runninguniqueUserName
        );
        insert runninguser;
        User u = new User(
            Alias = 'adminU', Email='AdminUser@rubrik.com.sandbox',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p2.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName=uniqueUserName, ManagerId=manageruser.Id
        );
        insert u;
        System.runAs(runninguser) {
            Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            insert act;
            
            Pricebook2 pbk1 = new Pricebook2(Name = 'Test Pricebook Entry 1', Description = 'Test Pricebook Entry 1', isActive = true);
            insert pbk1;
            
            Product2 prd1 = new Product2(Name = 'Test Product Entry 1', Description = 'Test Product Entry 1', productCode = 'OPTY-SPLIT', isActive = true);
            insert prd1;
            
            PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prd1.Id, UnitPrice = 40, IsActive = true, UseStandardPrice = false);
            insert standardPrice;
            
            Id standardPBId = test.getStandardPricebookId();
            PriceBookEntry pbEntry = new PriceBookEntry(
                UnitPrice = 300,
                PriceBook2Id = standardPBId,
                Product2Id = prd1.Id,
                IsActive = true,
                UseStandardPrice = false);
            
            
            //Generate the Contact
            Map < String, Object > cntMap = new Map < String, Object > {
                'AccountId' => act.Id,
                    'Email' => 'leademail@hidden.com.sandbox'
                    };
                        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
            insert cnt1;
            
            //Generate the Opportunity
            Map < String, Object > oppMap = new Map < String, Object > {
                'AccountId' => act.Id,
                    'Initial_Contacts_Name__c' => cnt1.Id,
                    'StageName' => '1 Discovery'
                    };
                        
            List < Opportunity > opptyList = (List < Opportunity > ) ShGl_TestFactory.createSObjectList(new Opportunity(), 3, oppMap);
            opptyList[0].Lead_Email_Hidden__c = 'leademail@hidden.com.sandbox';
            opptyList[0].Converted_From_Lead__c = true;
            opptyList[0].Pricebook2Id = Test.getStandardPricebookId();
            opptyList[0].Primary_Competitor__c = 'Other';
            opptyList[0].ForecastCategoryName = 'Best Case';
            opptyList[0].Other_Competitor_Field__c = 'Testing';
            insert opptyList;
    
            opptyList[0].SE_Misalignment_User__c = u.Id;
            
            flowControll.opportunityTriggerHandler = false;
            update opptyList[0];

            
            RequestSEMisalignmentControllerLWC.getOppDetails(opptyList[0].Id);
            RequestSEMisalignmentControllerLWC.save(opptyList[0]);
        }

    }
}