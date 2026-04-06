/********************************************************************************************************
* Name              : CommunityCaseExtension_Test
* Purpose           : CommunityCaseExtension_Test is Used for Testing CommunityCaseExtension Class
*********************************************************************************************************/
@isTest
public class CommunityCaseExtension_Test{ 
    
    static testMethod void testCommunityCaseExtensionMthods() {
        Test.startTest();
        // Create a Case
        Case c = new Case();
        c.Priority='P2';
        c.Origin = 'Email';
        c.Subject = 'Test';
        insert c;  

        Apexpages.StandardController sc = new Apexpages.standardController(c);
        CommunityCaseExtension cce = new CommunityCaseExtension(sc); 

        cce.getComments();            
        cce.closeCase();
        cce.refresh();
        cce.saveAndUpload();
        Test.stopTest();
    }
 
}