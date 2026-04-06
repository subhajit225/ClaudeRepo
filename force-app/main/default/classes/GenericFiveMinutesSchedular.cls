global class GenericFiveMinutesSchedular implements Schedulable {
   global void execute(SchedulableContext sc) {
        //JIRA Scheduled Job - Needs execution every 5 minutes
        JIRAFieldUpdateBatch b = new JIRAFieldUpdateBatch(); 
        database.executebatch(b,2000);

   }
}