@isTest
public class Asset_TradeUp_Email_Bounce_Test {
    
    @isTest
    static void testMethod1(){
        Account act;
        
        ShGl_TestFactoryHelper.insertTriggerControls();
        
        Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act = new Account(
            Name = 'Customer',
            recordtypeId = partner,
            Phone = '123-456-7890',
            AccountNumber = 'Test',
            TradeUp_Contact_Email_Temp__c = 'abc@abc.com.invalid',
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
        
        EmailMessage em1 = new EmailMessage();
        em1.FromAddress = 'test12345@rubrik.com';
        em1.ToAddress = 'test@test.com';
        em1.TextBody = 'This is for the test class.';
        em1.IsBounced = false;
        em1.RelatedToId = act.Id;
        insert em1;
        em1.IsBounced = true;
        
        test.startTest();
        update em1;
        Asset_TradeUp_Email_Bounce_Notification.assetTradeUpPDFAddendumEmailBounce(new List<EmailMessage>{em1});
        test.stopTest();
        
        System.assert(act.Id != null);
    }
    
}