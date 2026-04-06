trigger PS_ProjectTrigger on PS_Project__c (after insert,after update,before insert,before update) {
    if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate)){
        PS_ProjectTriggerHandler.updateCSATonSubtask(trigger.new,trigger.oldMap);
        PS_ProjectTriggerHandler.updatePSProjectFlagOnAccount(trigger.new,trigger.oldMap); 

    }
    
        //MKT22-378 PS Project name Change //
    if(Trigger.isBefore){
        if(Trigger.isInsert) {
            PS_ProjectTriggerHandler.validatePSProjectName(Trigger.new, Trigger.oldMap);
            PS_ProjectTriggerHandler.updateCommentDateTime(Trigger.new, Trigger.oldMap);
        }
        if(Trigger.isUpdate) {
            PS_ProjectTriggerHandler.validatePSProjectName(Trigger.new, Trigger.oldMap);
            PS_ProjectTriggerHandler.updateCommentDateTime(Trigger.new, Trigger.oldMap);
        }
        
          //MKT22-378 PS Project name Change End //
           //MKT22-378 PS name   End//
    }

    if(trigger.isAfter && trigger.isInsert){
        PS_ProjectTriggerHandler.createAsanaSFPsProjectPlatformEvent(trigger.new);
     }
}