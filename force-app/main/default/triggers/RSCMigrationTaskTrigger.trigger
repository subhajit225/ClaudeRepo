/** 
* @Author      : Raveesh Layal
* @CreatedDate : 5th October 2023
* @Description : Updates the repective RSC Migration Task records and related records.
* @TstClass    : RSCMigrationTaskHandlerTest
* @Jira		   : CS21-1939 

* -------------------------- @History --------------------------------------------------------------------------------------------
* Story Number       Modified By              Date           Description
* CS21-1939        		           
* --------------------------------------------------------------------------------------------------------------------------------
*/

trigger RSCMigrationTaskTrigger on RSC_Migration_Tasks__c (before insert,before update, after insert, after update, after delete) {
    if((Trigger.isInsert || Trigger.isUpdate) && trigger.isbefore)
    {
        RSCMigrationTaskHandler.UpdateClusterId(trigger.new,trigger.oldmap);
    }
    if((Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete) && Trigger.isAfter){
        RSCMigrationTaskHandler.updateTotalCountOnCluster(trigger.new,trigger.oldmap);
        
    }
    
}