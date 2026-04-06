@isTest(SeeAllData=true)
public class WelcomeEmailThirdPartyHardwareContTest {
    public static testMethod void testController(){
        WelcomeEmail_ThirdPartyHardwareCont ob = new WelcomeEmail_ThirdPartyHardwareCont();
        ob.ordId = null;
        ob.getEntitlements();
    }
    public static testMethod void testPSProduct(){
        WelcomeEmail_ThirdPartyHardwareCont ob = new WelcomeEmail_ThirdPartyHardwareCont();
        ob.ordId = null;
        ob.getPSTasks();
    }
}