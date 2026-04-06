@isTest
public class UnlockControllerTest {
    @isTest
    static void testUnlock(){
        CCR__c ccr = new CCR__c();
        insert ccr;
        UnlockController.unlockCCR(ccr.Id);
        
        
        ccr.User__c = 'Pending';
        //ccr.Justifications__c = 'AE/SE/SDR mapping change';
        ccr.RecordTypeId = Schema.SObjectType.CCR__c.getRecordTypeInfosByDeveloperName().get('Partner_Claim_Form').getRecordTypeId();
        update ccr;
        
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();          
        req.setComments('Submitting approval request using Trigger');        
        req.setObjectId(ccr.id);
        Approval.ProcessResult result = Approval.process(req); 
        
        Approval.LockResult DemoList = Approval.lock(ccr, false);
        UnlockController.unlockCCR(ccr.Id);
    }
}