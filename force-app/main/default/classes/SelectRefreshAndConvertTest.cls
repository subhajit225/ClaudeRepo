/**
 * Test class for SelectConvertOrRefresh Controller
 * Author: Saket Joshi
**/

@isTest
private with sharing class SelectRefreshAndConvertTest {

    @isTest
    static void testPage() {
        Account acct= new Account();
        acct.name='TestAccount01';
        insert acct; 
        Account acct1 = new Account();
        acct1.name='TestAccount011';
        insert acct1; 
        
        Contact ct = new Contact();
        ct.AccountId = acct.id;
        ct.Email='test.user@rurbrik.com'; 
        ct.FirstName='test';
        ct.LastName='TestContact01'; 
        ct.Phone = '8971371780';
        insert ct;
        
        Opportunity op = new Opportunity();
        op.CloseDate=Date.today()+1; 
        op.Deal_Registration_Type__c='Rubrik Sourced';
        op.LeadSource='Channel Marketing';
        op.Polaris_Portal_Contact__c =ct.Id;
        op.Initial_Contacts_Name__c=ct.Id;
        op.Name='TestContact01'; 
        op.StageName='1 Discovery';
        op.Opportunity_Sub_Type__c = 'Regular';
        op.Opportunity_Type__c = 'New Customer';
        op.Installation_Assigned_To__c = 'FE Install';
        op.Partner_Level_Of_Involvement__c = '1.Rubrik initiated, Partner was fulfillment only';
        op.Lost_To_Won_Against__c = 'Actifio';
        op.AccountId =acct.id;
        insert op;

        SBQQ__Quote__c qt = new SBQQ__Quote__c();
        qt.SBQQ__Account__c = acct.Id;
        qt.Opportunity_Program__c = 'Conversion'; 
        qt.ApprovalStatus__c  = 'Approved';
        qt.SBQQ__Primary__c   = false;
        qt.SBQQ__Opportunity2__c = op.Id;
        qt.SBQQ__Status__c  = 'Draft';
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.Task_Products__c  = 'RBK-DISK-RETENTION';
        qt.SBQQ__PriceBook__c = Test.getStandardPricebookId();
        qt.SBQQ__Type__c = 'Renewal+Expansion';
        insert qt; 

        PageReference pgRef = Page.SelectConvertOrRefresh;
        pgRef.getParameters().put('qid', qt.Id);
        Test.setCurrentPage(pgRef);
        Test.startTest();
        
        SelectRefreshAndConvert cntrol = new SelectRefreshAndConvert();
        cntrol.selectedRT = 'Convert';
        cntrol.onChangeFnCall();
        System.assert(cntrol.page1Rendered == true);
        System.assert(cntrol.page2Rendered == false);
        
        cntrol.selectedRT = 'Refresh';
        cntrol.onChangeFnCall();
        System.assert(cntrol.page1Rendered == false);
        System.assert(cntrol.page2Rendered == true);
        
        cntrol.selectedRT = '';
        cntrol.onChangeFnCall();
        System.assert(cntrol.page1Rendered == false);
        System.assert(cntrol.page2Rendered == false);
    }

}