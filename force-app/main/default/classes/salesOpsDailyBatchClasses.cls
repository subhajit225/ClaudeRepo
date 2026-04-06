//created as a part of SFDCSOX-215
global with sharing class salesOpsDailyBatchClasses implements Schedulable{
    global void execute(SchedulableContext sc){
        try{
            updateProductTypeOLIBatch ptypebatch = new updateProductTypeOLIBatch();
            Database.executeBatch(ptypebatch,100);  }catch(Exception e){
            system.debug(LoggingLevel.DEBUG,'@@ Exception occured updateProductTypeOLIBatch '+e.getMessage());
        } 
        try{
            RenewalOppClosedAdminBatch roppclosedAdmin = new RenewalOppClosedAdminBatch();
            Database.executeBatch(roppclosedAdmin,50); }catch(Exception e){
            system.debug(LoggingLevel.DEBUG,'@@ Exception occured RenewalOppClosedAdminBatch '+e.getMessage());
        }
        try{
            SDRLedBatchController sdrbatch = new SDRLedBatchController();
            Database.executeBatch(sdrbatch,50);}catch(Exception e){
            system.debug(LoggingLevel.DEBUG,'@@ Exception occured SDRLedBatchController '+e.getMessage());
        }
        try{
            Database.executeBatch(new AccountUpdateTypeStatusBatch(null));}catch(Exception e){
            system.debug(LoggingLevel.DEBUG,'@@ Exception occured AccountUpdateTypeStatusBatch '+e.getMessage());
        }
        //SAL25-939 PQL Reminder Email Batch
        try{
            PQLOpptyReminder pqlOpptyReminderBatch = new PQLOpptyReminder();
            Database.executeBatch(pqlOpptyReminderBatch,50);}catch(Exception e){
            system.debug(LoggingLevel.DEBUG,'@@ Exception occured pqlOpptyReminderBatch '+e.getMessage());
        }

        //SAL26-73
        try{
            OpportunityOwnerAssignmentBatch otmAssignment = new OpportunityOwnerAssignmentBatch();
            Database.executeBatch(otmAssignment, 50);}catch(Exception e){
            system.debug(LoggingLevel.DEBUG, '@@ Exception occured otmAssignment '+e.getMessage());
        }
        //SAL26-313
        try{
            Database.executeBatch(new AccountSharedCustomerUpdateBatch());}catch(Exception e){
            system.debug(LoggingLevel.DEBUG,'@@ Exception occured AccountSharedCustomerUpdateBatch '+e.getMessage());
        }
    }
    
}