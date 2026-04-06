public without sharing class ETMBatchJobsLWCController {

    @AuraEnabled
    public static string runETMBatch(String recId){
        ETMStage_Monitoring__c etmStageMonitorRec = new ETMStage_Monitoring__c();
        etmStageMonitorRec = [select Id, Status__c from ETMStage_Monitoring__c where Id =:recId];
        Boolean isETMJobsRunning = checkETMJobsRunning(null);
        String status = '';
        if(etmStageMonitorRec.Status__c == 'New'){
            if(!isETMJobsRunning){
                ETMCreateTerritoryModelBatch etmBatch = new ETMCreateTerritoryModelBatch();
                etmBatch.etmStageMonitoringId = etmStageMonitorRec.Id;
                Database.executeBatch(etmBatch,1);
                status = 'Started';
            }else{
                status = 'Already Running';
            }
        }else {
            status = 'Not Eligible';
        }
        return status;
    }
    public static Boolean checkETMJobsRunning(Id currentJobId){
        //Id thisClassId = '<id_of_you_batch_apex_class>'; //can be in a custom label for easier maintenance.
        Set<String> etmBatchJobClassNames = new Set<String> {'ETMCreateTerritoryModelBatch','ETMCreateUserTerritoryAssociationBatch','UserTerritoryAssociationHistoryHelper','ETMAdaptiveUpdateOnAccountBatch','ETMArchieveTerritoryModel', 'ETM_ActivateTerritoryModel', 'ETM_ExecuteTerritoryAssignmentRuleBatch','ETM_UpdateUTAHistoryRecordBatch','ETM_ProcessAssociationRecordBatch','ETMTerritoryOwnerAssociationBatch','ETMContactOwnerChangeBatch','ETMUpdateOppOwner'};
        Set<String> batchJobStatus = new Set<String> {'Holding', 'Queued', 'Preparing', 'Processing'};
        Set<String> batchJobType = new Set<String> {'BatchApex', 'BatchApexWorker'};
        AsyncApexJob[] etmJobs = [select id from AsyncApexJob where id!=:currentJobId AND status IN :batchJobStatus AND ApexClass.Name IN :etmBatchJobClassNames AND JobType IN :batchJobType];
        if(etmJobs.isEmpty()) { //==null || etmJobs.size()==0) {
            return false;
        }
        return true;
    }
}