public class PC_PartnerMonthlyScheduler implements Schedulable {
    public void execute(SchedulableContext sc){
		/*Chain all monthly batches in PC_UpdatePartnerValuesOnContactBatch*/
		Database.executeBatch(new PC_UpdatePartnerValuesOnContactBatch());
    }
}