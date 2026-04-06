public class PC_PartnerDailyScheduler implements Schedulable {
    public void execute(SchedulableContext sc){
        /*Chain all daily batches in PartnerAccAccrdtionCalcBatch*/
		Database.executeBatch(new PartnerAccAccrdtionCalcBatch());
    }
}