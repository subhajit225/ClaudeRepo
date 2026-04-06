/**
* @description : Test class for CSCommunityTermsAndConditionsController - JIRA - CS21-827
*
* @Created By Veera Gandi
*/
@isTest(SeeAllData=false)
public class CSCommunityTAndCControllerTest {
    
    @istest
    static void updateTermsAndConditionsTest() {
        string userId = userInfo.getUserId();
        CSCommunityTermsAndConditionsController.updateTermsAndConditions(userId);
        system.assertEquals(true, [SELECT Id, IsCustomerSupportTCAccepted__c FROM User Where Id = :userId].IsCustomerSupportTCAccepted__c);
    }
    
    @istest
    static void updateTermsAndConditionsNegitiveTest() {
        try {
            string userId = 'qwerty';
            CSCommunityTermsAndConditionsController.updateTermsAndConditions(userId); 
        } catch (exception ex) {
            system.assertEquals('Script-thrown exception', ex.getMessage());
        }
    }
    
}