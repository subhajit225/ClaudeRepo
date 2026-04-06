/***************************************************************
* @description       : EntitlementsManagement_Test.cls
* @author            : Siva Kumar
* @last modified on  : July 2, 2025
* Modifications Log
* Ver   Date          Author        Modification
* 1.0   02-06-2025   chaitra        Initial Version
************************************************************/
@isTest
public class EntitlementsManagementTest {
    static String userEmail = 'TestContractOrders@User.Rubrik.com';
    /**
    * @description setup method to generate initial data required for  class methods
    */
    @testSetup
    static void insertData() {
        ShGl_TestFactory.UserDefaults userDef = new ShGl_TestFactory.UserDefaults();
        User runningUser = (User)ShGl_TestFactory.createSObject(new User(), userDef.getDynamicValueMap());
        runningUser.RBAC_Department__c = 'Service Account';
        runningUser.RBAC_Group__c = 'API';
        runningUser.Email = userEmail;
        insert runningUser;
        System.runAs(runningUser) {
            insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Disable_Account_Old_Trigger__c = true);
            insert new ShGl_DisableBusinessLogic__c(
                setupownerid = runningUser.Id,
                Disable_Entitlement_Validation_Rules__c = true,
                Disable_Account_Triggers__c = true,
                Disable_Asset_Triggers__c = true,
                Disable_SBQQ_Quote_Triggers__c = true,
                Disable_SBQQ_QuoteLine_Triggers__c = true,
                Disable_Product2_Validation_Rules__c = true,
                Disable_Order_Old_Trigger__c = true,
                Disable_OrderItem_Old_Trigger__c = true,
                Disable_Opportunity_Triggers__c = true,
                Disable_Product2_Trigger__c = true,
                Disable_Order_Validation_Rules__c = true,
                Disable_Contract_Line_Item_Triggers__c = true,
                Disable_SBQQ_QuoteLine_Validation_Rules__c = true
                
            );
            TriggerControl.stopOrderItemTrigger = true;
            TriggerControl.stopOrderTrigger = true;
            TriggerControl__c objOrderTrigger = new TriggerControl__c(Name = 'Entitlement', Disable_Trigger__c = true, DisableTrigger__c = true, SendEmail__c = false);
            insert objOrderTrigger;
            
            Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            Account customer = new Account(
                Name = 'Customer',
                recordtypeId = partner,
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
            
            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = opp.Id,
                SBQQ__SubscriptionTerm__c = 12,
                Is_RWD_Polaris_Quote__c = true,
                SBQQ__Primary__c = true,
                ApprovalStatus__c = 'Recalled',
                SBQQ__Type__c = 'Quote',
                SBQQ__PriceBook__c = Test.getStandardPricebookId()
            );
            insert quote;
            
            SBQQ__Quote__c quote2 = new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = opp1.Id,
                SBQQ__SubscriptionTerm__c = 12,
                Is_RWD_Polaris_Quote__c = true,
                SBQQ__Primary__c = true,
                ApprovalStatus__c = 'Recalled',
                SBQQ__Type__c = 'Renewal+Expansion',
                SBQQ__PriceBook__c = Test.getStandardPricebookId()
            );
            insert quote2;
            
            
            Product2 prod1 = getProduct('RS-BT-EE-PE-PP', 'Bundle', 'Rubrik Licence', 'Enterprise Edition',
                                                       'SaaS', 'Hybrid Software', 'Default', 'One per quote line', 'Fixed Price',
                                                       36, 'List', 'Renewable');
            Product2 prod2 = getProduct('RBK-R6412-CONS', 'Platform', 'r300', 'Hardware',
                                        null, 'Hardware', 'Default', 'None', 'Fixed Price',
                                        1, 'List', 'Renewable');
            prod2.Usable_Capacity__c = 1;
            prod2.Appliance_Model__c = 'RBK-R344';
            prod2.Appliance_Model_HW__c = 'RBK-R344';
            prod2.CPQ_MSP_Base_Price__c = 0.13;
            prod2.Asset_Priority__c = 0;
            prod2.MSP_Segment_Product__c = true;
            
            Product2 prod3 = getProduct('RBK-RADAR-CONS', 'Support', null, 'Hardware',
                                        null, 'Support', 'Default', 'One per quote line', 'Fixed Price',
                                        36, 'List', 'Renewable');
            prod3.CPQ_MSP_Base_Price__c = 0.02;
            
            Product2 prod4 = getProduct('RBK-RADAR-CONS1', 'Support', null, null, null, null, 'Default', 'One per quote line',
                                       'Fixed Price', 36, 'List', 'Renewable');
			prod4.CPQ_MSP_Base_Price__c = 0.02;
            
            Product2 prod5 = getProduct('RS-HW-SVC-PE-S1', 'Support', 'Support', 'HW Support', null, 'Support',
                                        null, 'One per quote line',
                                       'Fixed Price', 36, 'List', 'Renewable');
            Product2 prod6 = getProduct('RS-BT-RCDM-T', 'Software', 'OnPrem', null, 'On Prem', 'OnPrem', null, 'One per quote line',
                                       'Fixed Price', 1, 'List', 'One-time');
            prod6.Support_Type__c = 'Premium';
            prod6.New_CPQ_Product__c = false;
            prod6.GPL_Name__c = 'NetApp';
            
            Product2 prod7 = getProduct('RH-6408S-01', 'Hardware', 'R6000', 'Hardware', null, 'Hardware', 'Default', 'None',
                                       null, null, 'List', null);
            prod7.Usable_Capacity__c = 60;
            prod7.Appliance_Model__c = 'RBK-R6408S';
            prod7.Appliance_Model_HW__c = 'RBK-R6408S';
            prod7.MSP_Segment_Product__c = true;
            
            Product2 prod8 = getProduct('RS-UR-FE-MD-PE-PP', 'SaaS', 'POLARIS', 'M365H', 'Subscriptions', 'SaaS Software Addon',
                                       null, 'One per quote line', 'Fixed Price', 1, 'List', 'Renewable');
           	prod8.Support_Type__c = 'Premium'; 
            
            Product2 prod9 = getProduct('RS-UR-M365-PE-PP', 'SaaS', 'POLARIS', 'Hybrid M365H', 'Subscriptions',
                                       'Standalone Software Addon', null, 'One per quote line', 'Fixed Price', 1,  'List', 'Renewable');
            
            prod9.Support_Type__c = 'Premium';
            
            Product2 prod10 = getProduct('RS-TB-EE-RSV-PE', null, null, 'Enterprise Edition', null, 'Hybrid Software',
                                        'Default', 'One per quote line', 'Fixed Price', null, null,  'Renewable');
            prod10.License_Type__c = 'Consumption';
            prod10.Product_Subtype__c = 'Scale MSP';
            prod10.Product_Payment_Option__c = 'Monthly';
            prod10.Approval_Category__c = 'Scale Utility RSV';
            
            Product2 prod11 = getProduct('RBK-HW-CONS1', 'Support', null, '3rd Party Hardware', null, null, 
                                        'Default', 'One per unit', 'Fixed Price', 36, 'List', 'Renewable');
            prod11.CPQ_MSP_Base_Price__c = 0.02;
            
            Product2 prod12 = getProduct('RBK-HW-Addon', 'Support', null, null, null, 'Standalone Software Addon',
                                        'Default', 'One per unit', 'Fixed Price', 36, 'List', 'Renewable');
            prod12.CPQ_MSP_Base_Price__c = 0.02;
            
            Product2 prod13 = getProduct('RS-TB-EE-RSVX-PE', null, null, 'Enterprise Edition', null, null,  'Hybrid Software',
                                         null, 'One per quote line', null, null, null);
            
            prod13.Product_Subtype__c = 'Scale MSP';
            prod13.License_Type__c = 'Consumption';
            prod13.Quotable_Date__c = system.today();
            prod13.SBQQ__Hidden__c = false;
            prod13.Support_Type__c = 'Premium';
            prod13.SBQQ__ExcludeFromOpportunity__c = true;
            prod13.New_CPQ_Product__c = true;
            
            Product2 prod14 = getProduct('RS-UR-EE-MD-RSVX-L3', null, null, 'Enterprise Edition', null, null,
                                        null, 'One per quote line', null, null, null, null);
            prod14.Product_Subtype__c = 'Scale MSP';
            prod14.License_Type__c = 'Consumption';
            prod14.Quotable_Date__c = system.today();
            prod14.SBQQ__Hidden__c = false;
            prod14.Support_Type__c = 'Premium';
            prod14.SBQQ__ExcludeFromOpportunity__c = true;
            prod14.New_CPQ_Product__c = true;
            
            Product2 prod15 = getProduct('RS-UR-FE-MD-RSV-PE', null, null, 'M365H', 'SaaS', null,
                                        'Default', 'One per quote line', 'Fixed Price', null, null, 'Renewable');
			prod15.Support_Type__c = 'Premium';
            prod15.License_Type__c = 'Consumption';
            prod15.Product_Subtype__c = 'Scale MSP';
            prod15.Product_Payment_Option__c = 'Monthly';
            prod15.Approval_Category__c = 'Scale Utility RSV';
            
            Product2 prod16 = getProduct('RS-TB-FUE-RSV-PE', null, null, 'Edition Upgrade', 'SaaS', null, 'Default',
                                        'One per quote line', 'Fixed Price', null, null, 'Renewable');
            prod16.Support_Type__c = 'Premium';
            prod16.License_Type__c = 'Consumption';
            prod16.Product_Subtype__c = 'Scale MSP';
            
            Product2 prod17 = getProduct('RBK-GO-FNDN-R6412-ADDON-NODE', 'Bundle', 'R6000', 'Foundation Edition', null,
                                        null, null, 'One per unit',  'Fixed Price', 1, 'List', 'Renewable');
            prod17.Edition__c = 'Foundation Edition';
            
            Product2 prod18 = getProduct('RBK-SVC-PREM-HW', 'Support', null, 'HW Support', 'Subscriptions', null,
                                       'Default',  'One per unit', 'Fixed Price', null, null, 'Renewable');
            prod18.Support_Type__c = 'Premium';
            
            List<Product2> sampleProducts = new List<Product2>{prod1, prod2, prod3, prod4, prod5, prod6, prod7, prod8,
                prod9, prod10, prod11, prod12, prod13, prod14, prod15, prod16, prod17, prod18};
            insert sampleProducts;
            
            List<PricebookEntry> entries = new List<PricebookEntry>();
            for(Product2 prodRec : sampleProducts){
                entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prodRec.Id, IsActive = true, UnitPrice = 100));    
            }
            insert entries;
            
            List<Asset> assestIns = new List<Asset>{
                new Asset(
                    Name = '09092019APMSP1250',
                    SerialNumber = '09092019APMSP1250',
                    serial_number__c = '09092019APMSP1250',
                    AccountId = customer.Id,
                    Product2Id = sampleProducts[0].Id
                ),
                    new Asset(
                        Name = '09092019APMSP1253',
                        SerialNumber = '09092019APMSP1253',
                        serial_number__c = '09092019APMSP1253',
                        AccountId = customer.Id,
                        Product2Id = sampleProducts[6].Id
                    ),
                    new Asset(
                        Name = '09092019APMSP1254',
                        SerialNumber = '09092019APMSP1254',
                        serial_number__c = '09092019APMSP1254',
                        AccountId = customer.Id,
                        Product2Id = sampleProducts[6].Id
                    )
                    };
                        
            insert assestIns;
            
            SBQQ__QuoteLine__c line1 = getQuoteLine(quote.Id, sampleProducts[0].Id, entries[0].Id, 70, null,
                                                 200, 200);
            SBQQ__QuoteLine__c line2 = getQuoteLine(quote.Id,  sampleProducts[1].Id,  entries[1].Id,  20,  'Fixed Price',
                                                  200,  200);
            line2.MSP_Segment_Product__c = true;
            line2.SBQQ__Segmentindex__c = 1;
            line2.SBQQ__Existing__c = true;
            
            SBQQ__QuoteLine__c line3 = getQuoteLine(quote.Id,  sampleProducts[2].Id,  entries[2].Id,  20,  null,
                                                  200,  200);
            SBQQ__QuoteLine__c line4 = getQuoteLine( quote.Id,  sampleProducts[3].Id, entries[3].Id,  20,   'Fixed Price',
                                                  200,  200);
            line4.MSP_Segment_Product__c = true;
            line4.SBQQ__Segmentindex__c = 1;
            
            SBQQ__QuoteLine__c line5 = getQuoteLine( quote.Id,  sampleProducts[4].Id,  entries[4].Id,  1,  'Fixed Price',
                                                  200,  200);
            line5.MSP_Segment_Product__c = true;
            line5.SBQQ__Segmentindex__c = 1;
            
            SBQQ__QuoteLine__c line6 = getQuoteLine( quote.Id, sampleProducts[5].Id,  entries[5].Id,  42,  null,
                                                  200,  200);
            line6.SBQQ__StartDate__c = System.today().addMonths(4).addDays(-6);
            line6.SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1);
            
            SBQQ__QuoteLine__c line7 = getQuoteLine( quote.Id, sampleProducts[6].Id,   entries[6].Id,  20,  'Fixed Price',
                                                  200,  200);
            line7.MSP_Segment_Product__c = true;
            line7.SBQQ__Segmentindex__c = 1;
            line7.SBQQ__Existing__c = true;
            
            SBQQ__QuoteLine__c line8 = getQuoteLine(quote.Id, sampleProducts[7].Id, entries[7].Id, 20, null, 200, 200);
            
            SBQQ__QuoteLine__c line9 = getQuoteLine(quote.Id, sampleProducts[8].Id, entries[8].Id, 20, null, 200, 200);
            line9.SBQQ__Optional__c = true;
            line9.Disposition_Reason__c = 'Replaced';
            
            SBQQ__QuoteLine__c line10 = getQuoteLine(quote.Id, sampleProducts[9].Id, entries[9].Id, 20, null, 200, 200);
            
            SBQQ__QuoteLine__c line11 = getQuoteLine(quote.Id, sampleProducts[10].Id, entries[10].Id, 20, null, 200, 200);
            
            SBQQ__QuoteLine__c line12 = getQuoteLine(quote.Id, sampleProducts[10].Id, entries[10].Id, 20, null, 200, 200);
            
            SBQQ__QuoteLine__c line13 = getQuoteLine(quote.Id, sampleProducts[11].Id, entries[11].Id, 20, null, 200, 200);
            
            SBQQ__QuoteLine__c line14 = getQuoteLine(quote.Id, sampleProducts[12].Id, entries[12].Id, 20, null, 200, 200);
            
            SBQQ__QuoteLine__c line15 = getQuoteLine(quote.Id, sampleProducts[13].Id, entries[13].Id, 20, null, 200, 200);
            
            SBQQ__QuoteLine__c line16 = getQuoteLine(quote.Id, sampleProducts[14].Id, entries[14].Id, 20, null, 200, 200);
            
            SBQQ__QuoteLine__c line17 = getQuoteLine(quote.Id, sampleProducts[15].Id, entries[15].Id, 20, null, 200, 200);
            line17.SBQQ__StartDate__c = System.today();
            line17.SBQQ__EndDate__c = System.today().addMonths(3).addDays(-1);
            
            SBQQ__QuoteLine__c line18 = getQuoteLine(quote.Id, sampleProducts[16].Id, entries[16].Id, 2, 'Fixed Price', 200, 200);
            line18.SBQQ__StartDate__c = System.today();
            line18.SBQQ__EndDate__c = System.today().addMonths(3).addDays(-1);
            
            SBQQ__QuoteLine__c line19 = getQuoteLine(quote.Id, sampleProducts[17].Id, entries[17].Id, 2, 'Fixed Price', 200, 200);
            line19.SBQQ__StartDate__c = System.today();
            line19.SBQQ__EndDate__c = System.today().addMonths(3).addDays(-1);
            
            SBQQ__QuoteLine__c line20 = getQuoteLine(quote.Id, sampleProducts[6].Id, entries[6].Id, 2, 'Fixed Price', 200, 200);
            line20.MSP_Segment_Product__c = true;
            line20.SBQQ__Segmentindex__c = 1;
            line20.Usable_Capacity__c = sampleProducts[6].Usable_Capacity__c;
            
            List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>{line1, line2, line3, line4, line5, line6,line7, line8, line9, line10,
                line11, line12, line13, line14, line15, line16,line17, line18, line19, line20};
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
            lines[9].SBQQ__RequiredBy__c = lines[12].Id;
            lines[14].SBQQ__RequiredBy__c = lines[13].Id;
            lines[15].SBQQ__RequiredBy__c = lines[12].Id;
            lines[17].SBQQ__RequiredBy__c = lines[19].Id;
            lines[18].SBQQ__RequiredBy__c = lines[19].Id;
            lines[18].Replacement_Details__c = '';
            update lines;
            
            quote.ApprovalStatus__c = 'Approved';
            update quote;
            
            List<Order> orderList = new List<Order>();
            Order orderInstanceNew = new Order();
            orderInstanceNew.AccountId = customer.Id;
            orderInstanceNew.OpportunityId = opp.Id;
            orderInstanceNew.EffectiveDate = system.today();
            orderInstanceNew.Status = 'Draft';
            orderInstanceNew.Type = 'Revenue';
            orderInstanceNew.Order_Status__c = 'Pending';
            orderInstanceNew.Status = 'Draft';
            orderInstanceNew.Pricebook2Id = Test.getStandardPricebookId();
            orderList.add(orderInstanceNew);
            Order ordNew = orderInstanceNew.clone();
            ordNew.EffectiveDate = Date.newInstance(2023, 6, 2);
            ordNew.Order_Sub_Type__c = 'Renewal';
            orderList.add(ordNew);
            Order ordNew1 = orderInstanceNew.clone();
            ordNew1.EffectiveDate = Date.newInstance(2023, 6, 2);
            ordNew1.Order_Sub_Type__c = 'Renewal';
            orderList.add(ordNew1);
            
            Order phantomORD = orderInstanceNew.clone();
            phantomORD.EffectiveDate = Date.newInstance(2023, 6, 2);
            phantomORD.recordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Phantom Order').getRecordTypeId();
            phantomORD.Type = 'Revenue Internal';
            orderList.add(phantomORD);
            insert orderList;
            
            
            OrderItem oItem1 = getOrderItem(orderInstanceNew.Id, sampleProducts[0].Id, '09092019APMSP1250', entries[0].UnitPrice,
                                            lines[0].Id, 36, 70,  entries[0].Id);
            OrderItem oItem2 = getOrderItem(orderInstanceNew.Id, sampleProducts[4].Id, '09092019APMSP1250', entries[4].UnitPrice,
                                            lines[4].Id, 36, 1,  entries[4].Id);
            OrderItem oItem3 = getOrderItem(orderInstanceNew.Id, sampleProducts[5].Id, null, entries[5].UnitPrice,
                                            lines[5].Id, 36, 20,  entries[5].Id);
            OrderItem oItem4 = getOrderItem(orderInstanceNew.Id, sampleProducts[6].Id, '09092019APMSP1250', entries[6].UnitPrice,
                                            lines[6].Id, 36, 1,  entries[6].Id);
            OrderItem oItem5 = getOrderItem(orderInstanceNew.Id, sampleProducts[7].Id, null, entries[7].UnitPrice,
                                            lines[7].Id, 36, 1,  entries[7].Id);
            oItem5.Program__c = 'Replaced';
            
            OrderItem oItem6 = getOrderItem(orderInstanceNew.Id, sampleProducts[2].Id, null, entries[2].UnitPrice,
                                            lines[2].Id, 36, 70,  entries[2].Id);
            
            OrderItem oItem7 = getOrderItem(orderInstanceNew.Id, sampleProducts[10].Id, null, entries[10].UnitPrice,
                                            lines[10].Id, 36, 70,  entries[10].Id);
            OrderItem oItem8 = getOrderItem(orderInstanceNew.Id, sampleProducts[10].Id, null, entries[11].UnitPrice,
                                            lines[11].Id, 36, 70,  entries[10].Id);
            OrderItem oItem9 = getOrderItem(orderInstanceNew.Id, sampleProducts[11].Id, null, entries[10].UnitPrice,
                                            lines[12].Id, 36, 70,  entries[11].Id);
            OrderItem oItem10 = getOrderItem(orderInstanceNew.Id, sampleProducts[9].Id, null, entries[9].UnitPrice,
                                            lines[9].Id, 36, 70,  entries[9].Id);
            OrderItem oItem11 = getOrderItem(orderInstanceNew.Id, sampleProducts[12].Id, null, entries[12].UnitPrice,
                                            lines[12].Id, 36, 70,  entries[12].Id);
            OrderItem oItem12 = getOrderItem(orderInstanceNew.Id, sampleProducts[13].Id, null, entries[13].UnitPrice,
                                            lines[13].Id, 36, 70,  entries[13].Id);
            OrderItem oItem13 = getOrderItem(orderInstanceNew.Id, sampleProducts[14].Id, null, entries[14].UnitPrice,
                                            lines[14].Id, 36, 70,  entries[14].Id);
            OrderItem oItem14 = getOrderItem(orderInstanceNew.Id, sampleProducts[15].Id, null, entries[15].UnitPrice,
                                            lines[15].Id, 36, 70,  entries[15].Id);
            OrderItem oItem15 = getOrderItem(orderInstanceNew.Id, sampleProducts[15].Id, null, entries[15].UnitPrice,
                                            lines[15].Id, 36, 70,  entries[15].Id);
            OrderItem oItem16 = getOrderItem(orderInstanceNew.Id, sampleProducts[15].Id, null, entries[15].UnitPrice,
                                            lines[15].Id, 36, 70,  entries[15].Id);
            OrderItem oItem17 = getOrderItem(orderInstanceNew.Id, sampleProducts[16].Id, null, entries[16].UnitPrice,
                                            lines[17].Id, 1, 2,  entries[16].Id);
            OrderItem oItem18 = getOrderItem(orderInstanceNew.Id, sampleProducts[1].Id, null, entries[1].UnitPrice,
                                            lines[19].Id, 1, 2,  entries[1].Id);
            OrderItem oItem19 = getOrderItem(orderInstanceNew.Id, sampleProducts[17].Id, '09092019APMSP1253, 09092019APMSP1254', entries[17].UnitPrice,
                                            lines[18].Id, 1, 2,  entries[17].Id);
            OrderItem oItem20 = getOrderItem(phantomORD.Id, sampleProducts[17].Id, '09092019APMSP1253, 09092019APMSP1254', 0,
                                            lines[18].Id, 1, 2,  entries[17].Id);
            OrderItem oItem21 = getOrderItem(orderInstanceNew.Id, sampleProducts[0].Id, '09092019APMSP1250', entries[0].UnitPrice,
                                            lines[0].Id, 36, 70,  entries[0].Id);
            List<OrderItem> orderItemList = new List<OrderItem>{oItem1, oItem2, oItem3, oItem4, oItem5, oItem6, oItem7, oItem8, oItem9,
                oItem10, oItem11, oItem12, oItem13, oItem14, oItem15, oItem16, oItem17, oItem18, oItem19,
                oItem20, oItem21};
            
           Test.startTest();
            insert orderItemList;
            
            ServiceContract objSC = new ServiceContract(
                Name = 'ServiceContractTest1',
                AccountId = customer.Id,
                StartDate = Date.today(),
                Term = 36,
                pricebook2Id = Test.getStandardPricebookId(),
                SBQQSC__Opportunity__c = opp.Id,
                SBQQSC__Order__c = orderInstanceNew.Id,
                SBQQSC__Quote__c = quote.Id
            );
            
            insert objSC;
            /*getContractLine(orderItemId, Id quoteLineId, Id productId, Id pbEntryId, Id serviceContractId,
                                                  Decimal unitPrice, Date startDate, Integer quantity)*/
            ContractLineItem conLineItem1 = getContractLine(orderItemList[0].Id, orderItemList[0].SBQQ__QuoteLine__c,
                                                            orderItemList[0].Product2Id, orderItemList[0].PricebookEntryId,
                                                            objSC.Id, orderItemList[0].UnitPrice, date.today(), orderItemList[0].quantity);
            ContractLineItem conLineItem2 = getContractLine(orderItemList[1].Id, orderItemList[1].SBQQ__QuoteLine__c,
                                                            orderItemList[1].Product2Id, orderItemList[1].PricebookEntryId,
                                                            objSC.Id, orderItemList[1].UnitPrice, date.today(), orderItemList[1].quantity);
            ContractLineItem conLineItem3 = getContractLine(orderItemList[2].Id, orderItemList[2].SBQQ__QuoteLine__c,
                                                            orderItemList[2].Product2Id, orderItemList[2].PricebookEntryId,
                                                            objSC.Id, orderItemList[2].UnitPrice, date.today(), orderItemList[2].quantity);
            ContractLineItem conLineItem4 = getContractLine(orderItemList[5].Id, orderItemList[5].SBQQ__QuoteLine__c,
                                                            orderItemList[5].Product2Id, orderItemList[5].PricebookEntryId,
                                                            objSC.Id, orderItemList[5].UnitPrice, date.today(), orderItemList[5].quantity);
            ContractLineItem conLineItem5 = getContractLine(orderItemList[6].Id, orderItemList[6].SBQQ__QuoteLine__c,
                                                            orderItemList[6].Product2Id, orderItemList[6].PricebookEntryId,
                                                            objSC.Id, orderItemList[6].UnitPrice, date.today(), orderItemList[6].quantity);
            ContractLineItem conLineItem6 = getContractLine(orderItemList[7].Id, orderItemList[7].SBQQ__QuoteLine__c,
                                                            orderItemList[7].Product2Id, orderItemList[7].PricebookEntryId,
                                                            objSC.Id, orderItemList[7].UnitPrice, date.today(), orderItemList[7].quantity);
            ContractLineItem conLineItem7 = getContractLine(orderItemList[8].Id, orderItemList[8].SBQQ__QuoteLine__c,
                                                            orderItemList[8].Product2Id, orderItemList[8].PricebookEntryId,
                                                            objSC.Id, orderItemList[8].UnitPrice, date.today(), orderItemList[8].quantity);
            ContractLineItem conLineItem8 = getContractLine(orderItemList[9].Id, orderItemList[9].SBQQ__QuoteLine__c,
                                                            orderItemList[9].Product2Id, orderItemList[9].PricebookEntryId,
                                                            objSC.Id, orderItemList[9].UnitPrice, date.today(), orderItemList[9].quantity);
            ContractLineItem conLineItem9 = getContractLine(orderItemList[10].Id, orderItemList[10].SBQQ__QuoteLine__c,
                                                            orderItemList[10].Product2Id, orderItemList[10].PricebookEntryId,
                                                            objSC.Id, orderItemList[10].UnitPrice, date.today(), orderItemList[10].quantity);
            ContractLineItem conLineItem10 = getContractLine(orderItemList[11].Id, orderItemList[11].SBQQ__QuoteLine__c,
                                                            orderItemList[11].Product2Id, orderItemList[11].PricebookEntryId,
                                                            objSC.Id, orderItemList[11].UnitPrice, date.today(), orderItemList[11].quantity);
            ContractLineItem conLineItem11 = getContractLine(orderItemList[12].Id, orderItemList[12].SBQQ__QuoteLine__c,
                                                            orderItemList[12].Product2Id, orderItemList[12].PricebookEntryId,
                                                            objSC.Id, orderItemList[12].UnitPrice, date.today(), orderItemList[12].quantity);
            ContractLineItem conLineItem12 = getContractLine(orderItemList[13].Id, orderItemList[13].SBQQ__QuoteLine__c,
                                                            orderItemList[13].Product2Id, orderItemList[13].PricebookEntryId,
                                                            objSC.Id, orderItemList[13].UnitPrice, date.today(), orderItemList[13].quantity);
            ContractLineItem conLineItem13 = getContractLine(orderItemList[16].Id, orderItemList[16].SBQQ__QuoteLine__c,
                                                            orderItemList[16].Product2Id, orderItemList[16].PricebookEntryId,
                                                            objSC.Id, orderItemList[16].UnitPrice, date.today(), orderItemList[16].quantity);
            ContractLineItem conLineItem14 = getContractLine(orderItemList[18].Id, orderItemList[18].SBQQ__QuoteLine__c,
                                                            orderItemList[18].Product2Id, orderItemList[18].PricebookEntryId,
                                                            objSC.Id, orderItemList[18].UnitPrice, date.today().addDays(-80), orderItemList[18].quantity);
            List<ContractLineItem> lstCli = new List<ContractLineItem>{conLineItem1, conLineItem2, conLineItem3, conLineItem4,
                conLineItem5, conLineItem6, conLineItem7, conLineItem8, conLineItem9, conLineItem10, conLineItem11,
                conLineItem12, conLineItem13, conLineItem14};
                        
            insert lstCli;
            orderItemList[0].SBQQSC__ContractLineItem__c = lstCli[0].Id;
            orderItemList[1].SBQQSC__ContractLineItem__c = lstCli[1].Id;
            orderItemList[2].SBQQSC__ContractLineItem__c = lstCli[2].Id;
            orderItemList[5].SBQQSC__ContractLineItem__c = lstCli[3].Id;
            orderItemList[6].SBQQSC__ContractLineItem__c = lstCli[4].Id;
            orderItemList[7].SBQQSC__ContractLineItem__c = lstCli[5].Id;
            orderItemList[8].SBQQSC__ContractLineItem__c = lstCli[6].Id;
            orderItemList[9].SBQQSC__ContractLineItem__c = lstCli[7].Id;
            orderItemList[10].SBQQSC__ContractLineItem__c = lstCli[8].Id;
            orderItemList[11].SBQQSC__ContractLineItem__c = lstCli[9].Id;
            orderItemList[12].SBQQSC__ContractLineItem__c = lstCli[10].Id;
            orderItemList[16].SBQQSC__ContractLineItem__c = lstCli[12].Id;
            orderItemList[18].SBQQSC__ContractLineItem__c = lstCli[13].Id;
            orderItemList[2].SBQQ__RequiredBy__c = orderItemList[0].Id;
            orderItemList[16].SBQQ__RequiredBy__c = orderItemList[17].Id;
            orderItemList[18].SBQQ__RequiredBy__c = orderItemList[17].Id;
            PreviousTransRefWrapper repJSON = new PreviousTransRefWrapper(orderItemList[0].Id,0,null,0,null,null,null,false);
           /* repJSON.orderItemId = orderItemList[0].Id;
            repJSON.orderItemRemainingQuantity =0;
            repJSON.entId = null;
            repJSON.usedEntitlementQuantity = 0;
            repJSON.storageTier = 10;*/
            orderItemList[20].Previous_Transaction_Reference__c = JSON.serialize(new List<PreviousTransRefWrapper>{repJSON});
            update orderItemList;
            Test.stopTest();
            Id supportRecordTypeId = Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Support').getRecordTypeId();
            
            List<Entitlement> lstEntitlement = new List<Entitlement>{
                new Entitlement(
                    Name = 'Ent Test 1',
                    RecordTypeId = supportRecordTypeId,
                    Type = 'Phone Support',
                    AccountId = customer.Id,
                    Product__c = sampleProducts[0].Id,
                    StartDate = date.today(),
                    ServiceContractId = objSC.Id,
                    ContractLineItemId = lstCli[0].Id,
                    Order_Service_Item__c = orderItemList[0].id
                ),
                    new Entitlement(
                        Name = 'Ent Test 2',
                        RecordTypeId = supportRecordTypeId,
                        Type = 'Phone Support',
                        AccountId = customer.Id,
                        Product__c = sampleProducts[4].Id,
                        StartDate = date.today(),
                        AssetId = assestIns[0].Id,
                        ServiceContractId = objSC.Id,
                        ContractLineItemId = lstCli[1].Id,
                        Order_Service_Item__c = orderItemList[1].Id
                    ),
                    new Entitlement(
                        Name = sampleProducts[5].ProductCode,
                        RecordTypeId = supportRecordTypeId,
                        Type = 'Phone Support',
                        AccountId = customer.Id,
                        Product__c = sampleProducts[5].Id,
                        StartDate = date.today(),
                        ServiceContractId = objSC.Id,
                        ContractLineItemId = lstCli[2].Id,
                        Order_Service_Item__c = orderItemList[2].Id
                    ),
                    new Entitlement(
                        Name = sampleProducts[2].ProductCode,
                        RecordTypeId = supportRecordTypeId,
                        Type = 'Phone Support',
                        AccountId = customer.Id,
                        Product__c = sampleProducts[2].Id,
                        StartDate = date.today(),
                        ServiceContractId = objSC.Id,
                        ContractLineItemId = lstCli[3].Id,
                        Order_Service_Item__c = orderItemList[5].Id
                    ),
                    new Entitlement(
                        Name = sampleProducts[10].ProductCode,
                        RecordTypeId = supportRecordTypeId,
                        Type = 'Phone Support',
                        AccountId = customer.Id,
                        Product__c = sampleProducts[10].Id,
                        StartDate = date.today(),
                        ServiceContractId = objSC.Id,
                        AssetId = assestIns[0].Id,
                        ContractLineItemId = lstCli[4].Id,
                        Order_Service_Item__c = orderItemList[6].Id
                    ),
                    new Entitlement(
                        Name = sampleProducts[10].ProductCode,
                        RecordTypeId = supportRecordTypeId,
                        Type = 'Phone Support',
                        AccountId = customer.Id,
                        Product__c = sampleProducts[11].Id,
                        StartDate = date.today(),
                        ServiceContractId = objSC.Id,
                        ContractLineItemId = lstCli[5].Id,
                        Order_Service_Item__c = orderItemList[7].Id
                    ),
                    new Entitlement(
                        Name = sampleProducts[11].ProductCode,
                        RecordTypeId = supportRecordTypeId,
                        Type = 'Phone Support',
                        AccountId = customer.Id,
                        Product__c = sampleProducts[11].Id,
                        StartDate = date.today(),
                        ServiceContractId = objSC.Id,
                        ContractLineItemId = lstCli[6].Id,
                        Order_Service_Item__c = orderItemList[8].Id
                    ),
                    new Entitlement(
                        Name = sampleProducts[14].ProductCode,
                        RecordTypeId = supportRecordTypeId,
                        Type = 'Phone Support',
                        AccountId = customer.Id,
                        Product__c = sampleProducts[14].Id,
                        StartDate = date.today(),
                        ServiceContractId = objSC.Id,
                        ContractLineItemId = lstCli[11].Id,
                        Order_Service_Item__c = orderItemList[13].Id
                    ),
                    new Entitlement(
                        Name = sampleProducts[16].ProductCode,
                        RecordTypeId = supportRecordTypeId,
                        Type = 'Phone Support',
                        AccountId = customer.Id,
                        Product__c = sampleProducts[16].Id,
                        StartDate = date.today(),
                        ServiceContractId = objSC.Id,
                        ContractLineItemId = lstCli[12].Id,
                        Order_Service_Item__c = orderItemList[16].Id,
                        AssetId = assestIns[1].Id
                    ), //license addon
                    new Entitlement(
                        Name = sampleProducts[16].ProductCode,
                        RecordTypeId = supportRecordTypeId,
                        Type = 'Phone Support',
                        AccountId = customer.Id,
                        Product__c = sampleProducts[16].Id,
                        StartDate = date.today(),
                        ServiceContractId = objSC.Id,
                        ContractLineItemId = lstCli[12].Id,
                        Order_Service_Item__c = orderItemList[16].Id
                    ), //license addon
                    new Entitlement(
                        Name = sampleProducts[17].ProductCode,
                        RecordTypeId = supportRecordTypeId,
                        Type = 'Phone Support',
                        AccountId = customer.Id,
                        Product__c = sampleProducts[17].Id,
                        StartDate = date.today(),
                        ServiceContractId = objSC.Id,
                        ContractLineItemId = lstCli[13].Id,
                        Order_Service_Item__c = orderItemList[18].Id,
                        AssetId = assestIns[1].Id
                    ), //Hw Support addon
                    new Entitlement(
                        Name = sampleProducts[17].ProductCode,
                        RecordTypeId = supportRecordTypeId,
                        Type = 'Phone Support',
                        AccountId = customer.Id,
                        Product__c = sampleProducts[17].Id,
                        StartDate = date.today(),
                        ServiceContractId = objSC.Id,
                        ContractLineItemId = lstCli[13].Id,
                        Order_Service_Item__c = orderItemList[18].Id
                    ), //Hw Support addon
                    new Entitlement(Name = sampleProducts[4].Name , RecordTypeId = supportRecordTypeId , Type= 'Phone Support', AccountId= customer.Id, Product__c   = sampleProducts[0].Id, AssetId = assestIns[0].Id,
                                    StartDate= date.today(), ServiceContractId = objSC.Id, ContractLineItemId = lstCli[0].Id, Order_Service_Item__c=orderItemList[0].id, Terminated_Date__c = System.today().addYears(1), Renewal_Category__c='Renewed'),
                    new Entitlement(Name = sampleProducts[0].Name, RecordTypeId = supportRecordTypeId , Type= 'Phone Support', AccountId= customer.Id, Product__c = sampleProducts[0].Id, 
                                    StartDate= date.today(), AssetId = assestIns[0].Id, ServiceContractId= objSC.Id, ContractLineItemId = lstCli[1].Id, Order_Service_Item__c=orderItemList[1].Id, Quantity__c = 0),
                    new Entitlement(Name = sampleProducts[5].ProductCode , RecordTypeId = supportRecordTypeId , Type= 'Phone Support', AccountId= customer.Id, Product__c = sampleProducts[5].Id, 
                                    StartDate= date.today(), ServiceContractId = objSC.Id, ContractLineItemId = lstCli[2].Id, Order_Service_Item__c=orderItemList[2].Id, Quantity__c = 0),
                    new Entitlement(Name = sampleProducts[2].ProductCode , RecordTypeId = supportRecordTypeId , Type= 'Phone Support', AccountId= customer.Id, Product__c = sampleProducts[2].Id, 
                                    StartDate= date.today(), ServiceContractId = objSC.Id, ContractLineItemId = lstCli[3].Id, Order_Service_Item__c=orderItemList[5].Id, Quantity__c = 2)
                    };
                        insert lstEntitlement;
            List<Scale_Entitlement__c> linkedAssetToInsert = new List<Scale_Entitlement__c>();
            List<Entitlement> entList = [Select id,ContractLineItemId,Order_Service_Item__c from Entitlement];
            for(Entitlement ent : entList){
                linkedAssetToInsert.add(new Scale_Entitlement__c(Entitlement__c = ent.id,Contract_Line_Item__c = ent.ContractLineItemId,Order_Product__c = ent.Order_Service_Item__c,Asset__c = assestIns[0].id,Type__c = 'Non-Scale')); 
            }
            insert linkedAssetToInsert;
        }
    }
    /**
    * @description method to generate product data
    * @return Product2 record
    * @param prodName
    * @param category
    * @param family
    * @param productType
    * @param licenseCategory
    * @param prodLevel
    * @param assetAmendBehaviour
    * @param entitlementConverion
    * @param subscriptionPricing
    * @param subscriptionTerm
    * @param subscriptionBase
    * @param subscriptionType
    */
    public static Product2 getProduct(String prodName, String category, String family, String productType,
                                      String licenseCategory, String prodLevel, String assetAmendBehaviour,
                                      String entitlementConverion, String subscriptionPricing, Integer subscriptionTerm,
                                      String subscriptionBase, String subscriptionType)
        
        
    {
        return new Product2(
            Name = prodName,
            ProductCode = prodName,
            Category__c = category,
            Family = family,
            Product_Type__c = productType,
            License_Category__c = licenseCategory,
            Product_Level__c = prodLevel,
            SBQQ__AssetAmendmentBehavior__c = assetAmendBehaviour,
            SBQQSC__EntitlementConversion__c = entitlementConverion,
            IsActive = true,
            SBQQ__SubscriptionPricing__c = subscriptionPricing,
            SBQQ__SubscriptionTerm__c = subscriptionTerm,
            SBQQ__SubscriptionBase__c = subscriptionBase,
            SBQQ__SubscriptionType__c = subscriptionType
        );    
    }
    /**
    * @description method to generate Quote Line data
    * @param quoteId
    * @param productId
    * @param pbEntryId
    * @param quantity
    * @param subscriptionPricing
    * @param listPrice
    * @param netPrice
    * @return SBQQ__QuoteLine__c
    */
    public static SBQQ__QuoteLine__c getQuoteLine(Id quoteId, Id productId, Id pbEntryId, decimal quantity, String subscriptionPricing,
                                                 Decimal listPrice, Decimal netPrice)
    {
    	return new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quoteId,
            SBQQ__Product__c = productId,
            SBQQ__PricebookEntryId__c = pbEntryId,
            SBQQ__Quantity__c = quantity,
            SBQQ__SubscriptionPricing__c = subscriptionPricing,
            SBQQ__ListPrice__c = listPrice,
            SBQQ__NetPrice__c = netPrice,
            SBQQ__DefaultSubscriptionTerm__c = null
        ); 
    }
    /**
    * @description method to generate ContractLineItem data
    * @param orderItemId
    * @param quoteLineId
    * @param productId
    * @param pbEntryId
    * @param serviceContractId
    * @param unitPrice
    * @param startDate
    * @param quantity
    * @return ContractLineItem
    */ 
    public static ContractLineItem getContractLine(Id orderItemId, Id quoteLineId, Id productId, Id pbEntryId, Id serviceContractId,
                                                  Decimal unitPrice, Date startDate, Decimal quantity){
        return new ContractLineItem(SBQQSC__OrderProduct__c = orderItemId,
                        Quantity = quantity,
                        SBQQSC__QuoteLine__c = quoteLineId,
                        SBQQSC__Product__c = productId,
                        PricebookEntryId = pbEntryId,
                        ServiceContractId = serviceContractId,
                        UnitPrice = unitPrice,
                        StartDate = startDate);
    }
    /**
    * @description method to generate OrderItem data
    * @param orderId
    * @param prodId
    * @param serialNum
    * @param unitPrice
    * @param quoteLineId
    * @param subscriptionTerm
    * @param quantity
    * @param pbEntryId
    * @return OrderItem
    */
    public static OrderItem getOrderItem(Id orderId, Id prodId, String serialNum, Decimal unitPrice, Id quoteLineId,
                                        Integer subscriptionTerm, Integer quantity, Id pbEntryId)
    {
        return new OrderItem(
            OrderId = orderId,
            Product2Id = prodId,
            SerialNumber__c = serialNum,
            UnitPrice = unitPrice,
            SBQQ__QuoteLine__c = quoteLineId,
            SBQQ__SubscriptionTerm__c = subscriptionTerm,
            Quantity = quantity,
            PricebookEntryId = pbEntryId);    
    }
    /**
    * @description method to test Replacement orders
    */
    @isTest
    static void testReplacementOrd() {
        List<user> adminUser = [SELECT Id FROM User WHERE Email = :userEmail LIMIT 1];
        System.runAs(adminUser[0]) {
            List<Asset> lstofAsset = [SELECT id FROM Asset LIMIT 1];
            List<OrderItem> existingOrdItem = [SELECT id FROM OrderItem WHERE quantity != NULL LIMIT 1];
            List<SBQQ__QuoteLine__c> qliList = [SELECT id, Replacement_details__c FROM SBQQ__QuoteLine__c];
            List<OrderItem> lstofordItem = new List<OrderItem>();
            List<Scale_Entitlement__c> linkedAssets = new List<Scale_Entitlement__c>();
            List<Entitlement> lstofEnt = [SELECT id, Order_Service_Item__r.Quantity, quantity__c, Order_Service_Item__c FROM Entitlement];
            for (Entitlement ent : lstofEnt) {
                ent.startdate = System.today();
                ent.EndDate = System.today().addMonths(1);
                ent.Quantity__c = 10;
                ent.Order_Service_Item__c = existingOrdItem[0].Id;
                linkedAssets.add(new Scale_Entitlement__c(Asset__c = lstofAsset[0].id, Entitlement__c = ent.id, Order_Product__c = ent.Order_Service_Item__c));
            }
            update lstofent;
            String replacementDetails = '{"targetProductType" : "Hardware","skuStorageTierVal":null,"skuStorageBundleVal":null,"skuSFDCVal":null,"skuSelectedName":"RS-BT-EE-PE-PA","skuSelected":"01t6f00000O6dT0AAJ","skuM365HVal":null,"skuAttlasianVal":null,"SeamlessCutover":null,"rowValues":[{"UpgradeLines":null,"selectedQty":300,"selectedAssetList":{"02i6f00000IfP9gAAF":"BB210464100059","02i6f00000IfPBSAA3":"BB210364100020","02i6f00000IrOTzAAN":"BB211364100028","02i6f00000IrOUJAA3":"BB211364100030"},"selectedAsset":"02i6f00000IrOUJAA3,02i6f00000IrOTzAAN,02i6f00000IfPBSAA3,02i6f00000IfP9gAAF","rowId":"2.1.0","inactiveLines":[{"childrowId":null,"childQnty":270,"childEntId":"550VI00000938QkYAI"}],"entId":"550VI000007aYKAYA2","disposition":"Converted","selectedTerm":12}],"mode":"1to1"}';
            for (SBQQ__QuoteLine__c qli : qliList) {
                qli.Replacement_details__c = replacementDetails;
                qli.special_program__c = 'Conversion';
            }
            
            update qlilist;
            insert linkedAssets;
            Entitlement_Links__c entLink = new Entitlement_Links__c();
            entLink.Previous_Entitlement__c = lstofEnt[0].id;
            entLink.Renewed_Entitlement__c = lstofEnt[0].id;
            entLink.quantity__c = 10;
            //entLink.Renewal_Category__c = 'Converted';
            entLink.Type__c = 'Split-Surviving';
            insert entLink;
            SplitOrder sp = new SplitOrder();
            Order replacedOrd = [
                SELECT
                id,
                Order_Sub_Type__c,
                SBQQ__Contracted__c,
                Polaris_Fulfillment_Status__c,
                Status,
                Order_Status__c,
                Actual_Order_Ship_Date__c,
                Welcome_letter_sent_for_the_first_time__c,
                (SELECT id, Enddate, order.ordernumber, Previous_Transaction_Reference__c FROM orderitems)
                FROM Order
                LIMIT 1
            ];
            //replacedOrd.Order_Sub_Type__c = 'Replacement';
            replacedOrd.SBQQ__Contracted__c = false;
            replacedOrd.Polaris_Fulfillment_Status__c = 'Completed';
            replacedOrd.Status = 'Activated';
            replacedOrd.Order_Status__c = 'Shipped';
            //orderInstance1.Program__c = 'Conversion';
            // replacedOrd.SBQQ__Quote__c = quoteObjNew.Id;
            replacedOrd.Actual_Order_Ship_Date__c = System.today().addDays(-30);
            replacedOrd.Order_Accepted_Timestamp__c = Datetime.newInstance(2025, 2, 20);
            replacedOrd.Line_Types__c = 'Conversion';
            replacedOrd.Welcome_letter_sent_for_the_first_time__c = true;
            
            List<Order_Item_Extension__c> oiExtension = new List<Order_Item_Extension__c>();
            //oiExtension.add(new Order_Item_Extension__c(Name = 'Test'+oi.id,Invoice_Number__c = oi.order.ordernumber, OI_ExternalID__c = oi.id, Order_Line_ID__c = oi.id, End_of_Paid_Term__c = system.today().addDays(90)));
            for (Orderitem oi : replacedOrd.orderitems) {
                oi.Previous_Transaction_Reference__c =
                    '[{\"usedEntitlementQuantity\":5.00,\"phantomOrderItemId\":null,\"orderItemId\":\"' +
                    lstofEnt[0].Order_Service_Item__c +
                    '\",\"orderItemRemainingQuantity\":5.00,\"entId\":\"' +
                    lstofEnt[0].id +
                    '\"}]';
                oi.SBQQ__Contracted__c = false;
                oi.Program__c = 'Conversion';
                oiExtension.add(
                    new Order_Item_Extension__c(
                        Name = 'Test' + oi.id,
                        Invoice_Number__c = oi.order.ordernumber,
                        OI_ExternalID__c = oi.id,
                        Order_Line_ID__c = oi.id,
                        End_of_Paid_Term__c = system.today().addDays(90)
                    )
                );
                lstofordItem.add(oi);
            }
            update lstofordItem;
            Test.starttest();
            update replacedOrd;
            //order ordertoupdate = new Order(id = replacedOrd.id,Line_Types__c = 'Conversion');
            //update ordertoupdate;
            insert oiExtension;
            
            ContractOrders replacedordtest = new ContractOrders();
            System.schedule('Test_Contract_Orders_Conversion', '0 0 * * * ?', replacedordtest);
            replacedordtest.execute(null);
            System.assert(replacedOrd.id != null);
            Test.stoptest();
        }
    }
    /**
    * @description method to test Refresh and Replacement orders
    */
    @isTest
    static void testRefreshAndReplacementOrder() {
        List<user> adminUser = [SELECT Id FROM User WHERE Email =:userEmail LIMIT 1];
        System.runAs(adminUser[0]) {
            List<Asset> lstofAsset = [SELECT Id, SerialNumber FROM Asset LIMIT 2];
            List<OrderItem> existingOrdItem = [SELECT id FROM OrderItem WHERE quantity != NULL LIMIT 1];
            List<SBQQ__QuoteLine__c> qliList = [SELECT id, Replacement_details__c FROM SBQQ__QuoteLine__c];
            List<OrderItem> lstofordItem = new List<OrderItem>();
            List<Scale_Entitlement__c> linkedAssets = new List<Scale_Entitlement__c>();
            List<Entitlement> lstofEnt = [SELECT id, Name, RecordTypeId, Type, AccountId,
                    Product__c, Product__r.Product_Type__c, Product__r.Edition__c,Order_Service_Item__r.Quantity, quantity__c, Order_Service_Item__c, AssetId,
                    StartDate, ServiceContractId, ContractLineItemId FROM Entitlement];
            Entitlement entWithoutScaleEnt;
            for (Entitlement ent : lstofEnt) {
                ent.startdate = System.today();
                ent.EndDate = System.today().addMonths(1);
                ent.Quantity__c = 10;
                ent.Order_Service_Item__c = existingOrdItem[0].Id;
                if(ent.Product__r.Edition__c == Constants.RSC_FOUNDATION_PRODUCT_TYPE){
                    ent.AssetId = lstofAsset[0].Id;
                    entWithoutScaleEnt = ent.clone();                                                                                                   
                }
                if(ent.Product__r.Product_Type__c == 'Foundation Edition'){
                    ent.AssetId = lstofAsset[0].Id;
                    continue;
                }
                linkedAssets.add(new Scale_Entitlement__c(Asset__c = lstofAsset[0].id, Entitlement__c = ent.id, Order_Product__c = ent.Order_Service_Item__c));
            }
            
            lstofent.add(entWithoutScaleEnt);
            
            upsert lstofent;
            String replacementDetails = '{"targetProductType" : "Hardware","skuStorageTierVal":null,"skuStorageBundleVal":null,"skuSFDCVal":null,"skuSelectedName":"RS-BT-EE-PE-PA","skuSelected":"01t6f00000O6dT0AAJ","skuM365HVal":null,"skuAttlasianVal":null,"SeamlessCutover":null,"rowValues":[{"UpgradeLines":null,"inactiveLines":[{"childrowId":null,"childQnty":270,"childEntId":"550VI00000938QkYAI"}],"selectedQty":300,"selectedAssetList":{"02i6f00000IfP9gAAF":"BB210464100059","02i6f00000IfPBSAA3":"BB210364100020","02i6f00000IrOTzAAN":"BB211364100028","02i6f00000IrOUJAA3":"BB211364100030"},"selectedAsset":"02i6f00000IrOUJAA3,02i6f00000IrOTzAAN,02i6f00000IfPBSAA3,02i6f00000IfP9gAAF","rowId":"2.1.0","entId":"550VI000007aYKAYA2","disposition":"Converted","selectedTerm":12}],"mode":"1to1"}';
            Integer Count1 = 0;
            for (SBQQ__QuoteLine__c qli : qliList) {
                qli.special_program__c = Count1 > 2 ? 'Refresh' : 'Conversion';
                qli.Replacement_details__c = replacementDetails;
                Count1++;
            }
            
            update qlilist;
            insert linkedAssets;
            Entitlement_Links__c entLink = new Entitlement_Links__c();
            entLink.Previous_Entitlement__c = lstofEnt[0].id;
            entLink.Renewed_Entitlement__c = lstofEnt[0].id;
            entLink.quantity__c = 10;
            //entLink.Renewal_Category__c = 'Converted';
            entLink.Type__c = 'Split-Surviving';
            insert entLink;
            
            Order replacedOrd = [
                SELECT
                id,
                Order_Sub_Type__c,
                SBQQ__Contracted__c,
                Polaris_Fulfillment_Status__c,
                Status,
                Order_Status__c,
                Actual_Order_Ship_Date__c,
                Welcome_letter_sent_for_the_first_time__c,
                (SELECT id, Enddate,Product2.Id,Product2.Edition__c,Product2.Product_Level__c, order.ordernumber, Previous_Transaction_Reference__c FROM orderitems)
                FROM Order
                LIMIT 1
            ];
            //replacedOrd.Order_Sub_Type__c = 'Replacement';
            replacedOrd.SBQQ__Contracted__c = false;
            replacedOrd.Polaris_Fulfillment_Status__c = 'Completed';
            replacedOrd.Status = 'Activated';
            replacedOrd.Order_Status__c = 'Shipped';
            //orderInstance1.Program__c = 'Conversion';
            // replacedOrd.SBQQ__Quote__c = quoteObjNew.Id;
            replacedOrd.Actual_Order_Ship_Date__c = System.today().addDays(-30);
            replacedOrd.Order_Accepted_Timestamp__c = Datetime.newInstance(2025, 2, 20);
            replacedOrd.Line_Types__c = 'Refresh';
            replacedOrd.Welcome_letter_sent_for_the_first_time__c = true;
            Test.starttest();
            update replacedOrd;
            
            //List<Order_Item_Extension__c> oiExtension = new List<Order_Item_Extension__c>();
            
            Set<Product2> productsToUpdate = new Set<Product2>();
            Integer count = 0;
            for (Orderitem oi : replacedOrd.orderitems) {
                oi.Previous_Transaction_Reference__c =
                    '[{\"usedEntitlementQuantity\":5.00,\"phantomOrderItemId\":null,\"orderItemId\":\"' +
                    lstofEnt[0].Order_Service_Item__c +
                    '\",\"orderItemRemainingQuantity\":5.00,\"entId\":\"' +
                    lstofEnt[0].id +
                    '\"}]';
                oi.SBQQ__Contracted__c = false;
                oi.Program__c = Count > 2 ? 'Refresh' : 'Conversion';
                if(oi.Program__c == 'Refresh' && !(oi.Product2.Edition__c == 'Foundation Edition' && oi.Product2.Product_Level__c == Null)){
                    productsToUpdate.add(new Product2(Id = oi.Product2Id,Product_Level__c = Constants.RSC_LOD_PRODUCT_LEVEL));
                }
                if(oi.Product2.Edition__c == 'Foundation Edition'){
                    oi.Program__c = 'Refresh';
                    productsToUpdate.add(new Product2(Id = oi.Product2Id,Product_Level__c = null));
                }
                oi.Upgraded_From__c = lstofAsset[0].SerialNumber;
                Oi.SerialNumber__c = lstofAsset[1].SerialNumber;
                //oiExtension.add(new Order_Item_Extension__c(Name = 'Test'+oi.id,Invoice_Number__c = oi.order.ordernumber, OI_ExternalID__c = oi.id, Order_Line_ID__c = oi.id, End_of_Paid_Term__c = oi.EndDate ));
                lstofordItem.add(oi);
                count++;
            }
            
            update new List<Product2> (productsToUpdate);
            update lstofordItem;
            
            ContractOrders replacedordtest = new ContractOrders();
            System.schedule('Test_Contract_Orders_Conversion', '0 0 * * * ?', replacedordtest);
            replacedordtest.execute(null);
            System.assert(replacedOrd.id != null);
            Test.stoptest();
        }
    }
    /**
    * @description method to test renewal orders with JSON
    */
    @isTest
    static void testRenewalOrdwithjson() {
        List<user> adminUser = [SELECT Id FROM User WHERE Email =:userEmail LIMIT 1];
        System.runAs(adminUser[0]) {
            List<ContractLineItem> cliList5 = [
                SELECT Id, Quantity, PricebookEntryId, ServiceContractId, UnitPrice, StartDate, SBQQSC__RenewalQuantity__c, SBQQSC__Product__c
                FROM ContractLineItem
                LIMIT 2
            ];
            Account customer = [SELECT Id, Name FROM Account WHERE Name = 'Customer' LIMIT 1];
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
            List<SBQQ__QuoteLine__c> qliList = [SELECT id, Replacement_details__c FROM SBQQ__QuoteLine__c];
            List<SBQQ__Quote__c> quoteList5 = [
                SELECT id, SBQQ__Opportunity2__c, SBQQ__SubscriptionTerm__c, Is_RWD_Polaris_Quote__c, SBQQ__PriceBook__c, SBQQ__Type__c
                FROM SBQQ__Quote__c
                LIMIT 10
            ];
            quoteList5[0].SBQQ__Type__c = 'Quote';
            quoteList5[0].Opportunity_Program__c = 'Refresh';
            quoteList5[1].SBQQ__Type__c = 'Renewal+Expansion';
            quoteList5[1].Opportunity_Program__c = 'Refresh';
            update quoteList5;
            List<Entitlement> lstofEnt = [
                SELECT id, Product__c, Order_Service_Item__r.Quantity, quantity__c, Order_Service_Item__c
                FROM Entitlement
                WHERE Order_Service_Item__r.Quantity > 10
                LIMIT 2
            ];
            for (Entitlement ent : lstofEnt) {
                ent.Quantity__c = ent.Order_Service_Item__r.Quantity;
                ent.Terminated_date__c = null;
            }
            update lstofent;
            
            String replacementDetails = '{"targetProductType" : "Hardware","skuStorageTierVal":null,"skuStorageBundleVal":null,"skuSFDCVal":null,"skuSelectedName":"RS-BT-EE-PE-PA","skuSelected":"01t6f00000O6dT0AAJ","skuM365HVal":null,"skuAttlasianVal":null,"SeamlessCutover":null,"rowValues":[{"UpgradeLines":null,"selectedQty":300,"inactiveLines":[{"childrowId":null,"childQnty":270,"childEntId":"550VI00000938QkYAI"}],"selectedAssetList":{"02i6f00000IfP9gAAF":"BB210464100059","02i6f00000IfPBSAA3":"BB210364100020","02i6f00000IrOTzAAN":"BB211364100028","02i6f00000IrOUJAA3":"BB211364100030"},"selectedAsset":"02i6f00000IrOUJAA3,02i6f00000IrOTzAAN,02i6f00000IfPBSAA3,02i6f00000IfP9gAAF","rowId":"2.1.0","entId":"550VI000007aYKAYA2","disposition":"Converted","selectedTerm":12}],"mode":"1to1"}';
            String replacementDetails1 = '{"targetProductType" : "Non-Hardware","skuStorageTierVal":null,"skuStorageBundleVal":null,"skuSFDCVal":null,"skuSelectedName":"RS-BT-EE-PE-PA","skuSelected":"01t6f00000O6dT0AAJ","skuM365HVal":null,"skuAttlasianVal":null,"SeamlessCutover":null,"rowValues":[{"UpgradeLines":null,"inactiveLines":[{"childrowId":null,"childQnty":270,"childEntId":"550VI00000938QkYAI"}] ,"selectedQty":300,"selectedAssetList":{"02i6f00000IfP9gAAF":"BB210464100059","02i6f00000IfPBSAA3":"BB210364100020","02i6f00000IrOTzAAN":"BB211364100028","02i6f00000IrOUJAA3":"BB211364100030"},"selectedAsset":"02i6f00000IrOUJAA3,02i6f00000IrOTzAAN,02i6f00000IfPBSAA3,02i6f00000IfP9gAAF","rowId":"2.1.0","entId":"550VI000007aYKAYA2","disposition":"Converted","selectedTerm":12}],"mode":"1to1"}';
            for (SBQQ__QuoteLine__c qli : qliList) {
                qli.Replacement_details__c = replacementDetails;
            }
            qlilist[0].Replacement_details__c = replacementDetails1;
            update qlilist;
            
            List<Product2> ProdToupdate = new List<Product2>();
            ProdToupdate.add(new Product2(Id = lstofEnt[0].Product__c, Edition__c = 'Business Edition Upgrade'));
            ProdToupdate.add(new Product2(Id = lstofEnt[1].Product__c, Edition__c = 'Business Edition Upgrade'));
            update ProdToupdate;
            
            Entitlement_Links__c entLink = new Entitlement_Links__c();
            entLink.Previous_Entitlement__c = lstofEnt[0].id;
            entLink.Renewed_Entitlement__c = lstofEnt[1].id;
            entLink.quantity__c = 10;
            entLink.Type__c = 'Upgrade';
            entLink.Renewal_Category__c = 'Upgraded';
            insert entLink;
            
            List<order> orderList5 = [
                SELECT
                id,
                OrderNumber,
                Status,
                Actual_Order_Ship_Date__c,
                SBQQ__Contracted__c,
                Polaris_Fulfillment_Status__c,
                AccountId,
                OpportunityId,
                Opportunity.Owner.Email,
                Order_Sub_Type__c,
                SBQQ__Quote__c,
                SBQQ__Quote__r.SBQQ__Type__c,
                Program__c,
                ProcessType__c,
                SBQQ__Quote__r.SBQQ__Opportunity2__c,
                Opportunity.Name,
                Opportunity.CloseDate,
                RecordTypeId,
                (
                    SELECT
                    id,
                    quantity,
                    product2.Product_Subtype__c,
                    product2.Product_Level__c,
                    product2.Product_Type__c,
                    product2.Name,
                    Upgraded_From__c,
                    SerialNumber__c,
                    Program__c,
                    Previous_Contract_Line_Items__c,
                    SBQQ__QuoteLine__r.SBQQ__Renewal__c,
                    SBQQ__QuoteLine__c,
                    SBQQ__QuoteLine__r.SBQQ__RenewedAsset__c,
                    SBQQ__QuoteLine__r.SBQQ__Existing__c
                    FROM OrderItems
                )
                FROM Order
                LIMIT 1
            ];
            orderList5[0].SBQQ__Contracted__c = false;
            orderList5[0].Polaris_Fulfillment_Status__c = 'Completed';
            orderList5[0].Status = 'Activated';
            orderList5[0].Order_Status__c = 'Shipped';
            orderList5[0].Program__c = 'Refresh';
            orderList5[0].Actual_Order_Ship_Date__c = System.today();
            orderList5[0].Welcome_letter_sent_for_the_first_time__c = true;
            orderList5[0].SBQQ__Quote__c = quoteList5[0].Id;
            orderList5[0].Order_Sub_Type__c = 'Renewal';
            
            //List<Order> ordNew=[SELECT Id,Name from Order WHERE Order_Sub_Type__c='Renewal' LIMIT 2];
            
            ServiceContract objSC1Obj = new ServiceContract(
                Name = 'ServiceContractTest1',
                AccountId = customer.Id,
                StartDate = Date.today(),
                Term = 36,
                pricebook2Id = Test.getStandardPricebookId(),
                SBQQSC__Opportunity__c = opp.Id,
                SBQQSC__Order__c = orderList5[0].Id,
                SBQQSC__Quote__c = quoteList5[0].Id
            );
            insert objSC1Obj;
            List<Asset> assestInsList5 = [
                SELECT id, Name, SerialNumber, serial_number__c, AccountId, Product2Id
                FROM Asset
                LIMIT 1
            ];
            List<OrderItem> lstofoi = new List<Orderitem>();
            Map<Id, SBQQ__QuoteLine__c> mapofQli = new Map<Id, SBQQ__QuoteLine__c>();
            for (Orderitem oi : orderList5[0].orderitems) {
                oi.Previous_Transaction_Reference__c =
                    '[{\"usedEntitlementQuantity\":5.00,\"phantomOrderItemId\":null,\"orderItemId\":\"' +
                    lstofEnt[0].Order_Service_Item__c +
                    '\",\"orderItemRemainingQuantity\":null,\"entId\":\"' +
                    lstofEnt[0].id +
                    '\"}]';
                oi.SBQQ__Contracted__c = false;
                lstofoi.add(oi);
                if (oi.SBQQ__QuoteLine__c != null && !mapofQli.containskey(oi.SBQQ__QuoteLine__c)) {
                    mapofQli.put(
                        oi.SBQQ__QuoteLine__c,
                        new SBQQ__QuoteLine__c(id = oi.SBQQ__QuoteLine__c, SBQQ__Renewal__c = true, SBQQ__Existing__c = true, SBQQ__RenewedAsset__c = assestInsList5[0].Id)
                    );
                }
            }
            update mapofQli.values();
            update lstofoi;
            Test.startTest();
            update orderList5;
            ContractOrders batch = new ContractOrders();
            batch.execute(null);
            // DataCorrectionModuleHandler.splitUpgradeDeltaSkusBasedOnQty();
            System.assertEquals(1, orderList5.size());
            Test.stopTest();
        }
    }
    /**
    * @description method to renewal orders with JSON
    */
    @isTest
    static void testRenewalOrdwithJsonUseCase2() {
        List<user> adminUser = [SELECT Id FROM User WHERE Email =:userEmail LIMIT 1];
        System.runAs(adminUser[0]) {
            List<ContractLineItem> cliList5 = [
                SELECT Id, Quantity, PricebookEntryId, ServiceContractId, UnitPrice, StartDate, SBQQSC__RenewalQuantity__c, SBQQSC__Product__c
                FROM ContractLineItem
                LIMIT 2
            ];
            Account customer = [SELECT Id, Name FROM Account WHERE Name = 'Customer' LIMIT 1];
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
            List<SBQQ__QuoteLine__c> qliList = [SELECT id, Replacement_details__c FROM SBQQ__QuoteLine__c];
            List<SBQQ__Quote__c> quoteList5 = [
                SELECT id, SBQQ__Opportunity2__c, SBQQ__SubscriptionTerm__c, Is_RWD_Polaris_Quote__c, SBQQ__PriceBook__c, SBQQ__Type__c
                FROM SBQQ__Quote__c
                LIMIT 10
            ];
            quoteList5[0].SBQQ__Type__c = 'Quote';
            quoteList5[0].Opportunity_Program__c = 'Refresh';
            quoteList5[1].SBQQ__Type__c = 'Renewal+Expansion';
            quoteList5[1].Opportunity_Program__c = 'Refresh';
            update quoteList5;
            List<Entitlement> lstofEnt = [SELECT id, Order_Service_Item__r.Quantity, quantity__c, Order_Service_Item__c FROM Entitlement];
            for (Entitlement ent : lstofEnt) {
                ent.Quantity__c = ent.Order_Service_Item__r.Quantity;
                ent.Terminated_date__c = System.today();
            }
            update lstofent;
            
            String replacementDetails = '{"targetProductType" : "Hardware","skuStorageTierVal":null,"skuStorageBundleVal":null,"skuSFDCVal":null,"skuSelectedName":"RS-BT-EE-PE-PA","skuSelected":"01t6f00000O6dT0AAJ","skuM365HVal":null,"skuAttlasianVal":null,"SeamlessCutover":null,"rowValues":[{"UpgradeLines":null, "inactiveLines":[{"childrowId":null,"childQnty":270,"childEntId":"550VI00000938QkYAI"}],"selectedQty":300,"selectedAssetList":{"02i6f00000IfP9gAAF":"BB210464100059","02i6f00000IfPBSAA3":"BB210364100020","02i6f00000IrOTzAAN":"BB211364100028","02i6f00000IrOUJAA3":"BB211364100030"},"selectedAsset":"02i6f00000IrOUJAA3,02i6f00000IrOTzAAN,02i6f00000IfPBSAA3,02i6f00000IfP9gAAF","rowId":"2.1.0","entId":"550VI000007aYKAYA2","disposition":"Converted","selectedTerm":12}],"mode":"1to1"}';
            for (SBQQ__QuoteLine__c qli : qliList) {
                qli.Replacement_details__c = replacementDetails;
            }
            
            update qlilist;
            
            Entitlement_Links__c entLink = new Entitlement_Links__c();
            entLink.Previous_Entitlement__c = lstofEnt[0].id;
            entLink.Renewed_Entitlement__c = lstofEnt[0].id;
            entLink.quantity__c = 10;
            entLink.Renewal_Category__c = 'Upgraded';
            entLink.Type__c = 'Upgrade';
            insert entLink;
            
            List<order> orderList5 = [
                SELECT
                id,
                OrderNumber,
                Status,
                Actual_Order_Ship_Date__c,
                SBQQ__Contracted__c,
                Polaris_Fulfillment_Status__c,
                AccountId,
                OpportunityId,
                Opportunity.Owner.Email,
                Order_Sub_Type__c,
                SBQQ__Quote__c,
                SBQQ__Quote__r.SBQQ__Type__c,
                Program__c,
                ProcessType__c,
                SBQQ__Quote__r.SBQQ__Opportunity2__c,
                Opportunity.Name,
                Opportunity.CloseDate,
                RecordTypeId,
                (
                    SELECT
                    id,
                    quantity,
                    product2.Product_Subtype__c,
                    product2.Product_Level__c,
                    product2.Product_Type__c,
                    product2.Name,
                    Upgraded_From__c,
                    SerialNumber__c,
                    Program__c,
                    Previous_Contract_Line_Items__c,
                    SBQQ__QuoteLine__r.SBQQ__Renewal__c,
                    SBQQ__QuoteLine__c,
                    SBQQ__QuoteLine__r.SBQQ__RenewedAsset__c,
                    SBQQ__QuoteLine__r.SBQQ__Existing__c
                    FROM OrderItems
                )
                FROM Order
                LIMIT 1
            ];
            orderList5[0].SBQQ__Contracted__c = false;
            orderList5[0].Polaris_Fulfillment_Status__c = 'Completed';
            orderList5[0].Status = 'Activated';
            orderList5[0].Order_Status__c = 'Shipped';
            orderList5[0].Program__c = 'Refresh';
            orderList5[0].Actual_Order_Ship_Date__c = System.today();
            orderList5[0].Welcome_letter_sent_for_the_first_time__c = true;
            orderList5[0].SBQQ__Quote__c = quoteList5[0].Id;
            orderList5[0].Order_Sub_Type__c = 'Renewal';
            
            //List<Order> ordNew=[SELECT Id,Name from Order WHERE Order_Sub_Type__c='Renewal' LIMIT 2];
            
            ServiceContract objSC1Obj = new ServiceContract(
                Name = 'ServiceContractTest1',
                AccountId = customer.Id,
                StartDate = Date.today(),
                Term = 36,
                pricebook2Id = Test.getStandardPricebookId(),
                SBQQSC__Opportunity__c = opp.Id,
                SBQQSC__Order__c = orderList5[0].Id,
                SBQQSC__Quote__c = quoteList5[0].Id
            );
            insert objSC1Obj;
            List<Asset> assestInsList5 = [
                SELECT id, Name, SerialNumber, serial_number__c, AccountId, Product2Id
                FROM Asset
                LIMIT 1
            ];
            List<OrderItem> lstofoi = new List<Orderitem>();
            Map<Id, SBQQ__QuoteLine__c> mapofQli = new Map<Id, SBQQ__QuoteLine__c>();
            for (Orderitem oi : orderList5[0].orderitems) {
                oi.Previous_Transaction_Reference__c =
                    '[{\"usedEntitlementQuantity\":5.00,\"phantomOrderItemId\":null,\"orderItemId\":\"' +
                    lstofEnt[0].Order_Service_Item__c +
                    '\",\"orderItemRemainingQuantity\":null,\"entId\":\"' +
                    lstofEnt[0].id +
                    '\"}]';
                oi.SBQQ__Contracted__c = false;
                lstofoi.add(oi);
                if (oi.SBQQ__QuoteLine__c != null && !mapofQli.containskey(oi.SBQQ__QuoteLine__c)) {
                    mapofQli.put(
                        oi.SBQQ__QuoteLine__c,
                        new SBQQ__QuoteLine__c(id = oi.SBQQ__QuoteLine__c, SBQQ__Renewal__c = true, SBQQ__Existing__c = true, SBQQ__RenewedAsset__c = assestInsList5[0].Id)
                    );
                }
            }
            update mapofQli.values();
            update lstofoi;
            Test.startTest();
            update orderList5;
            ContractOrders batch = new ContractOrders();
            batch.execute(null);
            System.assertEquals(1, orderList5.size());
            Test.stopTest();
        }
    }
    
    @isTest
    static void getSurvivingEntTest() {
        List<user> adminUser = [SELECT Id FROM User WHERE Email = :userEmail LIMIT 1];
        System.runAs(adminUser[0]) {
            List<Asset> lstofAsset = [SELECT id FROM Asset LIMIT 1];
            List<OrderItem> existingOrdItem = [SELECT id FROM OrderItem WHERE quantity != NULL LIMIT 1];
            List<SBQQ__QuoteLine__c> qliList = [SELECT id, Replacement_details__c FROM SBQQ__QuoteLine__c];
            List<OrderItem> lstofordItem = new List<OrderItem>();
            List<Scale_Entitlement__c> linkedAssets = new List<Scale_Entitlement__c>();
            List<Entitlement> lstofEnt = [SELECT id, Order_Service_Item__r.Quantity, quantity__c, Order_Service_Item__c FROM Entitlement];
            Integer counter = 0;
            for (Entitlement ent : lstofEnt) {
                ent.Order_Service_Item__c = existingOrdItem[0].Id;
                if(counter == 0){
                    ent.startdate = System.today().addMonths(-2);
                    ent.EndDate = System.today().addMonths(-1);
                    ent.Terminated_Date__c = ent.EndDate;
                    ent.Quantity__c = 10;
                    ent.Renewal_Category__c = 'Converted';    
                }
                counter++;
                linkedAssets.add(new Scale_Entitlement__c(Asset__c = lstofAsset[0].id, Entitlement__c = ent.id, Order_Product__c = ent.Order_Service_Item__c));
            }
            update lstofent;
            String replacementDetails = '{"targetProductType" : "Hardware","skuStorageTierVal":null,"skuStorageBundleVal":null,"skuSFDCVal":null,"skuSelectedName":"RS-BT-EE-PE-PA","skuSelected":"01t6f00000O6dT0AAJ","skuM365HVal":null,"skuAttlasianVal":null,"SeamlessCutover":null,"rowValues":[{"UpgradeLines":null, "inactiveLines":[{"childrowId":null,"childQnty":270,"childEntId":"550VI00000938QkYAI"}],"selectedQty":300,"selectedAssetList":{"02i6f00000IfP9gAAF":"BB210464100059","02i6f00000IfPBSAA3":"BB210364100020","02i6f00000IrOTzAAN":"BB211364100028","02i6f00000IrOUJAA3":"BB211364100030"},"selectedAsset":"02i6f00000IrOUJAA3,02i6f00000IrOTzAAN,02i6f00000IfPBSAA3,02i6f00000IfP9gAAF","rowId":"2.1.0","entId":"550VI000007aYKAYA2","disposition":"Converted","selectedTerm":12}],"mode":"1to1"}';
            
            for (SBQQ__QuoteLine__c qli : qliList) {
                qli.Replacement_details__c = replacementDetails;
                qli.special_program__c = 'Conversion';
            }
            
            update qlilist;
            insert linkedAssets;
            List<Entitlement_Links__c> entLinks = new List<Entitlement_Links__c>();
            Entitlement_Links__c entLink = new Entitlement_Links__c();
            entLink.Previous_Entitlement__c = lstofEnt[0].id;
            entLink.Renewed_Entitlement__c = lstofEnt[0].id;
            entLink.quantity__c = 10;
            entLink.Renewal_Category__c = 'Converted';
            entLink.Type__c = Constants.ENT_LINK_TYPE_SPLIT_RENEWAL;
            entLinks.add(entLink);
            
            Entitlement_Links__c entLink1 = new Entitlement_Links__c();
            entLink1.Previous_Entitlement__c = lstofEnt[0].id;
            entLink1.Renewed_Entitlement__c = lstofEnt[1].id;
            entLink1.quantity__c = 10;
            entLink1.Type__c = Constants.ENT_LINK_TYPE_SPLIT_SURVIVING;
            entLinks.add(entLink1);
            insert entLinks;
            
            SplitOrder sp = new SplitOrder();
            Order replacedOrd = [
                SELECT
                id,
                Order_Sub_Type__c,
                SBQQ__Contracted__c,
                Polaris_Fulfillment_Status__c,
                Status,
                Order_Status__c,
                Actual_Order_Ship_Date__c,
                Welcome_letter_sent_for_the_first_time__c,
                (SELECT id, Enddate, order.ordernumber, Previous_Transaction_Reference__c FROM orderitems)
                FROM Order
                LIMIT 1
            ];
            //replacedOrd.Order_Sub_Type__c = 'Replacement';
            replacedOrd.SBQQ__Contracted__c = false;
            replacedOrd.Polaris_Fulfillment_Status__c = 'Completed';
            replacedOrd.Status = 'Activated';
            replacedOrd.Order_Status__c = 'Shipped';
            //orderInstance1.Program__c = 'Conversion';
            // replacedOrd.SBQQ__Quote__c = quoteObjNew.Id;
            replacedOrd.Actual_Order_Ship_Date__c = System.today().addDays(-30);
            replacedOrd.Order_Accepted_Timestamp__c = Datetime.newInstance(2025, 2, 20);
            replacedOrd.Line_Types__c = 'Conversion';
            replacedOrd.Welcome_letter_sent_for_the_first_time__c = true;
            
            List<Order_Item_Extension__c> oiExtension = new List<Order_Item_Extension__c>();
            //oiExtension.add(new Order_Item_Extension__c(Name = 'Test'+oi.id,Invoice_Number__c = oi.order.ordernumber, OI_ExternalID__c = oi.id, Order_Line_ID__c = oi.id, End_of_Paid_Term__c = system.today().addDays(90)));
            for (Orderitem oi : replacedOrd.orderitems) {
                oi.Previous_Transaction_Reference__c =
                    '[{\"usedEntitlementQuantity\":5.00,\"phantomOrderItemId\":null,\"orderItemId\":\"' +
                    lstofEnt[0].Order_Service_Item__c +
                    '\",\"orderItemRemainingQuantity\":5.00,\"entId\":\"' +
                    lstofEnt[0].id +
                    '\"}]';
                oi.SBQQ__Contracted__c = false;
                oi.Program__c = 'Conversion';
                oiExtension.add(
                    new Order_Item_Extension__c(
                        Name = 'Test' + oi.id,
                        Invoice_Number__c = oi.order.ordernumber,
                        OI_ExternalID__c = oi.id,
                        Order_Line_ID__c = oi.id,
                        End_of_Paid_Term__c = system.today().addDays(90)
                    )
                );
                lstofordItem.add(oi);
            }
            update lstofordItem;
            Test.starttest();
            update replacedOrd;
            insert oiExtension;
            
            ContractOrders replacedordtest = new ContractOrders();
            System.schedule('Test_Contract_Orders_Conversion', '0 0 * * * ?', replacedordtest);
            replacedordtest.execute(null);
            System.assert(replacedOrd.id != null);
            Test.stoptest();
        }
    }
    
    @isTest
    static void testEntSplitBasedOnReplacementCase1() {
        List<user> adminUser = [SELECT Id FROM User WHERE Email = :userEmail LIMIT 1];
        System.runAs(adminUser[0]) {
            List<Asset> lstofAsset = [SELECT id FROM Asset LIMIT 1];
            List<OrderItem> existingOrdItem = [SELECT id FROM OrderItem WHERE quantity != NULL LIMIT 1];
            List<SBQQ__QuoteLine__c> qliList = [SELECT id, Replacement_details__c FROM SBQQ__QuoteLine__c];
            List<OrderItem> lstofordItem = new List<OrderItem>();
            List<Scale_Entitlement__c> linkedAssets = new List<Scale_Entitlement__c>();
            List<Entitlement> lstofEnt = [SELECT id, Order_Service_Item__r.Quantity, quantity__c, Order_Service_Item__c FROM Entitlement];
            Integer counter = 0;
            for (Entitlement ent : lstofEnt) {
                ent.startdate = System.today();
                ent.EndDate = System.today().addMonths(1);
                ent.Quantity__c = 70;
                ent.Order_Service_Item__c = existingOrdItem[0].Id; 
                linkedAssets.add(new Scale_Entitlement__c(Asset__c = lstofAsset[0].id, Entitlement__c = ent.id, Order_Product__c = ent.Order_Service_Item__c));
            }
            update lstofent;
            String replacementDetails = '{"targetProductType" : "Hardware","skuStorageTierVal":null,"skuStorageBundleVal":null,"skuSFDCVal":null,"skuSelectedName":"RS-BT-EE-PE-PA","skuSelected":"01t6f00000O6dT0AAJ","skuM365HVal":null,"skuAttlasianVal":null,"SeamlessCutover":null,"rowValues":[{"UpgradeLines":null,"selectedQty":300,"inactiveLines":[{"childrowId":null,"childQnty":270,"childEntId":"550VI00000938QkYAI"}] ,"selectedAssetList":{"02i6f00000IfP9gAAF":"BB210464100059","02i6f00000IfPBSAA3":"BB210364100020","02i6f00000IrOTzAAN":"BB211364100028","02i6f00000IrOUJAA3":"BB211364100030"},"selectedAsset":"02i6f00000IrOUJAA3,02i6f00000IrOTzAAN,02i6f00000IfPBSAA3,02i6f00000IfP9gAAF","rowId":"2.1.0","entId":"550VI000007aYKAYA2","disposition":"Converted","selectedTerm":12}],"mode":"1to1"}';
            
            for (SBQQ__QuoteLine__c qli : qliList) {
                qli.Replacement_details__c = replacementDetails;
                qli.special_program__c = 'Conversion';
            }
            
            update qlilist;
            insert linkedAssets;
            Entitlement_Links__c entLink = new Entitlement_Links__c();
            entLink.Previous_Entitlement__c = lstofEnt[0].id;
            entLink.Renewed_Entitlement__c = lstofEnt[0].id;
            entLink.quantity__c = 70;
            entLink.Type__c = 'Split-Surviving';
            insert entLink;
            SplitOrder sp = new SplitOrder();
            Order replacedOrd = [
                SELECT
                id,
                Order_Sub_Type__c,
                SBQQ__Contracted__c,
                Polaris_Fulfillment_Status__c,
                Status,
                Order_Status__c,
                Actual_Order_Ship_Date__c,
                Welcome_letter_sent_for_the_first_time__c,
                (SELECT id, Enddate, order.ordernumber, Previous_Transaction_Reference__c FROM orderitems)
                FROM Order
                LIMIT 1
            ];
            replacedOrd.SBQQ__Contracted__c = false;
            replacedOrd.Polaris_Fulfillment_Status__c = 'Completed';
            replacedOrd.Status = 'Activated';
            replacedOrd.Order_Status__c = 'Shipped';
            replacedOrd.Actual_Order_Ship_Date__c = System.today().addDays(-30);
            replacedOrd.Order_Accepted_Timestamp__c = Datetime.newInstance(2025, 2, 20);
            replacedOrd.Line_Types__c = 'Conversion';
            replacedOrd.Welcome_letter_sent_for_the_first_time__c = true;
            
            List<Order_Item_Extension__c> oiExtension = new List<Order_Item_Extension__c>();
            //oiExtension.add(new Order_Item_Extension__c(Name = 'Test'+oi.id,Invoice_Number__c = oi.order.ordernumber, OI_ExternalID__c = oi.id, Order_Line_ID__c = oi.id, End_of_Paid_Term__c = system.today().addDays(90)));
            for (Orderitem oi : replacedOrd.orderitems) {
                oi.Previous_Transaction_Reference__c =
                    '[{\"usedEntitlementQuantity\":5.00,\"phantomOrderItemId\":null,\"orderItemId\":\"' +
                    lstofEnt[0].Order_Service_Item__c +
                    '\",\"orderItemRemainingQuantity\":5.00,\"entId\":\"' +
                    lstofEnt[0].id +
                    '\"}]';
                oi.SBQQ__Contracted__c = false;
                oi.Program__c = 'Conversion';
                oiExtension.add(
                    new Order_Item_Extension__c(
                        Name = 'Test' + oi.id,
                        Invoice_Number__c = oi.order.ordernumber,
                        OI_ExternalID__c = oi.id,
                        Order_Line_ID__c = oi.id,
                        End_of_Paid_Term__c = system.today().addDays(90)
                    )
                );
                lstofordItem.add(oi);
            }
            update lstofordItem;
            Test.starttest();
            update replacedOrd;
            insert oiExtension;
            ReplacementEntSplitManager.isTestSplit = false;
            ContractOrders replacedordtest = new ContractOrders();
            System.schedule('Test_Contract_Orders_Conversion', '0 0 * * * ?', replacedordtest);
            replacedordtest.execute(null);
            System.assert(replacedOrd.id != null);
            Test.stoptest();
        }
    }
    
    @isTest
    static void testEntSplitBasedOnReplacementCase2() {
        List<user> adminUser = [SELECT Id FROM User WHERE Email = :userEmail LIMIT 1];
        System.runAs(adminUser[0]) {
            List<Asset> lstofAsset = [SELECT id FROM Asset LIMIT 1];
            List<OrderItem> existingOrdItem = [SELECT id FROM OrderItem WHERE quantity != NULL LIMIT 1];
            List<SBQQ__QuoteLine__c> qliList = [SELECT id, Replacement_details__c FROM SBQQ__QuoteLine__c];
            List<OrderItem> lstofordItem = new List<OrderItem>();
            List<Scale_Entitlement__c> linkedAssets = new List<Scale_Entitlement__c>();
            List<Entitlement> lstofEnt = [SELECT id, Order_Service_Item__r.Quantity, quantity__c, Order_Service_Item__c FROM Entitlement];
            Integer counter = 0;
            for (Entitlement ent : lstofEnt) {
                ent.startdate = System.today();
                ent.EndDate = System.today().addMonths(1);
                ent.Quantity__c = 70;
                ent.Order_Service_Item__c = existingOrdItem[0].Id;
                ent.Terminated_Date__c = ent.EndDate;
                linkedAssets.add(new Scale_Entitlement__c(Asset__c = lstofAsset[0].id, Entitlement__c = ent.id, Order_Product__c = ent.Order_Service_Item__c));
            }
            update lstofent;
             Map<String, Entitlement> entToUpsert = new  Map<String, Entitlement>();
            ReplacementEntSplitManager.EntitlementDetails wrapDet = new ReplacementEntSplitManager.EntitlementDetails();
            wrapDet.transactionType = 'Upgraded';
            wrapDet.inactiveEntsToTerminate = new Set<Id>{lstofEnt[0].Id};
            List<Entitlement> inactiveEntList = new List<Entitlement>{lstofEnt[0]};
            Map<Id, Entitlement> inactiveEntById = new Map<Id, Entitlement>(inactiveEntList);
            ReplacementEntSplitManager.prepareInactiveEntitlementUpdates(lstofEnt[0].Id, wrapDet, entToUpsert, inactiveEntById);
            String replacementDetails = '{"targetProductType" : "Hardware","skuStorageTierVal":null,"skuStorageBundleVal":null,"skuSFDCVal":null,"skuSelectedName":"RS-BT-EE-PE-PA","skuSelected":"01t6f00000O6dT0AAJ","skuM365HVal":null,"skuAttlasianVal":null,"SeamlessCutover":null,"rowValues":[{"UpgradeLines":null, "inactiveLines":[{"childrowId":null,"childQnty":270,"childEntId":"550VI00000938QkYAI"}],"selectedQty":300,"selectedAssetList":{"02i6f00000IfP9gAAF":"BB210464100059","02i6f00000IfPBSAA3":"BB210364100020","02i6f00000IrOTzAAN":"BB211364100028","02i6f00000IrOUJAA3":"BB211364100030"},"selectedAsset":"02i6f00000IrOUJAA3,02i6f00000IrOTzAAN,02i6f00000IfPBSAA3,02i6f00000IfP9gAAF","rowId":"2.1.0","entId":"550VI000007aYKAYA2","disposition":"Converted","selectedTerm":12}],"mode":"1to1"}';
            
            for (SBQQ__QuoteLine__c qli : qliList) {
                qli.Replacement_details__c = replacementDetails;
                qli.special_program__c = 'Conversion';
            }
            
            update qlilist;
            insert linkedAssets;
            Entitlement_Links__c entLink = new Entitlement_Links__c();
            entLink.Previous_Entitlement__c = lstofEnt[0].id;
            entLink.Renewed_Entitlement__c = lstofEnt[0].id;
            entLink.quantity__c = 70;
            entLink.Type__c = 'Split-Surviving';
            insert entLink;
            SplitOrder sp = new SplitOrder();
            Order replacedOrd = [
                SELECT
                id,
                Order_Sub_Type__c,
                SBQQ__Contracted__c,
                Polaris_Fulfillment_Status__c,
                Status,
                Order_Status__c,
                Actual_Order_Ship_Date__c,
                Welcome_letter_sent_for_the_first_time__c,
                (SELECT id, Enddate, order.ordernumber, Previous_Transaction_Reference__c FROM orderitems)
                FROM Order
                LIMIT 1
            ];
            replacedOrd.SBQQ__Contracted__c = false;
            replacedOrd.Polaris_Fulfillment_Status__c = 'Completed';
            replacedOrd.Status = 'Activated';
            replacedOrd.Order_Status__c = 'Shipped';
            replacedOrd.Actual_Order_Ship_Date__c = System.today().addDays(-30);
            replacedOrd.Order_Accepted_Timestamp__c = Datetime.newInstance(2025, 2, 20);
            replacedOrd.Line_Types__c = 'Conversion';
            replacedOrd.Welcome_letter_sent_for_the_first_time__c = true;
            
            List<Order_Item_Extension__c> oiExtension = new List<Order_Item_Extension__c>();
            //oiExtension.add(new Order_Item_Extension__c(Name = 'Test'+oi.id,Invoice_Number__c = oi.order.ordernumber, OI_ExternalID__c = oi.id, Order_Line_ID__c = oi.id, End_of_Paid_Term__c = system.today().addDays(90)));
            for (Orderitem oi : replacedOrd.orderitems) {
                oi.Previous_Transaction_Reference__c =
                    '[{\"usedEntitlementQuantity\":5.00,\"phantomOrderItemId\":null,\"orderItemId\":\"' +
                    lstofEnt[0].Order_Service_Item__c +
                    '\",\"orderItemRemainingQuantity\":5.00,\"entId\":\"' +
                    lstofEnt[0].id +
                    '\"}]';
                oi.SBQQ__Contracted__c = false;
                oi.Program__c = 'Conversion';
                oiExtension.add(
                    new Order_Item_Extension__c(
                        Name = 'Test' + oi.id,
                        Invoice_Number__c = oi.order.ordernumber,
                        OI_ExternalID__c = oi.id,
                        Order_Line_ID__c = oi.id,
                        End_of_Paid_Term__c = system.today().addDays(90)
                    )
                );
                lstofordItem.add(oi);
            }
            update lstofordItem;
            Test.starttest();
            update replacedOrd;
            insert oiExtension;
            ReplacementEntSplitManager.isTestSplit = false;
            ContractOrders replacedordtest = new ContractOrders();
            System.schedule('Test_Contract_Orders_Conversion', '0 0 * * * ?', replacedordtest);
            replacedordtest.execute(null);
            System.assert(replacedOrd.id != null);
            Test.stoptest();
        }
    }
    
    @isTest
    static void testEntSplitManager(){
        List<user> adminUser = [SELECT Id FROM User WHERE Email = :userEmail LIMIT 1];
        System.runAs(adminUser[0]) {
            Order ordRec = [SELECT Id FROM Order LIMIT 1];
            ordRec.Order_Accepted_Timestamp__c = System.Today();
            ordRec.Actual_Order_Ship_Date__c = System.today().addDays(-30);
            update ordRec;
        	Map<Id, OrderItem> orderItemDetById = new Map<Id, OrderItem>([SELECT
                                                                          id,
                                                                          Product2.SBQQSC__EntitlementConversion__c,
                                                                          SBQQ__RequiredBy__c,
                                                                          Previous_Transaction_Reference__c,
                                                                          order.is_Amendment_Order__c,
                                                                          OrderId,
                                                                          Line_Type__c,
                                                                          Order.Associated_Order_Numbers__c,
                                                                          Order.OpportunityId,
                                                                          ServiceDate,
                                                                          EndDate,
                                                                          Global_Commit_Split_ID__c,
                                                                          SBQQ__QuotedQuantity__c,
                                                                          Support_Start_Date__c,
                                                                          Order.Actual_Order_Ship_Date__c,
                                                                          SBQQ__QuoteLine__r.Replacement_Details__c,
                                                                          SBQQ__QuoteLine__r.SubscribedAssetNames__c,
                                                                          Product2.Bundle_Features__c,
                                                                          Product2.License_Category__c,
                                                                          quantity,
                                                                          product2.Product_Subtype__c,
                                                                          product2.Product_Level__c,
                                                                          product2.Product_Type__c,
                                                                          product2.Name,
                                                                          Upgraded_From__c,
                                                                          SerialNumber__c,
                                                                          Program__c,
                                                                          Previous_Contract_Line_Items__c,
                                                                          Global_Commit_ID__c,
                                                                          Product2Id,
                                                                          Order.Order_Sub_Type__c,
                                                                          Order.Line_Types__c,
                                                                          Order.Order_Accepted_Timestamp__c
                                                                          FROM OrderItem
                                                                         ]);

            Schema.SObjectType objectType = Entitlement.getSObjectType();
            List<String> entFields = new List<String>(objectType.getDescribe().fields.getMap().keySet());
            String soqlStr = 
                'SELECT Order_Service_Item__r.SBQQ__OrderedQuantity__c,Order_Service_Item__r.product2.Upgrade_Path__c,Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c,Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.Usable_Capacity__c,Order_Service_Item__r.Entitlement_Id__c, Order_Service_Item__r.SBQQ__QuoteLine__r.Line_Type__c,Order_Service_Item__r.Product2.Custom_Renewal_Attributes__c, Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Type__c, ContractLineItem.Resync_Line__c, Order_Service_Item__r.TPH_Quantity__c, ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__c, ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.Arroyo_Subscribed_Asset_Name__c, ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SubscribedAssetNames__c,Order_Service_Item__r.Order.Is_RWD_Polaris_Quote__c,Order_Service_Item__r.Order.Type,Order_Service_Item__r.Order.Order_Status__c,ContractLineItem.SBQQSC__QuoteLine__r.SubscribedAssetNames__c,Order_Service_Item__r.SBQQ__RequiredBy__c,Order_Service_Item__r.product2.SBQQSC__EntitlementConversion__c,ContractLineItem.SBQQSC__QuoteLine__r.Arroyo_Subscribed_Asset_Name__c,Order_Service_Item__r.Previous_Contract_Line_Items__c,ContractLineItem.SBQQSC__QuoteLine__r.Subscribed_Asset_Name__c,ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.Subscribed_Asset_Name__c,asset.SerialNumber,asset.Program__c,asset.UsageEndDate,asset.serial_number__c,Order_Service_Item__r.SerialNumber__c,Order_Service_Item__r.Quantity,Order_Service_Item__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,Order_Service_Item__r.Product2Id,Order_Service_Item__r.Order.Order_Sub_Type__c,Order_Service_Item__r.SBQQ__QuoteLine__r.Disposition_Reason__c,Order_Service_Item__r.product2.Product_Level__c,Product__r.Product_Type__c, Product__r.Product_Level__c,Order_Service_Item__r.Order.Program__c,' + //RM
                'Order_Service_Item__r.Order.Actual_Order_Ship_Date__c,Product__r.Name,Product__r.Product_Subtype__c,Product__r.License_Category__c, ContractLineItem.SBQQSC__RequiredById__c,ContractLineItem.Product_Category__c, Order_Service_Item__r.Upgraded_From__c,Order_Service_Item__r.Product2.Product_Subtype__c, Order_Service_Item__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQSC__ContractLineItem__c,' +
                'Order_Service_Item__r.Order.SBQQ__Quote__c,Order_Service_Item__r.OrderId,Order_Service_Item__r.product2.ProductCode,Order_Service_Item__r.Program__c,ContractLineItem.LineItemNumber, ContractLineItem.SBQQSC__OrderProduct__r.Order.OpportunityId, ContractLineItem.SBQQSC__OrderProduct__r.Order.Opportunity.Name,ContractLineItem.SBQQSC__OrderProduct__r.Order.Order_Sub_Type__c,Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c, Order_Service_Item__r.SBQQ__QuoteLine__c,ContractLineItem.SBQQSC__Product__r.Product_Level__c, ContractLineItem.SBQQSC__Product__r.Product_Type__c,ContractLineItem.SBQQSC__Product__r.Product_Subtype__c,ContractLineItem.SBQQSC__TerminatedDate__c,ContractLineItem.Quantity,ContractLineItem.SBQQSC__RenewalQuantity__c,ContractLineItem.SBQQSC__Quantity__c,ContractLineItem.ServiceContractId,ContractLineItem.ServiceContract.SBQQSC__RenewalQuoted__c,ContractLineItem.SBQQSC__RootId__c,Product__r.Gorefresh_Mark_SW_End_Date__c,Product__r.SBQQSC__EntitlementConversion__c,ContractLineItem.EndDate,Order_Service_Item__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__QuoteLine__r.Disposition_Reason__c,Order_Service_Item__r.product2.License_Subtype__c, Order_Service_Item__r.product2.Product_Type__c, Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c, Order_Service_Item__r.Order.SBQQ__Quote__r.Manual_Fulfillment_Quote__c, Order_Service_Item__r.product2.Family, ContractLineItem.SBQQSC__Product__r.SBQQSC__EntitlementConversion__c    ,       ServiceContract.SBQQSC__Order__r.Order_Sub_Type__c,  ContractLineItem.SBQQSC__Product__r.Entitlement_Conversion_Non_CPQ__c,' +
                ' Order_Service_Item__r.SBQQ__RequiredBy__r.Product2.Product_Level__c,Order_Service_Item__r.Previous_Transaction_Reference__c, Order_Service_Item__r.Line_Type__c,Order_Service_Item__r.SBQQ__RequiredBy__r.SerialNumber__c, Order_Service_Item__r.SBQQ__RequiredBy__r.Upgraded_From__c,Order_Service_Item__r.SBQQ__RequiredBy__r.Program__c,Order_Service_Item__r.Order.ProcessType__c,(SELECT Id, Asset__r.SerialNumber,Type__c FROM Scale_Entitlements__r),Product__r.Edition__c, ' +
                String.join(entFields, ',') +
                ' FROM Entitlement';
            List<Entitlement> lstofEnt = Database.query(soqlStr);
            List<Asset> lstofAsset = [SELECT Id, SerialNumber FROM Asset LIMIT 2];
            Map<String, Id> assetNoToId = new Map<String, Id>();
            for(Asset ast : lstofAsset){
                assetNoToId.put(ast.SerialNumber, ast.id);
            }
            System.assert(lstofEnt.size() > 0);
            List<ReplacementEntSplitManager.EntitlementDetails> entDetials = new List<ReplacementEntSplitManager.EntitlementDetails>();
            Map<Id, List<Entitlement_Links__c>> entLinksByCliId = new Map<Id, List<Entitlement_Links__c>>();
            Map<Id, List<Entitlement>> repOrderItemToEntitlements = new Map<Id, List<Entitlement>>();
            OrderItem replacementOrdItem, replacementOrdItem1;
            for (OrderItem oitem : orderItemDetById.values()) {
                if(oitem.Previous_Transaction_Reference__c != null){
                    replacementOrdItem = oitem;
                }   
                if(oitem.Order?.Order_Accepted_Timestamp__c != null && oitem.Order?.Actual_Order_Ship_Date__c != null){
                	replacementOrdItem1 = oitem;
                }
            }
            List<Scale_Entitlement__c> linkedAssets = new List<Scale_Entitlement__c>();
            Map<Id, List<Scale_Entitlement__c>> entToLinkedAssets = new Map<Id, List<Scale_Entitlement__c>>();
            Entitlement renewedEntitlementSplitUpgrade, renewedEntitlementSplitSurviving;
            Integer counter =0;
            for (Entitlement ent : lstofEnt) {
                ent.startdate = System.today();
                ent.EndDate = System.today().addMonths(1);
                ent.Quantity__c = 10;
                ent.Order_Service_Item__c = orderItemDetById.values()[0].Id;
                ReplacementEntSplitManager.EntitlementDetails origEntWrap = new ReplacementEntSplitManager.EntitlementDetails();
                origEntWrap.newEntitlementsByNewOrdItemId = new Map<Id, List<Entitlement>>{replacementOrdItem.Id => new List<Entitlement>{ent}};
                origEntWrap.orderType = 'Refresh';
                if(ent.contractlineItemId != null){
                	origEntWrap.orgEntRec = ent; 
                    entLinksByCliId.put(ent.contractlineItemId, new List<Entitlement_Links__c>());
                }
                if(counter == 15){
                	//origEntWrap.orgEntRec = null; 
                    origEntWrap.terminateDate = System.today();
                    origEntWrap.orderItemIdToTargetProductType.put(replacementOrdItem.Id, 'Hardware');
                }
                entDetials.add(origEntWrap);
                if(!repOrderItemToEntitlements.containsKey(ent.Order_Service_Item__c)){
                    repOrderItemToEntitlements.put(ent.Order_Service_Item__c, new List<Entitlement>());
                }
                repOrderItemToEntitlements.get(ent.Order_Service_Item__c).add(ent); 
                counter++;
                if(ent.Terminated_Date__c != null && ent.contractlineItemId != null && ent.Renewal_Category__c != null){
                    renewedEntitlementSplitUpgrade = ent;
                }
                if(ent.Terminated_Date__c == null && ent.Renewal_Category__c == null){
                    renewedEntitlementSplitSurviving = ent;    
                }
                linkedAssets.add(new Scale_Entitlement__c(Asset__c = lstofAsset[0].id, Entitlement__c = ent.id, Order_Product__c = ent.Order_Service_Item__c));
                
            }
            update lstofent;
            insert linkedAssets;
            Entitlement inactiveEnt = lstofEnt[0];
            
            Map<String, Entitlement> entToUpsert = new Map<String, Entitlement>();
            
            Entitlement usedInactiveEnt = lstofEnt[1];
            Entitlement leftInactiveEnt = lstofEnt[1];
            //insert new List<Entitlement>{ usedInactiveEnt, leftInactiveEnt };
                
            entToUpsert.put(inactiveEnt.Id + '-inactiveUsedEnt', usedInactiveEnt);
            entToUpsert.put(inactiveEnt.Id + '-inactiveLeftEnt', leftInactiveEnt);
            
            for(Scale_Entitlement__c linkedAsset : [SELECT Id, Asset__c, Asset__r.SerialNumber, Entitlement__c, Order_Product__c FROM Scale_Entitlement__c]){
                if(!entToLinkedAssets.containsKey(linkedAsset.Entitlement__c)){
                	entToLinkedAssets.put(linkedAsset.Entitlement__c, new List<Scale_Entitlement__c>());    
                }
                entToLinkedAssets.get(linkedAsset.Entitlement__c).add(linkedAsset);
            }
            List<Entitlement_Links__c> entLinks = new List<Entitlement_Links__c>();
            Entitlement_Links__c entLink = new Entitlement_Links__c();
            entLink.Previous_Entitlement__c = lstofEnt[12].Id;
            entLink.Renewed_Entitlement__c = renewedEntitlementSplitUpgrade.id;
            entLink.quantity__c = 10;
            entLink.Type__c = Constants.ENT_LINK_TYPE_SPLIT_UPGRADE;
            entLinks.add(entLink);
            
            Entitlement_Links__c entLink2 = new Entitlement_Links__c();
            entLink2.Previous_Entitlement__c = lstofEnt[12].Id;
            entLink2.Renewed_Entitlement__c = renewedEntitlementSplitSurviving.Id;
            entLink2.quantity__c = 10;
            entLink2.Type__c = Constants.ENT_LINK_TYPE_SPLIT_SURVIVING;
            entLinks.add(entLink2);
            insert entLinks;
            for(String cliId : entLinksByCliId.keySet()){
                entLinksByCliId.get(cliId).addAll(entLinks);
            }
            List<Entitlement_Links__c> entitlementLinks = [SELECT
                                                           id,
                                                           Quantity__c,
                                                           Previous_Entitlement__r.Asset.SerialNumber,
                                                           Renewed_Entitlement__r.Asset.SerialNumber,
                                                           Previous_Entitlement__r.Order_Service_Item__r.Quantity,
                                                           Renewed_Entitlement__r.Order_Service_Item__r.Quantity,
                                                           Renewed_Entitlement__r.AccountId,
                                                           Previous_Entitlement__r.AccountId,
                                                           Previous_Entitlement__r.StartDate,
                                                           Renewed_Entitlement__r.StartDate,
                                                           Type__c,
                                                           Previous_Entitlement__r.Name,
                                                           Renewed_Entitlement__r.Name,
                                                           Previous_Entitlement__r.ContractLineItem.SBQQSC__RenewalQuantity__c,
                                                           Renewed_Entitlement__r.ContractLineItem.SBQQSC__RenewalQuantity__c,
                                                           Previous_Entitlement__r.Product__c,
                                                           Renewed_Entitlement__r.Product__c,
                                                           Renewed_Entitlement__c,
                                                           Renewed_Entitlement__r.order_service_item__r.serialnumber__c,
                                                           Previous_Entitlement__r.order_service_item__r.serialnumber__c,
                                                           Renewed_Entitlement__r.Product__r.Product_Level__c,
                                                           Previous_Entitlement__r.Product__r.Product_Level__c,
                                                           Renewed_Entitlement__r.id,
                                                           Renewed_Entitlement__r.ContractLineItemId,
                                                           Previous_Entitlement__c,
                                                           Previous_Entitlement__r.ContractLineItemId,
                                                           Previous_Entitlement__r.Terminated_Date__c,
                                                           Renewed_Entitlement__r.Terminated_Date__c,
                                                           Renewed_Entitlement__r.Entitlement_Status__c,
                                                           Renewed_Entitlement__r.Renewal_Category__c,
                                                           Previous_Entitlement__r.Renewal_Category__c,
                                                           Renewed_Entitlement__r.Quantity__c,
                                                           Previous_Entitlement__r.Quantity__c,
                                                           Renewed_Entitlement__r.EndDate,
                                                           Previous_Entitlement__r.EndDate,
                                                           Renewal_Category__c,
                                                           Renewed_Entitlement__r.ServicecontractId,
                                                           Previous_Entitlement__r.ServicecontractId,
                                                           Previous_Entitlement__r.Entitlement_Status__c,
                                                           Renewed_Entitlement__r.Product__r.Product_Type__c,
                                                           Previous_Entitlement__r.Product__r.Product_Type__c,
                                                           Renewed_Entitlement__r.Product__r.Product_Subtype__c,
                                                           Previous_Entitlement__r.Product__r.Product_Subtype__c
                                                           
                                                           FROM Entitlement_Links__c
                                                           ORDER BY createddate ASC];
           	Map<Id, ReplacementEntSplitManager.EntitlementDetails> orgEntIdToWrap = new Map<Id, ReplacementEntSplitManager.EntitlementDetails>();
            List<Error_Logs__c> lstofErrorLogs = new List<Error_Logs__c>();
            counter =0;
            for(ReplacementEntSplitManager.EntitlementDetails origEntWrap : entDetials){
                ReplacementEntSplitManager.getSurvivingEnt(orderItemDetById, origEntWrap, entLinksByCliId,
    			new Map<Id, Orderitem>(), new Map<Id, List<Entitlement>>(), new Map<Id, OrderItem>(),new Set<Id>(),lstofErrorLogs);
                if(origEntWrap.orgEntRec != null && counter == 0){
                	orgEntIdToWrap.put(origEntWrap.orgEntRec.Id, origEntWrap);    
                }
                else{
                    ReplacementEntSplitManager.EntitlementDetails origEntWrap1 = new ReplacementEntSplitManager.EntitlementDetails(); 
                    origEntWrap1.orgEntRec = lstofEnt[13];
                    for (OrderItem oitem : orderItemDetById.values()) {
                        if(oitem?.Order?.Order_sub_type__c == 'Renewal'){
                            origEntWrap1.newEntitlementsByNewOrdItemId = new Map<Id, List<Entitlement>>{oitem.Id => new List<Entitlement>{origEntWrap1.orgEntRec}};    
                        }
                    }
                    origEntWrap1.terminateDate = lstofEnt[13].Terminated_Date__c;
                    origEntWrap1.orderType = Constants.ORDER_TYPE_RENEWAL;
                    origEntWrap1.survivingEnt = lstofEnt[14];
                    origEntWrap1.replacedOrRenewedEnt = lstofEnt[14];
                    origEntWrap1.replacedOrRenewedEntLink = entitlementLinks[0];
                    origEntWrap1.survEntLink = entitlementLinks[1];
                    origEntWrap1.isTerminatedDateMatch = true;
                    origEntWrap1.orderFulfillmentDate = System.today().addDays(-10);
                    origEntWrap1.newEntitlementsByNewOrdItemId = new Map<Id, List<Entitlement>>();
                    origEntWrap1.newEntitlementsByNewOrdItemId.put(replacementOrdItem.Id, new List<Entitlement>{origEntWrap1.orgEntRec});
                    List<PreviousTransRefWrapper> jsonWrap = (List<PreviousTransRefWrapper>)JSON.deserialize(replacementOrdItem.Previous_Transaction_Reference__c, List<PreviousTransRefWrapper>.class);
                    origEntWrap1.newOrdItemNEntIdToWrapper = new Map<String, PreviousTransRefWrapper>{replacementOrdItem.id + '-' + origEntWrap1.orgEntRec.Id => jsonWrap[0]};
                            
                    orgEntIdToWrap.put(origEntWrap.orgEntRec.Id, origEntWrap1);    
                }
                counter++;
                ReplacementEntSplitManager.isTestSplit = false;
                try{
                    ReplacementEntSplitManager.processEntSplitBasedOnReplacmentFramework(orderItemDetById, repOrderItemToEntitlements,
                                                                                   orgEntIdToWrap, new Map<Id, List<Scale_Entitlement__c>>(), new Map<String, Id>(),
                                                                                   new Map<String, Map<String, Id>>(), new List<Entitlement_Links__c>(),
                                                                                   new List<Scale_Entitlement__c>(),new Map<Id, ContractLineItem>(), new List<Scale_Entitlement__c>(),
                                                                                   new Map<String, Polaris_SKU_Mapping_V2__c>(),
                                                                                   new Map<Id, Set<String>>(), new Map<Id, SBQQ__QuoteLine__c>(), new Map<Id, Asset>(), new Map<Id,Entitlement>(), lstofErrorLogs); 
                    ReplacementEntSplitManager.EntitlementDetails clonedWrapper = origEntWrap;
                    clonedWrapper.newReplacedRenewedOI = new List<OrderItem>{replacementOrdItem1};
                    ReplacementEntSplitHelper.getTerminateDateBasedRepPolicy(clonedWrapper, new Map<Id, List<Entitlement>>(), orderItemDetById, lstofErrorLogs);
                    
                    
                }
                catch(Exception error){
                    System.debug(system.logginglevel.DEBUG,  'error '+error.getMessage());
                }
                counter =0;
                for(OrderItem ordItem : orderItemDetById.values()){
                    OrderItem clonedOrdItem = ordItem.clone();
                    if(counter == 0){
                    	clonedOrdItem.Program__c = CONSTANTS.PROGRAM_REFRESH;    
                    }
                    else{
                        clonedOrdItem.Program__c = CONSTANTS.PROGRAM_UPGRADE;
                    }
                    counter++;
                    clonedOrdItem.Upgraded_From__c = lstofAsset[0].SerialNumber;
                    clonedOrdItem.SerialNumber__c = lstofAsset[1].SerialNumber;
                     
                    ReplacementEntSplitHelper.handleLinkedAssetForNewOI(clonedOrdItem, new Map<String, Set<String>>{lstofAsset[0].SerialNumber => new Set<String>{lstofAsset[1].SerialNumber}},
                                                                        repOrderItemToEntitlements, new Map<String, Asset>{lstofAsset[0].SerialNumber => lstofAsset[0]},
                                                                         new Map<Id, OrderItem>(),
    																	new Set<Scale_Entitlement__c>(),new Set<String>(),false);
                    origEntWrap.allAssets = new Set<String>{lstofAsset[0].SerialNumber,lstofAsset[1].SerialNumber };
                    origEntWrap.usedAssets = new Set<String>{lstofAsset[0].SerialNumber};
                    origEntWrap.transactionTypeByAssetSN = new Map<String, String>{lstofAsset[0].SerialNumber =>'Refresh'}; 
                        
                        
                    ReplacementEntSplitHelper.handleAssetLinkageInactiveEnt(origEntWrap,origEntWrap.orgEntRec.Id,inactiveEnt,assetNoToId,new List<Scale_Entitlement__c>(),entToLinkedAssets,entToUpsert);
                    ReplacementEntSplitHelper.handleAssetLinkageSurvivingOld(origEntWrap, entToLinkedAssets, new List<Scale_Entitlement__c>());
                    ReplacementEntSplitHelper.handleEntlinkInactiveEnt(origEntWrap,origEntWrap.orgEntRec.Id, inactiveEnt, new List<Entitlement_Links__c>(), entToUpsert, 'Upgraded', new Map<String, Polaris_SKU_Mapping_V2__c>());
                    List<Entitlement> lstOfInactiveEnt = new List<Entitlement>{inactiveEnt};
                        ReplacementEntSplitManager.processInactiveEntSplits(origEntWrap, new Set<Id>{inactiveEnt.Id}, origEntWrap.orgEntRec.Id, 20, 'Upgraded', entToUpsert, new Map<Id, Entitlement>(lstOfInactiveEnt));
                    Set<String> upgradedSkuTypes = new Set<String>{lstofEnt[2].Id+ '-' +lstofEnt[3].Id, lstofEnt[4].Id+ '-' +lstofEnt[5].Id};
                    origEntWrap.relatedUpgradedSkuType = new List<String>(upgradedSkuTypes);
                    Map<Id, ReplacementEntSplitManager.EntitlementDetails> orgEntIdToWrapMap = new Map<Id, ReplacementEntSplitManager.EntitlementDetails>();
                    origEntWrap.relatedBaseEnt = lstofEnt[0];
                    origEntWrap.relatedDeltaEnt =  lstofEnt[1];
                    origEntWrap.newReplacedEnts = lstofEnt;
                    orgEntIdToWrapMap.put(lstofEnt[0].Id, origEntWrap);
                    orgEntIdToWrapMap.put(lstofEnt[1].Id, origEntWrap);
                    ReplacementEntSplitHelper.createLinkageforUpgradeSkus(origEntWrap, new List<Entitlement_Links__c>(),
                                                                          new Map<String, Polaris_SKU_Mapping_V2__c>(), lstofEnt[0], 'Refreshed', 'Test', 
                                                                          orgEntIdToWrapMap, upgradedSkuTypes);
                }
            } 
            
                
        }
        
    }

     @isTest
    static void testPartialReplacement() {
        List<user> adminUser = [SELECT Id FROM User WHERE Email = :userEmail LIMIT 1];
        System.runAs(adminUser[0]) {
            List<Asset> lstofAsset = [SELECT id FROM Asset LIMIT 1];
            List<OrderItem> existingOrdItem = [SELECT id FROM OrderItem WHERE quantity != NULL LIMIT 1];
            List<SBQQ__QuoteLine__c> qliList = [SELECT id, Replacement_details__c FROM SBQQ__QuoteLine__c];
            List<OrderItem> lstofordItem = new List<OrderItem>();
            List<Scale_Entitlement__c> linkedAssets = new List<Scale_Entitlement__c>();
            List<Entitlement> lstofEnt = [SELECT id, Order_Service_Item__r.Quantity, quantity__c, Order_Service_Item__c FROM Entitlement];
            for (Entitlement ent : lstofEnt) {
                ent.startdate = System.today();
                ent.EndDate = System.today().addMonths(1);
                ent.Quantity__c = 10;
                ent.Order_Service_Item__c = existingOrdItem[0].Id;
                linkedAssets.add(new Scale_Entitlement__c(Asset__c = lstofAsset[0].id, Entitlement__c = ent.id, Order_Product__c = ent.Order_Service_Item__c));
            }
            update lstofent;
            String replacementDetails = '{"targetProductType" : "Hardware","skuStorageTierVal":null,"skuStorageBundleVal":null,"skuSFDCVal":null,"skuSelectedName":"RS-BT-EE-PE-PA","skuSelected":"01t6f00000O6dT0AAJ","skuM365HVal":null,"skuAttlasianVal":null,"SeamlessCutover":null,"rowValues":[{"UpgradeLines":null, "inactiveLines":[{"childrowId":null,"childQnty":270,"childEntId":"550VI00000938QkYAI"}],"selectedQty":300,"selectedAssetList":{"02i6f00000IfP9gAAF":"BB210464100059","02i6f00000IfPBSAA3":"BB210364100020","02i6f00000IrOTzAAN":"BB211364100028","02i6f00000IrOUJAA3":"BB211364100030"},"selectedAsset":"02i6f00000IrOUJAA3,02i6f00000IrOTzAAN,02i6f00000IfPBSAA3,02i6f00000IfP9gAAF","rowId":"2.1.0","entId":"550VI000007aYKAYA2","disposition":"Converted","selectedTerm":12}],"mode":"1to1"}';
            
            for (SBQQ__QuoteLine__c qli : qliList) {
                qli.Replacement_details__c = replacementDetails;
                qli.special_program__c = 'Conversion';
            }
            
            update qlilist;
            insert linkedAssets;
            Entitlement_Links__c entLink = new Entitlement_Links__c();
            entLink.Previous_Entitlement__c = lstofEnt[0].id;
            entLink.Renewed_Entitlement__c = lstofEnt[0].id;
            entLink.quantity__c = 10;
            //entLink.Renewal_Category__c = 'Converted';
            entLink.Type__c = 'Split-Surviving';
            insert entLink;
            SplitOrder sp = new SplitOrder();
            Order replacedOrd = [
                SELECT
                id,
                Order_Sub_Type__c,
                SBQQ__Contracted__c,
                Polaris_Fulfillment_Status__c,
                Status,
                Order_Status__c,
                Actual_Order_Ship_Date__c,
                Welcome_letter_sent_for_the_first_time__c,
                Ordernumber,
                AccountId,
                OpportunityId,
                SBQQ__Quote__c,
                (SELECT id, Enddate, order.ordernumber, Previous_Transaction_Reference__c FROM orderitems)
                FROM Order
                LIMIT 1
            ];

            String recordTypeId= Schema.SObjectType.Order.getRecordTypeInfosByName().get('Phantom Order').getRecordTypeId();
            Map<String, Object>  OrderMap = new Map<String, Object> {
            'Type' => 'Revenue Internal',
            'recordTypeId' => recordTypeId,
            'AccountId' => replacedOrd.AccountId,
            'OpportunityId' => replacedOrd.OpportunityId,
            'Sync_to_NetSuite__c' => true,
            'EffectiveDate' => system.today(),
            'Status' => 'Pending',
            'Bill_To_Name__c'=> replacedOrd.AccountId,
            'SBQQ__Quote__c'=> replacedOrd.SBQQ__Quote__c,
            'Line_Types__c'=> 'Partial Surviving'
            };
            
            Order phantomOrd =  (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
            phantomOrd.Type = 'Revenue Internal';
            phantomOrd.Associated_Order_Numbers__c = replacedOrd.Ordernumber;
            insert phantomOrd;
            
            List<PricebookEntry> lstofpricebookentry = [select id,Pricebook2Id,Product2Id,UnitPrice,IsActive from PricebookEntry];
            
            List<Order> lstPhantomOrder = [SELECT Id,Ordernumber FROM Order WHERE Id = :phantomOrd.Id];
            replacedOrd.Associated_Order_Numbers__c = lstPhantomOrder[0].Ordernumber;
            //replacedOrd.Order_Sub_Type__c = 'Replacement';
            replacedOrd.SBQQ__Contracted__c = false;
            replacedOrd.Polaris_Fulfillment_Status__c = 'Completed';
            replacedOrd.Status = 'Activated';
            replacedOrd.Order_Status__c = 'Shipped';
            //orderInstance1.Program__c = 'Conversion';
            // replacedOrd.SBQQ__Quote__c = quoteObjNew.Id;
            replacedOrd.Actual_Order_Ship_Date__c = System.today().addDays(-30);
            replacedOrd.Order_Accepted_Timestamp__c = Datetime.newInstance(2025, 2, 20);
            replacedOrd.Line_Types__c = 'Conversion';
            replacedOrd.Welcome_letter_sent_for_the_first_time__c = true;
            
            List<Order_Item_Extension__c> oiExtension = new List<Order_Item_Extension__c>();
            //oiExtension.add(new Order_Item_Extension__c(Name = 'Test'+oi.id,Invoice_Number__c = oi.order.ordernumber, OI_ExternalID__c = oi.id, Order_Line_ID__c = oi.id, End_of_Paid_Term__c = system.today().addDays(90)));
            for (Orderitem oi : replacedOrd.orderitems) {
                oi.Previous_Transaction_Reference__c =
                    '[{\"usedEntitlementQuantity\":5.00,\"phantomOrderItemId\":null,\"orderItemId\":\"' +
                    lstofEnt[0].Order_Service_Item__c +
                    '\",\"orderItemRemainingQuantity\":5.00,\"entId\":\"' +
                    lstofEnt[0].id +
                    '\"}]';
                oi.SBQQ__Contracted__c = false;
                oi.Program__c = 'Conversion';
                oiExtension.add(
                    new Order_Item_Extension__c(
                        Name = 'Test' + oi.id,
                        Invoice_Number__c = oi.order.ordernumber,
                        OI_ExternalID__c = oi.id,
                        Order_Line_ID__c = oi.id,
                        End_of_Paid_Term__c = system.today().addDays(90)
                    )
                );
                lstofordItem.add(oi);
            }
            update lstofordItem;

            OrderItem phantomoi = new OrderItem(SBQQ__QuotedQuantity__c = 10,OrderId = phantomOrd.Id, Quantity = 10, PricebookEntryId = lstofpricebookentry[0].id, unitprice =lstofpricebookentry[0].unitprice,Sales_Price__c = lstofpricebookentry[0].unitprice);
            phantomoi.Previous_Transaction_Reference__c =  '{\"orderItemId\":\"'+lstofEnt[1].Order_Service_Item__c+'\",\"entId\":\"'+lstofEnt[1].id+'\"}';
            phantomoi.Support_Start_Date__c = system.today();
            phantomoi.Support_End_Date__c = system.today().addMonths(1).addDays(-1);
            insert phantomoi;

            Test.starttest();
            update replacedOrd;
            //order ordertoupdate = new Order(id = replacedOrd.id,Line_Types__c = 'Conversion');
            //update ordertoupdate;
            insert oiExtension;
            
            ContractOrders replacedordtest = new ContractOrders();
            System.schedule('Test_Contract_Orders_Conversion', '0 0 * * * ?', replacedordtest);
            replacedordtest.execute(null);
            System.assert(replacedOrd.id != null);
            Test.stoptest();
        }
    }
    
        @isTest
    static void testPhantomOrder() {
        List<user> adminUser = [SELECT Id FROM User WHERE Email = :userEmail LIMIT 1];
        System.runAs(adminUser[0]) {
            List<Asset> lstofAsset = [SELECT id FROM Asset LIMIT 1];
            List<OrderItem> existingOrdItem = [SELECT id FROM OrderItem WHERE quantity != NULL LIMIT 1];
            List<SBQQ__QuoteLine__c> qliList = [SELECT id, Replacement_details__c FROM SBQQ__QuoteLine__c];
            List<OrderItem> lstofordItem = new List<OrderItem>();
            List<Scale_Entitlement__c> linkedAssets = new List<Scale_Entitlement__c>();
            List<Entitlement> lstofEnt = [SELECT id, Order_Service_Item__r.Quantity, quantity__c, Order_Service_Item__c FROM Entitlement];
            for (Entitlement ent : lstofEnt) {
                ent.startdate = System.today();
                ent.EndDate = System.today().addMonths(1);
                ent.Quantity__c = 10;
                ent.Order_Service_Item__c = existingOrdItem[0].Id;
                linkedAssets.add(new Scale_Entitlement__c(Asset__c = lstofAsset[0].id, Entitlement__c = ent.id, Order_Product__c = ent.Order_Service_Item__c));
            }
            update lstofent;
            String replacementDetails = '{"targetProductType" : "Hardware","skuStorageTierVal":null,"skuStorageBundleVal":null,"skuSFDCVal":null,"skuSelectedName":"RS-BT-EE-PE-PA","skuSelected":"01t6f00000O6dT0AAJ","skuM365HVal":null,"skuAttlasianVal":null,"SeamlessCutover":null,"rowValues":[{"UpgradeLines":null,"selectedQty":300,"selectedAssetList":{"02i6f00000IfP9gAAF":"BB210464100059","02i6f00000IfPBSAA3":"BB210364100020","02i6f00000IrOTzAAN":"BB211364100028","02i6f00000IrOUJAA3":"BB211364100030"},"selectedAsset":"02i6f00000IrOUJAA3,02i6f00000IrOTzAAN,02i6f00000IfPBSAA3,02i6f00000IfP9gAAF","rowId":"2.1.0","inactiveLines":[{"childrowId":null,"childQnty":270,"childEntId":"550VI00000938QkYAI"}],"entId":"550VI000007aYKAYA2","disposition":"Converted","selectedTerm":12}],"mode":"1to1"}';
            for (SBQQ__QuoteLine__c qli : qliList) {
                qli.Replacement_details__c = replacementDetails;
                qli.special_program__c = 'Conversion';
            }
            
            update qlilist;
            insert linkedAssets;
            Entitlement_Links__c entLink = new Entitlement_Links__c();
            entLink.Previous_Entitlement__c = lstofEnt[0].id;
            entLink.Renewed_Entitlement__c = lstofEnt[0].id;
            entLink.quantity__c = 10;
            entLink.Type__c = 'Split-Surviving';
            insert entLink;
            SplitOrder sp = new SplitOrder();

            Order phantomOrder = [SELECT Id,Ordernumber,(SELECT Id,Previous_Transaction_Reference__c FROM orderitems) FROM Order WHERE RecordType.Name = 'Phantom Order'];
            
            Order replacedOrd = [
                SELECT
                id,
                Order_Sub_Type__c,
                SBQQ__Contracted__c,
                Polaris_Fulfillment_Status__c,
                Status,
                Order_Status__c,
                Actual_Order_Ship_Date__c,
                Welcome_letter_sent_for_the_first_time__c,
                Ordernumber,
                (SELECT id, Enddate, order.ordernumber, Previous_Transaction_Reference__c,Product2Id, PricebookEntryId,Support_End_Date__c,UnitPrice,Quantity FROM orderitems)
                FROM Order
                LIMIT 1
            ];
            
            replacedOrd.Associated_Order_Numbers__c = phantomOrder.Ordernumber;
            replacedOrd.SBQQ__Contracted__c = false;
            replacedOrd.Polaris_Fulfillment_Status__c = 'Completed';
            replacedOrd.Status = 'Activated';
            replacedOrd.Order_Status__c = 'Shipped';
            replacedOrd.Actual_Order_Ship_Date__c = System.today().addDays(-30);
            replacedOrd.Order_Accepted_Timestamp__c = Datetime.newInstance(2025, 2, 20);
            replacedOrd.Line_Types__c = 'Conversion';
            replacedOrd.Welcome_letter_sent_for_the_first_time__c = true;
            
            List<Order_Item_Extension__c> oiExtension = new List<Order_Item_Extension__c>();
            
            for (Orderitem oi : replacedOrd.orderitems) {
                oi.Previous_Transaction_Reference__c =
                   '[{"usedEntitlementQuantity":5.00,"phantomOrderItemId":null,"orderItemId":"' +
                    lstofEnt[0].Order_Service_Item__c +
                    '","orderItemRemainingQuantity":5.00,"entId":"' +
                    lstofEnt[0].Id +
                    '","relatedInactiveEntitlements":[{"entitlementId":"' +
                    lstofEnt[1].Id +
                    '","remainingOrderItemQuantity":5.00,"usedEntitlementQuantity":5.00,"orderItemId":"' +
                    lstofEnt[1].Order_Service_Item__c +
                    '","orderNumber":"ORD-1001"}]}]'; 
                oi.SBQQ__Contracted__c = false;
                oi.Program__c = 'Conversion';
                oiExtension.add(
                    new Order_Item_Extension__c(
                        Name = 'Test' + oi.id,
                        Invoice_Number__c = oi.order.ordernumber,
                        OI_ExternalID__c = oi.id,
                        Order_Line_ID__c = oi.id,
                        End_of_Paid_Term__c = system.today().addDays(90)
                    )
                );
                lstofordItem.add(oi);
            }

            phantomOrder.Associated_Order_Numbers__c = replacedOrd.OrderNumber;
            update phantomOrder;

			phantomOrder.OrderItems[0].Previous_Transaction_Reference__c =  '{\"orderItemId\":\"'+lstofEnt[1].Order_Service_Item__c+'\",\"entId\":\"'+lstofEnt[1].id+'\"}';
            lstofordItem.add(phantomOrder.OrderItems[0]);
                
            Test.starttest();

            update lstofordItem;
            update replacedOrd;
            insert oiExtension;
            
            ContractOrders replacedordtest = new ContractOrders();
            System.schedule('Test_Contract_Orders_Conversion', '0 0 * * * ?', replacedordtest);
            replacedordtest.execute(null);
            System.assert(replacedOrd.id != null);
            Test.stoptest();
        }
    }
}