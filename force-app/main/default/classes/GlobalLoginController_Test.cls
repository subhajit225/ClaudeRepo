/********************************************************************************************************
* Name              : GlobalLoginController_Test
* Purpose           : GlobalLoginController_Test is Used for Testing GlobalLoginController Class
*********************************************************************************************************/
@isTest
public class GlobalLoginController_Test{
    
    static testMethod void testStringIsEmptyException(){
        Test.startTest();
        System.runAs(new User(Id=UserInfo.getUserId())) {
            GlobalLoginController globalController = new GlobalLoginController();
            globalController.username=UserInfo.getUserName();
            globalController.pw='Abc';
            globalController.go();
        }
        Test.stopTest();
    }   
}