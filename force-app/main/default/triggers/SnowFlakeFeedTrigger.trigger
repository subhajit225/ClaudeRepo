trigger SnowFlakeFeedTrigger on Snowflake_Feed__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance(); 
  DateTime startTime = System.now();
  Long cpuLimitstart = Limits.getCpuTime();
  Long soqlLimitstart = Limits.getQueries();
  Long dmlLimitstart = Limits.getDMLStatements();
  String triggerDetails =
    'Snowflake_Feed' +
    (Trigger.isBefore ? ' Before' : (Trigger.isAfter ? ' After' : '')) +
    (Trigger.isInsert ? ' Insert' : (Trigger.isUpdate ? ' Update' : (Trigger.isDelete ? ' Delete' : ' SomethingElse')));
  System.debug(
    '\n\t\tSnowflake_Feed\tRUBRIK TRIGGER Initiated \t' +
      triggerDetails +
      '\nTrigger~~~~: oldRecord: ' +
      Trigger.old +
      '\nTrigger~~~~: newRecord: ' +
      Trigger.new
  );

  if (!disabled.Disable_SnowFlake_Feed_Triggers__c && FlowControll.SnowflakeFeedTrigger) { 
    System.debug(
      '\n\t\tSnowflake_Feed\tRUBRIK TRIGGER-EXECUTION STARTED:\t' +
        ++TriggerManager.triggerDepthCount +
        ': ' +
        triggerDetails +
        ' at: ' +
        startTime
    );
    new SnowFlakeFeedTriggerHandler().run(); 
    System.debug(
      '\n\t\tSnowflake_Feed\tRUBRIK TRIGGER-EXECUTION FINISHED:\t' +
        TriggerManager.triggerDepthCount-- +
        ': ' +
        triggerDetails +
        ' at: ' +
        System.now() +
        '\t Total time taken: ' +
        (System.now().getTime() - startTime.getTime()) +
        'ms, \tCPU_TIME_TAKEN: ' +
        (Limits.getCpuTime() - cpuLimitstart) +
        ' ms.\tSOQL # ' +
        (Limits.getQueries() - soqlLimitstart) +
        ', DMLs #' +
        (Limits.getDMLStatements() - dmlLimitstart)
    );
  } else {
    System.debug(
      '\n\t\tSnowflake_Feed\tRUBRIK Trigger Blocked:\t' +
        triggerDetails +
        ' at: ' +
        System.now() +
        '\t Total time taken: ' +
        (System.now().getTime() - startTime.getTime()) +
        'ms, \tCPU_TIME_TAKEN: ' +
        (Limits.getCpuTime() - cpuLimitstart) +
        ' ms.\tSOQL # ' +
        (Limits.getQueries() - soqlLimitstart) +
        ', DMLs #' +
        (Limits.getDMLStatements() - dmlLimitstart)
    );
  }    
}