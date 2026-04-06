//Global class used to schedule test run results
global class ShGl_TestRunnerResults implements Schedulable {

    global void execute(SchedulableContext SC) {
        emailUnprocessedJobStatus();
    }

    public static list<Messaging.SingleEmailMessage> emailUnprocessedJobStatus() {
        list<ShGl_TestRunnerJob__c> jobs = getUnprocessedJobs();

        System.debug(LoggingLevel.ERROR, 'DEBUG emailUnprocessedJobStatus-jobs:' + System.json.SerializePretty(jobs));

        list<Messaging.SingleEmailMessage> messages = ShGl_TestRunner.emailMethodStatus(jobs);

        for (ShGl_TestRunnerJob__c job : jobs) {
            job.ShGl_Processed__c = true;
        }


        update jobs;

        return messages;
    }

    public static list<ShGl_TestRunnerJob__c> getUnprocessedJobs() {
        return [Select t.Name,
                t.ShGl_AutomatedTestRuns__r.ShGl_Emails__c,
                t.ShGl_AutomatedTestRuns__r.ShGl_EmailOnPass__c,
                t.ShGl_AutomatedTestRuns__r.Name,
                t.ShGl_AutomatedTestRuns__c
                From ShGl_TestRunnerJob__c t where ShGl_Processed__c = false];
    }

}