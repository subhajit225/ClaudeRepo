/**
** @Last modified by : Akashdeep Singh
* @Description : Send an email notification to case owner when a new attachment gets added to the case by someone other than case owner
* @Tickect no. : CS-397
**/

trigger ContentDocumentLinkTrigger on ContentDocumentLink (before insert,after insert, after delete, before delete) {
    if(TriggerControl__c.getAll() != null && TriggerControl__c.getAll().containsKey('ContentDocumentLink') && !TriggerControl__c.getInstance('ContentDocumentLink').DisableTrigger__c && !ContentDocumentLinkTriggerHandler.CDLTriggerRecurssion){
        ContentDocumentLinkTriggerHandler cdl = new ContentDocumentLinkTriggerHandler();
        if(Trigger.isBefore && Trigger.isInsert){
            cdl.beforeInsert(trigger.new);
        }
        if(Trigger.isAfter && Trigger.isInsert){
            cdl.afterInsert(trigger.new);
        }
        if(Trigger.isAfter && Trigger.isDelete){
            cdl.afterDelete(trigger.old);
        }
        
         if(Trigger.isBefore && Trigger.isDelete){
            cdl.beforeDelete(trigger.old);
        }
    }  
}