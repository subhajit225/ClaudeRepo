global with sharing class OppAcvUpdateBatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc){
        OppAcvUpdateBatch batch = new OppAcvUpdateBatch();
        batch.isSalesCompCategoryBatch = true;
        Database.executeBatch(batch, 1);
    }
}