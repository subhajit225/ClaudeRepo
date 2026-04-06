global class UserTenureBatchSchedular implements Schedulable {
   global void execute(SchedulableContext sc) {
      User_Tenure_Batch_simplified b = new User_Tenure_Batch_simplified(); 
      database.executebatch(b,20);
   }
}