// Test Runner Tests
@isTest
private class ShGl_TestRunner_Tests {
    static ShGl_AutomatedTestRun__c run;
    static ShGl_TestRunnerJob__c job;
    static list<Messaging.SingleEmailMessage> messages;
    static Messaging.SingleEmailMessage mail;

    static {
        run = new ShGl_AutomatedTestRun__c( ShGl_Active__c = true,
                                            Name = 'Test Automated Run',
                                            ShGl_ExcludedClasses__c = 'ShGl_TestRunner, Foo',
                                            ShGl_EmailOnPass__c = true,
                                            ShGl_Emails__c = 'test@test.com');
        insert run;

        System.debug(LoggingLevel.ERROR, 'DEBUG 1 Test Class Run ' + run);

        job = new ShGl_TestRunnerJob__c(Name = 'Test Automated Run:', ShGl_AutomatedTestRuns__c = run.Id, ShGl_Processed__c = false);
        insert job;

        System.debug(LoggingLevel.ERROR, 'DEBUG 2 Test Class Job:' + job);

        runJobs();
    }

    static void runJobs() {
        messages = ShGl_TestRunnerResults.emailUnprocessedJobStatus();

        System.debug(LoggingLevel.ERROR, 'DEBUG 3 runJobs:' + messages);

        mail = messages.size() > 0 ? messages[0] : null;
    }

    public static testMethod void enqueueTestsCreatesJobs() {
        System.assertEquals(0, ShGl_TestRunner.enqueueTests().size(), 'Tests should not be queued during a test');
    }

    public static testMethod void emailCreatedForAllPassing() {

        System.debug(LoggingLevel.ERROR, 'DEBUG: emailCreatedForAllPassing' + mail);

        System.assert(mail.getSubject().contains(run.Name), 'Run name not in subject');

        set<string> emails = new set<string>();
        emails.addAll(mail.getToAddresses());
        System.assert(emails.contains(run.ShGl_Emails__c), 'Run emails not in mail');

        System.assert(!mail.getHtmlBody().contains('Test Failures'), 'Failures appear for passing tests');
    }

    public static testMethod void emailCreatedForFailures() {
        list<ApexTestResult> results = new list<ApexTestResult>();
        ApexTestResult result = new ApexTestResult(Outcome = 'Fail', ApexClass = [select Id, Name, ApexClass.LastModifiedBy.Name from ApexClass limit 1], MethodName = 'TestMethod', Message  = 'Test Message', StackTrace = 'Test Stack Trace');
        results.add(result);

        list<ShGl_TestRunnerJob__c> jobs = [Select t.Name,
                                            t.ShGl_AutomatedTestRuns__r.ShGl_Emails__c,
                                            t.ShGl_AutomatedTestRuns__r.ShGl_EmailOnPass__c,
                                            t.ShGl_AutomatedTestRuns__r.Name,
                                            t.ShGl_AutomatedTestRuns__c
                                            From ShGl_TestRunnerJob__c t where t.Id = :job.Id];
        mail = ShGl_TestRunner.emailMethodStatus(jobs, results)[0];

        System.assert(mail.getHtmlBody().contains(result.Message), 'No message for failures');
    }

    public static testMethod void emailOnPassUnchecked() {
        run.ShGl_EmailOnPass__c = false;
        update run;

        job = job.clone();
        insert job;

        runJobs();

        System.assertEquals(null, mail, 'Email created when Email on Pass unchecked');
    }

    public static testMethod void testRunnerResultsProcessesJobs() {
        job = [select ShGl_Processed__c from ShGl_TestRunnerJob__c where Id = :job.Id];
        System.assert(job.ShGl_Processed__c, 'Job not marked processed');
    }
}