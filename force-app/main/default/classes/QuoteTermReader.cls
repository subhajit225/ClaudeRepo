/**
* @Class Name :- QuoteTermReader
* @Author :- Mustakim Shaikh
* @Created Date :- May 12th, 2025 
* @description : CPQ22-5226 QuoteTermReader
*   This class provides functionality to load quote terms and evaluate whether additional
*   Terms and Conditions (TnC) are required for a given quote based on metadata-driven conditions.
*   It interacts with SBQQ.QuoteTermAPI and Addnl_TnC_Query_Clause__mdt metadata.
* TestClass   : QuoteTermReaderTest

// ********************Mofification Log *****************************************************************************
*     
* Modified By          Date             Description (Include Jira Details)
* 
*    
* 
// ********************Modification Log *****************************************************************************
**/
public with sharing class QuoteTermReader {

    
    // Holds the list of additional quote terms queried from SBQQ__QuoteTerm__c. This is used to avoid redundant SOQL queries within the setAdditionalTnCFlag method.
    static List<SBQQ__QuoteTerm__c> adnlQuoteTermsList;

    /**
     * @description : Loads quote terms for a given quote and template in the specified language.
     *
     * @param quoteId    The Id of the SBQQ__Quote__c record.
     * @param templateId The Id of the template to use.
     * @param language   The language code for the terms.
     * @return           A list of QuoteTermModel objects representing the quote terms.
     */
    public List<QuoteTermModel> load(Id quoteId, Id templateId, String language) {
        TermContext ctx = new TermContext(templateId, language);
        String quoteTermsJSON = SBQQ.ServiceRouter.load('SBQQ.QuoteTermAPI.Load', quoteId, JSON.serialize(ctx));
        return (List<QuoteTermModel>) JSON.deserialize(quoteTermsJSON, List<QuoteTermModel>.class);
    }

    /**
     * @class TermContext
     * @description
     *   Helper class to encapsulate the context for loading quote terms.
     */
    private class TermContext {
        private Id templateId;
        private String language;

        /**
         * @description : Constructor for TermContext.
         *
         * @param templateId The Id of the template.
         * @param language   The language code.
         */
        private TermContext(Id templateId, String language) {
            this.templateId = templateId;
            this.language = language;
        }
    }

    // Call in QuoteTriggerHelper
    // qt.Additional_Terms_Required__c = QuoteTermReader.setTnCFlag(qt, quotelines);

    /**
     * @description Evaluates whether additional Terms and Conditions are present for a given Quote.
     * This method checks the Quote and its related Quote Lines against metadata-driven conditions
     * defined in Addnl_TnC_Query_Clause__mdt. If any condition is met, it returns true.
     *
     * @param quoteRec      The SBQQ__Quote__c record to evaluate.
     * @param quoteLineList A map of Quote Line Ids to SBQQ__QuoteLine__c records related to the quote.
     * @return              True if any condition is met that requires additional TnC, false otherwise.
     */
    public static Boolean setAdditionalTnCFlag(SBQQ__Quote__c quoteRec, Map <Id, SBQQ__QuoteLine__c > quoteLineList) {
        //FY25SR-1861
        List<SBQQ__QuoteLine__c> replacementLines = new List<SBQQ__QuoteLine__c>();

        // Check if the Quote is a Scale Utility Quote, as there will be always Additional Terms
        if(quoteRec.OpportunitySubType__c == 'GC Offer'){
            return true;
        }

        List<Addnl_TnC_Query_Clause__mdt> clauseLst = Addnl_TnC_Query_Clause__mdt.getAll().values();
        
        // Check Quote-level conditions first
        for (Addnl_TnC_Query_Clause__mdt mdt : clauseLst) {
            if (mdt.Object_Scope__c == 'Quote' && mdt.FieldName__c != null) {
                Object fieldValue = quoteRec.get(mdt.FieldName__c);
                if (evaluateCondition(fieldValue, mdt.Operator__c, mdt.Value__c)) {
                    return true;
                }
            }
        }

        // Only check QuoteLine-level conditions if no Quote-level condition is met
        for (SBQQ__QuoteLine__c ql : quoteLineList.values()) {
            if (String.isBlank(ql.Disposition_Reason__c) ||
                new Set<String>{ReplacementConstants.DISPOSE_NONE, 
                                ReplacementConstants.DISPOSTION_RENEWING, 
                                ReplacementConstants.UPGRADE_VALUE}.contains(ql.Disposition_Reason__c)) {
                for (Addnl_TnC_Query_Clause__mdt mdt : clauseLst) {
                    if (mdt.Object_Scope__c == 'QuoteLine' && mdt.FieldName__c != null) {
                        Object fieldValue = ql.get(mdt.FieldName__c);
                        String value = mdt.Value__c != null ? mdt.Value__c.replaceAll('\'', '') : '';
                        if (evaluateCondition(fieldValue, mdt.Operator__c, value)) {
                            return true;
                        }
                    }
                }
            }

            //FY25SR-1861 start
            if (ql.Special_Program__c == ReplacementConstants.CONVERT_VALUE ||
                ql.Special_Program__c == ReplacementConstants.UPGRADE_VALUE){
                replacementLines.add(ql);
            }
            //FY25SR-1861 end
        }

        //Only check QuoteTerm if no Quote/ QuoteLines met any condition
        QuoteTermReader quoteTermReader = new QuoteTermReader();
        List<QuoteTermModel> quoteTerms = quoteTermReader.load(quoteRec.Id, quoteRec.SBQQ__QuoteTemplateId__c, 'es');
        Set<Id> qTermsIdSet = new Set<Id>();
        for(QuoteTermModel qt: quoteTerms){
            qTermsIdSet.add(qt.Id);
        }
                
        if(Schema.sObjectType.SBQQ__QuoteTerm__c.isAccessible() && (adnlQuoteTermsList == null || adnlQuoteTermsList.isEmpty())){
            adnlQuoteTermsList = [Select Id from SBQQ__QuoteTerm__c Where Id IN: qTermsIdSet
             and Additional_Term__c = true WITH SECURITY_ENFORCED];
        }

        if(adnlQuoteTermsList != null){
            for(SBQQ__QuoteTerm__c qt : adnlQuoteTermsList){
                return true;
            }
        }

        //FY25SR-1861 check order item extensions
        List<Order_Item_Extension__c> orderItemExtensions = QuoteDocumentHelper.getOrderItemExtensionRecords(replacementLines);
        for (Order_Item_Extension__c orderItemExtension : orderItemExtensions){
            for (Addnl_TnC_Query_Clause__mdt mdt : clauseLst) {
                if (mdt.Object_Scope__c == 'Order_Item_Extension__c' && mdt.FieldName__c != null) {
                    Object fieldValue = orderItemExtension.get(mdt.FieldName__c);
                    if (evaluateCondition(fieldValue, mdt.Operator__c, mdt.Value__c)) {
                        return true;
                    }
                }
            }
        }

        return false;
    }
    
    
    /**
     * @description : Helper method to Evaluate a condition between a field value and a comparison value using the specified operator.
     *
     * @param fieldValue The value of the field to evaluate.
     * @param operator   The operator to use for comparison (e.g., '=', '!=', '>', '<', 'contains', etc.).
     * @param value      The value to compare against.
     * @return           True if the condition is met, false otherwise.
     */
    public static Boolean evaluateCondition(Object fieldValue, String operator, String value) {
        if (fieldValue == null) return false;
        String fieldStr = String.valueOf(fieldValue);
        switch on operator {
            when '='  { return fieldStr == value; }
            when '!=' { return fieldStr != value; }
            when '>'  { return Decimal.valueOf(fieldStr) > Decimal.valueOf(value); }
            when '<'  { return Decimal.valueOf(fieldStr) < Decimal.valueOf(value); }
            when '>=' { return Decimal.valueOf(fieldStr) >= Decimal.valueOf(value); }
            when '<=' { return Decimal.valueOf(fieldStr) <= Decimal.valueOf(value); }
            when 'contains' { return fieldStr.contains(value); }
            when 'startsWith' { return fieldStr.startsWith(value); }
            when 'endsWith' { return fieldStr.endsWith(value); }
            when 'notContains' { return !fieldStr.contains(value); }
            when else { return false; }
        }
    }
}