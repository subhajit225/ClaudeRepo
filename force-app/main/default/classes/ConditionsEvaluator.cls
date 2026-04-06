/**
* @File Name : ConditionsEvaluator.cls
* @description : FY26WL-227 , FY26WL-237 - Custom Smart approval implementation
* @Author : Paritosh Bhatia
* @Last Modified By :  Ankita Varma
* @Last Modified On :  October 27, 2025
* @Modification Log :
* Test class : AutoApprovalTriggerUtilityTest
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 27, 2025 |   | Initial Version
**/
public with sharing class ConditionsEvaluator {
    /**
     * @description : Returns true if the input is number
     * @param str  : String to be verified
     * @return
     */
    private static Boolean isNumeric(String str) {
        if (String.isBlank(str)) return false;
        Pattern numericPattern = Pattern.compile('^-?\\d*(\\.\\d+)?$');
        return numericPattern.matcher(str.trim()).matches();
    }
    /**
     * @description : return the comparision betweern tow inputs
     * @param operand1  : Value to be compared
     * @param operator  : operator that compares
     * @param operand2  : Value be compared to
     * @return
     */
    public static Boolean operate(Object operand1, String operator, Object operand2) {
        // --- Null Safety ---
        operand1 = operand1 != null ? operand1 : '';
        operand2 = operand2 != null ? operand2 : '';

        // --- Attempt numeric detection and conversion ---
        Decimal dec1, dec2;
        Boolean numericCompare = false;

        if (isNumeric(String.valueOf(operand1)) && isNumeric(String.valueOf(operand2))) {
            dec1 = operand1 instanceof Decimal ? (Decimal)operand1 : Decimal.valueOf(String.valueOf(operand1).trim());
            dec2 = operand2 instanceof Decimal ? (Decimal)operand2 : Decimal.valueOf(String.valueOf(operand2).trim());
            numericCompare = true;
        }

        // --- Comparison Logic ---
        if (operator == Constants.EQUALS_OPERATOR) {
            if (numericCompare) return dec1 == dec2;
            // Support comma-separated list equality (A == "A,B,C")
            if (String.valueOf(operand2).contains(',')) {
                for (String item : String.valueOf(operand2).split(',')) {
                    if (String.valueOf(operand1).trim().equalsIgnoreCase(item.trim())) {
                        return true;
                    }
                }
                return false;
            }
            return String.valueOf(operand1).trim().equalsIgnoreCase(String.valueOf(operand2).trim());

        } else if (operator == Constants.NOT_EQUALS_OPERATOR) {
            if (numericCompare) return dec1 != dec2;

            if (String.valueOf(operand2).contains(',')) {
                for (String item : String.valueOf(operand2).split(',')) {
                    if (String.valueOf(operand1).trim().equalsIgnoreCase(item.trim())) {
                        return false;
                    }
                }
                return true;
            }
            return !String.valueOf(operand1).trim().equalsIgnoreCase(String.valueOf(operand2).trim());

        } else if (operator == Constants.LESS_THAN_OPERATOR && numericCompare) {
            return dec1 < dec2;

        } else if (operator == Constants.LESS_OR_EQUALS_OPERATOR && numericCompare) {
            return dec1 <= dec2;

        } else if (operator == Constants.GREATER_THAN_OPERATOR && numericCompare) {
            return dec1 > dec2;

        } else if (operator == Constants.GREATER_OR_QUALS_OPERATOR && numericCompare) {
            return dec1 >= dec2;

        } else if (operator == Constants.STARTS_WITH_OPERATOR) {
            return String.valueOf(operand1).startsWith(String.valueOf(operand2));

        } else if (operator == Constants.ENDS_WITH_OPERATOR) {
            return String.valueOf(operand1).endsWith(String.valueOf(operand2));

        } else if (operator == Constants.CONTAINS_OPERATOR) {
            if (String.valueOf(operand2).contains(',')) {
                for (String item : String.valueOf(operand2).split(',')) {
                    if (String.valueOf(operand1).trim().containsIgnoreCase(item.trim())) {
                        return true;
                    }
                }
                return false;
            }
            return String.valueOf(operand1).trim().contains(String.valueOf(operand2).trim());

        } else if (operator == Constants.DOES_NOT_CONTAIN_OPERATOR) {
            if (String.valueOf(operand2).contains(',')) {
                for (String item : String.valueOf(operand2).split(',')) {
                    if (String.valueOf(operand1).trim().containsIgnoreCase(item.trim())) {
                        return false;
                    }
                }
                return true;
            }
            return !String.valueOf(operand1).trim().contains(String.valueOf(operand2).trim());

        } else if (operator == Constants.INCLUDES_OPERATOR) {
            // For semicolon-separated fields like "A;B;C"
            return (';' + String.valueOf(operand1) + ';').containsIgnoreCase(';' + String.valueOf(operand2) + ';');
        }

        // --- Default ---
        return false;
    }
}