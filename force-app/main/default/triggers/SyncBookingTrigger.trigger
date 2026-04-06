/***************************************************************************** 
* @description       : This is a Platform Event that triggers the Booking Sync
* @author            : 
* @last modified on  : 10-06-2025
* @last modified by  : Shrutika Kesarkar
* Modifications Log
* Ver   Date          Author               Modification
* 1.0   10-06-2025    Shrutika Kesarkar    Initial Version
******************************************************************************/
trigger SyncBookingTrigger on Sync_Booking__e (after insert) {
    SyncBookingHelper.executeSyncBookingScheduler();  
}