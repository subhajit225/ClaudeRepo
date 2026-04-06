trigger ClusterMain on Cluster__c (after Update,after insert, before update) {
    if(TriggerControl__c.getAll() != null && TriggerControl__c.getAll().containsKey('Cluster') && !TriggerControl__c.getInstance('Cluster').DisableTrigger__c){
        if(Trigger.isBefore){
            if(Trigger.isUpdate){
                ClusterMainTriggerHandler.setInsightMatches(Trigger.new, Trigger.oldMap);
                ClusterMainTriggerHandler.updateEndOfSupportFromAcc(Trigger.new, Trigger.oldMap, trigger.isInsert);
            }
        }
        if(Trigger.isAfter){
        if (Trigger.isInsert){
                ClusterMainTriggerHandler.clusterInsert(Trigger.New);
                ClusterMainTriggerHandler.updateEndOfSupportFromAcc(Trigger.new, null, trigger.isInsert);
        }
    /*Trigger Update*/
        if (Trigger.isUpdate){
                ClusterMainTriggerHandler.existingCode(Trigger.New,Trigger.OldMap);
                ClusterMainTriggerHandler.clusterupdate(Trigger.New,Trigger.OldMap);
            }
            /*Trigger Update*/
        }
    }
}