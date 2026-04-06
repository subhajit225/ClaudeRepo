/***************************************************************************** 
* @description       : This is a handler class for Booking Line Item trigger
* @author            : Prashik
* @last modified on  : 10-06-2025
* @last modified by  : Prashik
* Modifications Log
* Ver   Date          Author               Modification
* 1.0   10-06-2025    Prashik              Initial Version/PRDOPS26-982
******************************************************************************/
public with sharing class BookingLineItemHandler extends TriggerHandler {
  /**
  * @description This method handler before insert context
  */
  public override void beforeUpdate() {
    if(TriggerControl__c.getInstance('Booking') != null && TriggerControl__c.getInstance('Booking').DisableTrigger__c) {
        return;
    }
    BookingLineItemHelper.validateBookingUpdatePermissions((Map<Id,Booking_Line_Item__c>) Trigger.newMap,(Map<Id,Booking_Line_Item__c>) Trigger.oldMap);
  }


}