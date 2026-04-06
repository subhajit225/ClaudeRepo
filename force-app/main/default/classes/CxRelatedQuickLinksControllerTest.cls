/**
 * Author       :   Abhishek Mahajan
 * CreatedDate  :   26th September 2023
 * Description  :   Test class for CxRelatedQuickLinksController
 */
@IsTest
public class CxRelatedQuickLinksControllerTest{

    @testSetup
    static void setup() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
    }

    @IsTest
    static void testGetRelatedQuickLinks_positive() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<CxRelatedQuickLinksController.RelatedQuickLink> relatedQuickLinks = CxRelatedQuickLinksController.getRelatedQuickLinks(testAccount.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, relatedQuickLinks);
        System.assertNotEquals(0, relatedQuickLinks.size());
    }

    @IsTest
    static void testGetRelatedQuickLinks_negative() {

        Test.startTest();
        try {
            CxRelatedQuickLinksController.getRelatedQuickLinks(null);
        } catch (Exception ex) {
            System.assertEquals('Script-thrown exception', ex.getMessage());
        }
        Test.stopTest();
    }
}