public with sharing class SandboxRefreshConfigEmailMaskBatch implements Database.batchable<String>, Database.Stateful{ 
    private boolean isFailed = false; 
    private String errorMsg = '';
    private Sandbox_Refresh_Config__c configEmailMaskBatch = null;
    /* This method internally invoke the web-service and parse data. Returm map list pass for batch execution. */
    public Iterable<String> start(Database.BatchableContext info){ 
        System.debug('~~~~SandboxRefreshConfigEmailMaskBatch.Started: ');
        List<String> objectNameSet = new List<String>();
        configEmailMaskBatch = SandboxRefreshUtil.updateSandboxRefreshConfig('Initiate Email Masking', 'Processing', '');
        try{
            Organization orgInfo = [Select InstanceName, Name, NamespacePrefix, OrganizationType, IsSandbox, PrimaryContact  From Organization];
            if(orgInfo.IsSandbox || Test.isRunningTest()){
                Set<String> objectToIgnore = new Set<String>{'location', 'orgdeleterequest', 'orgdeleterequestshare', 'pdri__connection__c', 'pdri__replicateIt_settings__c', 'emailmessage'};
                
                Map<String, Schema.SObjectType> sObjectTypeMap = Schema.GetGlobalDescribe();
                for(String objectName :sObjectTypeMap.keySet()){
                    Schema.SObjectType sObjectTypeObj = sObjectTypeMap.get(objectName);
                    Sobject obj = sObjectTypeObj.newSObject();
                    System.debug(objectName + '~~~~objectName: ' + obj);
                    if(!objectToIgnore.contains(objectName) ){
                        Schema.DescribeSObjectResult objResult = obj.getSobjectType().getDescribe();
                        if(objResult.isUpdateable()){
                            if(!Test.isRunningTest() || (Test.isRunningTest() && objectName == 'Contact' )){
                                objectNameSet.add(objResult.getName());
                            }
                        }
                    }
                }
                errorMsg += 'Info: Object List- ' + JSON.serialize(objectNameSet);
                errorMsg = errorMsg.replaceAll('","', ', ');
                List<Sandbox_Refresh_Config__c> oldConfigList = [Select ID from Sandbox_Refresh_Config__c where ObjectLabel__c != null AND Type__c != 'Configuration'];
                if(!oldConfigList.isEmpty()){
                    delete oldConfigList;
                }
            }
        }catch(Exception e){
            isFailed = true;
            errorMsg += ' ' + e.getStackTraceString();
        }
        return objectNameSet; 

    } 

    
    public void execute(Database.BatchableContext BC, List<String> objectNameSet){
        System.debug('~~~~objectNameSet:'+objectNameSet);
        List<Sandbox_Refresh_Config__c> sandboxRefreshConfigList = new List<Sandbox_Refresh_Config__c>();
        for(String objectName: objectNameSet){
            Sandbox_Refresh_Config__c obj = SandboxRefreshUtil.getEmailMaskingObject(objectName);
            if(obj != null){
                obj.ParentTask__c = configEmailMaskBatch.id;
                sandboxRefreshConfigList.add(obj);
                if(SandboxRefreshUtil.SPLIT_BATCH.containsKey(objectName)){
                    sandboxRefreshConfigList.addAll(SandboxRefreshUtil.splitConfig(obj, SandboxRefreshUtil.SPLIT_BATCH.get(objectName)));
                }
            }
        }
        if(!sandboxRefreshConfigList.isEmpty()){
            insert sandboxRefreshConfigList;
        }
    }    
        
    public void finish(Database.BatchableContext bc){
        SandboxRefreshUtil.updateSandboxRefreshConfig('Execute Sandbox Post Refresh Script', (isFailed ? 'Failed' : 'Completed'), errorMsg);
        SandboxRefreshUtil.updateSandboxRefreshConfig('Initiate Email Masking', (isFailed ? 'Not Started' : 'Completed'), '');
        if(!Test.isRunningTest() && !isFailed){
            SandboxRefreshUtil.scheduleNextBatch(1);
        }
    }    
}