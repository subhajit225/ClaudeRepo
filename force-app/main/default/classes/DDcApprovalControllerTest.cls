@isTest
private class DDcApprovalControllerTest {
    
    static testMethod void testApprovals(){
   Test.startTest();
   
   PageReference pageRef = Page.PreviewApproval;
   Test.setCurrentPage(pageRef);
   
   Account objAccount = new Account();
        Contact objContact = new Contact();
        
        objAccount.Name = 'Test Account 26-05';
        objAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        insert objAccount;
        
        objContact.Account = objAccount;
        objContact.LastName = 'Test Contact 22-05';
        insert objContact; 
        Opportunity objOpportunity = new Opportunity();
        objOpportunity.StageName = '1 Discovery';
        objOpportunity.Initial_Contacts_Name__c = objContact.Id;
        objOpportunity.Distributor_Lookup__c = objAccount.Id;
        objOpportunity.closeDate = System.Today() + 16;
        objOpportunity.Name = 'Test Opp 31-05';
        objOpportunity.Opportunity_Sub_Type__c = 'Regular';
        objOpportunity.Partner_Lookup__c = objAccount.Id;
        
        insert objOpportunity;
        
        Deal_Desk_Case__c ddCase = new Deal_Desk_Case__c();
        ddCase.Deal_Desk_Team__c = 'Deal Structuring';
        ddCase.ApprovalStatus__c = 'Approved';
        ddCase.Amount_Conditional__c = 100;
        ddCase.Request_Type__c = 'General Inquiry';
        ddCase.Request_Sub_Type__c = 'Below Minimum Term';
        ddCase.Request_Status__c = 'Draft';
        ddCase.Business_Justification__c = 'minimum characters';
        ddCase.ETM_Theatre__c = 'EMEA';
        ddCase.Opportunity__c = objOpportunity.Id;
        ddCase.ETM_Area__c = 'MAJORS';
        ddCase.ETM_Region__c = 'ENT-SOUTHEAST-N';
        insert ddCase; 
   
   ApexPages.StandardController sc = new ApexPages.StandardController(ddCase);
   
   
   DDcApprovalController ddCaseAC = new DDcApprovalController(sc);
   SBAA__Approval__c[] app = ddCaseAC.approvals; 
   Boolean b = ddCaseAC.isReadyForApproval;   
    Test.stopTest();

        System.assert(ddcase.id!=null);
    
 }
}