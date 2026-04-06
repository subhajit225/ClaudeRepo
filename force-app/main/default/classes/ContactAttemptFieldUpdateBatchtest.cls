@isTest
private class ContactAttemptFieldUpdateBatchtest {
    
    static testmethod void test() {
        List<Account> actlst = CustomTestDataFactory.createAccounts(1);
        List<Contact> conlst = CustomTestDataFactory.createContactsNQ(actlst);
        List<Task> tasklst = CustomTestDataFactory.createTaskcontact(3,conlst);
        system.debug('@@@tasklst'+tasklst);
        system.debug('@@@conlst'+conlst);
        
        Test.startTest();
        ContactAttemptFieldUpdateBatch conatmpt = new ContactAttemptFieldUpdateBatch();
        Database.executeBatch(conatmpt);
        Test.stopTest();
    }
}