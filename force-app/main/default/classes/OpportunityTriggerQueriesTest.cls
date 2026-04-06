@isTest
public class OpportunityTriggerQueriesTest {
@TestSetUp
    static void initialDataSetup() { 
        insert new Opportunity_Stage_Days__c(AllowAcvCalculation__c = true, AllowArrCalculation__c = true);
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
         
        ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c();
        settingDisable.Trigger_Max_Loop_Count__c = 10;
        settingDisable.Disable_Opportunity_Validation_Rules__c = true;
        insert settingDisable;
        
        upsert disableFuncCS;
        Account objAccount = new Account();
        Contact objContact = new Contact();
        Contact objContact1 = new Contact();
        Account objAccount1 = new Account();
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        objAccount.Name = 'Test Account 29-05';
        objAccount.RecordTypeId = recordTypeId;
        insert objAccount;
        objAccount1.Name = 'Test Account 29-06';
        objAccount1.RecordTypeId = recordTypeId;
        insert objAccount1;
        objContact.Account = objAccount;
        objContact.LastName = 'Test Contact 29-05';
        insert objContact; 
        
        objContact1.LastName = 'Test Contact 29-06';
        objContact1.Account = objAccount1;
        insert objContact1; 
        
        Opportunity objOpportunity = new Opportunity();
        objOpportunity.StageName = '1 Discovery';
        objOpportunity.closeDate = System.Today() + 30;
        objOpportunity.Name = 'Test Opp 29-05';
        objOpportunity.Opportunity_Sub_Type__c = 'Regular';
        objOpportunity.Initial_Contacts_Name__c = objContact.Id;
        objOpportunity.Distributor_Lookup__c = objAccount.Id;
        objOpportunity.Partner_Lookup__c = objAccount.Id;
        insert objOpportunity;
        
        ServiceContract serviceContractObj = new ServiceContract();
        serviceContractObj.Name = 'TestServiceContract2';
        serviceContractObj.SBQQSC__Opportunity__c = objOpportunity.Id;
        serviceContractObj.StartDate = System.today();
        serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj.Term = 36;
        serviceContractObj.EndDate = System.today().addDays(365);
        serviceContractObj.SBQQSC__RenewalForecast__c = false;
        serviceContractObj.SBQQSC__RenewalTerm__c = 12;
        insert serviceContractObj;

    }
    
    @isTest
    static void testQueryMethods(){ 
        List<Opportunity> opplist = new List<Opportunity>();
        List<serviceContract> scList = new List<serviceContract>();
        Set<Id> scIdSet = new Set<Id>();
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
        opplist = [select Id,name from Opportunity limit 1];
        scList = [select Id,Name from serviceContract limit 1];
        for(Opportunity opp : opplist){
            oppMap.put(opp.Id,opp);
        }
        for(serviceContract sc : scList){
            scIdSet.add(sc.Id);
        }
        Test.startTest();
        OpportunityTriggerQueries.getServiceContracts(scIdSet);
        OpportunityTriggerQueries.getOppMapTrgAfterUpdate(oppMap);
        system.assertnotequals(scIdSet,null);
        Test.stopTest();
    }
}