@isTest
public with sharing class Asset_TradeUp_Batch_Test {
    
    @isTest
    static void testMethod1(){
        Account act;
        Product2 prdHW;
        Asset ast;
        
        ShGl_TestFactoryHelper.insertTriggerControls();
        
        Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act = new Account(
            Name = 'Customer',
            recordtypeId = partner,
            Phone = '123-456-7890',
            TradeUp_Contact_Email_Temp__c = 'abc@abc.com.invalid',
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
        insert act;
        
        
        prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        prdHW.ProductCode = 'RBK-SVC-test-product';
        prdHW.Product_Subtype__c = 'GO';
        prdHW.SBQQSC__EntitlementConversion__c = 'One per unit';
        insert prdHW;
        
        ast = (Asset) ShGl_TestFactory.createSObject(new Asset(), null);
        ast.AccountId = act.Id;
        ast.Name = 'EntitlementTriggerHelperAsset';
        ast.Rubrik_Suite__c = 'Foundation';
        ast.Payment_Options__c = 'Annual';
        ast.SerialNumber = '123\\s+';
        ast.Support_Type__c = 'L3';
        ast.Licensing_Model__c = 'Perpetual';
        ast.Product2Id = prdHW.Id;
        ast.Premium_Support_End_Date__c = System.today().addMonths(2);
        ast.Eligible_for_Free_HW__c = 'True';
        ast.Free_HW_Refresh_Forfeited__c = false;
        insert ast;
        
        test.startTest();
        database.executebatch(new Asset_TradeUp_Batch(),1);
        test.stopTest();
        System.assert(act.Id != null);
        
    }  
}