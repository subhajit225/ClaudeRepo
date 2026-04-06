@isTest
public class UpdateMetaDataTest {
    static testMethod void testmethod1() {
        insert new DomainsUpdate__c(Action__c='ADD',Name='test.t',DomainAPI__c='text_te');
        Database.executeBatch(new UpdateMetaData());
        String CRON_EXP = '0 0 0 15 3 ? *';
        String jobId = System.schedule('ScheduleApexClassTest',  CRON_EXP, new UpdateMetaData());

    }
}