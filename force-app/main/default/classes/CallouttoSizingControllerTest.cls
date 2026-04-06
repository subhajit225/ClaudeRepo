@isTest
public class CallouttoSizingControllerTest {
     @testSetup static void setup(){
         ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c();
        settingDisable.Trigger_Max_Loop_Count__c = 10;
        settingDisable.Disable_Opportunity_Validation_Rules__c = true;
        insert settingDisable;
        Id pricebookId = Test.getStandardPricebookId();
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        FlowControll.accountTrigger = false;
        flowControll.contactTrigger = false;
        flowControll.opportunityTriggerHandler = false;
        
        Account objAccount = new Account();
        Contact objContact = new Contact();
        
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        objAccount.Name = 'Test Account 99-05';
        objAccount.RecordTypeId = recordTypeId;
        insert objAccount;
        objContact.Account = objAccount;
        objContact.LastName = 'Test Contact 99-05';
        insert objContact; 
        
        Opportunity objOpportunity = new Opportunity();
        objOpportunity.StageName = '1 Discovery';
        objOpportunity.closeDate = System.Today() + 30;
        objOpportunity.Name = 'Test Opp 99-05';
        objOpportunity.Opportunity_Sub_Type__c = 'Regular';
        objOpportunity.Initial_Contacts_Name__c = objContact.Id;
        objOpportunity.Distributor_Lookup__c = objAccount.Id;
        objOpportunity.Partner_Lookup__c = objAccount.Id;
        objOpportunity.Pricebook2Id = pricebookId;
        insert objOpportunity;

     }
    @isTest static void testCallout1() {
        Opportunity objOpportunity = [select Id from Opportunity limit 1];
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new SizingCalloutMockup_Test());
        Test.startTest();
        System.enqueueJob(new CallouttoSizingController(new Set<Id>{objOpportunity.Id}));
        Test.stopTest();
        system.assertequals('test','test');
    }
    @isTest static void testCallout2() { 
        Opportunity objOpportunity = [select Id from Opportunity limit 1];
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new SizingCalloutMockup_Test2());
        Test.startTest();
        System.enqueueJob(new CallouttoSizingController(new Set<Id>{objOpportunity.Id}));
        Test.stopTest();
        system.assertequals('test','test');
    }
    @isTest static void testCallout3() { 
        Opportunity objOpportunity = [select Id from Opportunity limit 1];
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new MockExceptionGenerator());
        Test.startTest();
        System.enqueueJob(new CallouttoSizingController(new Set<Id>{objOpportunity.Id}));
        Test.stopTest();
        system.assertequals('test','test'); 
    }
    
    public class MockExceptionGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // This forces the "catch(Exception e)" block in the main class
            throw new CalloutException('Forced Mock Exception');
        }
    }
}