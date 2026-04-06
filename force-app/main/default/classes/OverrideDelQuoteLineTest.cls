@isTest
private class OverrideDelQuoteLineTest {

    @isTest
    static void setup() {
        test.startTest();
        testDataFactoryClass.createCustomSettings();
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.RecordTypeId = partnerRecordTypeId;
        insert act;
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => act.Id,
            'CloseDate' => System.Today()+30,
            'Partner_Lookup__c' => act.id,
            'Alliance_Partner_Name__c' =>'Amazon',
            'Alliance_Source_Type__c' => 'Alliance Initiated Deal'
        };
        
        Id standardPBId = test.getStandardPricebookId();
        Opportunity opp1 = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp1.Pricebook2Id =standardPBId;
        insert opp1;
        
        Map<String, Object>  OrderMap = new Map<String, Object> {
            'Type' => 'Revenue',
            'AccountId' => act.Id,
            'OpportunityId' => opp1.Id,
            'EffectiveDate' => system.today(),
            'Status' => 'Pending'
        };
        
        Product2 newProd = new Product2(Name = 'Test Del', family = 'TestDel', ProductCode='Test-Del');
        insert newProd;
        
        PriceBookEntry pbEntry = new PriceBookEntry(
            UnitPrice = 300,
            PriceBook2Id = standardPBId,
            Product2Id = newProd.Id,
            IsActive = true,
            UseStandardPrice=false);
        insert pbEntry ;
        SBQQ__Quote__c q = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp1.Id);        
        insert(q);
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=newProd.Id, SBQQ__Quantity__c=10, SBQQ__Number__c=1);  
        insert qli1;
        
        system.debug('test code '+qli1);
        
        ApexPages.StandardController ctrl = new ApexPages.StandardController(qli1);
        ApexPages.CurrentPage().getParameters().put('delID',qli1.id);
        OverrideDelQuoteLine overDel = new OverrideDelQuoteLine(ctrl);
        overDel.checkProfAndDel();
        overDel.cancelDel();
        test.stopTest();
        
    }
    
}