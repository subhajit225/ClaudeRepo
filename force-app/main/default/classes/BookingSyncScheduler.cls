/*******************************************************************************************************************
* @description       : scheduler run BookingSyncBatch
* @author            : Shrutika
* @last modified on  : 0-22-2025
* @last modified by  : Shrutika
*********************************************************************/
public without sharing class BookingSyncScheduler implements Schedulable {
    
    public boolean abortJob = false;
	

   //Execue method
  /**
   * @description execute method
   * @param sc
   */
   public void execute(SchedulableContext sc) {
   	BookingSyncBatch scbat = new BookingSyncBatch(Date.Today());
    string jobID = Database.executeBatch(scbat, 200);
    if(abortJob)
    	System.abortJob(sc.getTriggerId()); 
   }
}