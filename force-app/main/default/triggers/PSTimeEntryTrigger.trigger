trigger PSTimeEntryTrigger on PS_Time_Entry__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
    system.debug('TE curr User check ___ '+ UserInfo.getUserId());
    if(UserInfo.getUserId() == Label.DisableTriggerUser) return;
    system.debug('Trigger Started');
    
    ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
    
    new PSTimeEntryTriggerHandler().run();  
 
}