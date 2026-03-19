/**
 * @description Apex controller for the myAccounts LWC component.
 *              Retrieves the top 5 Account records and the total Account count
 *              for display in the My Accounts card view.
 * Check if MCP
 */
public with sharing class MyAccountsController {

    /**
     * @description Returns the top 5 Accounts (ordered by Name) and the
     *              total number of Accounts accessible to the running user.
     * @return AccountResult wrapper containing the accounts list and total count.
     */
    @AuraEnabled(cacheable=true)
    public static AccountResult getAccountData() {
        AccountResult result = new AccountResult();

        result.accounts = [
            SELECT Id, Name, Industry, Phone, AnnualRevenue, Rating
            FROM Account
            WITH USER_MODE
            ORDER BY Name
            LIMIT 5
        ];

        result.totalCount = [SELECT COUNT() FROM Account WITH USER_MODE];

        return result;
    }

    /** @description Wrapper returned to the LWC component. */
    public class AccountResult {
        /** @description The top 5 Account records. */
        @AuraEnabled
        public List<Account> accounts { get; set; }

        /** @description Total number of Account records accessible to the user. */
        @AuraEnabled
        public Integer totalCount { get; set; }
    }
}