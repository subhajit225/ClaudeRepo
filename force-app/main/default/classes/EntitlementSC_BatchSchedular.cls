global class EntitlementSC_BatchSchedular implements Schedulable {
   global void execute(SchedulableContext sc) {
      Entititlement_To_ServiceContract_Batch b = new Entititlement_To_ServiceContract_Batch(); 
      database.executebatch(b,1);
   }
}