@isTest
public inherited sharing class PartnerAccredRollUpCorrectionTest {
    @TestSetup
    static void makeData(){
        //create accounts
        Id partnerDistributorRTId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer/Prospect').getRecordTypeId();
        Map<String, Object> dynamicFieldsMap = new Map<String, Object>{
                                                    'RecordTypeId' => partnerDistributorRTId
                                                };
        List<Account> newActList = (List<Account>) ShGl_TestFactory.createSObjectList(new Account(), 1, dynamicFieldsMap);
        insert newActList;
        //create contacts 
        List<Contact> contacts = new List<Contact>();
        dynamicFieldsMap = new Map<String, Object>{
            'AccountId' => newActList[0].Id,
            'RSP_Accredited__c' => Date.today().addDays(-10),
            'RSP_Expiration__c' => Date.today().addDays(10),
            'RSSE_Accredited__c' => Date.today().addDays(-10),
            'RSSE_Expiration__c' => Date.today().addDays(-2)
        };
        List<Contact> tempConList = (List<Contact>) ShGl_TestFactory.createSObjectList(new Contact(), 50, dynamicFieldsMap); //50 RSP valid, all RSSP expired
        contacts.addAll(tempConList);
        dynamicFieldsMap = new Map<String, Object>{
            'AccountId' => newActList[0].Id,
            'RSP_Accredited__c' => Date.today().addDays(-10),
            'RSP_Expiration__c' => Date.today().addDays(-5)
        };
        tempConList = (List<Contact>) ShGl_TestFactory.createSObjectList(new Contact(), 10, dynamicFieldsMap); //10 RSP expired
        contacts.addAll(tempConList);
        insert contacts;
    }
    @istest static void testBatch(){
        Test.startTest();
            Database.executeBatch(new PartnerAccredRollUpCorrection(), 200);
        Test.stopTest();
        Account testAccount = [SELECT Id, RSP_Accredited__c, RSSE_Accredited__c FROM Account LIMIT 1];
        System.assertEquals(50, testAccount.RSP_Accredited__c);
        System.assertEquals(0, testAccount.RSSE_Accredited__c);
    }
    @isTest static void testScheduler() {
        Test.startTest();
            String jobId = System.schedule('Test Partner Account Accreditations', '0 0 0 ? * FRI', new PartnerAccredRollUpCorrection());
        Test.stopTest();
        System.assert(jobId != null);
    }    
}