//Controller for AutomatedTestSet page
public with sharing class ShGl_AutomatedTestSetupController {
    public boolean hasScheduledJobs { get; set; }
    public boolean hasTestRun { get; set; }
    public boolean isRunning { get; set; }
    public boolean isEmailing { get; set; }

    // Add Variables to allow Test Jobs to be scheduled via the UX
    public String cronStringResults { get; set ; }
    public String cronStringRunner { get; set; }

    public void refreshHasScheduledJobs() {
        integer jobCount = [select count() from CronJobDetail where Name like 'TestRunner%' and JobType = '7'];
        hasScheduledJobs = jobCount == 2;
    }

    public void refreshHasTestRun() {
        integer runCount = [select count() from ShGl_AutomatedTestRun__c limit 1];
        hasTestRun = runCount > 0;
    }

    public string getTestRunLink() {
        return '/' + ShGl_AutomatedTestRun__c.SObjectType.getDescribe().getKeyPrefix();
    }

    public ShGl_AutomatedTestSetupController() {
        refreshHasScheduledJobs();
        refreshHasTestRun();
        cronStringRunner = '0 30 0 1/1 * ? *'; // Default CRON for Test Job (12:30am)
        cronStringResults = '0 30 2 1/1 * ? *'; // Default CRON for Test Result Email (02:30am) - 2 hours later
    }

    public void scheduleJobs() {
        ShGl_TestRunner.setup(cronStringRunner, cronStringResults);
        refreshHasScheduledJobs();
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm, 'Jobs scheduled'));
    }

    public void createTestRun() {
        User currentUser = [select Email from User where Id = :UserInfo.getUserId()];
        insert new ShGl_AutomatedTestRun__c(Name = 'All Tests', ShGl_Emails__c = currentUser.Email);
        refreshHasTestRun();
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm, 'Automated Test Run created'));
    }

    public void run() {
        ShGl_TestRunner.enqueueTests();
        isRunning = true;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm, 'Tests queued'));
    }

    public void email() {
        ShGl_TestRunnerResults.emailUnprocessedJobStatus();
        isEmailing = true;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm, 'Results processed and emailed'));
    }

}