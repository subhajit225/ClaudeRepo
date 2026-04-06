/*******************************************************************************
 * @description       : Test class for auto-accept PO helper 
 * @author            : moises, moises.contreras@rubrik.com
 * @group             : Stage PO Validations
 * @last modified on  : 05-10-2022
 * @last modified by  : Moises Nunez moises.contreras@rubrik.com
 * *****************************************************************************
 * History
 * Date                Modification           Author
 * 05-10-2022          PRDOPS23-93            moises.contreras@rubrik.com
 *******************************************************************************/
@isTest
public class AcceptPOHelper_Test {
    /**
      * @description This is a Map of Static values for Opportunity Stage Name
      */
    private static Map<Integer, String> OPP_STAGENAME_MAP = new Map<Integer, String>{ 4 => '4 Business Justification', 5 => '5 Negotiate & Close', 6 => '6 PO With Channel' };
    /**
      * @description This method creates the Test data for the test class
      */
    @TestSetup
    static void testDataSetup() { 
        String uniqueUserName = 'TestUser' + DateTime.now().getTime() + '@rbk.com';
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User usr = new user(
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
        insert usr;
        System.runAs(usr) {
            insert new List<SObject>{
                new ShGl_DisableFunctionalityLogic__c(setupOwnerId = usr.Id, Disable_OpportunityValidationRules__c = true, Disable_Account_Old_Trigger__c = true),
                new ShGl_DisableBusinessLogic__c(
                    setupownerid = usr.Id,
                    Disable_Account_Triggers__c = true,
                    Disable_Asset_Triggers__c = true,
                    Disable_SBQQ_QuoteLine_Triggers__c = true,
                    Disable_SBQQ_Quote_Triggers__c = true,
                    Disable_Order_Old_Trigger__c = true,
                    Disable_OrderItem_Old_Trigger__c = true,
                    Disable_Opportunity_Triggers__c = true,
                    Disable_Opportunity_Validation_Rules__c = true,
                    Disable_SBQQ_Quote_Validation_Rules__c = true
                ),
                new POValidation_ErrorCode__c(Name = 'INT CM Mismatch', Code__c = 'INT-14', Error_Issue__c = 'CM Mismatch')
            };

            TriggerControl.stopOrderItemTrigger = true;
            TriggerControl.stopOrderTrigger = true;
            TriggerControls.disableQuoteTrigger = true;

            Map<String, Schema.RecordTypeInfo> AcRecTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByName();
            List<Account> accounts = new List<Account>{
                new Account(Name = 'Test Account', RecordTypeId = AcRecTypeInfo.get('Customer/Prospect').getRecordTypeId()),
                new Account(Name = 'Promark Technology, Inc.', Type = 'Distributor', RecordTypeId = AcRecTypeInfo.get('Partner/Distributor').getRecordTypeId())
            };
            insert accounts;
            Opportunity opp = TestDataFactory.getOpportunity(accounts[0]);
            opp.Distributor_Lookup__c = accounts[1].Id;
            opp.ContractManufacturer__c = 'Flextronics International USA, Inc.';
            opp.Partner_Lookup__c = accounts[1].Id;
            opp.Aspen_Eligibility__c = 'Proposed Aspen';
            opp.StageName = OPP_STAGENAME_MAP.get(4);
            opp.Pricebook2Id =  System.Label.CPQPricebookId;
            insert opp;

            
            Opportunity opp1 = TestDataFactory.getOpportunity(accounts[0]);
            opp1.Distributor_Lookup__c = accounts[1].Id;
            opp1.ContractManufacturer__c = 'Flextronics International USA, Inc.';
            opp1.Partner_Lookup__c = accounts[1].Id;
            opp1.Aspen_Eligibility__c = 'Proposed Aspen';
            opp1.StageName = OPP_STAGENAME_MAP.get(4);
            opp1.Pricebook2Id =  System.Label.CPQPricebookId;
            insert opp1;
            
            opp1.Name = 'New mAWS Deal Test';
            
            update opp1;

            List<Product2> sampleProducts = new List<Product2>{
                // 0
                new Product2(
                    Name = 'CPQ Bundle Product',
                    ProductCode = 'CPQ Bundle Product',
                    IsActive = true,
                    Product_Level__c = 'Hybrid Software',
                    SBQQ__Hidden__c = true,
                    SBQQ__ExcludeFromOpportunity__c = true,
                    New_CPQ_Product__c = true,
                    Quotable_Date__c = system.today()
                ),
                // 1
                new Product2(
                    Name = 'HW',
                    ProductCode = 'HW',
                    Category__c = 'Platform',
                    Family = 'r300',
                    Usable_Capacity__c = 1,
                    Product_Level__c = 'Hardware',
                    Product_Type__c = 'Software',  //changed product type
                    Appliance_Model__c = 'RBK-R344',
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
                    SBQQ__SubscriptionType__c = 'Renewable',
                    Bundle_Features__c = 'Sonar',
                    Quotable_Date__c = system.today()
                )
            };
            insert sampleProducts;
            List<PricebookEntry> entries = new List<PricebookEntry>{
                new PricebookEntry( Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[0].Id, IsActive = true, UnitPrice = 100),
                new PricebookEntry( Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[1].Id, IsActive = true, UnitPrice = 0),
                new PricebookEntry( Pricebook2Id = System.Label.CPQPricebookId, Product2Id = sampleProducts[0].Id, IsActive = true, UnitPrice = 100),
                new PricebookEntry( Pricebook2Id = System.Label.CPQPricebookId, Product2Id = sampleProducts[1].Id, IsActive = true, UnitPrice = 0)
            };
            insert entries;
            Map<Id,Id> productToPricebookEntry = new Map<Id,Id>();
            for(PricebookEntry entry: entries ) {
                if(entry.Pricebook2Id == System.Label.CPQPricebookId) productToPricebookEntry.put(entry.Product2Id, entry.Id);
            }
            // System.debug('***entries\n' + JSON.serialize(entries));
            SBQQ__Quote__c quote = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(
                new SBQQ__Quote__c(),
                new Map<String, Object>{
                    'SBQQ__Account__c' => opp.AccountId,
                    'SBQQ__Opportunity2__c' => opp.Id,
                    'SBQQ__Primary__c' => true,
                    'SBQQ__SubscriptionTerm__c' => 12,
                    // 'Is_RWD_Polaris_Quote__c' => true,
                    'ProcessType__c' => 'Aspen',
                    'SBQQ__PaymentTerms__c' => 'Net 45'
                }
            );
			quote.Opportunity_Program__c='Conversion';
            insert quote;

            
            SBQQ__Quote__c quote1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(
                new SBQQ__Quote__c(),
                new Map<String, Object>{
                    'SBQQ__Account__c' => opp.AccountId,
                        'SBQQ__Opportunity2__c' => opp.Id,
                        'SBQQ__Primary__c' => true,
                        'SBQQ__SubscriptionTerm__c' => 12,
                        //'Is_RWD_Polaris_Quote__c' => true,
                        'ProcessType__c' => 'Aspen',
                        'SBQQ__PaymentTerms__c' => 'Net 45'
                        }
            );
            quote1.Opportunity_Program__c='Conversion';
            insert quote1;
            
            List<ProductModel> prodModels = new List<ProductModel>();

            for (product2 prod : sampleProducts) {
                prodModels.add(
                    (ProductModel) JSON.deserialize(
                        SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prod.Id, '{"pricebookId" : "' + system.label.CPQPricebookID + '", "currencyCode" : "USD"}'),
                        ProductModel.class
                    )
                );
            }

            String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', quote.id);
            ProductAdder adder = new ProductAdder();
            QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), prodModels, 0);
            Map<String, Integer> prodKey = new Map<String, Integer>();
            for (QuoteLineModel QLModel : quoteWithProducts.lineItems) {
                if (QLModel.record.Product_Level__c == 'Hybrid Software') {
                    prodKey.put(QLModel.record.SBQQ__ProductCode__c, QLModel.key);
                    QLModel.record.SBQQ__Quantity__c = 500;
                    QLModel.record.SBQQ__SubscriptionTerm__c = 12;
                    QLModel.record.SBQQ__NetPrice__c = 100;
                } else if (QLModel.record.Product_Level__c == 'Hardware') {
                    prodKey.put(QLModel.record.SBQQ__ProductCode__c, QLModel.key);
                    QLModel.record.SBQQ__Quantity__c = 6;
                    QLModel.record.SBQQ__NetPrice__c = 0;
                }
                QLModel.record.SBQQ__PricebookEntryId__c = productToPricebookEntry.get(QLModel.record.SBQQ__Product__c);

            }
            for (QuoteLineModel QLModel : quoteWithProducts.lineItems) {
                if (QLModel.record.Product_Level__c == 'Hardware') {
                    QLModel.parentItemKey = prodKey.get('CPQ Bundle Product');
                }
            }
           // String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
            QuoteCalculator calculator = new QuoteCalculator();
            //calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
            quote.ApprovalStatus__c = 'Approved';
            quote.SBQQ__Status__c = 'Approved';
            quote.Payment_year_2__c = 0;
            //quote.Manual_Billing__c = true;
            quote.SBQQ__ExpirationDate__c = System.today().addDays(-1);
            quote.SBQQ__Type__c='Quote';
            quote.Renewal_Opportunity__c=opp1.id;
            quote.Opportunity_Program__c='Conversion';
            update quote;
            
            quote1.ApprovalStatus__c = 'Approved';
            quote1.SBQQ__Status__c = 'Approved';
            quote1.SBQQ__Type__c='Quote';
            quote1.Renewal_Opportunity__c=opp1.id;
            update quote1;
            // System.debug('##GQ\n' + JSON.serialize([SELECT Id, Name, (SELECT Id, Name,SBQQ__PricebookEntryId__c, SBQQ__ProductCode__c, SBQQ__Quantity__c FROM SBQQ__LineItems__r) FROM SBQQ__Quote__c]));
            ShGl_DisableBusinessLogic__c disableBusinessLogic = ShGl_DisableBusinessLogic__c.getInstance();
            disableBusinessLogic.Disable_Opportunity_Triggers__c = false;
            update disableBusinessLogic;
            PO_Stage__c poStage = ShGl_TestFactoryHelper.createPOStage(
                'Promark Technology, Inc.pp',
                'test123',
                system.today().addDays(10),
                1,
                'test@test.com',
                'test partner',
                System.today(),
                1,
                'test12345',
                quote.name,
                quote.SBQQ__NetAmount__c
            );
            poStage.Bill_To_Name__c = quote.SBQQ__Opportunity2__r.Distributor_Lookup__c;
            poStage.Account_Name__c = quote.SBQQ__Account__r.Name;
            poStage.Quote_number__c = quote.name;
            poStage.Quote__c = quote.Id;
            poStage.Opportunity__c = quote.SBQQ__Opportunity2__c;
            poStage.Ship_to_Email__c = 'test@test.com';
            poStage.Ship_To_Contact_Name__c = 'testCon';
            poStage.Ship_To_Phone_Number__c = '7000022448';
            poStage.ShippingCountryCode__c = 'IN';
            poStage.ShippingStateCode__c = 'KA';
            poStage.ShippingCity__c = 'test City';
            poStage.ShippingStreet__c = 'test street';
            poStage.ShippingPostalCode__c = '0000';
            poStage.PO_Validation_Status__c = 'Success';
            poStage.ContractManufacturer__c = 'Flextronics International USA, Inc.';
            poStage.EDI_DISTI_ID__c = 'PO PDF';
			poStage.TotalAmount__c=100000;
            poStage.Bill_To_Name__c= accounts[0].Id;
            poStage.PoNumber__c= 'Other';
            poStage.Payment_Terms__c='Other';
            poStage.End_User_PO__c= 'Other';
            poStage.Shipping_Method__c='Other';
            poStage.Shipping_Carrier__c='Other';
            poStage.Account_name__c='Other';
            insert poStage;

            PO_Stage__c poStage1 = ShGl_TestFactoryHelper.createPOStage(
                'Promark Technology, Inc.pp',
                'test123',
                system.today().addDays(10),
                1,
                'test@test.com',
                'test partner',
                System.today(),
                1,
                'test12345',
                quote.name,
                quote.SBQQ__NetAmount__c
            );
            poStage1.Bill_To_Name__c = quote1.SBQQ__Opportunity2__r.Distributor_Lookup__c;
            poStage1.Account_Name__c = quote1.SBQQ__Account__r.Name;
            poStage1.Quote_number__c = quote1.name;
            poStage1.Quote__c = quote1.Id;
            poStage1.Opportunity__c = quote1.SBQQ__Opportunity2__c;
            poStage1.Ship_to_Email__c = 'test@test.com';
            poStage1.Ship_To_Contact_Name__c = 'testCon';
            poStage1.Ship_To_Phone_Number__c = '7000022448';
            poStage1.ShippingCountryCode__c = 'IN';
            poStage1.ShippingStateCode__c = 'KA';
            poStage1.ShippingCity__c = 'test City';
            poStage1.ShippingStreet__c = 'test street';
            poStage1.ShippingPostalCode__c = '0000';
            poStage1.PO_Validation_Status__c = 'Success';
            poStage1.ContractManufacturer__c = 'Super Micro Computer, Inc.';
            poStage1.PO_Internal_Validation_Status__c ='Internal Failure';
            poStage1.Service_Level__c = null;
            poStage1.Payment_schedule_type__c='Test';
            insert poStage1;
            
            
            PO_Item_Stage__c PoIS = new PO_Item_Stage__c();
            PoIS.Buyer_Part_Number__c='1234';
            PoIS.EDI_Line_Number__c ='100';
            PoIS.ProductCode__c =sampleProducts[0].ProductCode;
            PoIS.Quantity__c = 50;
            PoIS.Stage_PO__c= poStage.id;
            PoIS.UnitPrice__c=1000;
            insert PoIS;

        }
    }
    /**
      * @description This method covers the code for AcceptPOController and AcceptPOHelper
      */
    @IsTest
    static void oppToStg6() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        List<Order> ords = [SELECT Id FROM Order LIMIT 1];
        SBQQ.TriggerControl.disable();
        //System.assertEquals(0, ords.size());
        
        SBQQ__Quote__c quoteList =[Select id,Is_RWD_Polaris_Quote__c,SBQQ__ExpirationDate__c,SBQQ__Status__c,Opportunity_Program__c,SBQQ__Opportunity2__c
                                   from SBQQ__Quote__c where Is_RWD_Polaris_Quote__c=: false limit 1];

        System.runAs(usr) {
        
            SBQQ__Quote__c quoteList1 =[Select id,Is_RWD_Polaris_Quote__c,SBQQ__ExpirationDate__c,SBQQ__Status__c,Opportunity_Program__c,
                                        SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.Distributor_Lookup__c,SBQQ__Account__r.Name,
                                        SBQQ__Opportunity2__r.SBQQ__Ordered__c,SBQQ__Opportunity2__r.SBQQ__PrimaryQuote__c,
                                        SBQQ__NetAmount__c,name
                                   from SBQQ__Quote__c limit 1];

            PO_Stage__c poStageObj = ShGl_TestFactoryHelper.createPOStage(
                'Promark Technology, Inc.pp',
                'test123',
                system.today().addDays(10),
                1,
                'test@test.com',
                'test partner',
                System.today(),
                1,
                'test12345',
                quoteList1.name,
                quoteList1.SBQQ__NetAmount__c
            );
            poStageObj.Bill_To_Name__c = quoteList1.SBQQ__Opportunity2__r.Distributor_Lookup__c;
            poStageObj.Account_Name__c = quoteList1.SBQQ__Account__r.Name;
            poStageObj.Quote_number__c = quoteList1.name;
            poStageObj.Quote__c = quoteList1.Id;
            poStageObj.Opportunity__c = quoteList1.SBQQ__Opportunity2__c;
            poStageObj.Ship_to_Email__c = 'test@test.com';
            poStageObj.Ship_To_Contact_Name__c = 'testCon';
            poStageObj.Ship_To_Phone_Number__c = '7000022448';
            poStageObj.ShippingCountryCode__c = 'IN';
            poStageObj.ShippingStateCode__c = 'KA';
            poStageObj.ShippingCity__c = 'test City';
            poStageObj.ShippingStreet__c = 'test street';
            poStageObj.ShippingPostalCode__c = '0000';
            poStageObj.PO_Validation_Status__c = 'Success';
            poStageObj.ContractManufacturer__c = 'Super Micro Computer, Inc.';
            poStageObj.PO_Internal_Validation_Status__c ='Internal Failure';
            poStageObj.Service_Level__c = null;
            poStageObj.Payment_schedule_type__c='Test';
            poStageObj.EDI_DISTI_ID__c = 'INGRAM';
            poStageObj.Customer_Requested_Ship_Date__c = '01-01-2025';
            poStageObj.PoDate__c = system.today();
            insert poStageObj;
            AcceptPOController.disableCmValidationInTest = false;
            ApexPages.StandardController ctrl = new ApexPages.StandardController(poStageObj);
            AcceptPOController poController = new AcceptPOController(ctrl);
            
            poController.inputMessage = 'Test error reason.';
            poController.toggleReject();
            poController.reject();
            poController.cancel();
            poController.savePO();
            Test.startTest();
            
            poStageObj.PO_Validation_Status__c ='Staged';
            poStageObj.PO_Internal_Validation_Status__c ='Internal Failure';
            poStageObj.Customer_Requested_Ship_Date__c = string.valueOf(System.today());
            update poStageObj;
            AcceptPOController.disableCmValidationInTest = false;
            ctrl = new ApexPages.StandardController(poStageObj);
            poController = new AcceptPOController(ctrl);
            //poController.savePO();
            
            poStageObj.PO_Validation_Status__c ='Success';
            update poStageObj;
            
            Opportunity opp = [SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c FROM Opportunity WHERE Name = 'New mAWS Deal' LIMIT 1];
            /*for(Opportunity oppitem : opp){
                oppitem.StageName = OPP_STAGENAME_MAP.get(6);
                oppitem.SBQQ__Ordered__c = false;
            }*/
            opp.StageName = OPP_STAGENAME_MAP.get(6);
            update opp;
          //  opp = [SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c, ContractManufacturer__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
            ctrl = new ApexPages.StandardController(poStageObj);
            poController = new AcceptPOController(ctrl);
            poController.savePO();
            quoteList1.Is_RWD_Polaris_Quote__c = true;
            update quoteList1;
            ApexPages.StandardController ctrl1 = new ApexPages.StandardController(poStageObj);
            AcceptPOController poController1 = new AcceptPOController(ctrl);
            Test.stopTest();
        }
        SBQQ.TriggerControl.enable();
        System.Assert(ords.isEmpty()); 
    }
    /**
      * @description This method covers the code for AcceptPOController and AcceptPOHelper
      */
    @IsTest
    static void updatePOItem() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        System.runAs(usr) {
        PO_Item_Stage__c poitemStage= [select id from PO_Item_Stage__c limit 1];
        update poitemStage;
        delete poitemStage;
        System.assertEquals(0, [SELECT COUNT() FROM PO_Item_Stage__c WHERE Id = :poitemStage.id], 'PoItem is deleted');
        }
    }
    /**
      * @description This method covers the code for AcceptPOController and AcceptPOHelper
      */
    @IsTest
    static void deletePOItem() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        System.runAs(usr) {
        PO_Item_Stage__c poitemStage= [select id from PO_Item_Stage__c limit 1];
        //system.debug('poitemStage is ### ' + poitemStage);
        //update poitemStage;
        delete poitemStage;
        System.assertEquals(0, [SELECT COUNT() FROM PO_Item_Stage__c WHERE Id = :poitemStage.id], 'PoItem is deleted');
        }
    }
    /**
      * @description This method covers the code for AcceptPOController and AcceptPOHelper
      */
    @IsTest
    static void oppToStg6forPOPdf() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        List<Order> ords = [SELECT Id FROM Order];
        SBQQ.TriggerControl.disable();
        //System.assertEquals(0, ords.size());
        
        SBQQ__Quote__c quoteList =[Select id,Is_RWD_Polaris_Quote__c,SBQQ__ExpirationDate__c,SBQQ__Status__c,Opportunity_Program__c,SBQQ__Opportunity2__c
                                   from SBQQ__Quote__c where Is_RWD_Polaris_Quote__c=: false limit 1];

        System.runAs(usr) {
        Test.startTest();
            SBQQ__Quote__c quoteList1 =[Select id,Is_RWD_Polaris_Quote__c,SBQQ__ExpirationDate__c,SBQQ__Status__c,Opportunity_Program__c,
                                        SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.Distributor_Lookup__c,SBQQ__Account__r.Name,
                                        SBQQ__Opportunity2__r.SBQQ__Ordered__c,SBQQ__Opportunity2__r.SBQQ__PrimaryQuote__c,
                                        SBQQ__NetAmount__c,name
                                   from SBQQ__Quote__c limit 1];

            PO_Stage__c poStageObj = ShGl_TestFactoryHelper.createPOStage(
                'Promark Technology, Inc.pp',
                'test123',
                system.today().addDays(10),
                1,
                'test@test.com',
                'test partner',
                System.today(),
                1,
                'test12345',
                quoteList1.name,
                quoteList1.SBQQ__NetAmount__c
            );
            poStageObj.name = 'test12';
            poStageObj.Bill_To_Name__c = quoteList1.SBQQ__Opportunity2__r.Distributor_Lookup__c;
            poStageObj.Account_Name__c = quoteList1.SBQQ__Account__r.Name;
            poStageObj.Quote_number__c = quoteList1.name;
            poStageObj.Quote__c = quoteList1.Id;
            poStageObj.Opportunity__c = quoteList1.SBQQ__Opportunity2__c;
            poStageObj.Ship_to_Email__c = 'test@test.com';
            poStageObj.Ship_To_Contact_Name__c = 'testCon';
            poStageObj.Ship_To_Phone_Number__c = '7000022448';
            poStageObj.ShippingCountryCode__c = 'IN';
            poStageObj.ShippingStateCode__c = 'KA';
            poStageObj.ShippingCity__c = 'test City';
            poStageObj.ShippingStreet__c = 'test street';
            poStageObj.ShippingPostalCode__c = '0000';
            poStageObj.PO_Validation_Status__c = 'Success';
            poStageObj.ContractManufacturer__c = 'Super Micro Computer, Inc.';
            poStageObj.PO_Internal_Validation_Status__c ='Internal Failure';
            poStageObj.Service_Level__c = null;
            poStageObj.Payment_schedule_type__c='Test';
            poStageObj.EDI_DISTI_ID__c = 'PO PDF';
            insert poStageObj;
            AcceptPOController.disableCmValidationInTest = false;
            ApexPages.StandardController ctrl = new ApexPages.StandardController(poStageObj);
            AcceptPOController poController = new AcceptPOController(ctrl);
            
            poController.inputMessage = 'Test error reason.';
            poController.toggleReject();
            poController.reject();
            poController.cancel();
            poController.savePO();
            
            
            poStageObj.PO_Validation_Status__c ='Staged';
            poStageObj.PO_Internal_Validation_Status__c ='Internal Failure';
            update poStageObj;
            ctrl = new ApexPages.StandardController(poStageObj);
            poController = new AcceptPOController(ctrl);
            //poController.savePO();
            
            poStageObj.PO_Validation_Status__c ='Success';
            update poStageObj;
            
            Opportunity opp = [SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c FROM Opportunity WHERE Name = 'New mAWS Deal' LIMIT 1];
            /*for(Opportunity oppitem : opp){
                oppitem.StageName = OPP_STAGENAME_MAP.get(6);
                oppitem.SBQQ__Ordered__c = false;
            }*/
            opp.StageName = OPP_STAGENAME_MAP.get(6);
            opp.Hold_Code__c = 'Unapproved Quote';
            update opp;
          //  opp = [SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c, ContractManufacturer__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
            ctrl = new ApexPages.StandardController(poStageObj);
            poController = new AcceptPOController(ctrl);
            poController.savePO();
            List<Opportunity> listOfOpp = new List<Opportunity>{opp};
            if(opp != null){
                AcceptPOHelper.autoAcceptPO(null, new Map<Id,Opportunity>(listOfOpp), new set<Id>{opp.id}); 
            }
            Schema.SObjectType sot = Schema.Opportunity.SObjectType;
            Integer s_num = 1;
            String result = String.valueOf(s_num++);
            Id opptyId = sot.getDescribe().getKeyPrefix() +
                         '0'.repeat(12-result.length()) + result;
			AcceptPOHelper.autoPoSubmission(opptyId);
			AcceptPOHelper.createErrorLogs('test error', 0, new set<Id>());
            
            Test.stopTest(); 
        }
        SBQQ.TriggerControl.enable();
        System.Assert(ords.isEmpty());
    }
    
    /*@IsTest
    static void oppToStg6PONull() {  
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        Opportunity oppList = [SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c FROM Opportunity WHERE Name = 'New mAWS Deal' LIMIT 1];
        
        SBQQ__Quote__c quoteObj=[Select id,SBQQ__Status__c,SBQQ__Type__c,Renewal_Opportunity__c,Is_RWD_Polaris_Quote__c,Opportunity_Program__c 
                                 from 
                                 SBQQ__Quote__c limit 1];
        quoteObj.SBQQ__Type__c='Quote';
        quoteObj.Renewal_Opportunity__c=oppList.Id;
        quoteObj.SBQQ__ExpirationDate__c = System.today().addDays(-1);
        quoteObj.Is_RWD_Polaris_Quote__c=true;
        quoteObj.Opportunity_Program__c='Conversion';
        update quoteObj;
        
        List<Account> accList=[Select id from Account limit 2];

        PO_Stage__c po = [Select id,EDI_DISTI_ID__c,PO_Internal_Validation_Status__c,PO_Validation_Status__c,Quote__c,
                                     (Select id ,Opportunity_Program__c from Quotes__r)
                                      from PO_Stage__c limit 1];

        po.Quote__c=quoteObj.id;
        //po.EDI_DISTI_ID__c = 'PO PDF';
        update po;
        
        List<Order> ords = [SELECT Id FROM Order];
        delete ords;
        //System.assertEquals(0, ords.size());
        System.runAs(usr) {
        Test.startTest();
            Opportunity opp = [SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c FROM Opportunity WHERE Name = 'New mAWS Deal' LIMIT 1];
            //opp.StageName = OPP_STAGENAME_MAP.get(6);
            opp.ContractManufacturer__c = 'Flextronics International USA, Inc.';
            update opp;
            opp = [SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c, ContractManufacturer__c, CM_Notification_To_Distributor__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
            Test.stopTest();
        }
        ApexPages.StandardController ctrl1 = new ApexPages.StandardController(po);
        AcceptPOController poController = new AcceptPOController(ctrl1);
        poController.savePO();
        //System.assertEquals(0, ords.size());
    }*/
    /**
      * @description This method check Polaris Quote PO Validation
      */
    @isTest
    static void testPolarisQuotePath() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        System.runAs(usr) {
            Test.startTest();
            SBQQ__Quote__c quote = [SELECT Id, SBQQ__PaymentTerms__c FROM SBQQ__Quote__c LIMIT 1];
            quote.Is_RWD_Polaris_Quote__c = true;
            update quote;
            
            PO_Stage__c po = [SELECT Id, Quote__c, Payment_Terms__c,Customer_Requested_Ship_Date__c,Quote_number__c,
                              EDI_DISTI_ID__c, PO_Internal_Validation_Status__c,PO_Validation_Status__c,ContractManufacturer__c,
                              Bill_To_Name__c, Bill_To_Name__r.Payment_Term__c
                              FROM PO_Stage__c WHERE Quote__c = :quote.Id LIMIT 1];
            po.EDI_DISTI_ID__c = 'EDI123';
            po.PO_Internal_Validation_Status__c = 'Internal Failure';
            po.PO_Validation_Status__c = 'Success';
            update po;
            
            ApexPages.StandardController sc = new ApexPages.StandardController(po);
            AcceptPOController controller = new AcceptPOController(sc);
            
            System.assert(controller.errorMessagesMap.containsKey('External Validations Done'), 'Should validate external logic for Polaris');
            Test.stopTest();
        }
    }
    /**
      * @description This method check PO PDF Validations
      */
    @isTest
    static void testAcceptPOControllerWithValidPOPDF() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        System.runAs(usr) {
            Test.startTest();
               insert new List<SObject>{
                new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getOrganizationId(), Disable_OpportunityValidationRules__c = true, Disable_Account_Old_Trigger__c = true)};
            PO_Stage__c stage = [SELECT Id,Quote__c,EDI_DISTI_ID__c, PO_Internal_Validation_Status__c,PO_Validation_Status__c,ContractManufacturer__c FROM PO_Stage__c WHERE EDI_DISTI_ID__c = 'PO PDF' LIMIT 1];
            
            SBQQ__Quote__c quote = [SELECT Id, SBQQ__Opportunity2__r.StageName, SBQQ__ExpirationDate__c FROM SBQQ__Quote__c WHERE Id = :stage.Quote__c];
            Opportunity opp = [SELECT Id, StageName, Distributor_Lookup__c FROM Opportunity WHERE Id = :quote.SBQQ__Opportunity2__c];
            
            opp.StageName = '6 PO With Channel';
            flowcontroll.opportunityTriggerHandler = false;
            update opp;
            
            quote.SBQQ__ExpirationDate__c = System.today().addDays(2);
            quote.ProcessType__c = '';
            update quote;
            
            stage.Bill_To_Name__c = opp.Distributor_Lookup__c;
            update stage;
            
            ApexPages.StandardController sc = new ApexPages.StandardController(stage);
            AcceptPOController controller = new AcceptPOController(sc);
            controller.disableCmValidation = false;
            controller = new AcceptPOController(sc);

            
            System.assertNotEquals(null, controller);
            //System.assertEquals(true, controller.disableButton, 'Button should be enabled for successful validation');
            System.assert(controller.errorMessagesMap.containsKey('Is Primary Quote Approved'), 'Validation keys missing');
            
            Test.stopTest();
        }
    }
    /**
      * @description This method check PO with External Failure
      */
    @isTest
    static void testAcceptPOControllerWithValidationFailure() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        System.runAs(usr) {
            Test.startTest();
            
            PO_Stage__c stage = [SELECT Id,Quote__c,EDI_DISTI_ID__c, PO_Internal_Validation_Status__c,PO_Validation_Status__c,ContractManufacturer__c FROM PO_Stage__c WHERE PO_Internal_Validation_Status__c = 'Internal Failure' LIMIT 1];
            stage.PO_Validation_Status__c = 'Failure';
            update stage;
            
            ApexPages.StandardController sc = new ApexPages.StandardController(stage);
            AcceptPOController controller = new AcceptPOController(sc);
            
            System.assert(controller.disableButton, 'Should disable when PO validation failed');
            System.assert(controller.errorMessagesMap.containsKey('External Validations Done'), 'Expected validation failure');
            
            Test.stopTest();
        }
    }
    /**
      * @description This method covers the reject PO method from AcceptPOController
      */
    @isTest
    static void testToggleRejectAndRejectWithoutMessage() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        System.runAs(usr) {
            Test.startTest();
            PO_Stage__c stage = [SELECT Id,Quote__c,EDI_DISTI_ID__c, PO_Internal_Validation_Status__c,PO_Validation_Status__c,ContractManufacturer__c FROM PO_Stage__c WHERE EDI_DISTI_ID__c = 'PO PDF' LIMIT 1];
            
            ApexPages.StandardController sc = new ApexPages.StandardController(stage);
            AcceptPOController controller = new AcceptPOController(sc);
            
            PO_Item_Stage__c PoIS = new PO_Item_Stage__c();
            PoIS.Buyer_Part_Number__c='1234';
            PoIS.EDI_Line_Number__c ='100';
            PoIS.Quantity__c = 1;
            PoIS.Stage_PO__c= stage.id;
            PoIS.UnitPrice__c=1000;
            insert PoIS;
            
            controller = new AcceptPOController(sc);
            
            SBQQ__Quote__c quote = [SELECT Id, SBQQ__Primary__c, SBQQ__Status__c FROM SBQQ__Quote__c WHERE Id =: stage.Quote__c LIMIT 1];
            quote.SBQQ__Status__c = 'Draft';
            update quote;
            
            controller = new AcceptPOController(sc);
            
            quote.SBQQ__Primary__c = false;
            update quote;
            
            controller = new AcceptPOController(sc);
            
            quote.SBQQ__Primary__c = true;
            quote.SBQQ__Status__c = 'Approved';
            update quote;
            
            controller.toggleReject();
            System.assert(controller.displayInputMessagePanel, 'toggleReject should enable the input panel');
            
            // Attempt reject without a reason
            controller.inputMessage = '';
            PageReference result = controller.reject();
            System.assertEquals(null, result, 'Reject without message should return null');
            
            stage.Payment_Terms__c = null;
            update stage;
            controller = new AcceptPOController(sc);
            Test.stopTest();
        }
    }
    /**
      * @description This method covers the reject PO method from AcceptPOController
      */
    @isTest
    static void testRejectWithMessage() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        System.runAs(usr) {
            Test.startTest();
            
            PO_Stage__c stage = [SELECT Id,Quote__c,EDI_DISTI_ID__c, PO_Internal_Validation_Status__c,PO_Validation_Status__c,ContractManufacturer__c FROM PO_Stage__c WHERE EDI_DISTI_ID__c = 'PO PDF' LIMIT 1];
            ApexPages.StandardController sc = new ApexPages.StandardController(stage);
            AcceptPOController controller = new AcceptPOController(sc);
            
            controller.inputMessage = 'Test rejection reason';
            PageReference result = controller.reject();
            
            System.assertNotEquals(null, result, 'Reject with valid reason should redirect');
            System.assert(result.getUrl().contains(stage.Id));
            
            PO_Stage__c updated = [SELECT PO_Validation_Status__c, Rejection_Reason__c FROM PO_Stage__c WHERE Id = :stage.Id];
            System.assertEquals('Failure', updated.PO_Validation_Status__c);
            System.assertEquals('Test rejection reason', updated.Rejection_Reason__c);
            
            stage.PO_Internal_Validation_Status__c ='Success';
            update stage;
            controller = new AcceptPOController(sc);
            
                
            Test.stopTest();
        }
    }
    /**
      * @description This method covers the ifs related to Quote
      */
    @isTest
    static void testQuotePrimaryButNotApproved() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        System.runAs(usr) {
            SBQQ__Quote__c quote = [SELECT Id, SBQQ__Account__c,SBQQ__Opportunity2__c,SBQQ__PricebookId__c,SBQQ__Primary__c, SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];
            quote.SBQQ__Primary__c = true;
            quote.SBQQ__Status__c = 'Draft';
            update quote;
            
            PO_Stage__c po = [SELECT Id,Bill_To_Name__c,Ship_to_Account_name__c,PoNumber__c,ShippingCity__c,Note_on_Contingency_and_Special_Language__c,
                              Customer_Requested_Ship_Date__c,ShippingCountryCode__c,ShippingStateCode__c,ShippingPostalCode__c,ShippingStreet__c,
                              Shipping_Carrier__c,Shipping_Method__c,Service_Level__c,Payment_Terms__c,Ship_To_Contact_Name__c,ContractManufacturer__c,
                              End_User_PO__c,Ship_To_Phone_Number__c,Shipping_Account_Number__c,Partner_Name__c,Ship_to_Email__c,Opportunity__c,TotalAmount__c,
                              Quote__r.SBQQ__Opportunity2__c, Expected_number_of_POs__c,Quote__c,Quote_number__c,EDI_DISTI_ID__c,
                              PO_Internal_Validation_Status__c,PO_Validation_Status__c, Bill_To_Name__r.Payment_Term__c FROM PO_Stage__c WHERE Quote__c = :quote.Id LIMIT 1];
            po.EDI_DISTI_ID__c = 'EDI123';
            po.PO_Internal_Validation_Status__c = 'Internal Failure';
            po.PO_Validation_Status__c = 'Success';
            po.PoDate__c = system.today();
            po.Customer_Requested_Ship_Date__c = String.ValueOf(system.today().addDays(-20));
            update po;
            Account acc = [SELECT Id FROM Account WHERE Id != : po.Bill_To_Name__c];
            TriggerControl.stopOrderTrigger = true;
            Map<String, Object> OrderMap = new Map<String, Object>{
                'Type' => 'Revenue',
                    'Send_for_Polaris_Fulfilment__c' => true,
                    'AccountId' => quote.SBQQ__Account__c,
                    'OpportunityId' => quote.SBQQ__Opportunity2__c,
                    'EffectiveDate' => system.today(),
                    'Order_Status__c' => null,
                    'Sell_to_Partner__c' => acc.Id,
                    'Bill_To_Name__c' => po.Bill_To_Name__c,
                    'Status' => 'Pending',
                    'Sync_to_NetSuite__c' => true,
                    'ShippingCountryCode' => 'US',
                    'ShippingStateCode' => 'CA',
                    'ShippingStreet' => 'Test Street',
                    'ShippingCity' => 'Test City',
                    'ShippingState' => 'California',
                    'ShippingCountry' => 'United States',
                    'ShippingPostalcode' => '94820',
                    'ship_To_Name__c' => quote.SBQQ__Account__c,
                    'ShipToContactName__c' => 'Test',
                    'Pricebook2Id' => quote.SBQQ__PricebookId__c ,
                    'Have_Polaris_Products__c' => false,
                    'Polaris_Fulfillment_Status__c' => 'Completed',
                    'Original_Est_Ship_Date__c' => Date.today().addDays(30),
                    'Est_Ship_Date__c' => null,
                    'Order_Splitted__c' => true,
                    'Order_Sub_Type__c' => 'Renewal'
                    };
                        
                        Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
            insert Ord;
            
            Test.startTest();
            AcceptPOController.disableCmValidationInTest = false;
            ApexPages.StandardController sc = new ApexPages.StandardController(po);
            AcceptPOController controller = new AcceptPOController(sc);
            System.assert(controller.disableButton, 'Should be disabled');
            try{
            	controller.savePO();
            }catch(system.Exception e){
                system.debug(LoggingLevel.DEBUG,'Catch Exception');
            }
            
            quote.SBQQ__Primary__c = false;
            quote.SBQQ__ExpirationDate__c = system.today().addDays(2);
            update quote;
            controller = new AcceptPOController(sc);
            Opportunity opp = new Opportunity(Id = ord.OpportunityId);
            opp.StageName = '6 PO With Channel';
            update opp;
            Order o = Ord.clone();
            insert o;
            controller = new AcceptPOController(sc);
            TriggerControl.stopOrderTrigger = false;
            Test.stopTest();
        }
    }
}