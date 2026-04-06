global class Opportunity_EOLProductBatchSchedular implements Schedulable {
	global void execute(SchedulableContext sc) {
		 database.executebatch(new Opportunity_EOLProductBatch(), 200);
	}
}