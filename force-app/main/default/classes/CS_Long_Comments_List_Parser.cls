/**
 * @author Raveesh Layal
 * @date 2025-01-14
 * @description
 * This class parses input strings from a Flow invocation and returns a collection (list of list)
 * of strings, split by either commas or newlines. This is useful for dynamically parsing comments 
 * or file-related input strings in flows.
 */
public class CS_Long_Comments_List_Parser {

    /**
     * @description
     * A wrapper class used to receive input from a Flow. It contains a single required string field.
     */
    public class InputParams {
        /**
         * @description The input string value passed from the Flow.
         */
        @InvocableVariable(required=true)
        public String inputValue;
    }

    /**
     * @description
     * This method converts a delimited input string (comma- or newline-separated) into a list of strings.
     * It's intended to be called from a Flow using the InvocableMethod annotation.
     *
     * @param inputList A list containing one InputParams object that wraps the string to be parsed.
     * @return A list of list of strings, where the inner list contains the parsed strings.
     */
    @InvocableMethod(label='Get String List' description='Returns a list of strings based on input')
    public static List<List<String>> convertStringIntoCollection(List<InputParams> inputList) {
        if (inputList == null || inputList.isEmpty()) {
            return null;
        }

        String inputValue = inputList[0].inputValue;

        if (String.isNotBlank(inputValue)) {
            if (inputValue.contains(',')) {
                return new List<List<String>> { inputValue.split(',') };
            } else if (inputValue.contains('\n')) {
                List<String> splittedData = new List<String>();
                for (String input : inputValue.split('\n')) {
                    splittedData.add(input.trim());
                }
                return new List<List<String>> { splittedData };
            } else {
                return new List<List<String>> { new List<String> { inputValue } };
            }
        }

        return null;
    }
}