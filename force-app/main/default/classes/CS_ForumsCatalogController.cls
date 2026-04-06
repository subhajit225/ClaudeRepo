/**
* @Author       :   Saakshi Gupta
* @CreatedDate  :   08-08-2022
* @Jira Ticket  :   CS21-1100 - Forums 2.0 Rewards Redemption/Swag Store
* @Description  :   This class is the apex controller for csForumsCatalog LWC component.
* @TestClass    :   CS_ForumsCatalogControllerTest
*/
public without sharing class CS_ForumsCatalogController {

    /**
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   08-08-2022
    * @Description  :   Gets the current user's details
    */
    @AuraEnabled(cacheable=true)
    public static User getCurrentUserDetails(){
        return [SELECT Id, Coins__c, Is_Rubrik_Employee__c
                FROM User
                WHERE Id =: UserInfo.getUserId()];
    }

    /**
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   08-08-2022
    * @Description  :   Retrieves all the active catalog items sorted by amount
    */
    @AuraEnabled(cacheable=true)
    public static List<Catalog__c> getCatalogItems(){
        try {
            return [SELECT Id, Name, Amount__c, Description__c, Name__c,
                        Current_user_eligible_to_redeem__c, Image__c
                    FROM Catalog__c
                    WHERE Active__c = true
                    ORDER BY Amount__c];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}