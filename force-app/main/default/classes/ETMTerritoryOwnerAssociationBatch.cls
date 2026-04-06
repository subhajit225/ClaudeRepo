/******************************************************************************************
Description : To Update Owner and TART values based on territory model on account Object 
Developer : Chaitra
Date : 11/2019
*******************************************************************************************/
public class ETMTerritoryOwnerAssociationBatch implements Database.Batchable<sObject>,Database.Stateful { //,Database.RaisesPlatformEvents

   public string StartDateTime,process ;
   public Integer totalNumExec = 0;
   //public boolean runUTAbtach = true ; // runs this batch only when there are no potential updates by objectterritoryassociation records
   public string CLASS_NAME = 'ETMTerritoryOwnerAssociationBatch';
   public string ERROR_FUNCTIONALITY = 'ETM';
   public string OwnerAssociation_SourceType = 'UserUpdate';
   public ETMTerritoryOwnerAssignment AOwner = new ETMTerritoryOwnerAssignment();
   public set<Id>TerrId = new set<Id>();
   public set<Custom_Error_Log__c> errLog = new set<Custom_Error_Log__c>();
   //SF-8545: Update Rubrik Sales Engineer Field On Accounts
   public Set<String> SEAdaptiveIds = new Set<String>();
   public Set<Id> allianceRepTerrIds = new Set<Id>(); //SAL23-443 //SAL24-28 //SAL24-472
   public Set<Id> sdrTerrIds = new Set<Id>(); //SAL24-14
   public List<Territory_Owner_Assignment__c> terrOwnerAssignList = new List<Territory_Owner_Assignment__c>(); //SAL24-334 

   public ETMTerritoryOwnerAssociationBatch(string process,set<Id>TerrId,Integer totalNumExec){
   this.process = process.trim(); // AccountUpdate , UserUpdate
   this.totalNumExec = totalNumExec;
   if(TerrId!=null)
   this.TerrId = TerrId;
   }
   
/*******************************************************************************************************             
Description :  Queries the elligible accounts for update using OobjectTerritoryAssociation reference
*********************************************************************************************************/ 

   public Database.QueryLocator start(Database.BatchableContext BC) {
    string query;
    try{
      //SF-8545: Update Rubrik Sales Engineer Field On Accounts
      //SAL23-443
      for(Territory_Owner_Assignment__c SETerr : [select id,AdaptiveId__c,LeafTerritoryId__c,Functionality__c from Territory_Owner_Assignment__c where Functionality__c NOT IN ('Owner Assignment', 'Opp Co-Owner Assignment') limit 50000]){ //SAL24-334
         if(SETerr.Functionality__c=='Sales Engineer Assignment') SEAdaptiveIds.add(SETerr.AdaptiveId__c);
         if(SETerr.Functionality__c=='Alliance Rep Assignment') allianceRepTerrIds.add(SETerr.LeafTerritoryId__c); //SAL24-28 //SAL24-472
         if(SETerr.Functionality__c=='SDR Assignment') sdrTerrIds.add(SETerr.LeafTerritoryId__c); //SAL24-14
         terrOwnerAssignList.add(SETerr); //SAL24-334 - get all the Territory Owner assignment records to delete at the end of the batch
      }
      query = AOwner.getUserToTerritories(process); 
      AOwner.getTerritoryOwner_TerrBased(); 
        // To disable account owner assignment
        if(AOwner.disable_AccountOwnerUpdate){ 
         return Database.getQueryLocator('select id from account limit 0');
        }
         
     }
      catch(exception e){
      insert LogError.CreateGenericErrorLog(CLASS_NAME,e,ERROR_FUNCTIONALITY);
     }              
      return Database.getQueryLocator(query);
      
   }
   
/**************************************************************************          
Description :  Updates the account Owner based on ETM Model
***************************************************************************/   

public void execute(Database.BatchableContext BC, List<ObjectTerritory2Association> acctTerritoryAssociationList) {
       set<id> Terr_ProcessedORWithoutAccounts = new set<Id>(); // holds leaf terr id which are processed for owner assignment or do not have accounts
       try{
       errLog.addall(AOwner.processOwnerAssignment(acctTerritoryAssociationList));
       StartDateTime = acctTerritoryAssociationList[acctTerritoryAssociationList.size()-1].lastmodifieddate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');    
       
       // Delete the processed terrId's   
      if(!AOwner.ProcessedLeafterritoryId.isEmpty()) {
         delete [select id from Territory_Owner_Assignment__c where LeafTerritoryId__c IN : AOwner.ProcessedLeafterritoryId and Functionality__c='Owner Assignment']; //SAL23-443 //SAL24-14
       }   
          }
         catch(exception e){
           errLog.add(LogError.CreateGenericErrorLog(CLASS_NAME,e,ERROR_FUNCTIONALITY));
     }  
       } 
       
/**************************************************************************          
Description :  creates error logs    
             Updates timestamp pf last processed OTA on mdt
             Triggers Contact owner update batch run  
***************************************************************************/    

   public void finish(Database.BatchableContext BC) {
       totalNumExec++;
       Map<string,Territory_Owner_Assignment__c> TerrId_TOW = new Map<string,Territory_Owner_Assignment__c>();
       List<Custom_Error_Log__c> errLogList;
       //SAL24-334
       Map<string,Id> AdaptiveIdTerrIdMap = new Map<string,Id>();
       List<Territory_Owner_Assignment__c> failedTerritoryOwnerAsignLists = new List<Territory_Owner_Assignment__c>();
       
       // EnableLogging - controls if the error logs need to be stored in SF

       if(errLog.size()>0 && AOwner.enableLogging){
       errLogList = new List<Custom_Error_Log__c>(errLog);
       database.insert(errLogList,false);
       }
     
       if(process.trim().equalsIgnoreCase('AccountUpdate') && StartDateTime!= null){
         //SAL25-56  
         //System.enqueueJob(new UpdateCustomMetadata(StartDateTime));
         List<ETM_Territory_Controller__c> etmCS = [select Id,Field_Value__c from ETM_Territory_Controller__c where Name = 'Con_OTA_LMDT' limit 1];
         if(!etmCS.isEmpty()){
            etmCS[0].Field_Value__c = StartDateTime;
            update etmCS[0];
         }
       }
  
       //SAL24-334 - Delete all the Territory Owner assignment records
       if(!terrOwnerAssignList.isEmpty()){
         List<Database.DeleteResult> drList = Database.delete(terrOwnerAssignList, false);
         LogError.deleteDMLErrorLog((List<SObject>)terrOwnerAssignList, drList, CLASS_NAME,'ETM - Delete TerritoryOwnerAssignment');
       }

       if(!AOwner.failedAdaptiveIds.isEmpty()){
         for(Territory2 terr : [select Id,Adaptive_Territory_Id__c from Territory2 where Adaptive_Territory_Id__c IN :AOwner.failedAdaptiveIds and Territory2Model.State = 'Active']){
            AdaptiveIdTerrIdMap.put(terr.Adaptive_Territory_Id__c, terr.Id);
         }
         //insert territory owner assignment records
         for(String adaptiveId :AOwner.failedAdaptiveIds){
            if(AdaptiveIdTerrIdMap.containsKey(adaptiveId)){
               failedTerritoryOwnerAsignLists.add(new Territory_Owner_Assignment__c(LeafTerritoryId__c=AdaptiveIdTerrIdMap.get(adaptiveId), Functionality__c='Owner Assignment'));
               failedTerritoryOwnerAsignLists.add(new Territory_Owner_Assignment__c(LeafTerritoryId__c=AdaptiveIdTerrIdMap.get(adaptiveId), Functionality__c='SDR Assignment'));
               failedTerritoryOwnerAsignLists.add(new Territory_Owner_Assignment__c(LeafTerritoryId__c=AdaptiveIdTerrIdMap.get(adaptiveId), Functionality__c='Alliance Rep Assignment'));
               failedTerritoryOwnerAsignLists.add(new Territory_Owner_Assignment__c(AdaptiveId__c=adaptiveId, Functionality__c='Sales Engineer Assignment'));
            }
         }
         if(!failedTerritoryOwnerAsignLists.isEmpty()){
            List<Database.SaveResult> srList = Database.insert(failedTerritoryOwnerAsignLists, false);
            LogError.createDMLErrorLog((List<SObject>)failedTerritoryOwnerAsignLists, srList, CLASS_NAME,'ETM - Insert TerritoryOwnerAssignment'); //SAL24-334
         }
       }
       //End - SAL24-334

       //Update contact
         Database.executeBatch(new ETMContactOwnerChangeBatch(AOwner.failedAccIds,AOwner.enableLogging,AOwner.disable_ContactOwnerUpdate,AOwner.disable_OppOwnerUpdate,totalNumExec)); 
  } 
}