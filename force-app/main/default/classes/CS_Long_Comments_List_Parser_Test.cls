/**
 * @author Raveesh Layal
 * @date 2025-01-14
 * @description
 * Test class for CS_Long_Comments_List_Parser.
 * Contains unit tests covering valid, null, and multiline input scenarios
 * for the convertStringIntoCollection method.
 */
@isTest
public class CS_Long_Comments_List_Parser_Test {
    
    /**
     * @description Creates a system admin user for test purposes.
     * @return User details
     */
    static User createSystemAdminUser() {
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User sysAdminUser = new User(
            Alias = 'sadcsit',
        Email = 'sysadmincsit@rubrik.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Admin',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = sysAdminProfile.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        UserName = 'sysadmincsit' + System.currentTimeMillis() + '@rubrik.com'
            );
        insert sysAdminUser;
        return sysAdminUser;
    }
    
    /**
     * @description
     * Tests convertStringIntoCollection method with a valid comma-separated string.
     * Asserts that the result contains a single list with correct number of elements.
     */
    @isTest
    static void testConvertStringIntoCollectionWithValidInput() {
        User sysAdminUser = createSystemAdminUser();
        System.runAs(sysAdminUser) {
            // Arrange
            CS_Long_Comments_List_Parser.InputParams inputParam = new CS_Long_Comments_List_Parser.InputParams();
            inputParam.inputValue = 'test A,Test B,Test C';
            List<CS_Long_Comments_List_Parser.InputParams> inputList = new List<CS_Long_Comments_List_Parser.InputParams>{ inputParam };
            
            // Act
            List<List<String>> result = CS_Long_Comments_List_Parser.convertStringIntoCollection(inputList);
            
            // Assert
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertEquals(1, result.size(), 'Result should contain one inner list');
            System.assertEquals(3, result[0].size(), 'Inner list should contain three elements');
        }
    }
    
    /**
     * @description
     * Tests convertStringIntoCollection method with null inputValue.
     * Asserts that the result is null.
     */
    @isTest
    static void testConvertStringIntoCollectionWithNullInput() {
        User sysAdminUser = createSystemAdminUser();
        System.runAs(sysAdminUser) {
            // Arrange
            CS_Long_Comments_List_Parser.InputParams inputParam = new CS_Long_Comments_List_Parser.InputParams();
            inputParam.inputValue = null;
            List<CS_Long_Comments_List_Parser.InputParams> inputList = new List<CS_Long_Comments_List_Parser.InputParams>{ inputParam };
            
            // Act
            List<List<String>> result = CS_Long_Comments_List_Parser.convertStringIntoCollection(inputList);
            
            // Assert
            System.assertEquals(null, result, 'Result should be null for null input');
        }
    }
    
    /**
     * @description
     * Tests convertStringIntoCollection method with newline-separated input string.
     * Asserts that the result is not null and inner list is correctly parsed.
     */
    @isTest
    static void testConvertStringIntoCollectionWithLineBreakInput() {
        User sysAdminUser = createSystemAdminUser();
        System.runAs(sysAdminUser) {
            // Arrange
            CS_Long_Comments_List_Parser.InputParams inputParam = new CS_Long_Comments_List_Parser.InputParams();
            inputParam.inputValue = 'test\ntest2';
            List<CS_Long_Comments_List_Parser.InputParams> inputList = new List<CS_Long_Comments_List_Parser.InputParams>{ inputParam };
            
            // Act
            List<List<String>> result = CS_Long_Comments_List_Parser.convertStringIntoCollection(inputList);
            
            // Assert
            System.assertNotEquals(null, result, 'Result should not be null for newline input');
            System.assertEquals(1, result.size(), 'Result should contain one inner list');
            System.assertEquals(2, result[0].size(), 'Inner list should contain two elements');
            System.assertEquals('test', result[0][0], 'First element should be "test"');
            System.assertEquals('test2', result[0][1], 'Second element should be "test2"');
        }
    }
}