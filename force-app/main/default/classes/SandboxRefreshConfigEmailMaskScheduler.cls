public with sharing class SandboxRefreshConfigEmailMaskScheduler implements Schedulable{
    public void execute(SchedulableContext sc) {
        //'Disable Triggers & Validation Rules
        Organization orgInfo = [Select InstanceName, Name, NamespacePrefix, OrganizationType, IsSandbox, PrimaryContact  From Organization];
        if(orgInfo.IsSandbox || Test.isRunningTest()){
            //SandboxRefreshUtil.changeCustomSettingTriggerControl(true);
            SandboxRefreshUtil.disableFunctionalityLogicCustomSetting();
            SandboxRefreshUtil.disableBusinessLogicCustomSetting();
            SandboxRefreshUtil.updateSandboxRefreshConfig('Disable Triggers & Validation Rules', 'Completed', '');
            Database.executebatch(new SandboxRefreshConfigEmailMaskBatch(), 1);
            Database.executebatch(new SandboxRefreshCustomMetadataBatch('Email_Preferences__mdt', new List<String>{'cc__c', 'Receipient__c'},'Email Masking in Email Preference Custom Metadata'), 1);
            SandboxRefreshUtil.updateSandboxRefreshConfig('Email Masking in Email Preference Custom Metadata', 'Processing', '');
            Database.executebatch(new SandboxRefreshCustomMetadataBatch('AspenConfig__mdt', new List<String>{'EmailId__c'},'Email Masking in Aspen Config Custom Metadata'), 1);
            SandboxRefreshUtil.updateSandboxRefreshConfig('Email Masking in Aspen Config Custom Metadata', 'Processing', '');
            Database.executebatch(new SandboxRefreshCustomMetadataBatch('Sfdc_Disti_Mapping__mdt', new List<String>{'Distributor_Email_Address__c'},'Email Masking in Distributor Config Custom Metadata'), 1);
            SandboxRefreshUtil.updateSandboxRefreshConfig('Email Masking in Distributor Config Custom Metadata', 'Processing', '');
            if(!Test.isRunningTest()){
                //Delete Scheduled Reports
                Database.executebatch(new SandboxRefreshReportAbortBatch(), 100);
            }
            SandboxRefreshUtil.updateSandboxRefreshConfig('Delete Scheduled Reports', 'Completed', '');
            
            //Update URL in Admin Tab
            //SandboxRefreshUtil.updateUrlInAdminTab();
            SandboxRefreshUtil.updateSandboxRefreshConfig('Update URL in Admin Tab', 'Completed', '');
        }
    }
}