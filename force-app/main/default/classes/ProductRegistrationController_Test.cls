/********************************************************************************************************
* Name              : ProductRegistrationController_Test
* Purpose           : ProductRegistrationController_Test is Used for Testing ProductRegistrationController Class
*********************************************************************************************************/
@isTest
public class ProductRegistrationController_Test{
    
    static testMethod void testProductRegistrationController(){
        Test.startTest();
        ProductRegistrationController pr = new ProductRegistrationController();

        pr.uuid = '1234-1234-1234';
        pr.nodename = 'RVM12345';
        pr.regMessage = 'test';
        pr.regString = 'tedgry6354654';
  
        pr.init();
        pr.validate();
        pr.callout();
        pr.submit();
        pr.validateSuccess();
        Id actId=pr.getacctId;
        Boolean dark=pr.isDark;
        Test.stopTest();
    }
    
}