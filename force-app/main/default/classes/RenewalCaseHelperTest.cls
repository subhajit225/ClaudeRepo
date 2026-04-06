/**
 * @description class RenewalCaseHelper {
 */
@isTest
public class RenewalCaseHelperTest {
    
    static TriggerControl__c getTriggerControl(){
        ShGl_DisableBusinessLogic__c disableLogic= new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Triggers__c = true, Disable_Order_Old_Trigger__c = true, Disable_OrderItem_Old_Trigger__c = true, Disable_Account_Triggers__c = true);
        disableLogic.Name = 'System Administrator';   
        disableLogic.Disable_Opportunity_Validation_Rules__c = TRUE; 
        disableLogic.Disable_Opportunity_Triggers__c = true;
        insert disableLogic;
        TriggerControl__c tc= new TriggerControl__c();
        tc.Name='Opportunity';
        tc.DisableTrigger__c = true;
        return tc;
    }
    static TriggerControl__c getTriggerControlCase(){
        TriggerControl__c tc=new TriggerControl__c();
        tc.Name='Renewal Case';
        tc.DisableTrigger__c = false ;
        return tc;
    }
   
    static testMethod void csCreationTest(){
        
        TriggerControl__c triggerCntlr= getTriggerControl();
        insert triggerCntlr;
        insert getTriggerControlCase();
        
        Account ACCT = new Account(Name='Test Account', Phone='123-456-7890', AccountNumber='Test',
                                   BillingStreet = '123 street', BillingCity = 'Santa Clara', BillingState = 'California', BillingPostalCode = '95050', BillingCountry = 'United States');
        insert ACCT;
        QuoteTriggerHandler.disableQuoteTrigger = true;
        Opportunity tempOpp= new Opportunity(name='Temp Opp', OwnerID=UserInfo.getUserId(),accountId=ACCT.id,stagename='Approved',Amount=1000,Lead_Email_Hidden__c='test@email.com',closeDate=Date.today());
        insert tempOpp;
        
        ServiceContract testContract = new ServiceContract();
        testContract.AccountId = ACCT.id;
        testContract.SBQQSC__RenewalOpportunityRecordTypeId__c = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId();
        testContract.Name = 'Case Instrument Contract Test- Contract';
        testContract.StartDate = System.today()+10;
        testContract.Term = 24;
        testContract.SBQQSC__RenewalTerm__c = 24;
        testContract.EndDate = System.today()+365;
        User u = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.RunAs(u){
            insert testContract;
            testContract.SBQQSC__RenewalQuoted__c = true;
            testContract.SBQQSC__Opportunity__c = tempopp.Id;
            update testContract;
        }
        System.assertNotEquals(testContract.SBQQSC__Opportunity__c,testContract.SBQQSC__RenewalOpportunity__c,'Not Matching');
    }
    
    static testMethod void csCreationTest2(){
        
        TriggerControl__c triggerCntlr= getTriggerControl();
        insert triggerCntlr;
        insert getTriggerControlCase();
        
        Account ACCT = new Account(Name='Test Account', Phone='123-456-7890', AccountNumber='Test',
                                   BillingStreet = '123 street', BillingCity = 'Santa Clara', BillingState = 'California', BillingPostalCode = '95050', BillingCountry = 'United States');
        insert ACCT;
        QuoteTriggerHandler.disableQuoteTrigger = true;
        Opportunity tempOpp= new Opportunity(name='Temp Opp', OwnerID=UserInfo.getUserId(),accountId=ACCT.id,stagename='Approved',Amount=1000,Lead_Email_Hidden__c='test@email.com',closeDate=Date.today());
        insert tempOpp;
        
        ServiceContract testContract = new ServiceContract();
        testContract.AccountId = ACCT.id;
        testContract.SBQQSC__RenewalOpportunityRecordTypeId__c = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId();
        testContract.Name = 'Case Instrument Contract Test- Contract';
        testContract.StartDate = System.today()+10;
        testContract.Term = 24;
        testContract.SBQQSC__RenewalTerm__c = 24;
        testContract.EndDate = System.today()+365;
        testContract.SBQQSC__RenewalOpportunity__c = tempopp.Id;
        testContract.SBQQSC__Opportunity__c = tempopp.Id;
        User u = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.RunAs(u){
            insert testContract;
            testContract.SBQQSC__RenewalQuoted__c = true;
            update testContract;
        }
       
        System.assertEquals(testContract.SBQQSC__Opportunity__c,testContract.SBQQSC__RenewalOpportunity__c);

    }
}