/**
    @Created By   : Santosh Gore
    @Class Name   : CCRAndPOCPendingApprovalControllerTest 
    @Description  : SAL-1275 Test Class for CCRAndPOCPendingApprovalController
*/
@isTest
private Class CCRAndPOCPendingApprovalControllerTest {
  
    @testSetup static void createCCRdata() {
        CCR__c ccr = new CCR__c ();
        ccr.RecordTypeId = Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Partner Claim Form').getRecordTypeId(); 
        ccr.Affective_Person__c = UserInfo.getUserId();   
        ccr.User__c = 'Pending';
        ccr.CCR_Type__c = 'Marketing SPIFF';
        //ccr.Justifications__c = 'Request Draw';
        ccr.Comment__c = 'test';
        ccr.Effective_Date__c=System.Today();
        ccr.Effective_End_Date__c = System.Today().addDays(90);
        insert ccr;
        
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('test Com');
        req.setObjectId(ccr.Id);
        try {
            Approval.ProcessResult result = Approval.process(req);
        }catch(Exception ex) {}
        
    }
    
    @isTest static void getAllDataTM1() {
        
        Test.startTest();
        CCRAndPOCPendingApprovalController.getCCRAndPOCPendingApprovalList('All');
        CCRAndPOCPendingApprovalController.getCCRAndPOCPendingApprovalList('POC__c');
        CCRAndPOCPendingApprovalController.getAllActorId(new Set<Id>{Userinfo.getUserId()});
        Test.stopTest();
        
    }
    
     @isTest static void getAllDataTM2() {
        Test.startTest();
        
        CCRAndPOCPendingApprovalController.pendingApprovalWrapper pendingApprovalRec = new CCRAndPOCPendingApprovalController.pendingApprovalWrapper();
        pendingApprovalRec.Status = 'status';
        pendingApprovalRec.RecordName = 'RecName';
        pendingApprovalRec.RecordId = 'RecId';
        pendingApprovalRec.RecordLink = 'RecLink';
        pendingApprovalRec.RecordObject = 'RecObject';
        pendingApprovalRec.AssignedToName = 'AssignName';
        pendingApprovalRec.ApproverName = 'ApproveName';
        pendingApprovalRec.CreatedDate = 'Date';
        pendingApprovalRec.approveRejectLink ='aprejLink';
        pendingApprovalRec.actionLabel = 'Approve / Reject';
        pendingApprovalRec.reassignLink = 'REASSIGN Link';
        pendingApprovalRec.reassignLabel = 'Reassign';
        Test.stopTest();
    }


}