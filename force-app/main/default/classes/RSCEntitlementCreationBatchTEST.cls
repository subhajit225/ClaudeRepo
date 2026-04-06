@isTest
public class RSCEntitlementCreationBatchTEST {
    @TestSetUp
    static void createdata(){
        TriggerControl__c cs = new TriggerControl__c(Name = 'Entitlement', DisableTrigger__c = true);
        insert cs;
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account acc = new Account();
        acc.name = 'test acc';
        acc.RecordTypeId = devRecordTypeId;
        acc.Type = 'Customer';     
        insert acc;
        Entitlement entRec = new Entitlement();
        entRec.StartDate = date.today();
        entRec.EndDate = date.today().addDays(60);
        entRec.AccountId = acc.id;
        entRec.Type = 'Phone Support';
        entRec.Name = 'RSC test';
        insert entRec;
        
    }
    @isTest
    static void testBatch(){
        test.startTest();
        RSCEntitlementCreationBatch bat = new RSCEntitlementCreationBatch(true);
        database.executeBatch(bat);
        test.stopTest();
    }
    @isTest
    static void testSchedule(){
        test.startTest();
        String schcron = '0 0 23 * * ?';
        RSCEntitlementCreationBatch schd1 = new RSCEntitlementCreationBatch(false);
        system.schedule('job1', schcron, schd1	);
        test.stopTest();
    }
}