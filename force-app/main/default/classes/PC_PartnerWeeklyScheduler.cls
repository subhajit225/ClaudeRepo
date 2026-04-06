public class PC_PartnerWeeklyScheduler implements Schedulable{
	public void execute(SchedulableContext sc){
		/*Chain all weekly batches in PC_MDF_RequestRemiderMailBatch*/
		Database.executeBatch(new PC_MDF_RequestRemiderMailBatch());
        
        /*PRIT25-552 MIP Account Contribution Batch Job Weekly Run*/
        Database.executeBatch(new MIPSyncBatch(null));
    }
}