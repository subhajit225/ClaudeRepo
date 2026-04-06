/**
 * @File Name          : ETM_TestDataFactory.cls
 * @Description        : 
 * @Author             : Bhushan Patil
 * @Group              : 
 * @Last Modified By   : Bhushan Patil
 * @Last Modified On   : 5/3/2020, 5:30:40 pm
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    5/3/2020         Bhushan Patil           Initial Version
**/
@isTest
public class ETM_TestDataFactory {
 
    public static List<Territory2> createTerritory(
        String strTerritoryName,
        String adaptiveId,
        Id ModelId,
        Id typeId,
        Integer intCount
    ){
        List<Territory2> listTerritory = new List<Territory2>();
        for(Integer i=0;i<intCount; i++){
            Territory2 obj = new Territory2();
            obj.Adaptive_Territory_Id__c = adaptiveId+i;
            obj.DeveloperName = strTerritoryName+'_'+i;
            obj.Name = strTerritoryName+'_'+i;
            obj.Territory2ModelId = ModelId;
            obj.Territory2TypeId = typeId;
            listTerritory.add(obj);
        }
        return listTerritory;
    }


    public static List<Territory2Model> createTerritoryModel(
        String strTerritoryModel,
        Integer intCount
    ){
        List<Territory2Model> lstModel = new List<Territory2Model>(); 
        for(Integer i=0;i<intCount; i++){
            Territory2Model objModel = new Territory2Model();
            objModel.Name = strTerritoryModel;
            objModel.DeveloperName = strTerritoryModel;
            lstModel.add(objModel);
        }
        return lstModel;
    }
    
    public static List<ETMStage_Monitoring__c> createMoniter(
        String strName,
        Integer intCount
    ){
        List<ETMStage_Monitoring__c> lstMonitor = new List<ETMStage_Monitoring__c>(); 
        for(Integer i=0;i<intCount; i++){
            ETMStage_Monitoring__c objMonitor = new ETMStage_Monitoring__c();
            objMonitor.Name = strName;
            objMonitor.Status__c = 'New';
            lstMonitor.add(objMonitor);
        }
        return lstMonitor;
    }
    
    public static List<Account_Stage__c> createAccountStage(
        String strName,
        Id accountId,
        Id monitorId,
        String territoryId,
        Integer intCount
    ){
        List<Account_Stage__c> lstAccount = new List<Account_Stage__c>(); 
        for(Integer i=0;i<intCount; i++){
            Account_Stage__c objAccount = new Account_Stage__c();
            //objAccount.Name = strName;
            objAccount.Account__c = accountId;
            objAccount.JobId__c = monitorId;
            objAccount.TerritoryAdaptive_Id__c = territoryId;
            objAccount.Account_Move_Reason__c='DNA (Do Not Assign)';
            lstAccount.add(objAccount);
        }
        return lstAccount;
    }
    
    public static List<Territory_Stage__c> createTerritoryStage(
        String strName,
        Id jobid,
        String adaptiveID,
        String parentAdaptiveID,
        Integer intCount
    ){
        List<Territory_Stage__c> lstTerritory = new List<Territory_Stage__c>(); 
        for(Integer i=0;i<intCount; i++){
            Territory_Stage__c objStage = new Territory_Stage__c();
            objStage.Name = strName;
            objStage.AdaptiveId__c = adaptiveID;
            objStage.JobId__c = jobid;
            objStage.Parent_Adaptive_Id__c = parentAdaptiveID;
            lstTerritory.add(objStage);
        }
        return lstTerritory;
    }
    
    public static List<ObjectTerritory2Association> createAssociationRecords(
        string accountId,
        string territoryId,
        string AssociationCause,  
        Integer intCount
    ){
        List<ObjectTerritory2Association> lstAssociation = new List<ObjectTerritory2Association>(); 
        for(Integer i=0;i<intCount; i++){
            ObjectTerritory2Association objAssociation = new ObjectTerritory2Association();
            objAssociation.ObjectId = accountId;
            objAssociation.Territory2Id = territoryId;
            objAssociation.AssociationCause = AssociationCause;
            lstAssociation.add(objAssociation);
        }
        return lstAssociation;
    }
     
    
    public static List<Account> createAccount(
        String strName,
        Integer intCount
    ){
        List<Account> lstAccount = new List<Account>(); 
        for(Integer i=0;i<intCount; i++){
            Account objAccount = new Account();
            objAccount.Name = strName;
            lstAccount.add(objAccount);
        }
        return lstAccount;
    }
    
    public static list<Contact> createContact(
        String strName,
        String accountId,
        Integer intCount
    ){
        List<Contact> lstContact = new List<Contact>(); 
        for(Integer i=0;i<intCount; i++){
            Contact objContact = new Contact();
            objContact.LastName = strName;
            objContact.accountId = accountId;
            lstContact.add(objContact);
        }
        return lstContact;
    }
}