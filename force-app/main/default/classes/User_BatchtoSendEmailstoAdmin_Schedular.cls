global class User_BatchtoSendEmailstoAdmin_Schedular implements Schedulable {
   global void execute(SchedulableContext sc) {
      User_BatchtoSendEmailstoAdmin b = new User_BatchtoSendEmailstoAdmin(); 
      database.executebatch(b,200);
   }
}