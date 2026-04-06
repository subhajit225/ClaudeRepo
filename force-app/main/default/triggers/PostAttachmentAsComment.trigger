trigger PostAttachmentAsComment on Attachment (after insert) {
        //calling trigger handler
        if(!ShGl_DisableBusinessLogic__c.getInstance()?.Disable_Attachment_Trigger__c){
                AttachmentTriggerHandler.handleTrigger(trigger.new, trigger.old, trigger.newMap, trigger.oldMap, trigger.OperationType);
        }
}