trigger AccountTrigger on Account (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
    DateTime startTime = System.now();
    Long cpuLimitstart = Limits.getCpuTime();
    Long soqlLimitstart = Limits.getQueries();
    Long dmlLimitstart = Limits.getDMLStatements();
    String triggerDetails = 'Account' + (Trigger.isBefore ? ' Before' : (Trigger.isAfter ? ' After' : '')) + (Trigger.isInsert ? ' Insert' : (Trigger.isUpdate ? ' Update' : (Trigger.isDelete? ' Delete' : ' SomethingElse')));
    System.debug('\n\t\tAccount\tRUBRIK TRIGGER Initiated \t' + triggerDetails +  '\nTrigger~~~~: oldRecord: ' + Trigger.old + '\nTrigger~~~~: newRecord: ' + Trigger.new);

    if(!disabled.Disable_Account_Triggers__c && FlowControll.accountTrigger){
        System.debug('\n\t\tAccount\tRUBRIK TRIGGER-EXECUTION STARTED:\t' +  ++TriggerManager.triggerDepthCount + ': ' + triggerDetails + ' at: ' + startTime);
        new AccountTriggersHandler().run(); 
        System.debug('\n\t\tAccount\tRUBRIK TRIGGER-EXECUTION FINISHED:\t' +  TriggerManager.triggerDepthCount-- + ': ' + triggerDetails + ' at: '  + System.now()
        + '\t Total time taken: ' + (System.now().getTime() - startTime.getTime()) + 'ms, \tCPU_TIME_TAKEN: ' + (Limits.getCpuTime() - cpuLimitstart) + ' ms.\tSOQL # ' + (Limits.getQueries() - soqlLimitstart) + ', DMLs #' + (Limits.getDMLStatements() - dmlLimitstart));
    }else{
        System.debug( '\n\t\tAccount\tRUBRIK Trigger Blocked:\t' + triggerDetails +  ' at: '  + System.now()
        + '\t Total time taken: ' + (System.now().getTime() - startTime.getTime()) + 'ms, \tCPU_TIME_TAKEN: ' + (Limits.getCpuTime() - cpuLimitstart) + ' ms.\tSOQL # ' + (Limits.getQueries() - soqlLimitstart) + ', DMLs #' + (Limits.getDMLStatements() - dmlLimitstart));
    }
    //SAL25-780
    if(Trigger.isBefore && Trigger.isDelete){
        AccountTriggerHelper.validateAccountOnDelete(Trigger.old); 
    }
    //SAL26-190 Start
    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        String disabledHistorytracking = System.label.Disable_Account_History_Tracking;
        if(disabledHistorytracking == 'No' || disabledHistorytracking == 'no') {
            CustomHistoryTracker.trackFieldsHistory(trigger.new, Trigger.oldMap, 'Account__c');
        }
    }
   //SAL26-190 End
}