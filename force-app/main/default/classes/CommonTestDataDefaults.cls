/**
* @description  Utility class that stores and provides default field values for common SObjects
*               used in test data creation. This helps maintain consistency and reduces repeated
*               boilerplate code across test classes.
*
* @author       kiran.kumar2@rubrik.com
* @date         2025-11-27
* @version      1.1
*
* @group        Test Data Factory Framework
* @group-content
* This class acts as the central repository for default values used by test data factory classes.
* It supports:
*  - Fetching default values for an SObject type
*  - Merging or overriding defaults globally
*
* @modification-log
*  - Version 1.0: Initial version with static maps.
*  - Version 1.1: Added defaults for SBQQ__QuoteLine__c (Quote Line).
*/
public class CommonTestDataDefaults {
   // =====================================================
   // STATIC DEFAULT MAP INITIALIZATION
   // =====================================================
   /**
    * @description Stores default field-value maps for each SObject type.
    */
   private static Map<String, Map<String, Object>> defaultFieldMap;
   static {
       defaultFieldMap = new Map<String, Map<String, Object>>{
           'Account' => new Map<String, Object>{
               'Industry' => 'Technology',
               'Type' => 'Prospect',
               'Phone' => '9999999999'
           },
           'Contact' => new Map<String, Object>{
               'FirstName' => 'John',
               'LastName' => 'Doe',
               'Email' => 'john.doe@test.com'
           },
           'Opportunity' => new Map<String, Object>{
               'StageName' => 'Prospecting',
               'CloseDate' => System.today().addDays(30),
               'Amount' => 10000
           },
           'Product2' => new Map<String, Object>{
               'Family' => 'Subscription',
               'IsActive' => true
           },
           'SBQQ__Quote__c' => new Map<String, Object>{
               'SBQQ__Status__c' => 'Draft'
           },
           'SBQQ__QuoteLine__c' => new Map<String, Object>{
               'SBQQ__Quantity__c' => 1,
               'SBQQ__NetPrice__c' => 100,
               'SBQQ__ListPrice__c' => 100,
               'SBQQ__SubscriptionPricing__c' => 'Fixed Price'
           }
       };
   }
   // =====================================================
   // PUBLIC METHODS
   // =====================================================
   /**
    * @description Returns default values for the given SObject type.
    *
    * @param sObjectType  The API name of the SObject.
    * @return Map<String, Object> Clone of default field map for safety.
    */
   public static Map<String, Object> getDefaults(String sObjectType) {
       return defaultFieldMap.containsKey(sObjectType)
           ? new Map<String, Object>(defaultFieldMap.get(sObjectType))
           : new Map<String, Object>();
   }
   /**
    * @description Merges override values into existing defaults.
    *              Useful for customizing default data setup globally across test classes.
    *
    * @param sObjectType  The SObject type whose defaults must be updated
    * @param overrides    Map of field-value overrides
    */
   public static void mergeDefaults(String sObjectType, Map<String, Object> overrides) {
       if (!defaultFieldMap.containsKey(sObjectType)) {
           defaultFieldMap.put(sObjectType, new Map<String, Object>());
       }
       for (String key : overrides.keySet()) {
           defaultFieldMap.get(sObjectType).put(key, overrides.get(key));
       }
   }
}