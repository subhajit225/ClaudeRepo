/**
* @description  : Utility methods for test data setup, trigger/flow control,
*                  and unique data generation.
* @author       : kiran.kumar2@rubrik.com
* @usage        : Used across all test factories and Apex tests.
*/
public class CommonTestDataUtils {
   /**
    * @description Generates a unique string for test data naming.
    * @param prefix Prefix to prepend for identification.
    * @return Unique string constructed using prefix + timestamp + random integer.
    */
   public static String generateUniqueString(String prefix) {
       return prefix + '_' + System.now().getTime() + '_' + Math.abs(Crypto.getRandomInteger());
   }
   // -------------------------------------------------------------------------
   // :jigsaw: AUTOMATION CONTROL (Generic for Triggers, Flows, Validation Rules)
   // -------------------------------------------------------------------------
   /**
    * @description Enables or disables automation flags in the Custom Setting.
    * @param disableAll If true, disables all automation controls. If false, enables all.
    * @param category Optional filter to update specific automation types.
    *                 Accepted values: 'Trigger', 'Flow', 'Validation'.
    */
   public static void setAutomationFlags(Boolean disableAll, String category) {
       String csName = 'ShGl_DisableBusinessLogic__c'; // Replace with actual setting
     
           Schema.DescribeSObjectResult dsr =
               Schema.getGlobalDescribe().get(csName).getDescribe();
           List<SObject> settings =
               Database.query('SELECT Id FROM ' + csName + ' LIMIT 1');
           SObject csRecord;
           if (!settings.isEmpty()) {
               csRecord = settings[0];
           } else {
               csRecord = dsr.getSObjectType().newSObject();
           }
           Map<String, Schema.SObjectField> fieldMap = dsr.fields.getMap();
           for (String fieldName : fieldMap.keySet()) {
               if (fieldName.startsWithIgnoreCase('Disable_')) {
                   if (String.isNotBlank(category)
&& !fieldName.toLowerCase().contains(category.toLowerCase())) {
                       continue;
                   }
                   Schema.DescribeFieldResult fdesc =
                       fieldMap.get(fieldName).getDescribe();
                   if (fdesc.getType() == Schema.DisplayType.Boolean) {
                       csRecord.put(fieldName, disableAll);
                   }
               }
           }
           if (csRecord.Id != null) {
               update csRecord;
           } else {
               insert csRecord;
           }
   }
   // -------------------------------------------------------------------------
   // :wrench: OTHER UTILITIES
   // -------------------------------------------------------------------------
   /**
    * @description Gets a future business day by skipping Saturdays and Sundays.
    * @param addDays Number of business days to add.
    * @return DateTime representing the future business day.
    */
   public static DateTime getFutureBusinessDate(Integer addDays) {
       DateTime dt = System.now();
       Integer added = 0;
       while (added < addDays) {
           dt = dt.addDays(1);
           String day = dt.format('E');
           if (day != 'Sat' && day != 'Sun') {
               added++;
           }
       }
       return dt;
   }
   /**
    *@description Asserts whether execution time is within expected threshold.
    * @param startTime Time captured before execution started.
    * @param thresholdMs Allowed threshold in milliseconds.
    */
   public static void assertPerformance(Long startTime, Long thresholdMs) {
       Long elapsed = System.now().getTime() - startTime;
       System.assert(
           elapsed < thresholdMs,
           ':warning: Performance issue: Took ' + elapsed + 'ms'
       );
   }
}