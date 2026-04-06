/**
 * @description Test class for ClearRBRKFieldsBatch.
 *              Validates account updates when field is null and ensures proper filtering.
 */
@isTest
private class ClearRBRKFieldsBatchTest {
    /**
     * @description Tests batch execution on accounts where field is null.
     */
    @isTest
    static void testBatchExecution() {
       List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser[0];
        system.runas(listUser[0]){
        // Step 1: Create test Accounts that match the batch query filter
		Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        act.RBRK_NotSummaryVarCustomRuleId__c = null;
          act.RBRK_SummaryVarCustomRuleId__c  = null;
            update act;
        Test.startTest();
        ClearRBRKFieldsBatch batch = new ClearRBRKFieldsBatch();
        Database.executeBatch(batch, 5);
        Test.stopTest();


        List<Account> updated = [
            SELECT Id FROM Account
            WHERE RBRK_NotSummaryVarCustomRuleId__c = :System.Label.AllCustomSVsJSON
        ];
        System.debug(LoggingLevel.INFO, 'Accounts updated by batch: ' + updated.size());
        System.assertEquals(1, updated.size(), 'All accounts should be updated.');
    }
    }
}