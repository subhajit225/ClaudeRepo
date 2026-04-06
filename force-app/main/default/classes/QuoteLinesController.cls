/**
 * @author Paritosh
 * @Date Created/Modified: 06/05/25
 * @description Controller for QuoteLinesPage
 * @Story FY25SR-1090
 */
public WITHOUT SHARING class QuoteLinesController {

    /** @description quote*/
    public sbqq__Quote__c quote {get; set;}
    /** @description template */
    public SBQQ__QuoteTemplate__c template {get; set;}
    /** @description quoteLines*/
    public List<SBQQ__QuoteLine__c> quoteLines {get; set;}
    /** @description line columns*/
    public List<SBQQ__LineColumn__c> lineColumns {get; set;}
    /** @description columns count*/
    public Integer columnCount {get; set;}
    /** @description currency Fields */
    public String currencyFields {get; set;}
    /** @description show table*/
    public Boolean showTable {get; set;}
    /** @description list of groups*/
    public List<GroupWrapper> groupList {get; set;}

    Id templateId;
    Map<String, String> filterOperatorMap = 
        new Map<String, String>{
            'equals' => '=', 'not equals' => '!=', 
            'less than' => '<', 'greater than' => '>'};
    

    /**
     * @description Contructor
     */
    public QuoteLinesController() {
        try {
            Id quoteId = (Id) ApexPages.currentPage().getParameters().get('qid');
            templateId = ApexPages.currentPage().getParameters().get('tid');
            SBQQ__TemplateSection__c section = getTemplateSection();
            template = getTemplate();
            showTable = true;
            Map<String, GroupWrapper> groupMap = new Map<String, GroupWrapper>();

            Map<String, sObjectField> fieldMap = SBQQ__QuoteLine__c.sObjectType.getDescribe().fields.getMap();
            currencyFields = '';
            for (String fieldName : fieldMap.keySet()){
                if(fieldMap.get(fieldName).getDescribe().getType() == DisplayType.CURRENCY){
                    currencyFields += ', ' + fieldName;
                }
            }

            //FY25SR-6040
            Map<String, String> labelMap = QuoteDocumentHelper.getVerbiages(quoteId);

            //create quote query
            String queryClause = Quote_Doc_Terms__mdt.getInstance('Quoteline_Query_Clause')?.Label__c;
            String queryQuote = 'SELECT Id';
            String qlFields = 'SELECT Id, prepayment_credit__c, Promo_Disc__c, Trade_Up_Discount__c, SBQQ__NetTotal__c, SBQQ__AdditionalDiscountAmount__c, SBQQ__RegularPrice__c, SBQQ__Group__r.Name';
            String qlConditions = ' FROM SBQQ__LineItems__r WHERE ' + queryClause;

            //add query fields
            if (section != null) {
                if (section.Line_Columns_Custom__r.size() > 0){
                    for (SBQQ__LineColumn__c lineColumn : section.Line_Columns_Custom__r){
                        if (!qlFields.containsIgnoreCase(lineColumn.SBQQ__FieldName__c)) {
                            qlFields += ', ' + lineColumn.SBQQ__FieldName__c;
                        }

                        if (lineColumn.SBQQ__ConditionalPrintField__c != null && 
                           !queryQuote.containsIgnoreCase(lineColumn.SBQQ__ConditionalPrintField__c)){
                            queryQuote += ', ' + lineColumn.SBQQ__ConditionalPrintField__c;
                        }
                    }
                    lineColumns = section.Line_Columns_Custom__r;
                }
                if (section.SBQQ__FilterField__c != null && 
                    section.SBQQ__FilterOperator__c != null && 
                    section.SBQQ__FilterValue__c != null){
                    qlConditions += ' AND ' + section.SBQQ__FilterField__c 
                                 + filterOperatorMap.get(section.SBQQ__FilterOperator__c);
                    String filterValue = section.SBQQ__FilterValue__c;
                    if(filterValue.isNumeric() || filterValue.toLowerCase() =='true' || 
                        filterValue.toLowerCase() == 'false'){
                        qlConditions += filterValue;
                    }
                    else {
                        qlConditions += '\'' + filterValue + '\'';
                    }
                }
            }

            //query quote
            queryQuote += ', (' + qlFields + qlConditions + ' ORDER BY SBQQ__Group__r.SBQQ__Number__c)';
            queryQuote += ' FROM SBQQ__Quote__c WHERE Id=:quoteId';
            quote = Database.query(queryQuote.trim());
            quoteLines = quote.SBQQ__LineItems__r;

            if (quote.SBQQ__LineItems__r == null || quote.SBQQ__LineItems__r.size() == 0){
                showTable = false;
                return;
            }

            if (lineColumns != null && lineColumns.size() > 0){
                lineColumns = filterLineColumns(lineColumns, quoteLines);
                setWidth(lineColumns);
            }
            
            //create one time sku
            SBQQ__QuoteLine__c oneTimeSKU;
            for (SBQQ__QuoteLine__c quoteLine : quoteLines){
                if ((quoteLine.Prepayment_Credit__c > 0 || quoteLine.Promo_Disc__c > 0 || 
                     quoteLine.Trade_Up_Discount__c > 0) && oneTimeSKU == null){
                    String oneTimeSKUJSON = '{"SBQQ__ProductCode__c" : "'
                            + (labelMap.containsKey('One_Time_Special_SKU') ? labelMap.get('One_Time_Special_SKU') : '')
                            +'", "List_Total_for_Template_PDF__c" : "$0.00", "List_Price__c":"$0.00",'
                            +' "Net_Total__c" : "$0.00", "SBQQ__Quantity__c" : 1, "SBQQ__ListPrice__c" : '
                            +'0.0, "SBQQ__NetTotal__c": 0.0,  "Quantity_TB_Template__c" : 1';
                    oneTimeSKUJSON += ', "SBQQ__Description__c" : "' 
                            + (labelMap.containsKey('One_Time_Special_description') ? labelMap.get('One_Time_Special_description') : '') + '"}';
                    oneTimeSKU = (SBQQ__QuoteLine__c) JSON.deserialize(oneTimeSKUJSON, SBQQ__QuoteLine__c.class);
                }

                //add to group
                String groupName = quoteLine.SBQQ__Group__r?.Name;
                if (!groupMap.containsKey(groupName)){
                    groupMap.put(groupName, new GroupWrapper(groupName));
                }
                groupMap.get(groupName).quoteLines.add(quoteLine);
                groupMap.get(groupName).total += quoteLine.SBQQ__NetTotal__c;
            }

            if (oneTimeSKU != null && groupMap.containsKey('Expansion Quote') && groupMap.get('Expansion Quote').quoteLines != null){
                groupMap.get('Expansion Quote').quoteLines.add(oneTimeSKU);
            }

            groupList = groupMap.values();
        }
        catch (Exception e){
            LogError.logCustomError('QuoteLinesController', e.getMessage(), 
                e.getStackTraceString(), 'QuoteLinesController controller');
        }
    }

    /**
     * @description get section info
     * @return template section record
     */
    public SBQQ__TemplateSection__c getTemplateSection(){
        List<SBQQ__TemplateSection__c> sections = 
            [SELECT SBQQ__FilterField__c, SBQQ__FilterOperator__c, SBQQ__FilterValue__c , 
                    (SELECT Name, SBQQ__DisplayOrder__c, SBQQ__Width__c, SBQQ__FieldName__c,
                            SBQQ__Alignment__c, SBQQ__ConditionalPrintField__c 
                       FROM Line_Columns_Custom__r ORDER BY SBQQ__DisplayOrder__c)
               FROM SBQQ__TemplateSection__c 
              WHERE SBQQ__Template__c=:templateId 
               AND SBQQ__Content__r.Name=:ReplacementConstants.CONTENT_NAME_LINES_NEW];

        if (sections.size()>0) return sections[0];
        else return null;
    }

    /**
     * @description get template info
     * @return template record
     */
    public SBQQ__QuoteTemplate__c getTemplate(){
        return [SELECT Id, SBQQ__FontFamily__c, SBQQ__FontSize__c, SBQQ__ShadingColor__c 
                  FROM SBQQ__QuoteTemplate__c WHERE Id = :templateId];
    }

    /**
     * @description filter line columns
     * @param lineColumnsParam line columns
     * @param quoteLines quote lines
     * @return line columns filtered
     */
    public List<SBQQ__LineColumn__c> filterLineColumns(List<SBQQ__LineColumn__c> lineColumnsParam, 
            List<SBQQ__QuoteLine__c> quoteLines){
        List<SBQQ__LineColumn__c> lineColumnsFiltered = new List<SBQQ__LineColumn__c>();
        for (SBQQ__LineColumn__c lineColumn : lineColumnsParam){
            Boolean hasValue = false;
            for (SBQQ__QuoteLine__c ql : quoteLines){
                if (ql.get(lineColumn.SBQQ__FieldName__c) != null){
                    if (lineColumn.SBQQ__FieldName__c == ReplacementConstants.PREPAYMENT_CREDIT_FIELD_API && 
                        ql.get(lineColumn.SBQQ__FieldName__c) == 0) continue;
                    hasValue = true;
                }

                //if discount is blank, use additional discount
                if (lineColumn.SBQQ__FieldName__c == 'SBQQ__Discount__c' && (ql.SBQQ__Discount__c == null || ql.SBQQ__Discount__c == 0) 
                && (ql.SBQQ__AdditionalDiscountAmount__c != null && ql.SBQQ__AdditionalDiscountAmount__c > 0)){
                    ql.SBQQ__Discount__c = ((ql.SBQQ__AdditionalDiscountAmount__c / ql.SBQQ__RegularPrice__c) * 100).setScale(2);
                }
            }
            if (hasValue){
                lineColumnsFiltered.add(lineColumn);
            }
        }

        return lineColumnsFiltered;
    }

    /**
     * @description set column width
     * @param lineColumnsParam line columns
     */
    public void setWidth(List<SBQQ__LineColumn__c> lineColumnsParam){
        Decimal totalWidth = 0.0;
        columnCount = 0;
        for (SBQQ__LineColumn__c lineColumn : lineColumnsParam){
            if ((lineColumn.SBQQ__ConditionalPrintField__c == null || 
                (Boolean) quote.get(lineColumn.SBQQ__ConditionalPrintField__c))){
                totalWidth += lineColumn.SBQQ__Width__c;
                columnCount++;
            }
        }


        if ((100 - totalWidth) > 0){
            for (SBQQ__LineColumn__c lineColumn : lineColumnsParam){
                lineColumn.SBQQ__Width__c += (100 - totalWidth) / columnCount;
            }
        }
    }

    /**
     * @description wrapper class for quote line group
     */
    public class GroupWrapper {
        /** @description quote lines in group*/
        public List<SBQQ__QuoteLine__c> quoteLines {get; set;}
        /** @description name of group*/
        public String name {get; set;}
        /** @description total of group*/
        public Decimal total {get; set;}

        /**
         * @description constructor
         * @param name : group name
         */
        public GroupWrapper(String name){
            this.name = name;
            quoteLines = new List<SBQQ__QuoteLine__c> ();
            total = 0.0;
        }
    }
}