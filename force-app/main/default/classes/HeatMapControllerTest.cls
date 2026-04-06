@isTest
public class HeatMapControllerTest {
    public static final String DASHBOARD_NAME = 'HeatMap';
    public static final String FILTER_DEV_NAME = 'Column_Filters';
    public static final String LOGGED_IN_USERID = UserInfo.getUserId();
    @TestSetup
    static void prepareTestSetupData(){
        insert new Opportunity_Stage_Days__c(AllowAcvCalculation__c = true, AllowArrCalculation__c = true);
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        
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
        
        objContact1.LastName = 'Test Contact 01-06';
        objContact1.Account = objAccount1;
        insert objContact1; 
        
        Opportunity objOpportunity = new Opportunity();
        objOpportunity.StageName = '1 Discovery';
        objOpportunity.closeDate = System.Today() + 30;
        objOpportunity.Name = 'Test Opp 31-05';
        objOpportunity.Opportunity_Sub_Type__c = 'Regular';
        objOpportunity.Initial_Contacts_Name__c = objContact.Id;
        objOpportunity.Distributor_Lookup__c = objAccount.Id;
        objOpportunity.Partner_Lookup__c = objAccount.Id;
        insert objOpportunity;
        /*
        Opportunity oppr = new Opportunity();
        objOpportunity.StageName = '1 Discovery';
        objOpportunity.closeDate = System.Today() + 30;
        objOpportunity.Name = 'Test Opp 31-05';
        objOpportunity.Opportunity_Sub_Type__c = 'Regular';
        objOpportunity.Initial_Contacts_Name__c = objContact1.Id;
        objOpportunity.Distributor_Lookup__c = objAccount1.Id;
        objOpportunity.Partner_Lookup__c = objAccount1.Id;
        insert oppr;
*/
        
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
        insert hc;

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
        
        Health_Check__c healthCheck = new Health_Check__c(
            Account__c = objAccount1.Id,
            Date__c = Date.today().addDays(10)
        );
        insert healthCheck;
        
        Health_Check__c pastHealthCheck = new Health_Check__c(
            Account__c = objAccount1.Id,
            Date__c = Date.today().addDays(-10)
        );
        insert pastHealthCheck;
        
        /*
        
        Product2 pd = new Product2(Name = 'Pord B', ProductCode = 'Product123XYZ', isActive = true, PDM_Feature_Enabled__c = false, Bundle_Features__c = 'App Flows;OnPrem NoSQL;OnPrem CDM;OnPrem UCL');
        pd.IsActive = true;
        insert pd;
        
        Asset asst = new Asset(Name = 'Test1234567Asset', SerialNumber = 'Test1234567Asset', Serial_Number__c = 'Test1234567Asset', Product2ID = pd.Id, Accountid = objAccount1.Id);
    	insert asst;
        
        Id standardPriceBookId = Test.getStandardPricebookId();
        PricebookEntry pbestandard = new PricebookEntry(Pricebook2Id = standardPriceBookId, Product2Id = pd.Id, UnitPrice = 99, isActive = true);
        PriceBook2 pb1 = new Pricebook2(Name = 'Test PriceBook', Description = 'Price Book 2009 Products 1', IsActive = true);
    	insert pb1;

    	PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pb1.id, Product2Id = pd.Id, UnitPrice = 99, isActive = true);
        
                
        Order ordr = new Order(
          Type = 'Revenue',
          AccountId = objAccount1.Id,
          OpportunityId = oppr.Id,
          ShippingStreet = 'Test Street',
          ShippingCity = 'Test City',
          ShippingState = null,
          ShippingCountry = 'Austria',
          ShippingPostalcode = '94820',
          EffectiveDate = system.Today(),
          Status = 'Pending'
        );
        insert ordr;
        
        OrderItem oli1 = new OrderItem(
          OrderId = ordr.Id,
          Quantity = 5,
          PricebookEntryId = pbe.Id,
          UnitPrice = pbe.UnitPrice,
          SerialNumber__c = 'Test1234567Asset2',
          Support_End_Date__c = System.Today().addYears(1),
          Support_Start_Date__c = System.Today()
        );
        insert oli1;
       
        Entitlement futureEntitlement = new Entitlement(
              Name = 'Testing',
              AccountId = objAccount1.Id,
              StartDate = Date.valueof(System.now().addDays(-2)),
              AssetId = asst.Id,
              Product__c = pd.Id,
              Order_Service_Item__c = oli1.id,
              EndDate = Date.today().addDays(30)
         );
         insert futureEntitlement;
		*/
        
        /*insert new TriggerControl__c(name = 'Entitlement', DisableTrigger__c = true);
        Entitlement rscEnt = new Entitlement(); 
        rscEnt.Name = 'RSC';
        rscEnt.AccountId = objAccount1.Id;
        rscEnt.Type = 'Admin';
        rscEnt.SubType__c = 'RSC';
        rscEnt.StartDate = Date.today();
        rscEnt.EndDate = Date.today().addDays(30);
        insert rscEnt;*/
    }
    
    @isTest
    public static void testMethod1(){
        HeatMapController.getCoulumnFilters();
        List<String> filters = new List<String>();
        List<Schema.PicklistEntry> picklistEntry = HeatMap_Column__c.Column_Filter__c.getDescribe().getPicklistValues();
        for( Schema.PicklistEntry pickListVal : picklistEntry){
            filters.add(pickListVal.getLabel());
        }
        String selectedFiltersToApex = '{"columnFilters":["Account Information","Cloud Data","Enterprise Data"]}';
        HeatMapController.getColumnsAccountDetails(selectedFiltersToApex);
        String updatedValues = '[{"key":"Column_Filters", "value":"Account Information;Cloud Data"}]';
        HeatMapController.updateSelectedColumnFilters(updatedValues);
    }
    
    
    @isTest
    public static void testMethod2(){
        Account objAccount1 = [SELECT Id FROM Account WHERE Name = 'Test Account 01-06' LIMIT 1];
        HeatMap_Column__c hc = [SELECT Id FROM HeatMap_Column__c WHERE Name = 'VMware' LIMIT 1];
        HeatMap_Entry__c entry = new HeatMap_Entry__c();
        entry.Account__c = objAccount1.Id;
        entry.Automated_LCD__c = System.now();
        entry.Automated_Value__c = 'Protected';
        entry.HeatMap_Column__c = hc.Id;
        entry.Manual_LCD__c = System.now();
        entry.Automated_Object_Count__c	= 2;
        entry.Manual_Object_Count__c = 1;
        entry.AccountId_ColumnId__c = objAccount1.Id + '_' + hc.Id;
        insert entry;
        HeatMapController.saveHeatMapAttribute(entry);
    }
    
    @isTest
    public static void testGetSavedFilterPreferences() {
        HeatMapController.RowFilterHeaders result = HeatMapController.getSavedFilterPreferances();
    }
    
    @isTest
    public static void testMethod3() {
        /*String updatedValues1 = '[{"key":"Row_Filters", "value":"Sales Engineer;Account Executive;Account"}]';
        String result = HeatMapController.updateSelectedRowFilters(updatedValues1);*/
        String result = HeatMapController.updateSelectedRowFilters('test');
    }

    @isTest
    public static void testMethod4() {
        Account objAccount1 = [SELECT Id FROM Account WHERE Name = 'Test Account 01-06' LIMIT 1];
        HeatMap_Column__c hc = [SELECT Id FROM HeatMap_Column__c WHERE Name = 'VMware' LIMIT 1];
        HeatMap_Entry__c entry1 = new HeatMap_Entry__c(
            Account__c = objAccount1.Id,
            HeatMap_Column__c = hc.Id,
            Automated_LCD__c = System.now()
        );
        insert entry1;
        // String selectedFiltersToApex = 'columnFilters=VMware';
        String selectedFiltersToApex = '{"salesEngineer":[],"accountExecutive":[],"account":["' + objAccount1.Id+'"],"theatre":[],"area":[],"region":[],"territory":[],"type":[],"tier":[],"columnFilters":[]}';
        HeatMapController.TableWrapper result = HeatMapController.getColumnsAccountDetails(selectedFiltersToApex);
    }
    
    @isTest
    public static void testMethod5() {
         Account objAccount1 = [SELECT Id FROM Account WHERE Name = 'Test Account 01-06' LIMIT 1];
         String accountId = objAccount1.Id;
         String accountColName1 = 'PG Notes';
         String accountColName2 = 'PG Next Step';
         String accountColVal = 'Test notes for PG';
         HeatMapController.updateAccountInformation(objAccount1);
    }

    @isTest
    public static void testGetSavedFilterPreferencesCatchBlock() {
        try {
            HeatMapController.RowFilterHeaders result = HeatMapController.getSavedFilterPreferances();
        } catch (AuraHandledException e) {
            System.assertEquals('Simulated exception for testing catch block', e.getMessage(), 'Expected exception message does not match');
        }
    }
}