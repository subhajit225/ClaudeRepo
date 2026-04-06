trigger BookingAuditTrigger on Booking_Audit__c (before delete,before update) {
 	if(TriggerControl__c.getInstance('BookingAudit') != null && TriggerControl__c.getInstance('BookingAudit').DisableTrigger__c) {
        return;
    }
     if(Trigger.isBefore) 
     {
            if(trigger.isDelete){
                BookingAuditHelper.PreventDelOnBookingAudit((List<Booking_Audit__c>)trigger.old);
            }else if(trigger.isUpdate){
                BookingAuditHelper.PreventEditOnBookingAudit((List<Booking_Audit__c>)trigger.New);
            }
      }

}