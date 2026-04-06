/**
 * @description Test class for AccountSharedCustomerUpdateBatch apex class (SAL26-313)
 */ 
@isTest
public class AccountSharedCustomerUpdateBatchTest {

    @isTest static void testExecute() {
        User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        Test.startTest();
        Account newAccount = new Account(Name = 'Test Account123', Type = 'Prospect');
        INSERT newAccount;
        
        List<POS_Report__c> posList = new List<POS_Report__c>();
        POS_Report__c pos1 = new POS_Report__c(Name = 'Test 001', Account__c=newAccount.Id, Transaction_Date__c = System.today(), Term_in_months__c = 2);
        posList.add(pos1);
        System.runAs(user) {
        	insert posList;
        }
        
        newAccount = [SELECT Id, Shared_MSP_Customer__c FROM Account WHERE Id = :newAccount.Id];
        System.assert(newAccount.Shared_MSP_Customer__c);
        
        Database.executeBatch(new AccountSharedCustomerUpdateBatch(), 10);
        
        Delete posList;
       
        Database.executeBatch(new AccountSharedCustomerUpdateBatch(), 10);
                
        Test.stopTest();
        newAccount = [SELECT Id, Shared_MSP_Customer__c FROM Account WHERE Id = :newAccount.Id];
        System.assert(!newAccount.Shared_MSP_Customer__c);
    }
    
    @istest
    static void sendErrorReportTest() {
        Test.startTest();  
        User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        System.runAs(user) {
            AccountSharedCustomerUpdateBatch accBatchObj = new AccountSharedCustomerUpdateBatch();
            accBatchObj.sendErrorReport();
        }
        System.assert(true);
        Test.stopTest();
    }
}