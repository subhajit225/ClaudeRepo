//Universal Batch Scheduler (introduced with SWD batch splitting)
global class BatchScheduler implements Schedulable {
    global Database.Batchable<SObject> batchClass {get; set;}
    global Integer batchSize {get; set;} {batchSize = 200;}

    global void execute(SchedulableContext sc) {
        database.executebatch(batchClass, batchSize);
    }
}