public with sharing class SandboxRefreshEmailMaskingScheduler implements Schedulable {  
    private String objectApiName = '';
    
    public SandboxRefreshEmailMaskingScheduler(){}

    public SandboxRefreshEmailMaskingScheduler(String objectApiName){
        this.objectApiName = objectApiName;
    }
    public void execute(SchedulableContext sc) {
        Organization orgInfo = [Select InstanceName, Name, NamespacePrefix, OrganizationType, IsSandbox, PrimaryContact  From Organization];
        if(orgInfo.IsSandbox || Test.isRunningTest()){
            List<Sandbox_Refresh_Config__c> sRefreshConfigObjList =  SandboxRefreshUtil.getObjectForMasking(objectApiName);
            if(!sRefreshConfigObjList.isEmpty()){
                Sandbox_Refresh_Config__c sRefreshConfigObj = sRefreshConfigObjList[0];
                SandboxRefreshUtil.scheduleParallelBatch(sRefreshConfigObj);
                sRefreshConfigObj.BatchSize__c = (sRefreshConfigObj.Status__c != 'Not Started') ? (SandboxRefreshUtil.BATCH_SIZE_SESET_MAP.get(Integer.valueOf(sRefreshConfigObj.BatchSize__c)) ): sRefreshConfigObj.BatchSize__c;
                sRefreshConfigObj.BatchSize__c = sRefreshConfigObj.BatchSize__c == null ? 100 : sRefreshConfigObj.BatchSize__c;
                sRefreshConfigObj.Status__c = sRefreshConfigObj.Status__c == 'Not Started' ? 'Processing' : sRefreshConfigObj.Status__c;
                sRefreshConfigObj.isInitiatedManually__c = String.isNotBlank(objectApiName);
                sRefreshConfigObj.LastBatchExecutedOn__c = System.now();
                update sRefreshConfigObj;
                Database.executebatch(new SandboxRefreshEmailMaskingBatch(sRefreshConfigObj), Integer.valueOf(sRefreshConfigObj.BatchSize__c));
            }
        }
    }
}