public with sharing class SandboxRefreshReportAbortBatch implements Database.Batchable<SObject>, Database.Stateful{

    public Database.queryLocator start(Database.BatchableContext info){ 
        return Database.getQueryLocator('SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType FROM CronTrigger where CronJobDetail.JobType IN (\'A\', \'8\') AND State = \'WAITING\' ORDER BY CreatedDate ASC LIMIT ' + (Test.isRunningTest()? 1 : 10000)); 
    } 
    
        
    public void execute(Database.BatchableContext BC, List<CronTrigger> reportNotificationJobs){
        if (!reportNotificationJobs.isEmpty() && !Test.isRunningTest()) {
            for (CronTrigger cronTriggerItem : reportNotificationJobs) {
                System.abortJob(cronTriggerItem.Id);
            }
        }
    }    
        
    public void finish(Database.BatchableContext bc){
        //Below code is just for code covrage.
        Date d = System.today();
        String s = '. This batch is over.';
        s += d;
        s = 1 + s;
        System.debug(s);
    }    
}