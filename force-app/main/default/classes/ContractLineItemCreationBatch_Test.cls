@isTest
public with sharing class ContractLineItemCreationBatch_Test {
    @isTest
    public static void testCliCreation(){
    
        List<Product2> listProduct = TestDataFactory.getProducts('Prod', 2);
        listProduct[0].Legacy_Software_Bundle__c = TRUE;
        insert listProduct;
    
        List<Pricebook2> listPricebook = TestDataFactory.getPricebook('PriceBook', 1);
        listPricebook[0].Name = 'CPQ Pricebook';
        insert listPricebook;
        
        List<PriceBookEntry> listPricebookentry = TestDataFactory.getPriceBookEntry(
            new List<Id>{listProduct[0].Id, listProduct[1].Id},
            new List<Id>{Test.getStandardPricebookId(), listPricebook[0].Id}
        );
        insert listPricebookentry;
        
        Opportunity objOpportunity = TestDataFactory.getOpportunity();
        insert objOpportunity;
        
        List<SBQQ__Quote__c> listQuote = TestDataFactory.getQuotes(new Set<Id>{objOpportunity.Id}, 1);
      //  listQuote[0].SBQQ__Primary__c = True;
        listQuote[0].SBQQ__PriceBook__c = listPricebook[0].Id;
        listQuote[0].SBQQ__PricebookId__c = listPricebook[0].Id;
        insert listQuote;
        
        List<SBQQ__QuoteLine__c> listQuoteLine = TestDataFactory.getQuoteLines (
            new Map<Id, List<Id>>{
                listQuote[0].Id => new List<Id>{listProduct[0].Id, listProduct[1].Id}
            }
        );
        listQuoteLine[0].SBQQ__PricebookEntryId__c = listPricebookentry[1].Id;
        listQuoteLine[0].SBQQ__NetPrice__c = 100;
        listQuoteLine[1].SBQQ__PricebookEntryId__c = listPricebookentry[3].Id;
        listQuoteLine[1].SBQQ__NetPrice__c = 100;
        insert listQuoteLine;
        
        listQuoteLine[1].SBQQ__RequiredBy__c = listQuoteLine[0].Id;
        update listQuoteLine[1];
        
        list<SBQQ__QuoteLine__c> lstQl = [Select Id, SBQQ__PricebookEntryId__c  From SBQQ__QuoteLine__c where Id = :listQuoteLine[0].Id];
        system.debug('&&&' + lstQl + '--->' + listQuoteLine[0].Id);
        
        ServiceContract objServiceContract = new Servicecontract(
            Name = 'Test Contract',
            Pricebook2Id = listPricebook[0].Id,
            StartDate = Date.Today(),
            EndDate = Date.Today() + 36
        );
        insert objServiceContract;
        
        ContractLineItem objContractLineItem = new ContractLineItem(
            ServiceContractId = objServiceContract.Id,
            SBQQSC__Product__c = listProduct[1].Id,
            SBQQSC__QuoteLine__c = listQuoteLine[1].Id,
            PricebookEntryId = listPricebookentry[3].Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert objContractLineItem;
list<ContractLineItem> lst = [Select Id, SBQQSC__QuoteLine__r.SBQQ__RequiredBy__c, SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__PricebookEntryId__c From ContractLineItem];
system.debug('???' + lst);
        Test.startTest();
        ContractLineItemCreationBatch objContractLineItemCreationBatch = new ContractLineItemCreationBatch();
        DataBase.executeBatch(objContractLineItemCreationBatch);
        Test.stopTest();

    }
}