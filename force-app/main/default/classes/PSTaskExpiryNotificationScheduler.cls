global class PSTaskExpiryNotificationScheduler implements schedulable{ 
    
	
	
    global void execute(SchedulableContext sc){
        PSTaskExpiryNotificationBatch bch = new PSTaskExpiryNotificationBatch();
        integer batchCount = 5;
        if(Test.isRunningTest()){
            batchCount = 40;
        }
        database.executeBatch(bch,batchCount);
    }
    
}