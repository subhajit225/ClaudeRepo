global class PostSubscribtionScheduler implements Schedulable {
   global void execute(SchedulableContext sc) {
      PostSubscriptionBatch b = new PostSubscriptionBatch(); 
      Database.executeBatch(b);
   }

}