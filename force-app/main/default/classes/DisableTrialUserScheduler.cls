global class DisableTrialUserScheduler  implements Schedulable {
    
    public static String CRON_EXP = '0 0 0 * * ? *';

   global void execute(SchedulableContext SC) {
      Database.executeBatch(new DisableTrialUserBatch());
   }
}