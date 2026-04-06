public class CustomEmailTemplateController {
    public Id quoteId {get;set;} 
 
    public List<SBQQ__QuoteLine__c> getLines(){ 
        List<SBQQ__QuoteLine__c> Records = [select Id, Name, SBQQ__Number__c, SBQQ__ProductName__c, SBQQ__SubscriptionTerm__c, SBQQ__Quantity__c, SBQQ__ListPrice__c, SBQQ__ListTotal__c,
                  Promo_Disc__c, SBQQ__Discount__c, SBQQ__TotalDiscountRate__c, SBQQ__AdditionalDiscount__c, SBQQ__NetTotal__c from SBQQ__QuoteLine__c 
                   where SBQQ__Quote__c =: quoteId ORDER BY SBQQ__Number__c];
        return Records;
    }
}