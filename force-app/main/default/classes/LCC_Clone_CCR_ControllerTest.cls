@isTest
public class LCC_Clone_CCR_ControllerTest {
    static testMethod void testInsertCCR(){
        CCR__c ccr = new CCR__c();
        test.startTest();
        LCC_Clone_CCR_Controller.saveRecord(ccr);
        LCC_Clone_CCR_Controller.getRecord(ccr.Id);
        LCC_Clone_CCR_Controller.getsectionVisibility();
        test.stopTest();
    }
}