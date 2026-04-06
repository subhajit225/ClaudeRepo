trigger BookingLineItemMain on Booking_Line_Item__c (
  before insert,
  after insert,
  after update,
  before update
) { 
    BookingLineItemHandler handler = new BookingLineItemHandler();
    handler.execute();
}