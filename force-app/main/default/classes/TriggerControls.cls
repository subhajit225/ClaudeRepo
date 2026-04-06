/*
 * Class Name :- TriggerControls
 * Author :- Palak
 * Created Date :- 07-13-2022
 * Description : Bypass and Enable/Disbale Flags for CPQ Triggers and subsequent functionalities
 * 
 // ********************Change Logs *****************************************************************************
 * 
 * Change Request            Modified By          Date           Description 
 *                                              12-16-2022       Prevent recursive calling of CallCalculateAPIBatch
 * 
 * 
 // ********************Change Logs Ends*************************************************************************
*/
public class  TriggerControls {
    public static boolean disableQuoteTrigger=false;
    public static boolean disableQuoteLineTrigger = false;

    public static boolean disableCalculateAPIBatch = false;    //Created to stop recursive calling of CallCalculateAPIBatch in QuoteTriggerHelper
    public static boolean disableCCLITrigger = false; // Disable Trigger for Consolidated Contract Line Item
 
   @InvocableMethod
    public static void disableCPQTriggers() {
       SBQQ.TriggerControl.disable();
       TriggerControls.disableQuoteTrigger = true;
       TriggerControls.disableQuoteLineTrigger = true;
   }
}