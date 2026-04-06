@isTest
public class OpportunityMergeController_Test {
    
    static TriggerControl__c getTriggerControl(){
        TriggerControl__c tc= new TriggerControl__c();
        tc.Name='Opportunity';
        tc.DisableTrigger__c=true;
        return tc;
    }
    
    static testMethod void opportunityMergeTest(){
        
        TriggerControl__c triggerCntlr= getTriggerControl();
        insert triggerCntlr;
        
        Account acc= new Account(name='Test Account');
        insert Acc;
        
        Opportunity sourceOpp= new Opportunity(name='Source Opp',accountId=acc.id,stagename='Approved',Amount=1000,Lead_Email_Hidden__c='test@email.com',closeDate=Date.today());
        insert sourceOpp;
        Opportunity targetOpp= new Opportunity(name='Target Opp',accountId=acc.id,stagename='Approved',Amount=1000,Lead_Email_Hidden__c='test@email.com',closeDate=Date.today());
        insert targetOpp;
        
        Test.setCurrentPageReference(new PageReference('Page.OpportunityMergeVFP')); 
		System.currentPageReference().getParameters().put('Id', sourceOpp.Id);
        System.currentPageReference().getParameters().put('oppId', targetOpp.Id);
        ApexPages.StandardController stdContlr = new ApexPages.StandardController(sourceOpp);
        OpportunityMergeController test_Contlr = new OpportunityMergeController();
        test_Contlr.jsonHidden = '{}';
        PageReference cpyRef = test_Contlr.CopyValues();
        PageReference cnclRef = test_Contlr.Cancel();
        
        Map<String,String> apiLabels= test_Contlr.getApiLabel();
        List<Opportunity> srcOpp= test_Contlr.getSourceOpp();
        List<Opportunity> trgtOpp= test_Contlr.getTargetOpp();
        test_Contlr.tick = true;
        test_Contlr.untick = true;      
    }

}