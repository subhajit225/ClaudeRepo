public with sharing class HeatMapService {
    public static final String DASHBOARD_NAME = 'HeatMap';
    public static final String RTNAME_SALES_OPPORTUNITY = 'Sales Opportunity';
    public static final String RTNAME_RENEWAL_OPPORTUNITY = 'Renewal Opportunity';

    public static List<String> getColumnFilters() {
        List<String> filters = new List<String>();
        List<Schema.PicklistEntry> picklistEntry = HeatMap_Column__c.Column_Filter__c.getDescribe().getPicklistValues();
        for( Schema.PicklistEntry pickListVal : picklistEntry){
            filters.add(pickListVal.getLabel());
        }
        return filters;
    }

    public static List<HeatMapColumn> getHeatMapColumns(List<String> filterNames) {
        List<HeatMapColumn> columns = new List<HeatMapColumn>();
        if(filterNames != null && !filterNames.isEmpty()){
            for(HeatMap_Column__c heatColmn : [SELECT Id, Name, Column_Alignment__c, Header_Filter__c, Column_Filter__c,Read_Only__c,Sortable__c,Color_Coding__c,Manual_Entry__c,Sorting_Datatype_Definition__c, Report_URL__c, Telemetry_Workload_Name__c
                                                FROM HeatMap_Column__c
                                                WHERE Column_Filter__c =: filterNames
                                                ORDER BY Order_within_Filter__c ASC]){
                columns.add(new HeatMapColumn(heatColmn));
            }
        }
        return columns;
    }

    public static List<Account> getAccountsForTheUser(Map<String,List<String>> mapOfFilterVsSelectedFilter){
        String baseQuery = 'SELECT Id, Name, PG_Notes__c,  PG_Next_Steps__c, Date_Became_Customer__c, Rubrik_Sales_Engineer__r.Name, Owner.Name, SumOfAcvCloseOpp__c, Type, Total_Open_Opportunities__c, SumOfAcvOpenOpp__c, Lifetime_Total_Value__c FROM Account WHERE RecordType.Name = \'Customer/Prospect\''; 
        List<String> whereClauses = new List<String>();

        List<String> listOfSelectedSE = new List<String>();
        List<String> listOfSelectedAE = new List<String>();
        List<String> listOfSelectedAccounts = new List<String>();
        List<String> listOfSelectedTheatre = new List<String>();
        List<String> listOfSelectedArea = new List<String>();
        List<String> listOfSelectedRegion = new List<String>();
        List<String> listOfSelectedTerritory = new List<String>();
        List<String> listOfSelectedType = new List<String>();
        List<String> listOfSelectedTier = new List<String>();

        if (mapOfFilterVsSelectedFilter.get('salesEngineer') != null && !mapOfFilterVsSelectedFilter.get('salesEngineer').isEmpty()) {
            listOfSelectedSE = mapOfFilterVsSelectedFilter.get('salesEngineer');
            whereClauses.add('Rubrik_Sales_Engineer__c IN :listOfSelectedSE');
        }
        if (mapOfFilterVsSelectedFilter.get('accountExecutive') != null && !mapOfFilterVsSelectedFilter.get('accountExecutive').isEmpty()) {
            listOfSelectedAE = mapOfFilterVsSelectedFilter.get('accountExecutive');
            whereClauses.add('OwnerId IN :listOfSelectedAE');
        }
        if (mapOfFilterVsSelectedFilter.get('account') != null && !mapOfFilterVsSelectedFilter.get('account').isEmpty()) {
            listOfSelectedAccounts = mapOfFilterVsSelectedFilter.get('account');
            whereClauses.add('Id IN :listOfSelectedAccounts');
        }
        if (mapOfFilterVsSelectedFilter.get('theatre') != null && !mapOfFilterVsSelectedFilter.get('theatre').isEmpty()) {
            listOfSelectedTheatre = mapOfFilterVsSelectedFilter.get('theatre');
            whereClauses.add('ETM_Theatre__c IN :listOfSelectedTheatre');
        }
        if (mapOfFilterVsSelectedFilter.get('area') != null && !mapOfFilterVsSelectedFilter.get('area').isEmpty()) {
            listOfSelectedArea = mapOfFilterVsSelectedFilter.get('area');
            whereClauses.add('ETM_Area__c IN :listOfSelectedArea');
        }
        if (mapOfFilterVsSelectedFilter.get('region') != null && !mapOfFilterVsSelectedFilter.get('region').isEmpty()) {
            listOfSelectedRegion = mapOfFilterVsSelectedFilter.get('region');
            whereClauses.add('ETM_Region__c IN :listOfSelectedRegion');
        }
        if (mapOfFilterVsSelectedFilter.get('territory') != null && !mapOfFilterVsSelectedFilter.get('territory').isEmpty()) {
            listOfSelectedTerritory = mapOfFilterVsSelectedFilter.get('territory');
            whereClauses.add('ETM_Territory__c IN :listOfSelectedTerritory');
        }
        if (mapOfFilterVsSelectedFilter.get('type') != null && !mapOfFilterVsSelectedFilter.get('type').isEmpty()) {
            listOfSelectedType = mapOfFilterVsSelectedFilter.get('type');
            whereClauses.add('Type IN :listOfSelectedType');
        }
        if (mapOfFilterVsSelectedFilter.get('tier') != null && !mapOfFilterVsSelectedFilter.get('tier').isEmpty()) {
            listOfSelectedTier = mapOfFilterVsSelectedFilter.get('tier');
            whereClauses.add('Account_Tier__c IN :listOfSelectedTier');
        }
        
        String finalQuery = baseQuery;
        if (!whereClauses.isEmpty()) {
            finalQuery += ' AND (' + String.join(whereClauses, ' AND ') + ')';
        }else{
            return new List<Account>();
        }
        finalQuery += ' LIMIT 1000';   
        return Database.query(finalQuery);
    }

    /*public static List<Account> getAccountsForTheUser(List<Id> userId){
        List<Account> accounts = [SELECT Id, Name, PG_Notes__c, PG_Next_Steps__c, Rubrik_Sales_Engineer__r.Name, Owner.Name, SumOfAcvCloseOpp__c FROM Account WHERE RecordType.Name = 'Customer/Prospect' LIMIT 10];
        return accounts;
    }*/

    public List<HeatMapAttribute> sortByColumn(HeatMapColumn column, List<HeatMapAttribute> attributes) {
        return null;
    }
    //return map of all heatmap attributes
    public static Map<Id,List<HeatMapAttribute>> getHeatMapAttributes(Map<Id,Account> accIdVsAccountsMap, Map<Id,HeatMapColumn> colIdVsColumnsMap, Boolean queryAccountInformationDetails) {
        Map<Id,List<HeatMapAttribute>>accIdVsAttributesMap = new Map<Id,List<HeatMapAttribute>>();//map to store account id and its attributes
        Map<Id,Map<Id,HeatMap_Entry__c>> accIdAndHeatMapEntryMap = getHeatMapEntries(accIdVsAccountsMap.keySet(),colIdVsColumnsMap.keyset());//get all heatmap entries for accounts/columns

        parseAccountInformationDetails parseAccInfoObj = new parseAccountInformationDetails();
        if(queryAccountInformationDetails){
            parseAccInfoObj = getAccountInformationDetails(accIdVsAccountsMap.keySet());
        }
        for(Account acc : accIdVsAccountsMap.values()){
            /*Map<Id, Integer> accountIdToClusterCount = new Map<Id, Integer>();
            if(acc.Clusters__r.size() > 3){
                Integer count = 0;
                for(Cluster__c clstr : acc.Clusters__r){
                    if(clstr.Capacity_Days_Until_90__c < 90 ){
                        count++;
                    }
                }
                accountIdToClusterCount.put(acc.Id, count);
            }else{
                accountIdToClusterCount.put(acc.Id, 0);
            }*/
            Map<String,String> colNameToColValueMap = parseAccountInfoColumnValue(acc, parseAccInfoObj);
            List<HeatMapAttribute> attributes = new List<HeatMapAttribute>();//list to store attributes for an account
            for(HeatMapColumn column : colIdVsColumnsMap.values()){
                HeatMapAttribute attribute;
                if(column.type == 'Workload'){
                    if(accIdAndHeatMapEntryMap.containsKey(acc.Id) && accIdAndHeatMapEntryMap.get(acc.Id).containsKey(column.columnId)){
                        HeatMap_Entry__c entry = accIdAndHeatMapEntryMap.get(acc.Id).get(column.columnId);//get the entry for the account and column
                        attribute = new WorkloadAttribute(entry);
                        attribute.columnType = column.type;
                        attribute.readOnly = column.isReadOnly;
                        attribute.columnAlignment = column.columnAlignment;
                        attribute.accountType = acc.Type;
                        //set the read only attribute based on the workload value and date difference
                        if(entry != null && entry.Final_Workload_Value__c == 'Protected' && entry.Automated_LCD__c !=null && getDateDaysDiff(entry.Automated_LCD__c) < 90){
                            attribute.readOnly = true;
                        }
                        if(column.Name == 'RSC Type'){
                            attribute.value = entry.Product_Edition__c;
                        }
                    }else {
                        //if no entry found
                        HeatMap_Entry__c entry = new HeatMap_Entry__c();
                        entry.Account__c = acc.Id;
                        entry.HeatMap_Column__c = column.columnId;
                        attribute = new WorkloadAttribute(entry);
                        attribute.columnType = column.type;
                        attribute.accountName = acc.Name;
                        attribute.accountType = acc.Type;
                        attribute.columnName = column.Name;
                        attribute.columnAlignment = column.columnAlignment;
                        if(colNameToColValueMap.containsKey(column.Name)){
                            attribute.value = colNameToColValueMap.get(column.Name);
                        }else{
                            attribute.value = '';
                        }
                        if(column.Name == 'CDM Capacity Risk' || column.Name == 'Next RBR' || column.Name == 'Next Renewal' || column.Name == 'Critical Support Cases'){
                            attribute.columnClickable = true;
                        }
                        attribute.columnFilter = column.category;
                        attribute.readOnly = column.isReadOnly;
                    }
                } else {
                    //if the column is not of type workload, create a manual attribute
                    attribute = new ManualAttribute();
                    attribute.accountId = acc.Id;
                    attribute.columnType = column.type;
                    attribute.columnId = column.columnId;
                    attribute.accountName = acc.Name;
                    attribute.accountType = acc.Type;
                    attribute.columnName = column.Name;
                    attribute.columnAlignment = column.columnAlignment;
                    if(colNameToColValueMap.containsKey(column.Name)){
                        attribute.value = colNameToColValueMap.get(column.Name);
                    }else{
                        attribute.value = '';
                    }
                    if(column.Name == 'CDM Capacity Risk' || column.Name == 'Next RBR' || column.Name == 'Next Renewal' || column.Name == 'Critical Support Cases'){
                        attribute.columnClickable = true;
                    }
                    attribute.columnFilter = column.category;
                    attribute.readOnly = column.isReadOnly;
                }
                attributes.add(attribute);
            }
            accIdVsAttributesMap.put(acc.Id,attributes);
        }
        return accIdVsAttributesMap;
    }

    public static String updateColumnFilterPreferences(String DASHBOARD_NAME, String updatedValues){
        try {
            FilterService.upsertFilterPreferences(DASHBOARD_NAME, updatedValues);
            return 'Success';
        } catch (Exception ex) {
            System.debug('Error Occurred: '+ex.getMessage());
            return 'Error';
        }
    }

    public static String updateRowFilterPreferences(String DASHBOARD_NAME, String updatedValues){
        try {
            FilterService.upsertFilterPreferences(DASHBOARD_NAME, updatedValues);
            return 'Success';
        } catch (Exception ex) {
            System.debug('Error Occurred: '+ex.getMessage());
            return 'Error';
        }
    }

    private static List<Id> getEligibleSEs(Id loggedInSEs) {
        List<Id> eligibleSEs = new List<Id>();
        eligibleSEs.add(loggedInSEs);
        return eligibleSEs;
    }

    //get all heatmap entries for accounts to map columns and entries
    private static Map<Id,Map<Id,HeatMap_Entry__c>> getHeatMapEntries(Set<Id> accountIds, Set<Id> columnIds) {
        Map<Id,Map<Id,HeatMap_Entry__c>> accIdVsHeatMapEntryMap = new Map<Id,Map<Id,HeatMap_Entry__c>>();

        //MKT26-1106
        for(HeatMap_Entry__c heatMapEntry : [SELECT Id,Name,Account__c,Automated_LCD__c,Automated_Value__c,Final_Workload_Value__c,HeatMap_Column__c,Manual_Entry__c,Manual_LCD__c,Manual_Workload_Value__c,Automated_Object_Count__c,Manual_Object_Count__c,Manual_Object_Capacity__c,Automated_Object_Capacity__c,Manual_Incumbent__c,Account__r.Name,HeatMap_Column__r.Name,HeatMap_Column__r.Column_Filter__c, Cell_Highlight_Override__c, Product_Edition__c
                                                FROM HeatMap_Entry__c
                                                WHERE Account__c IN : accountIds AND HeatMap_Column__c IN : columnIds]){
            if(accIdVsHeatMapEntryMap.containsKey(heatMapEntry.Account__c)){
                accIdVsHeatMapEntryMap.get(heatMapEntry.Account__c).put(heatMapEntry.HeatMap_Column__c,heatMapEntry);
            } else{
                accIdVsHeatMapEntryMap.put(heatMapEntry.Account__c,new Map<Id,HeatMap_Entry__c>{heatMapEntry.HeatMap_Column__c => heatMapEntry});
            }
        }
        return accIdVsHeatMapEntryMap;
    }

    //method to upsert heatmap entry
    public static void saveHeatMapEntry(HeatMap_Entry__c heatMapEntryRec) {
        List<HeatMap_Entry__c> heatMapEntryList = [SELECT ID,Name,Manual_LCD__c,Manual_Workload_Value__c,Manual_Incumbent__c,Manual_Object_Count__c,Manual_Object_Capacity__c,AccountId_ColumnId__c
                                                    FROM HeatMap_Entry__c
                                                    WHERE AccountId_ColumnId__c =:heatMapEntryRec.AccountId_ColumnId__c];
        for(HeatMap_Entry__c entry : heatMapEntryList){
            if(heatMapEntryRec.Manual_Workload_Value__c != null && (heatMapEntryRec.Manual_Workload_Value__c != entry.Manual_Workload_Value__c)){
                entry.Manual_Workload_Value__c = heatMapEntryRec.Manual_Workload_Value__c;
            }
            if(heatMapEntryRec.Manual_Incumbent__c != null && (heatMapEntryRec.Manual_Incumbent__c != entry.Manual_Incumbent__c)){
                entry.Manual_Incumbent__c = heatMapEntryRec.Manual_Incumbent__c;
            }
            if(heatMapEntryRec.Manual_Object_Count__c != null && (heatMapEntryRec.Manual_Object_Count__c != entry.Manual_Object_Count__c)){
                entry.Manual_Object_Count__c = heatMapEntryRec.Manual_Object_Count__c;
            }
            if(heatMapEntryRec.Manual_Object_Capacity__c != null && (heatMapEntryRec.Manual_Object_Capacity__c != entry.Manual_Object_Capacity__c)){
                entry.Manual_Object_Capacity__c = heatMapEntryRec.Manual_Object_Capacity__c;
            }
            entry.Manual_LCD__c = System.now();
        }
        if(heatMapEntryList.isEmpty()){
            heatMapEntryRec.Id = null;
            heatMapEntryRec.Manual_LCD__c = System.now();
            heatMapEntryList.add(heatMapEntryRec);
        }
        Upsert heatMapEntryList AccountId_ColumnId__c;
    }

    //method to convert datetime to date and find months difference
    private static Integer getDateDaysDiff(Datetime workloadDate){
        Date today = Date.today();
        Integer daysDiff = 0;
        if(workloadDate != null){
            daysDiff = workloadDate.date().daysBetween(today);
        }
        return daysDiff;
    }

    public static  Map<String, List<String>> getSavedRowFilterPreferences(List<String> rowFilterLables, String DASHBOARD_NAME) {
        Map<String, List<String>> mapOfFilterAndSelectedFilterNames = new Map<String, List<String>>();
        Map<String, Object> mapOfFilterNameAndObjFilterValue = (Map<String, Object>)JSON.deserializeUntyped(FilterService.gerUserPreferences(DASHBOARD_NAME));
        if(!mapOfFilterNameAndObjFilterValue.isEmpty()){
            for(String filterName: rowFilterLables){
                String selectedValues = (String)mapOfFilterNameAndObjFilterValue.get(filterName);
                if (String.isNotBlank(selectedValues)) {
                    List<String> selectedValuesList = new List<String>();
                    selectedValuesList.addAll(selectedValues.split(';')); 
                    mapOfFilterAndSelectedFilterNames.put(filterName,selectedValuesList);
                }
            }
        }
        return mapOfFilterAndSelectedFilterNames;
    }

    public static void queryAEAndSEAndAssignToWrapper(HeatMapController.RowFilterHeaders rowHeaders, Map<String, List<String>> selectedFilterNames){
        List<UserTerritory2Association> queryUserTerritoryData = [SELECT Territory2Id ,UserId, User.Name, RoleInTerritory2 FROM UserTerritory2Association 
                    WHERE (RoleInTerritory2 ='Account Executive' OR RoleInTerritory2 ='Sales Engineer') AND isActive = true AND Territory2.Territory2Model.State = 'Active' ORDER BY User.Name];
        
        Map<String, Set<Id>> mapOfSEAndAEIds = new Map<String, Set<Id>> {
            'Sales Engineer' => new Set<Id>(),
            'Account Executive' => new Set<Id>()
        };

        for (UserTerritory2Association uta : queryUserTerritoryData) {
            String role = uta.RoleInTerritory2;
            if (role == 'Sales Engineer' || role == 'Account Executive') {
                if (!mapOfSEAndAEIds.get(role).contains(uta.UserId)) {
                    Boolean isSelected = selectedFilterNames.containsKey(role) && selectedFilterNames.get(role).contains((String)uta.UserId);
                    getDynamicRowFilterData(rowHeaders, role, isSelected, uta.UserId, uta.User.Name);
                    mapOfSEAndAEIds.get(role).add(uta.UserId);
                }
            }
        }

    }

    public static void queryAndAssignAllTerritories(HeatMapController.RowFilterHeaders rowHeaders, Map<String, List<String>> selectedFilterNames){
        List<Territory2> queryAllTerritories = [SELECT ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c, ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c, 
                                                ParentTerritory2.Internal_Territory_Name__c, Internal_Territory_Name__c  
                                                FROM Territory2 
                                                WHERE ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c IN ('EMEA','APAC','AMER','MSP') AND Territory2Model.State = 'Active'];
        
        Map<String, Set<String>> mapOfRegions = new Map<String, Set<String>> { 'Region' => new Set<String>() };
        Map<String, Set<String>> mapOfAreas = new Map<String, Set<String>> { 'Area' => new Set<String>() };
        Map<String, Set<String>> mapOfTerritories = new Map<String, Set<String>> { 'Territory' => new Set<String>() };

        if(!queryAllTerritories.isEmpty()){
            for (Territory2 trr : queryAllTerritories) {
                processTerritoryLevel(rowHeaders, mapOfAreas, selectedFilterNames, 'Area', trr.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c);
                processTerritoryLevel(rowHeaders, mapOfRegions, selectedFilterNames, 'Region', trr.ParentTerritory2.Internal_Territory_Name__c);
                processTerritoryLevel(rowHeaders, mapOfTerritories, selectedFilterNames, 'Territory', trr.Internal_Territory_Name__c);
            }
        }
    }

    private static void processTerritoryLevel(HeatMapController.RowFilterHeaders rowHeaders, Map<String, Set<String>> mapOfFilterWithSetOfString, Map<String, List<String>> selectedFilterNames, String level, String name) {

        if (!mapOfFilterWithSetOfString.get(level).contains(name)) {
            Boolean isSelected = selectedFilterNames.containsKey(level) && selectedFilterNames.get(level).contains(name);
            getDynamicRowFilterData(rowHeaders, level, isSelected, name, name);
            mapOfFilterWithSetOfString.get(level).add(name);
        }
    }

    public static void getDynamicRowFilterData(HeatMapController.RowFilterHeaders rowHeaders, String rowFilter, Boolean isSelected, String key, String value) {
        Map<Boolean, Map<String, String>> rowFilterData = new Map<Boolean, Map<String, String>>{
            isSelected => new Map<String, String>{key => value}
        };
        switch on rowFilter {
            when 'Sales Engineer'{
                if (rowHeaders.salesEngineer == null) {
                    rowHeaders.salesEngineer = new List<Map<Boolean, Map<String, String>>>();
                }
                rowHeaders.salesEngineer.add(rowFilterData);
            }
            when 'Account Executive'{
                if (rowHeaders.accountExecutive == null) {
                    rowHeaders.accountExecutive = new List<Map<Boolean, Map<String, String>>>();
                }
                rowHeaders.accountExecutive.add(rowFilterData);
            }
            when 'Region'{
                if (rowHeaders.region == null) {
                    rowHeaders.region = new List<Map<Boolean, Map<String, String>>>();
                }
                rowHeaders.region.add(rowFilterData);
            }
            when 'Area' {
                if (rowHeaders.area == null) {
                    rowHeaders.area = new List<Map<Boolean, Map<String, String>>>();
                }
                rowHeaders.area.add(rowFilterData);
            }
            when 'Territory'{
                if (rowHeaders.territory == null) {
                    rowHeaders.territory = new List<Map<Boolean, Map<String, String>>>();
                }
                rowHeaders.territory.add(rowFilterData);
            }
        }
    }

    public static Map<String,List<String>> parseSelectedData(String selectedFiltersToApex){
        Map<String,List<String>> mapOfFilterVsSelectedFilter = new Map<String,List<String>>();
        ParseObjectData wrapper = (ParseObjectData) JSON.deserialize(selectedFiltersToApex,ParseObjectData.Class);
        mapOfFilterVsSelectedFilter.put('salesEngineer',wrapper.salesEngineer);
        mapOfFilterVsSelectedFilter.put('accountExecutive',wrapper.accountExecutive);
        mapOfFilterVsSelectedFilter.put('account',wrapper.account);
        mapOfFilterVsSelectedFilter.put('theatre',wrapper.theatre);
        mapOfFilterVsSelectedFilter.put('area',wrapper.area);
        mapOfFilterVsSelectedFilter.put('region',wrapper.region);
        mapOfFilterVsSelectedFilter.put('territory',wrapper.territory);
        mapOfFilterVsSelectedFilter.put('type',wrapper.type);
        mapOfFilterVsSelectedFilter.put('tier',wrapper.tier);
        mapOfFilterVsSelectedFilter.put('columnFilters',wrapper.columnFilters);
        return mapOfFilterVsSelectedFilter;
    }

    private static Map<String,String> parseAccountInfoColumnValue(Account acc, parseAccountInformationDetails parseAccInfoObj){
        System.debug('parseAccInfoObj---'+parseAccInfoObj);
        String nextMeetingDate = parseAccInfoObj.nextMeetingMap != null && parseAccInfoObj.nextMeetingMap.containsKey(acc.Id) ? parseAccInfoObj.nextMeetingMap.get(acc.Id).Date__c.format() : '';
        String lastMeetingDate = parseAccInfoObj.lastMeetingMap != null && parseAccInfoObj.lastMeetingMap.containsKey(acc.Id) ? parseAccInfoObj.lastMeetingMap.get(acc.Id).Date__c.format() : '';
        String nextRenewalDate = parseAccInfoObj.nextRenewalMap != null && parseAccInfoObj.nextRenewalMap.containsKey(acc.Id) ? parseAccInfoObj.nextRenewalMap.get(acc.Id).EndDate?.format() : '';
        String countOfCDMCapacity = parseAccInfoObj.cdmCapacityMap != null && parseAccInfoObj.cdmCapacityMap.get(acc.Id) > 0 ? String.valueOf(parseAccInfoObj.cdmCapacityMap.get(acc.Id)) : '';
        String newLogoDate = acc.Date_Became_Customer__c != null ? acc.Date_Became_Customer__c.format() : '';
        String lastNonRenewalPurchaseDate = parseAccInfoObj.accountIdToLastNonRenewalDateMap != null && parseAccInfoObj.accountIdToLastNonRenewalDateMap.containsKey(acc.Id) ? parseAccInfoObj.accountIdToLastNonRenewalDateMap.get(acc.Id)?.format() : '';
        String nextRenewalACV = parseAccInfoObj.accountIdToRenewalACVMap != null && parseAccInfoObj.accountIdToRenewalACVMap.containsKey(acc.Id) ? '$' + String.valueOf(parseAccInfoObj.accountIdToRenewalACVMap.get(acc.Id).format()).substringBefore('.') : '';
        String criticalSupportCases = parseAccInfoObj.accountIdToCountP1CasesMap?.get(acc.Id) != null ? String.valueOf(parseAccInfoObj.accountIdToCountP1CasesMap.get(acc.Id)) : '0';

        Map<String,String> colNameToColValueMap = new Map<String, String>();
        colNameToColValueMap.put('PG Notes',acc.PG_Notes__c);
        colNameToColValueMap.put('PG Next Step', acc.PG_Next_Steps__c);
        colNameToColValueMap.put('Next RBR',nextMeetingDate);
        colNameToColValueMap.put('Sales Engineer',acc.Rubrik_Sales_Engineer__r.Name);
        colNameToColValueMap.put('Account Executive',acc.Owner.Name);
        colNameToColValueMap.put('New Logo Date', newLogoDate);
        colNameToColValueMap.put('Sum of Won ACV','$'+String.valueOf(acc.Lifetime_Total_Value__c.format()).substringBefore('.'));
        colNameToColValueMap.put('Last RBR',lastMeetingDate);
        colNameToColValueMap.put('Next Renewal',nextRenewalDate);
        colNameToColValueMap.put('CDM Capacity Risk',countOfCDMCapacity);
        colNameToColValueMap.put('# of Open Opptys',String.valueOf(acc.Total_Open_Opportunities__c));
        colNameToColValueMap.put('ACV on Open Opptys','$'+String.valueOf(acc.SumOfAcvOpenOpp__c.format()).substringBefore('.'));
        colNameToColValueMap.put('Last Non-renewal Purchase Date', lastNonRenewalPurchaseDate);
        colNameToColValueMap.put('Next Renewal ACV', nextRenewalACV);
        colNameToColValueMap.put('Critical Support Cases', criticalSupportCases);
        return colNameToColValueMap;
    }

    private static parseAccountInformationDetails getAccountInformationDetails(Set<Id> accIds){
        Date todaDate = System.today();
        Map<Id, Health_Check__c> nextMeetingMap = new Map<Id, Health_Check__c>();
        Map<Id, Health_Check__c> lastMeetingMap = new Map<Id, Health_Check__c>();
        Map<Id, Entitlement> nextRenewalMap = new Map<Id, Entitlement>();
        Map<Id, List<Cluster__c>> accountIdToClusterMap = new Map<Id, List<Cluster__c>>();
        Map<Id, Date> accountIdToLastNonRenewalDateMap = new Map<Id, Date>();
        Map<Id, Decimal> accountIdToRenewalACVMap = new Map<Id, Decimal>();
        Map<Id, Integer> accountIdToCountP1CasesMap = new Map<Id, Integer>();

        Map<Id, Integer> accountIdToClusterCountMap = new Map<Id, Integer>();

        for(Health_Check__c healthChk : [SELECT Id, Account__c, Date__c, Status__c FROM Health_Check__c WHERE Account__c IN : accIds ORDER BY Date__c DESC]){
            if(healthChk.Date__c > todaDate && healthChk.Status__c == 'Scheduled' && !nextMeetingMap.containsKey(healthChk.Account__c)){
                nextMeetingMap.put(healthChk.Account__c, healthChk);
            }else if(healthChk.Date__c < todaDate && !lastMeetingMap.containsKey(healthChk.Account__c)){
                lastMeetingMap.put(healthChk.Account__c, healthChk);
            }
        }
        for(Entitlement nextRenew : [SELECT Id, AccountId, EndDate FROM Entitlement WHERE AccountId IN : accIds AND EndDate > TODAY AND Status = 'Active' ORDER BY EndDate DESC]){
                nextRenewalMap.put(nextRenew.AccountId, nextRenew);
        }

        for(Account account : [SELECT Id, (SELECT Id, account__c, Capacity_Days_Until_90__c FROM Clusters__r), (SELECT Id, RecordType.Name, CloseDate, IsClosed, ACV_Amount__c FROM Opportunities WHERE (IsClosed = false AND RecordType.Name = :RTNAME_RENEWAL_OPPORTUNITY) OR (IsWon = true AND RecordType.Name = :RTNAME_SALES_OPPORTUNITY) ORDER BY CloseDate DESC), (SELECT Id FROM Cases WHERE IsClosed = false AND Priority = 'P1') FROM Account WHERE Id IN : accIds]){
            accountIdToClusterMap.put(account.Id, account.Clusters__r);

            //process opportunities
            Decimal totalAcvAmount = 0;
            Date latestClosedDate;
            for(Opportunity opportunity : account.Opportunities){
                //consider only Open Renewal opportunities
                if(opportunity.RecordType.Name == RTNAME_RENEWAL_OPPORTUNITY && !opportunity.IsClosed){
                    totalAcvAmount += opportunity.ACV_Amount__c != null ? opportunity.ACV_Amount__c : 0;
                    //get the latest close date of won Sales opportunities
                }else if(opportunity.RecordType.Name == RTNAME_SALES_OPPORTUNITY && latestClosedDate == null){
                    latestClosedDate = opportunity.CloseDate;
            }
        }
            accountIdToRenewalACVMap.put(account.Id, totalAcvAmount);
            accountIdToLastNonRenewalDateMap.put(account.Id, latestClosedDate);

            //process cases
            accountIdToCountP1CasesMap.put(account.Id, account.Cases.size());
        }

        for(Id accId : accIds){
            if(!accountIdToClusterMap.containsKey(accId)){
                accountIdToClusterCountMap.put(accId, 0);
            }else{
                if(accountIdToClusterMap.get(accId).size() > 3){
                    integer count =0;
                    for(Cluster__c cls : accountIdToClusterMap.get(accId)){
                        if(cls.Capacity_Days_Until_90__c != null && cls.Capacity_Days_Until_90__c < 90){
                            count++;
                        }
                    }
                    accountIdToClusterCountMap.put(accId, count);
                }else{
                    accountIdToClusterCountMap.put(accId, 0);
                }
            }
            
        }

        parseAccountInformationDetails parseAccInfObj = new parseAccountInformationDetails();
        parseAccInfObj.nextMeetingMap = nextMeetingMap;
        parseAccInfObj.lastMeetingMap = lastMeetingMap;
        parseAccInfObj.nextRenewalMap = nextRenewalMap;
        parseAccInfObj.cdmCapacityMap = accountIdToClusterCountMap;
        parseAccInfObj.accountIdToLastNonRenewalDateMap = accountIdToLastNonRenewalDateMap;
        parseAccInfObj.accountIdToRenewalACVMap = accountIdToRenewalACVMap;
        parseAccInfObj.accountIdToCountP1CasesMap = accountIdToCountP1CasesMap;

        return parseAccInfObj;

    }

    public static List<Id> editableAccountRecords(List<Id> accountIdList, String loggedInUserId){
        Map<Id, UserRecordAccess> mapOfAccountIdWithRecordAccess = new Map<Id, UserRecordAccess>([SELECT RecordId FROM UserRecordAccess WHERE RecordId IN : accountIdList AND UserId =: loggedInUserId AND HasEditAccess = true LIMIT 200]);
        List<Id> accountIds = new List<Id>(mapOfAccountIdWithRecordAccess.keySet());
        return accountIds;
    }

    public class parseAccountInformationDetails{
        public Map<Id, Health_Check__c> nextMeetingMap;
        public Map<Id, Health_Check__c> lastMeetingMap;
        public Map<Id, Entitlement> nextRenewalMap;
        public Map<Id, Integer> cdmCapacityMap;
        public Map<Id, Date> accountIdToLastNonRenewalDateMap;
        public Map<Id, Decimal> accountIdToRenewalACVMap;
        public Map<Id, Integer> accountIdToCountP1CasesMap;
    }
    
    public class ParseObjectData {
        public List<String> salesEngineer;
        public List<String> accountExecutive;
        public List<String> account;
        public List<String> theatre;
        public List<String> area;
        public List<String> region;
        public List<String> territory;
        public List<String> type;
        public List<String> tier;
        public List<String> columnFilters;
    }
}