/**
 * Author           :   Saakshi Gupta
 * Created Date     :   24-03-2020
 * Description      :   Test class for CaseDetailLightningController class
 */
@isTest
private class CaseDetailLightningControllerTest {
    
    /**
     * Author           :   Saakshi Gupta
     * Created Date     :   24-03-2020
     * Description      :   Test method for getUserInfo()
     */
    static testMethod void testGetUserInfo(){
        User currentUser = new User();
        
        Test.startTest();

        currentUser = CaseDetailLightningController.getUserInfo();

        Test.stopTest();

        System.assert(currentUser.Profile.Name != null);
    }
}