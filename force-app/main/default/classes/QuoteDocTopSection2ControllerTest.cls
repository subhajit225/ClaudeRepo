@isTest
public class QuoteDocTopSection2ControllerTest {
    
    @isTest static void myTest() {
        
        // Set up test data
        Account vAccount = new Account();
        vAccount.Name = 'Test Account';
        vAccount.Type='Distributor';
        vAccount.Focused_Partner__c = True;
        vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        insert vAccount;
                 
        Opportunity oppObject = TestDataFactory.getOpportunity();
        oppObject.Partner_Lookup__c = vAccount.Id;
        insert oppObject;
        
        SBQQ__QuoteTemplate__c QuoteTemplate1 = new SBQQ__QuoteTemplate__c();
        QuoteTemplate1.name = 'Test1';
        QuoteTemplate1.SBQQ__CompanyStreet__c = 'Test1';
        QuoteTemplate1.SBQQ__CompanyCity__c = 'Test3';
        QuoteTemplate1.SBQQ__CompanyState__c = 'Test4';
        QuoteTemplate1.SBQQ__CompanyPostalCode__c = '12344';
        QuoteTemplate1.SBQQ__CompanyPhone__c = '234545';
        insert QuoteTemplate1;
        
        List<SBQQ__Quote__c> listQuote = TestDataFactory.getQuotes(new Set<Id>{oppObject.Id}, 1);
        listQuote[0].SBQQ__QuoteTemplateId__c = QuoteTemplate1.Id;
        insert listQuote;
        
        // Set any parameters you need
        ApexPages.currentPage().getParameters().put('qid', listQuote[0].Id);
        
        Test.startTest();
        
        QuoteDocTopSection2Controller controller = new QuoteDocTopSection2Controller();
    }
    
    
    @isTest static void myTest2() {
        
        // Set up test data
        Account vAccount = new Account();
        vAccount.Name = 'Test Account';
        vAccount.Type='Distributor';
        vAccount.Focused_Partner__c = True;
        vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        insert vAccount;
        
         List<Contact> conList = (List<Contact>)ShGl_TestFactory.createSObjectList(new Contact(), 1, null);
        conList[0].AccountId=vAccount.Id;
        conList[0].Latest_UTM_Term__c = 'msft';
        conList[0].Last_UTM_Term_Date__c=system.today()-1;     
       
        insert conList;
                
        Opportunity oppObject = TestDataFactory.getOpportunity();
        oppObject.Partner_Lookup__c = vAccount.Id;
        insert oppObject;
        
        SBQQ__QuoteTemplate__c QuoteTemplate1 = new SBQQ__QuoteTemplate__c();
        QuoteTemplate1.name = 'Test1';
        QuoteTemplate1.SBQQ__CompanyStreet__c = 'Test1';
        QuoteTemplate1.SBQQ__CompanyCity__c = 'Test3';
        QuoteTemplate1.SBQQ__CompanyState__c = 'Test4';
        QuoteTemplate1.SBQQ__CompanyPostalCode__c = '12344';
        QuoteTemplate1.SBQQ__CompanyPhone__c = '234545';
        
        insert QuoteTemplate1;
        
        List<SBQQ__Quote__c> listQuote = TestDataFactory.getQuotes(new Set<Id>{oppObject.Id}, 1);
        listQuote[0].NIPA__c = vAccount.Id;
        listQuote[0].SBQQ__Type__c = 'Renewal';
        insert listQuote;
        
        
        listQuote[0].NIPA__c = vAccount.Id;
        listQuote[0].SBQQ__QuoteTemplateId__c = QuoteTemplate1.Id;
        update listQuote;
        
        // Set any parameters you need
        ApexPages.currentPage().getParameters().put('qid', listQuote[0].Id);
        Test.startTest();
        
        QuoteDocTopSection2Controller controller = new QuoteDocTopSection2Controller();
    }
    
}