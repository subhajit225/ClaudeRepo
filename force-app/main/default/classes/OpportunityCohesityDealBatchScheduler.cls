global class OpportunityCohesityDealBatchScheduler implements Schedulable{
    
    global void execute(System.SchedulableContext sc){
        OpportunityCohesityDealBatch b = new OpportunityCohesityDealBatch(); 
        database.executeBatch(b);
    }
}