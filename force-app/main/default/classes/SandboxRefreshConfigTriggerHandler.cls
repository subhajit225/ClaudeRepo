public with sharing class SandboxRefreshConfigTriggerHandler extends TriggerManager.GenericTriggerHandler{

    public override void onBeforeUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {
        Map<ID, Sandbox_Refresh_Config__c> oldMap = (Map<ID, Sandbox_Refresh_Config__c>) oldRecordsMap;
        List<Sandbox_Refresh_Config__c> newList = (List<Sandbox_Refresh_Config__c>) newRecordsMap.values();
        if(newList.size() == 1){
            Sandbox_Refresh_Config__c newSrConfig = newList[0];            
            Sandbox_Refresh_Config__c oldSrConfig = oldMap.get(newSrConfig.id);
            if( newSrConfig.Status__c == 'Not Started' && (newSrConfig.ProcessType__c == 'Automated' || newSrConfig.ProcessType__c == 'Start Manually')){
                if(newSrConfig.isInitiatedManually__c && !oldSrConfig.isInitiatedManually__c){
                    Boolean isProcessing = false;
                    Boolean isCompleted = false;
                    if(newSrConfig.Type__c == 'Email Mask' ){
                        SandboxRefreshUtil.scheduleNextBatch(2, newSrConfig.Name);
                    }else if(newSrConfig.Type__c == 'Configuration'){
                        if(newSrConfig.Name == 'Initiate Email Masking'){
                            SandboxRefreshUtil.scheduleNextBatch(1);
                            isCompleted = true;
                        }else if(newSrConfig.Name == 'Execute Sandbox Post Refresh Script'){
                            Datetime dt = Datetime.now().addMinutes(1);
                            String jobID = System.Schedule('SyncObjectsForEmailMasking' + dt.format('-yyyy_MM_dd-H_mm_ss'), dt.format('s m H d M \'?\' yyyy'), new SandboxRefreshConfigEmailMaskScheduler());
                            isProcessing = true;	
                        }else if(newSrConfig.Name == 'Masking on Workflow Email Alerts'){
                            Database.executebatch(new SandboxRefreshEmailMaskInWorkFlowAlerts(newSrConfig.id), 1);
                            isProcessing = true;
                        }else if(newSrConfig.Name == 'Email Masking in Email Preference Custom Metadata'){
                            Database.executebatch(new SandboxRefreshCustomMetadataBatch('Email_Preferences__mdt', new List<String>{'cc__c', 'Receipient__c'},'Email Masking in Email Preference Custom Metadata'), 1);
                            isProcessing = true;
                        }else if(newSrConfig.Name == 'Email Masking in Aspen Config Custom Metadata'){
                            Database.executebatch(new SandboxRefreshCustomMetadataBatch('AspenConfig__mdt', new List<String>{'EmailId__c'},'Email Masking in Aspen Config Custom Metadata'), 1);
                            isProcessing = true;
                        }else if(newSrConfig.Name == 'Activate Users'){
                            Database.executebatch(new SandboxRefreshActivateUsersBatch(newSrConfig.id), 2000);
                            isProcessing = true;
                        }else if(newSrConfig.Name == 'Update URLs'){
                            SandboxRefreshUtil.updateCustomActionURL();// (new Set<String>{'Go Refresh', 'Preview Approvals'});
                            SandboxRefreshUtil.updateTemplateContentURL();// (new Set<String>{'Custom 7 year Payments', 'Line Items MDQ', 'Line Items MDQ Non Disti'});
                            isCompleted = true;
                        }else if(newSrConfig.Name == 'Disable Triggers & Validation Rules'){
                            //SandboxRefreshUtil.changeCustomSettingTriggerControl(true);
                            SandboxRefreshUtil.disableFunctionalityLogicCustomSetting();
                            SandboxRefreshUtil.disableBusinessLogicCustomSetting();
                            isCompleted = true;
                        }else if(newSrConfig.Name == 'Delete Scheduled Reports'){
                            SandboxRefreshUtil.abortScheduleReportJob();
                            isCompleted = true;
                        /*}else if(newSrConfig.Name == 'Update URL in Admin Tab'){
                            //SandboxRefreshUtil.updateUrlInAdminTab();
                            isCompleted = true; */                       
                        }else if(newSrConfig.Name == 'Enable Triggers & Validation Rules'){
                            SandboxRefreshUtil.changeCustomSettingTriggerControl(false);
                            ShGl_DisableFunctionalityLogic__c disableFunctionalityLogicSaved = ShGl_DisableFunctionalityLogic__c.getInstance(UserInfo.getUserId());
                            if(disableFunctionalityLogicSaved.SetupOwnerId == UserInfo.getUserId()){
                                delete disableFunctionalityLogicSaved;
                            }
                            ShGl_DisableBusinessLogic__c disableBusinessLogicSavedCS = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId());
                            if(disableBusinessLogicSavedCS.SetupOwnerId == UserInfo.getUserId()){
                                delete disableBusinessLogicSavedCS;
                            } 
                            isCompleted = true;
                        }
                    }
                    if(isCompleted){
                        newSrConfig.LastBatchExecutedOn__c = System.now();
                        newSrConfig.Status__c = 'Completed';
                    }else if(isProcessing){
                        newSrConfig.LastBatchExecutedOn__c = System.now();
                        newSrConfig.Status__c = 'Processing';
                    }
                }
            }else{
                if(newSrConfig.isInitiatedManually__c && !oldSrConfig.isInitiatedManually__c){
                    //newSrConfig.addError('This feature is not automated...');
                }
            }
        }
    }
}