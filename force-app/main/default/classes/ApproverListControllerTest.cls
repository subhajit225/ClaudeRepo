@isTest(SeeAllData=true)

public class ApproverListControllerTest {
    
    static testmethod void myTestMethod1() {
        Customer_Registration_Request__c csrList = new Customer_Registration_Request__c();
        insert csrList;
        Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
        app.setObjectId(csrList.id);
        //Approval.ProcessResult result = Approval.process(app);
        Test.StartTest();
        //Call your class method
        Test.StopTest();
        ApproverListController arr = new ApproverListController();
        arr.getApprovalRecordList();
    }
}