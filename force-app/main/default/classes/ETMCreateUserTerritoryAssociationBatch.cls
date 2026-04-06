/***************************************************************************************************************
Description : To create/update the UserTerritoryAssociation based on staging table created from adaptive system
To capture error logs against each staging record
To update the monitoring log with failed record count
Developer : Chaitra/Santosh
Date : 1/2020
****************************************************************************************************************/

public class ETMCreateUserTerritoryAssociationBatch implements Database.Batchable<sObject>,Database.Stateful {
    public static set<Territory_Owner_Assignment__c> reprocessTerr = new set<Territory_Owner_Assignment__c>(); // Holds id's of leaf territory or UTA of sales enginerr that needs to be reprocessed for user assignment on account ,opportunity
    public final string CLASS_NAME = 'ETMCreateUserTerritoryAssociationBatch';
    public final string DUMMY_STAGE ='Dummy existing rec delete';
    public List<Territory_Owner_Assignment__c> totalReprocessTerr = new List<Territory_Owner_Assignment__c>();
    public Map <string,Id> UserId_StageId = new Map < string, Id > ();
    public static string ADD_UPDATE_OPERATION ='AddUpdate';
    public List <Custom_Error_Log__c> errLog = new List <Custom_Error_Log__c> ();
    public set<Id>JobIds = new set<id>();
    //Id terModalId;
    public string terrModelName ;
    List<UserTerritoryAssociation_Stage__c> stageListFinalUpdate = new List<UserTerritoryAssociation_Stage__c>();
    Map<Id,Integer> jobIdCountMap = new Map<Id,Integer>();
    
/*****************************************
Constructor
******************************************/ 
    public  ETMCreateUserTerritoryAssociationBatch(set<Id>JobIds,String terrModelName) { //, Id territorymodelId
        this.terrModelName = terrModelName;
        //this.terModalId = territorymodelId;
        this.JobIds = JobIds;
        for(Id JID : JobIds){
            jobIdCountMap.put(JID,0);
        }
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {  
        String query;
        if(!jobIdCountMap.isEmpty()) {
            //ETM-184: Start Date and End Date updates for commissions
            query = 'SELECT Id,name,Adaptive_Id__c,Area__c,JobId__c,Region__c,Error_message__c,RoleInTerritory2__c,Status__c, Start_Date__c, End_Date__c, '
                + ' Territory__c,Theatre__c,User__c,SQL_Operation__c FROM UserTerritoryAssociation_Stage__c'
                + ' WHERE JobId__c IN: jobIds and status__c!=\'Success\' order by SQL_Operation__c desc ,createddate desc' ;
            
            system.debug('CP query'+query);
            system.debug('CP UTA - jobIds'+jobIds);
            return Database.getQueryLocator(query);
            
        }else{
            return Database.getQueryLocator('select id from UserTerritoryAssociation_stage__C limit 0');
        }
    }
    
    
    
    public void execute(Database.BatchableContext BC, List<UserTerritoryAssociation_Stage__c> utaStgeList) {
       
       /* UserTerritory2Association UTA1 = new UserTerritory2Association(Territory2Id='0MI1g0000004qvRGAQ', UserId='0051W000005as3aQAA', RoleInTerritory2='VP of SE');
        upsert uta1;
        system.debug('uta==>CP'+uta1); */
    
        reprocessTerr = new set<Territory_Owner_Assignment__c>(); //SAL25-57
        system.debug('@@ utaStgeList '+utaStgeList);
        Set<String> adaptiveIdSet = new Set<String>();
        set<Id>deleteUTAIds = new set<id>();
        Integer index = 0;
        UserTerritory2Association currentUTA;
        string stageId;
        Set<String> userId = new Set<String>();
        Map<String, String> territoryMap = new Map<String, String>();
        Map<String,UserTerritory2Association> existingUTAMap = new Map<String, UserTerritory2Association>();
        List<UserTerritory2Association> utaUpsertList = new List<UserTerritory2Association>();
        List<UserTerritory2Association> utadeleteList = new List<UserTerritory2Association>(); 
        String errorMessage = '';
        List<UserTerritoryAssociation_Stage__c> validUTAStgeList = new List<UserTerritoryAssociation_Stage__c>();
        List<UserTerritoryAssociation_Stage__c> deleteUTAStgeList = new List<UserTerritoryAssociation_Stage__c>();
        List<UserTerritoryAssociation_Stage__c> duplicateUTAStageList = new List<UserTerritoryAssociation_Stage__c>();
        Set<string> inactiveUsers = new Set<string>();
        UserTerritory2AssociationTriggerHelper.runningContext ='ETM_UTABatch';
        //ETM-137
        UserTerritory2AssociationTriggerHandler.runUTAHistoryMethod = false;
        //ETM-184: Start Date and End Date updates for commissions
        //Set<Id> deleteSuccessUTAIds = new Set<Id>();
        //Set<Id> insertSuccessUTAIds = new Set<Id>();
        Map<Id, Date> insertUTAMap = new Map<Id, Date>();
        Map<Id, Date> updateUTAHistMap = new Map<Id, Date>();
        Set<Id> updateUTAIds = new Set<Id>();
        for(UserTerritoryAssociation_Stage__c uta : utaStgeList) {
            adaptiveIdSet.add(uta.Adaptive_Id__c);
            userId.add(uta.User__c);
        }
        for(User u : [select Id,name,isactive from user where Id IN: userId and isactive=false]){  
            inactiveUsers.add(u.Id); 
        }
        for(Territory2 ter : [SELECT Id,Adaptive_Territory_Id__c FROM Territory2 WHERE Adaptive_Territory_Id__c IN :adaptiveIdSet AND Territory2Model.Name = :terrModelName]) {
            territoryMap.put(ter.Adaptive_Territory_Id__c, ter.Id);
        }
        //to check existing records or association
        for(UserTerritory2Association uta : [SELECT Id, territory2.Adaptive_Territory_Id__c, UserId,RoleInTerritory2 FROM UserTerritory2Association WHERE (territory2Id IN : territoryMap.values() OR UserId IN :userId) AND territory2.Territory2Model.Name = :terrModelName]) {
            if(!existingUTAMap.containsKey(uta.UserId+'-'+uta.territory2.Adaptive_Territory_Id__c)){
             existingUTAMap.put(uta.UserId+'-'+uta.territory2.Adaptive_Territory_Id__c,uta);
        }
        else{
             System.debug('CP Error : Duplicate Users with same territory ');
        }
        }
        system.debug('@@ existingUTAMap '+existingUTAMap);
        system.debug('@@ territoryMap '+territoryMap);
        
        for(UserTerritoryAssociation_Stage__c utaStage : utaStgeList) {
            system.debug('Start processing'+utaStage);
             if(String.isNotBlank(utaStage.Error_message__c) && utaStage.Error_message__c.startsWith('Duplicate record')){
                continue;
              }
            if(existingUTAMap.containsKey(utaStage.User__c+'-'+utaStage.Adaptive_Id__c)){
            currentUTA = existingUTAMap.get(utaStage.User__c+'-'+utaStage.Adaptive_Id__c);
        }
        else
            currentUTA = null ;
            try {
                if(utaStage.User__c== NULL || utaStage.Adaptive_Id__c == NULL){
                    utaStage.Status__c = 'Failure';
                    jobIdCountMap.put(utaStage.JobId__c,jobIdCountMap.get(utaStage.JobId__c)+1); 
                    utaStage.Error_message__c = 'Error : Adaptive Id or User is blank';
                }
                else if(UserId_StageId.containsKey(utaStage.User__c+'-'+utaStage.Adaptive_Id__c+'-'+utaStage.SQL_Operation__c) || UserId_StageId.containsKey(utaStage.User__c+'-'+utaStage.Adaptive_Id__c+'-'+ADD_UPDATE_OPERATION)){
                    duplicateUTAStageList.add(utaStage);
                }
                else if(!inactiveUsers.isEmpty() && inactiveUsers.contains(utaStage.User__c)){
                    utaStage.Status__c = 'Failure';
                    jobIdCountMap.put(utaStage.JobId__c,jobIdCountMap.get(utaStage.JobId__c)+1); 
                    utaStage.Error_message__c = 'Error : User is Inactive';
                }
                else if(!territoryMap.containskey(utaStage.Adaptive_Id__c)){  
                    utaStage.Status__c = 'Failure';
                    jobIdCountMap.put(utaStage.JobId__c,jobIdCountMap.get(utaStage.JobId__c)+1); 
                    utaStage.Error_message__c = 'Error : AdaptiveId doesn\'t belong to current Model';
                    
                } 
                else {
                    // main logic
                    
                    if(utaStage.SQL_Operation__c!=null && utaStage.SQL_Operation__c.equalsignorecase('Delete')){
                        system.debug('In delete -'+utaStage);
                        if(currentUTA!=null && currentUTA.RoleInTerritory2 == utaStage.RoleInTerritory2__c 
                           &&  currentUTA.territory2.Adaptive_Territory_Id__c == utaStage.Adaptive_Id__c) {

                            if(!deleteUTAIds.contains(currentUTA.id)){
                                  utadeleteList.add(currentUTA);
                                  deleteUTAStgeList.add(utaStage);
                                  deleteUTAIds.add(currentUTA.id);
                              }
                          }    

                      else{
                            jobIdCountMap.put(utaStage.JobId__c,jobIdCountMap.get(utaStage.JobId__c)+1);
                            utaStage.Status__c = 'Failure';
                            utaStage.Error_message__c = 'No matching record found for delete' ;   
                         }
                                                 UserId_StageId.put(utaStage.User__c+'-'+utaStage.Adaptive_Id__c+'-'+utaStage.SQL_Operation__c, utaStage.Id);    
                       }
                       
                    else{  // Update and add operation
                       
                        if(currentUTA!=null && currentUTA.territory2.Adaptive_Territory_Id__c == utaStage.Adaptive_Id__c && currentUTA.RoleInTerritory2 == utaStage.RoleInTerritory2__c) {
                             
                             jobIdCountMap.put(utaStage.JobId__c,jobIdCountMap.get(utaStage.JobId__c)+1);
                            utaStage.Status__c = 'Failure';
                            utaStage.Error_message__c = 'Data already available' ;
                            //ETM-184: Start Date and End Date updates for commissions
                            updateUTAHistMap.put(currentUTA.Id, utaStage.Start_Date__c);
                            updateUTAIds.add(currentUTA.Id);
                       } 
                        else{
                         
                          
                         /*  if(existingUTAMap.containsKey(utaStage.User__c) && existingUTAMap.containsKey(utaStage.User__c) && !deleteUTAIds.contains(existingUTAMap.get(utaStage.User__c).id)){
                                deleteUTAStgeList.add(new UserTerritoryAssociation_Stage__c(name=DUMMY_STAGE));
                                utadeleteList.add(UTArec);
                            }  */
                            if(utaStage.SQL_Operation__c.equalsignorecase('Update')){
                                 utaStage.Status__c = 'Failure';
                            utaStage.Error_message__c = 'UPDATE SQL operation is out of scope' ;
                            continue;
                            }
 
                            UserTerritory2Association newUTA = new UserTerritory2Association (
                                territory2Id = territoryMap.get(utaStage.Adaptive_Id__c), 
                                UserId = utaStage.User__c, 
                                RoleInTerritory2 = utaStage.RoleInTerritory2__c
                            );
                            utaUpsertList.add(newUTA);
                            validUTAStgeList.add(utaStage);
                            
                        }
                        UserId_StageId.put(utaStage.User__c+'-'+utaStage.Adaptive_Id__c+'-'+ADD_UPDATE_OPERATION, utaStage.Id);
                    }
                }   
            } catch(Exception ex) {
                system.debug('@@ Exception occurred '+ex.getMessage()+' at '+ex.getLineNumber());
                utaStage.Status__c = 'Failure';
                jobIdCountMap.put(utaStage.JobId__c,jobIdCountMap.get(utaStage.JobId__c)+1);
                utaStage.Error_message__c = ex.getMessage()+' at line'+ex.getLineNumber();
                
            }     
        }
       
        system.debug('@@ utadeleteList '+utadeleteList);
        system.debug('@@ utaUpsertList '+utaUpsertList);
        //DML for utaUpsertList + userUpdateMap
        if(!utadeleteList.isEmpty()) {
            index = 0 ;
            for (Database.deleteResult ur : Database.delete(utadeleteList, false)) {
                if(!deleteUTAStgeList.get(index).name.equalsIgnoreCase(DUMMY_STAGE)){
                    if(ur.isSuccess()) {
                        deleteUTAStgeList.get(index).Status__c = 'Success';
                        deleteUTAStgeList.get(index).Error_message__c='';
                        System.debug('-------------Success @@------------'+deleteUTAStgeList.get(index));
                        //ETM-137
                        //ETM-184: Start Date and End Date updates for commissions
                        //deleteSuccessUTAIds.add(ur.Id);
                        updateUTAHistMap.put(ur.Id, deleteUTAStgeList.get(index).End_Date__c);
                    } else {
                        // Operation failed, so get all errors   
                        errorMessage = '';
                        System.debug('-------------Failure @@------------'+deleteUTAStgeList.get(index));
                        for(Database.Error err : ur.getErrors()) {
                            errorMessage += 'Status Code : ' + err.getStatusCode() + ':' + err.getMessage() + ':' + err.getFields() +'\n';
                        }
                        deleteUTAStgeList.get(index).Status__c = 'Failure';
                        jobIdCountMap.put(deleteUTAStgeList.get(index).JobId__c,jobIdCountMap.get(deleteUTAStgeList.get(index).JobId__c)+1);
                        deleteUTAStgeList.get(index).Error_message__c = errorMessage;
                    }
                    
                }
                else{
                    if(!ur.isSuccess()) {
                        errorMessage = '';
                        for(Database.Error err : ur.getErrors()) {
                            errorMessage += 'Status Code : ' + err.getStatusCode() + ':' + err.getMessage() + ':' + err.getFields() +'\n';
                        }
                        errLog.add(new Custom_Error_Log__c(Functionality__c = 'ETM', FailedRecords__c = utadeleteList.get(index).id, Exception_Message__c = errorMessage, Class__c =CLASS_NAME)); // CP Check on adding extra details like userId and territoryId
                        
                    }
                }
                index++;
            }
        }
        
        if(!utaUpsertList.isEmpty()) {
            index = 0;
            for (Database.UpsertResult ur : Database.upsert(utaUpsertList, false)) {
                if(ur.isSuccess()) {
                    validUTAStgeList.get(index).Status__c = 'Success';
                    validUTAStgeList.get(index).Error_message__c='';
                    System.debug('-------------Success @@------------'+validUTAStgeList.get(index));
                    //ETM-137
                    //ETM-184: Start Date and End Date updates for commissions
                    //insertSuccessUTAIds.add(ur.Id);
                    insertUTAMap.put(ur.Id, validUTAStgeList.get(index).Start_Date__c);
                } else {
                    // Operation failed, so get all errors   
                    errorMessage = '';
                    System.debug('-------------Failure @@------------'+validUTAStgeList.get(index));
                    System.debug('utaUpsertList'+utaUpsertList.get(index));
                    for(Database.Error err : ur.getErrors()) {
                       System.debug('UTA error'+ err.getMessage());
                        errorMessage += 'Status Code : ' + err.getStatusCode() + ':' + err.getMessage() + ':' + err.getFields() +'\n';
                    }
                    validUTAStgeList.get(index).Status__c = 'Failure';
                    jobIdCountMap.put(validUTAStgeList.get(index).JobId__c,jobIdCountMap.get(validUTAStgeList.get(index).JobId__c)+1);
                    validUTAStgeList.get(index).Error_message__c = errorMessage;
                }
                index++;
            }  
        }
        system.debug('batch LeafTerrId'+reprocessTerr);
        //SAL25-57
        //if(reprocessTerr.size()>0){
        //    totalReprocessTerr.addall(reprocessTerr);
        //}
        //update errors on staging object
        for(UserTerritoryAssociation_Stage__c utaStage : duplicateUTAStageList) {
            if(utaStage.SQL_Operation__c != NULL && utaStage.SQL_Operation__c.equalsignorecase('Delete')){
                stageId = UserId_StageId.get(utaStage.User__c+'-'+utaStage.Adaptive_Id__c+'-'+utaStage.SQL_Operation__c)==null?UserId_StageId.get(utaStage.User__c+'-'+utaStage.Adaptive_Id__c+'-'+ADD_UPDATE_OPERATION):UserId_StageId.get(utaStage.User__c+'-'+utaStage.Adaptive_Id__c+'-'+utaStage.SQL_Operation__c);
            }
            else{
                stageId = utaStage.SQL_Operation__c == NULL || UserId_StageId.get(utaStage.User__c+'-'+utaStage.Adaptive_Id__c+'-'+utaStage.SQL_Operation__c)==null?UserId_StageId.get(utaStage.User__c+'-'+utaStage.Adaptive_Id__c+'-'+ADD_UPDATE_OPERATION):UserId_StageId.get(utaStage.User__c+'-'+utaStage.Adaptive_Id__c+'-'+utaStage.SQL_Operation__c);
                
            }
            utaStage.Status__c = 'Failure';
            jobIdCountMap.put(utaStage.JobId__c,jobIdCountMap.get(utaStage.JobId__c)+1);
            system.debug('stageId'+stageId);
            system.debug('UserId_StageId'+JSON.serialize(UserId_StageId));
            system.debug('utaStageUserId'+utaStage.id);
            
            utaStage.Error_message__c = 'Duplicate record with Userterritory stage record : '+stageId ;
        }
        
        stageListFinalUpdate.addAll(utaStgeList);
        
        //ETM-137
        //ETM-184: Start Date and End Date updates for commissions
        //System.enqueueJob(new UserTerritoryAssociationHistoryHelper(insertSuccessUTAIds, deleteSuccessUTAIds, 'BATCH'));
        //SAL25-57 - //Added a parameter to update the logic to create TerritoryOwnerAssignment record - 
        //System.enqueueJob(new UserTerritoryAssociationHistoryHelper(insertUTAMap, updateUTAHistMap, updateUTAIds, 'BATCH'));
        System.enqueueJob(new UserTerritoryAssociationHistoryHelper(reprocessTerr,insertUTAMap, updateUTAHistMap, updateUTAIds, 'BATCH'));
        
    } 
    
    
    
    public void finish(Database.BatchableContext BC) {
        try{
        if(errLog.size()>0){
            insert errLog;
        }
        if(!jobIdCountMap.isEmpty()){
            
            //SAL25-57
            //system.debug('totalReprocessTerr'+totalReprocessTerr);    
            //if(totalReprocessTerr.size()>0){     
            //    Database.insert(totalReprocessTerr,false) ;  
            //}  
            //Update ETm stage records with count of errors
            List<ETMStage_Monitoring__c> etmList = new List<ETMStage_Monitoring__c>();
            for(ETMStage_Monitoring__c etmLog : [select id,Stage_History__c from ETMStage_Monitoring__c where id IN:jobIdCountMap.keySet()]){ 
                etmLog.Total_Unprocessed_UTA_Records__c = jobIdCountMap.get(etmLog.id);
                 if(jobIdCountMap.get(etmLog.id)>0){
                    etmLog.Status__c = 'Failed';
                    etmLog.Stage_History__c = string.isBlank(etmLog.Stage_History__c)?'UTA:Failed':etmLog.Stage_History__c+'\n UTA:Failed';
                    etmList.add(etmLog);
                }
             }
             if(etmList.size()>0)
            database.update(etmList,false);
            System.debug('--------@@-----'+etmList);
            database.update(stageListFinalUpdate,false);
            
             // Call Account stage batch
            Database.executeBatch(new ETMAdaptiveUpdateOnAccountBatch(jobIdCountMap.keyset(),terrModelName));
           
        } 
         
        }
        Catch(exception e){
          insert LogError.CreateGenericErrorLog('ETMCreateUserTerritoryAssociationBatch',e,'ETM');      
         }   
        
    } 
}