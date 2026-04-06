@isTest
public with sharing class LCC_Credit_SDRISR_Opportunity_Cont_test {
    
    @isTest
    static void testMethod1(){
        
        Account act;
        Opportunity opportunityObj;
        
        Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act = new Account(
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
        insert act;
        
        
        Contact con = new Contact();
        con.Lastname = 'test con';
        con.email = 'test@test.com';
        insert con;
        
        
        opportunityObj = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opportunityObj.AccountId = act.Id;
        opportunityObj.Name = 'abc Opportunity';
        opportunityObj.CloseDate = System.today().addMonths(12);
        opportunityObj.StageName = 'Prospecting';
        opportunityObj.Partner_Lookup__c = act.Id;
        opportunityObj.Distributor_Lookup__c = opportunityObj.AccountId;
        opportunityObj.Initial_Contacts_Name__c = con.Id;
        opportunityObj.Amount = 100;
        opportunityObj.OppSubscriptionTermMonths__c = 12;
        opportunityObj.Pricebook2Id = Test.getStandardPricebookId();
        opportunityObj.Deal_Structuring_Oppty_Notes__c = 'Test';
        insert opportunityObj;
        
        test.startTest();
        LCC_Credit_SDRISR_Opportunity_Controller.opportunityApproval(opportunityObj.Id,'test.test.com','notes');
        test.stopTest();
        System.assert(opportunityObj.Id != null);
    }
    
}