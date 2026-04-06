/**
 * @author Paritosh
 * @Date Created/Modified: 06/05/25
 * @description Controller for OutstandingInvoicePage
 * @Story FY25SR-1090
 */
public WITH SHARING class OutstandingInvoiceController {

    /** @description Outstanding Invoice Label*/
    public String outstandingInvoiceLabel {get; set;}
    /** @description template */
    public SBQQ__QuoteTemplate__c template {get; set;}

    /**
     * @description Contructor
     */
    public OutstandingInvoiceController() {
        try{
        Id quoteId = (Id) ApexPages.currentPage().getParameters().get('qid');
        Id templateId = ApexPages.currentPage().getParameters().get('tid');
        template = getTemplate(templateId);
            List<SBQQ__QuoteLine__c>  quoteLines = 
                [SELECT Id, Replacement_Details__c FROM SBQQ__QuoteLine__c 
                  WHERE SBQQ__Quote__c =:quoteId 
                  AND Special_Program__c 
                        IN (:ReplacementConstants.CONVERT_VALUE, :ReplacementConstants.UPGRADE_VALUE)];
        
       //CPQ22-6040 get veribages from quote terms
       Map<String, String> labelMap = QuoteDocumentHelper.getVerbiages(quoteId);
        
            List<Order_Item_Extension__c> orderItemExtensions = 
                QuoteDocumentHelper.getOrderItemExtensionRecords(quoteLines);
        
        List<String> invoiceList = new List<String>();
        
        Boolean hasOutstandingInvoice = false;
        for (Order_Item_Extension__c orderItemExtension : orderItemExtensions){
            if (orderItemExtension.Unpaid__c){
                    invoiceList.add('Inv ' + orderItemExtension.Invoice_Number__c + ', ' 
                        + orderItemExtension.Invoice_Creation_Date__c);
                hasOutstandingInvoice = true;
            }
        }
       //CPQ22-6040 added contains check
            if (hasOutstandingInvoice && labelMap.containsKey(ReplacementConstants.CUSTOM_LABEL_OUTSTANDING_INVOICE)){
                outstandingInvoiceLabel = labelMap.get(ReplacementConstants.CUSTOM_LABEL_OUTSTANDING_INVOICE);
                outstandingInvoiceLabel = outstandingInvoiceLabel.replace('<invoice_info>', String.join(invoiceList, ', '));
                //CPQ22-6040 added to handle html encoded tags, for customized quote terms
                outstandingInvoiceLabel = outstandingInvoiceLabel.replace('&lt;invoice_info&gt;', String.join(invoiceList, ', '));
            }
        }
        catch (Exception e){
            LogError.logCustomError('OutstandingInvoiceController',
                e.getMessage(), e.getStackTraceString(), 'OutstandingInvoiceController controller');
        }
    }

    /**
     * @description get template info
     * @param templateId template id
     * @return template record
     */
    public SBQQ__QuoteTemplate__c getTemplate(Id templateId){
        return [SELECT Id, SBQQ__FontFamily__c, SBQQ__FontSize__c, SBQQ__ShadingColor__c FROM SBQQ__QuoteTemplate__c WHERE Id = :templateId];
    }
}