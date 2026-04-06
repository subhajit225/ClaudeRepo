/**
* @Description        : This is the Scheduler Class for UpdatePrimaryQuotesBatch
* @Author             : Shivani
* Ver       Date            Author                 Modification
* 1.0      06-20-2022       Shivani               Intial Draft
**/ 
global class UpdatePrimaryQuotesBatchScheduler implements Schedulable {
    global void execute(SchedulableContext SC) {
        Database.executeBatch(new UpdatePrimaryQuotesBatch(), 10);
    }
}