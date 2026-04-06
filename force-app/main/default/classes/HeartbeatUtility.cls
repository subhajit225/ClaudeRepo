/**
 * @Author      : Vijay Kumar K R
 * @CreatedDate : Oct 17, 2022 
 * @TstClass    : 
 * -------------------------- @History -------------------------------------
 * Story Number       Modified By              Date           Description
 * -------------------------------------------------------------------------
 */
public without sharing class HeartbeatUtility {
    
    /*
    * @Author       :   Vijay Kumar K R
    * @Jira Ticket  :   CS21-1623 - Add support for new error structure from HBX on support portal
    * @Description  :   generic method to return heartbeat error message
    */
    public static String getHeartbeatErrorMessage(String errorBody, CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm formFields){
        FailureMessagae response = (FailureMessagae)JSON.deserialize(errorBody, FailureMessagae.class);
        String originalSentence = response.message.error;
        String errorCause = response.message.cause;
        System.debug('errorCause:: '+errorCause);
        if(errorCause != null 
            && errorCause.containsIgnoreCase('Teleport registration failed')){
            if(errorCause.containsIgnoreCase('re-registration')){
                String inputString = errorCause.split('ERROR:')[1];
                String nodeId = extractString(inputString, 'node', 'is already registered').replaceAll('\\s+', '');
                String registrationTime = extractString(inputString, 'registered at', 'and after');
                String manufacturedTime = extractString(inputString, 'manufactured', ', hence overriding');
                String contactEmail = [SELECT Name, contact__r.email 
                                        FROM Entitlement_Use__c
                                        WHERE node__r.name =: nodeId
                                            AND Name =: formFields.uuid].contact__r.email;
                originalSentence = 'Node ('+nodeId+') is already registered at '+registrationTime+' by '+contactEmail+' after it was manufactured on '+manufacturedTime.replace('(', '').replace(')', '')+', hence re-registration is not permitted. ';
            }
            else{
                originalSentence = 'The teleport token is not valid. Please verify the teleport token and submit the registration request again.';
            }
        }
        String wordToHyperlink = 'open a case';
        String url = Label.Community_Base_URL+'newcases';
        String updatedSentence = addHyperlinkToString(originalSentence, wordToHyperlink, url);
        return updatedSentence;
    }

    public static String extractString(String input, String startWord, String endWord) {
        Integer startIndex = input.indexOf(startWord);
        if (startIndex == -1) {
            // Start word not found
            return null;
        }

        startIndex += startWord.length();

        Integer endIndex = input.indexOf(endWord, startIndex);
        if (endIndex == -1) {
            // End word not found after the start word
            return null;
        }

        return input.substring(startIndex, endIndex);
    }
    
    public static String addHyperlinkToString(String sentence, String word, String linkUrl) {
        // Find the starting index of the word within the sentence
        Integer startIndex = sentence.indexOf(word);

        // If the word is found, create the updated string with the hyperlink
        if(startIndex != -1) {
            Integer endIndex = startIndex + word.length();
            String linkedWord = sentence.substring(startIndex, endIndex);
            String replacement = '<a href="' + linkUrl + '" target="_blank"><b>' + linkedWord + '</b></a>';
            return sentence.replace(linkedWord, replacement);
        } else {
            return sentence; // Return the original sentence if the word is not found
        }
    }

    /*
    * @Author       :   Vijay Kumar K R
    * @CreatedDate  :   
    * @Jira Ticket  :   CS21-1623 - Add support for new error structure from HBX on support portal
    * @Description  :   Response wrapper class for Heartbeat responses: message
    */
    public class FailureMessagae{
        public message message {get;set;}
    }

    public class message{
        public String error_code {get;set;}
        public String error {get;set;}
        public String cause {get;set;}
        public String remedy {get;set;}
    }

}