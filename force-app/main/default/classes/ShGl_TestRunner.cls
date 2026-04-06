// Global class used to schedule test runs
global class ShGl_TestRunner implements Schedulable {

    public static void setup(String cronTestRunner, String cronTestRunnerResult) {
        try {
            system.schedule('TestRunner', cronTestRunner, new ShGl_TestRunner());
            system.schedule('TestRunnerResults', cronTestRunnerResult, new ShGl_TestRunnerResults());
        } catch (Asyncexception ex) {
            system.debug('Job already scheduled');
        }
    }


    global void execute(SchedulableContext SC) {
        enqueueTests();
    }

    // Enqueue all unit test classes as spec'd by Automated_Test_Run__c record(s)
    public static list<ID> enqueueTests() {
        list<Id> jobIds = new list<Id>();

        for (ShGl_AutomatedTestRun__c run : [select ShGl_Query__c,
                                             ShGl_ExcludedManagedPackages__c ,
                                             ShGl_EmailOnPass__c,
                                             ShGl_ExcludedClasses__c

                                             from ShGl_AutomatedTestRun__c where ShGl_Active__c = true]) {
            string whereExcluded = '';
            if (run.ShGl_ExcludedClasses__c != null) {
                for (string c : run.ShGl_ExcludedClasses__c.split('[,\\s]+')) {
                    whereExcluded += 'and Name != \'' + c + '\'';
                }
            }
            if (run.ShGl_ExcludedManagedPackages__c == True) {
                whereExcluded += ' AND NameSpacePrefix = null';
            }

            string query = 'SELECT Id, LastModifiedById FROM ApexClass WHERE Name LIKE \'' + run.ShGl_Query__c + '\' ' + whereExcluded;
            ApexClass[] testClasses = Database.query(query);

            if (testClasses.size() > 0) {
                ApexTestQueueItem[] queueItems = new List<ApexTestQueueItem>();
                for (ApexClass cls : testClasses) {
                    queueItems.add(new ApexTestQueueItem(ApexClassId = cls.Id));
                }

                if (!Test.isRunningTest()) {
                    insert queueItems;

                    // Get the job ID of the first queue item returned.
                    ApexTestQueueItem item =
                        [SELECT ParentJobId FROM ApexTestQueueItem
                         WHERE Id = :queueItems[0].Id LIMIT 1];

                    insert new ShGl_TestRunnerJob__c (Name = item.parentjobid, ShGl_AutomatedTestRuns__c  = run.Id);

                    jobIds.add(item.parentjobid);
                }
            }
        }

        return jobIds;
    }

    public static list<Messaging.SingleEmailMessage> emailMethodStatus(list<ShGl_TestRunnerJob__c> jobs) {
        set<string> jobNames = new set<string>();
        for (ShGl_TestRunnerJob__c  job : jobs) {
            jobNames.add(job.Name);
        }

        ApexTestResult[] results =
            [SELECT Id, AsyncApexJobId, Outcome, ApexClass.Name, MethodName,
             ApexClass.LastModifiedById, ApexClass.LastModifiedBy.Name, Message, StackTrace
             FROM ApexTestResult
             WHERE AsyncApexJobId in :jobNames];



        return emailMethodStatus(jobs, results);

    }

    public static list<Messaging.SingleEmailMessage> emailMethodStatus(list<ShGl_TestRunnerJob__c > jobs, ApexTestResult[] results) {
        list<Messaging.SingleEmailMessage> messages = new list<Messaging.SingleEmailMessage>();

        for (ShGl_TestRunnerJob__c  job : jobs) {
            system.debug('Test Runner Job: Id ' + job.Id + ' Name ' + job.Name);
            integer passed = 0;
            integer total = 0;

            string failTable = '<table border="1" cellpadding="5px">';
            string className = '';
            string classId = '';

            for (ApexTestResult atr : results) {
                system.debug('Apex Test Result: Id'  + atr.AsyncApexJobId);
                if ((string)atr.AsyncApexJobId == job.Name || (Test.isRunningTest() && jobs.size() == 1)) {
                    if (atr.Outcome == 'Pass') {
                        passed++;
                    } else {
                        if (atr.ApexClass.Name != className) {
                            className = atr.ApexClass.Name;
                            classId = atr.ApexClass.Id;
                            String classUrl = URL.getSalesforceBaseUrl().getProtocol() + '://' +  System.URL.getSalesforceBaseUrl().getHost() + '/' + classId;

                            failTable += '<tr style="background: #ddd; font-weight: bold;"><td colspan="2">' + className
                                         + ' LastModifiedBy:' + atr.ApexClass.LastModifiedBy.Name + ' Link: ' + classUrl +  '</td></tr>\n';
                        }
                        failTable += '<tr><td>' + atr.MethodName + '</td><td> ' + atr.message + '</td></tr>\n';

                        failTable += '<tr><td>Stack Trace</td><td> ' + atr.stacktrace + '</td></tr>\n';
                    }
                    total++;
                }
            }

            failTable += '</table>';

            string body = '<p>' + passed + '/' + total + ' tests passed</p>\n';
            boolean allPassed = passed == total;

            if (!allPassed) {
                body += '<p>Test Failures:</p>\n' + failTable;
            }

            PageReference pdf = Page.ShGl_ApexCodeCoverageExport;
            pdf.setRedirect(true);

            Blob b = null;
            if (!Test.isRunningTest()) {
                b =  pdf.getContent();

            }

            if ((allPassed && job.ShGl_AutomatedTestRuns__r.ShGl_EmailOnPass__c) || !allPassed) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                if (!Test.isRunningTest())  {
                    efa.setFileName('ClassCoverageReport.pdf');
                    efa.setBody(b);
                }
                String orgName = UserInfo.getUserName().substringAfterLast('.');
                mail.setToAddresses(job.ShGl_AutomatedTestRuns__r.ShGl_Emails__c.split('[,\\s]+'));
                mail.setSubject('[' + orgName.toUpperCase() + '] ' + job.ShGl_AutomatedTestRuns__r.Name + ' Automated Test Results: ' + (passed < total ? 'Fail' : 'Pass'));
                mail.setHtmlBody(body);
                if (!Test.isRunningTest()) mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
                System.debug(mail);
                messages.add(mail);


            }
        }

        if (!Test.isRunningTest()) {
            Messaging.sendEmail(messages);
        }

        return messages;
    }



}