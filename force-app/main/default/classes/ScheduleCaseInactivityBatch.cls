/*
Author:Akashdeep Singh
Date: 21 September 2020
Ticket No:  CS21-272 
Description :Scheduler for class CaseInactivityBatch
*/

global class ScheduleCaseInactivityBatch  implements Schedulable{
    
    global void execute(SchedulableContext SC) {
      Database.executeBatch(new CaseInactivityBatch(), 200);
   }

}