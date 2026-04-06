/**
 * @author       :   Raveesh Layal
 * @createdDate  :   16-01-2025
 * @description  :   CS21-3043 - Issue with the Currency fields in Edit Opportunity button on Renewals Cases
 * @class        :   LGTRenewalOpportunityController.cls
 */
@IsTest
public class LGTRenewalOpportunityController_Test {
    
    /**
     * @description Tests the getAccessibleOpportunityFields method in LGTRenewalOpportunityController.
     */
    @IsTest
    static void testGetAccessibleOpportunityFields() {
        String uniqueUserName = 'csuser' + DateTime.now().getTime() + '@rubrik.com';

        // Fetch System Administrator profile
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

        // Create a test user
        User u = new User(
            Alias = 'standt',
            Email = 'standarduser@rubrik.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUserName
        );
        
        System.runAs(u) {
            // Call the method and assert the result
            List<String> result = LGTRenewalOpportunityController.getAccessibleOpportunityFields();
            System.assertNotEquals(null, result, 'Result should not be null');
        }
    }
}