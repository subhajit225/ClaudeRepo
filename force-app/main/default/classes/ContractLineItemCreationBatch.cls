public class ContractLineItemCreationBatch implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String strQuery = 'SELECT Id'
                             + ', ServiceContractId'
                             + ', ServiceContract.AccountId'
                             + ', SBQQSC__QuoteLine__c'
                             + ', SBQQSC__QuoteLine__r.SBQQ__RequiredBy__c'
                             + ', SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__c'
                             + ', SBQQSC__RequiredById__c'
                             + ', SBQQSC__RootId__c'
                             + ', StartDate'
                             + ', EndDate'
                             + ', Quantity'
                             + ', SBQQSC__Quantity__c'
                             + ', SBQQSC__RenewalQuantity__c'
                             + ', SBQQSC__BundledQuantity__c'
                             + ', SBQQSC__SubscriptionStartDate__c'
                             + ', SBQQSC__SubscriptionEndDate__c'
                             + ', SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__PricebookEntryId__c'
                             + ', SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__NetPrice__c'
                       + ' FROM ContractLineItem'
                       + ' WHERE SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Legacy_Software_Bundle__c = TRUE'
                       + ' AND SBQQSC__RootId__c = NULL'
                       + ' AND ServiceContract.Pricebook2.Name = \'CPQ Pricebook\''
                       + ' AND ServiceContract.Status = \'Active\'';
                       
        return Database.getQueryLocator(strQuery);
    }
    
    public void execute(Database.BatchableContext BC, List<ContractLineItem> listContractLineItem) {
        Set<Id> setServicecontractId = new Set<Id>();
        Set<Id> setParentQuoteLineId = new Set<Id>();
        List<ContractLineItem> listContractLineItemToUpdate = new List<ContractLineItem>();
        Map<String, List<ContractLineItem>> mapParentWithChildCliList = new Map<String, List<ContractLineItem>>();
        Map<String, ContractLineItem> mapParentWithParentCli = new Map<String, ContractLineItem>();
        
        for (ContractLineItem objContractLineItem : listContractLineItem) {
            String strConcat = objContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__c + '#' + objContractLineItem.ServiceContractId;
            
            if (!mapParentWithChildCliList.containsKey(strConcat)) {
                mapParentWithChildCliList.put(strConcat, new List<ContractLineItem>{objContractLineItem});
            } else {
                List<ContractLineItem> listChildCli = mapParentWithChildCliList.get(strConcat);
                listChildCli.add(objContractLineItem);
                mapParentWithChildCliList.put(strConcat, listChildCli);
            }
            
            setServicecontractId.add(objContractLineItem.ServiceContractId);
            setParentQuoteLineId.add(objContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__c);
        }
        
        // If parent Contract Line Item already present
        for (
                ContractLineItem objContractLineItem :
                    [SELECT Id
                          , ServiceContractId
                          , SBQQSC__QuoteLine__c
                     FROM ContractLineItem
                     WHERE ServiceContractId IN :setServicecontractId
                     AND SBQQSC__QuoteLine__c IN :setParentQuoteLineId]
        ) {
            mapParentWithParentCli.put(
                objContractLineItem.SBQQSC__QuoteLine__c + '#' + objContractLineItem.ServiceContractId,
                objContractLineItem
            );
        }
        
        for (String strConcatQlParentWithContract : mapParentWithChildCliList.keySet()) {
            if (!mapParentWithParentCli.containsKey(strConcatQlParentWithContract)) {
                ContractLineItem objChildContractLineItem = mapParentWithChildCliList.get(strConcatQlParentWithContract)[0];
                
                mapParentWithParentCli.put(
                    strConcatQlParentWithContract,
                    new ContractLineItem(
                        ServiceContractId = objChildContractLineItem.ServiceContractId,
                        SBQQSC__Account__c = objChildContractLineItem.ServiceContract.AccountId,
                        SBQQSC__Product__c = objChildContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__c,
                        SBQQSC__Number__c = 1,
                        StartDate = objChildContractLineItem.StartDate,
                        EndDate = objChildContractLineItem.EndDate,
                        Quantity = objChildContractLineItem.Quantity,
                        SBQQSC__Quantity__c = objChildContractLineItem.SBQQSC__Quantity__c,
                        SBQQSC__RenewalQuantity__c = objChildContractLineItem.SBQQSC__RenewalQuantity__c,
                        SBQQSC__BundledQuantity__c = objChildContractLineItem.SBQQSC__BundledQuantity__c,
                        SBQQSC__Bundle__c = TRUE,
                        SBQQSC__ComponentDiscountedByPackage__c = FALSE,
                        SBQQSC__SubscriptionStartDate__c = objChildContractLineItem.SBQQSC__SubscriptionStartDate__c,
                        SBQQSC__SubscriptionEndDate__c = objChildContractLineItem.SBQQSC__SubscriptionEndDate__c,
                        PricebookEntryId = objChildContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__PricebookEntryId__c,
                        UnitPrice = objChildContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__NetPrice__c,
                        SBQQSC__QuoteLine__c = objChildContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__c
                    )
                );
            }
        }
        
        if (!test.isrunningtest()) { upsert mapParentWithParentCli.values(); }
        
        for (String strConcatQlParentWithContract : mapParentWithChildCliList.keySet()) {
            for (ContractLineItem objChildContractLineItem : mapParentWithChildCliList.get(strConcatQlParentWithContract)) {
                objChildContractLineItem.SBQQSC__RootId__c = mapParentWithParentCli.get(strConcatQlParentWithContract).Id;
                objChildContractLineItem.SBQQSC__RequiredById__c = mapParentWithParentCli.get(strConcatQlParentWithContract).Id;
                listContractLineItemToUpdate.add(objChildContractLineItem);
            }
        }
        
        update listContractLineItemToUpdate;
    }
    
    public void finish(Database.BatchableContext BC) {
    
    }
}