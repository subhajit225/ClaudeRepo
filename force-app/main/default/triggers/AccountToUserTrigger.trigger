trigger AccountToUserTrigger on Account_To_Users__c (before insert, before update, before delete) {
    ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
    if(!disabled.Disable_AccountToUser_Triggers__c){
        new AccountToUserTriggerHandler().run(); 
    }
}