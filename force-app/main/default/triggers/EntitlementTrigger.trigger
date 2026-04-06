trigger EntitlementTrigger on Entitlement (before insert, before update, before delete, after insert, after update, after delete) {
  if(!TriggerControl__c.getInstance('Entitlement').DisableTrigger__c  && !triggerControl.stopEntitlementTrigger){
      TriggerFactory.createHandler(Entitlement.sObjectType);
  }
}