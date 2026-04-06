/**
 * @author Sushant Arora
 * @date 2026-01-14
 * @description Utility class to manage bypass flags for triggers or business logic.
 *              This class allows conditional bypass of validations or rules in a
 *              transaction by setting, checking, or removing string-based flags.
 *
 *              Usage:
 *              - TriggerConditionsBypass.addFlag('US_Citizen_Validation');
 *              - TriggerConditionsBypass.isBypassed('US_Citizen_Validation');
 *              - TriggerConditionsBypass.removeFlag('US_Citizen_Validation');
 *
 * @TestClass TriggerConditionsBypassTest
 */
public class TriggerConditionsBypass {

    /**
     * @description Each flag is a string representing a validation or business rule
     * that should be skipped for the current execution context.
     */
    public static Set<String> bypassFlags = new Set<String>();

    /**
     * @description Adds a bypass flag for the current transaction.
     * @param flagName Name of the validation or rule to bypass.
     */
    public static void addFlag(String flagName) {
        if (String.isNotBlank(flagName)) {
            bypassFlags.add(flagName);
        }
    }

    /**
     * @description Checks whether a given flag is set to bypass a rule.
     * @param flagName Name of the flag to check.
     * @return Boolean True if the flag is present, false otherwise.
     */
    public static Boolean isBypassed(String flagName) {
        return String.isNotBlank(flagName) && bypassFlags.contains(flagName);
    }

    /**
     * @description Removes a bypass flag after the transaction or DML is complete.
     * @param flagName Name of the flag to remove.
     */
    public static void removeFlag(String flagName) {
        if (String.isNotBlank(flagName)) {
            bypassFlags.remove(flagName);
        }
    }

    /**
     * @description Clears all bypass flags for the current transaction.
     */
    public static void clearAllFlags() {
        bypassFlags.clear();
    }
}