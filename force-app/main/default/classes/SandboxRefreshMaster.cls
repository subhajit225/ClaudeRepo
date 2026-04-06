global with sharing class SandboxRefreshMaster implements SandboxPostCopy {
    global void runApexClass(SandboxContext context) {
        System.debug(context.organizationId()); 
        System.debug(context.sandboxId()); 
        System.debug(context.sandboxName()); 
        Datetime dt = Datetime.now().addMinutes(10);

        SandboxRefreshUtil.createDataInDeveloperSandbox();
        SandboxRefreshUtil.changeCustomSettingTriggerControl(true);

        String jobID = System.Schedule('SyncObjectsForEmailMasking' + dt.format('-yyyy_MM_dd-H_mm_ss'), dt.format('s m H d M \'?\' yyyy'), new SandboxRefreshConfigEmailMaskScheduler());
    }
}