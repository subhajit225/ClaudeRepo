/**
 * @author Paritosh
 * @Date Created/Modified: 10/06/25
 * @description Helper for quote doc custom pages
 * @Story FY25SR-1090
 */
public without sharing class QuoteDocumentHelper {
    
    /**
     * @description get order item extensions related to quote lines
     * @param quoteLines quote lines
     * @return Order_Item_Extension__c records
     */
    public static List<Order_Item_Extension__c> getOrderItemExtensionRecords(List<SBQQ__QuoteLine__c> quoteLines){

        Set<Id> selectedEntIds = new Set<Id>();

        //get ent ids and order item ids
        for(SBQQ__QuoteLine__c line : quoteLines) {
            if(!String.isBlank(line.Replacement_Details__c)) {
                ReplacementJson lineJson = (ReplacementJson) JSON.deserialize(
                    line.Replacement_Details__c,
                    ReplacementJson.class
                );
                if(lineJson.rowValues != null && (lineJson.mode == '1tomany' || lineJson.mode == '1to1' || lineJson.mode == 'manyto1')){
                    for(ReplacementJson.RowDetail row : lineJson.rowValues) {
                        selectedEntIds.add(row.entId);
                        if(row.inactiveLines != null && row.inactiveLines.size() > 0) {
                            for(ReplacementJson.RelatedChildEntRowDetail inactiveRow : row.inactiveLines) {
                                selectedEntIds.add(inactiveRow.childEntId);
                            }
                        }
                    }
                }
            }       
        }

        List<Order_Item_Extension__c> orderItemExts = [SELECT Id, Unbilled__c, Unpaid__c, Invoice_Number__c, Invoice_Creation_Date__c
            FROM Order_Item_Extension__c
            WHERE Order_Line_ID__c IN (SELECT Order_Service_Item__c FROM Entitlement WHERE Id IN :selectedEntIds)
            AND Order_Line_ID__c != NULL];

        return orderItemExts;
    }
     /**
     * @description get verbiages configured in quote terms
     * @param quoteId quote Id
     * @return Map of quote term name to quote term body
     * Story : CPQ22-6040
     */
    public static Map<String, String> getVerbiages(Id quoteId){

        Map<String, String> labelMap = new Map<String, String>();
        for (SBQQ__QuoteTerm__c term : [
            SELECT Id, Quote_Term_Name__c, SBQQ__StandardTerm__r.Quote_Term_Name__c, SBQQ__Body__c FROM SBQQ__QuoteTerm__c  
            WHERE (Quote_Term_Name__c !=null OR SBQQ__Quote__c =: quoteId) AND SBQQ__Active__c=true AND SBQQ__Status__c='Approved' ORDER BY SBQQ__Type__c DESC]){
                if (term.Quote_Term_Name__c != null){
                    labelMap.put(term.Quote_Term_Name__c, term.SBQQ__Body__c.stripHtmlTags());
                }
                else if (term.SBQQ__StandardTerm__c != null && term.SBQQ__StandardTerm__r.Quote_Term_Name__c != null){
                    labelMap.put(term.SBQQ__StandardTerm__r.Quote_Term_Name__c, term.SBQQ__Body__c.stripHtmlTags());
                }
        }

        return labelMap;

    }
}