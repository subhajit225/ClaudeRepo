global with sharing class SplitOrderScheduler implements Schedulable {
    global void execute(SchedulableContext SC) {
        SplitOrder scbat = new SplitOrder();
        string jobID =Database.executeBatch(scbat,1);
        
        //JobId = system.schedule('Split EDI Orders', cronExp, new SplitOrderScheduler());
    }
   
}