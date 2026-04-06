trigger ScaleEntitlementTrigger on Scale_Entitlement__c (before insert,after insert) {
    
    if(Trigger.isAfter && Trigger.isInsert){
        ScaleEntitlementTriggerHelper.getQueryResult();
        ScaleEntitlementTriggerHelper.AfterInsert();  
    } 
}