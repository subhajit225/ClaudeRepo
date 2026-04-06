/*******************************************************************************************************
Description : To create/update the territory model based on staging table created from adaptive system
              To capture error logs against each staging record
              Picks only one territoryModel in one run and with monitoringlog status ='New'
              To update the monitoring log with failed record count
Developer : Chaitra
Date : 1/2020
***********************************************************************************************************/

public class ETMCreateTerritoryModelBatch implements Database.Batchable < sObject > , Database.Stateful,Schedulable {
    public final string CLASS_NAME = 'ETMCreateTerritoryModelBatch';
    public final string UNASSIGNED_TERRITORY = 'Unassigned';
    public final string GLOBAL_TERRITORYNAME = 'WW';
    public final string ERROR_FUNCTIONALITY = 'ETM';
    public List<Territory_Stage__c> terrStgObjectTotalLst = new List<Territory_Stage__c>();
    public Map <string,Id> AdapId_StageId = new Map <string,Id> ();
    public Map <string,Id> AdaptiveId_TerrId = new Map <string,Id> ();
    public Map <Id,Integer> Controller_UnprocessTerr = new Map <Id,Integer>(); 
    public boolean isArchievedModel = false;
    public boolean runNextJob = true; // To check if next chained batches(UTA,account) needs to be run
    public Id TerritoryModelId;
    public Id GlobalTerrId;
    public string TerrModelName ;
    public string splChar_RegExp = '[^a-zA-Z0-9]';
    public List <Custom_Error_Log__c> errLog = new List <Custom_Error_Log__c> ();
    public integer setpriority_Test = 5 ; // Used only for code coverage - default to Global territory type
    public static Set<Id> reprocessLeafTerrIds = new set<Id>();
    public set<Id> totalReprocessLeafTerrIds = new set<Id>();

    //SF-13037
    public Id etmStageMonitoringId  = null;
    public Boolean isETMJobsRunning = false;
    public Boolean allowArchivingETMModel = false;
    public set<Id> inActiveETMStageIds = new set<Id>();
    
    /******************************************************************************************
Each batch picks just one territory model details from staging for upsert operation
*******************************************************************************************/
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        string query;
        List <Territory2Model> Terr2Model = new List <Territory2Model> ();
        set <string> Monitor_Status = new set <string> {'New'};
        //SF-13037
        List<Territory2Model> activeTerr2Model = new List<Territory2Model>();
        isETMJobsRunning = ETMBatchJobsController.checkETMJobsRunning(BC.getJobId());
        allowArchivingETMModel = ShGl_DisableFunctionalityLogic__c.getInstance(UserInfo.getUserId()).ETM_Allow_Archiving_Territory_Model__c;
        if(isETMJobsRunning){
            return Database.getQueryLocator('select id from account limit 0');
        }//End
            try{
                //SF-13037
                activeTerr2Model = [select id, Name,State from Territory2Model where State ='Active'];
                String etmStageQuery = 'Select id, Name from ETMStage_Monitoring__c where Status__c IN: Monitor_Status ';
                etmStageQuery += etmStageMonitoringId != null ? ' and Id = :etmStageMonitoringId ' : ' order by createddate desc';
                //for (ETMStage_Monitoring__c StgController: [Select id, Name from ETMStage_Monitoring__c where Status__c IN: Monitor_Status order by createddate desc]) {
                for (ETMStage_Monitoring__c StgController: Database.query(etmStageQuery)) { //End
                    //SF-13037
                    if(allowArchivingETMModel){
                        if (string.isBlank(TerrModelName)) {
                            Controller_UnprocessTerr.put(StgController.Id,0);
                            TerrModelName = StgController.Name;
                        } else if (StgController.Name == TerrModelName) {
                            Controller_UnprocessTerr.put(StgController.Id,0);
                        }
                    }
                    else {
                        if(activeTerr2Model.size() != 0 && activeTerr2Model[0].Name==StgController.Name){
                            Controller_UnprocessTerr.put(StgController.Id,0);
                            TerrModelName = StgController.Name;
                        }
                        else{
                            inActiveETMStageIds.add(StgController.Id);
                        }
                    } //End
                }
                system.debug('Controller_UnprocessTerr' + Controller_UnprocessTerr);
                
                if(!Controller_UnprocessTerr.isEmpty()){
                    Terr2Model = [select id, Name,State from Territory2Model where Name =: TerrModelName];
                    if(Terr2Model.size() != 0 && Terr2Model[0].State=='Archived'){
                       isArchievedModel = true;
                       return Database.getQueryLocator('select id from account limit 0');
                    }
                    else if (Terr2Model.size() == 0) {
                        Terr2Model.add(new Territory2Model(Name = TerrModelName, DeveloperName = TerrModelName.trim().replaceAll(splChar_RegExp, '_')));
                        Insert Terr2Model;
                    } else {
                        for (territory2 currentTerr: [select id, Adaptive_Territory_Id__c, Territory2Type.DeveloperName from territory2 where Territory2Model.Name =: TerrModelName]) {
                            system.debug('currentTerr'+currentTerr);
                            if (currentTerr.Territory2Type.DeveloperName.equalsIgnoreCase(GLOBAL_TERRITORYNAME)) {
                                GlobalTerrId = currentTerr.id;
                            } else {
                                if (currentTerr.Adaptive_Territory_Id__c != null) { // Can check to use if unassigned terr is created
                                    AdaptiveId_TerrId.put(currentTerr.Adaptive_Territory_Id__c, currentTerr.id);
                                }
                            }
                        }
                        
                    }
                    
                    system.debug('AdaptiveId_TerrId' + AdaptiveId_TerrId);
                    system.debug('Controller_UnprocessTerr' + Controller_UnprocessTerr);
                    TerritoryModelId = Terr2Model[0].id;
                    if(Test.IsRunningTest()){
                        query = 'select Id,DeveloperName,Priority from Territory2Type where priority = '+setpriority_Test;
                    }  
                    else{
                        query = 'select Id,DeveloperName,Priority from Territory2Type order by Priority desc';
                    }
                    system.debug('Territory model query'+query);
                    return Database.getQueryLocator(query);
                }
            }
        catch(exception e){
            errLog.add(LogError.CreateGenericErrorLog(CLASS_NAME,e,ERROR_FUNCTIONALITY));
        }  
        runNextJob = false;             
        return Database.getQueryLocator('select id from account limit 0');
    }
    
    /*******************************************************************************
Each execute call batch processes territories of on territory type (TART)
*******************************************************************************/
    
    public void execute(Database.BatchableContext BC, List <Territory2Type> terrType) {
        List <Territory2> TerrList = new List <Territory2> ();
        List <Territory2> delTerrList = new List <Territory2> ();
        List <Territory_Stage__c> DupStgList = new List <Territory_Stage__c> ();
        List <Territory_Stage__c> updateStgList = new List <Territory_Stage__c> ();
        List <Territory_Stage__c> deleteStgList = new List <Territory_Stage__c> ();
        List <string> updateSuccess_AdaptiveId = new List <string> ();
        List <Territory_Stage__c> updateSuccessRec = new List <Territory_Stage__c> ();
        
        system.debug('AdaptiveId_TerrId' + AdaptiveId_TerrId);
        system.debug('terrType' + terrType);
        system.debug('GlobalTerrId'+GlobalTerrId);
        Territory2TriggerHelper.runningContext ='ETM_TerritoryBatch';
        if (terrType[0].DeveloperName.equalsIgnoreCase(GLOBAL_TERRITORYNAME)) { //Create or get global territory
            try {
                if (GlobalTerrId == null) {
                    Territory2 Globalterritory = new Territory2(
                        Territory2ModelId = TerritoryModelId,
                        name = GLOBAL_TERRITORYNAME,
                        DeveloperName = GLOBAL_TERRITORYNAME,
                        Territory2TypeId = terrType[0].Id);
                    insert Globalterritory;
                    GlobalTerrId = Globalterritory.id;
                    
                  Id terrTypeId =[ select Id from Territory2Type where DeveloperName ='Territory' limit 1 ].Id;
                    Territory2 Unassignedterritory = new Territory2(
                        Territory2ModelId = TerritoryModelId,
                        name = UNASSIGNED_TERRITORY,
                        DeveloperName = UNASSIGNED_TERRITORY,
                        ParentTerritory2Id = GlobalTerrId,
                        Territory2TypeId = terrTypeId);
                        insert Unassignedterritory;
                   
                }
            } catch (exception e) {
                errLog.add(LogError.CreateGenericErrorLog(CLASS_NAME, e, ERROR_FUNCTIONALITY));
            }
        } else { //Upsert TART territory
            List<Territory_Stage__c> terrStgObjectLst = [Select id, Name, AdaptiveId__c, Error_message__c, Parent_Adaptive_Id__c, Type__c, JobId__r.Name, SQL_Operation__c,Hierarchy_Level__c,SubType__c from Territory_Stage__c where JobId__c IN: Controller_UnprocessTerr.keyset() and Type__c =: terrType[0].DeveloperName and status__c!='Success' order by LastModifiedDate desc];
            for (Territory_Stage__c StgTerr: terrStgObjectLst) {  //and status__c!='Success'
                system.debug('StgTerr' + StgTerr);
                try{
                    if(String.isNotBlank(StgTerr.Error_message__c) && StgTerr.Error_message__c.startsWith('Duplicate record')){
                      continue;
                    }
                    if(String.isBlank(StgTerr.AdaptiveId__c)){
                        StgTerr.Status__c = 'Failure';
                        Controller_UnprocessTerr.put(StgTerr.JobId__c,Controller_UnprocessTerr.get(StgTerr.JobId__c)+1);
                        StgTerr.Error_message__c = 'AdaptiveId is mandatory';
                    }
                    else if (!AdapId_StageId.containskey(StgTerr.AdaptiveId__c)) { // Process distinct stage records
                        AdapId_StageId.put(StgTerr.AdaptiveId__c, StgTerr.Id);
                        if(StgTerr.SQL_Operation__c!=null && StgTerr.SQL_Operation__c.equalsIgnoreCase('delete')){
                            deleteStgList.add(StgTerr);
                            delTerrList.add(new Territory2(id = AdaptiveId_TerrId.containskey(StgTerr.AdaptiveId__c) ? AdaptiveId_TerrId.get(StgTerr.AdaptiveId__c) : null));
                        }
                        else{
                            updateStgList.add(StgTerr);
                            TerrList.add(new Territory2(id = AdaptiveId_TerrId.containskey(StgTerr.AdaptiveId__c) ? AdaptiveId_TerrId.get(StgTerr.AdaptiveId__c) : null,
                                                              Adaptive_Territory_Id__c = StgTerr.AdaptiveId__c,
                                                              ParentTerritory2Id = (StgTerr.Type__c.equalsIgnoreCase('Theatre')||StgTerr.Type__c.equalsIgnoreCase('Theater')) ? GlobalTerrId : AdaptiveId_TerrId.get(StgTerr.Parent_Adaptive_Id__c),
                                                              Territory2TypeId = terrType[0].id,
                                                              Name = StgTerr.Name,
                                                              Territory2ModelId = TerritoryModelId,
                                                              DeveloperName = StgTerr.Name.trim().replaceAll(splChar_RegExp, '_'),
                                                              SubType__c = StgTerr.SubType__c
                                                             ));
                        }
                    } else {
                        DupStgList.add(StgTerr);
                        
                    }
                }
                catch(Exception ex) {
                    system.debug('@@ Exception occurred '+ex.getMessage()+' at '+ex.getLineNumber());
                    StgTerr.Status__c = 'Failure';
                    Controller_UnprocessTerr.put(StgTerr.JobId__c,Controller_UnprocessTerr.get(StgTerr.JobId__c)+1);
                    StgTerr.Error_message__c = 'Error : '+ex.getMessage()+' at '+ex.getLineNumber();
                } 
            }  
            try{
                system.debug('TerrList' + JSON.serialize(TerrList));
                
                system.debug('DupStgList' + DupStgList);
                system.debug('updateStgList' + updateStgList);
                integer i = 0;
                if (!TerrList.isEmpty()) {
                    for (Database.UpsertResult sr: Database.upsert(TerrList, false)) {
                        if (sr.isSuccess()) {
                            updateStgList[i].Status__c = 'Success';
                            updateStgList[i].Error_message__c='';
                            System.debug('Successfully inserted terr. Terr ID: ' + sr.getId()+' ref to'+updateStgList[i].id);
                            if (TerrList[i].Adaptive_Territory_Id__c != null && !AdaptiveId_TerrId.containskey(TerrList[i].Adaptive_Territory_Id__c))
                                AdaptiveId_TerrId.put(TerrList[i].Adaptive_Territory_Id__c,TerrList[i].id);
                        } else {
                            Controller_UnprocessTerr.put(updateStgList[i].JobId__c,Controller_UnprocessTerr.get(updateStgList[i].JobId__c)+1);
                            // Operation failed, so get all errors                
                            for (Database.Error err: sr.getErrors()) {
                                updateStgList[i].Error_message__c = updateStgList[i].Error_message__c==null ? (err.getMessage() + ':' + err.getFields() + '\n') : updateStgList[i].Error_message__c+' '+err.getMessage() + ':' + err.getFields() + '\n' ;
                            }
                            updateStgList[i].Status__c = 'Failure';
                        }
                        i++;
                    }
                    
                    for (Territory_Stage__c terrStage: DupStgList) {
                        Controller_UnprocessTerr.put(terrStage.JobId__c,Controller_UnprocessTerr.get(terrStage.JobId__c)+1);
                        terrStage.Status__c = 'Failure';
                        terrStage.Error_message__c = 'Duplicate record with territory stage record : ' + AdapId_StageId.get(terrStage.AdaptiveId__c) +
                            ' operating on common Territory : ' + AdaptiveId_TerrId.get(terrStage.AdaptiveId__c);
                        
                    }
                    
                }
                system.debug('delTerrList' + delTerrList);
                
                if(!delTerrList.isEmpty()){
                    i = 0;
                    for (Database.DeleteResult sr: Database.delete(delTerrList, false)) {
                        if (sr.isSuccess()) {
                            deleteStgList[i].Status__c = 'Success';
                            System.debug('Successfully deleted terr.: ' + sr.getId());
                            if (delTerrList[i].Adaptive_Territory_Id__c != null && !AdaptiveId_TerrId.containskey(delTerrList[i].Adaptive_Territory_Id__c))
                                AdaptiveId_TerrId.put(delTerrList[i].Adaptive_Territory_Id__c, delTerrList[i].id);
                        } else {
                            Controller_UnprocessTerr.put(deleteStgList[i].JobId__c,Controller_UnprocessTerr.get(deleteStgList[i].JobId__c)+1);
                            // Operation failed, so get all errors             
                            for (Database.Error err: sr.getErrors()) {
                                deleteStgList[i].Error_message__c = deleteStgList[i].Error_message__c==null ? (err.getMessage() + ':' + err.getFields() + '\n') : deleteStgList[i].Error_message__c+' '+err.getMessage() + ':' + err.getFields() + '\n' ;
                            }
                            deleteStgList[i].Status__c = 'Failure';
                        }
                        i++;
                    } 
                }
                  
                
            }
            catch (exception e) {
                errLog.add(LogError.CreateGenericErrorLog(CLASS_NAME, e, ERROR_FUNCTIONALITY));
            }
            
            if (terrStgObjectLst.size() > 0)
                terrStgObjectTotalLst.addall(terrStgObjectLst);
           if(reprocessLeafTerrIds.size()>0){
            totalReprocessLeafTerrIds.addall(reprocessLeafTerrIds);
            }  
            
            system.debug('Controller_UnprocessTerr' + Controller_UnprocessTerr);
        }
        
    }
    
    public void finish(Database.BatchableContext BC) {
        system.debug('isArchievedModel==>'+isArchievedModel+' runNextJob'+runNextJob);
        if (!errLog.isEmpty())
        {
            database.insert(errLog,false);
        } 
        //SF-13037
        List <ETMStage_Monitoring__c> updateInactiveETMStageList = new List <ETMStage_Monitoring__c> ();
        if(!inActiveETMStageIds.isEmpty()){
            for(Id jobId :inActiveETMStageIds){
                updateInactiveETMStageList.add(new ETMStage_Monitoring__c(id = jobId, Status__c = 'Failed', Stage_History__c = 'Error: No active Territory model found with this name.'));
            }
            Database.update(updateInactiveETMStageList, false);
        } //End

        // Process only if there are staging records
        if(!Controller_UnprocessTerr.isEmpty() && runNextJob){ 
            
           if(!isArchievedModel){
            // If territory type is not one of TART value
            for(Territory_Stage__c terrStg : [Select id,JobId__c from Territory_Stage__c where JobId__c IN: Controller_UnprocessTerr.keyset() and Hierarchy_Level__c='NA']){
                terrStg.Status__c = 'Failure';
                terrStg.Error_message__c = 'Invalid territory type';
                Controller_UnprocessTerr.put(terrStg.JobId__c,Controller_UnprocessTerr.get(terrStg.JobId__c)+1);
                terrStgObjectTotalLst.add(terrStg);
            }
            
            // Updating territory stage 
            if (terrStgObjectTotalLst.size()>0){
                database.update(terrStgObjectTotalLst, false);
            }
           } 
            List <ETMStage_Monitoring__c> ProcessedJob = new List <ETMStage_Monitoring__c> ();
            for (Id controllrId: Controller_UnprocessTerr.keyset()) {
                ProcessedJob.add(new ETMStage_Monitoring__c(id = controllrId, Total_Unprocessed_Territory2_Records__c = Controller_UnprocessTerr.get(controllrId))); //, Status__c='Complete'
                if(isArchievedModel){
                  ProcessedJob[ProcessedJob.size()-1].Status__c = 'Failed';
                    ProcessedJob[ProcessedJob.size()-1].Stage_History__c = 'Territory model in the Archived state cannot be updated';
                }
                else if(Controller_UnprocessTerr.get(controllrId)>0){
                    ProcessedJob[ProcessedJob.size()-1].Status__c = 'Failed';
                    ProcessedJob[ProcessedJob.size()-1].Stage_History__c = 'Terrritory:Failed';
                }
            }
            if(!totalReprocessLeafTerrIds.isEmpty()){     
                List<Territory_Owner_Assignment__c> toBeProcessedTerr_OwnerAssignment = new List<Territory_Owner_Assignment__c>();
                for(Id TerrId : totalReprocessLeafTerrIds){
                    toBeProcessedTerr_OwnerAssignment.add(new Territory_Owner_Assignment__c(LeafTerritoryId__c=TerrId,Functionality__c='Owner Assignment'));
                    
                } 
                if(!toBeProcessedTerr_OwnerAssignment.isEmpty()) {
                  database.insert(toBeProcessedTerr_OwnerAssignment,false);
                } 
              } 
              
            if (ProcessedJob.size() > 0)
                database.update(ProcessedJob, false);
            
            system.debug('JobIds in TerritoryModel batch'+Controller_UnprocessTerr.keyset());
            // Call the UTA creation batch
            if(!isArchievedModel)
            Database.executeBatch(new ETMCreateUserTerritoryAssociationBatch(Controller_UnprocessTerr.keyset(),TerrModelName),100); //SAL24-735
        }
        else if(!isETMJobsRunning && etmStageMonitoringId == null) { //SF-13037
            //SAL24-735
            Integer accBatchSize = 50;
            List<Territory_Management_Setup__mdt> fielSalesMdtBatchSize = [select Field_Value__c,Field_Type__c,Operator__c from Territory_Management_Setup__mdt where DeveloperName='ETM_Account_Batch_Size'];
            if(!fielSalesMdtBatchSize.isEmpty() && fielSalesMdtBatchSize[0].Field_Value__c!=null){
                accBatchSize = Integer.valueOf(fielSalesMdtBatchSize[0].Field_Value__c);
            }
            Database.executeBatch(new ETMTerritoryOwnerAssociationBatch('AccountUpdate',null,0), accBatchSize); //SAL24-735
        }
    }
    
   public void execute(SchedulableContext sc) {
       Database.executeBatch(new ETMCreateTerritoryModelBatch(), 1);          
    }
    
}