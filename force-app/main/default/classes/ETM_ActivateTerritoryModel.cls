/** ***********************************************************************************
 * @File Name          : ETM_ActivateTerritoryModel.cls
 * @Description        : The Class checks if the territory is activated or not if the 
 *                       territory model is not activated then we are activating the 
 *                       territory model and calling the next batch.
 * @Author             : Bhushan Patil
 * @Group              : 
 * @Last Modified By   : Bhushan Patil
 * @Last Modified On   : 15/4/2020, 2:39:59 pm
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    2/3/2020           Bhushan Patil          Initial Version
***************************************************************************************/
global class ETM_ActivateTerritoryModel implements Schedulable{
    List<ETMStage_Monitoring__c> lstMonitor;
    Integer DELAY_MIN = 10; 
    String CLASS_NAME = 'ETM_ActivateTerritoryModel';
    String ERROR_FUNCTIONALITY = 'ETM';
    String strModelName;
    String strArchivedTerrName;
    public Boolean activatingTerritory = false;
    public set<id>jobIds = new set<id>(); 
    public ETM_ActivateTerritoryModel(set<id>jobIds,String modelName,String strArchivedTerrName) {
        strModelName = modelName;
        this.jobIds = jobIds;
        this.strArchivedTerrName = strArchivedTerrName;
    }

    //ETM-137
    String strArchivedTerrNameTemp;

    /**
    * @description 
    * @author Bhushan Patil | 19/3/2020 
    * @param SchedulableContext SC 
    * @return void 
    **/
    global void execute(SchedulableContext SC) {
        if(strArchivedTerrName != null){
            List<Territory2Model> lstArchivedModel = [
                Select 
                    Id,
                    State,
                    Name
                from
                    Territory2Model
                Where 
                    Name =: strArchivedTerrName
                    AND State = 'Archived'];
            if(!lstArchivedModel.isEmpty()){
                UpdateTerritoryLogs(jobIds,'Territory Archived : ',strArchivedTerrName + ' \n ');
                //ETM-137
                strArchivedTerrNameTemp = strArchivedTerrName;
            }                    
        }//End of if
        for(Territory_Management_Setup__mdt setupData: [
            select 
                Field_Value__c  
            from 
                Territory_Management_Setup__mdt 
            where 
                DeveloperName ='TimeDelay_Activate']) {
        if(setupData.Field_Value__c != null)
            DELAY_MIN = integer.valueof(setupData.Field_Value__c);  
        }
        List<Territory2Model> lstmodel = [
            Select 
                Id,
                State,
                Name
            from
                Territory2Model
            Where 
                Name =: strModelName 
            AND
                state != 'Active'];
        if(!lstmodel.isEmpty()
        && lstmodel[0].state == 'Planning'){
            lstmodel[0].state = 'Activating';
            activatingTerritory = true;
        }
        try{
            //If the model is not activated yet then activating the model and running the next batch after 10 minutes
            //The time delay interval is stored in Territory_Management_Setup__mdt metadata and if the record is not found
            //Then we are using the local variable to set the time delay. 
            if(activatingTerritory){
                Update lstmodel;
                //UpdateTerritoryLogs(jobIds,' Territory Activating : ',strModelName);    
                DateTime scheduleTime = Datetime.now().addminutes(DELAY_MIN);
                String hour = String.valueOf(scheduleTime.hour()); 
                String minute = String.valueOf(scheduleTime.minute());
                String second = String.valueOf(scheduleTime.second());  
                String nextFireTime = '0 ' + minute + ' ' + hour + ' ' + String.valueOf(scheduleTime.day()) + ' ' + String.valueOf(scheduleTime.month()) + ' ?' + ' ' + String.valueOf(scheduleTime.year());
               // System.schedule('ETM_RunRules_' + String.valueOf(Datetime.now()), nextFireTime, new ETM_ExecuteTerritoryAssignmentRuleBatch(jobIds,lstmodel[0].id));
                 System.schedule('ETM_RunRules_' + String.valueOf(Datetime.now()), nextFireTime, new ETM_ExecuteTerritoryAssignmentRuleBatch(jobIds,strModelName,strArchivedTerrNameTemp,true,true));
            }
            else{
                // If its already an active model call rule assignment immediately
               // Database.ExecuteBatch(new ETM_ExecuteTerritoryAssignmentRuleBatch(jobIds,lstmodel[0].id),200);
                Database.ExecuteBatch(new ETM_ExecuteTerritoryAssignmentRuleBatch(jobIds,strModelName,strArchivedTerrNameTemp,true,false),200);
            }
        }catch(Exception e){
            //If any exception occurs updating the stage history for monitering record , creating the error logs in future to avoid the mixed dml error 
            CreateErrUpdateTerrLog(e.getMessage(),e.getStackTraceString(),jobIds,'Exception occurred during Activating terr : ',strModelName + ' \n ');
        }
    }//End of execute
    
    /**
    * @description This method is used to create error log records from any exception and updates the status of the monitering log which is processed 
    * @author Bhushan Patil | 19/3/2020 
    * @param string execptionMsg 
    * @param string trace 
    * @return void 
    **/
   
    
     @future
    public static void CreateErrUpdateTerrLog(string execptionMsg , string trace ,set<Id> logIds,String strStatus,String modelName) {
        Custom_Error_Log__c CaptureError = new Custom_Error_Log__c();
        CaptureError.Class__c = 'ETM_ActivateTerritoryModel';
        CaptureError.Functionality__c = 'ETM';
        if(execptionMsg != NULL){
            CaptureError.Exception_Message__c= execptionMsg;
            CaptureError.ErrorTrace__c= trace;
        }
        insert CaptureError;
         List<ETMStage_Monitoring__c> lstStageMoniter = [
            Select 
                Id,
                Stage_History__c,
                Status__c
            From    
                ETMStage_Monitoring__c
            Where 
                Id IN :logIds];
        for(ETMStage_Monitoring__c obj : lstStageMoniter){
            if(obj.Stage_History__c != null){
                obj.Stage_History__c += '\n'+ strStatus + modelName ;
            }else{
                obj.Stage_History__c = strStatus + modelName ;
            } 
            if(CaptureError!=null)
            obj.Stage_History__c += 'Excep errId: '+CaptureError.id;  
            obj.Status__c = 'Failed';    
        }
        Update lstStageMoniter;
    }//End of CreateErrUpdateTerrLog

    /**
    * @description This method updates the status of the monitering log which is processed 
    * @author Bhushan Patil | 23/3/2020 
    * @param set<Id> logIds 
    * @param String strStatus 
    * @param String modelName 
    * @return void 
    **/
    @future
    public static void UpdateTerritoryLogs(set<Id> logIds,String strStatus,String modelName) {
        List<ETMStage_Monitoring__c> lstStageMoniter = [
            Select 
                Id,
                Stage_History__c,
                Status__c
            From    
                ETMStage_Monitoring__c
            Where 
                Id IN :logIds ];
        for(ETMStage_Monitoring__c obj : lstStageMoniter){
            if(obj.Stage_History__c != null){
                obj.Stage_History__c += ' \n '+ strStatus + modelName ;
            }else{
                obj.Stage_History__c = strStatus + modelName ;
            }       
        }
        Update lstStageMoniter;
    }//End of CreateErrLogs
}//End of ETM_ActivateTerritoryModel