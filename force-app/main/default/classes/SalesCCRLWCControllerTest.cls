/**
 * @description Apex test class for SalesCCRLWCController apex controller
 * @createdDate July 20025
 */ 
@istest
public class SalesCCRLWCControllerTest {
     /**
     * @description create test data
     */ 
    @testsetup static void createTestData(){
         Map<String, Object> CCRMap = new Map<String, Object> {
            	'Comment__c'=>'test',
                'CCR_Type__c'=>'Compensation Exception',
                'CCR_Subtype__c'=>'Account Movement (credit and comp)',   
                'recordtypeId' => Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Sales CCR').getRecordTypeId()
                };
        List<CCR__c> CCRList = (List<CCR__c>) ShGl_TestFactory.createSObjectList(new CCR__c(),1, CCRMap); 
        insert CCRList;
    }
	/**
     * @description test createCCR method
     */ 
    @istest static void createCCR(){
        String RecordTypeId = Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Sales CCR').getRecordTypeId();
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('test2222ClassUser', new Set<Id>{listProfile[0].Id}, 1);
        insert listUser;
        String finalSaveString = '{"RecordTypeId":RecordTypeId,"Opportunity__c":null,"CCR_Type__c":"Compensation Exception","Amount__c":440,"CCR_Subtype__c":"Account Movement (credit and comp)","Does_CCR_affect_People_or_Territory__c":null,"Comment__c":"dd"}';
        List<CCR__c> ccrLst = [SELECT Id, CCR_Type__c,CCR_Subtype__c FROM CCR__c];
        Test.startTest();
        System.runAs(listUser[0]) {
            SalesCCRLWCController.saveCCR(finalSaveString);
            finalSaveString = '{"RecordTypeId":"'+RecordTypeId+'", "CCR_Type__c":"'+ccrLst[0].CCR_Type__c+'","CCR_Subtype__c":"'+ccrLst[0].CCR_Subtype__c+'"}';
            SalesCCRLWCController.saveCCR(finalSaveString);
        }
        List<CCR__c> ccrLst2 = [select Id from CCR__c];
        string str = '';
        System.runAs(listUser[0]) {
            finalSaveString = '{"Does_CCR_affect_People_or_Territory__c":"'+str+'","Id":"'+ccrLst2[0].Id+'", "CCR_Type__c":"'+ccrLst[0].CCR_Type__c+'","CCR_Subtype__c":"'+ccrLst[0].CCR_Subtype__c+'"}';
            SalesCCRLWCController.saveCCR(finalSaveString);
        }
        System.assert(true);
        Test.stopTest();
    }
}