@isTest
public class TestSevenYearPayments {

    testMethod static void testMethod_1() {

        Opportunity oppty = TestDataFactory.getOpportunity();
        insert oppty;
        Test.startTest();
        
        SBQQ__Quote__c qt = new SBQQ__Quote__c();
        qt.SBQQ__Account__c = oppty.AccountId;
        qt.SBQQ__Opportunity2__c = oppty.Id;
        qt.Payment_year_1__c = 122323.98989;
        qt.Payment_year_2__c = 122323.98989;
        qt.Payment_year_3__c = 122323.98989;
        qt.Payment_year_4__c = 122323.98989;
        qt.Payment_year_5__c = 122323.98989;
        qt.Payment_year_6__c = 122323.98989;
        qt.Payment_year_7__c = 122323.98989;
        insert qt; 
        
        ApexPages.currentPage().getParameters().put('qid', qt.id);
        SevenYearPayments SYP = new SevenYearPayments();
        SYP.init() ;
        Test.stopTest();
    }

}