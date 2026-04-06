/**
 * @author Paritosh
 * @Date Created/Modified: 06/05/25
 * @description Controller for OutstandingInvoiceAdditional
 * @Story FY25SR-1091
 */
public WITH SHARING class OutstandingInvoiceAdditionalController {
    /** @description One Time special label*/
    public String oneTimeSpecialLabel {get; set;}
    /** @description replacement TNC label*/
    public String replacementTNCLabel {get; set;}
    /** @description future unbilled label*/
    public String futureUnbilledLabel {get; set;}
    /** @description template */
    public SBQQ__QuoteTemplate__c template {get; set;}
    
    /**
     * @description Contructor
     */
    public OutstandingInvoiceAdditionalController() {
        try {
        Id quoteId = (Id) ApexPages.currentPage().getParameters().get('qid');
        Id templateId = ApexPages.currentPage().getParameters().get('tid');
        template = getTemplate(templateId);

        //CPQ22-6040
        Map<String, String> labelMap = QuoteDocumentHelper.getVerbiages(quoteId);

        List<SBQQ__QuoteLine__c>  quoteLines = [
                SELECT Id, Prepayment_Credit__c, Promo_Disc__c, 
                       Trade_Up_Discount__c, Special_Program__c, Replacement_Details__c
            FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =:quoteId];

        List<SBQQ__QuoteLine__c> replacementLines = new List<SBQQ__QuoteLine__c>();

        for (SBQQ__QuoteLine__c quoteLine : quoteLines){
                if (quoteLine.Prepayment_Credit__c > 0 || 
                    quoteLine.Promo_Disc__c > 0 || 
                    quoteLine.Trade_Up_Discount__c > 0){
                    oneTimeSpecialLabel = labelMap.get(ReplacementConstants.CUSTOM_LABEL_OTST);
                }
                if (quoteLine.Special_Program__c == ReplacementConstants.CONVERT_VALUE || 
                    quoteLine.Special_Program__c == ReplacementConstants.UPGRADE_VALUE){
                    replacementLines.add(quoteLine);
                    if (quoteLine.Prepayment_Credit__c > 0){
                        replacementTNCLabel = labelMap.get(ReplacementConstants.CUSTOM_LABEL_REPLACEMENT_TNC);
                }
            }
        }
        
            List<Order_Item_Extension__c> orderItemExtensions = 
                QuoteDocumentHelper.getOrderItemExtensionRecords(replacementLines);

            for (Order_Item_Extension__c orderItemExtension : orderItemExtensions){
                if (orderItemExtension.Unbilled__c || orderItemExtension.Unpaid__c){
                    replacementTNCLabel = labelMap.get(ReplacementConstants.CUSTOM_LABEL_REPLACEMENT_TNC);
                    if (orderItemExtension.Unbilled__c){
                        futureUnbilledLabel = labelMap.get(ReplacementConstants.CUSTOM_LABEL_FUTURE_UNBILLED);
                }
            }
        }
    }
        catch (Exception e){
            LogError.logCustomError('OutstandingInvoiceAdditionalController', 
                e.getMessage(), e.getStackTraceString(), 
                'OutstandingInvoiceAdditionalController controller');
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