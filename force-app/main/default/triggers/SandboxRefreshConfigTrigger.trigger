trigger SandboxRefreshConfigTrigger on Sandbox_Refresh_Config__c (before update) {
    Organization orgInfo = [Select InstanceName, Name, NamespacePrefix, OrganizationType, IsSandbox, PrimaryContact  From Organization];
    if(orgInfo.IsSandbox || Test.isRunningTest()){
        TriggerManager.invokeHandler(new SandboxRefreshConfigTriggerHandler());    
    }
}