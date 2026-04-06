@isTest
public class HeatMapServiceTest {
    public static final String DASHBOARD_NAME = 'HeatMap';
    public static final String FILTER_DEV_NAME = 'Column_Filters';
    public static final String LOGGED_IN_USERID = UserInfo.getUserId();
    public static final Id RTID_SALES_OPPORTUNITY = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Sales_Opportunity').getRecordTypeId();
    public static final Id RTID_RENEWAL_OPPORTUNITY = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Renewal_Opportunity').getRecordTypeId();
    @TestSetup
    static void prepareTestSetupData(){
       insert new Opportunity_Stage_Days__c(AllowAcvCalculation__c = true, AllowArrCalculation__c = true);
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        disableFuncCS.Allow_Updating_Closed_Won_Oppty__c  = true;
        
        upsert disableFuncCS;
        Account objAccount = new Account();
        Contact objContact = new Contact();
        Contact objContact1 = new Contact();
        Account objAccount1 = new Account();
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        objAccount.Name = 'Test Account 31-05';
        objAccount.RecordTypeId = recordTypeId;
        insert objAccount;
        objAccount1.Name = 'Test Account 01-06';
        Id recordTypeId2 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer/Prospect').getRecordTypeId();
        objAccount1.RecordTypeId = recordTypeId2;
        insert objAccount1;
        objContact.Account = objAccount;
        objContact.LastName = 'Test Contact 31-05';
        insert objContact; 
        
        Date tsds = System.today().addDays(2);
        Health_Check__c healtchek1 = new Health_Check__c();
        healtchek1.Status__c = 'Scheduled';
        healtchek1.Date__c = tsds;
        healtchek1.Account__c = objAccount1.Id;
        insert healtchek1;
        
        Date tsdss = System.today().addDays(-3);
        Health_Check__c healtchek2 = new Health_Check__c();
        healtchek2.Status__c = 'Scheduled';
        healtchek2.Date__c = tsdss;
        healtchek2.Account__c = objAccount1.Id;
        insert healtchek2;
        
        objContact1.LastName = 'Test Contact 01-06';
        objContact1.Account = objAccount1;
        insert objContact1; 
        
        List<Opportunity> opportunities = new List<Opportunity>();
        Opportunity objOpportunity = new Opportunity();
        objOpportunity.StageName = '1 Discovery';
        objOpportunity.closeDate = System.Today() + 30;
        objOpportunity.Name = 'Test Opp 31-05';
        objOpportunity.Opportunity_Sub_Type__c = 'Regular';
        objOpportunity.Initial_Contacts_Name__c = objContact.Id;
        objOpportunity.Distributor_Lookup__c = objAccount.Id;
        objOpportunity.Partner_Lookup__c = objAccount.Id;
        opportunities.add(objOpportunity);

        Opportunity salesOpportunity = getOpportunity(RTID_SALES_OPPORTUNITY, objAccount.Id, objContact.Id, '1 Discovery');
        salesOpportunity.StageName = 'Closed Won';
        salesOpportunity.CloseDate = System.today().addDays(-10);
        opportunities.add(salesOpportunity);

        opportunities.add(getOpportunity(RTID_RENEWAL_OPPORTUNITY, objAccount.Id, objContact.Id, '1 Discovery'));

        insert opportunities;

        //create Cases
        List<Case> cases = new List<Case>();
        cases.add(getCase(objAccount.Id, 'New', 'P1'));
        insert cases;
        
        SBQQ__Quote__c objQuote = new SBQQ__Quote__c();
        objQuote.SBQQ__Status__c = 'Draft';
        objQuote.SBQQ__Opportunity2__c = objOpportunity.Id;
        objQuote.Task_Products__c='RBK-DISK-RETENTION';
        insert objQuote;

        HeatMap_Column__c hc = new HeatMap_Column__c();
        hc.Name = 'VMware';
        hc.Column_Filter__c = 'Enterprise Data';
        hc.Read_Only__c = false;
        hc.Sortable__c = false;
        hc.Color_Coding__c = 'Target=>#0668DD;Not Protected=>#BAC9D1;Protected=>#00B46E';
        hc.Sorting_Datatype_Definition__c  = 'Number';
        hc.Manual_Entry__c = true;
        hc.Column_Alignment__c = 'Right';
        insert hc;

        HeatMap_Column__c hc1 = new HeatMap_Column__c();
        hc1.Name = 'VMware';
        hc1.Column_Filter__c = 'Enterprise Data';
        hc1.Read_Only__c = false;
        hc1.Sortable__c = false;
        hc1.Color_Coding__c = 'Target=>#0668DD;Not Protected=>#BAC9D1;Protected=>#00B46E';
        hc1.Manual_Entry__c = false;
        hc1.Sorting_Datatype_Definition__c = 'String';
        hc.Column_Alignment__c = 'Left';
        insert hc1;

        Dashboard_Filter__c dashboard = new Dashboard_Filter__c();
        dashboard.Dashboard_Name__c = DASHBOARD_NAME;
		dashboard.Filter_Name__c = 'Column Filters';
        dashboard.Type__c = 'Checkbox Group';
        dashboard.Order__c = 10;
        dashboard.Options__c = 'Account Information;Product Editions;Enterprise Data;Cloud Data;Unstructured Data;SaaS Data;Data Security Posture;Data Threat Analytics;Cyber Security;RCV - Archive;Cyber Resiliency';
        dashboard.Filter_Developer_Name__c = FILTER_DEV_NAME;
        insert dashboard;
        
        Filter_Preference__c filter = new Filter_Preference__c();
        filter.Dashboard_Filter__c = dashboard.Id;
        filter.Filter_Identifier__c = DASHBOARD_NAME + FILTER_DEV_NAME + LOGGED_IN_USERID;
		filter.Preferred_Filter_Value__c = 'Account Information';
		filter.User__c = LOGGED_IN_USERID;
        insert filter;
        
        HeatMap_Entry__c entry = new HeatMap_Entry__c();
        entry.Account__c = objAccount1.Id;
        entry.Automated_LCD__c = System.now();
        entry.Automated_Value__c = 'Protected';
        entry.HeatMap_Column__c = hc.Id;
        entry.Manual_LCD__c = System.now();
        entry.Automated_Object_Count__c	= 2;
        entry.Manual_Object_Count__c = 1;
        entry.Manual_Workload_Value__c = 'Target';
        entry.Manual_Incumbent__c = 'Cohesity';
        entry.Manual_Object_Capacity__c = 2;
        entry.AccountId_ColumnId__c = '0011W000023btiHQAQ-aAMEc000000hDf3OAE';

        insert entry;

        HeatMap_Entry__c entry1 = new HeatMap_Entry__c();
        entry1.Account__c = objAccount1.Id;
        entry1.Automated_LCD__c = System.now();
        entry1.Automated_Value__c = 'Protected';
        entry1.HeatMap_Column__c = hc1.Id;
        entry1.Manual_LCD__c = System.now();
        entry1.Automated_Object_Count__c	= 2;
        entry1.Manual_Object_Count__c = 1;
        insert entry1;
    }
    
    @isTest
    public static void testMethod1(){
        HeatMap_Column__c htmapcol = [SELECT Id,Name,Column_Alignment__c ,Header_Filter__c,Column_Filter__c,Read_Only__c,Sortable__c,Color_Coding__c,Manual_Entry__c, Sorting_Datatype_Definition__c, Report_URL__c, Telemetry_Workload_Name__c FROM HeatMap_Column__c LIMIT 1];
        Account acc2 = [SELECT Id, Name, PG_Notes__c, Date_Became_Customer__c, PG_Next_Steps__c, Rubrik_Sales_Engineer__r.Name, Owner.Name, SumOfAcvCloseOpp__c,Type FROM Account WHERE Name LIKE '%Test Account 01-06%' LIMIT 1]; 
        HeatMapService service = new HeatMapService();
        HeatMapAttribute att = new WorkLoadAttribute();
        HeatMapColumn col = new HeatMapColumn(htmapcol);
        HeatMapService.getColumnFilters();
        Map<String,List<String>> updatedValues = new Map<String,List<String>>();
        updatedValues.put('salesEngineer',new List<String>{'12345678909876543'});
        updatedValues.put('accountExecutive',new List<String>{'12345678909876543'});
        updatedValues.put('account',new List<String>{acc2.Id});
        updatedValues.put('theatre',new List<String>{'EMEA','APAC','AMER'});
        updatedValues.put('area',new List<String>{'WEUR'});
        updatedValues.put('region',new List<String>{'UK-SOUTH'});
        updatedValues.put('territory',new List<String>{'UK-SOUTH-1'});
        updatedValues.put('type',new List<String>{'CUstomer','Prospect'});
        updatedValues.put('tier',new List<String>{'Tier 1'});
        HeatMapService.getAccountsForTheUser(updatedValues);
        HeatMapService.getHeatMapColumns(new List<String>{'Enterprise Data'});
        service.sortByColumn(col, new List<HeatMapAttribute>{att});
        Map<Id,Account> accIdVsAccountsMap = new Map<Id,Account>();
        Map<Id,HeatMapColumn> colIdVsColumnsMap = new Map<Id,HeatMapColumn>();
        colIdVsColumnsMap.put(htmapcol.Id,col);
        for(Account acc: [SELECT Id, Name, Date_Became_Customer__c, PG_Notes__c, PG_Next_Steps__c, Rubrik_Sales_Engineer__r.Name, Owner.Name, SumOfAcvCloseOpp__c,Type,Total_Open_Opportunities__c, SumOfAcvOpenOpp__c, Lifetime_Total_Value__c FROM Account LIMIT 10000]){ 
            accIdVsAccountsMap.put(acc.Id, acc);
        }
        
        HeatMapService.getHeatMapAttributes(accIdVsAccountsMap, colIdVsColumnsMap, true);
    }
    
    /*
    @isTest
    public static void testMethod2(){
        HeatMapAttribute manualAtt = new ManualAttribute();
        WorkloadAttribute workloadatt = new WorkloadAttribute();
        workloadatt.manualObjectCapacity = 2.0;
        workloadatt.manualincumbent = 'Test';
    	workloadatt.automatedValue = 'Test';
    	workloadatt.manualValue = 'Test';
        
        HeatMapEntry entryClass = new HeatMapEntry();
        entryClass.attributes = new List<HeatMapAttribute>{manualAtt};
    }*/
    
    @isTest
    public static void testMethod3() {
        String updatedValues = '[{"key":"Column_Filters", "value":"Cloud Data;Account Information"}]';
        String result = HeatMapService.updateColumnFilterPreferences(DASHBOARD_NAME, updatedValues);
    }
    
    @isTest
    public static void testMethod4() {
        HeatMap_Column__c hc = new HeatMap_Column__c();
        hc.Name = 'VMware';
        hc.Column_Filter__c = 'Enterprise Data';
        hc.Read_Only__c = false;
        hc.Sortable__c = false;
        hc.Color_Coding__c = 'Target=>#0668DD;Not Protected=>#BAC9D1;Protected=>#00B46E';
        hc.Manual_Entry__c = false;
        hc.Column_Alignment__c = 'Left';
        insert hc;
        
		Account acc2 = [SELECT Id, Name, PG_Notes__c, Date_Became_Customer__c, PG_Next_Steps__c, Rubrik_Sales_Engineer__r.Name, Owner.Name, SumOfAcvCloseOpp__c,Type, Total_Open_Opportunities__c, SumOfAcvOpenOpp__c FROM Account WHERE Name LIKE '%Test Account 01-06%' LIMIT 1]; 
        
        HeatMapService service = new HeatMapService();
        HeatMapAttribute att = new WorkLoadAttribute();
        HeatMapColumn col = new HeatMapColumn(hc);
        HeatMapService.getColumnFilters();
        Map<String,List<String>> updatedValues = new Map<String,List<String>>();
        updatedValues.put('salesEngineer',new List<String>());
        updatedValues.put('accountExecutive',new List<String>());
        updatedValues.put('account',new List<String>{acc2.Id});
        updatedValues.put('theatre',new List<String>{'EMEA','APAC','AMER'});
        updatedValues.put('area',new List<String>());
        updatedValues.put('region',new List<String>());
        updatedValues.put('territory',new List<String>());
        updatedValues.put('type',new List<String>());
        updatedValues.put('tier',new List<String>());
        HeatMapService.getAccountsForTheUser(updatedValues);
        
        HeatMapService.getHeatMapColumns(new List<String>{'Enterprise Data'});
        service.sortByColumn(col, new List<HeatMapAttribute>{att});
        Map<Id,Account> accIdVsAccountsMap = new Map<Id,Account>();
        Map<Id,HeatMapColumn> colIdVsColumnsMap = new Map<Id,HeatMapColumn>();
        colIdVsColumnsMap.put(hc.Id,col);
        for(Account acc: [SELECT Id, Name, PG_Notes__c,Date_Became_Customer__c,  PG_Next_Steps__c, Rubrik_Sales_Engineer__r.Name, Owner.Name, SumOfAcvCloseOpp__c,Type, Total_Open_Opportunities__c, SumOfAcvOpenOpp__c, Lifetime_Total_Value__c FROM Account LIMIT 10000]){  
            accIdVsAccountsMap.put(acc.Id, acc);
        }
        
        HeatMapService.getHeatMapAttributes(accIdVsAccountsMap, colIdVsColumnsMap, true);
    }
    
    @isTest
    public static void testMethod5() {
        String updatedValues = '[{"key":"Row Filters", "value":"Sales Engineer;Account Executive;Account"}]';
        String result = HeatMapService.updateRowFilterPreferences(DASHBOARD_NAME, 'test');
        // String result1 = HeatMapService.updateRowFilterPreferences(DASHBOARD_NAME, updatedValues);
    }
    
    @isTest
    public static void testMethod6() {
        HeatMap_Entry__c heatMapEntry = [SELECT Id,Name,Account__c,Automated_LCD__c,Automated_Value__c,Final_Workload_Value__c,HeatMap_Column__c,Manual_Entry__c,Manual_LCD__c,Manual_Workload_Value__c,Automated_Object_Count__c,Manual_Object_Count__c,Manual_Object_Capacity__c,Automated_Object_Capacity__c,Manual_Incumbent__c,Account__r.Name,HeatMap_Column__r.Name,HeatMap_Column__r.Column_Filter__c,AccountId_ColumnId__c FROM HeatMap_Entry__c LIMIT 1];
        HeatMapService.saveHeatMapEntry(heatMapEntry);
    }
    
    @isTest
    public static void testMethod7() {
        List<String> rowFilterLabels = new List<String>{'Column Filters','Sales Engineer','Account Executive','Theatre','Area','Region','Territory','Type','Tier'};
        Map<String, List<String>> result = HeatMapService.getSavedRowFilterPreferences(rowFilterLabels, DASHBOARD_NAME);
    }
    
    @isTest
    public static void testMethod8() {
        HeatMapController.RowFilterHeaders rowHeaders = new HeatMapController.RowFilterHeaders();
        Map<String, List<String>> selectedFilterNames = new Map<String, List<String>>();
        selectedFilterNames.put('Account Executive', new List<String>{});
        selectedFilterNames.put('Sales Engineer', new List<String>{});
        HeatMapService.queryAEAndSEAndAssignToWrapper(rowHeaders, selectedFilterNames);
    }
    
    @isTest
    public static void testMethod9() {
        HeatMapController.RowFilterHeaders rowHeaders = new HeatMapController.RowFilterHeaders();
        Map<String, List<String>> selectedFilterNames = new Map<String, List<String>>();
        selectedFilterNames.put('Region', new List<String>());
        selectedFilterNames.put('Area', new List<String>());
        selectedFilterNames.put('Territory', new List<String>());
        HeatMapService.queryAndAssignAllTerritories(rowHeaders, selectedFilterNames);
    }
    
    @isTest
    public static void testMethod10() {
        String selectedFiltersToApex = '{"columnFilters":["Account Information","Cloud Data"], "rowFilters":["Region1","Region2"]}';
        Map<String, List<String>> result = HeatMapService.parseSelectedData(selectedFiltersToApex);
    }

    @isTest
    public static void testMethod11() {
        Account testAccount = [SELECT Id, Name, PG_Notes__c,Date_Became_Customer__c, PG_Next_Steps__c, Rubrik_Sales_Engineer__r.Name, Owner.Name, SumOfAcvCloseOpp__c,Type,Total_Open_Opportunities__c, SumOfAcvOpenOpp__c, Lifetime_Total_Value__c FROM Account WHERE Name = 'Test Account 01-06' LIMIT 1]; 
        HeatMap_Column__c htmapcol = [SELECT Id, Name, Column_Alignment__c ,Header_Filter__c,Column_Filter__c, Read_Only__c, Sortable__c, Color_Coding__c, Manual_Entry__c, Sorting_Datatype_Definition__c, Report_URL__c, Telemetry_Workload_Name__c FROM HeatMap_Column__c WHERE Manual_Entry__c = true AND Name = 'VMware' LIMIT 1];
        HeatMap_Entry__c heatMapEntry = [SELECT Id, Manual_Entry__c, Manual_LCD__c , Account__c , HeatMap_Column__c FROM HeatMap_Entry__c WHERE Account__c =: testAccount.Id AND HeatMap_Column__c =: htmapcol.Id];
        HeatMapColumn col = new HeatMapColumn(htmapcol);
        Map<Id, Account> accIdVsAccountsMap = new Map<Id, Account>{heatMapEntry.Account__c => testAccount };
        Map<Id, HeatMapColumn> colIdVsColumnsMap = new Map<Id, HeatMapColumn>{ htmapcol.Id => col };
        Map<Id, List<HeatMapAttribute>> result = HeatMapService.getHeatMapAttributes(accIdVsAccountsMap, colIdVsColumnsMap, true);
    }

    @isTest
    public static void testMethod12() {
        Account testAccount = [SELECT Id, Name, Date_Became_Customer__c, PG_Notes__c, PG_Next_Steps__c, Rubrik_Sales_Engineer__r.Name, Owner.Name, SumOfAcvCloseOpp__c,Type,Total_Open_Opportunities__c, SumOfAcvOpenOpp__c, Lifetime_Total_Value__c FROM Account WHERE Name = 'Test Account 01-06' LIMIT 1]; 
        HeatMap_Column__c htmapcol = [SELECT Id, Name, Column_Alignment__c ,Header_Filter__c,Column_Filter__c, Read_Only__c, Sortable__c, Color_Coding__c, Manual_Entry__c,Sorting_Datatype_Definition__c, Report_URL__c, Telemetry_Workload_Name__c FROM HeatMap_Column__c WHERE Manual_Entry__c = false AND Name = 'VMware' LIMIT 1];
        HeatMap_Entry__c heatMapEntry = [SELECT Id, Manual_Entry__c, Manual_LCD__c , Account__c , HeatMap_Column__c FROM HeatMap_Entry__c WHERE Account__c =: testAccount.Id AND HeatMap_Column__c =: htmapcol.Id];
        HeatMapColumn col = new HeatMapColumn(htmapcol);
        Map<Id, Account> accIdVsAccountsMap = new Map<Id, Account>{heatMapEntry.Account__c => testAccount };
        Map<Id, HeatMapColumn> colIdVsColumnsMap = new Map<Id, HeatMapColumn>{ htmapcol.Id => col };
        Map<Id, List<HeatMapAttribute>> result = HeatMapService.getHeatMapAttributes(accIdVsAccountsMap, colIdVsColumnsMap, true);
    }

    @isTest
    public static void handleExceptions() {
        String DASHBOARD_NAME = 'TestDashboard';
        String updatedValues = 'TestValues';
        String result = HeatMapService.updateColumnFilterPreferences(null, updatedValues);
        HeatMapEntry hme = new HeatMapEntry();
    }
    
    @isTest
    public static void testMethod13(){
        User user = [SELECT Id From User where Profile.Name = 'System Administrator' and isActive = true LIMIT 1];
        List<Id> accountIdList = new List<Id>();
        for(Account acc : [SELECT Id, Name, PG_Notes__c,Date_Became_Customer__c, PG_Next_Steps__c, Rubrik_Sales_Engineer__r.Name, Owner.Name, SumOfAcvCloseOpp__c,Type,Total_Open_Opportunities__c, SumOfAcvOpenOpp__c FROM Account ]){
            accountIdList.add(acc.Id);
        }
        System.runAs(user){
            HeatMapService.editableAccountRecords(accountIdList, LOGGED_IN_USERID);
        }
        System.assertEquals(accountIdList.isEmpty(),false);
    }

    private static Opportunity getOpportunity(Id recordTypeId, Id accountId, Id contactId, String stageName) {
        Opportunity opportunity = new Opportunity();
        opportunity.recordTypeId = recordTypeId;
        opportunity.AccountId = accountId;
        opportunity.Initial_Contacts_Name__c = contactId;
        opportunity.StageName = stageName;
        opportunity.closeDate = System.Today() + 30;
        opportunity.Name = 'Test Opp 31-05';
        opportunity.Opportunity_Sub_Type__c = 'Regular';
        
        return opportunity;
    }

    private static Case getCase(Id accountId, String status, String priority) {
        Case caseObj = new Case();
        caseObj.AccountId = accountId;
        caseObj.Status = status;
        caseObj.Priority = priority;

        return caseObj;
    }


}