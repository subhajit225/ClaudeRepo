@isTest
public class LMSCourseEnrollmentTriggerHandler_Test {
    public static testmethod void testSetAccreditationC64(){
        test.startTest();
        Account accRec = ShGl_TestFactory.testMethod_PartnerAccount('Test Account');
        List<Contact> lstContact = ShGl_TestFactory.testMethod_PartnerContact(1,accRec);
		List<String> lstTraining = new List<String>();
        lstTraining.add('C64');
        lstTraining.add('C83');
        lstTraining.add('C82');
        lstTraining.add('C66');
        List<DOCEBO1_CO__c> lstTrainignRecord = ShGl_TestFactory.testMethod_createTraining(lstTraining);
        SYstem.debug('lstTrainignRecord**'+lstTrainignRecord);
        List<DOCEBO2_CO__c> lstDocebo = ShGl_TestFactory.testMethod_createDecebo(1,lstTrainignRecord[0],lstContact[0]);
        lstDocebo[0].Contact__c = lstContact[0].id;
        List<DOCEBO2_CO__c> lstDocebo83 = ShGl_TestFactory.testMethod_createDecebo(1,lstTrainignRecord[1],lstContact[0]);
        lstDocebo83[0].Contact__c = lstContact[0].id;        
        Test.stopTest();
    }
    public static testmethod void testSetAccreditationC82(){
        test.startTest();
        Account accRec = ShGl_TestFactory.testMethod_PartnerAccount('Test Account');
        List<Contact> lstContact = ShGl_TestFactory.testMethod_PartnerContact(1,accRec);
        lstContact[0].PSE_Shadow_Completed__c = system.today();
        update lstContact;
		List<String> lstTraining = new List<String>();
        lstTraining.add('C64');
        lstTraining.add('C83');
        lstTraining.add('C82');
        lstTraining.add('C66');
        List<DOCEBO1_CO__c> lstTrainignRecord = ShGl_TestFactory.testMethod_createTraining(lstTraining);
        List<DOCEBO2_CO__c> lstDocebo = ShGl_TestFactory.testMethod_createDecebo(1,lstTrainignRecord[2],lstContact[0]);
        lstDocebo[0].Contact__c = lstContact[0].id;
        List<DOCEBO2_CO__c> lstDocebo66 = ShGl_TestFactory.testMethod_createDecebo(1,lstTrainignRecord[3],lstContact[0]);
        lstDocebo66[0].Contact__c = lstContact[0].id;
        //update lstDocebo;
        Test.stopTest();
    }    
}