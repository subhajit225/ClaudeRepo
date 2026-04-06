@isTest
public class renewalDocumentationControllerTest {
    static TriggerControl__c getTriggerControl(){
        TriggerControl__c tc= new TriggerControl__c();
        tc.Name='Opportunity';
        tc.DisableTrigger__c = false;
        return tc;
    }
    
    @TestSetUp
    static void initialDataSetup() {
        SBQQ__QuoteTemplate__c objQuoteTemplate =
            new SBQQ__QuoteTemplate__c(
                Name = 'Quote Document - Elevate',
                SBQQ__DeploymentStatus__c = 'Deployed'
            );
        insert objQuoteTemplate;
        
        SBQQ__TemplateContent__c objTemplateContent =
            new SBQQ__TemplateContent__c(
                Name = 'Template Content Test',
                SBQQ__Type__c = 'HTML',
                SBQQ__Markup__c = '<p>Test Content</p>'
            );
        insert objTemplateContent;
        
        SBQQ__TemplateSection__c objTemplateSection =
            new SBQQ__TemplateSection__c(
                Name = 'Template Section Test',
                SBQQ__Template__c = objQuoteTemplate.Id,
                SBQQ__Content__c = objTemplateContent.Id,
                SBQQ__DisplayOrder__c = 10
            );
        insert objTemplateSection;
    }
    static testMethod void test(){
        TriggerControl__c triggerCntlr= getTriggerControl();
        insert triggerCntlr;
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Opportunity tempOpp= new Opportunity(name='Temp Opp', OwnerID=UserInfo.getUserId(),accountId=acc.id,stagename='Approved',Amount=1000,Lead_Email_Hidden__c='test@email.com',closeDate=Date.today());
        insert tempOpp;
        SBQQ__Quote__c qt = new SBQQ__Quote__c();
        qt.SBQQ__Account__c = acc.Id;
        qt.SBQQ__Opportunity2__c = tempOpp.Id;
        qt.ApprovalStatus__c = 'Approved';
        qt.OpportunitySubType__c = 'MSP';
        insert qt;
        SBQQ__QuoteDocument__c doc = new SBQQ__QuoteDocument__c(
                 SBQQ__Quote__c = qt.Id,
                 SBQQ__Template__c = 'Standard Quote',
            SBQQ__Opportunity__c = tempOpp.Id
                 );
        insert doc;
        Test.startTest();
        renewalDocumentationController.getAttch(tempOpp.Id);
        Test.stopTest();
    }
    static testmethod void test2(){
        TriggerControl__c triggerCntlr= getTriggerControl();
        insert triggerCntlr;
        
        ShGl_DisableBusinessLogic__c sg = new ShGl_DisableBusinessLogic__c();
        sg.Disable_SBQQ_Quote_Validation_Rules__c = true;
        insert sg;
        Account ACCT = new Account(Name='Test Account', Phone='123-456-7890', AccountNumber='Test',
                                   BillingStreet = '123 street', BillingCity = 'Santa Clara', BillingState = 'California', BillingPostalCode = '95050', BillingCountry = 'United States');
        insert ACCT;        
        Opportunity tempOpp= new Opportunity(name='Temp Opp', OwnerID=UserInfo.getUserId(),accountId=ACCT.id,stagename='1 Discovery',Amount=1000,Lead_Email_Hidden__c='test@email.com',closeDate=Date.today());
        insert tempOpp;
        SBQQ__Quote__c qt = new SBQQ__Quote__c();
        qt.SBQQ__Account__c = ACCT.Id;
        qt.SBQQ__Opportunity2__c = tempOpp.Id;
        qt.ApprovalStatus__c = 'Approved';
        qt.OpportunitySubType__c = 'MSP';
        qt.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Approved Quote').getRecordTypeId();
        insert qt;
        ServiceContract testContract = new ServiceContract();
        testContract.AccountId = ACCT.id;
        testContract.SBQQSC__RenewalOpportunityRecordTypeId__c = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId();
        testContract.Name = 'Case Instrument Contract Test- Contract';
        testContract.StartDate = System.today()+10;
        testContract.Term = 24;
        testContract.SBQQSC__RenewalTerm__c = 24;
        testContract.SBQQSC__RenewalOpportunity__c = tempopp.Id;
        insert testContract;
        tempOpp.SBQQ__PrimaryQuote__c = qt.id;
        tempOpp.Alliance_Source_Type_HW__c = 'Alliance Initiated Deal';
        update tempOpp; 
        Case cs = new Case(Priority = 'P4', Platform__c = 'Other', Subject = 'Test', Description = 'Testing', AccountId = ACCT.Id, ServiceContractId = testContract.Id, Opportunity_lookup__c = tempOpp.Id);
        insert cs;
        Attachment attach=new Attachment();     
        attach.Name='Unit Test Attachment';
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        attach.body=bodyBlob;
        attach.parentId=cs.id;
        insert attach;
        Test.startTest();
        List<String> strList = new List<String>();
        strList.add('Partner');
        List<String> ccList = new List<String>();
        ccList.add('Owner');
        ccList.add('ROwner');
        ccList.add('Engineer');
        ccList.add('cOwner');
        
        renewalDocumentationController.sendMail(attach.Id,'',strList,cs.Id,ccList);
        renewalDocumentationController.getDocs(cs.Id);
        GenerateQuoteProposal proposalGenerator = new GenerateQuoteProposal();
        String jobId = proposalGenerator.save(null);
        QuoteProposalModel qm = new QuoteProposalModel();
        qm.language = '12';
        qm.name = 'a';
        qm.outputFormat = 'a';
        qm.paperSize = '1';
        qm.quoteId = qt.id;
        qm.templateId = qt.id;
        Test.stopTest();
    }
}