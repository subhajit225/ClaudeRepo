@isTest
private class BatchUpdateContactAgreementTest {

    @testSetup
    static void setup() {

        insert new TriggerControl__c(Name = 'CampaignMember', DisableTrigger__c = true);

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact ct1 = new Contact(LastName = 'test1', AccountId = acc.Id, Email = 'test1.BatchUpdateContactAgreementTest@testdomain.com');
        Contact ct2 = new Contact(LastName = 'test2', AccountId = acc.Id, Email = 'test2.BatchUpdateContactAgreementTest@testdomain.com');
        Contact ct3 = new Contact(LastName = 'test3', AccountId = acc.Id, Email = 'test3.BatchUpdateContactAgreementTest@testdomain.com');
        Contact ct4 = new Contact(LastName = 'test4', AccountId = acc.Id, Email = 'test4.BatchUpdateContactAgreementTest@testdomain.com');
        insert new List<Contact>{ct1, ct2, ct3, ct4};

        Campaign c1 = TestDataFactory.insertCampaign('CampaignTest1');
        insert c1;

        CampaignMemberStatus cms1 = new CampaignMemberStatus(
            CampaignId = c1.Id,
            Label = 'Filled-out Form',
            SortOrder = 4,
            IsDefault = false,
            HasResponded = true
        );
        CampaignMemberStatus cms2 = new CampaignMemberStatus(
            CampaignId = c1.Id,
            Label = 'Negative',
            SortOrder = 3,
            IsDefault = true,
            HasResponded = false
        );
        insert new List<CampaignMemberStatus>{cms1, cms2};

        CampaignMember cm11 = new CampaignMember(CampaignId = c1.Id, ContactId = ct1.Id, Status = 'Filled-out Form');
        CampaignMember cm12 = new CampaignMember(CampaignId = c1.Id, ContactId = ct2.Id, Status = 'Negative');
        CampaignMember cm13 = new CampaignMember(CampaignId = c1.Id, ContactId = ct3.Id, Status = 'Sent');
        CampaignMember cm14 = new CampaignMember(CampaignId = c1.Id, ContactId = ct4.Id, Status = 'Responded');

        insert new List<CampaignMember>{cm11, cm12, cm13, cm14};
    }

    @isTest
	static void testBatch() {

        List<Contact> contactsBefore = [SELECT LastName, Try_Buy_Agreement__c FROM Contact];
        System.assertEquals(4, contactsBefore.size());
        for(Contact c : contactsBefore) {
            System.assertEquals(false, c.Try_Buy_Agreement__c);
        }

        Test.startTest();
            BatchUpdateContactAgreement bInstance = new BatchUpdateContactAgreement();
            DataBase.executeBatch(bInstance);
        Test.stopTest();

        List<Contact> contactsAfter = [SELECT LastName, Try_Buy_Agreement__c FROM Contact];
        System.assertEquals(4, contactsAfter.size());
        for(Contact c : contactsAfter) {
            if(c.LastName == 'test1') {
                System.assertEquals(true, c.Try_Buy_Agreement__c);
            }
            else {
                System.assertEquals(false, c.Try_Buy_Agreement__c);
            }
        }
	}

    @isTest
    static void testScheduler() {

        List<Contact> contactsBefore = [SELECT LastName, Try_Buy_Agreement__c FROM Contact];
        System.assertEquals(4, contactsBefore.size());
        for(Contact c : contactsBefore) {
            System.assertEquals(false, c.Try_Buy_Agreement__c);
        }

        Test.startTest();
            BatchUpdateContactAgreement bInstance = new BatchUpdateContactAgreement();
            String cronExpr = '0 0 0 15 3 ? 2022';
            String jobId = System.schedule('BatchUpdateContactAgreement', cronExpr, bInstance);
            bInstance.execute(null);
        Test.stopTest();

        List<Contact> contactsAfter = [SELECT LastName, Try_Buy_Agreement__c FROM Contact];
        System.assertEquals(4, contactsAfter.size());
        for(Contact c : contactsAfter) {
            if(c.LastName == 'test1') {
                System.assertEquals(true, c.Try_Buy_Agreement__c);
            }
            else {
                System.assertEquals(false, c.Try_Buy_Agreement__c);
            }
        }
    }


}