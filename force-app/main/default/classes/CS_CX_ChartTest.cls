@isTest
public class CS_CX_ChartTest {

    // Test method for getAccountScore
    @isTest
    public static void testGetAccountScore() {
        // Create test Account
        Account testAccount = new Account();
        testAccount.Name = 'test';
        testAccount.BillingStreet = 'street';
        testAccount.BillingCity = 'city';
        testAccount.BillingCountry = 'India';
        testAccount.BillingPostalCode = '456789';
        testAccount.Type = 'Partner';
        insert testAccount;

        // Call the method to get AccountScore
        Test.startTest();
        CS_CX_Chart.AccountScore result = CS_CX_Chart.getAccountScore(testAccount.Id);
        Test.stopTest();

        // Assertions to verify the results
        System.assertNotEquals(result, null, 'AccountScore should not be null');
        System.assertEquals(result.account.Name, 'test', 'Account name should match');
    }

    // Test method for getHistoricalCharts
    @isTest
    public static void testGetHistoricalCharts() {
        // Create test Account
        Account testAccount = new Account();
        testAccount.Name = 'test';
        testAccount.BillingStreet = 'street';
        testAccount.BillingCity = 'city';
        testAccount.BillingCountry = 'India';
        testAccount.BillingPostalCode = '456789';
        testAccount.Type = 'Partner';
        insert testAccount;

        // Call the method to get historical charts
        Test.startTest();
        CS_CX_Chart.dataSegment historicalCharts = CS_CX_Chart.getHistoricalCharts(testAccount.Id);
        Test.stopTest();

        // Assertions to verify the results
        System.assertNotEquals(historicalCharts, null, 'Historical charts dataSegment should not be null');
        System.assertNotEquals(historicalCharts.monthlyCharts, null, 'Monthly charts should not be null');
        System.assertEquals(historicalCharts.monthlyCharts.labelsList.size(), 1, 'There should be two monthly chart labels');
    }
}