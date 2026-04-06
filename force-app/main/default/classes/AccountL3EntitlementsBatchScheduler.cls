global class AccountL3EntitlementsBatchScheduler implements Schedulable {
   global void execute(SchedulableContext sc) {
      AccountL3EntitlementsBatch b = new AccountL3EntitlementsBatch(); 
      database.executebatch(b);
   }
}