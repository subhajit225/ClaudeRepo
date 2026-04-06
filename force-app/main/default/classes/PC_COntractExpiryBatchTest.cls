@isTest
public class PC_COntractExpiryBatchTest {
    @isTest static void testMethod1() {
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account acct = new Account(Name ='test',RecordTypeId = devRecordTypeId,Type = 'Reseller');
        insert acct;

        Contract cont = new Contract(Name='contracttest',Agreement_Type__c = 'Master Agreement',Contract_Status__c='Active',status='Draft',AccountId=acct.Id,startdate=system.today().addDays(-60),ContractTerm=1);
        insert cont;

        PC_ContractExpiryBatch b = new PC_ContractExpiryBatch();
        Database.executeBatch(b,100);
    }
}