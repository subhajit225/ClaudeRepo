trigger FileSharingTrigger on File_Sharing__c (after insert,after update) {
    
    if(trigger.isAfter && (trigger.isUpdate || trigger.isInsert)){
        if(trigger.isUpdate){
            FileSharingTriggerHandler.deleteApexSharing(trigger.new);
        }   
        FileSharingTriggerHandler.invokeApexSharing(trigger.new); 
    }
}