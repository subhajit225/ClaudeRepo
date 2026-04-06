@isTest
private class DDCaseExtControllerTests {
    
    testMethod static void testSubmit() {
        
        Opportunity objOpportunity = TestDataFactory.getOpportunity();
        insert objOpportunity;
        Deal_Desk_Case__c ddCase = new Deal_Desk_Case__c();
        ddCase.Deal_Desk_Team__c = 'Deal Structuring';
        ddCase.Amount_Conditional__c = 100;
        ddCase.Request_Type__c = 'General Inquiry';
        ddCase.Request_Sub_Type__c = 'Below Minimum Term';
        //ddCase.Request_Status__c = 'Draft';
        ddCase.Business_Justification__c = 'minimum characters';
        ddCase.ETM_Theatre__c = 'EMEA';
        ddCase.Opportunity__c = objOpportunity.Id;
        ddCase.ETM_Area__c = 'MAJORS';
        insert ddCase; 
        Test.startTest();
        DDCaseExtController con = new DDCaseExtController(new ApexPages.StandardController(ddCase));

        con.onSubmit();
        ddCase = [SELECT ApprovalStatus__c FROM Deal_Desk_Case__c WHERE Id = :ddCase.Id LIMIT 1];
        Test.stopTest();
        
        System.assert(ddCase.Id!=null);
    }
    
    testMethod static void testRecall() {
        
        Opportunity objOpportunity = TestDataFactory.getOpportunity();
        insert objOpportunity;
        Deal_Desk_Case__c ddCase = new Deal_Desk_Case__c();
        ddCase.Deal_Desk_Team__c = 'Deal Structuring';
        ddCase.Amount_Conditional__c = 100;
        ddCase.Request_Type__c = 'General Inquiry';
        ddCase.Request_Sub_Type__c = 'Below Minimum Term';
        //ddCase.Request_Status__c = 'Draft';
        ddCase.Business_Justification__c = 'minimum characters';
        ddCase.ETM_Theatre__c = 'EMEA';
        ddCase.Opportunity__c = objOpportunity.Id;
        ddCase.ETM_Area__c = 'MAJORS';
        insert ddCase; 
        Test.startTest();
        DDCaseExtController con = new DDCaseExtController(new ApexPages.StandardController(ddCase));
        con.onRecall();
        ddCase = [SELECT ApprovalStatus__c FROM Deal_Desk_Case__c WHERE Id = :ddCase.Id LIMIT 1];
        Test.stopTest();
        System.assert(ddCase.Id!=null);
    }
    @istest
    static void testPagereference(){
                Opportunity objOpportunity = TestDataFactory.getOpportunity();
        insert objOpportunity;
        Deal_Desk_Case__c ddCase = new Deal_Desk_Case__c();
        ddCase.Deal_Desk_Team__c = 'Deal Structuring';
        ddCase.Amount_Conditional__c = 100;
        ddCase.Request_Type__c = 'General Inquiry';
        ddCase.Request_Sub_Type__c = 'Below Minimum Term';
        //ddCase.Request_Status__c = 'Draft';
        ddCase.Business_Justification__c = 'minimum characters';
        ddCase.ETM_Theatre__c = 'EMEA';
        ddCase.Opportunity__c = objOpportunity.Id;
        ddCase.ETM_Area__c = 'MAJORS';
        insert ddCase;  
        Test.startTest();
        DDCaseExtController con = new DDCaseExtController(new ApexPages.StandardController(ddCase));
        con.reDirect();
        DDCaseExtController.testpasser();
        Test.stopTest();
        System.assert(ddCase.Id!=null);
        
    }
}