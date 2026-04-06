trigger BookingTrigger on Booking__c (before insert,before update, after update) {
    if(TriggerControl__c.getInstance('Booking') != null && TriggerControl__c.getInstance('Booking').DisableTrigger__c) {
        return;
    }
    if(trigger.isAfter)
    {
        if(trigger.isUpdate)
        {
            BookingHelper.TrackBookingChanges((List<Booking__c>)Trigger.New,(Map<Id,Booking__c>)Trigger.oldMap);
        }
    }
    if(trigger.isBefore)
    {
        if(trigger.isInsert)
        { 
            BookingHelper.updateBooking((List<Booking__c>)Trigger.New,null);
        }
        if(trigger.isUpdate)
        { 
            BookingHelper.updateBooking((List<Booking__c>)Trigger.New,(Map<Id,Booking__c>)Trigger.oldMap);
        }
    }
    
}