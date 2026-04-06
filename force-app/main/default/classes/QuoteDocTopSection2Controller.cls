/*-------------------------------------------------- 
Purpose : show account and partner information in quote document
Story : REEN-57
Created : 4th Dec 23
----------------------------------------------------*/

public class QuoteDocTopSection2Controller {
     
    public PartnerInfo partnerInfo {get; set;}
    public SBQQ__Quote__c quote {get; set;}
    public SBQQ__QuoteTemplate__c QuoteTemplate{get; set;}
    public QuoteDocTopSection2Controller(){
        Id quoteId = ApexPages.currentPage().getParameters().get('qid');

        //get quote info
        quote = [SELECT Distributor_s_Name__c, SBQQ__BillingName__c, SBQQ__BillingStreet__c, SBQQ__BillingCity__c, SBQQ__BillingState__c, SBQQ__BillingPostalCode__c, SBQQ__BillingCountry__c
                                , Is_Renewal_Quote__c, SBQQ__Partner__c, SBQQ__Partner__r.Name,SBQQ__Distributor__r.name,SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Initial_Contacts_Name__c, SBQQ__Opportunity2__r.Initial_Contacts_Name__r.Name, SBQQ__Opportunity2__r.Initial_Contacts_Name__r.Email, SBQQ__Opportunity2__r.Initial_Contacts_Name__r.Phone
                                , NIPA__c, NIPA__r.Name,NIPD__c,NIPD__r.name,SBQQ__QuoteTemplateId__c,Quote_Template_Company_Email__c,SBQQ__SalesRep__r.name,MSP_Created_Date_Only__c,Expiration_Date__c,SBQQ__PaymentTerms__c, ShowSellToPartner__c, Sell_to_Partner__c 
                               FROM SBQQ__Quote__c WHERE Id=:quoteId];
        QuoteTemplate=[select name,SBQQ__CompanyStreet__c,SBQQ__CompanyCity__c,SBQQ__CompanyState__c,SBQQ__CompanyPostalCode__c,SBQQ__CompanyPhone__c from SBQQ__QuoteTemplate__c where id =:quote.SBQQ__QuoteTemplateId__c];
        partnerInfo = new PartnerInfo();
        
        //original partner
        if (quote.SBQQ__Partner__c!=null && quote.NIPA__c==null){
            partnerInfo.accountName = quote.SBQQ__Partner__r.Name;
            partnerInfo.DistributerName=quote.SBQQ__Distributor__r.name;
            
        }
        //non incumbent partner
        else if (quote.NIPA__c!=null){
            partnerInfo.accountName = quote.NIPA__r.Name;
            partnerInfo.DistributerName=quote.NIPD__r.Name;
            
        }
    }
    
    public class PartnerInfo{
        public String accountName {get; set;}
        public String DistributerName {get; set;}
            }

}