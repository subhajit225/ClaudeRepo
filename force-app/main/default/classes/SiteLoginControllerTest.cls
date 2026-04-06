/**
 * An apex page controller that exposes the site login functionality
 */
@IsTest global with sharing class SiteLoginControllerTest {
    @IsTest(SeeAllData=true) global static void testSiteLoginController () {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Profile profl = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

		User testUsr1 = new User(
                ProfileId = profl.Id,
                Username = 'shadab.hussain+partner1@randomtestdomain.com',
                Alias = 'testuser',
                Email = System.now().millisecond() + 'random.email@randomtestdomain.com',
                EmailEncodingKey = 'UTF-8',
                Firstname = 'test',
                Lastname = 'test',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'America/Chicago'
            );
        // Instantiate a new controller with all parameters in the page
        SiteLoginController controller = new SiteLoginController ();
        controller.username = 'shadab.hussain+partner1@randomtestdomain.com';
        controller.password = 'Rubrik@1234'; 
        controller.headerdata='/partner/';
        controller.urlvalue='https://fullsbstg-rubrik.cs78.force.com/partners?terms=true';
        controller.url='https://fullsbstg-rubrik.cs78.force.com/partners?terms=true';
        controller.OptIn =true;
          controller.parentUrl = 'https://fullsbstg-rubrik.cs78.force.com/partners?terms=true';
        System.runAs(testUsr1) {       
            controller.login();
            controller.continueAfterOptInCheck(); 
            controller.OptIn =false;
            System.assertEquals(controller.continueAfterOptInCheck(), null);
            controller.forwardToCustomAuthPage();
        }
 
    }    
}