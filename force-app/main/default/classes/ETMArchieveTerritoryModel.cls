/**
 * @File Name          : ETMArchieveTerritoryModel.cls
 * @Description        : 
 * @Author             : Chaitra 
 * @Group              : 
 * @Last Modified By   : Bhushan Patil
 * @Last Modified On   : 3/4/2020, 12:23:44 pm
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    24/3/2020         Chaitra     Initial Version
**/
public class ETMArchieveTerritoryModel implements Queueable {
    public string terrModelName;
    public Set<Id> jobIds = new Set<Id>();  
    public ETMArchieveTerritoryModel(set<Id>JobIds,string terrModelName){
        this.terrModelName = terrModelName;
        this.JobIds = JobIds;
    }
    
    public void execute(QueueableContext context) {
        Boolean archivingModel = false;
        String strArchivingTerrName;
        Integer DELAY_MIN = 10; 
        Integer DEFAULT_DELAY_MIN = 1;
        Map<String,Territory2Model> mapModels = New Map<String,Territory2Model>();
        system.debug('Archieving Model'+terrModelName);
        try{
            for(Territory_Management_Setup__mdt setupData: [select Field_Value__c  from Territory_Management_Setup__mdt where DeveloperName ='TimeDelay_Archieve']) {
                if(setupData.Field_Value__c != null){
                    DELAY_MIN = Integer.valueof(setupData.Field_Value__c);
                }     
            }//End of mdt for
            List<Territory2Model> lstmodel = [
                Select 
                    Id,
                    State,
                    Name
                from
                    Territory2Model
                Where 
                    State ='Active'
                OR
                    Name =: terrModelName
            ];
            for(Territory2Model objModel : lstmodel){
                mapModels.put(objModel.Name,objModel);
            }    
            if(mapModels.containsKey(terrModelName)){
                for(Territory2Model objModel : lstmodel){
                    if(objModel.state == 'Active' 
                    && objModel.Name != terrModelName){
                        objModel.State = 'Archiving';
                        archivingModel = true;
                        strArchivingTerrName = objModel.Name;
                    }
                }
            }
            DateTime scheduleTime ;
            if(archivingModel){
                update lstmodel;
                //UpdateTerritoryLogs(jobIds,'Archiving Territory : ',strArchivingTerrName);
                scheduleTime = Datetime.now().addminutes(DELAY_MIN);
                //ETM-185: Prod Issue fix
                String hour = String.valueOf(scheduleTime.hour()); 
                string minute = String.valueOf(scheduleTime.minute());
                String second = String.valueOf(scheduleTime.second());  
                String nextFireTime = '0 ' + minute + ' ' + hour + ' ' + String.valueOf(scheduleTime.day()) + ' ' + String.valueOf(scheduleTime.month()) + ' ?' + ' ' + String.valueOf(scheduleTime.year());
                System.schedule('ETM_ActivateTerritoryModel_' + String.valueOf(Datetime.now()), nextFireTime, new ETM_ActivateTerritoryModel(jobIds,terrModelName,strArchivingTerrName));
            } 
            else
                //ETM-185: Prod Issue fix //SAL24-334/SF-37097
                //Database.ExecuteBatch(new ETM_ExecuteTerritoryAssignmentRuleBatch(jobIds,terrModelName,strArchivingTerrName,true,false),200);
                Database.ExecuteBatch(new ETM_ExecuteTerritoryAssignmentRuleBatch(jobIds,terrModelName,strArchivingTerrName,true,false),100);
        } 
        catch(Exception e){
           CreateErrUpdateTerrLog(e.getMessage(),e.getStackTraceString(),jobIds,'Exception occurred during Archiving terr : ',strArchivingTerrName + ' \n '); // Future call from batch isn't allowed
        }   
    }//End of  execute
         
    @future
    public static void CreateErrUpdateTerrLog(string execptionMsg , string trace ,set<Id> logIds,String strStatus,String modelName) {
        Custom_Error_Log__c CaptureError = new Custom_Error_Log__c();
        CaptureError.Class__c = 'ETM_ArchivingTerritoryModel';
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
    
   
}//End of class