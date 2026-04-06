global class SplitOrderSchedular implements Schedulable {
   public boolean abortJob = false;
   global void execute(SchedulableContext sc) {
         
        SplitOrder scbat = new SplitOrder();
        string jobID =Database.executeBatch(scbat,1);
        if(abortJob)
        	System.abortJob(sc.getTriggerId()); 
   }
}