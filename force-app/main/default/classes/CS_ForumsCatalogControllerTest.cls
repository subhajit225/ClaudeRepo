/**
* @Author       :   Saakshi Gupta
* @CreatedDate  :   08-08-2022
* @Jira Ticket  :   CS21-1100 - Forums 2.0 Rewards Redemption/Swag Store
* @Description  :   Test class for CS_ForumsCatalogController.
*/
@isTest(seeAllData=false)
public class CS_ForumsCatalogControllerTest {
    @isTest static void testGetCurrentUserDetails() {
        CS_ForumsCatalogController.getCurrentUserDetails();
    }

    @isTest static void testGetCatalogItems() {
        CS_ForumsCatalogController.getCatalogItems();
    }
}