@isTest
public class PSEscalationTrigger_Test {
    @TestSetup
    static void makeData(){
        List<WorkflowTriggerBypass__c> wtList = new List<WorkflowTriggerBypass__c>();
        WorkflowTriggerBypass__c wt = new WorkflowTriggerBypass__c(name='leadReassignOnBusinessUnitChange',ByPassTrigger__c=false);
        wtList.add(wt);
        WorkflowTriggerBypass__c wt1 = new WorkflowTriggerBypass__c(name='cnsFirstAttemptUpdateLeadStatus',ByPassTrigger__c=false);
        wtList.add(wt1);
        WorkflowTriggerBypass__c wt2 = new WorkflowTriggerBypass__c(name='CreateSDRLedMeetingTask',ByPassTrigger__c=false);
        wtList.add(wt2);
        WorkflowTriggerBypass__c wt3 = new WorkflowTriggerBypass__c(name='updateLastOwnershipUpdateDate',ByPassTrigger__c=false);
        wtList.add(wt3);
        WorkflowTriggerBypass__c wt4 = new WorkflowTriggerBypass__c(name='updateOpportunitySource',ByPassTrigger__c=false);
        wtList.add(wt4);
        WorkflowTriggerBypass__c wt5 = new WorkflowTriggerBypass__c(name='salesOperationsAssignAccountSIC',ByPassTrigger__c=false);
        wtList.add(wt5);
        WorkflowTriggerBypass__c wt6 = new WorkflowTriggerBypass__c(name='salesOperationsSetEUResident',ByPassTrigger__c=false);
        wtList.add(wt6);
        insert wtList;

        CountryWithCode__c cc = new CountryWithCode__c(Code__c='US',Name='United States');
        insert cc;

        String netAppName = Label.NetApp_Account_Names.split(';')[0];
        Account acc=TestDataFactory.getAccount();
        acc.Name = netAppName;
        insert acc;

        List<Deal_Registration__c> dealList = new List<Deal_Registration__c>();
        Deal_Registration__c deal=TestDataFactory.getDealRegistration();
        deal.Deal_Registration_Status__c = 'Submitted';
        deal.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
        deal.Distributor__c = acc.Id;
        dealList.add(deal);

        Deal_Registration__c deal1=TestDataFactory.getDealRegistration();
        deal1.Deal_Registration_Status__c = 'Submitted';
        deal1.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByDeveloperName().get('Service_Delivery_Partner').getRecordTypeId();
        deal1.Distributor__c = acc.Id;
        dealList.add(deal1);

        Deal_Registration__c deal2=TestDataFactory.getDealRegistration();
        deal2.Deal_Registration_Status__c = 'Submitted';
        deal2.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
        deal2.Distributor__c = acc.Id;
        dealList.add(deal2);

        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        Test.startTest();
        insert dealList;
        Test.stopTest();
    }
    @isTest static void rejectRecord(){
        Id recId = createPsEscalationRec();
        sendForApproval(recId);

        DR_PS_Escalation__c p = new DR_PS_Escalation__c();
        p.Id = recId;
        p.Status__c = 'Rejected';
        p.Rejection_Reason__c = 'test';
        Test.startTest();
        update p;
        Test.stopTest();
    }
    @isTest static void removeFromApproval(){
        Id recId = createPsEscalationRec();
        sendForApproval(recId);

        DR_PS_Escalation__c p = new DR_PS_Escalation__c();
        p.Id = recId;
        p.Status__c = 'More Info Required';
        Test.startTest();
        update p;
        Test.stopTest();
    }

    public static Id createPsEscalationRec(){
        Deal_Registration__c deal = [SELECT Id,Partner_Lookup__c,Opportunity__c,Company_Name__c,Opportunity_Stage__c,PID_Meeting_Task__c,OwnerId,Theatre_VP__c FROM Deal_Registration__c LIMIT 1];
        DR_PS_Escalation__c p = new DR_PS_Escalation__c();
        p.Deal_Registration__c = deal.Id;
        p.Partner_Lookup__c = deal.Partner_Lookup__c;
        p.Team__c = 'AMER';
        p.Escalation_Type__c = 'Federal';
        p.Existing_Opportunity__c = deal.Opportunity__c;
        p.Deal_Initiated_Type__c = 'Partner Sourced New Logo (PSNL)';
        p.Escalation_Reason__c = 'test';
        p.End_User_Account__c = deal.Company_Name__c;
        p.Opportunity_Stage__c = deal.Opportunity_Stage__c;
        p.Opportunity_ACV__c = deal.PID_Meeting_Task__c;
        p.Status__c = 'Submitted';
        p.Deal_Reg_AE__c = deal.OwnerId;
        p.RVP__c = deal.Theatre_VP__c;
        insert p;
        return p.Id;
    }

    public static void sendForApproval(Id recId){
        Approval.ProcessSubmitRequest testapproval = new Approval.ProcessSubmitRequest();
        testapproval.setComments('Submitting request for approval');
        testapproval.setObjectId(recId);
        Approval.process(testapproval);
    }

    @isTest
     static void onApprovalActionsTest(){
        Id precId = createPsEscalationRec();

        Test.startTest();
        DR_PS_Escalation__c p = new DR_PS_Escalation__c();
        p.Id = precId;
        p.Status__c = 'Approved';
        update p;
        Test.stopTest();
    }

    @isTest
     static void afterApprovalActionsTest(){
        Deal_Registration__c deal = [SELECT Id,Partner_Lookup__c,Opportunity__c,Company_Name__c,Opportunity_Stage__c,PID_Meeting_Task__c,OwnerId,Theatre_VP__c FROM Deal_Registration__c LIMIT 1];
        DR_PS_Escalation__c p = new DR_PS_Escalation__c();
        p.Deal_Registration__c = deal.Id;
        p.Partner_Lookup__c = deal.Partner_Lookup__c;
        p.Team__c = 'AMER';
        p.Escalation_Type__c = 'Split Opp';
        p.Existing_Opportunity__c = deal.Opportunity__c;
        p.New_Opportunity__c = deal.Opportunity__c;
        p.Deal_Initiated_Type__c = 'Partner Sourced New Logo (PSNL)';
        p.Escalation_Reason__c = 'test';
        p.End_User_Account__c = deal.Company_Name__c;
        p.Opportunity_Stage__c = deal.Opportunity_Stage__c;
        p.Opportunity_ACV__c = deal.PID_Meeting_Task__c;
        p.Status__c = 'Submitted';
        p.Deal_Reg_AE__c = deal.OwnerId;
        p.RVP__c = deal.Theatre_VP__c;
        insert p;

        Test.startTest();
        p.Status__c = 'Approved';
        update p;
        Test.stopTest();
    }

    @isTest
    static void afterApprovalActionsTest1(){
        string ResellerRecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
        Deal_Registration__c deal = [SELECT Id,Partner_Lookup__c,Opportunity__c,Company_Name__c,Opportunity_Stage__c,PID_Meeting_Task__c,OwnerId,Theatre_VP__c FROM Deal_Registration__c Where RecordTypeId =: ResellerRecordTypeId LIMIT 1];
        DR_PS_Escalation__c p = new DR_PS_Escalation__c();
        p.Deal_Registration__c = deal.Id;
        p.Partner_Lookup__c = deal.Partner_Lookup__c;
        p.Team__c = 'AMER';
        p.Escalation_Type__c = 'Dormant Opp';
        p.Existing_Opportunity__c = deal.Opportunity__c;
        p.Deal_Initiated_Type__c = 'Partner Sourced New Logo (PSNL)';
        p.Escalation_Reason__c = 'test';
        p.End_User_Account__c = deal.Company_Name__c;
        p.Opportunity_Stage__c = deal.Opportunity_Stage__c;
        p.Opportunity_ACV__c = deal.PID_Meeting_Task__c;
        p.Status__c = 'Submitted';
        p.Deal_Reg_AE__c = deal.OwnerId;
        p.RVP__c = deal.Theatre_VP__c;
        insert p;

        Test.startTest();
        p.Status__c = 'Approved';
        update p;
        Test.stopTest();
   }

   @isTest
    static void afterApprovalActionsTest3(){
        String ServiceDeliveryRecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByDeveloperName().get('Service_Delivery_Partner').getRecordTypeId();
        Deal_Registration__c deal = [SELECT Id,Partner_Lookup__c,Opportunity__c,Company_Name__c,Opportunity_Stage__c,PID_Meeting_Task__c,OwnerId,Theatre_VP__c FROM Deal_Registration__c WHERE RecordTypeId =: ServiceDeliveryRecordTypeId LIMIT 1];
        DR_PS_Escalation__c p = new DR_PS_Escalation__c();
        p.Deal_Registration__c = deal.Id;
        p.Partner_Lookup__c = deal.Partner_Lookup__c;
        p.Team__c = 'AMER';
        p.Escalation_Type__c = 'Split Opp';
        p.Existing_Opportunity__c = deal.Opportunity__c;
        p.New_Opportunity__c = deal.Opportunity__c;
        p.Deal_Initiated_Type__c = 'Partner Sourced Expand';
        p.Escalation_Reason__c = 'test';
        p.End_User_Account__c = deal.Company_Name__c;
        p.Opportunity_Stage__c = deal.Opportunity_Stage__c;
        p.Opportunity_ACV__c = deal.PID_Meeting_Task__c;
        p.Status__c = 'Submitted';
        p.Deal_Reg_AE__c = deal.OwnerId;
        p.RVP__c = deal.Theatre_VP__c;
        insert p;

        Test.startTest();
        p.Status__c = 'Approved';
        update p;
        Test.stopTest();
   }


    @isTest
    static void testMethod2() {
        Test.startTest();
        flowControll.disableAllTriggers();
        Test.stopTest();
    }
}