@isTest
public class BookingAuditTriggerTest{	
    static testmethod void TestPreventDelEditOnBookingAudit()
    {
        Booking_Audit__c adtRecord = new Booking_Audit__c(Booking_Field__c='Field_Update_Status__c',
                                                        New_Value__c='Core Attributes - Frozen');
        insert adtRecord;
        
        try{
            delete adtRecord;
        }catch(DMLexception e){
            system.assert(e.getMessage().contains('Cannot Delete Booking Audit entry'),'Cannot Delete Booking Audit entry');                       
        }
        try{
            adtRecord.New_Value__c='Freeze Completed';
            update adtRecord;
        }catch(DMLexception e){
            system.assert(e.getMessage().contains('Cannot update Booking Audit entry'),'Cannot update Booking Audit entry');                       
        }
    }
    static testmethod void TestTriggerControlCase()
    {
        TriggerControl__c tc=new TriggerControl__c();
        tc.DisableTrigger__c=TRUE;
        tc.Name='BookingAudit';
        insert tc;
        Booking_Audit__c adtRecord = new Booking_Audit__c(Booking_Field__c='Field_Update_Status__c',
                                                        New_Value__c='Core Attributes - Frozen');
        insert adtRecord;
        
        delete adtRecord;
    }
    
}