/**
* @description test class for RubrikEnforceAdminPanelController
* - JIRA - CS21-891
*
* @CreatedDate 15th March 2022
* @Created By Veera Gandi
*/
@isTest(SeeAllData=false)
public class RubrikEnforceAdminPanelControllerTest {
    
    @testSetup
    static void testSetUp() {
        insert new TriggerControl__c(Name='Case');
        
        Account account = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        account.Name = 'Test Account';
        insert account;
    }
    
    @istest
    static void testEnforceAdmin() {
        List<Account> accounts = [SELECT Id, Enforce_Admin_User__c FROM Account LIMIT 1];
        RubrikEnforceAdminPanelController.updateEnforceAdminUser(accounts[0].Id, true);
        List<Account> refreshedAccounts = RubrikEnforceAdminPanelController.getAccountDetails(accounts[0].Id);
        RubrikEnforceAdminPanelController.generateAuditLog(refreshedAccounts[0], accounts[0]);
    }
    
    @istest
    static void testEnforceAdminException() {
        try {
            List<Account> accounts = [SELECT Id FROM Account LIMIT 1];
            RubrikEnforceAdminPanelController.updateEnforceAdminUser(accounts[0].Id, true);
            RubrikEnforceAdminPanelController.updateEnforceAdminUser(accounts[0].Id, true);
        } catch (exception ex) {
            system.assertEquals('Error :: Automated User Registration Approval is already enabled.', ex.getMessage());
        }
    }
    
}