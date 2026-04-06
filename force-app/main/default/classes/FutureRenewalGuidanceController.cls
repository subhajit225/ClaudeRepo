/**
 * @author Paritosh
 * @Date Created/Modified: 06/05/25
 * @description Controller for FutureRenewalGuidance
 * @Story FY25SR-1090
 */
public with sharing class FutureRenewalGuidanceController {
    /** @description show future guidance*/
    public Boolean showFutureRenewalGuidance {get; set;}
    /** @description future guidance verbiage*/
    public String futureRenewalGuidanceStatic {get; set;}
    /** @description quotelines*/
    public List<SBQQ__QuoteLine__c> quoteLines {get; set;}
    /** @description template */
    public SBQQ__QuoteTemplate__c template {get; set;}

    /**
     * @description Contructor
     */
    public FutureRenewalGuidanceController() {
        try {
        Id quoteId = (Id) ApexPages.currentPage().getParameters().get('qid');
        Id templateId = ApexPages.currentPage().getParameters().get('tid');
        template = getTemplate(templateId);

        //CPQ22-6040 get verbiages from quote terms
        Map<String, String> labelMap = QuoteDocumentHelper.getVerbiages(quoteId);

        quoteLines = [
                SELECT Id, Prepayment_Credit__c, Promo_Disc__c, Trade_Up_Discount__c, 
                       SBQQ__ProductName__c, SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, 
                       Renewal_Uplift_Estimate__c, CPQ_Uplift__c
                  FROM SBQQ__QuoteLine__c 
                 WHERE SBQQ__Quote__c =:quoteId 
                   AND Quote_Line_Type__c = :ReplacementConstants.QUOTE_TYPE_NEW 
                   AND SBQQ__SubscriptionPricing__c != NULL];
            
            
            for (SBQQ__QuoteLine__c quoteLine : quoteLines){
                if (quoteLine.Prepayment_Credit__c > 0 || 
                    quoteLine.Promo_Disc__c > 0 || 
                    quoteLine.Trade_Up_Discount__c > 0){
                    showFutureRenewalGuidance = true;
                    futureRenewalGuidanceStatic = 
                        labelMap.get(ReplacementConstants.CUSTOM_LABEL_RENEWAL_GUIDANCE);
                break;
            }
        }
    }
        catch (Exception e){
            LogError.logCustomError('FutureRenewalGuidanceController',
                e.getMessage(), e.getStackTraceString(), 
                'FutureRenewalGuidanceController controller');
        }
    }

    /**
     * @description get template info
     * @param templateId template id
     * @return template record
     */
    public SBQQ__QuoteTemplate__c getTemplate(Id templateId){
        return [SELECT Id, SBQQ__FontFamily__c, SBQQ__FontSize__c, SBQQ__ShadingColor__c 
                  FROM SBQQ__QuoteTemplate__c WHERE Id = :templateId];
    }
}