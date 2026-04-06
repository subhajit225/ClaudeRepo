@isTest
public class ConvertToV2ControllerTest { 
    
    @isTest
    public static void testConvertToV2(){
        
        ShGl_DisableBusinessLogic__c dbl = ShGl_DisableBusinessLogic__c.getInstance();
        dbl.Disable_Account_Triggers__c = true;
        dbl.Disable_Opportunity_Triggers__c = true;
        insert dbl;
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Type='Distributor';
        acc.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        insert acc;
        
        
        //create products
        List<Product2> lstProduct = new List<Product2>();
        
        Product2 hardwareProductObj = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        hardwareProductObj.Name = 'RBK-R6404S-HW-ADDON-NODE-01';
        hardwareProductObj.ProductCode = 'RBK-R6404S-HW-ADDON-NODE-01';
        hardwareProductObj.Category__c = 'Hardware';
        hardwareProductObj.SBQQ__AssetConversion__c = 'None';
        hardwareProductObj.SBQQSC__EntitlementConversion__c = 'One per unit';
        hardwareProductObj.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        hardwareProductObj.SBQQ__SubscriptionTerm__c = 12;
        hardwareProductObj.SBQQ__SubscriptionBase__c = 'List';
        hardwareProductObj.SBQQ__SubscriptionType__c = 'Renewable';
        hardwareProductObj.IsActive = true;
        hardwareProductObj.Asset_Priority__c = 1;
        hardwareProductObj.New_CPQ_Product__c = true;
        hardwareProductObj.Product_Level__c = '';
        lstProduct.add(hardwareProductObj);
        
        Product2 newHardwareProductObj = hardwareProductObj.clone();
        newHardwareProductObj.Name = 'RH-R6404S-HW-N-01';
        newHardwareProductObj.ProductCode = 'RH-R6404S-HW-N-01';
        newHardwareProductObj.Product_Level__c = 'Hardware';
        lstProduct.add(newHardwareProductObj);
        
        insert lstProduct;
        
        //create opp
        Opportunity opportunityObj = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opportunityObj.AccountId = acc.Id;
        opportunityObj.Name = 'Testing Opportunity';
        opportunityObj.CloseDate = System.today().addMonths(12);
        opportunityObj.StageName = 'Prospecting';
        opportunityObj.Pricebook2Id = Test.getStandardPricebookId();
        insert opportunityObj;
        
        //create quote 
        SBQQ__Quote__c quoteObj= new SBQQ__Quote__c(SBQQ__Account__c=acc.Id,
                                                    SBQQ__Opportunity2__c=opportunityObj.Id,
                                                    SBQQ__StartDate__c=System.today(),
                                                    SBQQ__Primary__c=true,
                                                    SBQQ__SubscriptionTerm__c = 36,
                                                    SBQQ__ExpirationDate__c = System.today().addYears(1)
                                                   );
        insert quoteObj;
        
        //create quotelines
        List<SBQQ__QuoteLine__c> lstQuoteLine = new List<SBQQ__QuoteLine__c>{
            new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteObj.id,
                                   SBQQ__Product__c = hardwareProductObj.Id,
                                   SBQQ__Quantity__c = 1,
                                   SBQQ__ListPrice__c = 100,
                                   SBQQ__NetPrice__c = 100,
                                   SBQQ__StartDate__c = System.today().addMonths(12).addDays(-1),
                                   SBQQ__SubscriptionPricing__c='Fixed Price',
                                   Product_Level__c = 'Hardware', SubscribedAssetNames__c = 'BB192863040046'
                                  ),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteObj.id,
                                       SBQQ__Product__c = newHardwareProductObj.Id,
                                       SBQQ__Quantity__c = 1,
                                       SBQQ__ListPrice__c = 100,
                                       SBQQ__NetPrice__c = 100,
                                       SBQQ__StartDate__c = System.today().addMonths(12).addDays(-1),
                                       SBQQ__SubscriptionPricing__c='Fixed Price',
                                       Product_Level__c = 'Hardware', SubscribedAssetNames__c = 'BB192863040046'
                                      )                
                };
                    insert lstQuoteLine;
        
        Test.startTest();
        
        PageReference convertV2Page = Page.ConvertToV2Page; 
        Test.setCurrentPage(convertV2Page);
        convertV2Page.getParameters().put('Id', quoteObj.id);
        
        ApexPages.StandardController sc = new  ApexPages.StandardController(quoteObj);  
        ConvertToV2Controller v2Controller = new ConvertToV2Controller(sc);
        
        v2Controller.convert();
        
        delete [select id from sbqq__quoteline__c where Id=:lstQuoteLine[0].Id];
        
        v2Controller.convert();

        Test.stopTest();
    }
    
}