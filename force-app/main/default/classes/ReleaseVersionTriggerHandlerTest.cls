/**
 * @description :
 * @Author      : Vijay Kumar K R
 * @CreatedDate : Jan 8, 2025 
 * @Class    : ReleaseVersionTriggerHandler, ReleaseVersionTrigger
 */
@isTest
public class ReleaseVersionTriggerHandlerTest {

    @isTest
    static void testAfterUpdate() {

        TriggerControl__c tc = new TriggerControl__c(Name = 'ReleaseVersion', DisableTrigger__c = false);
        INSERT tc;

        List<Cluster__c> clusterList = new List<Cluster__c>{ 
            new Cluster__c(UUID__c = 'Cluster 1', Name = 'Cluster 1',  software_version__c = '9.0.0-24610', Release_Version_End_Of_Support_Date__c = Date.today().addDays(30)),
            new Cluster__c(UUID__c = 'Cluster 2', Name = 'Cluster 2',  software_version__c = '9.0.3-p4-25542', Release_Version_End_Of_Support_Date__c = Date.today().addDays(60)),
            new Cluster__c(UUID__c = 'Cluster 3', Name = 'Cluster 3',  software_version__c = '9.1.3-28061', Release_Version_End_Of_Support_Date__c = Date.today().addDays(90))};
        INSERT clusterList;
        
        Release_Version__c rv = new Release_Version__c( Name = 'Test Release Version', End_Of_Support_Date__c = Date.today().addDays(30));
        INSERT rv;
        
        Releases__c release = new Releases__c( Name = 'Test Release', Release_Version__c = rv.Id,  Version__c = '9.0.0-24610');
        INSERT release;

        rv.End_Of_Support_Date__c = Date.today().addDays(-60);
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
                UPDATE rv;
            Test.stopTest();
        }

        // Assert that the batch job was called. You can assert the number of jobs or run the job manually.
        List<CronTrigger> cronJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'ReleaseVersionUpdateClusterBatch'];
        Cluster__c objClstr = [SELECT Id, CDM_End_of_Support_Status__c FROM Cluster__c WHERE software_version__c = '9.0.0-24610' Limit 1];
        System.assertEquals('Unsupported CDM software version', objClstr.CDM_End_of_Support_Status__c);
    }
}