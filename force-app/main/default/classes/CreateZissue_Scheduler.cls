//Scheduler for Apex Class CreateZissue_SFFArticle_CaseScheduler
global  class CreateZissue_Scheduler implements Schedulable {
   global void execute(SchedulableContext sc) {
      System.enqueueJob(new CreateZissue_SFFArticle_CaseScheduler());
   }
}