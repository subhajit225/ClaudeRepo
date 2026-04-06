@IsTest
public class DemandMatrixCalculationTest { 
    /*
    *
    Test class for DemandMatrixCalculation
    *
    */
    private static Map<Integer, String> OPP_STAGENAME_MAP = new Map<Integer, String>{ 4 => '4 Business Justification', 5 => '5 Negotiate & Close', 6 => '6 PO With Channel' };
 
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
                    Disable_SBQQ_QuoteLine_Validation_Rules__c = true,
					Disable_Order_Old_Trigger__c = true,
                    Disable_OrderItem_Old_Trigger__c = true,
                    Disable_Opportunity_Triggers__c = true,
                    
                    Disable_Opportunity_Validation_Rules__c = true,
                    Enable_Logs__c = true
                ),
                new POValidation_ErrorCode__c(Name = 'INT CM Mismatch', Code__c = 'INT-14', Error_Issue__c = 'CM Mismatch')
            };

            TriggerControl.stopOrderItemTrigger = true;
            TriggerControl.stopOrderTrigger = true;

            Map<String, Schema.RecordTypeInfo> AcRecTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByName();
            List<Account> accounts = new List<Account>{
                new Account(Name = 'Test Account', RecordTypeId = AcRecTypeInfo.get('Customer/Prospect').getRecordTypeId()),
                new Account(Name = 'Promark Technology, Inc.', Type = 'Distributor', RecordTypeId = AcRecTypeInfo.get('Partner/Distributor').getRecordTypeId())
            };
            insert accounts;
            Id standardPBId = test.getStandardPricebookId();

            Opportunity opp = TestDataFactory.getOpportunity(accounts[0]);
            opp.Distributor_Lookup__c = accounts[1].Id;
            opp.Partner_Lookup__c = accounts[1].Id;
            opp.Aspen_Eligibility__c = 'Proposed Aspen';
            opp.StageName = OPP_STAGENAME_MAP.get(4);
            opp.Pricebook2Id =  System.Label.CPQPricebookId;
            opp.ContractManufacturer__c='Super Micro Computer, Inc.';
            insert opp;
            
            /*Opportunity oppSecond = TestDataFactory.getOpportunity(accounts[0]);
            opp.Distributor_Lookup__c = accounts[1].Id;
            opp.Partner_Lookup__c = accounts[1].Id;
            opp.Aspen_Eligibility__c = 'Actual non-Aspen';
            opp.StageName = OPP_STAGENAME_MAP.get(4);
            opp.Pricebook2Id =  System.Label.CPQPricebookId;
            insert oppSecond;*/

            Opportunity oppNew = new opportunity();
            oppNew.Name = 'New mAWS Deal Second';
            oppNew.AccountId = accounts[1].Id;
            oppNew.Distributor_Lookup__c = accounts[1].Id;
            oppNew.Partner_Lookup__c = accounts[1].Id;
            oppNew.Aspen_Eligibility__c = 'Proposed non-Aspen';
            oppNew.StageName = OPP_STAGENAME_MAP.get(4);
            oppNew.Pricebook2Id =  standardPBId;
        	oppNew.CloseDate = System.today()+30;
            insert oppNew;
            
            
            List<Product2> sampleProducts = new List<Product2>{
                // 0
                new Product2(
                    Name = 'CPQ Bundle Product',
                    ProductCode = 'CPQ Bundle Product',
                    IsActive = true,
                    Product_Level__c = 'Hybrid Software',
                    SBQQ__Hidden__c = true,
                    SBQQ__ExcludeFromOpportunity__c = true,
                    New_CPQ_Product__c = true
                ),

                new Product2(
                    Name = 'RCA-DDR4-16',
                    ProductCode = 'RCA-DDR4-16',
                    IsActive = true,
                    Product_Level__c = 'Hardware'
                ),
                new Product2(
                    Name = 'RBK-MSP-R6404S-HW-02',
                    ProductCode = 'RBK-MSP-R6404S-HW-02',
                    IsActive = true,
                    Product_Level__c = 'Hardware'
                ),    
                    
                // 1
                new Product2(
                    Name = 'HW',
                    ProductCode = 'HW',
                    Category__c = 'Platform',
                    Family = 'r300',
                    Usable_Capacity__c = 1,
                    Product_Level__c = 'Hardware',
                    Product_Type__c = 'Hardware',
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
                    SBQQ__SubscriptionType__c = 'Renewable'
                )
            };
            insert sampleProducts;

            SBQQ__Quote__c quoteSecond = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(
                new SBQQ__Quote__c(),
                new Map<String, Object>{
                    'SBQQ__Account__c' => oppNew.AccountId,
                    'SBQQ__Opportunity2__c' => oppNew.Id,
                    'SBQQ__Primary__c' => true,
                    'SBQQ__SubscriptionTerm__c' => 12,
                    // 'Is_RWD_Polaris_Quote__c' => true,
                    'SBQQ__PaymentTerms__c' => 'Net 45',
                    'SBQQ__Type__c'=> 'Renewal+Expansion'
                }
            );
            insert quoteSecond;


            List<PricebookEntry> entries = new List<PricebookEntry>{
                new PricebookEntry( Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[0].Id, IsActive = true, UnitPrice = 100),
                    new PricebookEntry( Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[1].Id, IsActive = true, UnitPrice = 0),
                   // new PricebookEntry( Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[2].Id, IsActive = true, UnitPrice = 100),
                    
                    new PricebookEntry( Pricebook2Id = System.Label.CPQPricebookId, Product2Id = sampleProducts[0].Id, IsActive = true, UnitPrice = 100),
                    new PricebookEntry( Pricebook2Id = System.Label.CPQPricebookId, Product2Id = sampleProducts[1].Id, IsActive = true, UnitPrice = 0)
                   // new PricebookEntry( Pricebook2Id = System.Label.CPQPricebookId, Product2Id = sampleProducts[2].Id, IsActive = true, UnitPrice = 0)
                    
                    };
            insert entries;
            List<Product2> prods = new List<Product2>();
            Product2 newProd = new Product2(
                Name = 'RBK-MSP-R6404S-HW-01',
                ProductCode = 'RBK-MSP-R6404S-HW-01',
                IsActive = true,
                Product_Level__c = 'Hardware'

            );
            prods.add(newProd);
            Product2 newProd2 = new Product2(
                Name = 'RCA-R6KSE-64-N-02',
                ProductCode = 'RBK-MSP-R6404S-HW-01',
                IsActive = true,
                Product_Level__c = 'Hardware'

            );
            prods.add(newProd2);

            Product2 newProd3 = new Product2(
                 Name = 'RCA-DDR4-16',
                ProductCode = 'RCA-DDR4-16',
                IsActive = true,
                Product_Level__c = 'Hardware'

            );
            prods.add(newProd3);

            insert prods;
        
                PriceBookEntry pbEntry = new PriceBookEntry(
                UnitPrice = 400,
                PriceBook2Id = oppNew.PriceBook2Id,
                Product2Id = newProd.Id,
                IsActive = true,
                UseStandardPrice=false);
                insert pbEntry ;
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteSecond.Id, SBQQ__Product__c=newProd.Id, SBQQ__Quantity__c=10, SBQQ__Number__c=1);  
        qliList.add(qli1);
        SBQQ__QuoteLine__c qli12 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteSecond.Id, SBQQ__Product__c=newProd2.Id, SBQQ__Quantity__c=10, SBQQ__Number__c=1);  
        qliList.add(qli12);
        SBQQ__QuoteLine__c qli13 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteSecond.Id, SBQQ__Product__c=newProd3.Id, SBQQ__Quantity__c=10, SBQQ__Number__c=1);  
        qliList.add(qli13);
        insert qliList;
        
        OpportunityLineItem oppLine = new OpportunityLineItem(pricebookentryid=pbEntry.Id,TotalPrice=2000, Quantity = 2,OpportunityID = oppNew.Id, SBQQ__QuoteLine__c=qli1.Id);
        insert oppLine;
            
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
            
            insert quote;
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
            Test.startTest();
            String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
            QuoteCalculator calculator = new QuoteCalculator();
            calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
            quote.ApprovalStatus__c = 'Approved';
            quote.SBQQ__Status__c = 'Approved';
            quote.Payment_year_2__c = 0;
            update quote;
            ShGl_DisableBusinessLogic__c disableBusinessLogic = ShGl_DisableBusinessLogic__c.getInstance();
            disableBusinessLogic.Disable_Opportunity_Triggers__c = false;
            update disableBusinessLogic;
            Test.stopTest();
            List<ContractManufacturerAllocation__c> contarct = new List<ContractManufacturerAllocation__c>();
            ContractManufacturerAllocation__c contractmanufacturer = new ContractManufacturerAllocation__c(
                ContractManufacturer__c='Super Micro Computer, Inc.',
                Product__c = newProd.id,
                Quarter__c = GeneralUtility.determineFinancialYearAndQuarter(System.today()),
                TotalFulfillment__c = 444,
                Type__c = 'Non Aspen',
                Distributor__c = accounts[1].Id
            );
            contarct.add(contractmanufacturer);
            ContractManufacturerAllocation__c contractmanufacturer2 = new ContractManufacturerAllocation__c(
                ContractManufacturer__c='Super Micro Computer, Inc.	',
                Product__c = newProd.id,
                Quarter__c = GeneralUtility.determineFinancialYearAndQuarter(System.today()),
                TotalFulfillment__c = 444,
                Type__c = 'Aspen',
                Distributor__c = accounts[1].Id);
            contarct.add(contractmanufacturer2);
            ContractManufacturerAllocation__c contractmanufacturer3 = new ContractManufacturerAllocation__c(
                ContractManufacturer__c='Super Micro Computer, Inc.	',
                Product__c = newProd.id,
                Quarter__c = 'FY2022Q4',
                TotalFulfillment__c = 444,
                Type__c = 'Aspen',
                Distributor__c = accounts[1].Id
            );
            contarct.add(contractmanufacturer3);
            insert contarct;
            DemandMatrixLine__c dmLine = new DemandMatrixLine__c(
            QuoteLine__c = qli1.Id,
            Distributor__c=accounts[1].Id,
            Quarter__c=GeneralUtility.determineFinancialYearAndQuarter(System.today()),
            Status__c='Active',
            Opportunity__c=opp.id,
            Quote__c=quote.id);
            insert dmLine;
        }
    }
    // Directly to STG 5
    @IsTest
    static void oppToStg5() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        System.runAs(usr) {
            Opportunity opp = [SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c FROM Opportunity WHERE Name = 'New mAWS Deal' LIMIT 1];
            opp.StageName = OPP_STAGENAME_MAP.get(5);
            opp.Accept_Conditions__c = true;
            Test.startTest();
            update opp;
            Test.stopTest();
            opp = [SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c, ContractManufacturer__c, CM_Notification_To_Distributor__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        }
    }
    // Directly to STG 6


  /*   @IsTest
    static void oppToStg6NonAspen() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        System.runAs(usr) {
        Test.startTest();
            Opportunity opp = [SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c FROM Opportunity WHERE Name = 'New mAWS Deal' LIMIT 1];
            opp.Aspen_Eligibility__c = 'Actual non-Aspen';
            opp.StageName = OPP_STAGENAME_MAP.get(6);
            update opp;
            opp = [SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c, ContractManufacturer__c, CM_Notification_To_Distributor__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
            Test.stopTest();
        }
    }*/

    
    
    // Directly to STG 5 -> STG 6
    @IsTest
    static void oppToStg5_To6() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        System.runAs(usr) {
    
            Opportunity opp = [SELECT Id, Name, StageName, Override__c,Pricebook2Id, Aspen_Eligibility__c FROM Opportunity WHERE Name = 'New mAWS Deal' LIMIT 1];
            opp.StageName = OPP_STAGENAME_MAP.get(5);
            opp.Accept_Conditions__c = true;
            update opp;
            opp.StageName = OPP_STAGENAME_MAP.get(6);
            Test.startTest();
            //update opp;
            Database.SaveResult srList = Database.update(opp, false);
            system.debug('Update result===>'+srList);
            opp = [SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c, ContractManufacturer__c, CM_Notification_To_Distributor__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
            Test.stopTest();
        }
    }

    // Directly to STG 5 -> Recalculate
    @IsTest
    static void oppToStg5Recalculate() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        System.runAs(usr) {
        Test.startTest();
            Opportunity opp = [SELECT Id, Name, StageName, CM_Notification_To_Distributor__c, Override__c, Aspen_Eligibility__c FROM Opportunity WHERE Name = 'New mAWS Deal' LIMIT 1];
            opp.StageName = OPP_STAGENAME_MAP.get(5);
            opp.Accept_Conditions__c = true;
            update opp;
            opp.CM_Notification_To_Distributor__c = 'Recalculate CM recommendation';
           // update opp;
            opp = [SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c, ContractManufacturer__c, CM_Notification_To_Distributor__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
            Test.stopTest();
        }
    }

    // Directly to STG 6 -> Recalculate
    @IsTest
    static void oppToStg6Recalculate() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        System.runAs(usr) {
        Test.startTest();
            Opportunity opp = [SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c FROM Opportunity WHERE Name = 'New mAWS Deal' LIMIT 1];
           // opp.StageName = OPP_STAGENAME_MAP.get(6);
            //update opp;
            opp.CM_Notification_To_Distributor__c = 'Recalculate CM recommendation';
           // update opp;
            opp = [SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c, ContractManufacturer__c, CM_Notification_To_Distributor__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
            Test.stopTest();
        }
    }
    // Directly to STG 5 -> CM Blank -> to STG 6
    @IsTest
    static void oppToStg5BlankCmToStg6() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        System.runAs(usr) {
        Test.startTest();
            Opportunity opp = [SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c FROM Opportunity WHERE Name = 'New mAWS Deal' LIMIT 1];
            opp.StageName = OPP_STAGENAME_MAP.get(5);
            opp.Accept_Conditions__c = true;
            update opp;
            opp.ContractManufacturer__c = null;
            update opp;
            opp.StageName = OPP_STAGENAME_MAP.get(6);
            opp.Pricebook2Id = System.Label.CPQPricebookId;
            //update opp;
            opp = [SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c, ContractManufacturer__c, CM_Notification_To_Distributor__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
            Test.stopTest();
        }
    }
    // Directly to STG 5 -> CM Blank -> to STG 4
    @IsTest
    static void oppToStg5BlankCmToStg4() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        System.runAs(usr) {
        Test.startTest();
            Opportunity opp = [SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c FROM Opportunity WHERE Name = 'New mAWS Deal' LIMIT 1];
            opp.StageName = OPP_STAGENAME_MAP.get(5);
            opp.Accept_Conditions__c = true;
            update opp;
            opp.StageName = OPP_STAGENAME_MAP.get(4);
            opp.ContractManufacturer__c = null;
            update opp;
            opp = [SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c, ContractManufacturer__c, CM_Notification_To_Distributor__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
            Test.stopTest();
        }
    }

    // Directly to STG 5 -> DML deleted -> STG 6
    @IsTest
    static void oppToStg5DeleteDmLinedCmToStg6() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        System.runAs(usr) {
        Test.startTest();
            Opportunity opp = [SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c FROM Opportunity WHERE Name = 'New mAWS Deal' LIMIT 1];
            opp.StageName = OPP_STAGENAME_MAP.get(5);
            opp.Accept_Conditions__c = true;
            update opp;
            delete [SELECT Id FROM DemandMatrixLine__c];
            opp.StageName = OPP_STAGENAME_MAP.get(6);
            //update opp;
            opp = [
                SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c, ContractManufacturer__c, CM_Notification_To_Distributor__c, (SELECT Id, Status__c, Product__r.ProductCode FROM DemandMatrixLines__r)
                FROM Opportunity
                WHERE Id = :opp.Id
                LIMIT 1
            ];
            Test.stopTest();
        }
    }
    // Directly to STG 5 -> DML deleted -> Recalculate
    @IsTest
    static void oppToStg5DeleteDmLinedCmRecalculate() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        System.runAs(usr) {
        Test.startTest();
            Opportunity opp = [SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c FROM Opportunity WHERE Name = 'New mAWS Deal' LIMIT 1];
            opp.StageName = OPP_STAGENAME_MAP.get(5);
            opp.Accept_Conditions__c = true;
            update opp;
            delete [SELECT Id FROM DemandMatrixLine__c];
            opp.CM_Notification_To_Distributor__c = 'Recalculate CM recommendation';
            update opp;
            opp = [
                SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c, ContractManufacturer__c, CM_Notification_To_Distributor__c, (SELECT Id, Status__c, Product__r.ProductCode FROM DemandMatrixLines__r)
                FROM Opportunity
                WHERE Id = :opp.Id
                LIMIT 1
            ];
            Test.stopTest();
        }
    }

    // Directly to STG 5 -> DML Deactivated -> to STG 6
    @IsTest
    static void oppToStg5DeactivateDmLineToStg6() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        System.runAs(usr) {
        Test.startTest();
            Opportunity opp = [SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c FROM Opportunity WHERE Name = 'New mAWS Deal' LIMIT 1];
            opp.StageName = OPP_STAGENAME_MAP.get(5);
            opp.Accept_Conditions__c = true;
            update opp;
            List<DemandMatrixLine__c> dmLines = new List<DemandMatrixLine__c>();
            for (DemandMatrixLine__c dmLine : [SELECT Id FROM DemandMatrixLine__c]) {
                dmLines.add(dmLine);
            }
            update dmLines;
            opp.StageName = OPP_STAGENAME_MAP.get(6);
           // update opp;
            opp = [
                SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c, ContractManufacturer__c, CM_Notification_To_Distributor__c, (SELECT Id, Status__c, Product__r.ProductCode FROM DemandMatrixLines__r)
                FROM Opportunity
                WHERE Id = :opp.Id
                LIMIT 1
            ];
            Test.stopTest();
        }
    }
    
    // Directly to STG 5 -> Quote Changed -> to STG 6
    @IsTest
    static void oppToStg5changedQuoteToStg6() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        System.runAs(usr) {
        Test.startTest();
            Opportunity opp = [SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c FROM Opportunity WHERE Name = 'New mAWS Deal' LIMIT 1];
            opp.StageName = OPP_STAGENAME_MAP.get(5);
            opp.Accept_Conditions__c = true;
            update opp;
            SBQQ__QuoteLine__c hwQuoteLine = [SELECT Id, SBQQ__Quantity__c FROM SBQQ__QuoteLine__c WHERE SBQQ__ProductCode__c = 'HW' LIMIT 1];
            hwQuoteLine.SBQQ__Quantity__c += 1;
            update hwQuoteLine;
            opp.StageName = OPP_STAGENAME_MAP.get(6);
            //update opp;
            opp = [
                SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c, ContractManufacturer__c, CM_Notification_To_Distributor__c, (SELECT Id, Status__c, Product__r.ProductCode FROM DemandMatrixLines__r)
                FROM Opportunity
                WHERE Id = :opp.Id
                LIMIT 1
            ];
            Test.stopTest();
        }
    }

    // Directly to STG 5 -> Quote Changed -> to STG 4
    @IsTest
    static void oppToStg5changedQuoteToStg4() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        System.runAs(usr) {
        Test.startTest();
            Opportunity opp = [SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c FROM Opportunity WHERE Name = 'New mAWS Deal' LIMIT 1];
            opp.StageName = OPP_STAGENAME_MAP.get(5);
            opp.Accept_Conditions__c = true;
            update opp;
            SBQQ__QuoteLine__c hwQuoteLine = [SELECT Id, SBQQ__Quantity__c FROM SBQQ__QuoteLine__c WHERE SBQQ__ProductCode__c = 'HW' LIMIT 1];
            hwQuoteLine.SBQQ__Quantity__c += 1;
            update hwQuoteLine;
            opp.StageName = OPP_STAGENAME_MAP.get(4);
            update opp;
            opp = [
                SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c, ContractManufacturer__c, CM_Notification_To_Distributor__c, (SELECT Id, Status__c, Product__r.ProductCode FROM DemandMatrixLines__r)
                FROM Opportunity
                WHERE Id = :opp.Id
                LIMIT 1
            ];
            Test.stopTest();
        }
    }

    // Directly to STG 5 -> Quote Changed -> to STG 4 -> to STG 5
    @IsTest
    static void oppToStg5changedQuoteToStg4ToStg5() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        System.runAs(usr) {
        Test.startTest();
            Opportunity opp = [SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c FROM Opportunity WHERE Name = 'New mAWS Deal' LIMIT 1];
            opp.StageName = OPP_STAGENAME_MAP.get(5);
            opp.Accept_Conditions__c = true;
            update opp;
            SBQQ__QuoteLine__c hwQuoteLine = [SELECT Id, SBQQ__Quantity__c FROM SBQQ__QuoteLine__c WHERE SBQQ__ProductCode__c = 'HW' LIMIT 1];
            hwQuoteLine.SBQQ__Quantity__c += 1;
            update hwQuoteLine;
            opp.StageName = OPP_STAGENAME_MAP.get(4);
            update opp;
            opp.StageName = OPP_STAGENAME_MAP.get(5);
            update opp;
            opp = [
                SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c, ContractManufacturer__c, CM_Notification_To_Distributor__c, (SELECT Id, Status__c, Product__r.ProductCode FROM DemandMatrixLines__r)
                FROM Opportunity
                WHERE Id = :opp.Id
                LIMIT 1
            ];
            Test.stopTest();
        }
    }
    
    // Directly to STG 5 -> Quote Changed -> Recalculate
    @IsTest
    static void oppToStg5changedQuoteRecalculate() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        System.runAs(usr) {
        Test.startTest();
            Opportunity opp = [SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c FROM Opportunity WHERE Name = 'New mAWS Deal' LIMIT 1];
            opp.StageName = OPP_STAGENAME_MAP.get(5);
            opp.Accept_Conditions__c = true;
            update opp;
            SBQQ__QuoteLine__c hwQuoteLine = [SELECT Id, SBQQ__Quantity__c FROM SBQQ__QuoteLine__c WHERE SBQQ__ProductCode__c = 'HW' LIMIT 1];
            hwQuoteLine.SBQQ__Quantity__c += 1;
            update hwQuoteLine;
            opp.CM_Notification_To_Distributor__c = 'Recalculate CM recommendation';
           // update opp;
            opp = [
                SELECT Id, Name, StageName, Override__c, Aspen_Eligibility__c, ContractManufacturer__c, CM_Notification_To_Distributor__c, (SELECT Id, Status__c, Product__r.ProductCode FROM DemandMatrixLines__r)
                FROM Opportunity
                WHERE Id = :opp.Id
                LIMIT 1
            ];
            Test.stopTest();
        }
    }

    static PO_Stage__c addShippingDetails(PO_Stage__c poStage) {
        // poStage.Payment_schedule_type__c = 'test';
        poStage.Ship_to_Email__c = 'test@test.com';
        poStage.Ship_To_Contact_Name__c = 'testCon';
        poStage.Ship_To_Phone_Number__c = '7000022448';
        poStage.ShippingCountryCode__c = 'IN';
        poStage.ShippingStateCode__c = 'KA';
        poStage.ShippingCity__c = 'test City';
        poStage.ShippingStreet__c = 'test street';
        poStage.ShippingPostalCode__c = '0000';
        poStage.PO_Validation_Status__c = 'Pending';
        return poStage;
    }
    @isTest
    static void singlePoAutoOrderGenerationSuccess() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        System.runAs(usr) {
            Test.startTest();
            Opportunity opp = [SELECT Id, Name, StageName, ContractManufacturer__c FROM Opportunity WHERE Name = 'New mAWS Deal' LIMIT 1];
            opp.StageName = OPP_STAGENAME_MAP.get(6);
            //update opp;
            SBQQ__Quote__c quote = [
                SELECT Id, Name, SBQQ__NetAmount__c, SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.Distributor_Lookup__c, SBQQ__Account__c, SBQQ__Account__r.Name,SBQQ__Status__c,(SELECT Id, SBQQ__ProductCode__c, SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__NetPrice__c FROM SBQQ__LineItems__r)
                FROM SBQQ__Quote__C
                WHERE SBQQ__Opportunity2__c = :opp.Id
                LIMIT 1
            ];
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
            poStage.Opportunity__c = quote.SBQQ__Opportunity2__c;
            poStage = addShippingDetails(poStage);
            poStage.ContractManufacturer__c = opp.ContractManufacturer__c;
            insert poStage;

            List<PO_Item_Stage__c> poItems = new List<PO_Item_Stage__c>();
            String ediLinenum = '1';
            for (SBQQ__QuoteLine__c quoteLine : quote.SBQQ__LineItems__r) {
                poItems.add(
                    ShGl_TestFactoryHelper.createPOItem(
                        '1234' + ediLinenum,
                        ediLinenum,
                        quoteLine.SBQQ__ProductCode__c,
                        quoteLine.SBQQ__Quantity__c,
                        poStage.Id,
                        quoteLine.SBQQ__SubscriptionTerm__c,
                        quoteLine.SBQQ__NetPrice__c
                    )
                );
                ediLinenum += '1';
            }
            insert poItems;

            POStageHelper.allStagePOmap.clear();
            POStageHelper.quoteMap.clear();
            poStage.PO_Validation_Status__c = 'Staged';
            update poStage;
            Test.stopTest();
            poStage = [
                SELECT
                    Id,
                    PO_Internal_Validation_Status__c,
                    PO_Validation_Status__c,
                    Expected_number_of_POs__c,
                    PO_Index__c,
                    Quote__c,
                    Quote_number__c,
                    TotalAmount__c,
                    Quote__r.ProcessType__c,
                    ContractManufacturer__c,
                    Opportunity__r.ContractManufacturer__c,
                    (SELECT Id, Name, Quantity__c, UnitPrice__c, SubscriptionTerm__c, ProductCode__c FROM PO_Item_Stage__r),
                    (SELECT Error_Code__c, Error_Message__c, Error_Type__c FROM PO_Stage_Errors__r)
                FROM PO_Stage__c
            ];
            // System.debug('### PO Stage : \n' + JSON.serialize(poStage));
            // System.debug('### quote : \n' + JSON.serialize(quote));
        }
    }
    /*@isTest
    static void singlePoAutoOrderGenerationFailure() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        System.runAs(usr) {
            Test.startTest();
            Opportunity opp = [SELECT Id, Name, StageName, ContractManufacturer__c FROM Opportunity WHERE Name = 'New mAWS Deal' LIMIT 1];
            opp.StageName = OPP_STAGENAME_MAP.get(6);
           // TriggerManager.resetTriggerCounter('Opportunity');
            //update opp;
            SBQQ__Quote__c quote = [
                SELECT Id, Name, SBQQ__NetAmount__c, SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.Distributor_Lookup__c, SBQQ__Account__c, SBQQ__Account__r.Name,SBQQ__Status__c,(SELECT Id, SBQQ__ProductCode__c, SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__NetPrice__c FROM SBQQ__LineItems__r)
                FROM SBQQ__Quote__C
                WHERE SBQQ__Opportunity2__c = :opp.Id
                LIMIT 1
            ];
            PO_Stage__c poStage = ShGl_TestFactoryHelper.createPOStage(
                'Promark Technology, Inc.pp',
                'test123',
                System.today().addDays(10),
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
            poStage.Opportunity__c = quote.SBQQ__Opportunity2__c;
            poStage = addShippingDetails(poStage);
            poStage.ContractManufacturer__c = [SELECT MasterLabel FROM AspenConfig__mdt WHERE Type__c = 'C' AND MasterLabel != :opp.ContractManufacturer__c LIMIT 1].MasterLabel;
            insert poStage;

            List<PO_Item_Stage__c> poItems = new List<PO_Item_Stage__c>();
            String ediLinenum = '1';
            for (SBQQ__QuoteLine__c quoteLine : quote.SBQQ__LineItems__r) {
                poItems.add(
                    ShGl_TestFactoryHelper.createPOItem(
                        '1234' + ediLinenum,
                        ediLinenum,
                        quoteLine.SBQQ__ProductCode__c,
                        quoteLine.SBQQ__Quantity__c,
                        poStage.Id,
                        quoteLine.SBQQ__SubscriptionTerm__c,
                        quoteLine.SBQQ__NetPrice__c
                    )
                );
                ediLinenum += '1';
            }
            insert poItems;

            POStageHelper.allStagePOmap.clear();
            POStageHelper.quoteMap.clear();
            poStage.PO_Validation_Status__c = 'Staged';
            update poStage;
            Test.stopTest();
            poStage = [
                SELECT
                    Id,
                    PO_Internal_Validation_Status__c,
                    PO_Validation_Status__c,
                    Expected_number_of_POs__c,
                    PO_Index__c,
                    Quote__c,
                    Quote_number__c,
                    TotalAmount__c,
                    Quote__r.ProcessType__c,
                    ContractManufacturer__c,
                    Opportunity__r.ContractManufacturer__c,
                    (SELECT Id, Name, Quantity__c, UnitPrice__c, SubscriptionTerm__c, ProductCode__c FROM PO_Item_Stage__r),
                    (SELECT Error_Code__c, Error_Message__c, Error_Type__c FROM PO_Stage_Errors__r)
                FROM PO_Stage__c
            ];
            // System.debug('### PO Stage : \n' + JSON.serialize(poStage));
            // System.debug('### quote : \n' + JSON.serialize(quote));
        }
    }*/

    /* @isTest
    static void singlePoManualAcceptSucess() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        System.runAs(usr) {
            Test.startTest();
            Opportunity opp = [SELECT Id,Pricebook2Id, Name, StageName, ContractManufacturer__c FROM Opportunity WHERE Name = 'New mAWS Deal' LIMIT 1];
            opp.StageName = OPP_STAGENAME_MAP.get(6);
             system.debug('price=====>'+opp);
           // opp.Pricebook2Id = Test.getStandardPricebookId(); 
           TriggerManager.resetTriggerCounter('Opportunity');
            update opp;
            SBQQ__Quote__c quote = [
                SELECT Id, Name, SBQQ__NetAmount__c, SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.Distributor_Lookup__c, SBQQ__Account__c, SBQQ__Account__r.Name,SBQQ__Status__c,(SELECT Id, SBQQ__ProductCode__c, SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__NetPrice__c FROM SBQQ__LineItems__r)
                FROM SBQQ__Quote__C
                WHERE SBQQ__Opportunity2__c = :opp.Id
                LIMIT 1
            ];
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
            poStage = addShippingDetails(poStage);
            poStage.ContractManufacturer__c = [SELECT MasterLabel FROM AspenConfig__mdt WHERE Type__c = 'C' AND MasterLabel != :opp.ContractManufacturer__c LIMIT 1].MasterLabel;
            insert poStage;

            List<PO_Item_Stage__c> poItems = new List<PO_Item_Stage__c>();
            String ediLinenum = '1';
            for (SBQQ__QuoteLine__c quoteLine : quote.SBQQ__LineItems__r) {
                poItems.add(
                    ShGl_TestFactoryHelper.createPOItem(
                        '1234' + ediLinenum,
                        ediLinenum,
                        quoteLine.SBQQ__ProductCode__c,
                        quoteLine.SBQQ__Quantity__c,
                        poStage.Id,
                        quoteLine.SBQQ__SubscriptionTerm__c,
                        quoteLine.SBQQ__NetPrice__c
                    )
                );
                ediLinenum += '1';
            }
            insert poItems;

            POStageHelper.allStagePOmap.clear();
            POStageHelper.quoteMap.clear();
            poStage.PO_Validation_Status__c = 'Success';
            poStage.PO_Internal_Validation_Status__c = 'Internal Failure';
            
            update poStage;
            
            AcceptPOController poController = new AcceptPOController(new ApexPages.StandardController(poStage));
            poController.savePO();
            Test.stopTest();

            poStage = [
                SELECT
                    Id,
                    PO_Internal_Validation_Status__c,
                    PO_Validation_Status__c,
                    Expected_number_of_POs__c,
                    PO_Index__c,
                    Quote__c,
                    Quote_number__c,
                    TotalAmount__c,
                    Quote__r.ProcessType__c,
                    ContractManufacturer__c,
                    Opportunity__r.ContractManufacturer__c,
                    (SELECT Id, Name, Quantity__c, UnitPrice__c, SubscriptionTerm__c, ProductCode__c FROM PO_Item_Stage__r),
                    (SELECT Error_Code__c, Error_Message__c, Error_Type__c FROM PO_Stage_Errors__r)
                FROM PO_Stage__c
            ];
            // System.debug('### PO Stage : \n' + JSON.serialize(poStage));
            // System.debug('### quote : \n' + JSON.serialize(quote));
        }
    } */
 
    @IsTest
    static void oppStageCoverageV2() {
        SBQQ.TriggerControl.disable();
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com'];
        List<Account> accounts = [SELECT Id FROM Account LIMIT 5];

        System.runAs(usr) {
            Test.startTest();
                Opportunity opp = TestDataFactory.getOpportunity(accounts[0]);
                opp.Name='Test Account';
                opp.Distributor_Lookup__c = accounts[1].Id;
            	opp.AccountId = accounts[0].Id;
                opp.Partner_Lookup__c = accounts[1].Id;
                opp.Aspen_Eligibility__c = 'Actual non-Aspen';
                opp.StageName = '7 Closed Won';
                opp.Pricebook2Id =  System.Label.CPQPricebookId;
                opp.Opportunity_Sub_Type__c = 'Regular';
                opp.ContractManufacturer__c='Super Micro Computer, Inc.';
                insert opp;
                SBQQ__Quote__c sd = new SBQQ__Quote__c();
                sd.SBQQ__Opportunity2__c =opp.Id;
            	sd.SBQQ__Account__c = accounts[0].Id;
                sd.sendSOWNotification__c = false;
                sd.Task_Products__c='RBK-DISK-RETENTION';
            	sd.SBQQ__Primary__c = true;
                insert sd;
                List<Product2> produs = new List<Product2>();
                Product2 newProd = new Product2(Name = 'RBK-MSP-R6404S-HW-01', family = 'test family', ProductCode = 'OPTY-SPLIT');
                produs.add(newProd);
                Product2 newProd2 = new Product2(
                    Name = 'RCA-R6KSE-64-N-02',
                    ProductCode = 'RBK-MSP-R6404S-HW-01',
                    IsActive = true,
                    Product_Level__c = 'Hardware'
    
                );
                produs.add(newProd2);
                insert produs;
             List<PricebookEntry> entries = new List<PricebookEntry>{
                new PricebookEntry( Pricebook2Id = Test.getStandardPricebookId(), Product2Id = produs[0].Id, IsActive = true, UnitPrice = 100),
                    new PricebookEntry( Pricebook2Id = Test.getStandardPricebookId(), Product2Id = produs[1].Id, IsActive = true, UnitPrice = 0),
                    new PricebookEntry( Pricebook2Id = System.Label.CPQPricebookId, Product2Id = produs[0].Id, IsActive = true, UnitPrice = 100),
                    new PricebookEntry( Pricebook2Id = System.Label.CPQPricebookId, Product2Id = produs[1].Id, IsActive = true, UnitPrice = 0)
                    };
            insert entries;
                SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=sd.Id, SBQQ__Product__c=produs[0].Id, SBQQ__Quantity__c=10, SBQQ__Number__c=1);  
                insert qli1;
                SBQQ__QuoteLine__c qli12 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=sd.Id, SBQQ__Product__c=produs[1].Id, SBQQ__Quantity__c=10, SBQQ__Number__c=1);  
                insert qli12;
                opp.SBQQ__PrimaryQuote__c = sd.Id;
                opp.StageName = '7 Closed Lost';
                update opp;
                TriggerManager.resetTriggerCounter('Opportunity');
                opp.StageName = '6 PO With Channel';
                update opp;
            Test.stopTest();
                DemandMatrixLine__c dmLine = new DemandMatrixLine__c(
                QuoteLine__c = qli12.Id,
                Distributor__c=accounts[1].Id,
                Quarter__c = GeneralUtility.determineFinancialYearAndQuarter(System.today()),
                Status__c='Active',
                Opportunity__c=opp.id,
                Quote__c=sd.id,
                Quantity__c=1);
                insert dmLine;
                //Test.stopTest();
                dmLine.Status__c='tretertwetw';
                dmLine.Quantity__c=1;
                DemandMatrixCalculation obj = new DemandMatrixCalculation(new Map<Id,string>());
                obj.execute(new Set<Id>{opp.Id},new List<DemandMatrixLine__c>{dmLine},new List<ContractManufacturerAllocation__c>());
            	System.assert(dmLine.Status__c != 'Active');
                // obj.cmCalculationAlgoForQuote(sd,new ContractManufacturerAllocation__c());
                // obj.updateOldOrOrphanedDmLines(new List<DemandMatrixLine__c>{dmLine});
   
        }
        SBQQ.TriggerControl.enable();
    } 

}