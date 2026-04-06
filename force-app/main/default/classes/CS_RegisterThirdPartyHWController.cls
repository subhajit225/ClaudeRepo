/**
* @description  :   Controller for data validations and Lightning aura component CS_RegisterThirdPartyHardware
* @Author       :   Saakshi Gupta
* @CreatedDate  :   14-09-2021
* @Jira Ticket  :   CS-679 - Enable offline product activation/registration for third party hardware manufacturing on the Support Portal
* @TestClass    :   CS_RegisterThirdPartyHWControllerTest.cls
* -------------------------- @History --------------------------------------------------------------------------------------------
 * Story Number       Modified By              Date           Description
 * CS21-1623         Vijay Kumar K R        Oct 04, 2023      Add support for new error structure from HBX on support portal
 * CS21-3819		 Shailesh Kumar		    Dec 11,2025	      Code - Remove third party prefix mapping check on SFDC
 * --------------------------------------------------------------------------------------------------------------------------------
 */
public without sharing class CS_RegisterThirdPartyHWController {

    /**
    * @description  :   Register method when the user clicks on Register button on the page. This method invokes all the data validation and callout methods
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   14-09-2021
    * @param thirdPartyHardwareFormFields
    * @return List<ThirdPartyHardwareResultWrapper>
    */
    @AuraEnabled
    public static List<ThirdPartyHardwareResultWrapper> registerThirdPartyHardware(String thirdPartyHardwareFormFields){
        //Retrieve logged in user's details
        User currentUser = [SELECT Id, Contact.AccountId, ContactId, Username FROM User WHERE Id =: userInfo.getUserId() LIMIT 1];

        //Parse the input values serialized into a string to a wrapper object
        CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm formFields = (CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm)JSON.deserialize(thirdPartyHardwareFormFields, CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm.class);

        //Retrieve Entitlement details
        List<Entitlement> entitlementList = [SELECT Id, Status, Product__r.ProductCode, AccountId, Account.Name,
                            (SELECT Id FROM EntitlementContacts WHERE ContactId =: currentUser.ContactId)
                            FROM Entitlement WHERE Id =: formFields.entitlementId AND Type = 'Manufacturing Entitlement'];

        //Perform validation on Entitlement
        ThirdPartyHardwareResultWrapper result = validateEntitlement(entitlementList);
        List<ThirdPartyHardwareResultWrapper> resultList = new List<ThirdPartyHardwareResultWrapper>();

        //If there is an error with the Entitlement, add the results wrapper object to an error list which will be displayed to the users
        if(result.internalError){
            resultList.add(result);
        }
        /*If there is no error with the Entitlement, check if the Entitlement belongs to the logged in user's Account and if the
        contact is added to the Entitlement*/
        else{
            result = validateEntitlementOnAccountContact(entitlementList[0], currentUser);
            if(result != null && result.internalError){
                resultList.add(result);
            }
        }

        //Validate the Node Id entered by the user
        //Node_Prefix_to_Product_Mapping__mdt productMapping = validateNodeId(formFields.nodeId);CS21-3819

        //If the node id is invalid, add the error result to the error list
        /*if(productMapping == null){
            resultList.add(new ThirdPartyHardwareResultWrapper(true, false, System.Label.Invalid_Node_Id_Error, null));
        }*/

        if(!resultList.isEmpty()){
            return resultList;
        }

        //If all the input data is valid, perform callouts to Heartbeat and Teleport
        //return nodeRegistrationCallout(formFields, currentUser, entitlementList[0], productMapping);CS21-3819
        return nodeRegistrationCallout(formFields, currentUser, entitlementList[0]);
    }

    /**
    * @description	:	Validate Entitlement Id entered by the user. Firstly, check if the entitlement is a valid Id
    *                   by searching in Salesforce. If the entitlement id is valid, check if the Entitlement is Active	
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   14-09-2021
    * @param entitlementList
    * @return ThirdPartyHardwareResultWrapper
    */
    private static ThirdPartyHardwareResultWrapper validateEntitlement(List<Entitlement> entitlementList){
        String message = '';

        //Return error object if the Entitlement Id is invalid and could not be found in Salesforce
        if(entitlementList.isEmpty()){
            message = System.Label.No_Entitlement_Error + ' ' + System.Label.Open_a_Case_Text + ' ' + System.Label.With_Rubrik_Support_Text;
            return new ThirdPartyHardwareResultWrapper(true, false, message, null);
        }
        //Return error object if the Entitlement Id is valid but not Active
        else if(!entitlementList[0].Status.equalsIgnoreCase('Active')){
            message = System.Label.Expired_Entitlement_Error + ' ' + System.Label.Open_a_Case_Text + ' ' + System.Label.With_Rubrik_Support_Text;
            return new ThirdPartyHardwareResultWrapper(true, false, message, null);
        }

        return new ThirdPartyHardwareResultWrapper(false, false, '', null);
    }

    /*
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   14-09-2021
    * @Description  :   Validate Node Id entered by the user. Check the prefix of the Node Id and see if it is one of the
    *                   listed node Id prefixes in the custom metadata
    */
    /*private static Node_Prefix_to_Product_Mapping__mdt validateNodeId(String nodeId){
        
        String nodeIdPrefix = nodeId.length() >= 2 ? nodeId.substring(0, 2) + '%': nodeId + '%';

        
        List<Node_Prefix_to_Product_Mapping__mdt> mappingList = [SELECT Node_Id_Prefix__c, Product_Code__c, Vendor__c
                                                                FROM Node_Prefix_to_Product_Mapping__mdt
                                                                WHERE Node_Id_Prefix__c LIKE: nodeIdPrefix];

        
        if(!mappingList.isEmpty()){
            for(Node_Prefix_to_Product_Mapping__mdt eachMapping : mappingList){
                if(nodeId.startsWithIgnoreCase(eachMapping.Node_Id_Prefix__c)){
                    return eachMapping;
                }
            }
        }
        return null;
    }*/

    /**
    * @description  :   Validate Entitlement Id entered by the user. Check if the entitlement Id belongs to the logged in
    *                   user's Account. Also check if the logged in Contact belongs to the Entitlement
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   14-09-2021
    * @param  entitlementRecord
    * @param currentUser
    * @return ThirdPartyHardwareResultWrapper
    */
    private static ThirdPartyHardwareResultWrapper validateEntitlementOnAccountContact(Entitlement entitlementRecord, User currentUser){
        List<EntitlementVerificationWrapper> entitlementResultList = new List<EntitlementVerificationWrapper>();
        Boolean error = false;
        String result = '';

        /*
        //Set the error message and error flag as true if the Account on Entitlement and logged in Contact's Account doesn't match
        if(entitlementRecord.AccountId != currentUser.Contact.AccountId){
            result = System.Label.Entitlement_Not_On_Account_Error_1 + ' (' + currentUser.Username + ') ' + System.Label.Entitlement_Not_On_Account_Error_2 + ' (' + entitlementRecord.Id + '). ' + System.Label.Entitlement_Not_On_Account_Error_3 + ' ' + System.Label.Open_a_Case_Text + ' ' + System.Label.With_Rubrik_Support_Text;
            error = true;
        }
        //Set the success message and error flag as false if the Account on Entitlement and logged in Contact's Account matches
        else {
            result = System.Label.Entitlement_Not_On_Account_Error_1 + ' (' + currentUser.Username + ') ' + System.Label.Entitlement_On_Account_Success_2 + ' (' + entitlementRecord.Id + ').';
            error = false;
        }

        //Add the result wrapper object to the result list
        entitlementResultList.add(new EntitlementVerificationWrapper(System.Label.Entitlement_related_to_the_Account_Type, result, error));
        */

        //Set the error message and error flag as true if the Contact is not added on the Entitlement as Entitlement Contact
        if(entitlementRecord.EntitlementContacts.isEmpty()){
            result = System.Label.Entitlement_Not_On_Account_Error_1 + ' (' + currentUser.Username + ') ' + System.Label.Entitlement_Not_On_Contact_Error + ' (' + entitlementRecord.Id + '). ' + System.Label.Entitlement_Not_On_Contact_Error_2 + ' ' + System.Label.Open_a_Case_Text + ' ' + System.Label.With_Rubrik_Support_Text;
            error = true;
        }
        //Set the success message and error flag as false if the Contact is added on the Entitlement as Entitlement Contact
        else {
            result = System.Label.Entitlement_Not_On_Account_Error_1 + ' (' + currentUser.Username + ') ' + System.Label.Entitlement_On_Contact_Success + ' (' + entitlementRecord.Id + ').';
            error = false;
        }

        entitlementResultList.add(new EntitlementVerificationWrapper(System.Label.Entitlement_related_to_the_Contact_Type, result, error));

        //If atleast one of the above validation fails, return the result list with internal error flag as true else return null
        for(EntitlementVerificationWrapper eachObject : entitlementResultList){
            if(eachObject.error){
                return new ThirdPartyHardwareResultWrapper(true, false, '', entitlementResultList);
            }
        }

        return null;
    }

    /**
    * @description	:	After all the input data validations are done and successful, this method makes the callouts to Heartbeat
    *                   and Teleport to register the node
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   14-09-2021
    * @param formFields
    * @param currentUser
    * @param entitlementRecord
    * @return List<ThirdPartyHardwareResultWrapper>
    */
    private static List<ThirdPartyHardwareResultWrapper> nodeRegistrationCallout(CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm formFields,
                                                                           User currentUser,
                                                                           Entitlement entitlementRecord)//,Node_Prefix_to_Product_Mapping__mdt productMapping
    {

        //Remove all special characters from the serial number
        formFields.serialNumber = formFields.serialNumber.replaceAll('[^a-zA-Z0-9\\s+]', '');

        //Set Integration attributes like endpoint and token, by checking if the current environment is a sandbox or production
        CS_ThirdPartyHWRegistrationHelper.setIntegrationAttributes();

        HttpResponse responseObject;
        String message = '';
        String heartbeatNotRespondingMessage = System.Label.Heartbeat_not_responding_error + ' ' + System.Label.Open_a_Case_Text + ' ' + System.Label.With_Rubrik_Support_Text;
        List<ThirdPartyHardwareResultWrapper> results = new List<ThirdPartyHardwareResultWrapper>();

        try {
            //Make the first post callout to Heartbeat which creates a Node in Salesforce
            responseObject = CS_ThirdPartyHWRegistrationHelper.nodeRegistrationCallout(formFields, currentUser, entitlementRecord);//,productMapping

            //If the callout is successful, make the subsequent callouts
            if(responseObject.getStatusCode() == 200) {
                results.add(setIntegrationResultWrapper(responseObject.getBody().replaceAll('"', ''), false, false));
                return results;
            }
            //If there is a validation or execution failure in Heartbeat, return the message returned by Heartbeat service and display to the user
            else if(responseObject.getStatusCode() == 400) {
                String errorBody = responseObject.getBody();
                if(errorBody.containsIgnoreCase('error_code')){
                    // New HBX Error format
                    results.add(setIntegrationResultWrapper(HeartbeatUtility.getHeartbeatErrorMessage(errorBody, formFields), false, true));
                }else{
                    CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareNodeResponse response = (CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareNodeResponse)JSON.deserialize(responseObject.getBody(), CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareNodeResponse.class);
                    results.add(setIntegrationResultWrapper(response.message, false, true));
                }
                return results;
            }
            //For any other types of error such as connection error, etc, display the message to the user saying service is not responding
            else{
                String errorBody = responseObject.getBody();
                if(errorBody.containsIgnoreCase('error_code')){
                    // New HBX Error format
                    results.add(setIntegrationResultWrapper(HeartbeatUtility.getHeartbeatErrorMessage(errorBody, formFields), false, true));
                }else{
                    results.add(setIntegrationResultWrapper(heartbeatNotRespondingMessage, false, true));
                }
                return results;
            }
        } catch(System.CalloutException e){
            results.add(setIntegrationResultWrapper(heartbeatNotRespondingMessage, false, true));
            return results;
        } catch(System.Exception ex){
            CS_ThirdPartyHWRegistrationHelper.insertIntegrationLogs(responseObject, null, ex.getMessage());
            String exceptionMessage = ex.getMessage() + ' ' + System.Label.Open_a_Case_Text + ' ' + System.Label.With_Rubrik_Support_Text;
            results.add(setIntegrationResultWrapper(exceptionMessage, false, true));
            return results;
        }
    }

    /**
    * @description	:	This method sets the error flags and message
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   14-09-2021
    * @param message
    * @param internalError
    * @param integrationError
    * @return ThirdPartyHardwareResultWrapper
    */
    private static ThirdPartyHardwareResultWrapper setIntegrationResultWrapper(String message, Boolean internalError, Boolean integrationError){
        ThirdPartyHardwareResultWrapper result = new ThirdPartyHardwareResultWrapper();
        result.internalError = internalError;
        result.integrationError = integrationError;
        result.message = message;
        return result;
    }

    /**
    * @description	:	Wrapper class for results of data validation and callouts which is used to display results to the user on the page
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   14-09-2021
    * @Jira Ticket  :   CS-679 - Enable offline product activation/registration for third party hardware manufacturing on the Support Portal
    */
    public class ThirdPartyHardwareResultWrapper{
        /**
        * @description internalError placeholder
        */
        @AuraEnabled public Boolean internalError {get;set;}
        /**
        * @description integrationError placeholder
        */
        @AuraEnabled public Boolean integrationError {get;set;}
        /**
        * @description message placeholder
        */
        @AuraEnabled public String message {get;set;}
        /**
        * @description entitlementVerificationResult placeholder
        */
        @AuraEnabled public List<EntitlementVerificationWrapper> entitlementVerificationResult {get;set;}
        /**
        * @description constructor with parameters
        * @param internalError
        * @param integrationError
        * @param message
        * @param entitlementVerificationResult
        */
        public ThirdPartyHardwareResultWrapper(Boolean internalError, Boolean integrationError, String message, List<EntitlementVerificationWrapper> entitlementVerificationResult){
            this.internalError = internalError;
            this.integrationError = integrationError;
            this.message = message;
            this.entitlementVerificationResult = entitlementVerificationResult;
        }
        /**
        * @description constructor
        */
        public ThirdPartyHardwareResultWrapper(){
            System.debug(LoggingLevel.DEBUG,'Default Constructor');
        }
    }

    /**
    * @description	:	Wrapper class for Entitlement validation on Account and Contact
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   14-09-2021
    * @Jira Ticket  :   CS-679 - Enable offline product activation/registration for third party hardware manufacturing on the Support Portal
    */
    public class EntitlementVerificationWrapper{
        /**
        * @description type placeholder
        */
        @AuraEnabled public String type {get;set;}
        /**
        * @description result placeholder
        */
        @AuraEnabled public String result {get;set;}
        /**
        * @description error placeholder
        */
        @AuraEnabled public Boolean error {get;set;}
        /**
        * @description message placeholder
        * @param type
        * @param result
        * @param error
        */
        public EntitlementVerificationWrapper(String type, String result, Boolean error){
            this.type = type;
            this.result = result;
            this.error = error;
        }
    }
}