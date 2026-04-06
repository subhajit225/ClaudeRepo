@isTest
public class RCDMTExtensionLoadUtilityHelperTest {

 @TestSetup
    static void setupData() {
        insert new ShGl_DisableBusinessLogic__c(
            SetupOwnerId = UserInfo.getUserId(),
            Disable_Opportunity_Validation_Rules__c = true,
            Disable_Opportunity_Email_Alerts__c = true,
            Disable_SBQQ_QuoteLine_Validation_Rules__c = true
        );
        
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Partner/Distributor')
            .getRecordTypeId();
        Account acct = new Account(
            Name = 'testAccount',
            RecordTypeId = partnerRecordTypeId,
            Account_Deal_Desk_Notes__c = 'Test Notes'
        );
        Account acc = new Account(Name = 'testAccount1');
        insert new List<Account>{ acct, acc };
            
            Opportunity oppr = TestDataFactory.getOpportunity(acct);
            oppr.stagename = '7 Closed Won';
        insert oppr;
        
        
    }

@isTest
    static void testSUCOntrlMethod(){  
      Test.startTest();
      
      Account acc = [Select id from Account limit 1];
      
      List<Quote_and_Order_Staging__c> qslst = new List<Quote_and_Order_Staging__c>();
      List<Quote_and_Order_Staging__c> qslst2 = new List<Quote_and_Order_Staging__c>();

      Quote_and_Order_Staging__c qos = new Quote_and_Order_Staging__c();
      qos.Account_OM__c = acc.Id;
      qos.Process_Status_CPQ__c = 'Ready';
      qos.Process_Status_OM__c = 'Ready';
      qos.Process_Type__c = 'Initial RCDM-T Processing';
      qslst.add(qos);
      
      Quote_and_Order_Staging__c qos1 = new Quote_and_Order_Staging__c();
      qos.Account_OM__c = acc.Id;
      qos1.Process_Status_CPQ__c = 'Ready';
      qos1.Process_Status_OM__c = 'Ready';
      qos1.Process_Type__c = 'QLI & Order Processing';

     qslst2.add(qos1);
     insert qslst;
     insert qslst2;
     
     RCDMTExtensionLoadUtilityHelper.cloneOpportunityRecord(qslst);
     RCDMTExtensionLoadUtilityHelper.updateStagingReadyForApproval(qslst);
     RCDMTExtensionLoadUtilityHelper.updateQuoteToCalculate(qslst,1);
     RCDMTExtensionLoadUtilityHelper.updateOpptyToOrdered(qslst);
     RCDMTExtensionLoadUtilityHelper.autoApproveQuotes(qslst);
     RCDMTExtensionLoadUtilityHelper.createQuoteLineRecords(qslst2);
     RCDMTExtensionLoadUtilityHelper.updateOpptyStage(qslst);
     RCDMTExtensionLoadUtilityHelper.updateStagingReadyForApprovalfortst();
      Test.StopTest();
    }  
}