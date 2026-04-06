@isTest
public class FilterServiceTest {
    public static final String DASHBOARD_NAME = 'HeatMap';
    public static final String FILTER_DEV_NAME = 'Column_Filters';
    public static final String LOGGED_IN_USERID = UserInfo.getUserId();
    
	@testSetup
    public static void prepareSetupData(){
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
    public static void testgetDashboardFilers(){
        FilterService.getDashboardFilers(DASHBOARD_NAME);
    }
    
    @isTest
    public static void testgerUserPreferences(){
        FilterService.gerUserPreferences(DASHBOARD_NAME);
    }
    
    @isTest
    public static void testupsertFilterPreferences(){
        String selectedFilterValues = '[{"key":"Column_Filters", "value":"Account Information;Cloud Data"}]';
        FilterService.upsertFilterPreferences(DASHBOARD_NAME, selectedFilterValues);
    }
    
    @isTest
    public static void testupsertFilterPreferences2(){
        String uniqueUserName = 'TestUser' + DateTime.now().getTime() + '@rbk.com';
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User usr = new user(
            alias = 'std',
            email = 'testuser@testclass.com',
            emailencodingkey = 'UTF-8',
            firstname = 'test',
            lastname = 'user',
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            profileid = p.Id,
            timezonesidkey = 'America/Los_Angeles',
            username = uniqueUserName
        );
        insert usr;
        System.runAs(usr) {
            String selectedFilterValues = '[{"key":"Column_Filters", "value":"Account Information;Cloud Data"}]';
        	FilterService.upsertFilterPreferences(DASHBOARD_NAME, selectedFilterValues);
        }
    }
}