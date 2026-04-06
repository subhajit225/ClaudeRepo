/**
 * Author           :   Saakshi Gupta
 * Created Date     :   24-03-2020
 * Description      :   Apex controller for cS_CurrentStatusNextStepLwc Lightning Web component
 * Test Class       :   CaseDetailLightningControllerTest
 */
public without sharing class CaseDetailLightningController {

    /**
     * Author           :   Saakshi Gupta
     * Created Date     :   24-03-2020
     * Description      :   This method fetches the currently logged in user's information from the User object
     */
    @AuraEnabled(cacheable=true)
    public static User getUserInfo() {
        return [Select Id, Profile.Name from User where Id =: UserInfo.getUserId()];
    }
}