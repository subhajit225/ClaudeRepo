/*************************************************************************************************************
Description : To update account with adaptiveId with refernce from staging table created from adaptive system
To capture error logs against each staging record
To update the monitoring log with failed record count
Developer : Chaitra/Santosh 
Date : 2/2020
************************************************************************************************************/
public class ETMAdaptiveUpdateOnAccountBatch implements Database.Batchable<sObject>,Database.Stateful {
    
    public Set<Id> jobIds = new Set<Id>();
    public string TerrModelName ;
    public Map<String, String> acctStageTerTypeAccIdMap = new Map<String, String>();
    public Map <Id,Integer> Controller_UnprocessAcc = new Map <Id,Integer>(); 
    public String TYPE_SEPARATOR = ':';    //***PL26-10
    public String TYPE_ID_SET_SEPARATOR = ';';   //***PL26-10
    public String IDS_SEPARATOR = ',';       //***PL26-10 
        
    
/*****************************************
  Constructor
******************************************/  
    
    public  ETMAdaptiveUpdateOnAccountBatch(set<id>jobIds,String terrModelName) {
        this.TerrModelName = terrModelName;
        this.jobIds = jobIds;
        for(Id JID : jobIds){ 
            Controller_UnprocessAcc.put(JID,0);
        }
        System.debug('jobId@@'+jobIds);
    }
    
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query;
        query = 'SELECT Id,Account__c,Error_message__c,JobId__c,Status__c,TerritoryAdaptive_Id__c,Account_Move_Reason__c, ' //SAL25-608
            + ' Territory_Structure_Type__c ' //PL26-10
            + ' FROM Account_Stage__c '
            + ' WHERE JobId__c IN :jobIds and status__c!=\'Success\' ORDER BY Createddate desc ' ;
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Account_Stage__c> accountStageList) {
        
        Map<Id, Account> accountUpdateMap = new Map<Id, Account>();
        Map<String, Account_Stage__c> duplicatedAccountRecords = new Map<String, Account_Stage__c>();
        Map<Integer, List<Account_Stage__c>> indToValidAccountStageListMap = new Map<Integer, List<Account_Stage__c>>();
        //SF-13037
        set<String> accIds = new set<String>();
        Set<String> StgAdaptiveIds = new Set<String>();
        for(Account_Stage__c acctStage : accountStageList) {
           if(acctStage.Account__c!=null)
           accIds.add(acctStage.Account__c);
           //SF-13037
           if(acctStage.TerritoryAdaptive_Id__c!=null) StgAdaptiveIds.add(acctStage.TerritoryAdaptive_Id__c);
        }
        //*** PL26-10: added non core fields to SOQL
        Map<Id,account> accMap = new Map<ID, Account>([select id,Adaptive_Territory_Id__c, Non_Core_Adaptive_Territory_Ids__c, Non_Core_Type_and_Adaptive_Id__c from account where id IN:accIds]); //and Adaptive_Territory_Id__c!=null
        //SF-13037
        Map<String, String> adaptiveTypeIdToTerritoryMap = new Map<String, String>(); 
        for(Territory2 ter : [SELECT Id,Adaptive_Territory_Id__c, Territory_Structure_Type__c FROM Territory2 WHERE Adaptive_Territory_Id__c IN :StgAdaptiveIds AND Territory2Model.Name = :terrModelName]) {
            String terrType = String.isBlank(ter.Territory_Structure_Type__c) ? 'Core' : ter.Territory_Structure_Type__c;
            adaptiveTypeIdToTerritoryMap.put(terrType +TYPE_SEPARATOR+ ter.Adaptive_Territory_Id__c, ter.Id);
        } //End //*** PL26-10: change map to type + terAdaptiveId map
        
        Integer iterationInd = 0;
        for(Account_Stage__c acctStage : accountStageList) {
            try{ 
                
                acctStage.Territory_Structure_Type__c = String.isBlank(acctStage.Territory_Structure_Type__c) ? 'Core' : acctStage.Territory_Structure_Type__c;
                
             if(String.isNotBlank(acctStage.Error_message__c) && acctStage.Error_message__c.startsWith('Duplicate record')){
                      continue;
                    }
                
                Account account = accMap.containskey(acctStage.Account__c) ? accMap.get(acctStage.Account__c) : new Account(); //*** PL26-10
                
                //*** PL26-10: get list of PLS type and adaptive Id string
                List<String> accNonCoreTypeAndAdaptiveIds = String.isNotBlank(account.Non_Core_Type_and_Adaptive_Id__c) ?
                     account.Non_Core_Type_and_Adaptive_Id__c.contains(TYPE_ID_SET_SEPARATOR) ? account.Non_Core_Type_and_Adaptive_Id__c.split(TYPE_ID_SET_SEPARATOR) : 
                     new List<String>{account.Non_Core_Type_and_Adaptive_Id__c} :
                     new List<String>();
                    
                String accStageTerTypeAndAdaptiveId = acctStage.Territory_Structure_Type__c+TYPE_SEPARATOR+acctStage.TerritoryAdaptive_Id__c;
                String key = acctStage.Territory_Structure_Type__c+'_'+acctStage.Account__c;
                
                //If adaptive id already present on account, stop processing
                if(!acctStageTerTypeAccIdMap.containsKey(key) &&  
                   (account.Adaptive_Territory_Id__c == acctStage.TerritoryAdaptive_Id__c || accNonCoreTypeAndAdaptiveIds.contains(accStageTerTypeAndAdaptiveId))){ //&& acctStage.TerritoryAdaptive_Id__c!=null
                  acctStage.Status__c = 'Failure';
                  Controller_UnprocessAcc.put(acctStage.JobId__c,Controller_UnprocessAcc.get(acctStage.JobId__c)+1);
                  acctStage.Error_message__c = 'Data already available';
                       acctStageTerTypeAccIdMap.put(key, acctStage.Id);
                  continue;
               }
                
               //SF-13037 - Territory Id not match with present territories: invalid territoty Id
                if(acctStage.TerritoryAdaptive_Id__c != null && !adaptiveTypeIdToTerritoryMap.containsKey(accStageTerTypeAndAdaptiveId)){
                acctStage.Status__c = 'Failure';
                Controller_UnprocessAcc.put(acctStage.JobId__c,Controller_UnprocessAcc.get(acctStage.JobId__c)+1);
                acctStage.Error_message__c = 'Error : AdaptiveId doesn\'t belong to current Model';
                    acctStageTerTypeAccIdMap.put(key, acctStage.Id);
                continue;
               } //End
                                
                //Assign Adaptive id to account
                if(!acctStageTerTypeAccIdMap.containsKey(key)) {
                    if(!accountUpdateMap.containsKey(account.Id)){
                        accountUpdateMap.put(account.Id, getAccountWithAdaptiveId(account, acctStage));
                    } else {
                        accountUpdateMap.put(account.Id, getAccountWithAdaptiveId(accountUpdateMap.get(account.Id), acctStage));
                    }                    
                    
                    if(!indToValidAccountStageListMap.containsKey(iterationInd)) {
                        indToValidAccountStageListMap.put(iterationInd, new List<Account_Stage__c>());
                    }   
                    indToValidAccountStageListMap.get(iterationInd).add(acctStage);
                    
                    acctStageTerTypeAccIdMap.put(key, acctStage.Id);
                } else {
                    duplicatedAccountRecords.put(acctStage.Id, acctStage);
                }
            }
            catch(Exception ex) {
                system.debug('@@ Exception occurred '+ex.getMessage()+' at '+ex.getLineNumber());
                acctStage.Status__c = 'Failure';
                Controller_UnprocessAcc.put(acctStage.JobId__c,Controller_UnprocessAcc.get(acctStage.JobId__c)+1);
                //SF-13037
                String errMsg = (ex.getMessage().contains('Invalid id')) ? 'Error : Invalid Account Id' : 'Error : '+ex.getMessage()+' at '+ex.getLineNumber();
                //acctStage.Error_message__c = 'Error : '+ex.getMessage()+' at '+ex.getLineNumber();
                acctStage.Error_message__c = errMsg;
            } 
        }
        
        
        try{
            if(!accountUpdateMap.isEmpty()) {
                Database.SaveResult[] updateResultList = Database.update(accountUpdateMap.values(), false);
                Integer index = 0;
                for (Database.SaveResult sr : updateResultList) {
                    if(sr.isSuccess()) {
                        if(indToValidAccountStageListMap.containsKey(index)){
                            List<Account_Stage__c>  validAccountStageList = indToValidAccountStageListMap.get(index);
                            for(Account_Stage__c accStage : validAccountStageList) {
                                accStage.Status__c = 'Success';
                                accStage.Error_message__c='';
                            }
                        }
                    } else {
                        // Operation failed, so get all errors 
                        if(indToValidAccountStageListMap.containsKey(index)){
                            List<Account_Stage__c>  validAccountStageList = indToValidAccountStageListMap.get(index);
                            for(Account_Stage__c accStage : validAccountStageList) {
                                
                                Controller_UnprocessAcc.put(accStage.JobId__c,Controller_UnprocessAcc.get(accStage.JobId__c)+1);
                        String errorMessage = '';
                        for(Database.Error err : sr.getErrors()) {
                            errorMessage += 'Status Code : ' + err.getStatusCode() + ':' + err.getMessage() + ':' + err.getFields() +'\n';
                        }
                                
                                accStage.Status__c = 'Failure';
                                accStage.Error_message__c= errorMessage;
                            }
                        }                         
                    }
                    index++;
                }
            }
            
            
            for(Account_Stage__c acctStage : duplicatedAccountRecords.values()) {
                Controller_UnprocessAcc.put(acctStage.JobId__c,Controller_UnprocessAcc.get(acctStage.JobId__c)+1);
                acctStage.Status__c = 'Failure';
                acctStage.Error_message__c = 'Duplicate record with account stage record: ' + acctStageTerTypeAccIdMap.get(acctStage.Territory_Structure_Type__c+'_'+acctStage.Account__c);  
            }
            
            Database.update(accountStageList, false);
        }
        catch (exception e) {
            insert LogError.CreateGenericErrorLog('ETMAdaptiveUpdateOnAccountBatch', e, 'ETM');
        }     
    } 
    
    public void finish(Database.BatchableContext BC) {
    
        //Update ETm stage records with count of errors
         List<ETMStage_Monitoring__c> ProcessedJob = [select id,Stage_History__c from ETMStage_Monitoring__c where id IN:Controller_UnprocessAcc.keySet()];//
          for (ETMStage_Monitoring__c etmLog: ProcessedJob) {
            etmLog.Total_Unprocessed_Account_Records__c = Controller_UnprocessAcc.get(etmLog.id);
            if(Controller_UnprocessAcc.get(etmLog.id)>0){
                etmLog.Status__c = 'Failed';
                etmLog.Stage_History__c = string.isBlank(etmLog.Stage_History__c)?'AccStage:Failed':etmLog.Stage_History__c+'\n AccStage:Failed';
            }
        }
        
        if (ProcessedJob.size() > 0)
            database.update(ProcessedJob, false);   
        // Call Assignmentrule and activate TM batch
        /* ETM_ArchivingTerritoryModel  SetTerritoryModel = new ETM_ArchivingTerritoryModel();
           SetTerritoryModel.archivingModel(TerrModelName); */
           System.enqueueJob(new ETMArchieveTerritoryModel(Controller_UnprocessAcc.keyset(),TerrModelName));  
    } 
    
    //***PL26-10: populate Non Core Adaptive Id fields and get account 
    public Account getAccountWithAdaptiveId(Account account, Account_Stage__c acctStage) {
        account.Is_RSE_Added_Manually__c = false;

        //Core territory type
        if(String.isBlank(acctStage.Territory_Structure_Type__c) || acctStage.Territory_Structure_Type__c.equalsIgnoreCase('Core')){
            account.Adaptive_Territory_Id__c = acctStage.TerritoryAdaptive_Id__c;
            account.Account_Move_Reason__c = acctStage.Account_Move_Reason__c;
            account.Last_Account_Move_Date__c = system.today();
        } else if(String.isNotBlank(account.Non_Core_Adaptive_Territory_Ids__c) && String.isNotBlank(account.Non_Core_Type_and_Adaptive_Id__c)){
            
            //Non-core territory type
            String newNonCoreIds = account.Non_Core_Adaptive_Territory_Ids__c + IDS_SEPARATOR + acctStage.TerritoryAdaptive_Id__c;
            String newNonCoreTypeIds = account.Non_Core_Type_and_Adaptive_Id__c + TYPE_ID_SET_SEPARATOR + acctStage.Territory_Structure_Type__c + TYPE_SEPARATOR + acctStage.TerritoryAdaptive_Id__c;
            
            //Multiple type-Ids are exists
            if(account.Non_Core_Type_and_Adaptive_Id__c.contains(TYPE_ID_SET_SEPARATOR)){
                List<String> typeAndAdaptiveIdsList =  account.Non_Core_Type_and_Adaptive_Id__c.split(TYPE_ID_SET_SEPARATOR);
                
                for(String typeAndId : typeAndAdaptiveIdsList) {
                    if(typeAndId.contains(TYPE_SEPARATOR)){
                        List<String> typeAndIdLst = typeAndId.split(TYPE_SEPARATOR);
                        //If similar type's adaptive Id is already exists, replace it with new Id
                        if(typeAndIdLst[0] == acctStage.Territory_Structure_Type__c) {
                            newNonCoreIds = account.Non_Core_Adaptive_Territory_Ids__c.replace(typeAndIdLst[1], acctStage.TerritoryAdaptive_Id__c);
                            newNonCoreTypeIds = account.Non_Core_Type_and_Adaptive_Id__c.replace(typeAndIdLst[1], acctStage.TerritoryAdaptive_Id__c);
                        }
                    }
                }
            } else if(account.Non_Core_Type_and_Adaptive_Id__c.contains(TYPE_SEPARATOR) && account.Non_Core_Type_and_Adaptive_Id__c.split(TYPE_SEPARATOR)[0] == acctStage.Territory_Structure_Type__c){
                //Non-core adaptive id already exists(single), if type matches replace id
                newNonCoreIds = acctStage.TerritoryAdaptive_Id__c;
                newNonCoreTypeIds = acctStage.Territory_Structure_Type__c + TYPE_SEPARATOR + acctStage.TerritoryAdaptive_Id__c;
            }
            account.Non_Core_Adaptive_Territory_Ids__c = newNonCoreIds;
            account.Non_Core_Type_and_Adaptive_Id__c = newNonCoreTypeIds;
                        
        } else {
            //If non-core ids does not exist on account yet, assign here. 
            account.Non_Core_Adaptive_Territory_Ids__c = acctStage.TerritoryAdaptive_Id__c;
            account.Non_Core_Type_and_Adaptive_Id__c = acctStage.Territory_Structure_Type__c + TYPE_SEPARATOR + acctStage.TerritoryAdaptive_Id__c;
        }
        return account;
    } 
}