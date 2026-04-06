global class ScheduleBookingBatch implements Schedulable {

	public static void setup() {
	try {

	System.schedule('Booking Batchs at every hour @ 00 min.', '0 0 * * * ? *' , new ScheduleBookingBatch()); //Every  0 min per hour.
	System.schedule('Booking Batchs at every hour @ 30 min.', '0 30 * * * ? *', new ScheduleBookingBatch()); //Every 30 min per hour.
	} catch (Asyncexception ex) {
	system.debug('Job already scheduled');
	}
	} 
	

	global void execute(SchedulableContext sc) {
		Date currentDate = System.today();
		Datetime currentDateTime = System.now();
		Date lastDayOfMonth = ((currentDate.addMonths(1)).toStartOfMonth()).addDays(-1);
		Integer noOfDaysBetween = currentDate.daysBetween(lastDayOfMonth);
		Integer currentHour = currentDateTime.hour();
		Integer currentMonth = currentDateTime.month();
		Integer currentMin = currentDateTime.minute();
		Order_control__mdt disableBookingScheduler = Order_control__mdt.getInstance('Disable_Old_Booking_Scheduler');
		if(disableBookingScheduler?.Value__c != null  && !boolean.valueOf(disableBookingScheduler?.Value__c)){
		BookingBatch bb=new BookingBatch();
		database.executeBatch(bb);//Batch#1
		}
		if((noOfDaysBetween < 4 && (currentMonth == 4 || currentMonth == 7 || currentMonth == 10 || currentMonth == 1 )) || ((currentHour == 0 || currentHour == 12) && currentMin < 30) ){
			BookingSyncBatch bsb=new BookingSyncBatch(Date.Today());
			database.executeBatch(bsb);//Batch#2
		}else{
			System.debug('Batch is not required at this time.');
		}
	}

}