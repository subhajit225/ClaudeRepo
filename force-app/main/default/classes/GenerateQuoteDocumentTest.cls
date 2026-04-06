@isTest
private class GenerateQuoteDocumentTest {

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
        
        Account objAccount = TestDataFactory.getAccount();
        insert objAccount;
        
        Opportunity objOpportunity = TestDataFactory.getOpportunity(objAccount);
        objOpportunity.Opportunity_Sub_Type__c = 'Regular';
        insert objOpportunity;
        
        Contact objContact = TestDataFactory.getContact(objAccount);
        objContact.FirstName = '';
        objContact.LastName = System.Label.Dummy_Contact_Name;
        insert objContact;
      
        List<SBQQ__Quote__c> listQuote = TestDataFactory.getQuotes(new Set<Id>{objOpportunity.Id}, 1);
        insert listQuote;
        
        for (SBQQ__Quote__c objQuote : listQuote) {
            objQuote.SBQQ__Primary__c = TRUE;
            objQuote.Generate_Document__c = TRUE;
            objQuote.SBQQ__QuoteTemplateId__c = '';
        }
        update listQuote;
    }
    
    @isTest
    static void autoGenerateQuoteDocumentTest() {
        Test.startTest();
        
        //Database.executeBatch(new GenerateQuoteDocumentBatch());
        System.schedule('UpdateQuoteForDoc', '0 0 * * * ?', new GenerateQuoteDocumentScheduler());
        
        Test.stopTest();
    }
}