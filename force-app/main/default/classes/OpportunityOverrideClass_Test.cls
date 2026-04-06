@isTest
public class OpportunityOverrideClass_Test{
    static testMethod void testMethod1() 
    {
        User usr=[Select id from User where isactive=true and Profile.Name ='System Administrator' limit 1];
        System.runAs(usr) {
            Account testAccount = new Account();
            testAccount.Name='Test Account' ;
            insert testAccount;
            
            Contact cont = new Contact();
            cont.FirstName='Test';
            cont.LastName='Test';
            cont.Email ='test@testrubrik.com';
            cont.Accountid= testAccount.id;
            cont.LeadSource='Channel';
            insert cont;
            
            Opportunity Opp = new Opportunity();
            Test.StartTest(); 
                
            Test.setCurrentPageReference(new PageReference('Page.OpportunityOverridePage')); 
            System.currentPageReference().getParameters().put('contactId', cont.id);
            System.currentPageReference().getParameters().put('AccId', testAccount.id);
            System.currentPageReference().getParameters().put('AccName', testAccount.Name);
             ApexPages.StandardController sc = new ApexPages.StandardController(Opp);
            //newAccountPlan testAccPlan = new newAccountPlan(sc);
            OpportunityOverrideClass controller = new OpportunityOverrideClass(sc);
            PageReference result = controller.save();
            Test.StopTest();
        }
    }
     static testMethod void testMethod2() 
    {
         User usr=[Select id from User where isactive=true and Profile.Name ='System Administrator' limit 1];
        System.runAs(usr) {
            Account testAccount = new Account();
            testAccount.Name='Test Account' ;
            insert testAccount;
        
            Contact cont = new Contact();
            cont.FirstName='Test';
            cont.LastName='Test';
            cont.Email ='test@testrubrik.com';
            cont.Accountid= testAccount.id;
            cont.LeadSource='Channel';
            insert cont;
            
            Opportunity Opp = new Opportunity();
            opp.Projected_Product_Edition__c = 'Test';//'DSPM';
            Test.StartTest(); 
                
            Test.setCurrentPageReference(new PageReference('Page.OpportunityOverridePage')); 
            System.currentPageReference().getParameters().put('contactId', cont.id);
            System.currentPageReference().getParameters().put('AccId', testAccount.id);
            System.currentPageReference().getParameters().put('AccName', testAccount.Name);
            System.currentPageReference().getParameters().put('conLead', testAccount.Name);
             ApexPages.StandardController sc = new ApexPages.StandardController(Opp);
            //newAccountPlan testAccPlan = new newAccountPlan(sc);
            OpportunityOverrideClass controller = new OpportunityOverrideClass(sc);
            PageReference result = controller.save();
            System.assert(true,Opp.Id);
            Test.StopTest();
        }
    }
    static testMethod void testMethod21() 
    {
         User usr=[Select id from User where isactive=true and Profile.Name ='System Administrator' limit 1];
        System.runAs(usr) {
            Account testAccount = new Account();
            testAccount.Name='Test Account' ;
            insert testAccount;
        
            Contact cont = new Contact();
            cont.FirstName='Test';
            cont.LastName='Test';
            cont.Email ='test@testrubrik.com';
            cont.Accountid= testAccount.id;
            cont.LeadSource='Channel';
            insert cont;
            
            Opportunity Opp = new Opportunity();
            opp.Projected_Product_Edition__c ='DSPM';
            Test.StartTest(); 
                
            Test.setCurrentPageReference(new PageReference('Page.OpportunityOverridePage')); 
            System.currentPageReference().getParameters().put('contactId', cont.id);
            //System.currentPageReference().getParameters().put('AccId', testAccount.id);
            System.currentPageReference().getParameters().put('AccName', testAccount.Name);
            System.currentPageReference().getParameters().put('conLead', testAccount.Name);
             ApexPages.StandardController sc = new ApexPages.StandardController(Opp);
            //newAccountPlan testAccPlan = new newAccountPlan(sc);
            OpportunityOverrideClass controller = new OpportunityOverrideClass(sc);
            PageReference result = controller.save();
            System.assert(true,Opp.Id);
            Test.StopTest();
        }
    }
}