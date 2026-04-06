trigger PartnerRelationTrigger on Partner_Relation__c (before insert, before update, before delete, after insert, after update, after delete) {
    if(!ShGl_DisableBusinessLogic__c.getInstance().Disable_Partner_Relation_Triggers__c){
        TriggerManager.invokeHandler(new PartnerRelationTriggerHandler());
    }
}