public with sharing class ETMBatchJobsController {
    public ETMStage_Monitoring__c etmStageMonitorRec;
    public Id etmStageMonitorId;
    public Boolean isETMJobsRunning = false;
    public ETMBatchJobsController(ApexPages.StandardController std) {
        this.etmStageMonitorId = std.getId();
        this.etmStageMonitorRec = [select Id, Status__c from ETMStage_Monitoring__c where Id =:etmStageMonitorId];
        this.isETMJobsRunning = checkETMJobsRunning(null);
    }

    public PageReference runETMBatch() {
        if(etmStageMonitorRec.Status__c == 'New'){
            if(!isETMJobsRunning){
                ETMCreateTerritoryModelBatch etmBatch = new ETMCreateTerritoryModelBatch();
                etmBatch.etmStageMonitoringId = etmStageMonitorRec.Id;
                Database.executeBatch(etmBatch,1);
                ApexPages.addMessage(new ApexPages.message(Apexpages.Severity.INFO,Label.ETM_BatchJob_Started_Message));
            }
            else{
                ApexPages.addMessage(new ApexPages.message(Apexpages.Severity.INFO,Label.ETM_BatchJob_Already_Running_Message));
            }
        }
        else ApexPages.addMessage(new ApexPages.message(Apexpages.Severity.INFO,Label.ETM_Batch_Job_Not_Eligible_Message));
        return null;
    }

    public Pagereference redirectToETMStageMonitorRecord(){
        PageReference etmSMPage = new ApexPages.StandardController(etmStageMonitorRec).view();
        etmSMPage.setRedirect(true);
        return etmSMPage;
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