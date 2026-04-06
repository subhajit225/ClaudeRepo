@isTest
public class CloseCaseControllerPartnerTest {
 @isTest
    static void testGetPartnerRecordTypeId() {
        String recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Partner_Case').getRecordTypeId();
        Test.startTest();
        String partnerRecordTypeId = CloseCaseControllerPartner.getPartnerRecordTypeId();
        Test.stopTest();
        System.assert(partnerRecordTypeId != null);
        System.assertEquals(partnerRecordTypeId, recordTypeId);
    }

}