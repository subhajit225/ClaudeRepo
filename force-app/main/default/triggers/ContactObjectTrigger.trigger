trigger ContactObjectTrigger on Contact (before insert, before update, after insert, after update, after delete) {
    set<id> AcountIds=new set<id>();
    ShGl_DisableBusinessLogic__c csDisableBusinessLogic = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId());    
    if(!csDisableBusinessLogic.Disable_Contact_Triggers__c && flowControll.contactTrigger){
        TriggerManager.invokeHandlerWithoutException(new ContactObjectTriggerHandler());
    }
   if(Trigger.isAfter && Trigger.isinsert) 
   {
        for(Contact eachContact: trigger.new){
if(eachContact.Agreed_to_POC_terms__c==True)
                    AcountIds.add(eachContact.AccountId);
            if(AcountIds.size()>0)
          ContactTriggerHelper.getUpdatedContactRecord(AcountIds);  
 
        }
   }
    if(trigger.isbefore && trigger.isUpdate){
        for(Contact eachContact: trigger.new){
            if((eachContact.Agreed_to_POC_terms__c != trigger.oldmap.get(eachContact.id).Agreed_to_POC_terms__c) && (eachContact.Agreed_to_POC_terms__c==True))
                AcountIds.add(eachContact.AccountId);
        } 
        if(AcountIds.size()>0)
          ContactTriggerHelper.getUpdatedContactRecord(AcountIds);  
    }
    
    // CS21-1403 Start--
    if(trigger.isAfter && trigger.isUpdate){
        ContactTriggerHelper.afterUpdate(trigger.newMap, trigger.oldMap);
        // CS21-3111 
        ContactTriggerHelper.updateUserRelease(trigger.newMap, trigger.oldMap);
    }
    // CS21-1403 End--
}