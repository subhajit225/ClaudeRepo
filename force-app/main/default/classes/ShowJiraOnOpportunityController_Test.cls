@isTest(seealldata=true)
public class ShowJiraOnOpportunityController_Test{
    static TriggerControl__c getTriggerControl(){
        TriggerControl__c tc= new TriggerControl__c();
        tc.Name='Opportunity';
        tc.DisableTrigger__c=true;
        return tc;
    }
    static testMethod void testMethod1() 
    {
        TriggerControl__c triggerCntlr= getTriggerControl();
        //insert triggerCntlr;
        
        Account acct = new Account();
        acct.Name='Test Account' ;
        insert acct;
        
        Contact cont = new Contact();
        cont.FirstName='Test';
        cont.LastName='Test';
        cont.Email ='test@testrubrik.com';
        cont.Accountid= acct.id;
        cont.LeadSource='Channel';
        insert cont;
        
        Date closeDt = System.Today()+90;
        //Opportunity Opp = new Opportunity(CloseDate=System.Today().addDays(90),StageName='1 Discovery',name='Test Opp', Initial_Contacts_Name__c =cont.Id,AccountId=testAccount.ID, Alliance_Partner_Name__c='Amazon', Alliance_Source_Type__c='Alliance Initiated Deal');
        //insert opp;
        
        //opportunity opp = new opportunity(Name='testing IEtestsalesforce 4/7/2015' ,  AccountId= acct.Id,StageName = '4 Business Justification', 
                        //                   CloseDate = closeDt, Lead_Email_Hidden__c='', partner_lookup__c=acct.id, Alliance_Partner_Name__c='Amazon', Alliance_Source_Type__c='Alliance Initiated Deal');
        //insert opp;
        
        opportunity opp = [select id,name from opportunity LIMIT 1];
        
        Test.StartTest(); 
            
        Test.setCurrentPageReference(new PageReference('Page.ShowJiraOnOpportunity_VF')); 
        System.currentPageReference().getParameters().put('Id', opp.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        //newAccountPlan testAccPlan = new newAccountPlan(sc);
        ShowJiraOnOpportunityController controller = new ShowJiraOnOpportunityController(sc);
        controller.jiraSearchText='vmware';
        controller.jiraSearchKey='';
        
        controller.authHeader();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        controller.Execute();
        controller.jiraIssues[0].selected =true;
        controller.UpdateOpportunity();
        controller.closePopup();
    
        Test.StopTest();
    }
}