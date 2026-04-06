@isTest
public class EntitlementLinkCreationClass_Test {
    
    @testSetup static void insertData() {
        String uniqueUserName = 'TestUser' + DateTime.now().getTime() + '@rbk.com';
        String uniqueUserName1 = 'TestUser1' + DateTime.now().getTime() + '@rbk.com';
        String uniqueUserName2 = 'TestUser2' + DateTime.now().getTime() + '@rbk.com';
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        
        User usr1 = new user(
            alias = 'std',
            email = 'testuser@testclass.com',
            emailencodingkey = 'UTF-8',
            firstname = 'test',
            lastname = 'user',
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            profileid = p.Id,
            timezonesidkey = 'America/Los_Angeles',
            username = uniqueUserName
        );
        User usr2 = new user(
            alias = 'std',
            email = 'testuser@testclass.com',
            emailencodingkey = 'UTF-8',
            firstname = 'test',
            lastname = 'user',
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            profileid = p.Id,
            timezonesidkey = 'America/Los_Angeles',
            username = uniqueUserName1
        );
        User usr3 = new user(
            alias = 'std',
            email = 'testuser@testclass.com',
            emailencodingkey = 'UTF-8',
            firstname = 'test',
            lastname = 'user',
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            profileid = p.Id,
            timezonesidkey = 'America/Los_Angeles',
            username = uniqueUserName2
        );
        List<User> ursList = New List<User>{usr1,usr2,usr3};
            insert ursList;
        System.runAs(usr1) {
            insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Disable_Account_Old_Trigger__c = TRUE);
            insert new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getUserId(), 
                                                    Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
                                                    Disable_SBQQ_Quote_Triggers__c = TRUE,
                                                    Disable_SBQQ_QuoteLine_Triggers__c=true,
                                                    Disable_Product2_Validation_Rules__c = true,
                                                    Disable_Order_Old_Trigger__c = true, Disable_OrderItem_Old_Trigger__c = true,
                                                    Disable_Opportunity_Triggers__c=true,Disable_Product2_Trigger__c=true,
                                                    Disable_SBQQ_QuoteLine_Validation_Rules__c =  true);
            TriggerControl.stopOrderItemTrigger = true;
            TriggerControl.stopOrderTrigger = true;
            TriggerControl__c objOrderTrigger = new TriggerControl__c(Name = 'Entitlement', Disable_Trigger__c = true, 
                                                                      DisableTrigger__c = true, SendEmail__c = false);
            insert objOrderTrigger;
            
            Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            Account customer = new Account(Name = 'Customer',recordtypeId = partner,Phone = '123-456-7890',AccountNumber = 'Test',BillingStreet = '123 street',BillingCity = 'Santa Clara',BillingState = 'California',BillingPostalCode = '95050',BillingCountry = 'United States',ShippingStreet = '123 street',ShippingCity = 'Santa Clara',ShippingState = 'California',ShippingPostalCode = '95050',ShippingCountry = 'United States');
            insert customer;
            
            //Contact cont = TestDataFactory.getContact(customer);
            //insert cont;
            
            Opportunity opp = TestDataFactory.getOpportunity();
            opp.Partner_Lookup__c = customer.Id;
            opp.AccountId = customer.Id;
            opp.Distributor_Lookup__c = opp.AccountId;
            //opp.Initial_Contacts_Name__c = cont.Id;
            opp.Pricebook2id = Test.getStandardPricebookId();
            insert opp;
            
            Opportunity opp1 = TestDataFactory.getOpportunity();
            opp1.Partner_Lookup__c = customer.Id;
            opp1.AccountId = customer.Id;
            opp1.Distributor_Lookup__c = opp.AccountId;
            //opp.Initial_Contacts_Name__c = cont.Id;
            opp1.Pricebook2id = Test.getStandardPricebookId();
            insert opp1;
            
            
            
            
            SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp.Id,SBQQ__SubscriptionTerm__c = 12,Is_RWD_Polaris_Quote__c = true,SBQQ__Primary__c = true,ApprovalStatus__c = 'Recalled',SBQQ__Type__c = 'Quote',SBQQ__PriceBook__c = Test.getStandardPricebookId());
            insert quote;
            
            SBQQ__Quote__c quote2 = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp1.Id,SBQQ__SubscriptionTerm__c = 12,Is_RWD_Polaris_Quote__c = true,SBQQ__Primary__c = true,ApprovalStatus__c = 'Recalled',SBQQ__Type__c = 'Renewal+Expansion',SBQQ__PriceBook__c = Test.getStandardPricebookId());
            insert quote2;
            
            List<Product2> sampleProducts = new List<Product2>{
                // 0
                new Product2(
                    Name = 'RS-BT-EE-PE-PP',
                    ProductCode = 'RS-BT-EE-PE-PP',
                    Category__c = 'Bundle',
                    Family = 'Rubrik Licence',
                    Product_Type__c = 'Enterprise Edition',
                    License_Category__c = 'SaaS',
                    Product_Level__c = 'Hybrid Software',
                    SBQQ__AssetAmendmentBehavior__c = 'Default',
                    SBQQSC__EntitlementConversion__c = 'One per quote line',
                    IsActive = true,
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 36,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable'
                ),
                    
                    // 1
                    new Product2(
                        Name = 'RBK-R6412-CONS',
                        ProductCode = 'RBK-R6412-CONS',
                        Category__c = 'Platform',
                        Family = 'r300',
                        Usable_Capacity__c= 1,
                        Product_Level__c ='Hardware',
                        Product_Type__c = 'Hardware',
                        Appliance_Model__c='RBK-R344',
                        Appliance_Model_HW__c = 'RBK-R344',
                        CPQ_MSP_Base_Price__c = 0.13,
                        SBQQSC__EntitlementConversion__c = 'None',
                        SBQQ__AssetAmendmentBehavior__c = 'Default',
                        IsActive = true,
                        Asset_Priority__c = 0,
                        MSP_Segment_Product__c = true,
                        SBQQ__SubscriptionPricing__c = 'Fixed Price',
                        SBQQ__SubscriptionTerm__c = 1,
                        SBQQ__SubscriptionBase__c = 'List',
                        SBQQ__SubscriptionType__c = 'Renewable'
                    ),
                    // 2
                    new Product2(
                        Name = 'RBK-RADAR-CONS',
                        ProductCode = 'RBK-RADAR-CONS',
                        Category__c = 'Support',
                        Product_Level__c ='Support',  
                        SBQQ__AssetAmendmentBehavior__c = 'Default',
                        SBQQSC__EntitlementConversion__c = 'One per quote line',
                        IsActive = true,
                        CPQ_MSP_Base_Price__c = 0.02,
                        SBQQ__SubscriptionPricing__c = 'Fixed Price',
                        SBQQ__SubscriptionTerm__c = 36,
                        SBQQ__SubscriptionBase__c = 'List',
                        SBQQ__SubscriptionType__c = 'Renewable'
                    ),
                    //3
                    new Product2(
                        Name = 'RBK-RADAR-CONS1',
                        ProductCode = 'RBK-RADAR-CONS1',
                        Category__c = 'Support',
                        SBQQ__AssetAmendmentBehavior__c = 'Default',
                        SBQQSC__EntitlementConversion__c = 'One per quote line',
                        IsActive = true,
                        CPQ_MSP_Base_Price__c = 0.02,
                        SBQQ__SubscriptionPricing__c = 'Fixed Price',
                        SBQQ__SubscriptionTerm__c = 36,
                        SBQQ__SubscriptionBase__c = 'List',
                        SBQQ__SubscriptionType__c = 'Renewable'
                    ), 
                    //4
                    new Product2(
                        Name = 'RS-HW-SVC-PE-S1',
                        ProductCode = 'RS-HW-SVC-PE-S1',
                        Category__c = 'Support',
                        Family = 'Support',
                        Product_Type__c = 'HW Support',
                        SBQQSC__EntitlementConversion__c = 'One per unit',
                        IsActive = true,
                        Product_Level__c = 'Support',
                        SBQQ__SubscriptionPricing__c = 'Fixed Price',
                        SBQQ__SubscriptionTerm__c = 36,
                        SBQQ__SubscriptionBase__c = 'List',
                        SBQQ__SubscriptionType__c = 'Renewable'
                    ),
                    //5
                    new Product2(
                        Name = 'RS-BT-RCDM-T',
                        ProductCode = 'RS-BT-RCDM-T',
                        License_Category__c = 'On Prem',
                        Category__c = 'Software',
                        Product_Level__c = 'OnPrem',
                        Family = 'OnPrem',
                        SBQQSC__EntitlementConversion__c = 'One per quote line',
                        SBQQ__SubscriptionPricing__c = 'Fixed Price',
                        SBQQ__SubscriptionTerm__c = 1,
                        SBQQ__SubscriptionBase__c = 'List',
                        SBQQ__SubscriptionType__c = 'One-time',
                        IsActive = true,
                        Support_Type__c = 'Premium',
                        New_CPQ_Product__c = false,
                        GPL_Name__c = 'NetApp'
                    ),
                    //6
                    new Product2(
                        Name = 'RH-6408S-01',
                        ProductCode = 'RH-6408S-01',
                        Category__c = 'Hardware',
                        Family = 'R6000',
                        Usable_Capacity__c= 60,
                        Product_Level__c ='Hardware',
                        Product_Type__c = 'Hardware',
                        Appliance_Model__c='RBK-R6408S',
                        Appliance_Model_HW__c = 'RBK-R6408S',
                        SBQQSC__EntitlementConversion__c = 'None',
                        SBQQ__AssetAmendmentBehavior__c = 'Default',
                        IsActive = true,
                        MSP_Segment_Product__c = true,
                        SBQQ__SubscriptionBase__c = 'List'
                    ),
                    //7
                    
                    new Product2(Name='RS-UR-FE-MD-PE-PP',ProductCode ='RS-UR-FE-MD-PE-PP',
                                 License_Category__c = 'Subscriptions',
                                 Category__c = 'SaaS',
                                 Product_Level__c = 'SaaS Software Addon',
                                 Product_Type__c = 'M365H',
                                 Family = 'POLARIS',
                                 SBQQSC__EntitlementConversion__c = 'One per quote line',
                                 SBQQ__SubscriptionPricing__c = 'Fixed Price',
                                 SBQQ__SubscriptionTerm__c = 1,
                                 SBQQ__SubscriptionBase__c = 'List',
                                 SBQQ__SubscriptionType__c = 'Renewable',
                                 IsActive = true,
                                 Support_Type__c = 'Premium'),
                    //8
                    new Product2(Name='RS-UR-M365-PE-PP',ProductCode ='RS-UR-M365-PE-PP',
                                 License_Category__c = 'Subscriptions',
                                 Category__c = 'SaaS',
                                 Product_Level__c = 'Standalone Software Addon',
                                 Product_Type__c = 'Hybrid M365H',
                                 Family = 'POLARIS',
                                 SBQQSC__EntitlementConversion__c = 'One per quote line',
                                 SBQQ__SubscriptionPricing__c = 'Fixed Price',
                                 SBQQ__SubscriptionTerm__c = 1,
                                 SBQQ__SubscriptionBase__c = 'List',
                                 SBQQ__SubscriptionType__c = 'Renewable',
                                 IsActive = true,
                                 Support_Type__c = 'Premium'),
                    
                    
                    //9
                    new Product2(Name='RS-TB-EE-RSV-PE',ProductCode ='RS-TB-EE-RSV-PE',
                                 Support_Type__c='Premium',Product_Level__c='Hybrid Software',License_Type__c='Consumption',
                                 Product_Type__c='Enterprise Edition',Product_Subtype__c='Scale MSP',
                                 Product_Payment_Option__c='Monthly',Approval_Category__c='Scale Utility RSV',
                                 SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__SubscriptionType__c='Renewable',
                                 SBQQSC__EntitlementConversion__c='One per quote line',SBQQ__AssetAmendmentBehavior__c='Default'),
                     //10
                    new Product2(
                        Name = 'RBK-HW-CONS1',
                        ProductCode = 'RBK-Hw-CONS1',
                        Category__c = 'Support',
                        SBQQ__AssetAmendmentBehavior__c = 'Default',
                        SBQQSC__EntitlementConversion__c = 'One per unit',
                        IsActive = true,
                        Product_Type__c = '3rd Party Hardware',
                        CPQ_MSP_Base_Price__c = 0.02,
                        SBQQ__SubscriptionPricing__c = 'Fixed Price',
                        SBQQ__SubscriptionTerm__c = 36,
                        SBQQ__SubscriptionBase__c = 'List',
                        SBQQ__SubscriptionType__c = 'Renewable'
                    ),
                     //11
                    new Product2(
                        Name = 'RBK-HW-Addon',
                        ProductCode = 'RBK-Hw-Addon',
                        Category__c = 'Support',
                        SBQQ__AssetAmendmentBehavior__c = 'Default',
                        SBQQSC__EntitlementConversion__c = 'One per unit',
                        IsActive = true,
						Product_Level__c = 'Standalone Software Addon',
                        CPQ_MSP_Base_Price__c = 0.02,
                        SBQQ__SubscriptionPricing__c = 'Fixed Price',
                        SBQQ__SubscriptionTerm__c = 36,
                        SBQQ__SubscriptionBase__c = 'List',
                        SBQQ__SubscriptionType__c = 'Renewable'
                    )

                    
                    };
                        insert sampleProducts;
            system.debug('sampleProducts***'+sampleProducts);
            system.debug('sample3***'+sampleProducts[3]);
            List<PricebookEntry>entries = new List<PricebookEntry>();
            
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[0].Id, IsActive = true, UnitPrice = 100));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[1].Id, IsActive = true, UnitPrice = 200));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[2].Id, IsActive = true, UnitPrice = 300));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[3].Id, IsActive = true, UnitPrice = 400));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[4].Id, IsActive = true, UnitPrice = 400));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[5].Id, IsActive = true, UnitPrice = 100));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[6].Id, IsActive = true, UnitPrice = 100));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[7].Id, IsActive = true, UnitPrice = 100));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[8].Id, IsActive = true, UnitPrice = 100));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[9].Id, IsActive = true, UnitPrice = 100));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[10].Id, IsActive = true, UnitPrice = 100));
			entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[11].Id, IsActive = true, UnitPrice = 100));
            insert entries;
            system.debug('entries****'+entries);
            
            Asset assestIns = new Asset();
            assestIns.Name = '09092019APMSP1250';
            assestIns.SerialNumber = '09092019APMSP1250';
            assestIns.serial_number__c= '09092019APMSP1250';
            assestIns.AccountId = customer.Id;
            assestIns.Product2Id = sampleProducts[0].Id;
            insert assestIns;
            List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
            lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[0].Id, SBQQ__PricebookEntryId__c = entries[0].Id, SBQQ__Quantity__c = 70, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
            lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[1].Id, SBQQ__PricebookEntryId__c = entries[1].Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__Existing__c =true));
            lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[2].Id, SBQQ__PricebookEntryId__c = entries[2].Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
            lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[3].Id, SBQQ__PricebookEntryId__c = entries[3].Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
            lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[4].Id, SBQQ__PricebookEntryId__c = entries[4].Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 1, SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
            lines.add(new SBQQ__QuoteLine__c( SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[5].Id, SBQQ__PricebookEntryId__c = entries[5].Id, SBQQ__Quantity__c = 42, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today().addMonths(4).addDays(-6), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
            lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[6].Id, SBQQ__PricebookEntryId__c = entries[6].Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__Existing__c =true));
            lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[7].Id, SBQQ__PricebookEntryId__c = entries[7].Id,SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
            lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[8].Id, SBQQ__PricebookEntryId__c = entries[8].Id,SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__Optional__c= true, Disposition_Reason__c = 'Replaced'));
            lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[9].Id, SBQQ__PricebookEntryId__c = entries[9].Id,SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
            lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[10].Id, SBQQ__PricebookEntryId__c = entries[10].Id,SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
          	lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[10].Id, SBQQ__PricebookEntryId__c = entries[10].Id,SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
          	lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[11].Id, SBQQ__PricebookEntryId__c = entries[11].Id,SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));


            insert lines;
            
            lines[0].SBQQ__Bundle__c = true;
            lines[1].SBQQ__RequiredBy__c = lines[0].Id;
            lines[2].SBQQ__RequiredBy__c = lines[1].Id;
            lines[3].SBQQ__RequiredBy__c = lines[0].Id;
            lines[4].SBQQ__RequiredBy__c = lines[1].Id;
            lines[5].SBQQ__RequiredBy__c = lines[0].Id;
            lines[10].SBQQ__RequiredBy__c = lines[1].Id;
            lines[11].SBQQ__RequiredBy__c = lines[1].Id;
            lines[12].SBQQ__RequiredBy__c = lines[1].Id;
   
            update lines;
            
            quote.ApprovalStatus__c = 'Approved';
            update quote;
            
            Order orderInstanceNew = new Order();
            orderInstanceNew.AccountId = customer.Id;
            orderInstanceNew.OpportunityId = opp.Id;
            orderInstanceNew.EffectiveDate = system.today();  
            orderInstanceNew.Status = 'Draft';
            orderInstanceNew.Type = 'Revenue';
            orderInstanceNew.Order_Status__c = 'Pending'; 
            orderInstanceNew.Status='Draft';
            //orderInstanceNew.Program__c = 'Refresh';
            orderInstanceNew.Pricebook2Id = Test.getStandardPricebookId(); 
            insert orderInstanceNew;
            Order ordNew=orderInstanceNew.clone();
            ordNew.EffectiveDate=Date.newInstance(2023,06,02);  
            ordNew.Order_Sub_Type__c='Renewal';
            //ordNew.SBQQ__Quote__c=quote2.Id;
            insert ordNew;
            Order ordNew1=orderInstanceNew.clone();
            ordNew1.EffectiveDate=Date.newInstance(2023,06,02);  
            ordNew1.Order_Sub_Type__c='Renewal';
            //  ordNew1.SBQQ__Quote__c=quote2.Id;
            insert ordNew1;
            
            List<OrderItem> orderItemList = new List<OrderItem>{
                new OrderItem(OrderId = orderInstanceNew.Id, Product2Id = sampleProducts[0].Id, SerialNumber__c = '09092019APMSP1250', UnitPrice= entries[0].UnitPrice, SBQQ__QuoteLine__c = lines[0].Id, SBQQ__SubscriptionTerm__c = 36, Quantity = 70, PricebookEntryId =  entries[0].Id),
                    new OrderItem(OrderId = orderInstanceNew.Id, Product2Id = sampleProducts[4].Id, SerialNumber__c = '09092019APMSP1250', UnitPrice= entries[4].UnitPrice, SBQQ__QuoteLine__c = lines[4].Id, SBQQ__SubscriptionTerm__c = 36, Quantity = 1, PricebookEntryId =  entries[4].Id),
                    new OrderItem(OrderId = orderInstanceNew.Id, Product2Id = sampleProducts[5].Id, UnitPrice= entries[5].UnitPrice, SBQQ__QuoteLine__c = lines[5].Id, SBQQ__SubscriptionTerm__c = 36, Quantity = 20, PricebookEntryId =  entries[5].Id),
                    new OrderItem(OrderId = orderInstanceNew.Id, Product2Id = sampleProducts[6].Id, SerialNumber__c = '09092019APMSP1250', UnitPrice= entries[6].UnitPrice, SBQQ__QuoteLine__c = lines[6].Id, SBQQ__SubscriptionTerm__c = 36, Quantity = 1, PricebookEntryId =  entries[6].Id),
                    new OrderItem(OrderId = orderInstanceNew.Id, Product2Id = sampleProducts[7].Id,  UnitPrice= entries[7].UnitPrice, SBQQ__QuoteLine__c = lines[7].Id, SBQQ__SubscriptionTerm__c = 36, Quantity = 1, PricebookEntryId =  entries[6].Id, Program__c = 'Replaced'),
                    new OrderItem(OrderId = orderInstanceNew.Id, Product2Id = sampleProducts[2].Id, UnitPrice= entries[2].UnitPrice, SBQQ__QuoteLine__c = lines[2].Id, SBQQ__SubscriptionTerm__c = 36, Quantity = 70, PricebookEntryId =  entries[2].Id),
                    new OrderItem(OrderId = orderInstanceNew.Id, Product2Id = sampleProducts[10].Id, UnitPrice= entries[10].UnitPrice, SBQQ__QuoteLine__c = lines[10].Id, SBQQ__SubscriptionTerm__c = 36, Quantity = 70, PricebookEntryId =  entries[10].Id),
                    new OrderItem(OrderId = orderInstanceNew.Id, Product2Id = sampleProducts[10].Id, UnitPrice= entries[10].UnitPrice, SBQQ__QuoteLine__c = lines[11].Id, SBQQ__SubscriptionTerm__c = 36, Quantity = 70, PricebookEntryId =  entries[10].Id),
                    new OrderItem(OrderId = orderInstanceNew.Id, Product2Id = sampleProducts[11].Id, UnitPrice= entries[10].UnitPrice, SBQQ__QuoteLine__c = lines[12].Id, SBQQ__SubscriptionTerm__c = 36, Quantity = 70, PricebookEntryId =  entries[11].Id)

                    };
                        
                        Test.startTest();
            /*
* 0-License, 1-Hw Support, 2-RCDM, 3-HW, 6- v1 sku
* ***/
            insert orderItemList;
            
            ServiceContract objSC = new ServiceContract(Name = 'ServiceContractTest1', AccountId = customer.Id, StartDate = Date.today(),
                                                        Term = 36, pricebook2Id = Test.getStandardPricebookId(), SBQQSC__Opportunity__c = opp.Id, SBQQSC__Order__c= orderInstanceNew.Id,  SBQQSC__Quote__c = quote.Id);
            
            insert objSC;
            List<ContractLineItem> lstCli = new List<ContractLineItem>{
                new ContractLineItem(SBQQSC__OrderProduct__c = orderItemList[0].Id,Quantity = orderItemList[0].quantity, SBQQSC__QuoteLine__c = orderItemList[0].SBQQ__QuoteLine__c,SBQQSC__Product__c = orderItemList[0].Product2Id, PricebookEntryId = orderItemList[0].PricebookEntryId,  ServiceContractId= objSC.Id, UnitPrice= orderItemList[0].UnitPrice, StartDate = date.today()),
                    new ContractLineItem(SBQQSC__OrderProduct__c = orderItemList[1].Id,Quantity = orderItemList[1].quantity, SBQQSC__QuoteLine__c = orderItemList[1].SBQQ__QuoteLine__c,SBQQSC__Product__c = orderItemList[1].Product2Id, PricebookEntryId = orderItemList[1].PricebookEntryId,  ServiceContractId= objSC.Id, UnitPrice= orderItemList[1].UnitPrice, StartDate = date.today()),
                    new ContractLineItem(SBQQSC__OrderProduct__c = orderItemList[2].Id,Quantity = orderItemList[2].quantity, SBQQSC__QuoteLine__c= orderItemList[2].SBQQ__QuoteLine__c,SBQQSC__Product__c = orderItemList[2].Product2Id,PricebookEntryId = orderItemList[2].PricebookEntryId,  ServiceContractId= objSC.Id, UnitPrice= orderItemList[2].UnitPrice, StartDate = date.today()),
                    new ContractLineItem(SBQQSC__OrderProduct__c = orderItemList[5].Id,Quantity = orderItemList[5].quantity, SBQQSC__QuoteLine__c= orderItemList[5].SBQQ__QuoteLine__c,SBQQSC__Product__c = orderItemList[5].Product2Id,PricebookEntryId = orderItemList[5].PricebookEntryId,  ServiceContractId= objSC.Id, UnitPrice= orderItemList[5].UnitPrice, StartDate = date.today()),
					new ContractLineItem(SBQQSC__OrderProduct__c = orderItemList[6].Id,Quantity = orderItemList[6].quantity, SBQQSC__QuoteLine__c= orderItemList[6].SBQQ__QuoteLine__c,SBQQSC__Product__c = orderItemList[6].Product2Id,PricebookEntryId = orderItemList[6].PricebookEntryId,  ServiceContractId= objSC.Id, UnitPrice= orderItemList[6].UnitPrice, StartDate = date.today()),
					new ContractLineItem(SBQQSC__OrderProduct__c = orderItemList[7].Id,Quantity = orderItemList[7].quantity, SBQQSC__QuoteLine__c= orderItemList[7].SBQQ__QuoteLine__c,SBQQSC__Product__c = orderItemList[7].Product2Id,PricebookEntryId = orderItemList[7].PricebookEntryId,  ServiceContractId= objSC.Id, UnitPrice= orderItemList[7].UnitPrice, StartDate = date.today()),
					new ContractLineItem(SBQQSC__OrderProduct__c = orderItemList[8].Id,Quantity = orderItemList[8].quantity, SBQQSC__QuoteLine__c= orderItemList[8].SBQQ__QuoteLine__c,SBQQSC__Product__c = orderItemList[8].Product2Id,PricebookEntryId = orderItemList[8].PricebookEntryId,  ServiceContractId= objSC.Id, UnitPrice= orderItemList[8].UnitPrice, StartDate = date.today())
                    }; 
                        
                        insert lstCli;
            orderItemList[0].SBQQSC__ContractLineItem__c = lstCli[0].Id;
            orderItemList[1].SBQQSC__ContractLineItem__c = lstCli[1].Id;
            orderItemList[2].SBQQSC__ContractLineItem__c = lstCli[2].Id;
            orderItemList[5].SBQQSC__ContractLineItem__c = lstCli[3].Id;
            orderItemList[6].SBQQSC__ContractLineItem__c = lstCli[4].Id;
            orderItemList[7].SBQQSC__ContractLineItem__c = lstCli[5].Id;
            orderItemList[8].SBQQSC__ContractLineItem__c = lstCli[6].Id;




            orderItemList[2].SBQQ__RequiredBy__c = orderItemList[0].Id;
            
            update orderItemList;
            Test.stopTest();
            Id supportRecordTypeId = Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Support').getRecordTypeId();
            
            List<Entitlement> lstEntitlement = new List<Entitlement> {
                
                new Entitlement(Name = 'Ent Test 1' , RecordTypeId = supportRecordTypeId , Type= 'Phone Support', AccountId= customer.Id, Product__c   = sampleProducts[0].Id, 
                                StartDate= date.today(), ServiceContractId = objSC.Id, ContractLineItemId = lstCli[0].Id, Order_Service_Item__c=orderItemList[0].id),
                    new Entitlement(Name = 'Ent Test 2' , RecordTypeId = supportRecordTypeId , Type= 'Phone Support', AccountId= customer.Id, Product__c = sampleProducts[4].Id, 
                                    StartDate= date.today(), AssetId = assestIns.Id, ServiceContractId= objSC.Id, ContractLineItemId = lstCli[1].Id, Order_Service_Item__c=orderItemList[1].Id),
                    new Entitlement(Name = sampleProducts[5].ProductCode , RecordTypeId = supportRecordTypeId , Type= 'Phone Support', AccountId= customer.Id, Product__c = sampleProducts[5].Id, 
                                    StartDate= date.today(), ServiceContractId = objSC.Id, ContractLineItemId = lstCli[2].Id, Order_Service_Item__c=orderItemList[2].Id),
                    new Entitlement(Name = sampleProducts[2].ProductCode , RecordTypeId = supportRecordTypeId , Type= 'Phone Support', AccountId= customer.Id, Product__c = sampleProducts[2].Id, 
                                    StartDate= date.today(), ServiceContractId = objSC.Id, ContractLineItemId = lstCli[3].Id, Order_Service_Item__c=orderItemList[5].Id),
                     new Entitlement(Name = sampleProducts[10].ProductCode , RecordTypeId = supportRecordTypeId , Type= 'Phone Support', AccountId= customer.Id, Product__c = sampleProducts[10].Id, 
                                    StartDate= date.today(), ServiceContractId = objSC.Id, AssetId = assestIns.Id, ContractLineItemId = lstCli[4].Id, Order_Service_Item__c=orderItemList[6].Id),
                    new Entitlement(Name = sampleProducts[10].ProductCode , RecordTypeId = supportRecordTypeId , Type= 'Phone Support', AccountId= customer.Id, Product__c = sampleProducts[11].Id, 
                                    StartDate= date.today(), ServiceContractId = objSC.Id, ContractLineItemId = lstCli[5].Id, Order_Service_Item__c=orderItemList[7].Id),
                    new Entitlement(Name = sampleProducts[11].ProductCode , RecordTypeId = supportRecordTypeId , Type= 'Phone Support', AccountId= customer.Id, Product__c = sampleProducts[11].Id, 
                                    StartDate= date.today(), ServiceContractId = objSC.Id, ContractLineItemId = lstCli[6].Id, Order_Service_Item__c=orderItemList[8].Id)
                    
                    
                    };
                        insert lstEntitlement; 
            system.debug('::lstEntitlement::'+lstEntitlement); 
        }
    }
    
    @isTest
    static void v1AndV2Method(){
        List<user> usr = [Select Id from User Where email = 'testuser@testclass.com'];
        System.runAs(usr[1]) {
            
            //  insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Disable_Account_Old_Trigger__c = TRUE);
            insert new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getUserId(), 
                                                    Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
                                                    Disable_SBQQ_Quote_Triggers__c = TRUE,
                                                    Disable_Product2_Validation_Rules__c = true,
                                                    Disable_SBQQ_QuoteLine_Triggers__c=true,
                                                    Disable_Order_Old_Trigger__c = true, Disable_OrderItem_Old_Trigger__c = true,
                                                    Disable_Opportunity_Triggers__c=true,
                                                    Disable_SBQQ_QuoteLine_Validation_Rules__c =  true);
            TriggerControl.stopOrderItemTrigger = true;
            TriggerControl.stopOrderTrigger = true;
            
            Test.startTest();
    		List<Order> lstOrder = [SELECT Id FROM Order Limit 1];
            lstOrder[0].Is_RWD_Polaris_Quote__c = false;
            update lstOrder;
            
            List<Account> lstAccount1 = [SELECT Id FROM Account LIMIT 1];
            List<Asset> lstAsset = [SELECT Id, SerialNumber FROM Asset Where SerialNumber = '09092019APMSP1250'];
            Opportunity opp3 = TestDataFactory.getOpportunity();
            opp3.Partner_Lookup__c = lstAccount1[0].Id;
            opp3.AccountId = lstAccount1[0].Id;
            opp3.Distributor_Lookup__c = opp3.AccountId;
            opp3.Pricebook2id = Test.getStandardPricebookId();
            insert opp3;
            
            SBQQ__Quote__c quoteObjNew = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp3.Id,SBQQ__SubscriptionTerm__c = 12,Is_RWD_Polaris_Quote__c = true,SBQQ__Primary__c = true,ApprovalStatus__c = 'Recalled',SBQQ__Type__c = 'Renewal+Expansion',SBQQ__PriceBook__c = Test.getStandardPricebookId());
            insert quoteObjNew;
            List<Product2> sampleProducts2 = [SELECT Id, ProductCode FROM Product2 LIMIT 12];
            List<PricebookEntry> entries = [SELECT Id, UnitPrice FROM PricebookEntry LIMIT 12];
            List<SBQQ__QuoteLine__c>lines10 = new List<SBQQ__QuoteLine__c>();
            lines10.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteObjNew.Id, SBQQ__Product__c = sampleProducts2[0].Id, SBQQ__PricebookEntryId__c = entries[0].Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 70, SBQQ__Segmentindex__c  =1,  SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200,Disposition_Reason__c='Renewing',Special_Program__c='Conversion'));
            
            insert lines10;
            List<ContractLineItem> lstContractLineItems  = [SELECT Id FROM ContractLineItem Limit 7]; 
            lines10[0].SBQQ__Bundle__c = true;
            lines10[0].Arroyo_Subscribed_Asset_Name__c = lstAsset[0].SerialNumber;
            lines10[0].Disposition_Reason__c = 'Converted';
            lines10[0].Arroyo_Subsumed_Old_Contract_Line_Items__c = lstContractLineItems[0].Id;
            update lines10;
            
            quoteObjNew.ApprovalStatus__c = 'Approved';
            update quoteObjNew;
            
            Order orderInstance1 = new Order();
            orderInstance1.AccountId = lstAccount1[0].Id;
            orderInstance1.OpportunityId = opp3.Id;
            orderInstance1.EffectiveDate = system.today();  
            orderInstance1.Status = 'Draft';
            orderInstance1.Type = 'Revenue';
            orderInstance1.Order_Status__c = 'Pending'; 
            //orderInstance1.Program__c = 'Conversion';
            
            orderInstance1.Order_Sub_type__c = 'Renewal';
            orderInstance1.Pricebook2Id = Test.getStandardPricebookId(); 
            insert orderInstance1;
            
            List<OrderItem> orderItemList = new List<OrderItem>{
                new OrderItem(OrderId = orderInstance1.Id, Previous_Contract_Line_Items__c = lstContractLineItems[0].Id, Product2Id = sampleProducts2[0].Id, UnitPrice= entries[0].UnitPrice, SBQQ__QuoteLine__c = lines10[0].Id, SBQQ__SubscriptionTerm__c = 36, SBQQ__Segmentindex__c = 2, Support_Start_Date__c = System.today(), Program__c = 'Conversion' ,Quantity = 20, PricebookEntryId =  entries[0].Id)
                    };
            insert orderItemList;
            
            List<String> lstOldCliIds = new List<String>{lstContractLineItems[0].Id};
                
                
                ServiceContract objSC = new ServiceContract(Name = 'ServiceContractTest4', AccountId = lstAccount1[0].Id, StartDate = Date.today(),
                                                            Term = 36, pricebook2Id = Test.getStandardPricebookId(), SBQQSC__Opportunity__c = opp3.Id, SBQQSC__Order__c= orderInstance1.Id,  SBQQSC__Quote__c = quoteObjNew.Id);
            
            insert objSC;
            
              ContractLineItem inserCLI =  new ContractLineItem(Quantity = orderItemList[0].quantity, PricebookEntryId = orderItemList[0].PricebookEntryId,  ServiceContractId= objSC.Id, UnitPrice= orderItemList[0].UnitPrice, StartDate = date.today());

            insert inserCLI;
            
            orderItemList[0].SBQQSC__ContractLineItem__c = inserCLI.Id;
            update orderItemList;
            Id supportRecordTypeId = Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Support').getRecordTypeId();
 Entitlement insertent = new Entitlement(Name = sampleProducts2[4].ProductCode , RecordTypeId = supportRecordTypeId , Type= 'Phone Support', AccountId= lstAccount1[0].Id, Product__c = sampleProducts2[4].Id, 
                                StartDate= date.today(), ServiceContractId= objSC.Id, ContractLineItemId = inserCLI.Id, Order_Service_Item__c=orderItemList[0].id);
							insert	insertent;
            
            List<String> lstNewEntitlementIds = new List<String>{insertent.Id};
							  orderInstance1.SBQQ__Contracted__c = false;
            orderInstance1.Polaris_Fulfillment_Status__c = 'Completed';
            orderInstance1.Status = 'Activated';
            orderInstance1.Order_Status__c = 'Shipped';
            //orderInstance1.Program__c = 'Conversion';
            orderInstance1.SBQQ__Quote__c = quoteObjNew.Id;
            orderInstance1.Actual_Order_Ship_Date__c=System.today();
            orderInstance1.Welcome_letter_sent_for_the_first_time__c = true;
            
            update orderInstance1;
            EntitlementLinkCreationClass objClo = new EntitlementLinkCreationClass();
            objClo.createEntitlementLinks(lstOldCliIds, lstNewEntitlementIds );
            
            
            Test.stopTest();
        }
        
    }
    
    @isTest
    static void renewalConversionMethod(){
        
        List<user> usr = [Select Id from User Where email = 'testuser@testclass.com'];
        System.runAs(usr[1]) {
            
            //  insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Disable_Account_Old_Trigger__c = TRUE);
            insert new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getUserId(), 
                                                    Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
                                                    Disable_SBQQ_Quote_Triggers__c = TRUE,
                                                    Disable_Product2_Validation_Rules__c = true,
                                                    Disable_SBQQ_QuoteLine_Triggers__c=true,
                                                    Disable_Order_Old_Trigger__c = true, Disable_OrderItem_Old_Trigger__c = true,
                                                    Disable_Opportunity_Triggers__c=true,
                                                    Disable_SBQQ_QuoteLine_Validation_Rules__c =  true);
            TriggerControl.stopOrderItemTrigger = true;
            TriggerControl.stopOrderTrigger = true;
            
            Test.startTest();
            
            List<Account> lstAccount1 = [SELECT Id FROM Account LIMIT 1];
            List<Asset> lstAsset = [SELECT Id, SerialNumber FROM Asset Where SerialNumber = '09092019APMSP1250'];
            Opportunity opp3 = TestDataFactory.getOpportunity();
            opp3.Partner_Lookup__c = lstAccount1[0].Id;
            opp3.AccountId = lstAccount1[0].Id;
            opp3.Distributor_Lookup__c = opp3.AccountId;
            opp3.Pricebook2id = Test.getStandardPricebookId();
            insert opp3;
            
            SBQQ__Quote__c quoteObjNew = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp3.Id,SBQQ__SubscriptionTerm__c = 12,Is_RWD_Polaris_Quote__c = true,SBQQ__Primary__c = true,ApprovalStatus__c = 'Recalled',SBQQ__Type__c = 'Renewal+Expansion',SBQQ__PriceBook__c = Test.getStandardPricebookId());
            insert quoteObjNew;
            List<Product2> sampleProducts2 = [SELECT Id, ProductCode FROM Product2 LIMIT 12];
            List<PricebookEntry> entries = [SELECT Id, UnitPrice FROM PricebookEntry LIMIT 12];
            List<SBQQ__QuoteLine__c>lines10 = new List<SBQQ__QuoteLine__c>();
            lines10.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteObjNew.Id, SBQQ__Product__c = sampleProducts2[0].Id, SBQQ__PricebookEntryId__c = entries[0].Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 70, SBQQ__Segmentindex__c  =1,  SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200,Disposition_Reason__c='Renewing',Special_Program__c='Conversion'));
            lines10.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteObjNew.Id, SBQQ__Product__c = sampleProducts2[6].Id, SBQQ__PricebookEntryId__c = entries[6].Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 1, SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200,SBQQ__Existing__c =true));
            lines10.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteObjNew.Id, SBQQ__Product__c = sampleProducts2[4].Id, SBQQ__PricebookEntryId__c = entries[4].Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 1, SBQQ__Segmentindex__c  =1, SBQQ__Renewal__c= true, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200,Disposition_Reason__c='Renewing',Special_Program__c='Conversion'));
            lines10.add(new SBQQ__QuoteLine__c( SBQQ__Quote__c = quoteObjNew.Id, SBQQ__Product__c = sampleProducts2[5].Id, SBQQ__PricebookEntryId__c = entries[5].Id, SBQQ__Quantity__c = 42, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today().addMonths(4).addDays(-6), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
            insert lines10;
            List<ContractLineItem> lstContractLineItems  = [SELECT Id FROM ContractLineItem Limit 7]; 
            system.debug('::lstContractLineItems::'+lstContractLineItems.size());
            lines10[0].SBQQ__Bundle__c = true;
            lines10[0].Arroyo_Subscribed_Asset_Name__c = lstAsset[0].SerialNumber;
            lines10[0].Disposition_Reason__c = 'Converted';
            lines10[0].Arroyo_Subsumed_Old_Contract_Line_Items__c = lstContractLineItems[0].Id;
            lines10[1].SBQQ__RequiredBy__c = lines10[0].Id;   
            lines10[2].SBQQ__RequiredBy__c = lines10[1].Id;
            lines10[2].Arroyo_Subscribed_Asset_Name__c = lstAsset[0].SerialNumber;
            lines10[2].Disposition_Reason__c = 'Renewing';
            lines10[2].Arroyo_Subsumed_Old_Contract_Line_Items__c = lstContractLineItems[1].Id;
            lines10[3].SBQQ__RequiredBy__c = lines10[0].Id;
            
            update lines10;
            
            quoteObjNew.ApprovalStatus__c = 'Approved';
            update quoteObjNew;
            
            Order orderInstance1 = new Order();
            orderInstance1.AccountId = lstAccount1[0].Id;
            orderInstance1.OpportunityId = opp3.Id;
            orderInstance1.EffectiveDate = system.today();  
            orderInstance1.Status = 'Draft';
            orderInstance1.Type = 'Revenue';
            orderInstance1.Order_Status__c = 'Pending'; 
            //orderInstance1.Program__c = 'Conversion';
            
            orderInstance1.Order_Sub_type__c = 'Renewal';
            orderInstance1.Pricebook2Id = Test.getStandardPricebookId(); 
            insert orderInstance1;
            
            List<OrderItem> orderItemList = new List<OrderItem>{
                new OrderItem(OrderId = orderInstance1.Id, Previous_Contract_Line_Items__c = lstContractLineItems[0].Id+','+lstContractLineItems[4].Id, Product2Id = sampleProducts2[0].Id, Upgraded_From__c = '09092019APMSP1250', SerialNumber__c = '09092019APMSP1250', UnitPrice= entries[0].UnitPrice, SBQQ__QuoteLine__c = lines10[0].Id, SBQQ__SubscriptionTerm__c = 36, SBQQ__Segmentindex__c = 2, Support_Start_Date__c = System.today(), Program__c = 'Conversion' ,Quantity = 20, PricebookEntryId =  entries[0].Id),
               	new OrderItem(OrderId = orderInstance1.Id, Previous_Contract_Line_Items__c = lstContractLineItems[3].Id, Product2Id = sampleProducts2[4].Id, Upgraded_From__c = '09092019APMSP1250', SerialNumber__c = '09092019APMSP1250', UnitPrice= entries[4].UnitPrice, SBQQ__QuoteLine__c = lines10[2].Id, SBQQ__SubscriptionTerm__c = 36, SBQQ__Segmentindex__c = 2, Support_Start_Date__c = System.today(), Program__c = 'Conversion' ,Quantity = 20, PricebookEntryId =  entries[4].Id),
                new OrderItem(OrderId = orderInstance1.Id, TPH_Quantity__c	= '1' ,Previous_Contract_Line_Items__c = lstContractLineItems[5].Id, Product2Id = sampleProducts2[0].Id, UnitPrice= entries[0].UnitPrice, SBQQ__QuoteLine__c = lines10[0].Id, SBQQ__SubscriptionTerm__c = 36, SBQQ__Segmentindex__c = 2, Support_Start_Date__c = System.today(), Program__c = 'Conversion' ,Quantity = 20, PricebookEntryId =  entries[0].Id),
                new OrderItem(OrderId = orderInstance1.Id ,Previous_Contract_Line_Items__c = lstContractLineItems[6].Id, Product2Id = sampleProducts2[0].Id, UnitPrice= entries[0].UnitPrice, SBQQ__QuoteLine__c = lines10[0].Id, SBQQ__SubscriptionTerm__c = 36, SBQQ__Segmentindex__c = 2, Support_Start_Date__c = System.today(), Program__c = 'Conversion' ,Quantity = 20, PricebookEntryId =  entries[0].Id)

                };
           	insert orderItemList;  
            
            List<String> lstOldCliIds = new List<String>{lstContractLineItems[0].Id, lstContractLineItems[3].Id, lstContractLineItems[4].Id, lstContractLineItems[5].Id, lstContractLineItems[6].Id};
                
                
                ServiceContract objSC = new ServiceContract(Name = 'ServiceContractTest2', AccountId = lstAccount1[0].Id, StartDate = Date.today(),
                                                            Term = 36, pricebook2Id = Test.getStandardPricebookId(), SBQQSC__Opportunity__c = opp3.Id, SBQQSC__Order__c= orderInstance1.Id,  SBQQSC__Quote__c = quoteObjNew.Id);
            
            insert objSC;
            
            List<ContractLineItem> lstCli = new List<ContractLineItem>{
                new ContractLineItem(Quantity = orderItemList[0].quantity, PricebookEntryId = orderItemList[0].PricebookEntryId,  ServiceContractId= objSC.Id, UnitPrice= orderItemList[0].UnitPrice, StartDate = date.today()),
                 new ContractLineItem(Quantity = orderItemList[1].quantity, PricebookEntryId = orderItemList[1].PricebookEntryId,  ServiceContractId= objSC.Id, UnitPrice= orderItemList[1].UnitPrice, StartDate = date.today()),
                 new ContractLineItem(Quantity = orderItemList[2].quantity, PricebookEntryId = orderItemList[2].PricebookEntryId,  ServiceContractId= objSC.Id, UnitPrice= orderItemList[2].UnitPrice, StartDate = date.today()),
                 new ContractLineItem(Quantity = orderItemList[3].quantity, PricebookEntryId = orderItemList[3].PricebookEntryId,  ServiceContractId= objSC.Id, UnitPrice= orderItemList[3].UnitPrice, StartDate = date.today())

                    }; 
                        
                        insert lstCli;
            orderItemList[0].SBQQSC__ContractLineItem__c = lstCli[0].Id;
                        orderItemList[2].SBQQSC__ContractLineItem__c = lstCli[2].Id;

            
            update orderItemList;
            Id supportRecordTypeId = Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Support').getRecordTypeId();
            
            List<Entitlement> lstEntitlement1 = new List<Entitlement> {
                
                new Entitlement(Name = sampleProducts2[4].ProductCode , RecordTypeId = supportRecordTypeId , Type= 'Phone Support', AccountId= lstAccount1[0].Id, Product__c = sampleProducts2[0].Id, 
                                StartDate= date.today(), AssetId = lstAsset[0].Id, ServiceContractId= objSC.Id, ContractLineItemId = lstCli[0].Id, Order_Service_Item__c=orderItemList[0].id),
                                new Entitlement(Name = sampleProducts2[4].ProductCode , RecordTypeId = supportRecordTypeId , Type= 'Phone Support', AccountId= lstAccount1[0].Id, Product__c = sampleProducts2[4].Id, 
                                StartDate= date.today(), AssetId = lstAsset[0].Id, ServiceContractId= objSC.Id, ContractLineItemId = lstCli[1].Id, Order_Service_Item__c=orderItemList[1].id),
                    new Entitlement(Name = sampleProducts2[4].ProductCode , RecordTypeId = supportRecordTypeId , Type= 'Phone Support', AccountId= lstAccount1[0].Id, Product__c = sampleProducts2[4].Id, 
                                StartDate= date.today(), ServiceContractId= objSC.Id, ContractLineItemId = lstCli[2].Id, Order_Service_Item__c=orderItemList[2].id),
                    new Entitlement(Name = sampleProducts2[4].ProductCode , RecordTypeId = supportRecordTypeId , Type= 'Phone Support', AccountId= lstAccount1[0].Id, Product__c = sampleProducts2[4].Id, 
                                StartDate= date.today(), ServiceContractId= objSC.Id, ContractLineItemId = lstCli[3].Id, Order_Service_Item__c=orderItemList[3].id)
                
                
                
                    };
                        insert lstEntitlement1; 
            List<String> lstNewEntitlementIds = new List<String>();
            for(Entitlement ojEnt :lstEntitlement1){
                lstNewEntitlementIds.add(ojEnt.Id);
            }
            
            orderInstance1.SBQQ__Contracted__c = false;
            orderInstance1.Polaris_Fulfillment_Status__c = 'Completed';
            orderInstance1.Status = 'Activated';
            orderInstance1.Order_Status__c = 'Shipped';
            //orderInstance1.Program__c = 'Conversion';
            orderInstance1.SBQQ__Quote__c = quoteObjNew.Id;
            orderInstance1.Actual_Order_Ship_Date__c=System.today();
            orderInstance1.Welcome_letter_sent_for_the_first_time__c = true;
            
            update orderInstance1;
            EntitlementLinkCreationClass objClo = new EntitlementLinkCreationClass();
            objClo.createEntitlementLinks(lstOldCliIds, lstNewEntitlementIds );
            Test.stopTest();
            
        }
        
    }
    
    @isTest
    static void newConversionMethod(){
        List<user> usr2 = [Select Id from User Where email = 'testuser@testclass.com'];
        System.runAs(usr2[1]) {
            
            //  insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Disable_Account_Old_Trigger__c = TRUE);
            insert new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getUserId(), 
                                                    Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
                                                    Disable_SBQQ_Quote_Triggers__c = TRUE,
                                                    Disable_SBQQ_QuoteLine_Triggers__c=true,
                                                    Disable_Product2_Validation_Rules__c = true,
                                                    Disable_Order_Old_Trigger__c = true, Disable_OrderItem_Old_Trigger__c = true,
                                                    Disable_Opportunity_Triggers__c=true,
                                                    Disable_SBQQ_QuoteLine_Validation_Rules__c =  true);
            TriggerControl.stopOrderItemTrigger = true;
            TriggerControl.stopOrderTrigger = true;
            
            Test.startTest();
            
            List<Account> lstAccount2 = [SELECT Id FROM Account LIMIT 1];
            List<Asset> lstAsset = [SELECT Id, SerialNumber FROM Asset Where SerialNumber = '09092019APMSP1250'];
            Opportunity opp2 = TestDataFactory.getOpportunity();
            opp2.Partner_Lookup__c = lstAccount2[0].Id;
            opp2.AccountId = lstAccount2[0].Id;
            opp2.Distributor_Lookup__c = opp2.AccountId;
            opp2.Pricebook2id = Test.getStandardPricebookId();
            insert opp2;
            
            SBQQ__Quote__c quote2 = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp2.Id,SBQQ__SubscriptionTerm__c = 12,Is_RWD_Polaris_Quote__c = true,SBQQ__Primary__c = true,ApprovalStatus__c = 'Recalled',SBQQ__Type__c = 'Renewal+Expansion',SBQQ__PriceBook__c = Test.getStandardPricebookId());
            insert quote2;
            List<Product2> sampleProducts = [SELECT Id, ProductCode FROM Product2 LIMIT 8];
            List<PricebookEntry> entries = [SELECT Id, UnitPrice FROM PricebookEntry LIMIT 8];
            List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
            lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote2.Id, SBQQ__Product__c = sampleProducts[0].Id, SBQQ__PricebookEntryId__c = entries[0].Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 70, SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200,Disposition_Reason__c='Renewing',Special_Program__c='Conversion'));
            lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote2.Id, SBQQ__Product__c = sampleProducts[6].Id, SBQQ__PricebookEntryId__c = entries[6].Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 1, SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200,SBQQ__Existing__c =true));
            lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote2.Id, SBQQ__Product__c = sampleProducts[4].Id, SBQQ__PricebookEntryId__c = entries[4].Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 1, SBQQ__Segmentindex__c  =1, SBQQ__Renewal__c= true, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200,Disposition_Reason__c='Renewing',Special_Program__c='Conversion'));
            lines.add(new SBQQ__QuoteLine__c( SBQQ__Quote__c = quote2.Id, SBQQ__Product__c = sampleProducts[5].Id, SBQQ__PricebookEntryId__c = entries[5].Id, SBQQ__Quantity__c = 42, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today().addMonths(4).addDays(-6), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
            insert lines;
            List<ContractLineItem> lstContractLineItems  = [SELECT Id FROM ContractLineItem Limit 5];   
            lines[0].SBQQ__Bundle__c = true;
            lines[0].Arroyo_Subscribed_Asset_Name__c = lstAsset[0].SerialNumber;
            lines[0].Disposition_Reason__c = 'Converted';
            lines[0].Arroyo_Subsumed_Old_Contract_Line_Items__c = lstContractLineItems[0].Id;
            lines[1].SBQQ__RequiredBy__c = lines[0].Id;   
            lines[2].SBQQ__RequiredBy__c = lines[1].Id;
            lines[2].Arroyo_Subscribed_Asset_Name__c = lstAsset[0].SerialNumber;
            lines[2].Disposition_Reason__c = 'Converted';
            lines[2].Arroyo_Subsumed_Old_Contract_Line_Items__c = lstContractLineItems[1].Id;
            lines[3].SBQQ__RequiredBy__c = lines[0].Id;
            
            update lines;
            
            List<String> lstOldCliIds = new List<String>{lstContractLineItems[0].Id, lstContractLineItems[1].Id};
                
                quote2.ApprovalStatus__c = 'Approved';
            update quote2;
            
            Order orderInstanceObj = new Order();
            orderInstanceObj.AccountId = lstAccount2[0].Id;
            orderInstanceObj.OpportunityId = opp2.Id;
            orderInstanceObj.EffectiveDate = system.today();  
            orderInstanceObj.Status = 'Draft';
            orderInstanceObj.Type = 'Revenue';
            orderInstanceObj.Order_Status__c = 'Pending'; 
            orderInstanceObj.Pricebook2Id = Test.getStandardPricebookId(); 
            insert orderInstanceObj;
            
            List<OrderItem> orderItemList = new List<OrderItem>{
                new OrderItem(OrderId = orderInstanceObj.Id, Previous_Contract_Line_Items__c = lstContractLineItems[0].Id,Product2Id = sampleProducts[0].Id, SerialNumber__c = lstAsset[0].SerialNumber, UnitPrice= entries[0].UnitPrice, SBQQ__QuoteLine__c = lines[0].Id, SBQQ__SubscriptionTerm__c = 36, Quantity = 20, PricebookEntryId =  entries[0].Id, Program__c = 'Conversion', Support_Start_Date__c = System.today().addDays(2)),
                    new OrderItem(OrderId = orderInstanceObj.Id, Previous_Contract_Line_Items__c = lstContractLineItems[1].Id,Product2Id = sampleProducts[4].Id, SerialNumber__c = lstAsset[0].SerialNumber, UnitPrice= entries[4].UnitPrice, SBQQ__QuoteLine__c = lines[2].Id, SBQQ__SubscriptionTerm__c = 36, Quantity = 20, PricebookEntryId =  entries[4].Id, Program__c = 'Conversion', Support_Start_Date__c = System.today().addDays(2)),
                    new OrderItem(OrderId = orderInstanceObj.Id, Product2Id = sampleProducts[5].Id, UnitPrice= entries[5].UnitPrice, SBQQ__QuoteLine__c = lines[3].Id, SBQQ__SubscriptionTerm__c = 36, Quantity = 20, PricebookEntryId =  entries[5].Id, Support_Start_Date__c = System.today().addDays(20))    
                    };
                        insert orderItemList;  
            List<ServiceContract> lstSC = new List<ServiceContract>{new ServiceContract(Name = 'ServiceContractTest2', AccountId = lstAccount2[0].Id, StartDate = Date.today(),
                                                                                        Term = 36, pricebook2Id = Test.getStandardPricebookId(), SBQQSC__Opportunity__c = opp2.Id, SBQQSC__Order__c= orderInstanceObj.Id,  SBQQSC__Quote__c = quote2.Id),
                new ServiceContract(Name = 'ServiceContractTest3', AccountId = lstAccount2[0].Id, StartDate = Date.today(),
                                    Term = 36, pricebook2Id = Test.getStandardPricebookId(), SBQQSC__Opportunity__c = opp2.Id, SBQQSC__Order__c= orderInstanceObj.Id,  SBQQSC__Quote__c = quote2.Id)};
                                        
                                        
                                        insert lstSC;
            
            List<ContractLineItem> lstCli = new List<ContractLineItem>{
                new ContractLineItem(SBQQSC__OrderProduct__c = orderItemList[0].Id,Quantity = orderItemList[0].quantity,SBQQSC__QuoteLine__c = orderItemList[0].SBQQ__QuoteLine__c,SBQQSC__Product__c = orderItemList[0].Product2Id, PricebookEntryId = orderItemList[0].PricebookEntryId,  ServiceContractId= lstSC[0].Id, UnitPrice= orderItemList[0].UnitPrice, StartDate = date.today()),
                    new ContractLineItem(SBQQSC__OrderProduct__c = orderItemList[1].Id,Quantity = orderItemList[1].quantity, SBQQSC__QuoteLine__c = orderItemList[1].SBQQ__QuoteLine__c,SBQQSC__Product__c = orderItemList[1].Product2Id,PricebookEntryId = orderItemList[1].PricebookEntryId,  ServiceContractId= lstSC[0].Id, UnitPrice= orderItemList[0].UnitPrice, StartDate = date.today()),
                    new ContractLineItem(SBQQSC__OrderProduct__c = orderItemList[2].Id,Quantity = orderItemList[2].quantity, SBQQSC__QuoteLine__c = orderItemList[2].SBQQ__QuoteLine__c,SBQQSC__Product__c = orderItemList[2].Product2Id,PricebookEntryId = orderItemList[2].PricebookEntryId,  ServiceContractId= lstSC[1].Id, UnitPrice= orderItemList[1].UnitPrice, StartDate = date.today().addDays(10))
                    
                    }; 
                        
                        insert lstCli;
            orderItemList[0].SBQQSC__ContractLineItem__c = lstCli[0].Id;
            orderItemList[1].SBQQSC__ContractLineItem__c = lstCli[1].Id;
            orderItemList[2].SBQQSC__ContractLineItem__c = lstCli[2].Id;
            orderItemList[2].SBQQ__RequiredBy__c = orderItemList[0].Id;
            
            
            update orderItemList;
            Id supportRecordTypeId = Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Support').getRecordTypeId();
            
            List<Entitlement> lstEntitlement = new List<Entitlement> {
                
                new Entitlement(Name = sampleProducts[0].ProductCode , RecordTypeId = supportRecordTypeId , Type= 'Phone Support', AccountId= lstAccount2[0].Id, Product__c = sampleProducts[0].Id, 
                                StartDate= date.today(), ServiceContractId = lstSC[0].Id, ContractLineItemId = lstCli[0].Id, Order_Service_Item__c=orderItemList[0].id),
                    new Entitlement(Name = sampleProducts[4].ProductCode , AssetId = lstAsset[0].Id,RecordTypeId = supportRecordTypeId , Type= 'Phone Support', AccountId= lstAccount2[0].Id, Product__c = sampleProducts[4].Id, 
                                    StartDate= date.today(), ServiceContractId = lstSC[0].Id, ContractLineItemId = lstCli[1].Id, Order_Service_Item__c=orderItemList[1].id),
                    
                    new Entitlement(Name = sampleProducts[5].ProductCode , RecordTypeId = supportRecordTypeId , Type= 'Phone Support', AccountId= lstAccount2[0].Id, Product__c = sampleProducts[5].Id, 
                                    StartDate= date.today().addDays(10), ServiceContractId = lstSC[1].Id, ContractLineItemId = lstCli[2].Id, Order_Service_Item__c=orderItemList[2].Id)
                    
                    };
                        insert lstEntitlement; 
            
            List<String> lstNewEntitlementIds = new List<String>{lstEntitlement[0].Id,lstEntitlement[1].Id};
                
                orderInstanceObj.SBQQ__Contracted__c = false;
            orderInstanceObj.Polaris_Fulfillment_Status__c = 'Completed';
            orderInstanceObj.Status = 'Activated';
            orderInstanceObj.Order_Status__c = 'Shipped';
            //orderInstanceObj.Program__c = 'Conversion';
            orderInstanceObj.SBQQ__Quote__c = quote2.Id;
            orderInstanceObj.Actual_Order_Ship_Date__c=System.today();
            orderInstanceObj.Welcome_letter_sent_for_the_first_time__c = true;
            
            update orderInstanceObj;
            
            EntitlementLinkCreationClass objCLass = new EntitlementLinkCreationClass();
            objCLass.createEntitlementLinks(lstOldCliIds, lstNewEntitlementIds );
            
            Test.stopTest();
        }
    }
    
    
}