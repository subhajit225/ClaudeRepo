@isTest
public class qlPromoRelatedListControllerTest {
    
    @isTest
    static void testGetQuoteLines() {
        ShGl_DisableBusinessLogic__c setting = new ShGl_DisableBusinessLogic__c();
		setting.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
        setting.Disable_SBQQ_Quote_Validation_Rules__c = true;
        setting.Disable_Account_Triggers__c = true;
        setting.Disable_Opportunity_Triggers__c = true;
        setting.Disable_ServiceContract_Trigger__c = true;
        setting.Disable_SBQQ_Quote_Triggers__c = true;
        setting.Disable_SBQQ_QuoteLine_Triggers__c = true;
		insert setting;
        
        Account acc = new Account(Name = 'Test Account',BillingCity = 'Oxford',BillingCountry = 'United Kingdom',
                                  BillingStreet = 'Citibase Oxford, New Barclay House, 234 Botley Road',BillingState = 'Oxfordshire',BillingPostalCode = 'OX2 0HP');
        insert acc;
        
        Opportunity oppr = TestDataFactory.getOpportunity(acc);
        insert oppr;
                
        ServiceContract sc = new ServiceContract(Name = 'Test Contract',PriceBook2Id = Test.getStandardPricebookId(), AccountId = acc.Id);
        insert sc;
        
        Product2 prod = new Product2();
        prod.Name = 'Test Product';
        prod.Quotable_By_Profiles__c = 'Deal Operations';
        prod.Quotable_by_users__c = '<a href="/0055g00000In" target="_blank">'+UserInfo.getName()+'</a> , <a href="/0055g000006AAB" target="_blank">Test User</a>';
        prod.IsActive = true;
        insert prod;
        
        PriceBookEntry pbe = new PriceBookEntry();
        pbe.Product2Id = prod.Id;
        pbe.IsActive = true;
        pbe.UnitPrice = 100;
        pbe.Pricebook2Id = Test.getStandardPricebookId();
        insert pbe; 
        
        ContractLineItem cli = new ContractLineItem(PricebookEntryId = pbe.Id, Quantity = 1, UnitPrice = 100,ServiceContractId = sc.Id);
        insert cli;
        
        SBQQ__Quote__c qt = new SBQQ__Quote__c();
        qt.SBQQ__Account__c = acc.Id;
        qt.SBQQ__Opportunity2__c = oppr.Id;
        qt.SBQQ__BillingCountry__c = oppr.Account.BillingCountry;
        qt.SBQQ__BillingName__c = oppr.Account.Name;
        qt.SBQQ__BillingCity__c = oppr.Account.BillingCity;
        qt.SBQQ__BillingStreet__c = oppr.Account.BillingStreet;
        qt.SBQQ__BillingState__c = oppr.Account.BillingState;
        qt.SBQQ__BillingPostalCode__c = oppr.Account.BillingPostalCode;
        insert qt;
        
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
        ql.SBQQ__Product__c = pbe.Product2Id;
        ql.SBQQ__Quote__c = qt.Id;
        ql.SBQQ__PricebookEntryId__c = pbe.Id;
        ql.SBQQSC__RenewedContractLine__c = cli.id;
        insert ql;
		
		SBQQ__QuoteLine__c renql = new SBQQ__QuoteLine__c();
        renql.SBQQ__Product__c = pbe.Product2Id;
        renql.SBQQ__Quote__c = qt.Id;
        renql.SBQQ__PricebookEntryId__c = pbe.Id;
        renql.Promo_Disc__c = 15;
        insert renql;
        
        cli.SBQQSC__OriginalQuoteLine__c = renql.Id;
        update cli;
        
        Test.startTest();
        String result = qlPromoRelatedListController.getQuoteLines(qt.Id);
        Test.stopTest();
        
    }

}