trigger PC_PartnerRegistrationRequestTrigger on Partner_Registration_Request__c (before insert, after insert, before update, after update) {
    if(!ShGl_DisableBusinessLogic__c.getInstance().Disable_PartnerRegRequest_Triggers__c){
        TriggerManager.invokeHandler(new PC_PartnerRegistrationRequestHandler());
    }
}