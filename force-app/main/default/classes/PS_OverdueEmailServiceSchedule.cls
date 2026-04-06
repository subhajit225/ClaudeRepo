global class PS_OverdueEmailServiceSchedule  implements Schedulable{
    global void execute(SchedulableContext SC){
        PS_OverdureEmailServiceBatch b = new PS_OverdureEmailServiceBatch();
		Database.executeBatch(b,75);
    }
}