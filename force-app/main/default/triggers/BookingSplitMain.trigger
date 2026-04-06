trigger BookingSplitMain on Booking_Split__c (
  before insert,
  after insert,
  after update,
  before update
) { 
    BookingSplitHandler handler = new BookingSplitHandler();
    handler.execute();
}