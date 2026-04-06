public with sharing class HeatMapController {
    public static final String LOGGED_IN_USER_ID = UserInfo.getUserId();
    public static final String DASHBOARD_NAME = 'HeatMap';
    public static final String COLUMN_FILTER = 'Column_Filters';
    public static final String COLUMN_FILTER_NAME = 'Column Filters';
    public static final List<String> rowFilterLables = new List<String>{'Column Filters','Sales Engineer','Account Executive','Account','Theatre','Area','Region','Territory','Type','Tier'};

    @AuraEnabled
    public static RowFilterHeaders getSavedFilterPreferances(){
        try {
            Map<String,List<String>> mapOfFilterAndSelectedFilterNames = HeatMapService.getSavedRowFilterPreferences(rowFilterLables,DASHBOARD_NAME);
            RowFilterHeaders rowHeaders = new RowFilterHeaders();
            List<String> selectedFilterNames = new List<String>();
            Map<String, List<String>> staticTierAndTypeValues = new Map<String, List<String>>{
                'Type' => new List<String>{'Customer', 'Prospect', 'MSP Customer'},
                'Tier' => new List<String>{'Tier 1', 'Tier 2', 'Tier 3', 'Tier 4', 'Tier 5'},
                'Theatre' => new List<String>{'EMEA', 'APAC', 'AMER','MSP'}
            };
            addColumnFiltersData(staticTierAndTypeValues);

            HeatMapService.queryAEAndSEAndAssignToWrapper(rowHeaders,mapOfFilterAndSelectedFilterNames);
            HeatMapService.queryAndAssignAllTerritories(rowHeaders, mapOfFilterAndSelectedFilterNames);

            rowHeaders.theatre = getStaticRowFilterData(staticTierAndTypeValues.get('Theatre'), mapOfFilterAndSelectedFilterNames, 'Theatre');
            rowHeaders.tier = getStaticRowFilterData(staticTierAndTypeValues.get('Tier'), mapOfFilterAndSelectedFilterNames,'Tier');
            rowHeaders.type = getStaticRowFilterData(staticTierAndTypeValues.get('Type'), mapOfFilterAndSelectedFilterNames,'Type');
            rowHeaders.columnFilters = getStaticRowFilterData(staticTierAndTypeValues.get('Column Filters'), mapOfFilterAndSelectedFilterNames,'Column Filters');

            List<String> selectedAccounts = new List<String>();
            if(mapOfFilterAndSelectedFilterNames != null && mapOfFilterAndSelectedFilterNames.containsKey('Account')){
                selectedAccounts = mapOfFilterAndSelectedFilterNames.get('Account');
            }else{
                new List<String>();
            }
            rowHeaders.account = getStaticRowFilterData(selectedAccounts, mapOfFilterAndSelectedFilterNames,'Account');
            return rowHeaders;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static List<Map<Boolean, Map<String, String>>> getStaticRowFilterData(List<String> values, Map<String,List<String>> mapOfFilterAndSelectedFilterNames, String filterName) {
        List<Map<Boolean, Map<String, String>>> rowDataList = new List<Map<Boolean, Map<String, String>>>();
        List<String> selectedFilterNames = mapOfFilterAndSelectedFilterNames.containsKey(filterName) ? mapOfFilterAndSelectedFilterNames.get(filterName) : new List<String>();
        for (String value : values) {
            rowDataList.add(new Map<Boolean, Map<String, String>>{
                selectedFilterNames.contains(value) => new Map<String, String>{value => value}
            });
        }
        return rowDataList;
    }

    public static void addColumnFiltersData(Map<String, List<String>> staticTierAndTypeValues){
        List<Schema.PicklistEntry> picklistEntry = HeatMap_Column__c.Column_Filter__c.getDescribe().getPicklistValues();
        if(!picklistEntry.isEmpty()){
            for( Schema.PicklistEntry pickListVal : picklistEntry){
                if(!staticTierAndTypeValues.containsKey('Column Filters')){
                    staticTierAndTypeValues.put('Column Filters', new List<String>());
                }
                String columnOption = pickListVal.getLabel();
                staticTierAndTypeValues.get('Column Filters').add(columnOption);
            }
        }
    }


    @AuraEnabled
    public static Map<String, Boolean> getCoulumnFilters(){
        Map<String, Object> mapOfFilterNameAndObjFilterValue = (Map<String, Object>)JSON.deserializeUntyped(FilterService.gerUserPreferences(DASHBOARD_NAME));
        List<String> selectedFilterNames = new List<String>();
        String selectedValues = (String)mapOfFilterNameAndObjFilterValue.get(COLUMN_FILTER_NAME);
        if (String.isNotBlank(selectedValues)) {
            for(String str: selectedValues.split(';')){
                selectedFilterNames.add(str);
            }
        }
        Map<String, Boolean> mapOfColumnValueWithState = new Map<String, Boolean>();
        List<Schema.PicklistEntry> picklistEntry = HeatMap_Column__c.Column_Filter__c.getDescribe().getPicklistValues();
            for( Schema.PicklistEntry pickListVal : picklistEntry){
                String columnOption = pickListVal.getLabel();
                if(!selectedFilterNames.isEmpty() && selectedFilterNames.contains(columnOption)){
                    mapOfColumnValueWithState.put(columnOption, true);
                }else{
                    mapOfColumnValueWithState.put(columnOption, false);
                }
            }
        return mapOfColumnValueWithState;
    }

    //TODO: Rename to getTableData
    @AuraEnabled
    public static TableWrapper getColumnsAccountDetails(String selectedFiltersToApex){
        //TODO: Rename to rowFilterToValues
    	Map<String,List<String>> mapOfFilterVsSelectedFilter = HeatMapService.parseSelectedData(selectedFiltersToApex);
        TableWrapper heatMapDetailsWrapper = new TableWrapper();
        List<HeatMapColumn> selectedColumns = HeatMapService.getHeatMapColumns(mapOfFilterVsSelectedFilter.get('columnFilters'));
        
        // List<String> testString = new List<String>{'1'};
        // List<HeatMapColumn> selectedColumns = HeatMapService.getHeatMapColumns(testString);

        Map<Id, HeatMapColumn> columnIdToColumn = new Map<Id, HeatMapColumn>();
        Boolean queryAccountInformationDetails = false;
        if(!selectedColumns.isEmpty()){
            heatMapDetailsWrapper.columnDetailsWrapper = new List<TableHeaderWrapper>();
            for(HeatMapColumn col : selectedColumns){
                TableHeaderWrapper wrp = new TableHeaderWrapper();
                wrp.columnName = col.name;
                wrp.columnCategory = col.category;
                wrp.columnId = col.columnId;
                wrp.sortingTypeDefinition = col.sortingTypeDefinition;
                wrp.isHeaderFilter = col.isHeaderFilter;
                wrp.reportUrl = col.reportUrl;
                wrp.isTelemetryAvailable = col.isTelemetryAvailable;
                heatMapDetailsWrapper.columnDetailsWrapper.add(wrp);
                columnIdToColumn.put(col.columnId, col);
                if(col.category == 'Account Information'){
                    queryAccountInformationDetails = true;
                }
            }
        }

        //  Map<Id,Account> queryAccounts = new Map<Id,Account>(HeatMapService.getAccountsForTheUser(new List<Id>()));
        Map<Id,Account> queryAccounts = new Map<Id,Account>(HeatMapService.getAccountsForTheUser(mapOfFilterVsSelectedFilter));
        
        //TODO: Rename to getWorkloadAttributes
        Map<Id,List<HeatMapAttribute>> accIdVsAttributesMap = HeatMapService.getHeatMapAttributes(queryAccounts, columnIdToColumn, queryAccountInformationDetails);
        if(!queryAccounts.isEmpty()){
            if (heatMapDetailsWrapper.accountDetailsWrapper == null) {
                heatMapDetailsWrapper.accountDetailsWrapper = new List<TableDataWrapper>();
            }

            for(Account acc: queryAccounts.values()){
                TableDataWrapper wrapper = new TableDataWrapper();
                wrapper.accountId = acc.Id;
                wrapper.accountName = acc.Name;
                wrapper.hasEditAccess = false;
                if(accIdVsAttributesMap.containsKey(acc.Id) && accIdVsAttributesMap.get(acc.Id) != null){
                    wrapper.workloadCells.addAll(accIdVsAttributesMap.get(acc.Id));//add the attributes to the data row
                }

                heatMapDetailsWrapper.accountDetailsWrapper.add(wrapper);
            }
        }
        return heatMapDetailsWrapper;
    }

    @AuraEnabled
    public static void saveHeatMapAttribute(HeatMap_Entry__c heatMapEntry){
        HeatMapService.saveHeatMapEntry(heatMapEntry);
    }

    @AuraEnabled
    public static String updateSelectedColumnFilters(String updatedValues){
        return HeatMapService.updateColumnFilterPreferences(DASHBOARD_NAME, updatedValues);
    }

    @AuraEnabled
    public static String updateSelectedRowFilters(String updatedValues){
        return HeatMapService.updateRowFilterPreferences(DASHBOARD_NAME, updatedValues);
    }

    @AuraEnabled
    public static void updateAccountInformation(Account accountObjRecord){
        update accountObjRecord;
    }

    @AuraEnabled
    public static List<Id> setEditAccessOnAccounts(List<Id> accountIdList){
        return HeatMapService.editableAccountRecords(accountIdList, LOGGED_IN_USER_ID);
    }

    //Every Table is a combination of header rows and data rows
    public class TableWrapper {
        @AuraEnabled
        public List<TableHeaderWrapper> columnDetailsWrapper { get; set; } //header row
        @AuraEnabled
        public List<TableDataWrapper> accountDetailsWrapper { get; set; }//data rows

        public TableWrapper(){
            this.columnDetailsWrapper = new List<TableHeaderWrapper>();
            this.accountDetailsWrapper = new List<TableDataWrapper>();
        }
    }

    //represents a data row in the table
    public class TableDataWrapper {
        @AuraEnabled
        public Id accountId { get; set; } //unique identifier for every row
        @AuraEnabled
        public String accountName { get; set; }
        @AuraEnabled
        public Boolean hasEditAccess { get; set; }
        @AuraEnabled
        public List<HeatMapAttribute> workloadCells { get; set; } //cells in the row

        public TableDataWrapper(){
            this.accountId = null;
            this.accountName = '';
            this.hasEditAccess = false;
            this.workloadCells = new List<HeatMapAttribute>();
        }
    }

    //represents a header cell in the table
    public class TableHeaderWrapper{
        @AuraEnabled
        public String columnName { get; set; }
        @AuraEnabled
        public String columnCategory { get; set; }
        @AuraEnabled
        public Id columnId { get; set; }
        @AuraEnabled
        public String sortingTypeDefinition { get; set; }
        @AuraEnabled
        public Boolean isHeaderFilter { get; set; }
        @AuraEnabled
        public String reportUrl { get; set; }
        @AuraEnabled
        public Boolean isTelemetryAvailable { get; set; }
    }

    public class RowFilterHeaders {
        @AuraEnabled
        public List<Map<Boolean,Map<String,String>>> salesEngineer;
        @AuraEnabled
        public List<Map<Boolean,Map<String,String>>> accountExecutive;
        @AuraEnabled
        public List<Map<Boolean,Map<String,String>>> theatre;
        @AuraEnabled
        public List<Map<Boolean,Map<String,String>>> area;
        @AuraEnabled
        public List<Map<Boolean,Map<String,String>>> region;
        @AuraEnabled
        public List<Map<Boolean,Map<String,String>>> territory;
        @AuraEnabled
        public List<Map<Boolean,Map<String,String>>> type;
        @AuraEnabled
        public List<Map<Boolean,Map<String,String>>> tier;
        @AuraEnabled
        public List<Map<Boolean,Map<String,String>>> columnFilters;
        @AuraEnabled
        public List<Map<Boolean,Map<String,String>>> account;
    }

}