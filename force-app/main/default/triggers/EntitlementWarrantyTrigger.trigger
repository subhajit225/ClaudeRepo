trigger EntitlementWarrantyTrigger on Entitlement_Warranty_Details__c (before delete) {
    /* comment*/
    for(Entitlement_Warranty_Details__c rec : trigger.old){
        rec.adderror('Record cannot be deleted');
    }


}