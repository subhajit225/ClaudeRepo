@isTest
public class CustomReportController_Test{
 static testMethod void testCustomReport(){
        User u =[select id,name from user where name='Angie Huang' LIMIT 1];
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account testAccount = new Account(RecordTypeId = partnerRecordTypeId);
        testAccount.Name='Test Account Report' ;
        insert testAccount;
        insert new TriggerControl__c(name='Opportunity',DisableTrigger__c=false);
        
        Date od = Date.today().addDays(-60);
   
        opportunity oppr = new opportunity(Name='testingReport' ,  AccountId= testAccount.Id,StageName = '1 Discovery', Opportunity_Type__c = 'New Customer', Opportunity_Sub_Type__c = 'Regular', Primary_Competitor__c = 'Actifio',
                                           CloseDate = od, Lead_Email_Hidden__c='', partner_lookup__c=testAccount.Id, Alliance_Partner_Name__c='Amazon', Alliance_Source_Type__c='Alliance Initiated Deal', Installation_Assigned_To__c ='FE Install');
        insert oppr;
       
        insert New ShGl_DisableBusinessLogic__c( name ='Opportunity',Disable_Opportunity_Validation_Rules__c=true);
        
        Cluster__c clust = new Cluster__c ();
        clust.account__c =testAccount.Id;
        clust.Name='2345678';
        clust.uuid__c='2345678';
        insert clust;
   
        oppr.StageName='7 Closed Won';
        oppr.Business_Unit__c='Rubrik';
        oppr.CloseDate = od;
        update oppr;
    
         Test.startTest();
       
           CustomerReportController cr = new CustomerReportController();
         Test.stopTest();
            
    }
    
}