/***************************************************************************** 
* @description       : This is a Platform Event that triggers the Booking Sync
* @author            : 
* @last modified on  : 10-06-2025
* @last modified by  : Shrutika Kesarkar
* Modifications Log
* Ver   Date          Author               Modification
* 1.0   10-06-2025    Shrutika Kesarkar    Initial Version
******************************************************************************/
public class SyncBookingHelper {
    /**
     * @description executeSyncBookingScheduler
    **/
    public static void executeSyncBookingScheduler(){
        BookingSyncBatch.executeSyncBookingBatch();
    }

}