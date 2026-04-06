global class ScheduleBookingSyncBatch implements Schedulable {

  public static void setup() {
        try {
            system.schedule('ScheduleBookingSyncBatch-Quarter1', '0 0 0/12 * 2,3,5,6,8,9,11,12 ? *', new ScheduleBookingSyncBatch());
            system.schedule('ScheduleBookingSyncBatch-Quarter2', '0 0 0/12 1-26 4 ? *', new ScheduleBookingSyncBatch());
            system.schedule('ScheduleBookingSyncBatch-Quarter3', '0 0 0/12 1-27 7,10,1 ? *', new ScheduleBookingSyncBatch());
            system.schedule('ScheduleBookingSyncBatch-QuarterEnd1', '0 0 * 27-30 4 ? *', new ScheduleBookingSyncBatch());
            system.schedule('ScheduleBookingSyncBatch-QuarterEnd2', '0 30 * 27-30 4 ? *', new ScheduleBookingSyncBatch());
            system.schedule('ScheduleBookingSyncBatch-QuarterEnd3', '0 0 * 28-31 7,10,1 ? *', new ScheduleBookingSyncBatch());
            system.schedule('ScheduleBookingSyncBatch-QuarterEnd4', '0 30 * 28-31 7,10,1 ? *', new ScheduleBookingSyncBatch());

        } catch (Asyncexception ex) {
            system.debug('Job already scheduled');
        }
    }
   global void execute(SchedulableContext sc) {
     BookingSyncBatch bsb=new BookingSyncBatch(Date.Today());
     database.executeBatch(bsb);
   }
}