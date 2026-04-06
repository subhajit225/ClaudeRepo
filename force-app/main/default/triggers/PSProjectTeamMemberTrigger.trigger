trigger PSProjectTeamMemberTrigger on PS_Project_Team_Member__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
    if(trigger.isbefore && trigger.isinsert){
        system.debug('I am in Before Insert');
        PSProjectTeamMemberTriggerHandler.beforeInsert(trigger.new);
    }
    if(trigger.isDelete){
    //PSProjectTeamMemberTriggerHandler.deletemthd(trigger.new); //added by grazitti
        if(trigger.isbefore){
            PSProjectTeamMemberTriggerHandler.deletemethod(trigger.old);
        }
        }
    new PSProjectTeamMemberTriggerHandler().run(); 
}