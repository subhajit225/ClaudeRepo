@isTest
public class HeatMapEntryTriggerTest {
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

        Id recordTypeId2 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer/Prospect').getRecordTypeId();
        objAccount1.Name = 'Test Account 01-06';
        objAccount1.RecordTypeId = recordTypeId2;
        insert objAccount1;

        objContact.LastName = 'Test Contact 31-05';
        objContact.Account = objAccount;
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
        hc.Manual_Entry__c = true;
        insert hc;

        HeatMap_Column__c hc1 = new HeatMap_Column__c();
        hc1.Name = 'VMware';
        hc1.Column_Filter__c = 'Enterprise Data';
        hc1.Read_Only__c = false;
        hc1.Sortable__c = false;
        hc1.Color_Coding__c = 'Target=>#0668DD;Not Protected=>#BAC9D1;Protected=>#00B46E';
        hc1.Manual_Entry__c = false;
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
}