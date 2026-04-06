/**
* @description : Class controller to capture Support Portal User Agreement acceptance on 
* User record- JIRA - CS21-827
*
* @CreatedDate 15th Dec 2021
* @Created By Veera Gandi
* 
* @Test Class CSCommunityTermsAndConditionsControllerTest
*/
public without sharing class CSCommunityTermsAndConditionsController {
    
    /**
    * @description once user accepts terms and conditions in the support portal,
    * terms and conditions field is updated on the user record.
    * return: void
    */
    @AuraEnabled
    Public static void updateTermsAndConditions(String currentUserId) {
        try {
            User currentUser = new User();
            currentUser.Id = currentUserId;
            currentUser.IsCustomerSupportTCAccepted__c = true;
            update currentUser;
        } catch (exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }    
}