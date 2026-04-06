global class ClusterBatchSchedular implements Schedulable {
   global void execute(SchedulableContext sc) {
      Account_ClusterCapacityBatch b = new Account_ClusterCapacityBatch(); 
      database.executebatch(b,200);
   }
}