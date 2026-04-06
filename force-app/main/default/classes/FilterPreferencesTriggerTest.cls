@isTest
public class FilterPreferencesTriggerTest {
	public static final String DASHBOARD_NAME = 'HeatMap';
    public static final String FILTER_DEV_NAME = 'Column_Filters';
    public static final String LOGGED_IN_USERID = UserInfo.getUserId();
    
	@isTest
    public static void testFilterPreference(){
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
}