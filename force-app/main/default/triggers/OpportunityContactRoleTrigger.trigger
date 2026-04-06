trigger OpportunityContactRoleTrigger on OpportunityContactRole ( after insert, after update,before insert, before update, after delete,before delete) {
    if(!ShGl_DisableBusinessLogic__c.getInstance().Disable_Contact_Role_Triggers__c){ // added as part of SAL26-371
       TriggerManager.invokeHandler(new OpportunityContactRoleHandler());
    }
}