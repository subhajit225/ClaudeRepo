@isTest
public class LCC_New_POC_RequestControllerTest {
    static testMethod void testloadPOCmethod(){
          Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account act =new Account(BillingCountryCode = 'US', Is_Refreshed__c = False, Name = 'Test', Sync_to_NetSuite__c = false, RecordTypeId = devRecordTypeId, Website='www.test3.com', OwnerId = userinfo.getUserId(),type='Customer');
        
        insert act;
          opportunity oppr = new opportunity(Name='testing DIEtestsalesforce 4/6/2015' , Opportunity_Sub_Type__c = 'Regular', Distributor_Lookup__c = act.Id, Alliance_Source_Type_HW__c = 'Rubrik Initiated Alliance Deal',
                                           Mosaic_Customer_Environment__c='AWS', CloseDate = Date.Today().addDays(10), Lead_Email_Hidden__c='', AccountId = act.Id, StageName = '1 Discovery',
                                           Rubrik_Sales_Engineer__c = UserInfo.getUserId(), Alliance_Partner_Name__c='Amazon', Alliance_Source_Type__c='Alliance Initiated Deal', Alliance_Source_Type_SW__c = 'Alliance Initiated Deal', Installation_Assigned_To__c ='FE Install',
                                           Economic_Buyer__c = 'Test', Metric__c = 'Test', Decision_Process__c = 'Test', Decision_Criteria__c = 'Test',
                                           Identified_Pain__c = 'Test', Champion__c = 'Test', ForecastCategoryName = 'Best Case');
        
        insert oppr;
        List<Opportunity> oppList = new List<Opportunity>();
        oppList.add(oppr);
        test.startTest();
        PageReference pageRef = Page.LCC_New_POC_Request; // Add your VF page Name here
        pageRef.getParameters().put('id', String.valueOf(oppr.Id));
        Test.setCurrentPage(pageRef);
        ApexPages.StandardSetcontroller sc = new ApexPages.StandardSetcontroller(oppList);
        ApexPages.currentPage().getParameters().put('id', String.valueOf(oppr.Id));
        LCC_New_POC_RequestController lcc = new LCC_New_POC_RequestController(sc);
        lcc.loadPOCmethod();
        test.stopTest();
    }
}