trigger ScaleUtilityIntegrationTrigger on Scale_Utility_Integration__e (after insert) {
    List<Scale_Utility_Integration__e> initialProcessing = new List<Scale_Utility_Integration__e>();
    List<Scale_Utility_Integration__e> reProcessing = new List<Scale_Utility_Integration__e>();
    for (Scale_Utility_Integration__e event : Trigger.new) {
        system.debug('### event.Job_Name__c:'+event.Job_Name__c);
        if (event.Job_Name__c == 'Initial Processing') {
            initialProcessing.add(event);
        } else if (event.Job_Name__c == 'Reprocessing') {
            reProcessing.add(event); 
        }
    }
    try{ 
        
        if(Trigger.new?.size() > 0){
            ScaleUtilityOverageTriggerHelper.sendOverageBatchTriggerEmail(Trigger.new);
        }
        
    }
    Catch(Exception ex){
        UtilityClass.logException(ex, 'ScaleUtilityOverageTriggerHelper', 'sendOverageBatchTriggerEmail' );
    }
    if(!initialProcessing.isEmpty()){
         Database.executeBatch(new ScaleUtilityOverageBatchWithCLI('Initial Processing', null, null), 1);
    }
    if(!reProcessing.isEmpty()){
        ScaleUtilityOverageTriggerHelper.processSnowflakeFeedsForReProcessing(null);
    } 
}