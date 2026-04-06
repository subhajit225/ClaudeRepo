/**
 * @name CS_StripHTMLTags
 * @description Utility class to clean HTML tags from input strings. 
 *              It decodes common HTML entities, retains line breaks, and normalizes whitespace.
 * @author Sushant Arora
 * @date   02-June-2025
 * @version 1.0
*/
public with sharing class CS_StripHTMLTags {
    
    /**
     * @invocablemethod
     * @label Strip HTML & Clean Extra Spaces
     * @description This method is designed to:
     *   - Decode basic HTML entities (e.g., &lt;, &gt;, &amp;, &nbsp;)
     *   - Replace <p> and <br> tags with line breaks
     *   - Remove all other HTML tags
     *   - Normalize whitespace and trim extra spaces
     * 
     * @param inputTexts List of strings that may contain HTML content
     * @return List<String> Cleaned-up text with no HTML and normalized formatting
     */
    @InvocableMethod(
        label='Strip HTML & Clean Extra Spaces' 
        description='Removes HTML tags, keeps line breaks, and trims extra whitespace' 
        category='Text Utilities'
    )
    public static List<String> stripHTMLTags(List<String> inputTexts) {
        List<String> results = new List<String>();
        
        if(inputTexts.IsEmpty()) return null;
        
        for (String inputText : inputTexts) {
            if (inputText == null) {
                results.add(null);
                continue;
            }
            
            // Step 1: Decode HTML entities
            String decodedText = inputText
                .replaceAll('&lt;', '<')
                .replaceAll('&gt;', '>')
                .replaceAll('&amp;', '&')
                .replaceAll('&nbsp;', ' ');
            
            // Step 2: Replace <p> and <br> with line breaks
            decodedText = decodedText
                .replaceAll('<\\s*/?\\s*p\\s*>', '\n')
                .replaceAll('<\\s*br\\s*/?>', '\n');
            
            // Step 3: Remove any remaining HTML tags
            String cleanedText = decodedText.replaceAll('<[^>]*>', '');
            cleanedText = cleanedText.replaceAll('</?[a-z][a-z0-9]*[^<>]*>', '');
            
            // Step 4: Normalize whitespace
            cleanedText = cleanedText
                .replaceAll('[ \\t\\x0B\\f\\r]+', ' ')
                .replaceAll('\\n+', '\n')
                .trim();
            
            cleanedText = cleanedText.replaceAll('(?s)Current Status:\\s*\\n\\s*([^\n]+)', 'Current Status: $1');
            cleanedText = cleanedText.replaceAll('(?s)Next Steps:\\s*\\n\\s*([^\n]+)', 'Next Steps: $1');
            results.add(cleanedText);
        }
        
        return results;
    }
}