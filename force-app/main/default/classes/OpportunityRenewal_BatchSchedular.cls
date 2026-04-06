global class OpportunityRenewal_BatchSchedular implements Schedulable {
   global void execute(SchedulableContext sc) {
      Opportunity_Renewal_Batch b = new Opportunity_Renewal_Batch(); 
      database.executebatch(b,20);
   }
}