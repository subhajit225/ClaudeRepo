/**
* @description Class to handle server side activities for RubrikCommunityEnforceAdminPanel LwC Component
* - JIRA - CS21-891
*
* @CreatedDate 15th March 2022
* @Created By Veera Gandi
*
* @Test Class RubrikEnforceAdminPanelControllerTest
*/
public without sharing class RubrikEnforceAdminPanelController {

    //custom exception class
    public class CustomException extends Exception {}

    /**
    * @description to return account details and audit log details.
    * @param  Account Id
    * @return List of Accounts
    */
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccountDetails(string AccountId) {
		return getAccounts(AccountId);
    }

    /**
    * @description method to update account record
    * @param  account Id
    * @param  boolean from the toggle button
    * @return void
    */
    @AuraEnabled
    public static void updateEnforceAdminUser(string accountId, Boolean enforceAdminUser) {
        try {
            //querying again as there is a chance that field is updated from backend
            //before the community user updates from admin panel page
		 	List<Account> accounts = getAccounts(accountId);

            if (!accounts.isEmpty()) {
                if (accounts[0].Enforce_Admin_User__c != enforceAdminUser) {
                    accounts[0].Enforce_Admin_User__c = enforceAdminUser;
                    update accounts[0];
                } else {
                    // if the value is already updated, throw custom error
                    String flag = accounts[0].Enforce_Admin_User__c ? 'enabled.' : 'disabled.';
                    throw new CustomException('Automated User Registration Approval is already ' + flag);
                }
            }
        } catch (exception ex) {
            throw new CustomException('Error :: ' + ex.getMessage());
        }
    }

    /**
    * @description to return account details and audit log details.
    * @param  Account Id
    * @return List of Accounts
    */
    private static List<Account> getAccounts(string accountId) {
        return [SELECT Id, Enforce_Admin_User__c,
                (SELECT Username__c, Email__c, CreatedDate, UserFullName__c, NewValue__c
                 FROM Account_Audit_Logs__r
                 /*WHERE IsRubrikUser__c = false*/
                 ORDER BY CreatedDate DESC LIMIT 1)
                FROM Account
                WHERE Id = :accountId];
    }

    /**
    * @description method constructs account audit logs and returns
    * @param  account record
    * @param  boolean from the toggle button
    * @return Account
    */
    public static AccountAuditLog__c generateAuditLog(Account newAccount, Account oldAccount) {
        AccountAuditLog__c auditLog = new AccountAuditLog__c();
        auditLog.Account__c = newAccount.Id;
        auditLog.User__c = userInfo.getUserId();
        auditLog.EditedField__c = 'Enforce Admin Panel';
        auditLog.NewValue__c = newAccount.Enforce_Admin_User__c;
        auditLog.OldValue__c = oldAccount.Enforce_Admin_User__c;
        return auditLog;
    }
}