global class JIRAFieldUpdateBatch_Schedular implements Schedulable {
   global void execute(SchedulableContext sc) {
      JIRAFieldUpdateBatch b = new JIRAFieldUpdateBatch(); 
      database.executebatch(b,2000);
   }
}