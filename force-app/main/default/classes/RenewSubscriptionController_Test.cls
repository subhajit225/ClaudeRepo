@isTest
public class RenewSubscriptionController_Test {
    
    @TestSetup
    static void makeData() {
        QuoteTriggerHandler.byPassQuoteTriggerForPolarisSKURestructuring = true;
        SBQQ_QuoteLineTriggerHandler.byPassQLITriggerForPolarisSKURestructuring = true;
        
        List<Product2> listProduct = new List<Product2>();
        Product2 standAloneProduct = new Product2(
            Name = 'RBK-MSP-AIR',
            ProductCode = 'RBK-MSP-AIR',
            Category__c = 'Software',
            SBQQ__AssetConversion__c = 'None',
            SBQQSC__EntitlementConversion__c = 'One per unit',
            SBQQ__SubscriptionPricing__c = 'Fixed Price',
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__SubscriptionBase__c = 'List',
            SBQQ__SubscriptionType__c = 'Renewable',
            IsActive = true,
            Asset_Priority__c = 1,
            New_CPQ_Product__c = true
        );
        listProduct.add(standAloneProduct);
        insert listProduct;
        List<Pricebook2> listPricebook = TestDataFactory.getPricebook('PriceBook', 1);
        listPricebook[0].Name = 'CPQ Pricebook';
        insert listPricebook;
        
        List<PriceBookEntry> listPricebookentry = TestDataFactory.getPriceBookEntry(
            new List<Id>{listProduct[0].Id},
            new List<Id>{Test.getStandardPricebookId(), listPricebook[0].Id}
        );
        insert listPricebookentry;
        ShGl_DisableBusinessLogic__c cdf222 = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Validation_Rules__c = True,Disable_Entitlement_Validation_Rules__c=True,
        Disable_SBQQ_QuoteLine_Validation_Rules__c = True );
        insert cdf222;
    }
    
    @isTest
    private static void testOldToNewProducts() {
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        
        ShGl_DisableBusinessLogic__c dbl = new ShGl_DisableBusinessLogic__c(
            Disable_Account_Triggers__c = true
        );
        
        TriggerControl__c settingtc = new TriggerControl__c();
        settingtc.Name = 'Entitlement';
        settingtc.DisableTrigger__c = true;
        insert settingtc;
        
        Set<Id> productIdSet = new Set<Id>();
        List<Product2> lstProduct = new List<Product2>();
        
        Product2 HardwareProductObj = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        HardwareProductObj.Name = 'RBK-R6404S-HW-ADDON-NODE-01';
        HardwareProductObj.ProductCode = 'RBK-R6404S-HW-ADDON-NODE-01';
        HardwareProductObj.Category__c = 'Hardware';
        HardwareProductObj.SBQQ__AssetConversion__c = 'None';
        HardwareProductObj.SBQQSC__EntitlementConversion__c = 'One per unit';
        HardwareProductObj.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        HardwareProductObj.SBQQ__SubscriptionTerm__c = 12;
        HardwareProductObj.SBQQ__SubscriptionBase__c = 'List';
        HardwareProductObj.SBQQ__SubscriptionType__c = 'Renewable';
        HardwareProductObj.IsActive = true;
        HardwareProductObj.Asset_Priority__c = 1;
        HardwareProductObj.New_CPQ_Product__c = true;
        HardwareProductObj.Product_Level__c = 'Hardware';
        lstProduct.add(HardwareProductObj);
        
        Product2 SoftwareProductObj = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        SoftwareProductObj.Name = 'RBK-MSP-AIR';
        SoftwareProductObj.ProductCode = 'RBK-MSP-AIR';
        SoftwareProductObj.Category__c = 'Software';
        SoftwareProductObj.SBQQ__AssetConversion__c = 'None';
        SoftwareProductObj.SBQQSC__EntitlementConversion__c = 'One per unit';
        SoftwareProductObj.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        SoftwareProductObj.SBQQ__SubscriptionTerm__c = 12;
        SoftwareProductObj.SBQQ__SubscriptionBase__c = 'List';
        SoftwareProductObj.SBQQ__SubscriptionType__c = 'Renewable';
        SoftwareProductObj.IsActive = true;
        SoftwareProductObj.Asset_Priority__c = 1;
        SoftwareProductObj.New_CPQ_Product__c = true;
        SoftwareProductObj.Product_Level__c = 'Hybrid Software';
        lstProduct.add(SoftwareProductObj);
        
        Product2 SupportProductObj = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        SupportProductObj.Name = 'RBK-SVC-PREM-SW';
        SupportProductObj.ProductCode = 'RBK-SVC-PREM-SW';
        SupportProductObj.Category__c = 'Support';
        SupportProductObj.SBQQ__AssetConversion__c = 'None';
        SupportProductObj.SBQQSC__EntitlementConversion__c = 'One per unit';
        SupportProductObj.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        SupportProductObj.SBQQ__SubscriptionTerm__c = 12;
        SupportProductObj.SBQQ__SubscriptionBase__c = 'List';
        SupportProductObj.SBQQ__SubscriptionType__c = 'Renewable';
        SupportProductObj.IsActive = true;
        SupportProductObj.Asset_Priority__c = 1;
        SupportProductObj.New_CPQ_Product__c = true;
        SupportProductObj.Product_Level__c = 'Support';
        lstProduct.add(SupportProductObj);
        
        Product2 NewHardwareProductObj = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        NewHardwareProductObj.Name = 'RH-R6404S-HW-N-01';
        NewHardwareProductObj.ProductCode = 'RH-R6404S-HW-N-01';
        NewHardwareProductObj.Category__c = 'Hardware';
        NewHardwareProductObj.SBQQ__AssetConversion__c = 'None';
        NewHardwareProductObj.SBQQSC__EntitlementConversion__c = 'One per unit';
        NewHardwareProductObj.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        NewHardwareProductObj.SBQQ__SubscriptionTerm__c = 12;
        NewHardwareProductObj.SBQQ__SubscriptionBase__c = 'List';
        NewHardwareProductObj.SBQQ__SubscriptionType__c = 'Renewable';
        NewHardwareProductObj.IsActive = true;
        NewHardwareProductObj.Asset_Priority__c = 1;
        NewHardwareProductObj.New_CPQ_Product__c = true;
        NewHardwareProductObj.Product_Level__c = 'Hardware';
        lstProduct.add(NewHardwareProductObj);
        
        Product2 NewSoftwareProductObj = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        NewSoftwareProductObj.Name = 'RS-PB-EDG-PE-PP';
        NewSoftwareProductObj.ProductCode = 'RS-PB-EDG-PE-PP';
        NewSoftwareProductObj.Category__c = 'Software';
        NewSoftwareProductObj.SBQQ__AssetConversion__c = 'None';
        NewSoftwareProductObj.SBQQSC__EntitlementConversion__c = 'One per unit';
        NewSoftwareProductObj.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        NewSoftwareProductObj.SBQQ__SubscriptionTerm__c = 12;
        NewSoftwareProductObj.SBQQ__SubscriptionBase__c = 'List';
        NewSoftwareProductObj.SBQQ__SubscriptionType__c = 'Renewable';
        NewSoftwareProductObj.IsActive = true;
        NewSoftwareProductObj.Asset_Priority__c = 1;
        NewSoftwareProductObj.New_CPQ_Product__c = true;
        NewSoftwareProductObj.Product_Level__c = 'Hybrid Software';
        lstProduct.add(NewSoftwareProductObj);
        
        Product2 NewSupportProductObj = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        NewSupportProductObj.Name = 'RS-SW-SVC-PE';
        NewSupportProductObj.ProductCode = 'RS-SW-SVC-PE';
        NewSupportProductObj.Category__c = 'Support';
        NewSupportProductObj.SBQQ__AssetConversion__c = 'None';
        NewSupportProductObj.SBQQSC__EntitlementConversion__c = 'One per unit';
        NewSupportProductObj.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        NewSupportProductObj.SBQQ__SubscriptionTerm__c = 12;
        NewSupportProductObj.SBQQ__SubscriptionBase__c = 'List';
        NewSupportProductObj.SBQQ__SubscriptionType__c = 'Renewable';
        NewSupportProductObj.IsActive = true;
        NewSupportProductObj.Asset_Priority__c = 1;
        NewSupportProductObj.New_CPQ_Product__c = true;
        NewSupportProductObj.Product_Level__c = 'Support';
        lstProduct.add(NewSupportProductObj);
        
        
        Product2 SupportProductObj2 = SupportProductObj.clone();
        SupportProductObj2.Name = 'RBK-SVC-PREM-APPLIANCE';
        SupportProductObj2.ProductCode = 'RBK-SVC-PREM-APPLIANCE';
        lstProduct.add(SupportProductObj2);
        
        Product2 SupportProductObj3 = SupportProductObj.clone();
        SupportProductObj3.Name = 'RBK-SVC-APPLIANCE-L3';
        SupportProductObj3.ProductCode = 'RBK-SVC-APPLIANCE-L3';
        lstProduct.add(SupportProductObj3);
        
        insert lstProduct;
        
        List<PricebookEntry> pricebookObj = new List<PricebookEntry>();
        
        pricebookObj.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = lstProduct[0].Id, IsActive = true, UnitPrice = 100));
        pricebookObj.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = lstProduct[1].Id, IsActive = true, UnitPrice = 200));
        pricebookObj.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = lstProduct[2].Id, IsActive = true, UnitPrice = 100));
        pricebookObj.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = lstProduct[3].Id, IsActive = true, UnitPrice = 100));
        pricebookObj.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = lstProduct[4].Id, IsActive = true, UnitPrice = 100));
        pricebookObj.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = lstProduct[5].Id, IsActive = true, UnitPrice = 100));
        pricebookObj.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = lstProduct[6].Id, IsActive = true, UnitPrice = 100));
        pricebookObj.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = lstProduct[7].Id, IsActive = true, UnitPrice = 100));
        insert pricebookObj;
        
        List<Polaris_SKU_Mapping_V2__c> polarisMappingList = new List<Polaris_SKU_Mapping_V2__c>();
        Polaris_SKU_Mapping_V2__c  polarisSKUMappingObj1 = TestDataFactory.createPolarisSKUMappingRecord(lstProduct[0], lstProduct[3]);
        Polaris_SKU_Mapping_V2__c  polarisSKUMappingObj2 = TestDataFactory.createPolarisSKUMappingRecord(lstProduct[1], lstProduct[4]);
        Polaris_SKU_Mapping_V2__c  polarisSKUMappingObj3 = TestDataFactory.createPolarisSKUMappingRecord(lstProduct[2], lstProduct[5]);
        polarisMappingList.add(polarisSKUMappingObj1);
        polarisMappingList.add(polarisSKUMappingObj2);
        polarisMappingList.add(polarisSKUMappingObj3);
        
        insert polarisMappingList;
        
        List<Account> accountList = new List<Account>();
        
        Account account = new Account (
            Name = 'Customer',
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
        accountList.add(account);
        
        Account vAccount = new Account();
        accountList.add(vAccount);
        vAccount.Name = 'Test Account';
        vAccount.Type='Distributor';
        vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
        Account vAccount2 = new Account();
        vAccount2.Name = 'Test Account';
        vAccount2.recordTypeId = vAccount.recordTypeId;
        accountList.add(vAccount2);
        
        insert accountList;
        
        List<Opportunity> lstOpportunity = new List<Opportunity>();
        Opportunity opportunityObj = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opportunityObj.AccountId = account.Id;
        opportunityObj.Name = 'Testing Opportunity';
        opportunityObj.CloseDate = System.today().addMonths(12);
        opportunityObj.StageName = 'Prospecting';
        opportunityObj.Pricebook2Id = Test.getStandardPricebookId();
        opportunityObj.Partner_Lookup__c = vAccount2.id;
        opportunityObj.Distributor_Lookup__c = vAccount.id;
        lstOpportunity.add(opportunityObj);
        
        insert lstOpportunity;
        
        SBQQ__Quote__c quoteObj= new SBQQ__Quote__c(SBQQ__Account__c=account.Id,
                                                    SBQQ__Opportunity2__c=lstOpportunity[0].Id,
                                                    SBQQ__StartDate__c=System.today(),
                                                    SBQQ__Primary__c=true,
                                                    SBQQ__SubscriptionTerm__c = 36,
                                                    SBQQ__ExpirationDate__c = System.today().addYears(1)
                                                   );
        insert quoteObj;
        
        List<SBQQ__QuoteLine__c> lstQuoteLine = new List<SBQQ__QuoteLine__c>();

        SBQQ__QuoteLine__c qlObj1 = new SBQQ__QuoteLine__c();
        qlObj1.SBQQ__Quote__c = quoteObj.id;
        qlObj1.SBQQ__Product__c = lstProduct[0].Id;
        qlObj1.SBQQ__Quantity__c = 1;
        qlObj1.SBQQ__ListPrice__c = 100;
        qlObj1.SBQQ__NetPrice__c = 100;
        qlObj1.SBQQ__StartDate__c = System.today().addMonths(12).addDays(-1);
        qlObj1.SBQQ__SubscriptionPricing__c='Fixed Price';
        qlObj1.Product_Level__c = 'Hardware';
        qlObj1.SubscribedAssetNames__c = 'BB192863040046';

        SBQQ__QuoteLine__c qlObj2 = new SBQQ__QuoteLine__c();
        qlObj2.SBQQ__Quote__c = quoteObj.id; 
        qlObj2.SBQQ__Product__c = lstProduct[1].Id;
        qlObj2.SBQQ__Quantity__c = 1;
        qlObj2.SBQQ__ListPrice__c = 100;
        qlObj2.SBQQ__NetPrice__c = 100;
        qlObj2.SBQQ__StartDate__c = System.today().addMonths(12).addDays(-1);
        qlObj2.SBQQ__SubscriptionPricing__c='Fixed Price';
        qlObj2.Product_Level__c = 'Hybrid Software';
        qlObj2.SubscribedAssetNames__c = 'BB192863040046';
        

        SBQQ__QuoteLine__c qlObj3 = new SBQQ__QuoteLine__c();
        qlObj3.SBQQ__Quote__c = quoteObj.id;
        qlObj3.SBQQ__Product__c = lstProduct[2].Id;
        qlObj3.SBQQ__Quantity__c = 1;
        qlObj3.SBQQ__ListPrice__c = 100;
        qlObj3.SBQQ__NetPrice__c = 100;
        qlObj3.SBQQ__StartDate__c = System.today().addMonths(12).addDays(-1);
        qlObj3.SBQQ__SubscriptionPricing__c='Fixed Price';
        qlObj3.Product_Level__c = 'Support';
        qlObj3.SubscribedAssetNames__c = 'BB192863040046';
                                      
        SBQQ__QuoteLine__c qlObj4 = new SBQQ__QuoteLine__c();       
        qlObj4.SBQQ__Quote__c = quoteObj.id;
        qlObj4.SBQQ__Product__c = lstProduct[6].Id;
        qlObj4.SBQQ__Quantity__c = 1;
        qlObj4.SBQQ__ListPrice__c = 100;
        qlObj4.SBQQ__NetPrice__c = 100;
        qlObj4.SBQQ__StartDate__c = System.today().addMonths(12).addDays(-1);
        qlObj4.SBQQ__SubscriptionPricing__c='Fixed Price';
        qlObj4.Product_Level__c = 'Support';
        qlObj4.SubscribedAssetNames__c = 'BB192863040046';
                                      
        SBQQ__QuoteLine__c qlObj5 = new SBQQ__QuoteLine__c();         
        qlObj5.SBQQ__Quote__c = quoteObj.id;
        qlObj5.SBQQ__Product__c = lstProduct[7].Id;
        qlObj5.SBQQ__Quantity__c = 1;
        qlObj5.SBQQ__ListPrice__c = 100;
        qlObj5.SBQQ__NetPrice__c = 100;
        qlObj5.SBQQ__StartDate__c = System.today().addMonths(12).addDays(-1);
        qlObj5.SBQQ__SubscriptionPricing__c='Fixed Price';
        qlObj5.Product_Level__c = 'Support';
        qlObj5.SubscribedAssetNames__c = 'BB192863040046';

        lstQuoteLine.add(qlObj1);
        lstQuoteLine.add(qlObj2);
        lstQuoteLine.add(qlObj3);
        lstQuoteLine.add(qlObj4);
        lstQuoteLine.add(qlObj5);

                
                    insert lstQuoteLine;
        
        List<ServiceContract> lstServiceContract = new List<ServiceContract>();
        ServiceContract serviceContractObj = new ServiceContract();
        serviceContractObj.Name = 'sample SC';
        serviceContractObj.SBQQSC__Opportunity__c = lstOpportunity[0].Id;
        serviceContractObj.AccountId = account.Id;
        serviceContractObj.StartDate = System.today().addDays(-30);
        serviceContractObj.EndDate = system.today().addDays(360);
        serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj.Term = 36;
        serviceContractObj.SBQQSC__Quote__c=quoteObj.Id;
        serviceContractObj.SBQQSC__Evergreen__c = false;
        
        lstServiceContract.add(serviceContractObj);
        insert lstServiceContract;
        
        
        List<ContractLineItem> ContractLineItemList = new List<ContractLineItem> {
            new ContractLineItem (SBQQSC__Account__c = account.Id,
                                  PricebookEntryId = pricebookObj[1].Id,
                                  ServiceContractId = lstServiceContract[0].Id,
                                  Quantity = 10,
                                  UnitPrice = 100,
                                  SBQQSC__SubscriptionPricing__c='Fixed Price',
                                  SBQQSC__QuoteLine__c=lstQuoteLine[1].Id,
                                  SBQQSC__Product__c = SoftwareProductObj.Id,
                                  SBQQSC__RenewalQuantity__c = 1,
                                  StartDate = Date.today(),
                                  EndDate = Date.today().addYears(1)
                                 ),
                new ContractLineItem (SBQQSC__Account__c = account.Id,
                                      PricebookEntryId = pricebookObj[2].Id,
                                      ServiceContractId = lstServiceContract[0].Id,
                                      Quantity = 10,
                                      UnitPrice = 100,
                                      SBQQSC__SubscriptionPricing__c='Fixed Price',
                                      SBQQSC__QuoteLine__c=lstQuoteLine[2].Id,
                                      SBQQSC__Product__c = SupportProductObj.Id,
                                      SBQQSC__RenewalQuantity__c = 1,
                                      StartDate = Date.today(),
                                      EndDate = Date.today().addYears(1)
                                     )
                ,
                new ContractLineItem (SBQQSC__Account__c = account.Id,
                                      PricebookEntryId = pricebookObj[6].Id,
                                      ServiceContractId = lstServiceContract[0].Id,
                                      Quantity = 10,
                                      UnitPrice = 100,
                                      SBQQSC__SubscriptionPricing__c='Fixed Price',
                                      SBQQSC__QuoteLine__c=lstQuoteLine[3].Id,
                                      SBQQSC__Product__c = SupportProductObj2.Id,
                                      SBQQSC__RenewalQuantity__c = 1,
                                      StartDate = Date.today(),
                                      EndDate = Date.today().addYears(1)
                                     )
                ,
                new ContractLineItem (SBQQSC__Account__c = account.Id,
                                      PricebookEntryId = pricebookObj[7].Id,
                                      ServiceContractId = lstServiceContract[0].Id,
                                      Quantity = 10,
                                      UnitPrice = 100,
                                      SBQQSC__SubscriptionPricing__c='Fixed Price',
                                      SBQQSC__QuoteLine__c=lstQuoteLine[4].Id,
                                      SBQQSC__Product__c = SupportProductObj3.Id,
                                      SBQQSC__RenewalQuantity__c = 1,
                                      StartDate = Date.today(),
                                      EndDate = Date.today().addYears(1)
                                     )
                };
                    insert ContractLineItemList;
        
        List<ContractLineItem> CLICheckList = [SELECT Id,
                                               PricebookEntryId,
                                               ServiceContractId,
                                               SBQQSC__SubscriptionPricing__c,
                                               SBQQSC__Product__c,
                                               SBQQSC__QuoteLine__c,
                                               ServiceContract.SBQQSC__ActiveContract__c, Renewed__c, SBQQSC__RenewedDate__c
                                               FROM ContractLineItem ];
        
        for(ContractLineItem ContractLineItem : CLICheckList) {
            System.debug('Id = '+ContractLineItem.Id);
            System.debug('PricebookEntryId = '+ContractLineItem.PricebookEntryId);
            System.debug('ServiceContractId = '+ContractLineItem.ServiceContractId);
            System.debug('SBQQSC__SubscriptionPricing__c = '+ContractLineItem.SBQQSC__SubscriptionPricing__c);
            System.debug('SBQQSC__Product__c = '+ContractLineItem.SBQQSC__Product__c);
            System.debug('SBQQSC__QuoteLine__c = '+ContractLineItem.SBQQSC__QuoteLine__c);
            System.debug('ServiceContract.SBQQSC__ActiveContract__c = '+ContractLineItem.ServiceContract.SBQQSC__ActiveContract__c);
            System.debug('Renewed '+ContractLineItem.Renewed__c);
            System.debug('SBQQSC__RenewedDate__c '+ContractLineItem.SBQQSC__RenewedDate__c);
        }
        
        Asset asset = new Asset(
            Product2Id = HardwareProductObj.Id,
            Name = 'BB214664160056',
            SBQQ__QuoteLine__c = lstQuoteLine[0].Id,
            AccountId = account.Id
        );
        insert asset;
        
        List<Entitlement> entitlements = new List<Entitlement>{
            new Entitlement(
                Name = 'entitlement1',
                AccountId = account.Id,
                ContractLineItemId = ContractLineItemList[0].Id,
                StartDate = System.today(),
                EndDate= System.today().addDays(360)
            ),
                new Entitlement(
                    Name = 'entitlement2',
                    AccountId = account.Id,
                    ContractLineItemId = ContractLineItemList[1].Id,
                    AssetId = asset.Id,
                    StartDate = System.today(),
                    EndDate= System.today().addDays(360)
                )
                };
                    
                    insert entitlements;
        
        TriggerControls.disableQuoteTrigger = false;
        TriggerControls.disableQuoteLineTrigger = false;
        SBQQ.TriggerControl.enable();
        
        test.startTest();
        
        PageReference pageRef = Page.RenewSubscription;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('newid', String.valueOf(quoteObj.Id));
        
        ApexPages.StandardController sc = new ApexPages.StandardController(quoteObj);
        RenewSubscriptionControllerV1 renewController = new RenewSubscriptionControllerV1(sc);
        
        renewController.allServiceContractChecked = true;
        renewController.checkAllServiceContractItems();
        renewController.handleNext();
        renewController.allCLIProductsChecked = true;
        renewController.checkCLIProducts();
        renewController.handleRenew();
        renewController.handleCancel();
        renewController.handleBack();
        Test.stopTest();
    }
    
    
}