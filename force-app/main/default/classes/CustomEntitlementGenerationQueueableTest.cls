@isTest
public with sharing class CustomEntitlementGenerationQueueableTest {
    
    @testSetup 
    static void testSetup() {  
        String baseEmail = 'testuser@testclass.com';
        String commonAlias = 'std';
        String profileName = 'System Administrator';
        String localeKey = 'en_US';
        String timezone = 'America/Los_Angeles';
        String emailEncoding = 'UTF-8';
        Profile profile = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        
        // Generate unique usernames
        String uniqueUserNamePrefix = 'TestUser';
        
        List<User> userList = new List<User>();
        
        for (Integer i = 0; i < 3; i++) {
            User user = new User(
                alias = commonAlias,
                email = baseEmail,    
                emailencodingkey = emailEncoding,
                firstname = 'test',
                lastname = 'user',
                languagelocalekey = localeKey,
                localesidkey = localeKey,
                profileid = profile.Id,
                timezonesidkey = timezone,
                username = uniqueUserNamePrefix + i + DateTime.now().getTime() + '@rbk.com'
            );
            userList.add(user);
        }
        
        // Insert the users
        Test.startTest();
        insert userList;
        System.runAs(userList[0]) {
            Id userId = UserInfo.getUserId();
            Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            Id standardPricebookId = Test.getStandardPricebookId();
            
            // Insert configuration records
            List<SObject> configRecords = new List<SObject>{
                new ShGl_DisableFunctionalityLogic__c(
                    setupOwnerId = userId,
                    Disable_Account_Old_Trigger__c = TRUE
                ),
                    new ShGl_DisableBusinessLogic__c(
                        setupownerid = userId,
                        Disable_Account_Triggers__c = TRUE,
                        Disable_Asset_Triggers__c = TRUE,
                        Disable_SBQQ_Quote_Triggers__c = TRUE,
                        Disable_SBQQ_QuoteLine_Triggers__c = TRUE,
                        Disable_Product2_Validation_Rules__c = TRUE,
                        Disable_Order_Old_Trigger__c = TRUE,
                        Disable_OrderItem_Old_Trigger__c = TRUE,
                        Disable_Opportunity_Triggers__c = TRUE,
                        Disable_Product2_Trigger__c = TRUE,
                        Disable_SBQQ_QuoteLine_Validation_Rules__c = TRUE
                    )
                    };
                        insert configRecords;
            
            TriggerControl.stopOrderItemTrigger = TRUE;
            TriggerControl.stopOrderTrigger = TRUE;
            
            // Insert TriggerControl__c record
            insert new TriggerControl__c(
                Name = 'Entitlement',
                Disable_Trigger__c = TRUE,
                DisableTrigger__c = TRUE,
                SendEmail__c = FALSE
            );
            
            // Create and insert Account
            Account customer = new Account(
                Name = 'Customer',
                RecordTypeId = partnerRecordTypeId,
                Phone = '123-456-7890',
                AccountNumber = 'Test',
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
            insert customer;
            
            // Create and insert Opportunities
            List<Opportunity> opportunities = new List<Opportunity>{
                TestDataFactory.getOpportunity(),
                    TestDataFactory.getOpportunity()
                    };
                        
                        for (Opportunity opp : opportunities) {
                            opp.Partner_Lookup__c = customer.Id;
                            opp.AccountId = customer.Id;
                            opp.Distributor_Lookup__c = customer.Id;
                            opp.Pricebook2Id = standardPricebookId;
                        }
            insert opportunities;
            
            // Create and insert Quotes
            List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>{
                new SBQQ__Quote__c(
                    SBQQ__Opportunity2__c = opportunities[0].Id,
                    SBQQ__SubscriptionTerm__c = 12,
                    Is_RWD_Polaris_Quote__c = TRUE,
                    SBQQ__Primary__c = TRUE,
                    ApprovalStatus__c = 'Recalled',
                    SBQQ__Type__c = 'Quote',
                    SBQQ__PriceBook__c = standardPricebookId
                ),
                    new SBQQ__Quote__c(
                        SBQQ__Opportunity2__c = opportunities[1].Id,
                        SBQQ__SubscriptionTerm__c = 12,
                        Is_RWD_Polaris_Quote__c = TRUE,
                        SBQQ__Primary__c = TRUE,
                        ApprovalStatus__c = 'Recalled',
                        SBQQ__Type__c = 'Renewal+Expansion',
                        SBQQ__PriceBook__c = standardPricebookId
                    )
                    };
                        insert quotes;
            
            String baseCategory = 'Support';
            String EntitlementConversionOnePerQLI = 'One per quote line';
            String EntitlementConversionOnePerUnit = 'One per unit';
            String commonSubscriptionPricing = 'Fixed Price';
            String commonSubscriptionBase = 'List';
            Integer commonSubscriptionTerm = 36;
            Boolean isActive = true;
            
            List<Product2> sampleProducts = new List<Product2>{
                new Product2(Name = 'RS-BT-EE-PE-PP', ProductCode = 'RS-BT-EE-PE-PP', Category__c = 'Bundle', Family = 'Rubrik Licence', Product_Type__c = 'Enterprise Edition', License_Category__c = 'SaaS', Product_Level__c = 'Hybrid Software', SBQQ__AssetAmendmentBehavior__c = 'Default', SBQQSC__EntitlementConversion__c = EntitlementConversionOnePerQLI, IsActive = isActive, SBQQ__SubscriptionPricing__c = commonSubscriptionPricing, SBQQ__SubscriptionTerm__c = commonSubscriptionTerm, SBQQ__SubscriptionBase__c = commonSubscriptionBase, SBQQ__SubscriptionType__c = 'Renewable'),
                    new Product2(Name = 'RBK-R6412-CONS', ProductCode = 'RBK-R6412-CONS', Category__c = 'Platform', Family = 'r300', Usable_Capacity__c = 1, Product_Level__c = 'Hardware', Product_Type__c = 'Hardware', Appliance_Model__c = 'RBK-R344', Appliance_Model_HW__c = 'RBK-R344', CPQ_MSP_Base_Price__c = 0.13, SBQQSC__EntitlementConversion__c = 'None', SBQQ__AssetAmendmentBehavior__c = 'Default', IsActive = isActive, Asset_Priority__c = 0, MSP_Segment_Product__c = true, SBQQ__SubscriptionPricing__c = commonSubscriptionPricing, SBQQ__SubscriptionTerm__c = 1, SBQQ__SubscriptionBase__c = commonSubscriptionBase, SBQQ__SubscriptionType__c = 'Renewable'),
                    new Product2(Name = 'RBK-RADAR-CONS', ProductCode = 'RBK-RADAR-CONS', Category__c = 'Support', Product_Level__c = 'Support', SBQQ__AssetAmendmentBehavior__c = 'Default', SBQQSC__EntitlementConversion__c = EntitlementConversionOnePerQLI, IsActive = isActive, CPQ_MSP_Base_Price__c = 0.02, SBQQ__SubscriptionPricing__c = commonSubscriptionPricing, SBQQ__SubscriptionTerm__c = commonSubscriptionTerm, SBQQ__SubscriptionBase__c = commonSubscriptionBase, SBQQ__SubscriptionType__c = 'Renewable'),
                    new Product2(Name = 'RBK-RADAR-CONS1',MSP_Std_Actual__c = Null,Product_Type__c = Constants.PROD_PRODUCT_TYPE_MSP, Family = Constants.PROD_SUB_TYPE_SCALE_MSP,ProductCode = 'RBK-RADAR-CONS1', Category__c = 'Support', SBQQ__AssetAmendmentBehavior__c = 'Default', SBQQSC__EntitlementConversion__c = EntitlementConversionOnePerUnit, IsActive = isActive, CPQ_MSP_Base_Price__c = 0.02, SBQQ__SubscriptionPricing__c = commonSubscriptionPricing, SBQQ__SubscriptionTerm__c = commonSubscriptionTerm, SBQQ__SubscriptionBase__c = commonSubscriptionBase, SBQQ__SubscriptionType__c = 'Renewable'),
                    new Product2(Name='RBK-SVC-PREM-R344',ProductCode='RBK-PS-CNSLT-ONST', Family='DELL', Appliance_Model_HW__c = 'RBK-R6408E',isActive = true, Product_Type__c = '3rd Party Hardware', Allow_PSO_Task_Creation__c = true),
                    //new Product2(Name = 'RS-HW-SVC-PE-S1', ProductCode = 'RS-HW-SVC-PE-S1', Category__c = baseCategory, Family = 'Support', Product_Type__c = 'HW Support', SBQQSC__EntitlementConversion__c = 'One per unit', IsActive = isActive, Product_Level__c = 'Support', SBQQ__SubscriptionPricing__c = commonSubscriptionPricing, SBQQ__SubscriptionTerm__c = commonSubscriptionTerm, SBQQ__SubscriptionBase__c = commonSubscriptionBase, SBQQ__SubscriptionType__c = 'Renewable'),
                    //new Product2(Name = 'RS-BT-RCDM-T', ProductCode = 'RS-BT-RCDM-T', License_Category__c = 'On Prem', Category__c = 'Software', Product_Level__c = 'OnPrem', Family = 'OnPrem', SBQQSC__EntitlementConversion__c = EntitlementConversionOnePerUnit, SBQQ__SubscriptionPricing__c = commonSubscriptionPricing, SBQQ__SubscriptionTerm__c = 1, SBQQ__SubscriptionBase__c = commonSubscriptionBase, SBQQ__SubscriptionType__c = 'One-time', IsActive = isActive, Support_Type__c = 'Premium', New_CPQ_Product__c = false, GPL_Name__c = 'NetApp')
                    new Product2(Name = 'RS-BT-RCDM-T', ProductCode = 'RS-BT-RCDM-T', License_Category__c = 'On Prem', Category__c = 'Software', Product_Level__c = Constants.RSC_HYBRID_PRODUCT_LEVEL, Family = 'DELL', Product_Type__c = Constants.PROD_Product_Type_THIRD_PARTY_HARDWARE, Product_Subtype__c = Null, SBQQ__SubscriptionPricing__c = commonSubscriptionPricing, SBQQ__SubscriptionTerm__c = 1, SBQQ__SubscriptionBase__c = commonSubscriptionBase, SBQQ__SubscriptionType__c = 'One-time', IsActive = true, Support_Type__c = 'Premium', New_CPQ_Product__c = false, GPL_Name__c = 'NetApp')

                    };
                        
                        // Insert all products in a single DML statement
                        insert sampleProducts;
            
            List<PricebookEntry>entries = new List<PricebookEntry>();
            
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[0].Id, IsActive = true, UnitPrice = 100));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[1].Id, IsActive = true, UnitPrice = 200));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[2].Id, IsActive = true, UnitPrice = 300));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[3].Id, IsActive = true, UnitPrice = 400));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[4].Id, IsActive = true, UnitPrice = 400));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[5].Id, IsActive = true, UnitPrice = 100));
            
            
            insert entries;          
            Asset assestIns = new Asset();
            assestIns.Name = '09092019APMSP1250';
            assestIns.SerialNumber = '09092019APMSP1250';
            assestIns.serial_number__c= '09092019APMSP1250';
            assestIns.AccountId = customer.Id;
            assestIns.Product2Id = sampleProducts[0].Id;
            insert assestIns;
            List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
            lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quotes[0].Id, SBQQ__Product__c = sampleProducts[1].Id, SBQQ__PricebookEntryId__c = entries[1].Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__Existing__c =true));
            lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quotes[0].Id, SBQQ__Product__c = sampleProducts[0].Id, SBQQ__PricebookEntryId__c = entries[0].Id, SBQQ__Quantity__c = 70, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
            lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quotes[0].Id, SBQQ__Product__c = sampleProducts[2].Id, SBQQ__PricebookEntryId__c = entries[2].Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
            lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quotes[0].Id, SBQQ__Product__c = sampleProducts[3].Id, SBQQ__PricebookEntryId__c = entries[3].Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
            lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quotes[0].Id, SBQQ__Product__c = sampleProducts[4].Id, SBQQ__PricebookEntryId__c = entries[4].Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 1, SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
            lines.add(new SBQQ__QuoteLine__c( SBQQ__Quote__c = quotes[0].Id, SBQQ__Product__c = sampleProducts[5].Id, SBQQ__PricebookEntryId__c = entries[5].Id, SBQQ__Quantity__c = 42, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today().addMonths(4).addDays(-6), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
            
            insert lines;
            
            lines[0].SBQQ__Bundle__c = true;
            lines[1].SBQQ__RequiredBy__c = lines[0].Id;
            lines[2].SBQQ__RequiredBy__c = lines[1].Id;
            lines[3].SBQQ__RequiredBy__c = lines[0].Id;
            lines[4].SBQQ__RequiredBy__c = lines[1].Id;
            lines[5].SBQQ__RequiredBy__c = lines[0].Id;
            
            update lines;
            
            quotes[0].ApprovalStatus__c = 'Approved';
            update quotes[0];
            
            POC__c pocobj = new POC__c();
            pocobj.POC_Duration__c = '60 Days';//30 Days
            pocobj.Planned_Installation_Date__c = date.today().addDays(90);
            pocobj.Support_Awareness_needed__c = 'Yes';
            pocobj.POC_Type__c= 'Conditional PO';
            pocobj.Product_Categories__c = 'Rubrik Appliance';
            
            insert pocobj;
            
            // Create and insert the first Order instance
            Order orderInstanceNew = new Order(
                AccountId = customer.Id,
                OpportunityId = opportunities[0].Id,
                EffectiveDate = System.today(),
                Status = 'Draft',
                Type = 'Revenue',
                Order_Status__c = 'Pending',
                Pricebook2Id = Test.getStandardPricebookId()
            );
            insert orderInstanceNew;
            
            // Clone and set fields for the second Order instance
            Order ordNew = orderInstanceNew.clone(false, true, false, false);
            ordNew.EffectiveDate = Date.newInstance(2023, 6, 2);
            ordNew.Order_Sub_Type__c = 'Renewal';
            // ordNew.SBQQ__Quote__c = quote2.Id; // Uncomment if needed
            
            // poc order
            Order ordNew1 = orderInstanceNew.clone(false, true, false, false);
            ordNew1.RecordTypeId = Constants.ORDER_RECORDTYPEID_POC_ORDER;
            ordNew1.Type = 'POC';
            ordNew1.EffectiveDate = Date.newInstance(2023, 6, 2);
            ordNew1.Order_Sub_Type__c = 'Renewal';
            ordNew1.POC_Request__c = pocobj.Id;
            
            
            // Insert all orders in a single DML statement
            insert new List<Order>{ordNew, ordNew1 };
                
                List<OrderItem> orderItemList = new List<OrderItem>{
                    new OrderItem(OrderId = orderInstanceNew.Id, Product2Id = sampleProducts[0].Id, SerialNumber__c = '09092019APMSP1250', UnitPrice = entries[0].UnitPrice, SBQQ__QuoteLine__c = lines[0].Id, SBQQ__SubscriptionTerm__c = 36, Quantity = 70, PricebookEntryId = entries[0].Id),
                        new OrderItem(OrderId = orderInstanceNew.Id, Product2Id = sampleProducts[1].Id, SerialNumber__c = '09092019APMSP1250', UnitPrice = entries[1].UnitPrice, SBQQ__QuoteLine__c = lines[1].Id, SBQQ__SubscriptionTerm__c = 36, Quantity = 1, PricebookEntryId = entries[1].Id),
                        new OrderItem(OrderId = orderInstanceNew.Id, Product2Id = sampleProducts[2].Id, UnitPrice = entries[2].UnitPrice, SBQQ__QuoteLine__c = lines[2].Id, SBQQ__SubscriptionTerm__c = 36, Quantity = 20, PricebookEntryId = entries[2].Id),
                        new OrderItem(OrderId = orderInstanceNew.Id, Product2Id = sampleProducts[3].Id, SBQQ__SegmentIndex__c = 1, SerialNumber__c = '09092019APMSP1250', UnitPrice = entries[3].UnitPrice, SBQQ__QuoteLine__c = lines[3].Id, SBQQ__SubscriptionTerm__c = 36, Quantity = 1, PricebookEntryId = entries[3].Id),
                        new OrderItem(OrderId = ordNew1.Id, Product2Id = sampleProducts[4].Id, UnitPrice = entries[4].UnitPrice, SBQQ__QuoteLine__c = lines[4].Id, SBQQ__SubscriptionTerm__c = 36, Quantity = 1, PricebookEntryId = entries[4].Id, Program__c = 'Replaced'),
                        new OrderItem(OrderId = ordNew1.Id, Product2Id = sampleProducts[5].Id, UnitPrice = entries[5].UnitPrice, SBQQ__QuoteLine__c = lines[5].Id, SBQQ__SubscriptionTerm__c = 36, Quantity = 70, PricebookEntryId = entries[5].Id)
                        };
                            insert orderItemList;
        }
    }
    
    @isTest
    public static void testCustomEntitlement(){
        
        List<Order> lstOrders = new List<Order>([SELECT Id, SC_or_Entitlement_Stage__c FROM Order]);
        System.runAs(new User(Id=UserInfo.getUserId())) {
        lstOrders[0].SC_or_Entitlement_Stage__c = CONSTANTS.SC_ENT_STAGE_CREATE_MANUFACTURING_ENT;
        update lstOrders;
        }
        //new CustomEntitlementGenerationHelper(lstOrders,lstOrders[0].SC_or_Entitlement_Stage__c);
        Test.startTest();
        System.enqueueJob(new CustomEntitlementGenerationQueueable(lstOrders, lstOrders[0].SC_or_Entitlement_Stage__c,Null));
        test.stopTest();
        List<Entitlement> EntitlementList= [Select id from Entitlement];
        system.assertEquals(true, EntitlementList.size()>0);
        
    }
    
    @isTest
    public static void testManufacturingEntitlement(){
        
        List<Order> lstOrders = new List<Order>([SELECT Id,POC_Request__c,SC_or_Entitlement_Stage__c FROM Order WHERE Type = 'POC']);
        System.runAs(new User(Id=UserInfo.getUserId())) {
        lstOrders[0].SC_or_Entitlement_Stage__c = CONSTANTS.SC_ENT_STAGE_CREATE_MANUFACTURING_ENT;
        
        update lstOrders;
        }
        //new CustomEntitlementGenerationHelper(lstOrders,lstOrders[0].SC_or_Entitlement_Stage__c);
        System.enqueueJob(new CustomEntitlementGenerationQueueable(lstOrders, lstOrders[0].SC_or_Entitlement_Stage__c,Null));
        
        //Test updatePOCExtensionDate
        lstOrders[0].SC_or_Entitlement_Stage__c = CONSTANTS.SC_ENT_STAGE_EXTEND_POC_ENT;
        update lstOrders;
        update new POC__C(Id = lstOrders[0].POC_Request__c, Approval_Status__c = 'Extension Approved',New_Expected_End_Date__c = date.today().addDays(200));
        //new CustomEntitlementGenerationHelper(lstOrders,lstOrders[0].SC_or_Entitlement_Stage__c);
        Test.startTest();
        System.enqueueJob(new CustomEntitlementGenerationQueueable(lstOrders, lstOrders[0].SC_or_Entitlement_Stage__c,Null));
        Test.stopTest();
        List<Entitlement> EntitlementList= [Select id from Entitlement]; 
        system.assertEquals(true, EntitlementList.size()>0);
    }  
    @isTest
    public static void testwithalreadyEntitlement(){
        insert new ShGl_DisableBusinessLogic__c(Disable_Entitlement_Validation_Rules__c=true, Disable_Order_Validation_Rules__c = true,Disable_POC_Validation_Rules__c = true, Disable_SBQQ_Quote_Triggers__c = true, Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =false ,Disable_Order_Email_Alerts__c = false, Disable_Order_Old_Trigger__c = true, Disable_Order_Triggers__c = false,Disable_Contact_Triggers__c =true, setupOwnerId = userinfo.getuserid(), Disable_POC_Trigger__c = true,Disable_SBQQ_Quote_Validation_Rules__c = true);
        Account customer = [select Id from account limit 1];
        List<Product2> sampleProducts = [select Id from Product2];
        List<Order> lstOrders = new List<Order>([SELECT Id,POC_Request__c,SC_or_Entitlement_Stage__c FROM Order WHERE Type = 'POC']);
        List<OrderItem> orderItemList = [select Id from orderItem where orderid =: lstOrders[0].id];
         System.runAs(new User(Id=UserInfo.getUserId())) {
        insert new Entitlement(Name = 'ENT-1', Type = 'Manufacturing Entitlement',Order_Service_Item__c=orderItemList[0].id, AccountId = customer.Id, StartDate = Date.valueof(System.now().addDays(-2)), EndDate = Date.valueof(System.now().addYears(2)),  Product__c = sampleProducts[0].Id);        
         }
        lstOrders[0].SC_or_Entitlement_Stage__c = CONSTANTS.SC_ENT_STAGE_CREATE_MANUFACTURING_ENT;
        update lstOrders;
        System.enqueueJob(new CustomEntitlementGenerationQueueable(lstOrders, lstOrders[0].SC_or_Entitlement_Stage__c,Null));
        lstOrders[0].SC_or_Entitlement_Stage__c = CONSTANTS.SC_ENT_STAGE_EXTEND_POC_ENT;
        update lstOrders;
        update new POC__C(Id = lstOrders[0].POC_Request__c, Approval_Status__c = 'Extension Approved',New_Expected_End_Date__c = date.today().addDays(200));
        System.enqueueJob(new CustomEntitlementGenerationQueueable(lstOrders, lstOrders[0].SC_or_Entitlement_Stage__c,Null));
        List<Entitlement> EntitlementList= [Select id from Entitlement];
        system.assertEquals(true, EntitlementList.size()>0);
    }   
}