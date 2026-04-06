global class OpportunityRenewalStatusBatchSchedular implements Schedulable {
   global void execute(SchedulableContext sc) {
      OpportunityRenewalStatusBatch b = new OpportunityRenewalStatusBatch(); 
      database.executebatch(b,10);
   }
}