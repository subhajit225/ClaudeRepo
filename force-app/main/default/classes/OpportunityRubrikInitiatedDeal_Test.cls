@isTest
public class OpportunityRubrikInitiatedDeal_Test{
    static testmethod void TestMethod1(){
        Opportunity oppObject = TestDataFactory.getOpportunity();
        /*
        Account testAccount = new Account();
        testAccount.Name='Test Account' ;
        insert testAccount;
        */
        Contact cont = new Contact();
        cont.FirstName='Test';
        cont.LastName='Test';
        cont.Email ='test@testrubrik.com';
        cont.Accountid= oppObject.AccountId;
        cont.LeadSource='Channel';
        insert cont;
        
        TriggerControl__c setting = new TriggerControl__c();
        setting.Name = 'Opportunity';
        setting.DisableTrigger__c = False;
        insert setting;
        
        oppObject.CloseDate=System.Today().addDays(90);
        oppObject.Initial_Contacts_Name__c =cont.Id;
        insert oppObject;
        Test.StartTest(); 
        
        
        PageReference pageRef = Page.Opp_RubrikInitiatedDealPage; // Adding VF page Name here
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id', oppObject.Id);//for page reference
        pageRef.getParameters().put('type', 'JID');//for page reference
        ApexPages.StandardController sc = new ApexPages.standardController(oppObject);
        OpportunityRubrikInitiatedDeal  controller = new OpportunityRubrikInitiatedDeal(sc);
        controller.saveOpp();
        pageRef.getParameters().put('type', 'RID');//for page reference
        ApexPages.StandardController sc2 = new ApexPages.standardController(oppObject);
        OpportunityRubrikInitiatedDeal  controller2 = new OpportunityRubrikInitiatedDeal(sc2);
        controller2.saveOpp();
        Test.StopTest(); 
     }

}