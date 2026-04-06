/**
 * @File Name          : ETM_ExecuteTerritoryAssignmentBatchTest.cls
 * @Description        : 
 * @Author             : Bhushan Patil
 * @Group              : 
 * @Last Modified By   : Bhushan Patil
 * @Last Modified On   : 6/3/2020, 2:38:47 pm
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    6/3/2020   Bhushan Patil     Initial Version
**/ 
@isTest
private class ETM_ExecuteTerritoryAssignmentBatchTest {
    
    @testSetup static void setup() {
        List<Territory2Model> lstOrgTerritories = [select id,Name,state from Territory2Model where state = 'Active'];
        if(lstOrgTerritories.isEmpty()){
            List<Territory2Model> lstModel = ETM_TestDataFactory.createTerritoryModel('Test_FY',1);
            Insert lstModel;
            lstOrgTerritories.addAll(lstModel);
        }
        
        List<Territory2Type> lstType = [select id from Territory2Type limit 1];
        
        List<Territory2> lstTerritories =  ETM_TestDataFactory.createTerritory('ETM_Territory','12345',lstOrgTerritories[0].id,lstType[0].Id,2);
        insert lstTerritories;
               
    }
    
    @isTest static void ExecuteAssignmentRules() {
        
        List<Territory2Model> lstOrgTerritories = [select id,Name,state from Territory2Model where state = 'Active'];
        List<Territory2> lstTerritories = [Select id,Adaptive_Territory_Id__c from Territory2 where Territory2Model.State = 'active' limit 1 ];
        
        Account acct = (Account)ShGl_TestFactory.createSObject(new Account(), null);
        insert acct;
        
        Account acct1 = (Account)ShGl_TestFactory.createSObject(new Account(), null);
        insert acct1;
        
        Account acct2 = (Account)ShGl_TestFactory.createSObject(new Account(), null);
        insert acct2;
         
        
        Test.startTest();
            //List<Account> lstAccount = [Select id from account limit 1];
            
            List<ObjectTerritory2Association> lstAssociation = ETM_TestDataFactory.createAssociationRecords(acct2.id,lstTerritories[0].id,'Territory2Manual',1);
            insert lstAssociation;
            
            List<ObjectTerritory2Association> lstAssociation1 = ETM_TestDataFactory.createAssociationRecords(acct1.id,lstTerritories[0].id,'Territory2Manual',1);
            insert lstAssociation1;
             
            List<ETMStage_Monitoring__c> lstMonitor = ETM_TestDataFactory.createMoniter('Test_FY',1);
            Insert lstMonitor;
            
            List<Territory_Stage__c> lstTerritoryStage = ETM_TestDataFactory.createTerritoryStage('test',lstMonitor[0].Id,lstTerritories[0].Adaptive_Territory_Id__c,lstTerritories[0].Adaptive_Territory_Id__c,5);
            Insert lstTerritoryStage ;
            
            List<Account_Stage__c> lstAccountStage = ETM_TestDataFactory.createAccountStage('Test Account',acct.id,lstMonitor[0].id,'1111',1);
            Insert lstAccountStage;
            
            
            
            set<id> jobid = new set<id>();
            jobid.add(lstMonitor[0].id);
            
            Database.ExecuteBatch(new ETM_ExecuteTerritoryAssignmentRuleBatch(jobid,lstOrgTerritories[0].Name,'',true,lstOrgTerritories[0].state=='Active'?true:false));
        Test.stopTest();
    }

    
    @isTest static void ExecuteAssignmentRulesProcessAccount() {
        
        List<Territory2Model> lstOrgTerritories = [select id,Name,state from Territory2Model where state = 'Active'];
        List<Territory2> lstTerritories = [Select id,Adaptive_Territory_Id__c from Territory2 where Territory2Model.State = 'active' limit 1 ];
        
        Account acct = (Account)ShGl_TestFactory.createSObject(new Account(), null);
        insert acct;
        
        Account acct1 = (Account)ShGl_TestFactory.createSObject(new Account(), null);
        insert acct1;
        
        Account acct2 = (Account)ShGl_TestFactory.createSObject(new Account(), null);
        insert acct2;
         
        
        Test.startTest();
            //List<Account> lstAccount = [Select id from account limit 1];
            
            List<ObjectTerritory2Association> lstAssociation = ETM_TestDataFactory.createAssociationRecords(acct2.id,lstTerritories[0].id,'Territory2Manual',1);
            insert lstAssociation;
            
            List<ObjectTerritory2Association> lstAssociation1 = ETM_TestDataFactory.createAssociationRecords(acct1.id,lstTerritories[0].id,'Territory2Manual',1);
            insert lstAssociation1;
             
            List<ETMStage_Monitoring__c> lstMonitor = ETM_TestDataFactory.createMoniter('Test_FY',1);
            Insert lstMonitor;
            
            List<Territory_Stage__c> lstTerritoryStage = ETM_TestDataFactory.createTerritoryStage('test',lstMonitor[0].Id,lstTerritories[0].Adaptive_Territory_Id__c,lstTerritories[0].Adaptive_Territory_Id__c,5);
            Insert lstTerritoryStage ;
            
            List<Account_Stage__c> lstAccountStage = ETM_TestDataFactory.createAccountStage('Test Account',acct.id,lstMonitor[0].id,'1111',1);
            lstAccountStage[0].Status__c = 'Success';
            Insert lstAccountStage;
            
            set<id> jobid = new set<id>();
            jobid.add(lstMonitor[0].id);
            
            Database.ExecuteBatch(new ETM_ExecuteTerritoryAssignmentRuleBatch(jobid,lstOrgTerritories[0].Name,'',false,lstOrgTerritories[0].state=='Active'?true:false));
        Test.stopTest();
    }
}