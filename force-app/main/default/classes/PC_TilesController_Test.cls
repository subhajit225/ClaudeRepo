/*
 * Class Name :- ContactMainTest
 * Created Date :- 02-06-2019
 * Description : This test class cover the PC_TilesCOntroller
 * 
 * */
@isTest
public class PC_TilesController_Test {
    @isTest static void testMethodPartnerConfiguration() {
        test.startTest();
        User u = [select id,name from user where profile.name ='System Administrator' and userRoleId != null and isactive=true limit 1];
        List<User> lstUserRec = new List<User>();
        system.runas(u){
            Account accRec = ShGl_TestFactory.testMethod_PartnerAccount('Test Account');
            List<Contact> lstContact = ShGl_TestFactory.testMethod_PartnerContact(1,accRec);
            lstUserRec = ShGl_TestFactory.testMethod_PartnerUser(1,lstContact);
        }
        List<Partner_Page_Configuration__c> pConfigRec = ShGl_TestFactory.testMethod_PartnerPageConfigurationCreation(1);
        List<Partner_Page_Configuration__c> lstGetTiles = PC_TilesController.getTiles('home', 'card');
        Partner_Page_Configuration__c GetBanner = PC_TilesController.getBanner('home', 'banner');
        List<Partner_Page_Configuration__c> lstHelpLinks = PC_TilesController.getHelpLinks('home', 'HelpLink');
        test.stopTest();
    }

}